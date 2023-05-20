;******************************************************************************
;
; File     : NUMBER.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains miscellaneous number conversion routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

NUM_GetBitMask:
	MOVC	A,@A+PC
        RET
	DB 1,2,4,8,16,32,64,128


;******************************************************************************
;
; Function:	DecDigit
; Input:	A=decimal digit in low nibble
;		DPTR=address in XRAM of where to store
; Output:	DPTR=address in XRAM + 1
; Preserved:	R0-7,B
; Destroyed:	None
; Description:
;   Stores the ASCII char corresponding to the decimal digit in the low order
;   nibble of the accumulator at the address in XRAM pointed to by DPTR.
;   The high order nibble is masked out for convenience.
;
;******************************************************************************

DecDigit:
	ANL	A,#00Fh
	ADD	A,#'0'
	MOVX	@DPTR,A
	INC	DPTR
	RET

;******************************************************************************
;
; Function:	HexDigit
; Input:	A=hex digit in low order nibble
;		DPTR=address in XRAM of where to store
; Output:	DPTR=address in XRAM + 1
; Preserved:	R0-7,B
; Destroyed:	None
; Description:
;   Stores the ASCII char corresponding to the hex digit in the low order
;   nibble of the accumulator at the address in XRAM pointed to by DPTR.
;   The high order nibble is masked out for convenience.
;
;******************************************************************************

HexChar:
	ANL	A,#00Fh
	ADD	A,#9
	MOVC	A,@A+PC
	RET

HexDigit:
	ANL	A,#00Fh
	ADD	A,#3		; need to skip 3 bytes of CODE space
	MOVC	A,@A+PC
	MOVX	@DPTR,A		; 1 byte instruction
	INC	DPTR		; 1 byte instruction
	RET			; 1 byte instruction
	DB '0123456789ABCDEF'

;******************************************************************************
;
; Function:	BCDtoBIN
; Input:	A = BCD number
; Output:	A = binary number
; Preserved:	?
; Destroyed:	B
; Description:
;   Converts a 2 digit BCD number to its binary equivalent.
;
;******************************************************************************

BCDtoBIN:
	PUSHACC
	ANL	A,#0F0h
	MOV	B,#10
	SWAP	A
	MUL	AB
	MOV	B,A
	POP	ACC
	ANL	A,#00Fh
	ADD	A,B
	RET

BCDtoASCII:
	PUSHACC
	SWAP	A
	ANL	A,#00Fh
	ADD	A,#'0'
	MOVX	@DPTR,A
	POP	ACC
	INC	DPTR
	ANL	A,#00Fh
	ADD	A,#'0'
	MOVX	@DPTR,A
	INC	DPTR
	RET
;******************************************************************************
;
; Function:	BINtoBCD
; Input:	A = binary number
; Output:       A = BCD number
; Preserved:	?
; Destroyed:	B
; Description:
;   Converts a binary number to its BCD equivalent.
;
;******************************************************************************

BINtoBCD:	;
	MOV	B,#10
	DIV	AB
	SWAP	A
	ORL	A,B
	RET

;******************************************************************************
;
; Function:	ClearDecimal
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Clears the internal number buffer
;
;******************************************************************************

ClearDecimal:
	PUSHACC
	MOV	A,#0
	MOV	n7,A
	MOV	n6,A
	MOV	n5,A
	MOV	n4,A
	MOV	n3,A
	MOV	n2,A
	MOV	n1,A
	MOV	n0,A
	POP	ACC
	RET

;******************************************************************************
; Function:	BinToHex
; Input:	A = 8 bit number to convert
;		DPTR = address to write 2 ascii chars of hex to
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Converts the 8 bit number in A to a 2 character string hex number
;******************************************************************************

BinToHex:
	PUSHACC
	SWAP	A
	CALL	HexDigit
	POP	ACC
	CALL	HexDigit
	RET

;******************************************************************************
;
; Function:	NUM_GetString
; Input:	R7 = max number of digits allowed
;		B = lcd pos to print number at
; Output:	A=0 if ok, <> 0 if aborted
; Preserved:	?
; Destroyed:	?
; Description:
;   Scans a number from the keyboard into the input buffer.
;
;******************************************************************************

