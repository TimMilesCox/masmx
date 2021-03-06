;******************************************************************************
;
; File     : Ports.asm
;
; Author   : Robert Gentles
;
; Project  : XQ10
;
; Contents : The port definitions and handling routines for IO.
;
; System   : 80C537
;
; History  :
;   Date   : 26/3/99
;
;******************************************************************************

WheelPhaseA	EQU	P1.0	;Int 3 	(Input)
WheelPhaseB	EQU	P7.3	;	(Input)
WheelSwitch	EQU	P1.5	;	(Input)
WheelPolarity	EQU	P5.7	;	(Output)

ReaderClock1	EQU	P1.1	;Int 4	(Input)
ReaderClock2	EQU	P1.2	;Int 5	(Input)
ReaderData1	EQU	P6.0	;	(Input)
ReaderData2	EQU	P6.3	;	(Input)

KeyPress	EQU	P1.4	;Int 2	(Input)

PricePlugPres	EQU	P1.3	;Int 6	(Input)
PricePlugPol	EQU	P1.6	;	(Output)

GenInt		EQU	P3.3	;Int 1	(Input)

PrintStrobe	EQU	P4.0	;	(Output)
PrintData	EQU	P3.0	;	(Serial Output)
PrintClock	EQU	P3.1	;	(Clock Output)
PrintEnable	EQU	P4.2	;	(One Shot Timer)

I2CData		EQU	P3.4	;	(Input/Output)
I2CClock	EQU	P3.5	;	(Clock Output)

LCDRegSelect	EQU	P5.4	;	(Output)
LCDDataStrobe	EQU	P5.5	;	(Output)
LCDEnableStrobe	EQU	P5.6	;	(Output)

BackLight	EQU	P4.3	;	(Output PWM?)

Watchdog	EQU	P4.4	;	(Output)

PowerFail	EQU	P3.2	;Int 0	(Input)



TurnstileStatus	EQU	P4.1	;	(Input)

RS232Recieve	EQU	P6.1	;	(Input)
RS232Transmit	EQU	P6.2	;	(Output)

StepperPhase1	EQU	P6.4	;	(Output)
StepperPhase2	EQU	P6.5	;	(Output)
StepperPower0	EQU	P6.6	;	(Output)
StepperPower1	EQU	P6.7	;	(Output)

SerialStatus	EQU	P7.0	;	(Input)

ExtIntStatus	EQU	P7.1	;	(Input)

RTClockStatus	EQU	P7.2	;	(Input)

BlackLine	EQU	P7.4	;	(Input 0=Line)

PrintTemp	EQU	P7.5	;	(Analog Input)

BatteryTemp	EQU	P7.6	;	(Analog Input)
BatteryVolts	EQU	P7.7	;	(Analog Input)

PowerOnReset	EQU	P8.0	;	(Input 0=Power On Reset)
ManualReset	EQU	P8.1	;	(Input 0=Manual Reset)
WatchDogReset	EQU	P8.2	;	(Input 0=Watchdog Reset)

PrintCutter	EQU	P8.3	;	(Input)


;Data Ports
PortA	EQU 000h
PORTB	EQU 001h
PortC	EQU 020h
PORTD	EQU 021h
PORTE	EQU 002h

;Port A Outouts

XramPageAdd0	EQU (001h SHL 0)
XramPageAdd1	EQU (001h SHL 1)
XramPageAdd2	EQU (001h SHL 2)
XramPageAdd3	EQU (001h SHL 3)
CmosOut1	EQU (001h SHL 4)
CmosOut2	EQU (001h SHL 5)

;Port A Inputs

KeySense0	EQU (001h SHL 0)
KeySense1	EQU (001h SHL 1)
KeySense2	EQU (001h SHL 2)
KeySense3	EQU (001h SHL 3)
CmosIn1		EQU (001h SHL 4)
CmosIn2		EQU (001h SHL 5)
CmosIn3		EQU (001h SHL 6)
CmosIn4		EQU (001h SHL 7)

;Port B Outputs

PrinterOn	EQU (001h SHL 0)
PricePlugOn	EQU (001h SHL 1)
UnitOn		EQU (001h SHL 2)
CardReaderOn	EQU (001h SHL 3)
StepperControl	EQU (001h SHL 4)
CutPaper	EQU (001h SHL 5)

;Port B Inputs
KeySelect0	EQU (001h SHL 0)
KeySelect1	EQU (001h SHL 1)
KeySelect2	EQU (001h SHL 2)
KeySelect3	EQU (001h SHL 3)
KeySelect4	EQU (001h SHL 4)
KeySelect5	EQU (001h SHL 5)

;Port C Outputs
RS485_232Select	EQU (001h SHL 0)
RS485TxOn	EQU (001h SHL 1)
Serial2On	EQU (001h SHL 2)
Serial3On	EQU (001h SHL 3)
Relay		EQU (001h SHL 5)

;Port C Inputs
ProtCmosIn1	EQU (001h SHL 0)
ProtCmosIn2	EQU (001h SHL 1)
ProtCmosIn3	EQU (001h SHL 2)
ProtCmosIn4	EQU (001h SHL 3)
ProtCmosIn5	EQU (001h SHL 4)
ProtCmosIn6	EQU (001h SHL 5)
ProtCmosIn7	EQU (001h SHL 6)
ProtCmosIn8	EQU (001h SHL 7)

;Port D Outputs
OpenCollOut1	EQU (001h SHL 0)
OpenCollOut2	EQU (001h SHL 1)
OpenCollOut3	EQU (001h SHL 2)
OpenCollOut4	EQU (001h SHL 3)
OpenCollOut5	EQU (001h SHL 4)
OpenCollOut6	EQU (001h SHL 5)

