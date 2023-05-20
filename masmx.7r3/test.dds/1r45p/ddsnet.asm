;******************************************************************************
;
; File     : DDSNET.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the DDSNET network definitions and DDSNET
;            level 2 handling code.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

; System Messages

MSG_ANA EQU 255
MSG_TST EQU 254
MSG_SSL EQU 253
MSG_SND EQU 252

; DT Messages

MSG_SSR EQU 128
MSG_SSI EQU 128
MSG_MBR EQU 129
MSG_MBD EQU 129
MSG_MBW EQU 130
MSG_ATR EQU 131
MSG_ARR EQU 132
MSG_ARD EQU 132
MSG_AMT EQU 133
MSG_STN EQU 135
MSG_SSN EQU 136
MSG_PST EQU 137

MSG_RAMREPORT   EQU 138
MSG_RAMSET      EQU 139
MSG_RAMSNAP     EQU 140

MSG_iRAMREPORT  EQU 141
MSG_iRAMSET     EQU 142
MSG_iRAMSNAP    EQU 143

MSG_RS232START  EQU 144

MSG_FINDSTRING  EQU 145
MSG_XMITP7      EQU 146

; RealTime Ticketing Application Messages

MSG_TSR EQU 64
MSG_TSF EQU 65
MSG_TSI EQU 66
MSG_TPI EQU 67
MSG_TSC EQU 68
MSG_TSD EQU 69
MSG_SUM EQU 70

MSG_CRT EQU 71 ; alton comms messages
MSG_TKS EQU 72 ;
MSG_PO  EQU 73 ;
MSG_PLOW EQU 74

; Generic Applications Messages

MSG_IDL EQU 2
MSG_GRQ EQU 1

;*******************************************************************************

NODE_ID_INSTALL         EQU 255
NODE_ID_ALLNODES        EQU 254
NODE_ID_ALLTS           EQU 253
NODE_ID_ALLDT           EQU 252
NODE_ID_ALLST           EQU 251

NODE_TYPE_TS            EQU 1
NODE_TYPE_DT            EQU 2
NODE_TYPE_TT            EQU 3
NODE_TYPE_ST            EQU 4

NET_ReceivePacketEx:
	MOV     R6,#20
NET_RPXtryagain:
	CALL    RS485_ReceivePacket
	JNZ     NET_RPsyscheck

	MOV     R0,#100
	CALL    delay100us
	DJNZ    R6,NET_RPXtryagain
	RET

NET_ReceivePacket:
	MOV     DPTR,#buffer

	CALL    RS485_ReceivePacket
	JNZ     NET_RPpktIn

	CALL    RS232_ReceivePacket
	JNZ     NET_RPpktIn

	JMP     NET_RPnopkt

NET_RPpktIn:
	mov     prt_field_len, a        ; save the interface number
	MOV     DPTR,#buffer+5
	MOVX    A,@DPTR

;**************************
; Check For System Messages
;**************************
NET_RPsyscheck:
	CJNE    A,#MSG_ANA,NET_RPnotauto
	JMP     NET_AutoResponse
NET_RPnotauto:
	CJNE    A,#MSG_TST,NET_RPnottest
	JMP     NET_TestComms
NET_RPnottest:
	CJNE    A,#MSG_SSL,NET_RPnotssl
	JMP     NET_SetSerial
NET_RPnotssl:
	CJNE    A,#MSG_SND,NET_RPnotsnd
	JMP     NET_SetNode
NET_RPnotsnd:
	CJNE    A,#MSG_RAMREPORT,NET_RPnotRamReport
	jmp     NET_RamReport
NET_RPnotRamReport:
	CJNE    A,#MSG_RAMSET,NET_RPnotRamSet
	jmp     NET_RamSet
NET_RPnotRamSet:
	CJNE    A,#MSG_RAMSNAP,NET_RPnotRamSnap
	jmp     NET_RamSnap
NET_RPnotRamSnap:
	CJNE    A,#MSG_iRAMREPORT,NET_RPnotiRamReport
	jmp     NET_iRamReport
NET_RPnotiRamReport:
	CJNE    A,#MSG_iRAMSET,NET_RPnotiRamSet
	jmp     NET_iRamSet
