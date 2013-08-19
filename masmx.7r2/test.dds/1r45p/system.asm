;******************************************************************************
;
; File     : SYSTEM.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains various routines relating to bootup, watchdog,
;            resets, power lines, battery monitoring etc.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

SYS_BATFAIL	EQU	124 ; 19.84 volts
SYS_BATLOW      EQU     140 ; 22.40 volts
SYS_BATOK       EQU     148 ; 23.68 volts

;*** Reserved RAM locations ***

SYS_MEM_POWERFAIL	EQU 07fffh
SYS_MEM_AREACODE	EQU 07ffeh

;*** Area Codes (Diagnostics) ***

SYS_AREA_UNITOFF	EQU 0
SYS_AREA_COLDBOOT	EQU 128
SYS_AREA_WARMBOOT	EQU 129
SYS_AREA_MAINLOOP	EQU 3
SYS_AREA_CLM_MAIN	EQU 9
SYS_AREA_PRINTTICKET	EQU 10
SYS_AREA_ISSUETICKET	EQU 11
SYS_AREA_MENUTICKET	EQU 12
SYS_AREA_WAYBILL	EQU 20
SYS_AREA_AUDITROLL	EQU 21
SYS_AREA_SPOTCHECK	EQU 22
SYS_AREA_SETDATE	EQU 23
SYS_AREA_SETTIME	EQU 24
SYS_AREA_SETDENSITY	EQU 25
SYS_AREA_SETQUALITY	EQU 26
SYS_AREA_VOIDSELECT     EQU 30
SYS_AREA_VOIDPRINT      EQU 31
SYS_AREA_RECEIPTSELECT	EQU 32
SYS_AREA_RECEIPTPRINT	EQU 33

;***

sys_batteryvolts:	VAR 1
sys_batteryvolts16:	VAR 2
sys_batterytemp:	VAR 1
sys_timeout:		VAR 1
sys_reset:		VAR 1

;******************************************************************************
;
; Function:	SYS_ReadSystemStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_ReadSystemStats:
	CLR	F0
        SETB	F1
	MOV	R1,#EE_SLAVE
        MOV	DPTR,#EE_STATS_POWER
        CALL	MEM_SetSource
        MOV	DPTR,#sys_stats_power
        CALL	MEM_SetDest
        MOV	R7,#(SYS_STATS_ITEMS*4)
        CALL	MEM_CopyEEtoXRAMsmall
        RET

;******************************************************************************
;
; Function:	SYS_UpdateStat
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_UpdateStat: ; srcDPTR = xram stat, DPTR = dest stat in EE
        CALL    MEM_SetDest
        MOV     DPH,srcDPH
        MOV     DPL,srcDPL
        CALL    MTH_IncLong
        MOV     R7,#4
        MOV     R1,#EE_SLAVE
	CLR     F0
        SETB    F1
        CALL    SYS_DisableInts
        CALL    MEM_CopyXRAMtoEEsmall
        CALL    SYS_EnableInts
        RET

SYS_STATS_ITEMS EQU 11
sys_stats_power:	VAR 4
sys_stats_manualreset:	VAR 4
sys_stats_wdogreset:	VAR 4
sys_stats_crashreset:	VAR 4
sys_stats_ppinserts:	VAR 4
sys_stats_pperrors:	VAR 4
sys_stats_tickets:	VAR 4
sys_stats_powerfail:	VAR 4
sys_stats_timeout:	VAR 4
sys_stats_uploads:	VAR 4
sys_stats_downloads:	VAR 4

;*******************************************************************************

sys_unitinfo:	VAR 2 ; checksum for this block
sys_dtserial:	VAR 4 ; the serial number of this node
sys_nodeno:	VAR 1 ; the network node number of this node

SYS_ReadUnitInfo:
	MOV	DPTR,#EE_UNITINFO	; read the checksummed
        CALL	MEM_SetSource		; serial number and node
        MOV	DPTR,#sys_unitinfo	; number into XRAM
        CALL	MEM_SetDest		;
        MOV	R1,#EE_SLAVE		;
	MOV	R7,#7			;
	SETB	F1			;
        CALL	MEM_CopyEEtoXRAMsmall	;
        JNZ	SYS_RUIerror		;
        MOV	DPTR,#sys_nodeno	;
        MOVX	A,@DPTR			;
        MOV	sys_mynode,A		;

	MOV	DPTR,#sys_unitinfo	; confirm that serial
        MOV	R6,#0			; number info intact
        MOV	R7,#7			;
        CALL	CRC_ConfirmChecksumLen	;
        JZ	SYS_RUIfail		;

        RET
