;******************************************************************************
;
; File     : SOUND.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the sound handling routines
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;***********
; Prototypes
;***********

;void SND_InitSound (void)
;void SND_Beep (ACC duration, B pitch)
;void SND_SoundOn (B pitch)
;void SND_SoundOff (void)
;void SND_Warning (void)

;******************************************************************************
;
; Function:	SND_InitSound
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Initialises the sound section.
;
;******************************************************************************

SND_InitSound:
	IF VT10			;No Pitch Control

	CLR	ET1		; disable timer 1 interrupt
	RET

	ELSE

	ORL	CMEN,#002h	; Enable compare function on CM1 (Ie., PWM)
	ORL	CMSEL,#002h	; Set CM1 to the compare timer
	MOV	CTCON,#000h	; Use fOSC/256 gives 46.875 KHz
	MOV	CMH1,#240	; volume
	MOV	CML1,#0
	MOV	CTRELH,#000h	; Start the compare timer
	MOV	CTRELL,#000h	; (Strobed start on writing CTRELL)
	CLR	ET1		; disable timer 1 interrupt
	RET

	ENDIF
;******************************************************************************
;
; Function:	SND_Beep
; Input:	A=duration, B=pitch
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Issues a beep at the specified pitch for the specified duration. Returns
;   immediately, sound will terminate automatically from interrupt shortly
;   after.
;
;******************************************************************************

SND_Beep:
	IF VT10			;No Pitch Control

	PUSHACC
	MOV	TL1,#0			; load duration into
	MOV	TH1,A			; timer 1 count reg.
	MOV	A,#OpenCollOut1
	CALL	PortSetD		;
	CLR	TF1			; ??? check this
	SETB	ET1			; allow interrupt for turning sound off
	POP	ACC
	RET

	ELSE

	MOV	TL1,#0			; load duration into
	MOV	TH1,A			; timer 1 count reg.
	MOV	A,#SB3			; set pitch
	CALL	SBS_Write		;
	CLR	TF1			; ??? check this
	SETB	ET1			; allow interrupt for turning sound off
	RET

	ENDIF
;******************************************************************************
;
; Function:	SND_SoundOn
; Input:	B=pitch
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Turns the speaker on at a specified pitch. Will stay on until turned off.
;
;******************************************************************************

SND_SoundOn:
	IF VT10			;No Pitch Control

	PUSHACC
	CLR	ET1
	MOV	A,#OpenCollOut1
	CALL	PortSetD
	POP	ACC
	RET

	ELSE

	PUSHACC
	CLR	ET1			; no interrupt driven turn-off
	MOV	A,#SB3			; set pitch
	CALL	SBS_Write		;
	POP	ACC
	RET

	ENDIF
;******************************************************************************
;
; Function:	SND_SoundOff
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Turns off any sound which may be sounding.
;
;******************************************************************************

SND_SoundOff:
	IF VT10

	PUSHACC
	CLR	ET1
	MOV	A,#OpenCollOut1
	CALL	PortSetD	
	POP	ACC
	RET

	ELSE

	CLR	ET1			; no interrupt driven turn-off
	MOV	A,#SB3			; pitch to 0
	MOV	B,#0			; (ie., no sound)
	CALL	SBS_Write		;
	RET

	ENDIF
;******************************************************************************
;
; Function:	SND_TerminateSound
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Automatically turns off sounds start with SND_Beep.
;
;******************************************************************************

SND_TerminateSound:
	IF VT10

;        PUSHACC
;        MOV     A,#OpenCollOut1
;        CALL    PortClrD
;        POP     ACC
	RETI

	ELSE

	PUSHPSW
	PUSHACC
	PUSHB
	CALL	SND_SoundOff
	POP	B
	POP	ACC
	POP	PSW
	RETI

	ENDIF
;******************************************************************************
;
; Function:	SND_Warning
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Gives the standard 3 warning bleeps.
;
;******************************************************************************

SND_LittleWarning:
	MOV	R7,#1
	JMP	SND_Wloop

SND_Warning:
	MOV	R7,#3
SND_Wloop:
	MOV	B,#100
	CALL	SND_SoundOn
	MOV	R0,#1
	CALL	delay100ms
	CALL	SND_SoundOff
	MOV	R0,#1
	CALL	delay100ms
	DJNZ	R7,SND_Wloop
	RET

;****************************** End Of SOUND.ASM ******************************
