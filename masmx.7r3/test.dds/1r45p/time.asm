;*******************************************************************************
;
; File     : TIME.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the date/time handling routines
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
;*******************************************************************************

olddatebuffer:	VAR 2
oldtimebuffer:	VAR 2

;******************************************************************************
;
; Function:	TIM_FormatDate
; Input:	DPTR1 = where to store date string in XRAM
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the ASCII representation of the default date to the specified
;   8 character buffer.
;
;******************************************************************************

TIM_FormatDate:
	MOV	DPSEL,#0
	MOV	DPTR,#datebuffer
	CALL	TIM_FormatDateCustom
	RET

;******************************************************************************
;
; Function:	TIM_FormatDateCustom
; Input:	DPTR1 = where to store date string in XRAM
;		DPTR0 = address of date/time stamp.
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the ASCII representation of the specified date to the specified
;   8 character buffer.
;
;******************************************************************************

TIM_FormatDay: ; DPTR0=datestamp, DPTR1=buffer
	MOV	DPSEL,#0		; get the days
	MOVX	A,@DPTR			;
	RR	A			;
	RR	A			;
	RR	A			;
	ANL	A,#01Fh			;
	MOV	B,A			;
	MOV	R5,#2+NUM_ZEROPAD	;
	CALL	NUM_NewFormatDecimalB	; output 2 digit days
        INC	DPTR
        INC	DPTR
        RET

TIM_FormatMonth: ; DPTR0=datestamp, DPTR1=buffer
	MOV	DPSEL,#0		; get the months
	PUSHDPH				;
        PUSHDPL				;
	MOVX	A,@DPTR			;
	ANL	A,#7			;
	RL	A			;
	MOV	B,A			;
	INC	DPTR			;
	MOVX	A,@DPTR			;
        POP	DPL			;
        POP	DPH			;
	RL	A			;
	ANL	A,#1			;
	ORL	A,B			;
	MOV	B,A			;
	MOV	R5,#2+NUM_ZEROPAD	;
	CALL	NUM_NewFormatDecimalB	; output 2 digit months
	INC	DPTR			;
	INC	DPTR			;
        RET

TIM_FormatYear: ; DPTR0=datestamp, DPTR1=buffer
	MOV	DPSEL,#0		; get the year
	PUSHDPH
        PUSHDPL
        INC	DPTR
	MOVX	A,@DPTR			;
	POP	DPL
	POP	DPH
	ANL	A,#07Fh			;
	MOV	B,A			;
	MOV	R5,#2+NUM_ZEROPAD	;
	CALL	NUM_NewFormatDecimalB	; output 2 digit years
	RET

TIM_FormatDateCustom:
	PUSHDPH
	PUSHDPL
	MOV	DPTR,#man_dateformat
	MOVX	A,@DPTR
	POP	DPL
	POP	DPH
	JNZ	TIM_FDCuseusa
	CALL	TIM_FormatDay
	MOV	A,#'/'			; output a "/"
	MOVX	@DPTR,A			;
	INC	DPTR			;
	CALL	TIM_FormatMonth
	JMP	TIM_FDCdate
TIM_FDCuseusa:
	CALL	TIM_FormatMonth
	MOV	A,#'/'			; output a "/"
	MOVX	@DPTR,A			;
	INC	DPTR			;
	CALL	TIM_FormatDay
TIM_FDCdate:
	MOV	A,#'/'			; output a "/"
	MOVX	@DPTR,A			;
	INC	DPTR			;
	CALL	TIM_FormatYear
	RET

;******************************************************************************
;
; Function:	TIM_FormatTime
; Input:	DPTR1 = where to store time string in XRAM
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the ASCII representation of the default time to the specified
;   5 character buffer.
;
;******************************************************************************

TIM_FormatTime:
;	PUSHR3
	MOV	A,R3
	PUSHACC
;	PUSHR4
	MOV	A,R4
	PUSHACC
	MOV	R3,#0
	MOV	R4,#0
	MOV	DPSEL,#0
	MOV	DPTR,#datebuffer+2
	CALL	TIM_FormatTimeCustom
;	POP	4
	POP	ACC
	MOV	R4,A
;	POP	3
	POP	ACC
	MOV	R3,A
	RET

TIM_FormatAdjustedTime:
	MOV	DPSEL,#0
	MOV	DPTR,#datebuffer+2
	CALL	TIM_FormatTimeCustom
	RET