SYS_RUIfail:
	MOV	sys_mynode,#NODE_ID_INSTALL
        RET

SYS_RUIerror:
	MOV	sys_mynode,#NODE_ID_INSTALL
	RET

;************************************************************************

SYS_WriteUnitInfo:
	MOV	A,sys_mynode		; set the node number
        MOV	DPTR,#sys_nodeno	;
        MOVX	@DPTR,A			;

	MOV	DPTR,#sys_dtserial	; checksum the block
        MOV	R6,#0			;
        MOV	R7,#5			;
        CALL	CRC_ComputeChecksum	;
	MOV	DPTR,#sys_unitinfo	;
        CALL	MTH_StoreWord		;

        MOV	DPTR,#EE_UNITINFO	; write the checksummed
        CALL	MEM_SetDest		; serial number and node
        MOV	DPTR,#sys_unitinfo	; number into EE
        CALL	MEM_SetSource		;
        MOV	R1,#EE_SLAVE		;
	MOV	R7,#7			;
        SETB	F1			;
        CALL	MEM_CopyXRAMtoEEsmall	;

	RET

;*******************************************************************************

POWER_UNIT	EQU ACC.3	; port 6 not bit addressable
POWER_ACCESSORY	EQU ACC.4	; port 6 not bit addressable
POWER_PRICEPLUG	EQU ACC.0	; port 6 not bit addressable

SYS_POWER_RESET		EQU 0 ; not logged in audit - normal bootup
SYS_MANUAL_RESET	EQU 1
SYS_WATCHDOG_RESET	EQU 2
SYS_CRASH_RESET		EQU 3

;******************************************************************************
;
; Function:	SYS_UnitPowerOn
; Input:	None
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Switches on the main power line and enables the power fail interrupt.
;
;******************************************************************************

SYS_UnitPowerOn:
	IF VT10

	PUSHACC
	MOV	A,#UnitOn
	CALL	PortSetB
	SETB	IT0			; INT0 (powerfail) -ve triggered
;	ORL	IEN0,#01h		; enable power fail interrupt
        CLR     sys_batlowwarn
	POP	ACC
	RET

	ELSE

	SETB	sys_uon
	CALL	SBS_WriteSB2
	SETB	IT0			; INT0 (powerfail) -ve triggered
	ORL	IEN0,#01h		; enable power fail interrupt
        CLR     sys_batlowwarn
	RET

	ENDIF
;******************************************************************************
;
; Function:	SYS_UnitPowerOff
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Turns off the main power. This function NEVER returns - the CPU dies.
;
;******************************************************************************

msg_removepplug: DB 16,'Remove PricePlug'

SYS_UnitPowerOff:
	CLR	A				; disable all interrupts so
	MOV	IEN0,A				; that we don't get a spurious
	MOV	IEN1,A				; interrupt during power
	MOV	IEN2,A				; down (eg powerfail)

        IF DT_TEST <> 1
	MOV	DPSEL,#0			; log the power down
;	MOV	DPTR,#aud_entry_switchoff	; in the audit roll
;	CALL	AUD_AddEntry			;
        ENDIF

	JB	ppg_plugstate,SYS_UPOnoplug	; if inserted, tell the
	IF DT5					; user to remove the
	ELSE					; priceplug
	 CALL	LCD_Clear2			;
	 MOV	A,#64				;
	 CALL	LCD_GotoXY			;
	 MOV	DPTR,#msg_removepplug		;
	 CALL	LCD_DisplayStringCode		;
	ENDIF					;
SYS_UPOnoplug:
	IF DT5
        ELSE
	 CALL	DIS_PowerOffMessage
        ENDIF

        IF      SPEAKER
	CALL	SND_SoundOff			; terminate sounds in progress
        ENDIF

        IF      LEDS
        CALL    LED_Led1Off			; turn off all leds
        CALL    LED_Led2Off			;
        CALL    LED_Led3Off			;
        CALL    LED_Led4Off			;
        ENDIF

        CALL	SYS_PrinterPowerOff

        MOV     A,#SYS_AREA_UNITOFF		; mark the area code as
        CALL	SYS_SetAreaCode			; a controlled power down

	IF VT10
	MOV	A,#UnitOn
	CALL	PortClrB
	ELSE
	CLR	sys_uon
	CALL	SBS_WriteSB2			; switch off unit power
	ENDIF

