;************************************************************************
;       CHEETAH7.ASM     Tim, 9v2000                                    *
;       This does not touch the Cheetah. It is a heavy traffic simulator*
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
CHEETAH_FINAL1  equ     126
CHEETAH_FINAL2  equ     127


CHEETAH_Initial:
                mov     dptr,#chee_state
                clr     a
                movx    @dptr,a
                mov     a,#21
                inc     dptr
                movx    @dptr,a
                mov     b,a
                mov     a,sys_mynode
                add     a,#18
CHEETAH_InitialL:
                inc     dptr
                movx    @dptr,a
                djnz    b,CHEETAH_InitialL
                ret



CHEETAH_State:  mov     dptr,#chee_state
                mov     a,#CHEE_WaitAllRead
                movx    @dptr,a
                inc     dptr

                IF      BARCODE_FORMAT eq BARCODE_ZERO
                clr     a
                movx    @dptr,a
                ENDIF

                IF      BARCODE_FORMAT eq BINARY72
                mov     a,#21
                movx    @dptr,a
                mov     b,a
                setB    C
CHEETAH_StateL: inc     dptr
                movx    a,@dptr
                addc    a,#0
                movx    @dptr,a
                add     a,#-':'
                jnc     CHEETAH_StateR
                mov     a,#'0'
                movx    @dptr,a
CHEETAH_StateR: djnz    b,CHEETAH_StateL

                
                mov     r7,#21
                mov     dptr,#chee_count+1
                call    ARITH_B2I72

                mov     r0,#prt_field_str
                mov     dptr,#tkc_currenttsr+3
                mov     b,#ARITH_FIELD
CHEETAH_StateZ:
                mov     a,@r0
                movx    @dptr,a
                inc     r0
                inc     dptr
                djnz    b,CHEETAH_StateZ

                ENDIF

                setB    C
                ret

CHEETAH_Move2StateFinal2:
                mov     dptr,#chee_state
                mov     a,#CHEETAH_FINAL2
                movx    @dptr,a
                clr     a
                inc     dptr
                movx    @dptr,a
                ret

CHEE_No:        
CHEE_Yes:
        ret        
        
        End