;******************************************************************************
;
; Function:	TIM_FormatTimeCustom
; Input:	DPTR1 = where to store time string in XRAM
;               DPTR0 = address of date/time stamp.
;		R3 = hours to add
;		R4 = minutes to add
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the ASCII representation of the specified time to the specified
;   5 character buffer.
;
;******************************************************************************

TIM_FormatTimeCustom:
;	PUSHR5
	MOV	A,R5
	PUSHACC
;	PUSHR6
	MOV	A,R6
	PUSHACC

	MOV	DPSEL,#0		; get the hours
	MOVX	A,@DPTR			;
	ANL	A,#7			;
	INC	DPTR			;
	RL	A			;
	RL	A			;
	MOV	B,A			;
	MOVX	A,@DPTR			;
	ANL	A,#0C0h			;
	RL	A			;
	RL	A			;
	ORL	A,B			;
	MOV	R5,A			; store hours for later

	MOVX	A,@DPTR			; get the minutes
	ANL	A,#63			;

	ADD	A, R4			; add extra minutes
	CJNE	A, #60, TIM1		; check for carry
TIM1:	JC	TIM_FTCok               ;
	INC	R5			; add an hour
	SUBB	A, #60			; correct minutes

TIM_FTCok:
	PUSHACC				; save minutes

	MOV	A, R5			;
	ADD	A, R3                   ; add extra hours
	CJNE	A, #24, TIM2		; check for carry
TIM2:	JC	TIM_FTCok2		;
	SUBB	A, #24			; correct hour

TIM_FTCok2:
; minutes on stack, hours in ACC, DPTR1 buffer
	MOV	B,A
	MOV	DPTR,#man_dateformat
	MOVX	A,@DPTR
	JNZ	TIM_FTusatime

	MOV	R5,#2+NUM_ZEROPAD	;
	MOV	DPSEL,#1		;
	CALL	NUM_NewFormatDecimalB	; output 2 digit hours (zero padded)

	INC	DPTR			;
	INC	DPTR			;
	MOV	A,#':'			; output a ":"
	MOVX	@DPTR,A			;
	INC	DPTR			;

	POP	ACC
	MOV	B, A
	MOV	R5,#2+NUM_ZEROPAD	;
	MOV	DPSEL,#1		;
	CALL	NUM_NewFormatDecimalB	; output 2 digit minutes
	INC	DPTR
	INC	DPTR
	MOV	A,#' '
	MOVX	@DPTR,A
	INC	DPTR
	MOVX	@DPTR,A

;	POP	6
	POP	ACC
	MOV	R6,A
;	POP	5
	POP	ACC
	MOV	R5,A
	RET

TIM_FTusatime:
; minutes on stack, hours in B, DPTR1 buffer
	POP ACC
	PUSHB
	PUSHACC

	MOV	A,B			; convert hours to 12hr format
	ADD	A,#11			;
	CALL	MTH_LoadOp1Acc		;
	MOV	A,#12			;
	CALL	MTH_LoadOp2Acc		;
	CALL	MTH_Divide32by16	;
	MOV	A,mth_op2ll		;
	INC	A			;
	MOV	B,A			;

	MOV	R5,#2			;
	MOV	DPSEL,#1		;
	CALL	NUM_NewFormatDecimalB	; output 2 digit hours (space pad)

	INC	DPTR			;
	INC	DPTR			;
	MOV	A,#':'			; output a ":"
	MOVX	@DPTR,A			;
	INC	DPTR			;

	POP	ACC			; retrieve minutes
	MOV	B, A
	MOV	R5,#2+NUM_ZEROPAD	;
	MOV	DPSEL,#1		;
	CALL	NUM_NewFormatDecimalB	; output 2 digit minutes
	INC	DPTR
	INC	DPTR

	POP	ACC			; retrieve hours
	CLR	C
	MOV	B,A
	MOV	A,#11
	SUBB	A,B
	JC	TIM_FTpm
	MOV	A,#'a'
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#'m'
	MOVX	@DPTR,A
	INC	DPTR
	JMP     TIM_FTtimedone
TIM_FTpm:
	MOV	A,#'p'
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#'m'
	MOVX	@DPTR,A
	INC	DPTR
TIM_FTtimedone:
	POP	6
	POP	5
	RET