num_inputlen: VAR 1
num_inputbuffer: VAR 10

NUM_GetString:
	IF DT5
        ELSE
	 PUSHB
         MOV	A,B
         CALL	LCD_GotoXY
	 CALL	LCD_TurnBlinkOn
	 POP	B
        ENDIF
	MOV	DPTR,#num_inputlen
        CLR	A
        MOVX	@DPTR,A
NUM_GSkey:
	CALL	KBD_ReadKey
        JZ	NUM_GSkey

        CJNE	A,#KBD_CANCEL,NUM_GSnotcancel
        MOV	DPTR,#num_inputlen
        IF DT5
        ELSE
         CALL	LCD_TurnBlinkOff
        ENDIF
        CLR	A
        MOVX	@DPTR,A
	RET
NUM_GSnotcancel:
	CJNE	A,#KBD_OK,NUM_GSchar
        IF DT5
        ELSE
	 CALL	LCD_TurnBlinkOff
        ENDIF
        MOV	DPTR,#num_inputlen
        MOVX	A,@DPTR
        JNZ	NUM_GSok
        MOV	A,#1
        MOVX	@DPTR,A
        INC	DPTR
        MOV	A,#'0'
        MOVX	@DPTR,A
NUM_GSok:
	MOV	A,#1
        RET
NUM_GSchar:
	CJNE	A,#11,NUM_GSnot10
        JMP	NUM_GSdel
NUM_GSnot10:
	JNC	NUM_GSdel
        ADD	A,#'0'-1
        PUSHACC
        MOV	A,R7
        JZ	NUM_GSmaxreached
        POP	ACC
        DEC	R7
        PUSHB

        IF DT5
        ELSE
         PUSHACC
         MOV	DPTR,#num_inputlen
         MOVX	A,@DPTR
         ADD	A,B
         CALL	LCD_GotoXY
         POP	ACC
         PUSHACC
         CALL	LCD_WriteData
         POP	ACC
	ENDIF

        PUSHACC
        MOV	DPTR,#num_inputlen
        MOVX	A,@DPTR
        INC	A
        MOVX	@DPTR,A
        DEC	A
        MOV	DPTR,#num_inputbuffer
        ADD	A,DPL
        MOV	DPL,A
        MOV	A,DPH
        ADDC	A,#0
        MOV	DPH,A
        POP	ACC
        POP	B
        MOVX	@DPTR,A
        JMP	NUM_GSkey

NUM_GSmaxreached:
	POP	ACC
        JMP	NUM_GSkey

NUM_GSdel:
	MOV	DPTR,#num_inputlen
        MOVX	A,@DPTR
        JZ	NUM_GSnodel
        DEC	A
        MOVX	@DPTR,A
        INC	R7
        ADD	A,B
        PUSHB
        PUSHACC
        CALL	LCD_GotoXY
        MOV	A,#' '
        CALL	LCD_WriteData
        POP	ACC
        CALL	LCD_GotoXY
        POP     B
NUM_GSnodel:
	JMP	NUM_GSkey

;*******

;R7=digits,B=lcdpos, DPTR0=addroflong
NUM_GetMoney:
	PUSHDPH
        PUSHDPL
        PUSHB
        MOV	A,R7
        PUSHACC
        MOV	A,B
        CALL	LCD_GotoXY
        MOV	DPTR,#man_currencystr
        MOV     R7,#2
        CALL	LCD_DisplayStringXRAM
        POP	ACC
        MOV	R7,A
        POP	B
        POP	DPL
        POP	DPH

        MOV	A,R7
        PUSHACC
        PUSHB
        PUSHDPH
        PUSHDPL
        DEC R7	; assume 2 decimal places
        DEC R7
	INC	B
        INC	B
        CALL	NUM_GetNumber
        JZ	NUM_GMcancel1
        MOV	A,#100
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Multiply32by16
	POP	DPL
        POP	DPH
        PUSHDPH
        PUSHDPL
        CALL	MTH_StoreLong
        POP	DPL
        POP	DPH
        POP	B
        JMP     NUM_GMcontinue

