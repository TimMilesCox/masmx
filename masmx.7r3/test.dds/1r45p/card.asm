;******************************************************************************
;
; File     : CARD.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains driver code for reading magnetic cards.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

CRD_COM	EQU 0				; set to 0 (COM0) or 1 (COM1)

CRD_SetRxPort:
	PUSHDPH
        PUSHDPL
        PUSHACC
        MOV	DPTR,#man_cardctrl
        MOVX	A,@DPTR
        RR	A
        ANL	A,#3
        MOV	B,A
        POP	ACC
        POP	DPL
        POP	DPH
        RET
CRD_Rx:					; define card reader
	CALL	CRD_SetRxPort	; MOV B,#CRD_COM ; serial port functions
	JMP	COM_RxChar		;
CRD_RxTimeout:				;
	CALL	CRD_SetRxPort	; MOV B,#CRD_COM ; serial port functions
        JMP	COM_RxCharTimeout	;
CRD_Flush:				;
	CALL	CRD_SetRxPort	; MOV B,#CRD_COM ; serial port functions
	JMP	COM_Flush		;

crd_buffer: VAR 30			; credit card number buffer
crd_cardnum:    DB 6,'Card: '
crd_msgaccept:  DB 13,'Card Accepted'

;******************************************************************************
;
; Function:	CRD_ClearCardNumber
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
CRD_ClearCardNumber:
	MOV	DPTR,#crd_buffer
        MOV	R7,#30
        MOV	A,#32
        CALL	MEM_FillXRAMsmall
	RET

;******************************************************************************
;
; Function:	CRD_DetectCard
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
CRD_DetectCard:
	MOV	DPTR,#man_cardctrl	; check if card reading enabled
        MOVX	A,@DPTR			;
        ANL     A,#1
        JZ	CRD_DCnorx		;

	CALL	CRD_Rx
	JNC	CRD_DCnorx
	ANL	A,#127
	CJNE	A,#'>',CRD_DCnotforwards
	JMP	CRD_DCgotcard
CRD_DCnotforwards:
	CJNE	A,#'<',CRD_DCnorx
CRD_DCgotcard:
	MOV	R0,#10
        CALL	delay100us

	CALL	CRD_Rx			; look for a header 'B'
	JNC	CRD_DCinvalid		;
	ANL	A,#127			;
	CJNE	A,#'B',CRD_DCinvalid	;

	MOV	R7,#16
	MOV	DPTR,#crd_buffer
CRD_DCloop:
	MOV	R5,#2
	CALL	CRD_RxTimeout
	JNC	CRD_DCinvalid
 	ANL	A,#127
	CJNE	A,#'0',CRD_DCne1	; check received char between
CRD_DCge1:				; 0 and 9
	JMP	CRD_DCvalid1		;
CRD_DCne1:				;
	JNC	CRD_DCge1		;
	JMP	CRD_DCinvalid		;
CRD_DCvalid1:				;
	CJNE	A,#'9',CRD_DCne2	;
CRD_DCle2:				;
	JMP	CRD_DCvalid2		;
CRD_DCne2:				;
	JC	CRD_DCle2		;
	JMP	CRD_DCinvalid		;
CRD_DCvalid2:				;
	MOVX	@DPTR,A
	INC	DPTR
	DJNZ	R7,CRD_Dcloop
	CALL	CRD_Rx			; look for an end 'D'
	JNC	CRD_DCinvalid		;
	ANL	A,#127			;
	CJNE	A,#'D',CRD_DCinvalid	;

	CLR	A			; flush remaining chars
CRD_DCflsh:				; if more than 15
	CALL	CRD_Rx			; there must be an error
	JNC	CRD_DCflushed		;
	INC	A			;
	JMP	CRD_DCflsh		;
CRD_DCflushed:				;
	ANL	A,#15			;
	JNZ	CRD_DCinvalid		;
	CALL	CRD_CardAccepted
CRD_DCnorx:
	RET

msg_crd_invalid: DB 12,'Invalid Card'
CRD_DCinvalid:
	CALL	CRD_Flush
	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	DPTR,#msg_crd_invalid
	CALL	LCD_DisplayStringCODE

        IF      SPEAKER
        CALL    SND_Warning
        ENDIF

	CALL	LCD_Clear2
	RET

;******************************************************************************
;
; Function:	CRD_CardAccepted
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
CRD_CardAccepted:
	CALL	CRD_Flush
        CALL    LCD_Clear2
	MOV	A,#64
	CALL	LCD_GotoXY
        MOV     DPTR,#crd_cardnum
        CALL    LCD_DisplayStringCODE
	MOV	DPTR,#crd_buffer
	MOV	R7,#16
	CALL	LCD_DisplayStringXRAM

        CALL	DIS_Clear1
        MOV	A,#0
        CALL	DIS_GotoXY
        MOV	DPTR,#crd_msgaccept
        CALL	DIS_DisplayStringCODE
;        JMP     DT_KeyOk
	RET

;******************************* End Of CARD.ASM ******************************