;******************************************************************************
;
; Function:	TIM_DisplayDate
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_curdate: DB 255,21,0,0,0,0,21,'Current Date DD/MM/YY'
TIM_DisplayDate:
	MOV	DPTR,#msg_curdate
	CALL	MEM_SetSource
	MOV	DPTR,#buffer
	CALL	MEM_SetDest
	MOV	R7,#FIELD_HEADER+21
	CALL	MEM_CopyCODEtoXRAM
	CALL	TIM_GetDateTime
	MOV	DPSEL,#1
	MOV	DPTR,#buffer+FIELD_HEADER+13
	CALL	TIM_FormatDate
	IF DT5
	 CALL	PRT_StartPrint
	 CALL	DisplayOneLiner
	 CALL	PRT_EndPrint
        ELSE
	 CALL	LCD_Clear
	 MOV	DPTR,#buffer+7
	 MOV	R7,#21
	 CALL	LCD_DisplayStringXRAM
	ENDIF
	RET

;******************************************************************************
;
; Function:	TIM_DisplayTime
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_curtime: DB 255,18,0,0,0,0,18,'Current Time HH:MM'
TIM_DisplayTime:
	MOV	DPTR,#msg_curtime
	CALL	MEM_SetSource
	MOV	DPTR,#buffer
	CALL	MEM_SetDest
	MOV	R7,#FIELD_HEADER+18
	CALL	MEM_CopyCODEtoXRAM
	CALL	TIM_GetDateTime
	MOV	DPSEL,#1
	MOV	DPTR,#buffer+FIELD_HEADER+13
	CALL	TIM_FormatTime
	IF DT5
	 CALL	PRT_StartPrint
	 CALL	DisplayOneLiner
	 CALL	PRT_EndPrint
        ELSE
	 CALL	LCD_Clear
	 MOV	DPTR,#buffer+7
	 MOV	R7,#18
	 CALL	LCD_DisplayStringXRAM
	ENDIF
	RET

;******************************************************************************
;
; Function:	TIM_ChangeDate
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_getdate: 	DB 255,20,0,0,0,0,20,'Enter date as ddmmyy'
msg_getdateusa:	DB 255,20,0,0,0,0,20,'Enter date as mmddyy'

msg_newdate: DB 10,'New Date: '

TIM_ChangeDate:
	MOV	A,#SYS_AREA_SETDATE
	CALL	SYS_SetAreaCode
	CALL	TIM_DisplayDate
	MOV	DPTR,#datebuffer
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#olddatebuffer
	CALL	MTH_StoreLong

	IF DT5

	 CALL	PRT_StartPrint

	 MOV	DPTR,#man_dateformat
	 MOVX	A,@DPTR
	 JNZ	TIM_CDusamessage
	 MOV	DPTR,#msg_getdate
	 JMP	TIM_CDprintmessage
TIM_CDusamessage:
	 MOV	DPTR, #msg_getdateusa
TIM_CDprintmessage:
	 CALL	PRT_DisplayMessageCODE
	 CALL	PRT_MessageFeed
	 CALL	PRT_EndPrint

	ELSE

	 MOV	A,#64
	 CALL	LCD_GotoXY
	 MOV	DPTR,#msg_newdate
	 CALL	LCD_DisplayStringCODE

	ENDIF

	MOV	B,#74
	MOV     R7,#6
	CALL	NUM_GetNumber
	JZ	TIM_CDabort
	MOV	DPTR,#buffer
	CALL	MTH_StoreLong
	MOV	DPTR,#buffer
	CALL	TIM_SetDate
	CALL    TIM_GetDateTime
	MOV	DPSEL,#0
;	MOV	DPTR,#aud_entry_changedate
;	CALL	AUD_AddEntry
TIM_CDabort:
	IF DT5
	 CALL	TIM_DisplayDate
	 CALL	PRT_StartPrint
	 CALL	PRT_FormFeed
	 CALL	PRT_EndPrint
        ELSE
	 CALL	LCD_Clear
	 SETB	tim_timerupdate
	ENDIF
	RET

