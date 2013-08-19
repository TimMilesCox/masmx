;******************************************************************************
;
; File     : PRT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the printer driver code for the following
;            Axiohm thermal printers:
;              CLBM 192dots 12volts
;              CLAA 160dots 24volts
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************
; Constants And Options
;******************************************************************************

USE_FAST_WHITESPACE		EQU 0 ; accelerate over whitespace ?
USE_VOLTAGE_COMPENSATION	EQU 1 ; adjust density w.r.t power supply ?

; note, the input lines are now shared by each 3717, so proper halfstep
; no longer available and the values in INPUT0/1_SEQ are sort of useless.

PRT_PHASE_SEQ		EQU 0CCh
PRT_INPUT0_SEQ		EQU 000h ; FF for medium current, 00 for high current
PRT_INPUT1_SEQ		EQU 000h ; AA for halfstep (sort of), 00 for fullstep
PRT_HORIZ_DOTS		EQU 192
PRT_MAX_HORIZ_CHARS	EQU 32
PRT_LINES_PER_BITMAP	EQU 64

	IF PRT_CLAA
PRT_HORIZ_CHARS		EQU 21
	ENDIF
	IF PRT_CLBM
PRT_HORIZ_CHARS		EQU 32
	ENDIF

;******************************************************************************
; Port assignments
;******************************************************************************
	IF VT10
prt_stepper_ctrl_port	EQU P6
prt_head_clock_port	EQU P3.1 ;Inverted. IE 'Active Low'
prt_head_data_port	EQU P3.0
prt_head_strobe_port	EQU P4.0
prt_head_oe_port	EQU P4.2
prt_paper_sense		EQU ACC.4 ; comes from P7.4
	ELSE
prt_stepper_ctrl_port	EQU P6
prt_head_clock_port	EQU P1.5
prt_head_data_port	EQU P1.6
prt_head_strobe_port	EQU P1.7
prt_head_oe_port	EQU P4.2
prt_paper_sense		EQU ACC.4 ; comes from P7.4
	ENDIF
;******************************************************************************
; Variable initialisation
;******************************************************************************

 ALIGN VAR,ToPage
prt_bitmap:		VAR (PRT_MAX_HORIZ_CHARS*8*PRT_LINES_PER_BITMAP)
prt_headtemp:		VAR 1
prt_firepulse:		VAR 2
prt_density:		VAR 1
;prt_fastaverage:        VAR 2
;prt_slowaverage:        VAR 2
prt_bitmaplen:           VAR 2
FIELD_HEADER		EQU 7 ; control,width,flags,mag,x,y,len (all BYTES)

;******************************************************************************
;
;              G e n e r a l   P r i n t e r   F u n c t i o n s
;
;******************************************************************************

;******************************************************************************
;
; Function:	PRT_StartPrint
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Turns the power on to the printer circuitry and sets the head fire time and
;   motor timing pulses based upon the available battery power and the user's
;   print density and print quality settings.
;
;******************************************************************************

prt_headlookuptable: DB 24,23,21,20,19,18,17,16,15,14,14,13,12,12,11,11

PRT_StartPrint:
	MOV	A,#StepperControl	;Select Cutter
	CALL	PortClrB		;
 	MOV	A,prt_powerdelay		; turn printer
        JNZ	PRT_SPwason			; power on if
	CALL	SYS_PrinterPowerOn		; it was off
        MOV     R0,#1				;
        CALL    delay100ms			;
PRT_SPwason:					;
	MOV	prt_powerdelay,#0		;

        CALL    PRT_IssuePulse			; re-issue last phasing

	IF USE_VOLTAGE_COMPENSATION		; get battery voltage
	 CALL	SYS_ScanBatteryVolts		;

         MOV	DPTR,#sys_batteryvolts		; round it to the range
         MOVX	A,@DPTR				; 124 (19.84v) to
         CJNE	A,#124,PRT_SPne1		; 187
         JMP	PRT_SPok1			;
PRT_SPne1:					;
	 JNC	PRT_SPok1			;
         MOV	A,#124				;
PRT_SPok1:					;
	 CJNE	A,#187,PRT_SPne2		;
         JMP	PRT_SPok2			;
