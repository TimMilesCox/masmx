;******************************************************************************
; Restart and interrupt vector initialisation
;******************************************************************************

	ORG 0000h               ; Restart vector
        JMP tv_DT_ColdBoot

	ORG 0003h               ; External interrupt 0
        JMP tv_SYS_PowerFail

	ORG 000Bh               ; Timer 0 overflow interrupt
        JMP tv_SYS_SystemTick

	ORG 0013h               ; External interrupt 1
	IF VT10
        JMP     tv_KBD_Read_Triggers2
	ELSE

SLEEP_IN EQU    1
        IF      SLEEP_IN
        jmp     InterruptStub
        ELSE
        JMP tv_TIM_ClockAlarm
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
        JMP tv_RS485_Rx
	ELSE
        JMP tv_COM_Rx0Int
	ENDIF
	ENDIF
	ORG 002Bh               ; Timer 2 overflow/reload interrupt
	JMP interruptstub

	ORG 0043h               ; A/D converter interrupt
	JMP interruptstub

	IF VT10

	ORG 004Bh               ; External interrupt 2
        JMP tv_KBD_ProcessKeyboard

	ORG 0053h               ; External interrupt 3
	JMP interruptstub

	ELSE

	ORG 004Bh               ; External interrupt 2
        JMP tv_PPG_PricePlugChange

	ORG 0053h               ; External interrupt 3
        JMP tv_KBD_ProcessKeyboard


	ENDIF

	ORG 005Bh               ; External interrupt 4
	JMP interruptstub

	ORG 0063h               ; External interrupt 5
	JMP interruptstub

	IF VT10

	ORG 006Bh               ; External interrupt 6
        JMP tv_PPG_PricePlugChange

	ELSE

	ORG 006Bh               ; External interrupt 6
	JMP interruptstub

	ENDIF


	ORG 0083h               ; Serial channel 1
	IF VT10
        JMP tv_RS485_Rx
	else
        JMP tv_COM_Rx1Int
	endif

	ORG 009Bh               ; Compare timer overflow
	JMP interruptstub

	ORG 0b0h                ; start of code
Com0Int:
	CLR	RI0
	CLR	TI0
	CLR	ES0
	RETI

interruptstub:
	RETI
;

dia_icode equ   31
dia_pcode equ   15

tv_DT_ColdBoot
        mov     dia_pcode,dia_icode
        mov     dia_icode,#101
        jmp     DT_ColdBoot
tv_SYS_PowerFail
        mov     dia_pcode,dia_icode
        mov     dia_icode,#102
        jmp     SYS_PowerFail
tv_SYS_SystemTick:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#103
        jmp     SYS_SystemTick
tv_KBD_Read_Triggers2:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#104
        jmp     KBD_Read_Triggers2

        IF      USE_RS485 EQ 0
tv_COM_Rx0Int:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#105
        jmp     COM_Rx0Int
        ENDIF

tv_KBD_ProcessKeyBoard
        mov     dia_pcode,dia_icode
        mov     dia_icode,#106
        jmp     KBD_ProcessKeyBoard
tv_PPG_PricePlugChange:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#107
        jmp     SYS_PowerFail
tv_RS485_Rx:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#108
        jmp     RS485_rx
tv_COM_Rx1Int:
        mov     dia_pcode,dia_icode
        mov     dia_icode,#109
        jmp     COM_Rx1Int

        End
