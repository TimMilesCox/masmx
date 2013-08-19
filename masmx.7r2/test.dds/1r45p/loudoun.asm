;******************************************************************************
;
; File     : LOUDOUN.ASM
;
; Author   : Tony Park
;
; Project  : Loudoun Castle DT/Turnstile system with counter
;
; Contents : This file contains most of the bits that are unique
;		to this version of the DT code
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

lou_bodycount		VAR 	4	; variable for number of bodies
					; through the turnstiles
lou_tempbc		VAR	1	;

THROUGH_CLICK		EQU	2	; number of consecutive times
					; LOU_CheckTurnstile must see
					; the switch closed before setting
					; lou_tsclick. 1 is approx 1/15 secs

OVERFLOW_CLICK		EQU	45	; number of consecutive times
					; LOU_CheckTurnstile must see
					; the switch closed before setting
					; lou_tsjammed. 15 is approx 3 secs

LED_ON_COUNT		EQU	7	; leave the led on for about half
					; a second when the turnstile clicks

;******************************************************************************
;
; Function:	LOU_CheckTurnstile
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	A, DPTR
; Description:
;   	Checks the turnstile switch and acts if necessary
;       Debounces switch in software (sort of)
;
;******************************************************************************

LOU_CheckTurnstile:
	JNB	lou_ledon, lou_ct_checkswitch
	INC	lou_ledcount
	MOV	A, lou_ledcount
	CJNE	A, #LED_ON_COUNT, lou_ct_checkswitch

        IF      LEDS
	CALL	LED_LED3On
        ENDIF

	CLR	lou_ledon
	MOV	lou_ledcount, #0

lou_ct_checkswitch:
	MOV	A, P7 			; look at P7.3
	ANL	A, #08h                 ; mask all except bit 3
	JZ	lou_ct_switchon         ; jump if bit clear else
	MOV	lou_statecount, #0	; reset the state counter
	CLR	lou_tsjammedon		; turnstile not jammed
	RET

lou_ct_switchon:
	INC	lou_statecount		; if statecount = THROUGH_COUNT set
	MOV	A, lou_statecount       ; bit for another person arriving
	CJNE	A, #THROUGH_CLICK, lou_ct_notth
	INC	lou_littlebc

        IF      LEDS
	CALL	LED_LED3Off
        ENDIF

	SETB	lou_ledon
	RET

lou_ct_notth:
	MOV	A, lou_statecount       ; if statecount = OVERFLOW_CLICK
	CJNE	A, #OVERFLOW_CLICK, lou_ct_notov
	SETB	lou_tsjammedon		; turnstile is probably jammed on
	DEC	lou_statecount		; prevent overflow

lou_ct_notov:
	RET

;*** End of LOU_CheckTurnstile ***********************************************

;******************************************************************************
;
; Function:	LOU_CheckTurnstileClick
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	DPTR
; Description:
;   	Called from the main loop, checks if LOU_CheckTurnstile has set
;	lou_tsclick, and does the business if necessary
;
;******************************************************************************

LOU_CheckTurnstileClick:

	CALL	SYS_DisableInts

	MOV	A, lou_littlebc   	;
	JZ	lou_ctc_dontdoit	;
	MOV	lou_littlebc, #0	;

	CALL	SYS_EnableInts

	MOV	DPTR, #lou_tempbc	;
	MOVX	@DPTR, A
	CALL	MTH_LoadOp2Acc          ;

	MOV	DPTR, #lou_bodycount    ;
	CALL 	MTH_LoadOp1Long         ;

	MOV	DPTR, #lou_bodycount    ;
	CALL	MTH_AddLongs            ;
	CALL	MTH_StoreLong           ;

	MOV	DPSEL, #0
	MOV	DPTR, #aud_entry_tsclick
	CALL	AUD_AddEntry

	;MOV	DPTR, #lou_tempbc
	;MOVX	A, @DPTR
	;MOV	R3, A
;lou_ctc_beeploop:
	;CALL	SND_SynchroBeep
	;MOV	R0, #1
	;CALL	delay100ms
	;DJNZ	R3, lou_ctc_beeploop

	JMP	lou_ctc_return

lou_ctc_dontdoit:
	CALL	SYS_EnableInts

lou_ctc_return:
	RET

;*** End of LOU_CheckTurnstileClick ***********************************************


;******************************************************************************
;
; Function:	LOU_TurnstileClickSetup
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	DPTR
; Description:
;   	Sets the local variables and flags to sensible values on powerup
;
;******************************************************************************

LOU_TurnstileClickSetup:
	CLR	lou_tsjammedon
        MOV	lou_littlebc, #0
	MOV	lou_statecount, #0
	RET