SYS_UPOdeath:
	JMP	SYS_UPOdeath			; wait here till power dies

;******************************************************************************
;
; Function:	SYS_PrinterPowerOn
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Turns on the printer power line.
;
;******************************************************************************

SYS_PrinterPowerOn:
	IF VT10

	CALL	PRT_On
	RET

	ELSE

	SETB	sys_prnon
	CALL	SBS_WriteSB2
	RET

	ENDIF




;******************************************************************************
;
; Function:	SYS_PrinterPowerOff
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Turns off the printer power line.
;
;******************************************************************************

SYS_PrinterPowerOff:
	IF VT10

	CALL	PRT_Off
	CALL    SYS_DisableInts
        ANL     P6,#00Fh		; clear stepper bits
        CALL	SYS_EnableInts
	RET

	ELSE

	CLR	sys_prnon
	CALL	SBS_WriteSB2
	CALL    SYS_DisableInts
        ANL     P6,#00Fh		; clear stepper bits
        CALL	SYS_EnableInts
	RET

	ENDIF


;******************************************************************************
;
; Function:	SYS_AccessoryPowerOn
; Input:	None
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Turns the accessory power line on.
;
;******************************************************************************

SYS_AccessoryPowerOn:
	IF VT10
	RET
	ELSE
	SETB	sys_aon
	CALL	SBS_WriteSB2
	RET
	ENDIF
;******************************************************************************
;
; Function:	SYS_AccessoryPowerOff
; Input:	None
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Turns the accessory power line off.
;
;******************************************************************************

SYS_AccessoryPowerOff:
	IF VT10
	RET
	ELSE
	CLR	sys_aon
	CALL	SBS_WriteSB2
	RET
	ENDIF
;******************************************************************************
;
; Function:	SYS_PricePlugPowerOn
; Input:	None
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Turns the priceplug power on.
;
;******************************************************************************

SYS_PricePlugPowerOn:
	IF VT10

	PUSHACC
	MOV	A,#PricePlugOn
	CALL	PortSetB
	POP	ACC
	RET

	ELSE

	SETB	sys_ppon
	CALL	SBS_WriteSB2
	RET

	ENDIF
;******************************************************************************
;
; Function:	SYS_PricePlugPowerOff
; Input:	None
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Turns the priceplug power off.
;
;******************************************************************************

SYS_PricePlugPowerOff:
	IF VT10

	PUSHACC
	MOV	A,#PricePlugOn
	CALL	PortClrB
	POP 	ACC
	RET

	ELSE

	CLR	sys_ppon
	CALL	SBS_WriteSB2
	RET

	ENDIF
;*******************************************************************************

xxx:
;	MOV	S1BUF,A			; write the data
;xxxwait:
;	MOV	A,S1CON			; wait for transmit
;	ANL	A,#002h			; buffer empty
;	JZ	xxxwait		;
;	MOV	A,S1CON			;
;	ANL	A,#0FDh			;
;	MOV	S1CON,A			;
	RET

;******************************************************************************
;
; Function:	SYS_EnableInts
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_EnableInts:
	PUSHACC
	DEC	sys_intnest
	MOV	A,sys_intnest
	JNZ	SYS_EIleaveon
 MOV A,#255
 CALL xxx
	SETB	EAL
SYS_EIleaveon:
	POP	ACC
	RET

;******************************************************************************
;
; Function:	SYS_DisableInts
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_DisableInts:
	PUSHACC
	MOV	A,sys_intnest
        JNZ	SYS_DIwasoff
 MOV A,#254
 CALL xxx
        CLR	EAL
SYS_DIwasoff:
	INC	sys_intnest
	POP	ACC
	RET

