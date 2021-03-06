;******************************************************************************
;
; File     : CUTTER.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for the autocutter.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************
CUT_VERBOSE		EQU	0
USE_FUJITSUCUTTER	EQU	1
USE_OLDSCHEME		EQU	1


cutter_status   VAR     1


	IF VT10

CUT_msg_Failed:		DB 12,'Check Cutter'
CUT_msg_cutting: 	DB 12,'Cutting     '
CUT_msg_Finish: 	DB 12,'Finished Cut'
CUT_msg_cut_up: 	DB 12,'Cutting Up  '
CUT_msg_cut_down: 	DB 12,'Cutting Down'
CUT_FireCutter:		
	PUSHACC
	MOV	A,R0
	PUSHACC
	MOV	A,R1
	PUSHACC
	MOV	A,R2
	PUSHACC
	PUSHDPH
	PUSHDPL
	IF CUT_VERBOSE
	CALL	LCD_Clear
	MOV	DPTR,#CUT_msg_cutting
	CALL	LCD_DisplayStringCODE
	ENDIF
CUT_Up_Again:
	MOV	A,#CutPaper
	CALL	PortSetB
	IF CUT_VERBOSE
	CALL	LCD_Clear
	MOV	DPTR,#CUT_msg_cut_up
	CALL	LCD_DisplayStringCODE
	ENDIF
;        mov     r2,#64                 ; 64 loops does the trick
        MOV     R2,#0FFh                ; but 255 wasn't causing a problem
CUT_Up:
	MOV	R0,#50
	CALL	delay100us
	MOV	A,P8
	ANL	A,#00001000b
	JZ	CUT_Down
	DJNZ	R2,CUT_Up
	JMP	CUT_Jammed
CUT_Down:
	IF CUT_VERBOSE
	CALL	LCD_Clear
	MOV	DPTR,#CUT_msg_cut_down
	CALL	LCD_DisplayStringCODE
	ENDIF
;        mov     r2,#64                 ; 64 loops is enough, but 255
        MOV     R2,#0FFh                ; wasn't causing any problem either
CUT_Switch:
	MOV	R0,#50
	CALL	delay100us		
	MOV	A,P8
	ANL	A,#00001000b
	JNZ	CUT_Finished
	DJNZ	R2,CUT_Switch
CUT_Jammed:
	CALL	LCD_Clear
	MOV	DPTR,#CUT_msg_Failed
	CALL	LCD_DisplayStringCODE
	MOV	A,#CutPaper
	CALL	PortClrB
CUT_WaitForOK

        mov     dptr,#cutter_status     ; T,26xj99
        mov     a,#MSG_STATE_F or MSG_CUTTR_F
        movx    @dptr,a
        call    TKC_idle

        CALL    KBD_ReadKey
;        CALL    KBD_ScanKeyboard
        CJNE    A,#20,CUT_WaitForOK

        jmp     CUT_Up_Again  ; T,26xj99

;        POP     ACC          ; What is this junk doing here? T,26xj99
;        MOV     R0,A
;        POP     ACC
;        RET

CUT_Finished:
	MOV	A,#CutPaper
	CALL	PortClrB
	IF CUT_VERBOSE
	CALL	LCD_Clear
	MOV	DPTR,#CUT_msg_finish
	CALL	LCD_DisplayStringCODE
	ENDIF
	POP	DPL
	POP	DPH
	POP	ACC
	MOV	R2,A
	POP	ACC
	MOV	R1,A
	POP	ACC
	MOV	R0,A
	POP	ACC
	RET

	ELSE
	IF USE_OLDSCHEME

CUT_FireCutter:
	MOV	DPTR,#man_cutterctrl
	MOVX	A,@DPTR
	ANL	A,#1
	JZ	CUT_FCdisabled

	MOV	R7,#16
	CALL	PRT_LineFeed

;	MOV	A,P6
;	ANL	A,#254
;	MOV	P6,A
; replaced in v1.02 with the next line to stop serial port hanging
	ANL	P6,#254

	MOV	R0,#10
	CALL	delay100us		; was 300ms ; was 100ms

;	MOV	A,P6
;	ORL	A,#1
;	MOV	P6,A
; replaced in v1.02 with the next line to stop serial port hanging
	ORL	P6,#1

	MOV     R0,#2			; to stop any more printing
	CALL    delay100ms		; before cutter has finished

CUT_FCdisabled:
	RET

	ELSE

CUT_StartCutter:
	MOV	DPTR,#man_cutterctrl
	MOVX	A,@DPTR
	ANL	A,#1
	JZ	CUT_FCdisabled

	MOV	R7,#16
	CALL	PRT_LineFeed

	SETB	cdopen
	CALL	SBS_WriteSB2
	RET