NUM_GMcancel1:
	POP	DPL
        POP	DPH
        POP	B
        POP	ACC
        CLR	A
        RET

NUM_GMcontinue:
	POP	ACC
	PUSHDPH
        PUSHDPL
        MOV	R5,A
        PUSHACC
        PUSHB
        MOV	DPSEL,#1
        MOV	DPTR,#buffer
        CALL	NUM_NewFormatMoney
        POP	B
        POP	ACC
        MOV	R5,A
        PUSHACC
        PUSHB
        MOV	A,B
        CALL	LCD_GotoXY
        MOV	DPTR,#buffer
        MOV	A,R5
        MOV	R7,A
        INC	R7
        INC     R7
        INC	R7
        CALL	LCD_DisplayStringXRAM
        MOV	DPSEL,#0
        POP	B
        POP	ACC
        POP	DPL
        POP	DPH
        ADD	A,B
        ADD     A,#1
        MOV	B,A

        MOV	R7,#2
        PUSHDPH
        PUSHDPL
        CALL	NUM_GetNumber
        JZ	NUM_GMcancel2
        POP	DPL
        POP	DPH
        PUSHDPH
        PUSHDPL
        CALL	MTH_LoadOp2Long
        CALL	MTH_AddLongs
        POP	DPL
        POP	DPH
        CALL	MTH_StoreLong
        MOV	A,#1
	RET
NUM_GMcancel2:
	POP	DPL
        POP	DPH
	CLR	A
        RET

NUM_ConvertNumber:
        MOVX	A,@DPTR
        JZ	NUM_GNdone
        MOV	R6,A
        INC	DPTR
        MOV	R0,#mth_operand1
        CALL	MTH_ClearOperand
NUM_GNloop:
	MOV	A,#10
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Multiply32by16
	MOVX	A,@DPTR
	INC	DPTR
	CLR	C
	SUBB	A,#'0'
        CALL	MTH_LoadOp2Acc
        CALL	MTH_AddLongs
        DJNZ	R6,NUM_Gnloop
        MOV	A,#1
NUM_GNdone:
        RET


NUM_GetNumber:
	CALL	NUM_GetString
        MOV	DPTR,#num_inputlen
        CALL	NUM_ConvertNumber
        RET

;*******************************************************************************
;*******************************************************************************
;*******************************************************************************
;*******************************************************************************
;*******************************************************************************

;                            new formatting routines

;*******************************************************************************
;*******************************************************************************
;*******************************************************************************
;*******************************************************************************
;*******************************************************************************

NUM_PARAM_DECIMALB	EQU 0
NUM_PARAM_DECIMAL8	EQU 1
NUM_PARAM_DECIMAL16	EQU 2
NUM_PARAM_DECIMAL32	EQU 3
NUM_PARAM_FLOAT8	EQU 4
NUM_PARAM_FLOAT16	EQU 5
NUM_PARAM_FLOAT32	EQU 6
NUM_PARAM_MONEY		EQU 7
NUM_PARAM_DATE		EQU 8
NUM_PARAM_TIME		EQU 9
NUM_PARAM_DECIMAL8IRAM	EQU 10
NUM_PARAM_STRING	EQU 11
NUM_PARAM_STRINGCODE	EQU 12
NUM_PARAM_TICKETTYPE    EQU 13

NUM_ZEROPAD EQU 32

; R5 bit 3:0 total digits
;    bit   4 sign ?
;    bit   5 padding (1=zero,0=space)
;
; R6 bit 3:0 dot location (0=no dot)
;    bit   4 currency loc (0=left, 1=right)

;******************************************************************************
;
; Function:	NUM_MultipleFormat
; Input:	DPTR2 = formattable
;               DPTR1 = destbuf (not cur used)
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Structure of formattable is:
;   BYTE fieldcount
;   BYTE linestoprint (1 or 2)
;   for each field
;     WORD param addr XRAM
;     WORD dest addr XRAM
;     BYTE R5 formatting control
;     BYTE R6 formatting control
;     BYTE paramtype
;
;******************************************************************************
NUM_MultipleFormat:
	MOV	DPSEL,#2
	CLR	A
	MOVC	A,@A+DPTR
        INC	DPTR
	MOV	R4,A			; number of fields to format
	JZ	NUM_MFnofields
	CLR	A
        MOVC	A,@A+DPTR
        INC	DPTR
        RL	A
        RL	A
        RL	A
        CALL	PRT_SetBitmapLenSmall