;******************************************************************************
;
; Function:	SYS_PowerFail
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_PowerFail:	; ISR
;	PUSHPSW
;	PUSHACC
;	PUSHDPH
;	PUSHDPL
	RETI	
	MOV	DPTR,#SYS_MEM_POWERFAIL
	MOV	A,#1
	MOVX	@DPTR,A

        MOV	DPTR,#SYS_MEM_AREACODE		; if code is main loop, change
        MOVX	A,@DPTR				; it to powerdown so we don't
        CJNE	A,#SYS_AREA_MAINLOOP,SYS_PFerr	; get the annoying dump at
        MOV     A,#SYS_AREA_UNITOFF		; powerup when we know there
        CALL	SYS_SetAreaCode			; is no other problem

SYS_PFerr:
	JMP	SYS_PFerr

;	POP     DPL
;	POP     DPH
;	POP	ACC
;	POP	PSW
;	RETI

;******************************************************************************
;
; Function:	SYS_SetAreaCode
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_SetAreaCode: ; A= code
	PUSHDPH
        PUSHDPL
	MOV	DPTR,#SYS_MEM_AREACODE
        MOVX	@DPTR,A
        POP	DPL
        POP	DPH
        RET

;*******************************************************************************

	IF DT10W
SYS_POWERUP_LEN	EQU ((19*6)+5)
        ELSE
SYS_POWERUP_LEN	EQU 42
	ENDIF

sys_powerup_template:
;              w   f  mag  x   y len string
	IF DT10W
         DB 255,19,1,0,2, 0,19,'DT10W Machine XXXXX'
         DB 255, 8,1,0,4,30, 8,'Power On'
	 DB 255,15,1,0,6,12,15,'dd/mm/yy  hh:mm'
        ELSE
	 IF DT10
          IF VT1
 	   DB 255,18,00h,00h, 1,  4,18,' VT1 Machine XXXXX'
          ELSE
	   DB 255,18,00h,00h, 1,  4,18,'DT10 Machine XXXXX'
          ENDIF
	 ENDIF
         IF DT5
	  DB 255,18,00h,00h, 1,  4,18,' DT5 Machine XXXXX'
         ENDIF
	 DB 255, 8,00h,00h, 6, 17, 8,'Power On'
	 DB 255,15,00h,00h, 3, 30,15,'dd/mm/yy  hh:mm'
	ENDIF
	DB 00h
sys_powerup_template_end:

sys_tmpl_text1		EQU 0100h
	IF DT10W
sys_tmpl_dtserial	EQU sys_tmpl_text1+FIELD_HEADER+14
        ELSE
sys_tmpl_dtserial	EQU sys_tmpl_text1+FIELD_HEADER+13
	ENDIF
sys_tmpl_text2		EQU sys_tmpl_dtserial+5
sys_tmpl_date		EQU sys_tmpl_text2+FIELD_HEADER+8+FIELD_HEADER
sys_tmpl_text3          EQU sys_tmpl_date+8
sys_tmpl_time		EQU sys_tmpl_text3+2
sys_tmpl_termination	EQU sys_tmpl_time+5

sys_powerup_format:
	DB 3
	DB 0

        DW sys_dtserial			; machine serial number
	DW sys_tmpl_dtserial
        DB 5,0,NUM_PARAM_DECIMAL32

	DW datebuffer			; date
        DW sys_tmpl_date
        DB 0,0,NUM_PARAM_DATE

        DW timebuffer			; time
        DW sys_tmpl_time
        DB 0,0,NUM_PARAM_TIME

;******************************************************************************
;
; Function:	SYS_PowerUpMessage
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_PowerUpMessage:
	CALL	PRT_StartPrint
	CALL	TIM_GetDateTime

	MOV	DPTR,#sys_powerup_template
	CALL	MEM_SetSource
	MOV	DPTR,#sys_tmpl_text1
	CALL	MEM_SetDest
	MOV	R7,#(sys_powerup_template_end-sys_powerup_template)
	CALL	MEM_CopyCODEtoXRAMsmall
        MOV	DPSEL,#2
        MOV	DPTR,#sys_powerup_format
        CALL	NUM_MultipleFormat

        MOV	A,#SYS_POWERUP_LEN
        CALL	PRT_SetBitmapLenSmall
        CALL	PRT_ClearBitmap
        MOV	DPTR,#sys_tmpl_text1
        CALL	PRT_FormatBitmap
        CALL	PRT_PrintBitmap
        CALL	PRT_EndPrint
        RET