PRT_SPne2:					;
	 JC	PRT_SPok2			;
         MOV	A,#187				;
PRT_SPok2:					;

	 CLR	C				; shift voltage to range
         SUBB	A,#124				; from 0 to 63
         RR	A				;
         RR	A				;
         ANL	A,#03Fh				;
         MOV	DPTR,#prt_headlookuptable	; store in firepulse, the
         MOVC	A,@A+DPTR			; entry from headlookuptable
         PUSHACC				; indexed by volt*density
         MOV	DPTR,#prt_density		;
         MOVX	A,@DPTR				;
         SWAP	A				;
         MOV	B,A				;
         POP	ACC				;
         MUL	AB				;
         MOV	DPTR,#prt_firepulse		;
         MOVX	@DPTR,A				;
         INC	DPTR				;
         MOV	A,B				;
         MOVX	@DPTR,A				;

         MOV	DPTR,#prt_firepulse		; set delay2 to half the
         CALL	MTH_LoadOp1Word			; loop time needed for the
         MOV	A,#100				; previously decided head
	 CALL	MTH_LoadOp2Acc			; fire time
         CALL	MTH_Divide32by16		;
         MOV	A,mth_op1ll			;
	 CJNE	A,#11,PRT_SPmin11		;
         JMP	PRT_SPminok			;
PRT_SPmin11:					;
	 JNC	PRT_SPminok			;
         MOV	A,#11				;
PRT_SPminok:					;
	 MOV	prt_stepdelay2,A		; stepdelay2 >= 11

         CLR	C				; set delay1+transfertime to
         SUBB	A,#10				; the other half needed
         MOV	prt_stepdelay,A			; stepdelay >= 1

         MOV    A,prt_stepdelay3		; subtract delay3 from delay2
         CJNE   A,#11,PRT_SPnot11		; up to a limit of 10, to
PRT_SPtoomuch:					; alter the phasing between
	 MOV	A,#10				; the pulses and the head
         SETB	C				; firing, improving quality
PRT_SPnot11:					;
	 JNC	PRT_SPtoomuch			;
PRT_SPdelay2ok:					;
	 MOV	B,A				;
         MOV	A,prt_stepdelay2		;
         CLR	C				;
         SUBB	A,B				;
         MOV	prt_stepdelay2,A		;

	 MOV	A,prt_stepdelay3		; if quality > 10, also
         CJNE	A,#10,PRT_SPnot10		; lengthen delay1 to make
	 JMP	PRT_SPdelay1ok			; the pulses equidistant
PRT_SPnot10:					; again
	 JC	PRT_SPdelay1ok			;
         CLR	C				;
         SUBB	A,#10				;
         MOV	B,A				;
         MOV	A,prt_stepdelay			;
         ADD	A,B				;
         MOV	prt_stepdelay,A			;
PRT_SPdelay1ok:					;
        ENDIF					;
PRT_SPon:
	RET

;******************************************************************************
;
; Function:	PRT_EndPrint
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Used to tell the printer controller that we are finished using the printer
;   for just now. The printer power will be switched off up to 20 seconds later
;   if the printer is not reused.
;
;******************************************************************************

PRT_EndPrint:
	MOV	prt_powerdelay,#255
	RET

;******************************************************************************
;
;                 S t e p p e r   M o t o r   F u n c t i o n s
;
;******************************************************************************

;******************************************************************************
;
; Function:	PRT_Initialise
; Input:	R1 = phase sequence
;		R2 = input0 sequence
;		R3 = input1 sequence
; Output:	None
; Preserved:	R1-7,B
; Destroyed:	R0,A,DPTR
; Description:
;   Initialises the phase,input0 and input1 sequences
;
;******************************************************************************