NET_RPnotiRamSet:
	CJNE    A,#MSG_iRAMSNAP,NET_RPnotiRamSnap
	jmp     NET_iRamSnap
NET_RPnotiRamSnap:
	CJNE    A,#MSG_RS232START,NET_RPnotRS232Start
	jmp     NET_RS232Start
NET_RPnotRS232Start:
	CJNE    a,#MSG_FINDSTRING,NET_RPnotFindString
	jmp     NET_FindXRAMString
NET_RPnotFindString:
	cjne    a,#MSG_XMITP7,NET_RPnotXMITP7
	jmp     NET_XmitP7
NET_RPnotXMITP7:
NET_RPnopkt:

	RET             ; return A=msg type for application to check

;*********************
; System Message - SND
;*********************

NET_SetNode:
	MOV     DPTR,#buffer+6                  ; ignore if its
	MOVX    A,@DPTR                         ; not for a DT
	CJNE    A,#NODE_TYPE_DT,NET_SNnotme     ;

	MOV     DPTR,#buffer+7                  ; ignore if its
	CALL    MEM_SetSource                   ; for a different
	MOV     DPTR,#sys_dtserial              ; serial number
	CALL    MEM_SetDest                     ; of machine
	MOV     R7,#4                           ;
NET_SNloop:                                     ;
	MOV     DPH,srcDPH                      ;
	MOV     DPL,srcDPL                      ;
	MOVX    A,@DPTR                         ;
	MOV     B,A                             ;
	INC     DPTR                            ;
	MOV     srcDPH,DPH                      ;
	MOV     srcDPL,DPL                      ;
	MOV     DPH,destDPH                     ;
	MOV     DPL,destDPL                     ;
	MOVX    A,@DPTR                         ;
	INC     DPTR                            ;
	MOV     destDPH,DPH                     ;
	MOV     destDPL,DPL                     ;
	CJNE    A,B,NET_SNnotme                 ;
	DJNZ    R7,NET_SNloop                   ;

	MOV     DPTR,#buffer+11                 ; its for me, save
	MOVX    A,@DPTR                         ; the node information
	MOV     sys_mynode,A                    ; in EE storage
	CALL    SYS_WriteUnitInfo               ;
	ANL     A,#1                            ;
	XRL     A,#1                            ;
	MOV     DPTR,#buffer+6                  ;
	MOVX    @DPTR,A                         ; send the reply indicating
	MOV     DPTR,#buffer+5                  ; whether we successfully
	MOV     R7,#2                           ; stored our new node id
	CALL    DDSNET_TransmitPacket            ;
NET_SNnotme:
	CLR     A
	RET

;******************************
; System Message - AUTORESPONSE
;******************************

NET_AutoResponse:
	MOV     DPTR,#buffer+6
	MOVX    A,@DPTR
	CJNE    A,#NODE_TYPE_DT,NET_ARnotme
	MOV     DPTR,#buffer+11
	MOVX    A,@DPTR
	MOV     sys_mynode,A

	MOV     DPTR,#sys_dtserial
	CALL    MEM_SetDest
	MOV     DPTR,#buffer+7
	CALL    MEM_SetSource
	MOV     R7,#4
	CALL    MEM_CopyXRAMtoXRAMsmall

	CALL    SYS_WriteUnitInfo
	ANL     A,#1
	XRL     A,#1
	MOV     DPTR,#buffer+6
	MOVX    @DPTR,A
	MOV     DPTR,#buffer+5
	MOV     R7,#2
	CALL    DDSNET_TransmitPacket
NET_ARnotme:
	CLR     A
	RET

;***************************
; System Message - TESTCOMMS
;***************************

NET_TestComms:
	MOV     DPTR,#buffer+6
	MOV     A,sys_mynode
	XRL     A,#255
	MOVX    @DPTR,A

	MOV     DPTR,#buffer+5
	MOV     R7,#2
	CALL    DDSNET_TransmitPacket
	CLR     A
	RET

;*********************
; System Message - SSL
;*********************