CUT_FireCutter:
	JB	cdopen,CUT_FCfinish
	MOV	DPTR,#man_cutterctrl
	MOVX	A,@DPTR
	ANL	A,#1
	JZ	CUT_FCdisabled

	MOV	R7,#16
	CALL	PRT_LineFeed

	SETB	cdopen
	CALL	SBS_WriteSB2

CUT_FCfinish:
	MOV	R0,#1
	CALL	delay100ms

	IF USE_ALTONCOMMS
	 SETB	alton_sensorwait
	ENDIF

CUT_FCcheckmicro:
	IF USE_ALTONCOMMS
;;;	 CALL	TKC_Idle ;;; Taken out by SSM 25/1/99
	ENDIF

;	IF USE_ALTONCOMMS
;	 JNB	alt_specialcut,CUT_FCnosensor1
;	 CALL   CUT_CheckSensor1
;	 JC	CUT_FCnosensor1
;	 SETB	alt_bpressed
;	 CLR	alt_specialcut
;CUT_FCnosensor1:
;	ENDIF

	MOV	A,P6
	ANL	A,#1
	JZ	CUT_FCcheckmicro

	IF USE_ALTONCOMMS
	 CLR	alton_sensorwait
	ENDIF

	CLR	cdopen
	CALL	SBS_WriteSB2

	MOV     R0,#2			; to stop any more printing
	CALL    delay100ms		; before cutter has finished

	MOV	R7,#16
	CALL	PRT_LineFeed

	RET

CUT_FCdisabled:
	RET

	ENDIF

	ENDIF



;CUT_CheckSensor1:
;	MOV	A,P8
;	MOV	C,ACC.3
;	RET
;
;CUT_CheckSensor2:
;	CALL	CDR_TestCashDrawer
;	RET
;
;CUT_LockTurnstile:
;	SETB	P4.0
;	RET
;
;CUT_UnlockTurnstile:
;	CLR	P4.0
;	RET
;************************************************************************************
CUT_NewCut:
	PUSHACC
	PUSHR0
	PUSHR1
	PUSHR2

	MOV	R3,#00110011b		;Stepper Phase Bits
	MOV	A,#StepperControl	;Select Cutter
	CALL	PortSetB		;

	MOV	R2,#120
CUT_Home:
	CALL	CUT_StepDown
	MOV	R0,#20
	CALL	delay100us
	MOV	A,P8			; read P8.3 (0 = closed)
	JNB	ACC.3,CUT_EndHome	; closed? Yes, Exit
	DJNZ	R2,CUT_Home
CUT_EndHome:

	MOV	A,P8			; read P8.3 (0 = closed)
	JB	ACC.3,CUT_EndCut	; Open? Yes, Abort Cut!
	MOV	R2,#115
CUT_Cut:
	CALL	CUT_StepUp
	MOV	R0,#50
	CALL	delay100us
	DJNZ	R2,CUT_Cut
CUT_EndCut

	MOV	R2,#115
CUT_Return:
	CALL	CUT_StepDown
	MOV	A,R2
	CALL	CUT_GetDelay
	MOV	R0,A
	CALL	delay100us
	MOV	A,P8			; read P8.3 (0 = closed)
	JNB	ACC.3,CUT_EndReturn	; closed? Yes, Exit
	DJNZ	R2,CUT_Return
CUT_EndReturn
	ORL	P6,#11000000b	; set P6.7,P6.6 = 11 turns PBL3717 Off
	MOV	A,#StepperControl	;Select Printer
	CALL	PortClrB		;

	POP	2
	POP	1
	POP	0
	POP	ACC
	RET

CUT_GetDelay:
	INC	A
	MOVC	A,@A+PC
	RET

CUT_LookUpTable:	;Step Delay in 100uS 120 Entrys
	DB	25,25,25,25,25,25,25,25,25,25
	DB	24,23,22,21,20,19,18,17,16,15
	DB	14,13,12,11,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,10,10,10,10
	DB	10,10,10,10,10,10,11,12,13,14
	DB	15,16,17,18,19,20,21,22,23,24
	DB	25,25,25,25,25,25,25,25,25,25






CUT_StepDown
	MOV	A,R3
	RR	A
	mov	R3,A
	ANL	A,#030h
	ORL	P6,#00fh	; keep P6.3-P6.0 high (inputs and special function output)
	ANL	P6,#00fh	; reset P6.7-P6.4, also P6.5,P6.4 = 00 turns PBL3717 current to maximum
	ORL	P6,A		; place phase bits on P6.5,P6.4
	RET



CUT_StepUp
	MOV	A,R3
	RL	A
	mov	R3,A
	ANL	A,#030h
	ORL	P6,#00fh	; keep P6.3-P6.0 high (inputs and special function output)
	ANL	P6,#00fh	; reset P6.7-P6.4, also P6.5,P6.4 = 00 turns PBL3717 current to maximum
	ORL	P6,A		; place phase bits on P6.5,P6.4
	RET

;***************************** End Of CUTTER.ASM ******************************



