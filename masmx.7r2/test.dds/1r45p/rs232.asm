RS232_ReceivePacket:
        push    dph
        push    dpl
        
        mov     dptr, #buffer-2
        movx    a, @dptr     
        mov     r6, a
        inc     dptr
        movx    a, @dptr
        mov     r7, a

        
        orl     a, r6
        
        jnz     RS232_LongPacketComingIn

        pop     dpl
        pop     dph
        
        call    EXAR_HowMany?   ; # unconsumed bytes
        jc      RS232_Yep
        
        add     a,#-5           ; enough to contain a length field?
        jnc     RS232_Nope      ; if not that aint no packet

        add     a,#4            ; if so the length don't include AF_AE
        mov     b,a             ; but does include carry  (add 2scomp)
        mov     a,#4
        call    EXAR_Index      ; read the length byte
        
        jnb     acc.7, RS232_BasicFormat
        mov     a, #-48         ; Don't OverRun
        add     a, b
        jnc     RS232_Nope
RS232_Yep        
        mov     b, #'!'
        call    LCD_BugA
        call    RS232_AreYouGoingtoDoAnythingAboutThis?
        jmp     RS232_ReceivePacket

RS232_BasicFormat:        
        mov     r7,a            ; pretend this is going to work
        cpl     a               ; subtract it from the actual received -2
        add     a,b
        jnc     RS232_Nope      ; Not Yet Received Enough

        call    EXAR_Read1
        cjne    a, #0afh, RS232_Trash  ; Monitor the two funny sentinel bytes
        call    EXAR_Read1
        cjne    a, #0aeh, RS232_Trash

        mov     dptr, #buffer          ; 
RS232_Deliver:
        call    EXAR_Read1
        movx    @dptr, a
        inc     dptr
        djnz    r7, RS232_Deliver

        mov     dptr, #buffer+3
        movx    a, @dptr
        cjne    a, sys_mynode, RS232_NotYet
        jmp     RS232_YeSSir
RS232_NotYet
        jmp     RS232_ReceivePacket
RS232_YeSSir        
        mov     a, #2           ; announce which interface packet is from
        ret

RS232_Trash:
        call    EXAR_Start      ; Hopeless. Initialise the whole thing.
RS232_Nope:
        clr     A
        ret

RS232_LongPacketComingIn
                                ; r6-7 are the Net write_to address
                                ; dptr = Buffer
                                ; 1st 3 bytes of Buffer are
                                ; ChecksumL, LengthU, LengthL
                                ; It has to be garaunteed that more data than
                                ; the actual message is not already xferred
                                ; from xcom1 256-byte buffer to Buffer
        
        
        

        inc     dptr            ; move forward from the cursor bytes
        inc     dptr            ; skip the checksum for now
        movx    a, @dptr        ; Expected Length Upper
        mov     b, a
        inc     dptr
        movx    a, @dptr        ; Expected Length Lower
        
        mov     dph, r6         ; Net Actual Write Pointer
        mov     dpl, r7
        
        clr     C               ; Calculate How Much More to Accept less 1
        xrl     r7, #255        ; Subtract Actual Write Pointer
        addc    a, r7           ; From Expected Length
        
        mov     r7, a

        mov     a, dph          ; Subtract Actual Write Pointer
        cpl     A               ; From Expected High Address
        addc    a, b
        
        
;        jnc     RS232_Trash     ; You've Minced It with the Next Packet
        
        mov     r6, a

        orl     a, r7
        jz      RS232_Long_Packet_Arrived   ; zero
;        jb      acc.7, RS232_Long_Packet_Arrived  ; or less

        mov     a, #buffer/*8
        add     a, dph
        mov     dph, a

        cjne    r6, #0, RS232_InputLongPacket
        mov     r6, #1          ; Don't Overdo it



RS232_InputLongPacket        
        call    EXAR_Read1        
        jnc     RS232_HaltInput
        movx    @dptr, a
        inc     dptr
        djnz    r7, RS232_InputLongPacket
        djnz    r6, RS232_InputLongPacket

RS232_Long_Packet_Arrived        
        mov     dptr, #buffer-2         ; restart Buffer
        clr     a
        movx    @dptr, a
        inc     dptr
        movx    @dptr, a
        mov     dptr, #buffer+3
        movx    a, @dptr
        pop     dpl
        pop     dph
        
        cjne    a, sys_mynode, RS232_NotYet
        jmp     RS232_YeSSir


RS232_HaltInput:
        mov     a, dph                  ; Save the input cursor
        
        add     a, #-(buffer/*8)
        
        mov     b, dpl
        mov     dptr, #buffer-2
        movx    @dptr, a
        inc     dptr
        mov     a, b
        movx    @dptr, a
        
        pop     dpl
        pop     dph
        
        clr     A                       ; Say we got no complete packet
        ret


RS232_AreYouGoingtoDoAnythingAboutThis?:
        mov     dptr, #buffer-2
        movx    a, @dptr     
        
        add     a, #buffer/*8
        
        mov     r6, a
        inc     dptr
        movx    a, @dptr
        mov     r7, a
        mov     dph, r6
        mov     dpl, r7
        
        mov     r5, #32         ; keep interrupts locked but do little
                                ; maybe about twice the FIFO size
        
        cjne    r6, #buffer/*8, RS232_AlreadyInPacket
        cjne    r7, #0, RS232_AlreadyInPacket

        call    EXAR_Read1
        cjne    a, #0afh, RS232_Trash
        call    EXAR_Read1
        cjne    a, #0aeh, RS232_Trash

        call    EXAR_Read1
        movx    @dptr, a        ; checksum Lower ->Buffer+0
        inc     dptr
        call    EXAR_Read1
        call    EXAR_Read1      ; Overwrite Checksum Upper with length Upper
        mov     b, a            ;
        clr     a
        jnb     b.7, RS232_StandardLength
        call    EXAR_Read1
        xch     a, b
        anl     a, #127
RS232_StandardLength:
        movx    @dptr, a        ; Length Upper ->Buffer+1
        inc     dptr
        mov     a, b            ; Length Lower ->Buffer+2
        movx    @dptr, a
        inc     dptr

RS232_AlreadyInPacket
        call    EXAR_Read1
        movx    @dptr, a
        inc     dptr
        djnz    r5, RS232_AlreadyInPacket
        mov     b, dpl
        mov     a, dph

        mov     dptr, #buffer-2         ; maintain the stored cursor
        
        add     a,#-(buffer/*8)
        
        movx    @dptr, a
        mov     a,b
        inc     dptr
        movx    @dptr, a

        ret
