cdr_cdinput	EQU P7.3 ; high=closed

CDR_GetEnableStatus:
	MOV	DPTR,#man_drawerenable
        MOVX	A,@DPTR
	RET

;******************************************************************************
;
; Function:	CDR_OpenCashDrawer
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

CDR_OpenCashDrawer:
	CALL	CDR_GetEnableStatus
        ANL	A,#6
	JZ	CDR_OCDdisabled
	SETB	cdopen
;	CALL	SBS_WriteSB2
	MOV	R0,#4
	CALL	delay100ms
	CLR	cdopen
;	CALL	SBS_WriteSB2
CDR_OCDdisabled:
	RET

;******************************************************************************
;
; Function:	CDR_TestCashDrawer
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

CDR_TestCashDrawer:
	MOV	bP7,P7
	MOV	C,cdr_cdinput
	RET

;****************************** End Of CDRAWER.ASM ****************************
