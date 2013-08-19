;       *****************************************************************
;       *       Transport Layer Data Transcribe                         *
;       *                                                               *
;       *       called cumulatively to compose PDU from IP_Pseudoheader,*
;       *                                               UDP/TCP Header, *
;       *                                               Application Data*
;       *                                                               *
;       *       May be called on input to maintain an input stream      *
;       *       or to remove and checksum a datagram from network buffer*
;       *                                                               *
;       *       ON ENTRY                                                *
;       *                                                               *
;       *       AB = 1scomp-checksum so far in network order            *
;       *            including previous endaround carry                 *
;       *                                                               *
;       *       R6 = how much data to embed in the destination, in bytes*
;       *                                                               *
;       *            For input, R6 = how much to extract                *
;       *                                                               *
;       *            Simple UDP/ICMP input can be effected without      *
;       *            this routine, simply by addressing the datagram    *
;       *            in the network buffer.                             *
;       *                                                               *
;       *            If streamed input is desired, R6 should always be  *
;       *            maximum, and DPTR1 should point to a circular input*
;       *            buffer which the socket interface can read as      *
;       *            desired                                            *
;       *                                                               *
;       *       R7   is accumulated count so far of data delivered      *
;       *                                                               *
;       *       DPTR0 =      source buffer                              *
;       *       DPTR1 = destination buffer                              *
;       *                                                               *
;       *                                                               *
;       *                                                               *
;       *       ON RETURN                                               *
;       *                                                               *
;       *       AB = updated 1scomp-checksum with trailing carry        *
;       *            added endaround, pseudo trailing NOT_0 added into  *
;       *            LS half sum if (R6) # bytes was an odd number      *
;       *                                                               *
;       *       R6 = zero                                               *
;       *                                                               *
;       *       R7   is incremented by the # data delivered             *
;       *                                                               *
;       *       DPTR0 =      source buffer + length transcribed         *
;       *       DPTR1 = destination buffer + length transcribed         *
;       *       DPSEL = 0                                               *
;       *                                                               *
;       *       R0   is overwritten                                     *
;       *                                                               *
;       *****************************************************************


move1sum:
        clr     c                       ; previous carry is already in
sum1loop:
        push    acc                     ; MS half of sum so far
        mov     dpsel,#0                ; read FROM
        movx    a,@dptr
        inc     dptr                    ; and advance
        mov     dpsel,#1                ; write TO
        movx    @dptr,a
        inc     dptr                    ; and advance
        cpl     a                       ; reverse MS half of sum increment
        push    acc                     ; save
        inc     r7                      ; increment the destination length
        djnz    r6,sum1leg2             ; process other half of word
        mov     a,b                     ; if none, fall thru
        addc    a,#255                  ; add a reversed 0 to LS half of sum
        mov     b,a                     ; 
        pop     acc                     ; retrieve the reversed MS half
        mov     r0,sp                   ; address the stack top
        addc    a,@r0                   ; add the previous sum MS half
        dec     sp                      ; drop object on stack top
        jmp     sum1_endaround          ; final processing
sum1leg2:
        mov     dpsel,#0                ; read FROM
        movx    a,@dptr
        inc     dptr                    ; and advance
        mov     dpsel,#1                ; write TO
        movx    @dptr,a                 ; 
        inc     dptr                    ; and advance
        cpl     a                       ; reverse LS half of sum increment
        addc    a,b                     ; add it
        mov     b,a                     ; and keep it
        pop     acc                     ; retrieve MS half of sum increment
        mov     r0,sp                   ; address stack top
        addc    a,@r0                   ; add to MS half of accumulated sum
        dec     sp                      ; drop object on stack top
        inc     r7                      ; increment the destination length
        djnz    r6,sum1loop             ; go back for the rest
sum1_endaround:                         ; or fall thru
        push    acc                     ; save MS half sum
        mov     a,b                     ; add carry to LS half
        addc    a,#0
        mov     b,a
        pop     acc                     ; retrieve MS half
        addc    a,#0                    ; add carry to MS half
        mov     dpsel,#0
        ret

        END