NUM_MFloop:
	MOV	DPSEL,#2
	CLR	A
	MOVC	A,@A+DPTR
	MOV	B,A
	INC	DPTR
	CLR	A
	MOVC	A,@A+DPTR
	INC	DPTR
	MOV	DPSEL,#0
	MOV	DPH,A
	MOV	DPL,B			; set up param address
	MOV	DPSEL,#2
	CLR	A
	MOVC	A,@A+DPTR
	MOV	B,A
	INC	DPTR
	CLR	A
	MOVC	A,@A+DPTR
	INC	DPTR
	MOV	DPSEL,#1
	MOV	DPH,A
	MOV	DPL,B			; set up dest address
	MOV	DPSEL,#2
        CLR	A
	MOVC	A,@A+DPTR
        INC	DPTR
        MOV	R5,A			; set up format control param 1
        CLR	A
        MOVC	A,@A+DPTR
        INC	DPTR
        MOV	R6,A			; set up format control param 2
	CLR	A
        MOVC	A,@A+DPTR		; set up param type
        INC	DPTR
        CALL	NUM_NewFormatParameter
	DJNZ	R4,NUM_MFloop
NUM_MFnofields:
	RET

;******************************************************************************
;
; Function:	NUM_NewFormatParameter
; Input:	A = paramtype
;		if paramtype = NUM_PARAM_DECIMALB then
;		  B = parameter
;		else
;		  DPTR0 = address of parameter
;		R5/R6 = format control, dependant on paramtype
;		DPTR1 = destination address for ASCII conversion
;
; Output:	DPTR1 = 1st unused char in destination
; Preserved:	R1-4, DPTR2-7
; Destroyed:	R0/5-7, DPTR0, A, B
; Description:
;   etc
;
;******************************************************************************
        ALIGN   ToPage
NUM_NewFormatParameter:
	MOV	DPSEL,#3
	RL	A
	MOV	DPTR,#param_table
	JMP	@A+DPTR
	RET
param_table:
	AJMP	NUM_NewFormatDecimalB
	AJMP	NUM_NewFormatDecimal8
	AJMP	NUM_NewFormatDecimal16
	AJMP	NUM_NewFormatDecimal32
	AJMP	NUM_NewFormatFloat8
	AJMP	NUM_NewFormatFloat16
	AJMP	NUM_NewFormatFloat32
	AJMP	NUM_NewFormatMoney
	AJMP	NUM_NewFormatDate
	AJMP	NUM_NewFormatTime
	AJMP	NUM_NewFormatDecimal8IRAM
        AJMP	NUM_NewFormatString
        AJMP	NUM_NewFormatStringCODE
        AJMP    NUM_NewFormatTicketType

NUM_NewConvert:
	MOV	R0,#n0
NUM_NCFDloop:
	MOVX	A,@DPTR
	ANL	A,#00Fh
	MOV	@R0,A
	INC	R0
	MOVX	A,@DPTR
	ANL	A,#0F0h
	SWAP	A
	MOV	@R0,A
	INC	R0
	INC	DPTR
	DJNZ	R7,NUM_NCFDloop
	RET

;****************************
; Decimal Formatting Routines
;****************************

NUM_NewFormatDecimalB:
	CALL	ClearDecimal
	MOV	A,B
	MOV	n0,A
	SWAP	A
	ANL	A,#00Fh
	MOV	n1,A
	MOV	A,n0
	ANL	A,#00Fh
	MOV	n0,A
	JMP	NUM_NewFormatDecimal
NUM_NewFormatDecimal8IRAM:
	MOV	DPSEL,#0
	MOV	R0,DPL
	MOV	B,@R0
	JMP	NUM_NewFormatDecimalB