;Port D Inputs
BitSw1		EQU (001h SHL 0)
BitSw2		EQU (001h SHL 1)
BitSw3		EQU (001h SHL 2)
BitSw4		EQU (001h SHL 3)
ProtSwIn1	EQU (001h SHL 4)
ProtSwIn2	EQU (001h SHL 5)
ProtSwIn3	EQU (001h SHL 6)
ProtSwIn4	EQU (001h SHL 7)


;****************************************************************************************
;Void PortSetA(ACC)
;Void PortSetB(ACC)
;Void PortSetC(ACC)
;Void PortSetD(ACC)
;Void PortClrA(ACC)
;Void PortClrB(ACC)
;Void PortClrC(ACC)
;Void PortClrD(ACC)
;C    PortReadA(ACC)
;C    PortReadB(ACC)
;C    PortReadC(ACC)
;C    PortReadD(ACC)
;****************************************************************************************
;******************************************************************************
;
; Function:	PortSetA
; Input:	ACC Bit of Port to Set
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the Port Bit and updates Mirror
;
;******************************************************************************
PortSetA:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorA
	ORL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortA
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortSetB
; Input:	ACC Bit of Port to Set
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the Port Bit and updates Mirror
;
;******************************************************************************
PortSetB:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorB
	ORL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortB
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortSetC
; Input:	ACC Bit of Port to Set
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the Port Bit and updates Mirror
;
;******************************************************************************
PortSetC:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorC
	ORL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortC
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortSetD
; Input:	ACC Bit of Port to Set
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the Port Bit and updates Mirror
;
;******************************************************************************
PortSetD:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorD
	ORL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortD
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;
; Function:	PortSetD
; Input:	ACC Bit of Port to Set
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the Port Bit and updates Mirror
;
;******************************************************************************
PortSetE:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorE
	ORL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortE
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortClrA
; Input:	ACC Bit of Port to Clear
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Clears the Port Bit and updates Mirror
;
;******************************************************************************
PortClrA:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorA
	CPL	A
	ANL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortA
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortClrB
; Input:	ACC Bit of Port to Clear
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Clears the Port Bit and updates Mirror
;
;******************************************************************************
PortClrB:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorB
	CPL	A
	ANL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortB
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortClrC
; Input:	ACC Bit of Port to Clear
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Clears the Port Bit and updates Mirror
;
;******************************************************************************
PortClrC:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorC
	CPL	A
	ANL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortC
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortClrD
; Input:	ACC Bit of Port to Clear
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;  Clears the Port Bit and updates Mirror
;
;******************************************************************************
PortClrD:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorD
	CPL	A
	ANL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortD
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;
; Function:	PortClrE
; Input:	ACC Bit of Port to Clear
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Clears the Port Bit and updates Mirror
;
;******************************************************************************
PortClrE:
	PUSHACC
	PUSHDPH
	PUSHDPL
;	PUSHR0
	PUSHB
	MOV	B,R0
	PUSHB
	MOV	R0,#PortMirrorE
	CPL	A
	ANL	A,@R0
	MOV	@R0,A
	MOV	DPTR,#PortE
	MOVX	@DPTR,A
;	POP	0
	POP	B
	MOV	R0,B
	POP	B
	POP	DPL
	POP	DPH
	POP	ACC
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortReadA
; Input:	ACC Bit of Port to Read
; Output:	C Bit Set if Bit is High
; Preserved:	All
; Destroyed:	None
; Description:
;   Read Port Bit and returns value in Carry
;
;******************************************************************************
PortReadA:
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV	B,A
	MOV	DPTR,#PortA
	MOVX	A,@DPTR
	ANL	A,B
	PUSHACC
	ADD	A,#0ffh
	POP	ACC
	POP	DPL
	POP	DPH
	POP	B
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortReadB
; Input:	ACC Bit of Port to Read
; Output:	C Bit Set if Bit is High
; Preserved:	All
; Destroyed:	None
; Description:
;   Read Port Bit and returns value in Carry
;
;******************************************************************************
PortReadB:
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV	B,A
	MOV	DPTR,#PortB
	MOVX	A,@DPTR
	ANL	A,B
	PUSHACC
	ADD	A,#0FFh
	POP	ACC
	POP	DPL
	POP	DPH
	POP	B
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortReadC
; Input:	ACC Bit of Port to Read
; Output:	C Bit Set if Bit is High
; Preserved:	All
; Destroyed:	None
; Description:
;   Read Port Bit and returns value in Carry
;
;******************************************************************************
PortReadC:
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV	B,A
	MOV	DPTR,#PortC
	MOVX	A,@DPTR
	ANL	A,B
	PUSHACC
	ADD	A,#0FFh
	POP	ACC
	POP	DPL
	POP	DPH
	POP	B
	RET
;******************************************************************************
;******************************************************************************
;
; Function:	PortReadD
; Input:	ACC Bit of Port to Read
; Output:	C Bit Set if Bit is High
; Preserved:	All
; Destroyed:	None
; Description:
;   Read Port Bit and returns value in Carry
;
;******************************************************************************

TRACEPORTD_ON EQU 0
        IF      TRACEPORTD_ON
traceportd var 1
        ENDIF

PortReadD:
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV	B,A
	MOV	DPTR,#PortD
	MOVX	A,@DPTR

        IF      TRACEPORTD_ON
        jz      skiptraceportd
        mov     dptr,#traceportd
        movx    @dptr,a
skiptraceportd:
        ENDIF

	ANL	A,B
	PUSHACC
	ADD	A,#0FFh
	POP	ACC
	POP	DPL
	POP	DPH
	POP	B
	RET
;******************************************************************************