NET_SetSerial:
	MOV     DPTR,#buffer+6
	CALL    MEM_SetSource
	MOV     DPTR,#sys_dtserial
	CALL    MEM_SetDest
	MOV     R7,#4
	CALL    MEM_CopyXRAMtoXRAMsmall
	CALL    SYS_WriteUnitInfo
	MOV     DPTR,#buffer+6
	ANL     A,#1
	XRL     A,#1
	MOVX    @DPTR,A
	MOV     R7,#2
	MOV     DPTR,#buffer+5
	CALL    DDSNET_TransmitPacket
	CLR     A
	RET

;***************************************************************
; System Message - RamReport                         T,15x99
;***************************************************************

NET_RamReport:
	inc     dptr                    ; move on from message type
	movx    a,@dptr                 ; load address upper
	mov     b,a                     ; set aside
	inc     dptr                    ; move on
	movx    a,@dptr                 ; load address lower
	mov     dpl,a                   ;
	mov     dph,b                   ; retrieve address upper
	movx    a,@dptr                 ; read target location
	mov     dptr,#buffer+8          ; write after address field
	movx    @dptr,a                 ; in original messsage buffer
	mov     r7,#4                   ; message_type + address[2] + value
	mov     dptr,#buffer+5          ; send back the same message
	CALL    DDSNET_TransmitPacket    ; plus one byte
	clr     a
	ret

;***************************************************************
; System Message - RamSet                         T,19x99
;***************************************************************

NET_RamSet:
	inc     dptr                    ; move on from message type
	movx    a,@dptr                 ; load address upper
	mov     b,a                     ; set aside
	inc     dptr                    ; move on
	movx    a,@dptr                 ; load address lower
	push    acc                     ; set aside
	inc     dptr                    ; move on
	movx    a,@dptr                 ; read store value
	pop     dpl                     ; retrieve address lower
	mov     dph,b                   ; retrieve address upper
	movx    @dptr,a                 ; write intended value
	mov     r7,#4                   ; message_type + address[2] + value
	mov     dptr,#buffer+5          ; scan back to message type
	CALL    DDSNET_TransmitPacket     
	clr     a
	ret

;***************************************************************
; System Message - RamSnap                         T,19x99
; NB This forces dpsel=0 and leaves it that way
;***************************************************************

NET_RamSnap:                            

	mov     dpsel,#0                ; make no external assumption

	mov     dptr,#buffer+6
	movx    a,@dptr                 ; read address upper
	mov     b,a                     ; set aside
	inc     dptr                    ; move on
	movx    a,@dptr                 ; read address lower


	push    acc                     ; set aside
	inc     dptr                    ; move on
	movx    a,@dptr                 ; read byte count
	pop     dpl                     ; retrieve address lower
	mov     dph,b                   ; retrieve address upper
	mov     b,a                     ; set aside the byte count
	add     a,#4                    ; and convert it to a message length
	mov     r7,a                    ; + message_type + address[2] + bcount

	mov     dpsel,#1                ; assume normal operation was dptr0
;        push    dph                     ; borrow dptr1
;        push    dpl                     ; appears to be used dynamically
	mov     dptr,#buffer+9          ; as string pointer into message buff

NET_RamSnapL1:
	mov     dpsel,#0                ; point to the target data 
	movx    a,@dptr                 ; read it
	inc     dptr                    ; advance
	mov     dpsel,#1                ; point to the message area
	movx    @dptr,a                 ; write it
	inc     dptr                    ; advance
	djnz    b,NET_RamSnapL1         ; loop
;        pop     dpl                     ; restore dptr1
;        pop     dph                     ; appears to be used dynamically
	mov     dpsel,#0

	mov     dptr,#buffer+5
	CALL    DDSNET_TransmitPacket
	clr     a
	ret

;***************************************************************
; System Message - iRamReport                         T,15x99
;***************************************************************

NET_iRamReport:
	inc     dptr                    ; move on from message type
	movx    a,@dptr                 ; load address
	mov     r0,a                    ; cursor
	inc     dptr                    ; move on
	mov     a,@r0                   ; read target value
	movx    @dptr,a                 ; into original messsage buffer
	mov     r7,#3                   ; message_type + address[1] + value
	mov     dptr,#buffer+5          ; send back the same message
	CALL    DDSNET_TransmitPacket    ; plus one byte
	clr     a
	ret

;***************************************************************
; System Message - iRamSet                         T,19x99
;***************************************************************