;******************************************************************************
;
; Function:	TIM_ChangeTime
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_gettime: DB 255,18,0,0,0,0,18,'Enter time as hhmm'
msg_newtime: DB 10,'New Time: '
TIM_ChangeTime:
	MOV	A,#SYS_AREA_SETTIME
	CALL	SYS_SetAreaCode
	CALL	TIM_DisplayTime
        MOV	DPTR,#datebuffer
        CALL	MTH_LoadOp1Long
	MOV	DPTR,#olddatebuffer
        CALL	MTH_StoreLong
	IF DT5
	 CALL	PRT_StartPrint
	 MOV	DPTR,#msg_gettime
	 CALL	PRT_DisplayMessageCODE
	 CALL	PRT_MessageFeed
	 CALL	PRT_EndPrint
        ELSE
	 MOV	A,#64
	 CALL	LCD_GotoXY
	 MOV	DPTR,#msg_newtime
	 CALL	LCD_DisplayStringCODE
	ENDIF
	MOV	B,#74
        MOV     R7,#4
	CALL	NUM_GetNumber
	JZ	TIM_CTabort
	MOV	DPTR,#buffer
	CALL	MTH_StoreLong
	MOV	DPTR,#buffer
	CALL	TIM_SetTime
        CALL    TIM_GetDateTime
        MOV	DPSEL,#0
;        MOV	DPTR,#aud_entry_changetime
;        CALL	AUD_AddEntry
TIM_CTabort:
	IF DT5
	 CALL	TIM_DisplayTime
	 CALL	PRT_StartPrint
	 CALL	PRT_FormFeed
	 CALL	PRT_EndPrint
        ELSE
	 CALL	LCD_Clear
	 SETB	tim_timerupdate
	ENDIF
	RET


tim_batlowmsg:	DB 8,'LOWPOWER'
tim_message:	DB 8,'Ready...'
;******************************************************************************
;
; Function:	TIM_ForceDisplayDateTime
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
TIM_ForceDisplayDateTime:
	SETB	tim_timerupdate
        SETB	tim_timerenabled
        ; fall thru to next routine

;******************************************************************************
;
; Function:	TIM_DisplayDateTime
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
msg_node:		DB 'Node '


TIM_DisplayDateTime:
	IF USE_ALTONCOMMS
	 JNB	tim_timerupdate,TIM_DDTok
	 JNB	tim_timerenabled,TIM_DDTok
	 CLR	tim_timerupdate
	 CALL	LCD_Clear			; display message
	 MOV	DPTR,#tim_message		;
	 CALL	LCD_DisplayStringCODE		;
	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	DPTR,#msg_node
	CALL	MEM_SetSource
	MOV	DPTR,#buffer
	CALL	MEM_SetDest
	MOV	R7,#5
	CALL	MEM_CopyCODEtoXRAMsmall
	MOV	DPSEL,#1
	MOV	DPTR,#buffer+5
	MOV	R5,#2
	MOV	DPSEL,#0
	MOV	DPTR,#sys_nodeno
	CALL	NUM_NewFormatDecimal8

	MOV	DPTR,#buffer
	MOV	R7,#7
	CALL	LCD_DisplayStringXRAM

	ELSE
	IF DT5
	ELSE
	 JNB	tim_timerupdate,TIM_DDTok
	 JNB	tim_timerenabled,TIM_DDTok
	 CALL	TIM_GetDateTime
	 MOV	DPSEL,#1
	 MOV	DPTR,#buffer
	 CALL	TIM_FormatDate
	 MOV	DPSEL,#1
	 MOV	DPTR,#buffer+8
	 CALL	TIM_FormatTime
	 MOV	A,#0
	 CALL	LCD_GotoXY
	 MOV	R7,#8
	 MOV	DPTR,#buffer
	 CALL	LCD_DisplayStringXRAM

;	MOV	A,#10
;	CALL	LCD_GotoXY
;	MOV	DPSEL,#0
;	MOV	DPTR,#sys_pulsecount
;	MOV	DPSEL,#1
;	MOV	DPTR,#buffer
;	MOV	R5,#8+NUM_ZEROPAD
;	CALL	NUM_NewFormatDecimal32
;	MOV	R7,#8
;	CALL	LCD_DisplayStringXRAM

	 MOV	A,#19
	 CALL	LCD_GotoXY
	 MOV	R7,#5
	 CALL	LCD_DisplayStringXRAM
	 CLR	tim_timerupdate

	 JNB     sys_batlowwarn,TIM_DDTok
	 MOV     A,#0
	 CALL    LCD_GotoXY
	 MOV     DPTR,#tim_batlowmsg
	 CALL    LCD_DisplayStringCODE
	ENDIF ;DT5
	ENDIF ;USE_ALTONCOMMS
TIM_DDTok:
	RET

;******************************* End Of TIME.ASM *******************************
