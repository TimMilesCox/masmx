;************************************************************************
;       CHEETAH.ASM     Tim, 17iv2000                                   *
;************************************************************************       


;                       Device->Host Status Codes


CHEE_Stopped            EQU     080h
CHEE_ForwardFeed        EQU     081h        
CHEE_ForwardFree        EQU     082h
CHEE_Paused             EQU     083h
CHEE_EjectRear          EQU     084h
CHEE_EjectFront         EQU     085h
CHEE_EjectFrontFree     EQU     086h
CHEE_WaitAllRead        EQU     087h
CHEE_ToRear             EQU     088h
CHEE_FlipperEjectRear   EQU     089h
CHEE_TicketRemoved      EQU     08Ah
CHEE_TicketEntered      EQU     08Bh
CHEE_TicketIn           EQU     08Ch
CHEE_TicketOutFront     EQU     08Dh
CHEE_TicketOutBack      EQU     08Eh
CHEE_BackUpState        EQU     08Fh
CHEE_WaitForEjectFrontReject EQU 090h
CHEE_WaitForRotateRear  EQU     091h
CHEE_WaitForEjevtFrontAccept EQU 092h
CHEE_WaitForRotateFront EQU     093h
CHEE_ReScanFront        EQU     094h
CHEE_TurnstileRotated   EQU     0B0h
CHEE_GateOpened         EQU     0C0h
CHEE_NobodyEntered      EQU     0D0h



;                       Host->Device Command Codes

CHEE_COMMAND            EQU     128
CHEE_ACK                EQU     64
CHEE_BACKEJECT          EQU     32
CHEE_RETAIN             EQU     16
CHEE_CHILDLIGHT         EQU     8
CHEE_ADULTLIGHT         EQU     4
CHEE_AUXRELEASE         EQU     2
CHEE_GATERELEASE        EQU     1


chee_state      equ     buffer+1024-1
chee_count      equ     buffer+1024

CHEETAH_LISTEN  equ     0


CHEETAH_Initial:
                mov     dptr,#chee_state
                clr     a
                movx    @dptr,a
                inc     dptr
                movx    @dptr,a
                ret



CHEETAH_State:  mov     dptr,#chee_state
                movx    a,@dptr
                cjne    a,#CHEETAH_LISTEN,CHEETAH_State2
CHEETAH_Sync1:  call    EXAR_Read1
                jnc     CHEETAH_X
                cjne    a,#CHEE_TicketEntered,CHEETAH_Sync1
                mov     dptr,#chee_state
                movx    @dptr,a
                jmp     CHEETAH_Sync2
CHEETAH_State2: cjne    a,#CHEE_TicketEntered,CHEETAH_State3
CHEETAH_Sync2:  call    EXAR_Read1
                jnc     CHEETAH_X
                cjne    a,#CHEE_ForwardFeed,CHEETAH_Sync2
                mov     dptr,#chee_state
                movx    @dptr,a
                inc     dptr
                clr     a
                movx    @dptr,a
                jmp     CHEETAH_Sync3
CHEETAH_State3: cjne    a,#CHEE_ForwardFeed,CHEETAH_State4
CHEETAH_Sync3:  call    EXAR_Read1                
                jnc     CHEETAH_X
                jb      acc.7,CHEETAH_Sync33
                cjne    a,#ANSII_CR,CHEETAH_Data1
                jmp     CHEETAH_Complete
CHEETAH_Data1:
                cjne    a,#ANSII_LF,CHEETAH_Data2
                jmp     CHEETAH_Complete
CHEETAH_Data2:
                mov     b,a
                mov     dptr,#chee_count
                movx    a,@dptr
                inc     a
                movx    @dptr,a
                mov     dpl,a
                mov     a,b
                movx    @dptr,a
                jmp     CHEETAH_Sync3
CHEETAH_Sync33: cjne    a,#CHEE_WaitAllRead,CHEETAH_Sync44
                jmp     CHEETAH_Complete
CHEETAH_Sync44:
                cjne    a,#CHEE_ForwardFree,CHEETAH_X
CHEETAH_Complete:            
                mov     a,#CHEE_WaitAllRead
                mov     dptr,#chee_state
                movx    @dptr,a
                inc     dptr
                movx    a,@dptr
                jz      CHEETAH_X
                
                IF      BARCODE_FORMAT EQ BINARY72

                mov     r7,a            ; Data Count (ASCII Digits)
                inc     dptr            ; First Digit
                call    ARITH_B2I72     ; Convert to 72-bit Binary
                mov     r0,#prt_field_str
                mov     dptr,#tkc_currenttsr+3
                mov     b,#ARITH_FIELD
CHEETAH_StateN: mov     a,@r0           ; Copy into Trailer of TSR Packet
                movx    @dptr,a
                inc     r0
                inc     dptr
                djnz    b,CHEETAH_StateN
                
                ENDIF                

                setB    C
                ret

CHEETAH_State4: cjne    a,#CHEE_WaitAllRead,CHEETAH_Y
                jmp     CHEETAH_X
                
CHEETAH_Y:      clr     a
                mov     dptr,#chee_state
                movx    @dptr,a
                inc     dptr
                movx    @dptr,a
CHEETAH_X:      clr     C
                ret
                

CHEE_No:        
        mov     a,#CHEE_COMMAND
        jmp     EXAR_TxL
CHEE_Yes:
        mov     a,#CHEE_COMMAND OR CHEE_ACK OR CHEE_BACKEJECT
        jmp     EXAR_TxL
        
        
        End