NUM_NewFormatDecimal8:
	CALL	ClearDecimal
	MOV	R7,#1
	JMP	NUM_NewConvertFormatDecimal
NUM_NewFormatDecimal16:
	CALL	ClearDecimal
	MOV	R7,#2
	JMP	NUM_NewConvertFormatDecimal
NUM_NewFormatDecimal32:
	MOV	R7,#4
	JMP	NUM_NewConvertFormatDecimal
NUM_NewConvertFormatDecimal:
	MOV	DPSEL,#0
	CALL	NUM_NewConvert
NUM_NewFormatDecimal:
	MOV	A,R1			; save R1
	PUSHACC
	MOV	DPSEL,#1
	PUSHDPH
	PUSHDPL

	MOV	A,R5
	ANL	A,#0Fh			; len

	MOV	R7,A			; space or zero pad
	MOV	A,R5			; the string leaving
	MOV	B,#' '			; DPTR after last
	JNB	ACC.5,NUM_NFDspacepad	; char
	MOV	B,#'0'			;
NUM_NFDspacepad:			;
	MOV	A,B			;
NUM_NFDpad:				;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	DJNZ	R7,NUM_NFDpad		;

        MOV	A,R5			; remove possible
        ANL	A,#0Fh			; NUM_ZEROPAD bit
        MOV	R5,A			;

NUM_NFDdigit:
	MOV	R1,#n7
	MOV	R0,#n6
	MOV	R7,#7
NUM_NFDnibble:
	MOV	B,#10
	MOV	A,@R1
	DIV	AB
	XCH	A,B
	SWAP	A
	ADD	A,@R0
	MOV	@R0,A
	MOV	@R1,B
	DEC	R1
	DEC	R0
	DJNZ	R7,NUM_NFDnibble
	MOV	A,DPL
	JNZ	NUM_NFDskip
	DEC	DPH
NUM_NFDskip:
	DEC	DPL
	MOV	B,#10
	MOV	A,n0
	DIV	AB
	XCH	A,B
	ADD	A,#48
	MOVX	@DPTR,A
	MOV	n0,B
	MOV	A,n0
	ORL	A,n1
	ORL	A,n2
	ORL	A,n3
	ORL	A,n4
	ORL	A,n5
	ORL	A,n6
	ORL	A,n7
	JZ	NUM_NFDnowzero
	DJNZ	R5,NUM_NFDdigit
NUM_NFDnowzero:
	POP	DPL
	POP	DPH
	POP	ACC			; restore R1
	MOV	R1,A
	RET

;**************************
; Float Formatting Routines
;**************************
NUM_NewFormatFloat8:
	CALL	ClearDecimal
	MOV	R7,#1
	JMP	NUM_NewConvertFormatFloat
NUM_NewFormatFloat16:
	CALL	ClearDecimal
	MOV	R7,#2
	JMP	NUM_NewConvertFormatFloat
NUM_NewFormatFloat32:
	MOV	R7,#4
	JMP	NUM_NewConvertFormatFloat
NUM_NewConvertFormatFloat:
	MOV	DPSEL,#0
	CALL	NUM_NewConvert
NUM_NewFormatFloat:
	MOV	DPSEL,#1
	MOV	A,R6
	ANL	A,#0Fh
	JNZ	NUM_NFFok
	JMP	NUM_NewFormatDecimal
NUM_NFFok:
	MOV	A,R5
	PUSHACC
	PUSHDPH
	PUSHDPL
	INC	DPTR
	CALL	NUM_NewFormatDecimal
	POP	DPL
	POP	DPH
	POP	ACC
	MOV	R5,A
	MOV	A,R6
	ANL	A,#0Fh
	MOV	B,A
	MOV	A,R5
	ANL	A,#0Fh
	CLR	C
	SUBB	A,B
	MOV	R7,A
	CALL	MEM_SetDest
	INC	DPTR
	CALL	MEM_SetSource
	CALL	MEM_CopyXRAMtoXRAMsmall
	MOV	A,#'.'
	MOVX	@DPTR,A
	MOV	A,DPL
	JNZ	NUM_FFskip
	DEC	DPH
