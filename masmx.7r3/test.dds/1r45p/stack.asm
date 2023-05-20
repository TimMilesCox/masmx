;*******************************************************************************
; Stack Macros - Detects Stack Overflow & Reboots Machine
;*******************************************************************************

PUSHR0*  MACRO	*
	PUSH	0
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR1*  MACRO	*
	PUSH	1
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR2*  MACRO	*
	PUSH	2
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR3*  MACRO	*
	PUSH	3
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR4*  MACRO	*
	PUSH	4
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR5*  MACRO	*
	PUSH	5
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR6*  MACRO	*
	PUSH	6
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHR7*  MACRO	*
	PUSH	7
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND


PUSHACC* MACRO	*
	PUSH    ACC
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHB* MACRO	*
	PUSH    B
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHDPH* MACRO	*
	PUSH    DPH
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND

PUSHDPL* MACRO	*
	PUSH    DPL
	MOV     stackcheck,SP
	JB      stackcheck7,DT_StackOk
	JMP     DT_ColdBoot
DT_StackOk:
	MACEND


PUSHPSW* MACRO
	PUSH PSW
	MACEND

        END