PRT_Initialise:
	MOV	A,R1
	MOV	R0,#prt_phaseseq
	MOV	@R0,A			; store phase sequence
	ANL	A,#030h
	MOV	R0,#prt_phase
	MOV	@R0,A			; set phase

	MOV	A,R2
	MOV	R0,#prt_input0seq
	MOV	@R0,A			; store input0 sequence
	ANL	A,#040h
	MOV	R0,#prt_input0
	MOV	@R0,A			; set input0

	MOV	A,R3
	MOV	R0,#prt_input1seq
	MOV	@R0,A			; store input1 sequence
	ANL	A,#080h
	MOV	R0,#prt_input1
	MOV	@R0,A			; set input1

	MOV	CMH2,#0
	MOV	CML2,#0
	ANL	CMSEL,#0FBh	; set CM2 to TIMER2
	ORL	CMEN,#004h	; enable compare mode on CM2 (P4.2)
;???
	MOV	T2CON,#085h	; timer 2, no reload, internal fOSC/24 timing
				; (strictly speaking, should get by with 081h)

; should be
;	ANL	T2CON,#060h
;	ORL	T2CON,#081h	; timer 2, no reload, internal fOSC/24 timing
;changing may bugger priceplug detection or keyboard detection
	MOV	prt_powerdelay,#0
	RET

;******************************************************************************
;
; Function:	PRT_IssuePulse
; Input:	None
; Output:	None
; Preserved:	R3-7,DPTR,B
; Destroyed:	R0-2,A
; Description:
;   Outputs the current phase,input0 and input1 values to the I/O port
;   controlling the printer's stepper motor.
;
;******************************************************************************

PRT_IssuePulse:
	MOV	R0,#prt_phase
	MOV	A,@R0
	MOV	R2,A			; R2 = prt_phase
	MOV	R1,#prt_input0
	MOV	A,@R1
	MOV	R1,A			; R1 = prt_input0
	MOV	R0,#prt_input1
	MOV	A,@R0
	MOV	R0,A			; R0 = prt_input1

; v2.56 code
	ANL	prt_stepper_ctrl_port,#0Fh	;
        MOV	A,R2
	ORL	prt_stepper_ctrl_port,A	; set new phase
        MOV	A,R1
	ORL	prt_stepper_ctrl_port,A	; set new input0
        MOV	A,R0
	ORL	prt_stepper_ctrl_port,A	; set new input1
        RET

; pre v2.56 code
;	MOV	A,prt_stepper_ctrl_port	; get current settings
;	ANL	A,#0Fh			;
;	ORL	A,R0			; set new phase
;	ORL	A,R1			; set new input0
;	ORL	A,R2			; set new input1
;	MOV	prt_stepper_ctrl_port,A	; output new settings
;	RET

;******************************************************************************
;
; Function:	PRT_GeneratePulse
; Input:	None
; Output:	None
; Preserved:	R3-7, DPTR
; Destroyed:	R0-2, A
; Description:
;   Generates the next values for phase,input0 and input1 from a predefined
;   sequence, and issue them to the printer.
;
;******************************************************************************

sys_pulsecount:		VAR 4		;long

PRT_GeneratePulse:

;	PUSHR7
;	PUSHDPH
;	PUSHDPL
;	MOV	DPTR,#sys_pulsecount
;	CALL	MTH_IncLong
;	POP	DPL
;	POP	DPH
;	POP	7

	MOV	R0,#prt_phaseseq
	MOV	A,@R0
	IF PRT_CLAA
	RL	A
	ENDIF
	IF PRT_CLBM
	RR	A
	ENDIF
	MOV	@R0,A			; update phaseseq to next in sequence
	ANL	A,#030h
	MOV	R0,#prt_phase
	MOV	@R0,A			; update phase

	MOV	R0,#prt_input0seq
	MOV	A,@R0
	RL	A
	MOV	@R0,A			; update input0seq to next in sequence
	ANL	A,#040h
	MOV	R0,#prt_input0
	MOV	@R0,A			; update input0

	MOV	R0,#prt_input1seq
	MOV	A,@R0
	RL	A
	MOV	@R0,A			; update input1seq to next in sequence
	ANL	A,#080h
	MOV	R0,#prt_input1
	MOV	@R0,A			; update input1

	CALL	PRT_IssuePulse
	RET

;******************************************************************************
;
; Function:	PRT_StopMotor
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	A
; Description:
;   Stops the motor moving
;
;******************************************************************************