;******************************************************************************
;
; Function:	SYS_SystemTick
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   General purpose system tick.
;
;******************************************************************************

; cooling system constants...

HEATCHECKMETHOD		EQU 2		; 0 = old method, 1 = new method

	IF HEATCHECKMETHOD = 2

sys_pulseconst:		DD 3500		; printer pulses allowed per slowtick
sys_pulseconst2:	DD 100000	; pulses before going slow
sys_pulseconst3:	DD 90000	; pulses before speeding up
sys_pulseconst4:	DD 110000	; max pulses allowed
SYS_COOLINGDELAY        EQU 25		; number of 100ms cooling delayed

	ELSE

sys_pulseconst:		DD 40000	; number of printer pulse allowed in
sys_pulseconst2:	DD 60000	; number of pulse allowed when slow
SYS_TIMECONST		EQU 18		; this many slow ticks
SYS_COOLINGDELAY        EQU 10		; number of 100ms cooling delayed

	ENDIF


SYS_SystemTick:
	PUSHPSW
	PUSHACC
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV	A,R0
	PUSHACC

;*****************************************************************
; Main System Tick - Hit Every 0.065536 secs (15.26 times per sec)
;*****************************************************************

	INC	sys_tick			; update main system tick

	MOV	A,prt_powerdelay		; handle the delayed
	JZ	SYS_STprtoff			; printed power down
	DEC	A				;
	MOV	prt_powerdelay,A		;
	JNZ	SYS_STprtoff			;
	CALL	SYS_PrinterPowerOff		;
SYS_STprtoff:					;

	IF USE_TMACHS                           ; checks the turnstile
	 CALL	LOU_CheckTurnstile              ; switch and increments
	ENDIF                                   ; the counter if necessary

;;; START OF SERVANT SECTION

	IF USE_SERVANT

	 MOV	B,#0

	 ;;; Transmit

	 CALL	COM_TxStatusAgain


	 ;;; Receive

	 MOV	A,kbd_rxpkt_state
	 MOV	DPTR,#rxpkttable
	 RL	A
	 JMP	@A+DPTR

rxpkttable:
	 AJMP	SYS_SVNTminipkt0
	 AJMP	SYS_SVNTminipkt1
	 AJMP	SYS_SVNTminipkt2
	 AJMP	SYS_SVNTminipkt3
	 AJMP	SYS_SVNTminipkt4

SYS_SVNTminipkt0:
	 CALL	COM_RxChar
	 JNC	SYS_SVNTnopacket
	 CJNE	A,#'k',SYS_SVNTminipktfail
	 INC	kbd_rxpkt_state

SYS_SVNTminipkt1:
	 CALL	COM_RxChar
	 JNC	SYS_SVNTnopacket
	 CJNE	A,#'b',SYS_SVNTminipktfail
	 INC	kbd_rxpkt_state

SYS_SVNTminipkt2:
	 CALL	COM_RxChar
	 JNC	SYS_SVNTnopacket
	 CJNE	A,#'p',SYS_SVNTminipktfail
	 INC	kbd_rxpkt_state

SYS_SVNTminipkt3:
	 CALL	COM_RxChar
	 JNC	SYS_SVNTnopacket
	 MOV	kbd_pkt_data,A
	 INC	kbd_rxpkt_state

SYS_SVNTminipkt4:
	 CALL	COM_RxChar
	 JNC	SYS_SVNTnopacket
	 CJNE	A,kbd_pkt_data,SYS_SVNTminipktfail
	 CALL 	KBD_ProcessInternals

SYS_SVNTminipktfail:
	 MOV	kbd_rxpkt_state,#0

SYS_SVNTnopacket:
	ENDIF

;;; END OF SERVANT SECTION

	CPL	P4.4				; trigger watchdog

        IF      LEDS
	CALL	LED_ServiceLEDs			; flash appropriate leds
        ENDIF

	MOV	A,sys_tick			; check for slow tick
	JZ      SYS_STdoslowtick
	JMP	SYS_STnoslowtick		;

;******************************************************************
; Slow System Tick - Hit Every 16.777216 secs (0.059 times per sec)
;******************************************************************

SYS_STdoslowtick:
	IF	VT10
	JNB	lcd_backlight,SYS_STskipbacklight
	MOV	A,lcd_delaybacklite
	DEC	A
	MOV	lcd_delaybacklite,A
	JNZ	SYS_STskipbacklight
	CLR	lcd_backlight
	CALL	LCD_TurnBacklightOff
