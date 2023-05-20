;******************************************************************************
;
; File     : CUSTDISP.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the customer display routines for the following
;            displays:
;                       Point 2 Point CD5220
;                       Puritron Technology ICD-2002
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

DIS_P2P		EQU 0 ; point 2 point display
DIS_PUR		EQU 1 ; old puritron display
DIS_PUR2	EQU 2 ; new puritron display

;******************************************************************************
;
; Function:	DIS_Tx
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

DIS_Tx:
	CALL	COM_TxChar
        RET

;******************************************************************************
;
; Function:	DIS_GetDisplayType
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

DIS_GetDisplayType:
	PUSHDPH
        PUSHDPL
	MOV	DPTR,#man_custdisptype
        MOVX	A,@DPTR
        POP	DPL
        POP	DPH
        RET

;******************************************************************************
;
; Function:	DIS_Init
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

dis_p2p_init:	DB 2,27,'@'			; point 2 point display
dis_pur_init:	DB 7,27,'=','2',27,'E',058h,'4'	; puritron display

DIS_Init:
	CALL	DIS_TestExist
	JNC	DIS_Idone
	CALL	DIS_GetDisplayType
	CJNE	A,#DIS_P2P,DIS_Inotp2p
DIS_likep2p:
	MOV	DPTR,#dis_p2p_init
	JMP     DIS_Iclear
DIS_Inotp2p:
	CJNE	A,#DIS_PUR,DIS_likep2p
	MOV	DPTR,#dis_pur_init
DIS_Iclear:
	CALL	DIS_DisplayStringCODE
        CALL    testdelay
	CALL	DIS_Clear
        CALL    testdelay
DIS_Idone:
	RET

;******************************************************************************
;
; Function:	DIS_TextExist
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Returns C=1 if display enabled. Also returns B=serialport to use.
;
;******************************************************************************

DIS_TestExist:
	PUSHDPH
	PUSHDPL
        PUSHACC
        MOV	DPTR,#man_custdispctrl
        MOVX	A,@DPTR
	RR	A
        ANL	A,#3
        MOV	B,A
        MOVX	A,@DPTR
        MOV     C,ACC.0
        POP	ACC
        POP	DPL
	POP	DPH

	CLR C
	RET

;******************************************************************************
;
; Function:	DIS_DisplayStringXRAM
; Input:	DPTR=address of string in XRAM, R7 = number of chars
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

DIS_DisplayStringXRAM:
	CALL	DIS_TestExist
        JNC	DIS_DSXdone
	MOVX	A,@DPTR
	INC	DPTR
	CJNE	A,#127,DIS_DSXok
        CALL    DIS_GetDisplayType
	CJNE    A,#DIS_P2P,DIS_DSXnotp2p
	MOV	A,#163				; p2p code for œ
        JMP	DIS_DSXok
DIS_DSXnotp2p:
        MOV     A,#156				; puritron code for œ
DIS_DSXok:
	CALL	DIS_Tx
	DJNZ	R7,DIS_DisplayStringXRAM
DIS_DSXdone:
	RET

;******************************************************************************
;
; Function:	DIS_DisplayStringCODE
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

DIS_DisplayStringCODE:
	CALL	DIS_TestExist
        JNC	DIS_DSCdone
        CLR	A
	MOVC	A,@A+DPTR
	MOV	R7,A
	JZ	DIS_DSCdone
DIS_DSCloop:
	INC	DPTR
	CLR	A
	MOVC	A,@A+DPTR
	CJNE	A,#127,DIS_DSCok
        CALL    DIS_GetDisplayType
	CJNE    A,#DIS_P2P,DIS_DSCnotp2p
	MOV	A,#163				; p2p code for œ
        JMP	DIS_DSCok
DIS_DSCnotp2p:
        MOV     A,#156				; puritron code for œ
DIS_DSCok:
	CALL	DIS_Tx
	DJNZ	R7,DIS_DSCloop
DIS_DSCdone:
	RET

;******************************************************************************
;
; Function:	DIS_Clear
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

DIS_Clear:
	CALL	DIS_TestExist
        JNC	DIS_Cdone
	MOV	A,#12				; suits p2p and puri
        CALL	DIS_Tx
        RET
DIS_Cdone:
        RET

;******************************************************************************
;
; Function:	DIS_Clear1
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

dis_p2p_clear1:	DB 3,11,24,13
dis_pur_clear1:	DB 8,27,'E',055h,'3',27,'E',055h,'4'

DIS_Clear1:
	CALL	DIS_TestExist
	JNC	DIS_DSXdone
	CALL	DIS_GetDisplayType
	CJNE	A,#DIS_P2P,DIS_C1notp2p
DIS_C1likep2p:
	MOV	DPTR,#dis_p2p_clear1
	JMP	DIS_C1go
DIS_C1notp2p:
	CJNE	A,#DIS_PUR,DIS_C1likep2p
	MOV	DPTR,#dis_pur_clear1
DIS_C1go:
	CALL	DIS_DisplayStringCODE
        RET

;******************************************************************************
;
; Function:	DIS_Clear2
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

dis_p2p_clear2:	DB 3,64,24,13
dis_pur_clear2:	DB 8,27,'E',044h,'3',27,'E',044h,'4'

DIS_Clear2:
	CALL	DIS_TestExist
	JNC	DIS_DSXdone
	CALL	DIS_GetDisplayType
	CJNE	A,#DIS_P2P,DIS_C2notp2p