PRT_StopMotor:
; v2.56 code
	ORL prt_stepper_ctrl_port,#0C0h		; set 3717 driver to "No Current"
        RET

; pre v2.56 code
;	MOV A,prt_stepper_ctrl_port
;	ORL A,#0C0h			; set 3717 driver to "No Current"
;	MOV prt_stepper_ctrl_port,A
;	RET

;******************************************************************************
;
; Function:	PRT_Strobe
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Fires the printer's strobe line up and then down, thus latching the
;   printer's shift register into the internal buffer which drives the
;   heating elements.
;
;******************************************************************************

PRT_Strobe:
	SETB	prt_head_strobe_port
	CLR	prt_head_strobe_port
	RET
;******************************************************************************
;
; Function:	PRT_Clock
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;
;******************************************************************************

PRT_Clock:
	IF VT10

	CLR	prt_head_clock_port
	SETB	prt_head_clock_port

	ELSE

	SETB	prt_head_clock_port
	CLR	prt_head_clock_port

	ENDIF
	RET

;******************************************************************************
;
; Function:	PRT_FireHeads
; Input:	None
; Output:	None
; Preserved:
; Destroyed:	A, DPTR
; Description:
;   Fires the printer's output enable line for a controlled period of time.
;
;******************************************************************************

PRT_FireHeads:
	CLR	prt_head_oe_port	; prepare to turn OE on
	MOV	CMH2,#0			; cause a compare match to make the
	MOV	CML2,#0			; OE turn on
	CLR	T2I0			; stop timer 2
	MOV	TH2,#0			; reset timer 2
	MOV	TL2,#0			;
        SETB	T2I0			; re-start timer 2

        IF USE_VOLTAGE_COMPENSATION

	 MOV	DPTR,#prt_firepulse
         MOVX	A,@DPTR
         MOV	B,A
         INC	DPTR
         MOVX	A,@DPTR
         MOV	CMH2,A			; set timeout for next compare
         MOV	CML2,B

        ELSE

         MOV	DPTR,#prt_density
	 MOVX	A,@DPTR
	 MOV	CMH2,A			; set timeout for next compare
	 MOV	CML2,#0

        ENDIF

	SETB	prt_head_oe_port	; at compare, make line go high (OE off)
	RET				; at some point later, the line will
					; now go high

;******************************************************************************
;
; Function:	PRT_ScanHeadTemp
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PRT_ScanHeadTemp:
	MOV	A,ADCON0
	ANL	A,#0C0h	; keep two bits nothing to do with ADC
	MOV	ADCON0,A
	MOV	ADCON1,#06h
	MOV	DAPR,#0
	NOP
	NOP
	NOP
	NOP
	NOP
PRT_SHTwait:
	JB	0DCh,PRT_SHTwait
	MOV	A,ADDAT
	MOV	DPTR,#prt_headtemp
	MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	PRT_TransferLine
; Input:	DPTR = address of (half)line to shift
; Output:	DPTR = address of next (half)line to shift
; Preserved:	R2-R7
; Destroyed:	R0,R1,A
; Description:
;   Transfers a full dotline to the printer's shift register (CLAA or DT10W).
;   Transfers half a dotline to the printer's shift register (CLBM).
;
; Note:
;   DT10s with CLAA printers use 126 dots of the 128 available.
;   DT10s with CLBM printers (never used) use all 192 available dots.
;   Non-barcode wristbanders use narrow bands which have 64 printable dots.
;   barcode wristbanders use wider bands which have 80 printable dots.
;
;******************************************************************************

PRT_TransferLine:
        IF DT10W				; transfer out any blank
	 IF USE_NARROWBAND			; dots that are required
	  MOV	R0,#6				; before the bitmap starts
	  ;MOV	R0,#33				; before the bitmap starts
	 ELSE					;
	  MOV	R0,#6				; on a DT10W-Narrow this is 6
	 ENDIF					; on a DT10W-Wide this is 6
	ELSE					; on a DT10-CLAA this is 1
	 IF PRT_CLAA				; on a DT10-CLBM this is 0
	  MOV	R0,#1				;
	 ELSE					;
	  MOV	R0,#0				;
	 ENDIF
	ENDIF					;
	MOV	A,R0				;
	JZ	PRT_TLnoloop1			;
	CLR	prt_head_data_port		;