SYS_STskipbacklight:
	ENDIF

	IF DT_TEST <> 1
	CALL	SYS_SampleBatteryVolts		; check for battery fail
	CJNE	A,#SYS_BATFAIL,SYS_STchkfail	;
	JMP	SYS_STnofailbat			;
SYS_STchkfail:					;
	JNC	SYS_STnofailbat			;
	JMP	SYS_BatteryFail			;
SYS_STnofailbat:				;

        CJNE	A,#SYS_BATLOW,SYS_STchklow	; check for battery low
	JMP	SYS_STnolowbat			;
SYS_STchklow:					;
	JNC	SYS_STnolowbat			;
	JB      sys_batlowwarn,SYS_STnolowbat	;

        IF      LEDS
        CALL    LED_Led3Flash                   ;
        ENDIF

	SETB    sys_batlowwarn			;
	SETB	tim_timerupdate			;
	JMP     SYS_STbattestdone               ;
SYS_STnolowbat:					;

	CJNE	A,#SYS_BATOK,SYS_STchkok	; check for battery rising
	JMP	SYS_STnobatok			; to a safe level
SYS_STchkok:					;
	JC	SYS_STnobatok			;
	JNB	sys_batlowwarn,SYS_STnobatok	;

        IF      LEDS
        CALL    LED_Led3On                      ;
        ENDIF

	CLR	sys_batlowwarn			;
	SETB	tim_timerupdate			;
	JMP     SYS_STbattestdone               ;
SYS_STnobatok:					;
SYS_STbattestdone:

	ENDIF

	JMP	SYS_STnoslowtick

	MOV	A,mth_op1ll
	PUSHACC
	MOV	A,mth_op1lh
	PUSHACC
	MOV	A,mth_op1hl
	PUSHACC
	MOV	A,mth_op1hh
	PUSHACC
	MOV	A,mth_op2ll
	PUSHACC
	MOV	A,mth_op2lh
	PUSHACC
	MOV	A,mth_op2hl
	PUSHACC
	MOV	A,mth_op2hh
	PUSHACC

;	PUSH	mth_op1ll
;	PUSH	mth_op1lh
;	PUSH	mth_op1hl
;	PUSH	mth_op1hh
;	PUSH	mth_op2ll
;	PUSH	mth_op2lh
;	PUSH	mth_op2hl
;	PUSH	mth_op2hh

	IF HEATCHECKMETHOD = 0

	INC	SYS_heatcount			;
	MOV	A,#SYS_TIMECONST
	CJNE	A,SYS_heatcount,SYS_SThc1ne

SYS_STtime:
	MOV	SYS_heatcount,#0

;	PUSHR1
	MOV	A,R1
	PUSHACC
;	PUSHR7
	MOV	A,R7
	PUSHACC

	MOV	R0,#mth_operand1
	MOV	DPTR,#sys_pulseconst
	CALL	MTH_LoadConstLong
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_LoadOp2Long
	CALL	MTH_TestGTLong
	JC	SYS_STnotoverheating
	SETB	SYS_overheating
	JMP	SYS_STresetpulsecount

SYS_STnotoverheating:
	CLR	SYS_overheating

SYS_STresetpulsecount:
	MOV	A,#0
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_StoreLong
;	POP	7
	POP	ACC
	MOV	R7,A
;	POP	1
	POP	ACC
	MOV	R1,A
	JMP	SYS_STendheatcheck

SYS_SThc1ne:
	JC	SYS_STtime

SYS_STendheatcheck:

	ENDIF
	IF HEATCHECKMETHOD = 1

;	PUSHR1
	MOV	A,R1
	PUSHACC
;	PUSHR7
	MOV	A,R7
	PUSHACC

	MOV	R0,#mth_operand1
	MOV	DPTR,#sys_pulseconst
	CALL	MTH_LoadConstLong
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_LoadOp2Long
	CALL	MTH_TestGTLong
	JC	SYS_STnotoverheating
	SETB	SYS_overheating

SYS_STnotoverheating:
	INC	SYS_heatcount			;
	MOV	A,#SYS_TIMECONST
	CJNE	A,SYS_heatcount,SYS_SThc1ne