NUM_FFskip:
	DEC	DPL
	MOV	A,B
	INC	A
	INC	A
	MOV	R7,A
NUM_FFminzero:
	MOVX	A,@DPTR
	CJNE	A,#' ',NUM_FFnotspace
	MOV	A,#'0'
	MOVX	@DPTR,A
NUM_FFnotspace:
	INC	DPTR
	DJNZ	R7,NUM_FFminzero
	RET

;**************************
; Money Formatting Routines
;**************************
NUM_NewFormatMoney:
	MOV	DPSEL,#0
	MOV	R7,#4
	CALL	NUM_NewConvert
	PUSHDPH
	PUSHDPL
	MOV	DPSEL,#0
	MOV	DPTR,#man_currencyformat
	MOVX	A,@DPTR
	MOV	DPSEL,#1
	JB	ACC.4,NUM_FMnotleft
	CALL	MEM_SetDest
	MOV	DPTR,#man_currencystr
	CALL	MEM_SetSource
	MOV	R7,#2
	CALL	MEM_CopyXRAMtoXRAMsmall
NUM_FMnotleft:
	MOV	DPSEL,#0
	MOV	DPTR,#man_currencyformat
	MOVX	A,@DPTR
	ANL	A,#0Fh
	MOV	DPSEL,#1
	MOV	R6,A
	CALL	NUM_NewFormatFloat
;	INC	DPTR
;NUM_FMloop:
;	INC	DPTR
;	DJNZ	B,NUM_FMloop
	MOV	DPSEL,#0
	MOVX	A,@DPTR
	MOV	DPSEL,#1
	JNB	ACC.4,NUM_FMnotright
	CALL	MEM_SetDest
	MOV	DPTR,#man_currencystr
	CALL	MEM_SetSource
	MOV	R7,#2
	CALL	MEM_CopyXRAMtoXRAMsmall
NUM_FMnotright:
	MOV	DPSEL,#0
	POP	DPL
	POP	DPH
	RET

;*************************
; Date Formatting Routines
;*************************
NUM_NewFormatDate:
	JMP	TIM_FormatDateCustom

;*************************
; Time Formatting Routines
;*************************
NUM_NewFormatTime:
;	PUSHR3
	MOV	A,R3
	PUSHACC
;	PUSHR4
	MOV	A,R4
	PUSHACC
	MOV	R3,#0
	MOV	R4,#0
;	MOV	DPSEL,#0
;	MOV	DPTR,#datebuffer+2
	CALL	TIM_FormatTimeCustom
;	POP	4
	POP	ACC
	MOV	R4,A
;	POP	3
	POP	ACC
	MOV	R3,A
	RET

;***************************
; String Formatting Routines
;***************************
NUM_NewFormatString:
	MOV	A,R5
	MOV	R7,A
	MOV	DPSEL,#0
	CALL	MEM_SetSource
	MOV	DPSEL,#1
	CALL	MEM_SetDest
	CALL	MEM_CopyXRAMtoXRAMsmall
	RET
NUM_NewFormatStringCODE:
	MOV	A,R5
	MOV	R7,A
	MOV	DPSEL,#0
	CALL	MEM_SetSource
	MOV	DPSEL,#1
	CALL	MEM_SetDest
	CALL	MEM_CopyCODEtoXRAMsmall
	RET

;********************************
; Ticket Type Formatting Routines
;********************************
NUM_NewFormatTicketType:
	MOV	DPSEL,#0
        MOVX	A,@DPTR
	MOV	B,A
	MOV	DPSEL,#1
        ANL	A,#0F0h
        JNZ	NUM_NFTTmenutkt
	MOV	A,#32
        MOVX	@DPTR,A
        INC	DPTR
        MOV	A,B
        ANL	A,#0Fh
        ADD     A,#'A'
        MOVX	@DPTR,A
        INC	DPTR
        RET
NUM_NFTTmenutkt:
	MOV	A,B
        INC     A
        MOV	B,A
        MOV	R5,#2
        JMP	NUM_NewFormatDecimalB

;******************************* End Of NUMBER.ASM *****************************