NET_iRamSet:
	inc     dptr                    ; move on from message type
	movx    a,@dptr                 ; load address
	mov     r0,a                    ; cursor
	inc     dptr                    ; move on
	movx    a,@dptr                 ; read store value
	mov     @r0,a                   ; write intended value
	mov     r7,#3                   ; message_type + address[1] + value
	mov     dptr,#buffer+5          ; scan back to message type
	CALL    DDSNET_TransmitPacket     
	clr     a
	ret

;***************************************************************
; System Message - iRamSnap                         T,19x99
;***************************************************************

NET_iRamSnap:                            

	inc     dptr                    ; move on from message type
	movx    a,@dptr                 ; read address
	mov     r0,a                    ; cursor
	inc     dptr                    ; move on
	movx    a,@dptr                 ; read byte count
	inc     dptr                    ; move to message readout area
	mov     b,a                     ; set aside the byte count
	add     a,#3                    ; and convert it to a message length
	mov     r7,a                    ; + message_type + address[1] + bcount

NET_iRamSnapL1:
	mov     a,@r0                   ; read iram
	inc     r0                      ; advance
	movx    @dptr,a                 ; write message buffer
	inc     dptr                    ; advance
	djnz    b,NET_iRamSnapL1        ; loop

	mov     dptr,#buffer+5
	CALL    DDSNET_TransmitPacket
	clr     a
	ret

NET_RS232Start:
	call    KBD_InitKeyBoard
	call    COM_InitSerial
	call    COM_InitRS485
	call    SYS_EnableInts
	call    SYS_ReadUnitInfo
	call    TIM_InitialiseClock
	call    EXAR_Start
	mov     r7,#1
	mov     dptr,#buffer+5
	call    DDSNET_TransmitPacket
	
	if      exar_barcode_application
	call    CHEETAH_Initial
	endif

	clr     a
	ret

NET_FindXRAMString:
	mov     dptr,#buffer+2
	movx    a,@dptr
	add     a,#-3
	mov     prt_field_len,a
	mov     r7,a
	
	mov     dptr,#buffer+6           ; Read Search Start Address
	movx    a,@dptr
	push    acc
	inc     dptr
	movx    a,@dptr
	push    acc                     ; Search Start Address on Stack
	mov     r0,#prt_field_str
NET_fXRAMsL1:
	inc     dptr
	movx    a,@dptr
	mov     @r0,a
	inc     r0
	djnz    r7,NET_fXRAMsL1         ; Search String in IRAM
	pop     dpl
	pop     dph                     ; Stack Clear
NET_fXRAMsL2:
	mov     r7,prt_field_len
	push    dph
	push    dpl                     ; Search Address on Stack
	mov     r0,#prt_field_str

NET_fXRAMsL3:        
	movx    a,@dptr
	xrl     a,@r0
	jnz     NET_fXRAMsL4            ; Unequal Location within String
	inc     dptr
	inc     r0
	djnz    r7,NET_fXRAMsL3
	pop     b                       ; Hit! Retrieve Search LS Address
	pop     acc                     ; Stack Clear;  Search MS Address
	mov     dptr,#buffer+6
	movx    @dptr,a                 ; Return with Address Bytes
	inc     dptr
	mov     a,b
	movx    @dptr,a
	mov     r7,#3
	jmp     NET_fXRAMsX

NET_fXRAMsL4:        
	pop     dpl                     ; Stack Clear
	pop     dph
	inc     dptr
	mov     a,dph
	orl     a,dpl
	jnz     NET_fXRAMsL2
	mov     r7,#1                   ; Return without Address Bytes
	
NET_fXRAMsX:
	mov     dptr,#buffer+5
	call    DDSNET_TransmitPacket
	clr     a
	ret

NET_XmitP7:
	mov     dptr,#buffer+6
	mov     a,P7
	movx    @dptr,a
	mov     R7,#2
	mov     dptr,#buffer+5
	call    DDSNET_TransmitPacket
	clr     a
	ret

DDSNET_TransmitPacket:
NET_TransmitPacket:
	mov     a, prt_field_len
	cjne    a, #2, NOT_RS232_TransmitPacket
	jmp     RS232_TransmitPacket
NOT_RS232_TransmitPacket:
	jmp     RS485_TransmitPacket

;******************************* End Of DDSNET.ASM ****************************/
;
	END





