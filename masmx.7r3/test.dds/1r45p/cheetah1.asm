CHEETAH_STRIP_CCHARS    EQU     1
DEBUG_ASCII17           EQU     0

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


;  Reader States


CHEETAH_LISTEN  equ     0       ; Waiting for Input to Start
                                ; Any previously assembled BarCode
                                ; has been consumed

                                ; Any Value--128 = scanning preliminary
                                ; Cheetah Status Values

CHEETAH_DATA1   equ     1       ; Data has begun to assembled
CHEETAH_FINAL1  equ     126     ; Data is assembled up to CR, but System
                                ; has not consumed the Assembled Barcode
CHEETAH_FINAL2  equ     127     ; System has consumed the Assembled 
                                ; BarCode, but Stopped = 80h has not been
                                ; encountered


CHEETAH_Initial:
                mov     dptr,#chee_state
                clr     a
                movx    @dptr,a
                inc     dptr
                movx    @dptr,a
                ret



CHEETAH_State:  mov     dptr,#chee_state        ; Read Machine State
                movx    a,@dptr
                cjne    a,#CHEETAH_LISTEN,CHEETAH_State2
CHEETAH_Sync1:  call    EXAR_Read1              ; Any Value Causes Transition
                jc      CHEETAH_D1
                ret
CHEETAH_D1:
                cjne    a,#ANSII_LF,CHEETAH_Sync11 ; Except LF 
                jmp     CHEETAH_Sync1
CHEETAH_Sync11:
                jnb     acc.7,CHEETAH_Tr2
                mov     dptr,#chee_state        ; Transition 1 Listen/Command
                movx    @dptr,a                 ; Any High Bit=State=Command
                jmp     CHEETAH_Sync2

;               *******************************************************
                ;  Transition 1: Listen/Command
                ;  A Value Encountered--128
;               *******************************************************




CHEETAH_State2: jnb     acc.7,CHEETAH_State3
CHEETAH_Sync2:  call    EXAR_Read1              ; The first Non-Command
                jc      CHEETAH_Sync2_Eval
                jmp     CHEETAH_X  
CHEETAH_Sync2_Eval:
                jb      acc.7,CHEETAH_Sync2     ; Except LF
                cjne    a,#ANSII_LF,CHEETAH_Tr2 ; Changes State to Data
                jmp     CHEETAH_Sync2
CHEETAH_Tr2:    mov     dptr,#chee_state
                mov     b,a
                mov     a,#CHEETAH_DATA1        ; Transition 2 Command/Data
                movx    @dptr,a
                clr     a                       ; Initialise Data Count
                inc     dptr
                movx    @dptr,a
                jmp     CHEETAH_Store1

;               *****************************************************
                ;  Transition 2: Command/Data      
                ;  A Value Encountered 0..127
;               *****************************************************



CHEETAH_State3: cjne    a,#CHEETAH_DATA1,CHEETAH_State4
CHEETAH_Sync3:  call    EXAR_Read1
                IF      DEBUG_ASCII17
                jc      CHEETAH_S3Read
                jmp     CHEETAH_X
CHEETAH_S3Read:
                ELSE
                jnc     CHEETAH_X
                ENDIF
                cjne    a,#ANSII_CR,CHEETAH_Data ; CR Causes Completion
                jmp     CHEETAH_Complete
CHEETAH_Data:
                jb      acc.7,CHEETAH_Sync3
                cjne    a,#ANSII_LF,CHEETAH_Store
                jmp     CHEETAH_Complete        ; Scarcely Possible to miss CR
CHEETAH_Store:
                mov     b,a                     ; Save Data While Accessing 
CHEETAH_Store1:                                 ; Count
                
                IF      CHEETAH_STRIP_CCHARS
                mov     a,#-32                  ; Some Scanners Deliver
                add     a,b                     ; SI, SO, STX ETX etc
                jnc     CHEETAH_Sync3
                ENDIF
                
                mov     dptr,#chee_count
                movx    a,@dptr
                inc     a
                movx    @dptr,a
                mov     dpl,a
                mov     a,b
                movx    @dptr,a
                jmp     CHEETAH_Sync3


;               *******************************************************
                ; Transition 3: Data/Completion
                ; Caused by CR
;               *******************************************************


CHEETAH_Complete:            
                mov     a,#CHEETAH_FINAL1
                mov     dptr,#chee_state
                movx    @dptr,a
                inc     dptr
                movx    a,@dptr
                jz      CHEETAH_Y       ; Transition 5 Forced by Error
                
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

                IF (BARCODE_FORMAT EQ ASCII21) OR (BARCODE_FORMAT EQ ASCII17)
                mov     r7,a
                mov     prt_field_len,a
                mov     r0,#prt_field_str
CHEETAH_StateX1:
                inc     dptr
                movx    a,@dptr
                mov     @r0,a
                inc     r0
                djnz    r7,CHEETAH_StateX1
                mov     r7,prt_field_len
                mov     r0,#prt_field_str
                mov     dptr,#tkc_currenttsr+3
CHEETAH_StateX2:
                mov     a,@r0
                movx    @dptr,a
                inc     dptr
                inc     r0
                djnz    r7,CHEETAH_StateX2
                
                ENDIF

CHEETAH_Z:
                setB    C
                ret
                


;               *****************************************************
;               A single-task system doesn't ever get here

CHEETAH_State4: cjne    a,#CHEETAH_FINAL1,CHEETAH_State5
                jmp     CHEETAH_Z       ; Advertise Unconsumed Completion

;               but future systems might
;               *****************************************************



;               ******************************************************
                ; Transition 4: Completion/Consumed
                ; Carried out by Application
;               ******************************************************
CHEETAH_Move2StateFinal2:
                
                IF      DEBUG_ASCII17
                mov     dptr,#chee_count
                movx    a,@dptr
                mov     r7,a
                mov     b,a
                mov     dph,#(chee_count+256) SHR 8
                movx    a,@dptr
                xch     a,b
                movx    @dptr,a
                xch     a,b
                mov     dph,#(chee_count+512) SHR 8
                movx    @dptr,a
CMSFDBA17:      inc     dpl
                mov     dph,#chee_count SHR 8
                movx    a,@dptr
                mov     dph,#(chee_count+256) SHR 8
                mov     b,a
                movx    a,@dptr
                xch     a,b
                movx    @dptr,a
                xch     a,b
                mov     dph,#(chee_count+512) SHR 8
                movx    @dptr,a
                djnz    r7,CMSFDBA17
                ENDIF
                
                mov     dptr,#chee_state
                mov     a,#CHEETAH_FINAL2
                movx    @dptr,a

                clr     a                
                inc     dptr
                movx    @dptr,a

                ret


CHEETAH_State5: cjne    a,#CHEETAH_FINAL2,CHEETAH_Y
CHEETAH_Cycle5: call    EXAR_Read1
                jnc     CHEETAH_X
                
                
                cjne    a,#CHEE_Stopped,CHEETAH_Cycle5

;               ******************************************************
                ; Transition 5: Consumed/Listen
                ; At CHEE_Stopped, Fall thru to CHEE_LISTEN
;               ******************************************************

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
        IF      ATARI EQ 0
        mov     a,#CHEE_COMMAND OR CHEE_ACK OR CHEE_BACKEJECT 
        ELSE
        mov     a,#CHEE_COMMAND OR CHEE_ACK 
        ENDIF
        
        jmp     EXAR_TxL
        
        
        End