PRT_TLloop1:					;
	NOP					;
	NOP
	CALL	PRT_Clock					;
	DJNZ	R0,PRT_TLloop1			;
PRT_TLnoloop1:					;

        IF DT10W				; transfer out a single
         IF USE_NARROWBAND			; line of dots
          MOV	R0,#8				; on a DT10W-NARROW this is
         ELSE					;   8 chars of 8 pixels
          MOV	R0,#10				;
         ENDIF					; on a DT10W-WIDE this is
        ELSE					;   10 chars of 8 pixels
 	 IF PRT_CLAA				;
	  MOV	R0,#21				;
	 ENDIF					; on a DT10-CLAA this is
	 IF PRT_CLBM				;   21 chars of 6 pixels
	  MOV	R0,#16				;
	 ENDIF					; on a DT10-CLBM this is
        ENDIF					;   16 chars of 6 pixels
PRT_TLloopa:					;
	MOVX	A,@DPTR				;
	ORL	prt_zerodetect,A		;
	INC	DPTR				;
        IF DT10W				;
         MOV	R1,#8				;
        ELSE					;
	 MOV	R1,#6				;
        ENDIF					;
PRT_TLloopb:
	RLC	A				;
	MOV	prt_head_data_port,C		;
	CALL	PRT_Clock					;
	DJNZ	R1,PRT_TLloopb			;
	DJNZ	R0,PRT_TLloopa			;

	IF DT10W				; transfer out any blank
	 IF USE_NARROWBAND			; dots that are required
	  MOV	R0,#58				; after the bitmap ends
	  ;MOV	R0,#33				; after the bitmap ends
	 ELSE					;
	  MOV	R0,#42				; on a DT10W-Narrow this is 58
	 ENDIF					; on a DT10W-Wide this is 42
	ELSE ; DT10/DT5				; on a DT10-CLAA this is 1
	 IF PRT_CLAA				; on a DT10-CLBM this is 0
	  MOV 	R0,#1				;
	 ELSE					;
	  MOV	R0,#0				;
	 ENDIF					;
	ENDIF					;
	MOV	A,R0				;
	JZ	PRT_TLnoloop2			;
	CLR	prt_head_data_port		;
PRT_TLloop2:					;
	NOP					;
	NOP					;
	CALL	PRT_Clock					;
	DJNZ	R0,PRT_TLloop2			;
PRT_TLnoloop2:					;

	IF DT10W				; correct the bitmap pointer
	 IF USE_NARROWBAND			; so that it is looking at
	  MOV	A,#216 ; -40 to DPTR		; the next line in the bitmap
	  MOV	B,#255				;
	 ELSE					; on a DT10W-Narrow the bitmap
	  MOV	A,#214 ; -42 to DPTR		; is backwards, so rewind the
	  MOV	B,#255				; 8 bytes we used plus another
	 ENDIF					; 32 to get onto the next line
	ELSE ; DT5/DT10				;
	 IF PRT_CLAA				; on a DT10W-Wide, rewind the
	  MOV	A,#11				; 10 we used, plus another 32
	  MOV	B,#0				;
	 ELSE					; on a DT10-CLAA 21 of the 32
	  MOV	A,#0				; chars are used, so skip 11
	  MOV	B,#0				;
	 ENDIF					; on a DT10-CLBM all 32 are
	ENDIF					; used, so skip 0
	CALL	AddABtoDPTR			;
	RET

;******************************************************************************
;
; Function:	PRT_PrintBitmap
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Prints the ticket previously setup by PRT_FormatBitmap
;
;******************************************************************************

PRT_PrintBitmap:
	IF USE_SERVANT
	 CALL	COM_StopStatusTransmit
	ENDIF

	MOV	A,prt_outputdevice
	JZ	PRT_PBcarryon
	JMP	PRT_PBdone