DIS_C2likep2p:
	MOV	DPTR,#dis_p2p_clear2
	JMP	DIS_C2go
DIS_C2notp2p:
	CJNE	A,#DIS_PUR,DIS_C2likep2p
	MOV	DPTR,#dis_pur_clear2
DIS_C2go:
	CALL	DIS_DisplayStringCODE
        RET

;******************************************************************************
;
; Function:	DIS_GotoXY
; Input:	A=(y,x) position. Y in high 2 bits, X in bottom 6 bits
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Moves the current cursor position on the customer display.
;
;******************************************************************************

DIS_GotoXY:
	CALL	DIS_TestExist
	JC	DIS_DSXcarryon1
	JMP	DIS_DSXdone
DIS_DSXcarryon1:
	PUSHACC
	CALL	DIS_GetDisplayType
	CJNE	A,#DIS_P2P,DIS_GXYnotp2p
DIS_GXYlikep2p:
	POP     ACC
        PUSHACC					; point to point display
        MOV	A,#27
        CALL	DIS_Tx
        MOV	A,#'l'
        CALL	DIS_Tx
        POP     ACC
        PUSHACC
        ANL	A,#63
        INC     A
        CALL	DIS_Tx
        POP     ACC
        SWAP	A
        RR	A
	RR	A
        ANL	A,#3
        INC     A
        CALL	DIS_Tx
	RET

DIS_GXYnotp2p:					; assume puri for now
	CJNE	A,#DIS_PUR,DIS_GXYlikep2p
	POP	ACC
	PUSHACC
	MOV	A,#27
	CALL	DIS_Tx
	MOV	A,#'C'
	CALL	DIS_Tx
	POP	ACC
	PUSHACC
	ANL	A,#0C0h
	MOV	R0,#055h
	JZ	DIS_GXYrowok
	MOV	R0,#044h
DIS_GXYrowok:
	MOV	A,R0
        CALL	DIS_Tx
        POP	ACC
        ANL	A,#63
        INC	A
        CALL	DIS_Tx
	RET

;******************************************************************************
;
;    H i g h   L e v e l   C u s t o m e r   D i s p l a y   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	DIS_IdleMessage
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Displays the idle message when there is nothing else to display on the
;   customer display. The idle message is defined in the manager config.
;
;******************************************************************************

DIS_IdleMessage:
	CALL	DIS_TestExist
        JNC	DIS_IMdone

        CLR	A
        CALL	DIS_GotoXY
	MOV	DPTR,#man_cd_idle_line1
        MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
        JZ	DIS_IMskipline1
        PUSHACC
        CALL	DIS_DisplayStringXRAM
        POP	ACC
DIS_IMskipline1:
        MOV	R7,A
        MOV	A,#20
        CLR	C
	SUBB	A,R7
        JZ      DIS_IMskip1
        MOV	R7,A
DIS_IMloop:
	MOV	A,#' '
	CALL	DIS_Tx
        DJNZ	R7,DIS_IMloop

DIS_IMskip1:
	MOV	A,#64
        CALL	DIS_GotoXY
        MOV	DPTR,#man_cd_idle_line2
	MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
        JZ	DIS_IMskipline2
	PUSHACC
        CALL	DIS_DisplayStringXRAM
        POP	ACC
DIS_IMskipline2:
        MOV	R7,A
        MOV	A,#20
        CLR	C
        SUBB	A,R7
        JZ      DIS_IMskip2
        MOV	R7,A
DIS_IMloop2:
	MOV	A,#' '
	CALL	DIS_Tx
        DJNZ	R7,DIS_IMloop2
DIS_IMskip2:
DIS_IMdone:
	RET

;******************************************************************************
;
; Function:	DIS_PowerOffMessage
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Displays the power off message.
;   The power off message is defined in the manager config.
;
;******************************************************************************

DIS_PowerOffMessage:
	CALL	DIS_TestExist
        JNC	DIS_POMdone
	CALL	DIS_Clear
        CLR	A
        CALL	DIS_GotoXY
	MOV	DPTR,#man_cd_poweroff_line1
        MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
        JZ	DIS_POMskip1
        CALL	DIS_DisplayStringXRAM
DIS_POMskip1:
	MOV	A,#64
        CALL	DIS_GotoXY
        MOV	DPTR,#man_cd_poweroff_line2
        MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
	JZ	DIS_POMskip2
        CALL	DIS_DisplayStringXRAM
DIS_POMskip2:
DIS_POMdone:
	RET

;******************************************************************************
;
; Function:	DIS_PowerOnMessage
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Displays the power on message.
;   The power on message is defined in the manager config.
;
;******************************************************************************

DIS_PowerOnMessage:
	CALL	DIS_TestExist
        JNC	DIS_POnMdone
	CALL	DIS_Clear
        CLR	A
        CALL	DIS_GotoXY
	MOV	DPTR,#man_cd_poweron_line1
        MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
        JZ	DIS_POnMskip1
        CALL	DIS_DisplayStringXRAM
DIS_POnMskip1:
	MOV	A,#64
	CALL	DIS_GotoXY
        MOV	DPTR,#man_cd_poweron_line2
        MOVX	A,@DPTR
        INC	DPTR
        MOV	R7,A
        JZ	DIS_POnMskip2
        CALL	DIS_DisplayStringXRAM
DIS_POnMskip2:
DIS_POnMdone:
	RET

;**************************** End Of CUSTDISP.ASM *****************************
