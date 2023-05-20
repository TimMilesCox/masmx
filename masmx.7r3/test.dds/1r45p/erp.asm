;******************************************************************************
;
; File     : ERP.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the driver for the external receipt printer
;            Currently this is the Able Systems AP842 thermal rs232 printer.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************
;
; Function:	ERP_TxStrIRAM
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

ERP_TxStrIRAM:
	MOV	A,@R0
        CJNE	A,#127,ERP_TSInotpoundsign
        MOV	A,#156
        JMP	ERP_TSItx
ERP_TSInotpoundsign:
        CLR	C
        SUBB	A,#32
        JC	ERP_TSIillegal
        MOV	A,@R0
        JMP	ERP_TSItx
ERP_TSIillegal:
	MOV	A,#'.'
ERP_TSItx:
	INC	R0
        CALL	COM_TxChar
        DJNZ	R7,ERP_TxStrIRAM
        RET

;******************************************************************************
;
; Function:	ERP_CR
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

ERP_CR:
	MOV	A,#13
        CALL	COM_TxChar
;        MOV	A,#10
;        CALL	COM_TxChar

	IF USE_SERVANT
	 CALL	COM_StartStatusTransmit
	ENDIF

	RET

;******************************************************************************
;
; Function:	ERP_FormFeed
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

ERP_FormFeed:
	MOV	A,prt_outputdevice
	RR	A
        ANL	A,#3
	MOV	B,A
;	MOV	A,#27
;        CALL	COM_TxChar
;        MOV	A,#'J'
;        CALL	COM_TxChar
;        MOV	A,#120
;        CALL	COM_TxChar
	CALL	ERP_CR
	CALL	ERP_CR
	CALL	ERP_CR
	CALL	ERP_CR
        CALL	ERP_CR
        CALL	ERP_CR
        MOV	A,#11	; VTAB for AP800
        CALL	COM_TxChar

	IF USE_SERVANT
	 CALL	COM_StartStatusTransmit
	ENDIF

	RET

ERP_Abort:
	MOV	A,prt_outputdevice
	RR	A
	ANL	A,#3
	MOV	B,A
	MOV	A,#24	; CAN for AP800
	CALL	COM_TxChar

	IF USE_SERVANT
	 CALL	COM_StartStatusTransmit
	ENDIF

	RET

;******************************* End Of ERP.ASM ********************************
