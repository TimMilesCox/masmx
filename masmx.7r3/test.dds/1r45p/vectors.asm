;******************************************************************************
; Restart and interrupt vector initialisation
;******************************************************************************

	ORG 0000h               ; Restart vector
	JMP DT_ColdBoot

	ORG 0003h               ; External interrupt 0
	JMP SYS_PowerFail

	ORG 000Bh               ; Timer 0 overflow interrupt
	JMP SYS_SystemTick

	ORG 0013h               ; External interrupt 1
	IF VT10
	JMP     KBD_Read_Triggers2
	ELSE

	IF      SLEEP_IN
	jmp     InterruptStub
	ELSE
	JMP TIM_ClockAlarm
	ENDIF

	ENDIF


	ORG 001Bh               ; Timer 1 overflow interrupt

	IF      SPEAKER
	JMP SND_TerminateSound
	ELSE
	JMP     InterruptStub
	ENDIF

	ORG 0023h               ; Serial channel 0 interrupt
	IF VT10
	JMP Com0Int
	ELSE
	IF USE_RS485
	JMP RS485_Rx
	ELSE
	JMP COM_Rx0Int
	ENDIF
	ENDIF
	ORG 002Bh               ; Timer 2 overflow/reload interrupt
	JMP interruptstub

	ORG 0043h               ; A/D converter interrupt
	JMP interruptstub

	IF VT10

	ORG 004Bh               ; External interrupt 2
	JMP KBD_ProcessKeyboard

	ORG 0053h               ; External interrupt 3
	JMP interruptstub

	ELSE

	ORG 004Bh               ; External interrupt 2
	JMP PPG_PricePlugChange

	ORG 0053h               ; External interrupt 3
	JMP KBD_ProcessKeyboard


	ENDIF

	ORG 005Bh               ; External interrupt 4
	JMP interruptstub

	ORG 0063h               ; External interrupt 5
	JMP interruptstub

	IF VT10

	ORG 006Bh               ; External interrupt 6
	JMP PPG_PricePlugChange

	ELSE

	ORG 006Bh               ; External interrupt 6
	JMP interruptstub

	ENDIF


	ORG 0083h               ; Serial channel 1
	IF VT10
	JMP RS485_Rx
	else
	JMP COM_Rx1Int
	endif

	ORG 009Bh               ; Compare timer overflow
	JMP interruptstub

	ORG 0b0h                ; start of code
Com0Int:
	CLR     RI0
	CLR     TI0
	CLR     ES0
	RETI

interruptstub:
	RETI
;
	End
