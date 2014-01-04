;******************************************************************************
;
; File     : SBUS.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the slow bus driver code.
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

;void SBS_WriteSB1 (void)
;void SBS_WriteSB2 (void)
;void SBS_Write (ACC port, B data)

;********************
; Variables + Defines
;********************

SB0	EQU 0	; driven directly by LCD driver
SB1	EQU 1	; driven by poking bits in IRAM then calling SBS_WriteSB1
SB2	EQU 2	; driven by poking bits in IRAM then calling SBS_WriteSB2
SB3	EQU 3	; driven via SOUND.ASM by calling SBS_Write

;******************************************************************************
;
; Function:	SBS_WriteSB1
; Input:        None
; Output:	None
; Preserved:	All except B
; Destroyed:	B
; Description:
;   Updates all settings on sbus port SB1. Call this after changing any bits
;   on this port.
;
;******************************************************************************
	IF VT10
	ELSE
SBS_WriteSB1:
	PUSHACC
	MOV	A,#SB1
	MOV	B,SB1data
	CALL	SBS_Write
	POP	ACC
	RET
	ENDIF
;******************************************************************************
;
; Function:	SBS_WriteSB2
; Input:        None
; Output:	None
; Preserved:	All except B
; Destroyed:	B
; Description:
;   Updates all settings on sbus port SB2. Call this after changing any bits
;   on this port.
;
;******************************************************************************
	IF VT10
	ELSE
SBS_WriteSB2:
	PUSHACC
	MOV	A,#SB2
	MOV	B,SB2data
	CALL	SBS_Write
	POP	ACC
	RET
	ENDIF
;******************************************************************************
;
; Function:	SBS_Write
; Input:	A = SBUS port, B = data
; Output:	None
; Preserved:    All except A
; Destroyed:	A
; Description:
;   Outputs the specified data to the specified sbus port.
;
;******************************************************************************

SBS_Write:
	IF VT10
	PUSHACC
	MOV	A,B
	ANL	A,#00001111b
	ORL	A,#01000000b
	MOV	P5,A		; output the data
	CLR	LCDEnableStrobe	; Clock The Strobe
	SETB	LCDEnableStrobe	;
	POP	ACC
	RET

	ELSE

	SWAP	A
	RL	A
	CALL	SYS_DisableInts
;	ANL	P4,#09Fh	; reset SBUS address
	ANL	P4,#NOT PX.1	; reset SBUS address
	ANL	P4,#NOT PX.2	; reset SBUS address
	ORL	P4,A		; set SBUS address
	MOV	P5,B		; output the data
	CLR	P4.7		; fire the...
	SETB	P4.7		; ...clock
	CALL	SYS_EnableInts
	RET

	ENDIF

;******************************* End Of SBUS.ASM ******************************