SYS_STtime:
	MOV	SYS_heatcount,#0
	MOV	R0,#mth_operand1
	MOV	DPTR,#sys_pulseconst2
	CALL	MTH_LoadConstLong
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_LoadOp2Long
	CALL	MTH_TestGTLong
	JC	SYS_STnotoverheating2
	SETB	SYS_overheating
	JMP	SYS_STresetpulsecount
SYS_STnotoverheating2:
	CLR	SYS_overheating
SYS_STresetpulsecount:
	MOV	A,#0
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_StoreLong
	JMP	SYS_STendheatcheck

SYS_SThc1ne:
	JC	SYS_STtime

SYS_STendheatcheck:
;	POP	7
	POP	ACC
	MOV	R7,A
;	POP	1
	POP	ACC
	MOV	R7,A
	ENDIF
	IF HEATCHECKMETHOD = 2

;	PUSHR1
	MOV	A,R1
	PUSHACC
;	PUSHR7
	MOV	A,R7
	PUSHACC

	MOV	R0,#mth_operand1	; check pulsecount big enough to
	MOV	DPTR,#sys_pulseconst	; take the const away from
	CALL	MTH_LoadConstLong	;
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_LoadOp2Long
	CALL	MTH_TestGTLong
	JNC	SYS_STisittoohigh
	JMP	SYS_STendheatcheck

SYS_STisittoohigh:
	MOV	R0,#mth_operand1	; check pulsecount not getting too
	MOV	DPTR,#sys_pulseconst4	; large
	CALL	MTH_LoadConstLong	;
	MOV	DPTR,#sys_pulsecount
	CALL	MTH_LoadOp2Long
	CALL	MTH_TestGTLong
	JC	SYS_STneedtest
	MOV	DPTR,#sys_pulsecount    ; if pulsecount too large, reduce
	CALL	MTH_StoreLong           ; to pulseconst4

SYS_STneedtest:
	MOV	DPTR,#sys_pulsecount	; take off the fixed constant
	CALL	MTH_LoadOp1Long		;
	MOV	R0,#mth_operand2	;
	MOV	DPTR,#sys_pulseconst	;
	CALL	MTH_LoadConstLong	;
	CALL	MTH_SubLongs		;
	MOV	DPTR,#sys_pulsecount	; take off the fixed constant
	CALL	MTH_StoreLong		;

	JB	SYS_overheating,SYS_SToverheating

	MOV	R0,#mth_operand1	; check pulsecount not big enough
	MOV	DPTR,#sys_pulseconst2	; to require cooling
	CALL	MTH_LoadConstLong	;
	MOV	DPTR,#sys_pulsecount	;
	CALL	MTH_LoadOp2Long         ;
	CALL	MTH_TestGTLong          ;
	JC	SYS_STendheatcheck	;
	SETB	SYS_overheating         ;
	JMP	SYS_STendheatcheck	;

SYS_SToverheating:
	MOV	R0,#mth_operand1	; check pulsecount has dropped
	MOV	DPTR,#sys_pulseconst3	; enough to warrent speeding up
	CALL	MTH_LoadConstLong	; again
	MOV	DPTR,#sys_pulsecount	;
	CALL	MTH_LoadOp2Long         ;
	CALL	MTH_TestGTLong          ;
	JNC	SYS_STendheatcheck	;
	CLR	SYS_overheating

SYS_STendheatcheck:
;	POP	7
	POP	ACC
	MOV	R7,A
;	POP	1
	POP	ACC
	MOV	R7,A

	ENDIF

;	MOV	A,#9
;	CALL	LCD_GotoXY
;	MOV	DPSEL,#0
;	MOV	DPTR,#sys_pulsecount
;	MOV	DPSEL,#1
;	MOV	DPTR,#buffer
;	MOV	R5,#8+NUM_ZEROPAD
;	CALL	NUM_NewFormatDecimal32
;	MOV	R7,#8
;	CALL	LCD_DisplayStringXRAM


	POP	mth_op2hh
	POP	mth_op2hl
	POP	mth_op2lh
	POP	mth_op2ll
	POP	mth_op1hh
	POP	mth_op1hl
	POP	mth_op1lh
	POP	mth_op1ll