PRT_PBcarryon:
	MOV	prt_zerodetect,#0
	CALL	PRT_SkipPerf

	CALL	PRT_GetBitmapLen		; len in R6:R7
	MOV	DPTR,#prt_bitmap		; start of bitmap

	IF DT10W				; if wristbander
	 MOV	A,R6				; move pointer to end
	 ANL	A,#7				; of bitmap since
	 SWAP	A				; wristbander bitmaps
	 RL	A				; are printed reversed
	 MOV	B,A				;
	 MOV	A,R7				;
	 SWAP	A				;
	 RL	A				;
	 ANL	A,#31				;
	 ORL	A,B				;
	 MOV	B,A				;
	 MOV	A,R7				;
	 SWAP	A				;
	 RL	A				;
	 ANL	A,#0E0h				;
	 CALL	AddABtoDPTR			;
	 MOV	A,#224 ; -32 to DPTR		;
	 MOV	B,#255				;
	 CALL	AddABtoDPTR			;
	ENDIF

	MOV	A,R7				; adjust length
	JZ	PRT_PBok			; to suit double
	INC	R6				; DJNZ loop
PRT_PBok:

PRT_PBloop:
;	JB	prt_paperout,PRT_PBend		; abort if paper out
	CALL	PRT_GeneratePulse		; 1st pulse
	CALL	PRT_CheckPaper			;
	CALL	PRT_TransferLine		; transfer dots

	MOV	R0,prt_stepdelay
	CALL	delay100us

;	CALL	PRT_LineFeedDelay
;
;	MOV	A,prt_stepdelay
;	CJNE	A,#PULSE_LENGTH,PRT_PBne1
;PRT_PBe1:
;	JMP	PRT_PBnextpulse
;PRT_PBne1:
;	JC	PRT_PBe1
;
;	CALL	PRT_StopMotor
;	SUBB	A,#PULSE_LENGTH
;	MOV	R0,A
;	CALL	delay100us
;
;PRT_PBnextpulse:

	CALL	PRT_GeneratePulse		; 2nd pulse
	CALL	PRT_CheckPaper			;
	IF DT10W
	ELSE
	IF PRT_CLBM				;
	 CALL	PRT_TransferLine		; transfer dots
	ENDIF					;
	ENDIF

	MOV	A,prt_stepdelay3
	JZ	PRT_PBnodelay3
	MOV	R0,A
	CALL	delay100us
PRT_PBnodelay3:

;	CALL	PRT_LineFeedDelay
;
;	MOV	A,prt_stepdelay3
;	CJNE	A,#PULSE_LENGTH,PRT_PBne3
;PRT_PBe3:
;	JMP	PRT_PBstrobe
;PRT_PBne3:
;	JC	PRT_PBe3
;
;	CALL	PRT_StopMotor
;	SUBB	A,#PULSE_LENGTH
;	MOV	R0,A
;	CALL	delay100us
;
;PRT_PBstrobe:
;	CALL	PRT_StopMotor

	CALL	PRT_Strobe			; fire the heads
	PUSHDPH				;
	PUSHDPL				;
	CALL	PRT_FireHeads			;
	POP	DPL				;
	POP	DPH				;

	MOV	R0,prt_stepdelay2		;
	CALL	delay100us			; and delay

	CALL    PRT_SkipPerf

	MOV     prt_zerodetect,#0

	DJNZ	R7,PRT_PBloop			; repeat for all lines
	DJNZ	R6,PRT_PBloop			;
PRT_PBend:
	CALL	PRT_StopMotor			; kill the motor
	MOV     C,prt_paperout
PRT_PBdone:

	IF USE_SERVANT
	 CALL	COM_StartStatusTransmit
	ENDIF

	RET

;***************************** End Of PRT_CLBM.ASM ****************************

PRT_FeedTest:
	CALL	PRT_StartPrint
ft_again:
	MOV	R7,#128
ft_loop:
	JB	prt_paperout,ft_end

	CALL	PRT_GeneratePulse
	CALL	PRT_CheckPaper
	MOV	R0,prt_stepdelay
	CALL	delay10us

	CALL	PRT_GeneratePulse
	CALL	PRT_CheckPaper
	MOV	R0,prt_stepdelay
	CALL	delay10us

	DJNZ    R7,ft_loop

ft_readkey:
        CALL    KBD_WaitKey
        CJNE    A,#KBD_CANCEL,ft_notcancel