SYS_STnoslowtick:				;
	POP	ACC
	MOV	R0,A
	POP	DPL
	POP	DPH
	POP	B
	POP	ACC
	POP	PSW
	RETI

;*******************************************************************************

sys_msgbatfail:	DB 12,'Battery Dead'

SYS_BatteryFail:
	CALL	LCD_Clear
	MOV	DPTR,#sys_msgbatfail
        CALL	LCD_DisplayStringCODE
        JMP	SYS_UnitPowerOff

;******************************************************************************
;
; Function:	SYS_SampleBatteryVolts
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_SampleBatteryVolts:
	MOV	A,ADCON0
	ANL	A,#0C0h		; keep two bits nothing to do with ADC
	MOV	ADCON0,A
	MOV	ADCON1,#07h		; ADC7 = battery
	MOV	DAPR,#0
SYS_SBVwait:
	JB	0DCh,SYS_SBVwait
	MOV	A,ADDAT
	MOV	DPTR,#sys_batteryvolts
	MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	SYS_ScanBatteryVolts
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_ScanBatteryVolts:
	CALL	SYS_SampleBatteryVolts
	INC	DPTR			; shift 4 places
	MOV	B,#16			; to get centivolts
	MUL	AB			;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOV	A,B			;
	MOVX	@DPTR,A			;
	RET

;******************************************************************************
;
; Function:	SYS_ScanBatteryTemp
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_ScanBatteryTemp:
	MOV	A,ADCON0
	ANL	A,#0C0h	; keep two bits nothing to do with ADC
	MOV	ADCON0,A
	MOV	ADCON1,#05h
	MOV	DAPR,#0
	NOP
	NOP
	NOP
	NOP
	NOP
SYS_SBTwait:
	JB	0DCh,SYS_SBTwait
	MOV	A,ADDAT
	MOV	DPTR,#sys_batterytemp
	MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	SYS_SetTimeout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_SetTimeout:
        ADD	A,sys_tick
        MOV	DPTR,#sys_timeout
        MOVX	@DPTR,A
        RET

;******************************************************************************
;
; Function:	SYS_CheckTimeout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SYS_CheckTimeout:
	MOV	DPTR,#sys_timeout
        MOVX	A,@DPTR
        CJNE	A,sys_tick,SYS_CTno
	SETB	C
        RET
SYS_CTno:
	CLR	C
        RET

;******************************************************************************
;
; Function:	SYS_DetectRAM
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

RAMSELECT EQU   0                       ; "Xram" Address of Upper Bank 
                                        ; Select Port
sys_ramsize: VAR 1
SYS_DetectRAM:
        MOV	R7,#32			; try all 32 possible pages
        MOV	B,#0			; starting from page 0


SYS_DRloop:
;       ANL     SB1data,#0E0h           ; keep rest of SB1data
;        MOV     A,B
;       ORL     SB1data,A               ; set up page addressing
;        PUSHB                           ;
;        CALL   SBS_WriteSB1            ;
;        POP     B                       ;

        mov     dptr,#RAMSELECT

        mov     a,b
        movx    @dptr,a

        MOV	DPTR,#0FFFFh		; poke last location of this page
        MOV	A,#055h			; with 55h
        MOVX	@DPTR,A			;
        MOVX	A,@DPTR			; and read it back and compare
        CJNE	A,#055h,SYS_DRfail	;

        MOV	A,#0AAh			; poke last location of this page
        MOVX	@DPTR,A			; with AAh
        MOVX	A,@DPTR			; and read it back and compare
        CJNE	A,#0AAh,SYS_DRfail	;

	INC	B
        DJNZ	R7,SYS_DRloop
SYS_DRfail:
	MOV	DPTR,#sys_ramsize	; save system ram size
	MOV	A,B			;
	MOVX	@DPTR,A			;
	RET
;*******************************************************************************
;
; Function:	SYS_IntPriority
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:	Set the interrupt priority levels. RI0 should be higher than
;		TF0, to make sure the RS485 network traffic is received OK.
;
;******************************************************************************

SYS_IntPriority:
	CALL	SYS_DisableInts
	MOV	IP0,#00010000b	; IP.4 selects RI0, 11 sets highest priority
	MOV	IP1,#00010000b	; All others set at lowest priority (00).
	CALL	SYS_EnableInts
	RET
;;***************************** End Of SYSTEM.ASM ******************************
        End