ft_end:
        CALL	PRT_EndPrint
        RET
ft_notcancel:
        CJNE    A,#KBD_OK,ft_notok
        JMP     ft_again
ft_notok:
        CJNE    A,#KBD_UP,ft_notup
        INC	prt_stepdelay
        MOV	A,prt_stepdelay
;        CALL	DBG_TxChar
        JMP	ft_again
ft_notup:
        CJNE    A,#KBD_DOWN,ft_notdown
        DEC	prt_stepdelay
        MOV	A,prt_stepdelay
;        CALL	DBG_TxChar
        JMP	ft_again
ft_notdown:
        JMP     ft_readkey


;PRT_DetectPaper:
;	PUSHDPH
;        PUSHDPL
;        MOV	A,R7
;        PUSHACC
;
;	MOV	A,ADCON0
;	ANL	A,#0C0h	; keep two bits nothing to do with ADC
;	MOV	ADCON0,A
;	MOV	ADCON1,#04h
;	MOV	DAPR,#0
;	NOP
;	NOP
;	NOP
;	NOP
;	NOP
;PRT_DPwait:
;	JB	0DCh,PRT_DPwait
;        MOV     R2,ADDAT
;
;        MOV     DPTR,#prt_fastaverage
;        CALL    MTH_LoadOp1Word
;        MOV     A,#7
;        CALL    MTH_LoadOp2Acc
;        CALL    MTH_Multiply32by16
;        CLR     A
;        CALL    MTH_LoadOp2Acc
;        MOV     mth_op2lh,R2		; op2 = sample.256
;        CALL	MTH_AddLongs
;        MOV	A,#8
;        CALL	MTH_LoadOp2Acc
;        CALL	MTH_Divide32by16
;        MOV	DPTR,#prt_fastaverage
;        CALL	MTH_StoreWord
;
;        MOV     DPTR,#prt_slowaverage
;        CALL    MTH_LoadOp1Word
;        MOV     A,#255
;        CALL    MTH_LoadOp2Acc
;        CALL    MTH_Multiply32by16
;        CLR     A
;        CALL    MTH_LoadOp2Acc
;        MOV     mth_op2lh,R2		; op2 = sample.256
;        CALL	MTH_AddLongs
;        CLR	A
;        CALL	MTH_LoadOp2Acc
;        MOV	mth_op2lh,#1		; op2 = 256
;        CALL	MTH_Divide32by16
;        MOV	DPTR,#prt_slowaverage
;        CALL	MTH_StoreWord
;
;;DEBUG
;	MOV	A,R2
;	CALL	DBG_TxChar
;        MOV	DPTR,#prt_fastaverage+1
;        MOVX	A,@DPTR
;	CALL	DBG_TxChar
;        MOV	DPTR,#prt_slowaverage+1
;        MOVX	A,@DPTR
;	CALL	DBG_TxChar
;
;	POP	ACC
;        MOV	R7,A
;
;        MOV     DPTR,#prt_fastaverage+1
;        MOVX    A,@DPTR
;        MOV     B,A
;        MOV     DPTR,#prt_slowaverage+1
;        MOVX    A,@DPTR
;        POP	DPL
;        POP	DPH
;        ADD	A,#5
;        CJNE    A,B,PRT_DPcheck
;PRT_DPblack:
;	SETB	C
;	RET
;PRT_DPcheck:
;	JC	PRT_DPblack
;        CLR	C
;	RET
;****************************************************************************
PRT_On:
	PUSHACC
	MOV	A,#PrinterOn
	CALL	PortSetB
	POP	ACC
	RET
;*****************************************************************************
PRT_OFF:
	PUSHACC
	MOV	A,#PrinterOn
	CALL	PortClrB
	POP	ACC
	RET
;*****************************************************************************
PRT_SetFeed:
	PUSHACC
	MOV	A,#StepperControl
	CALL	PortClrB
	POP	ACC
	RET
;*****************************************************************************
PRT_SetCutter:
	PUSHACC
	MOV	A,#StepperControl
	CALL	PortSetB
	POP	ACC
	RET
;*****************************************************************************
