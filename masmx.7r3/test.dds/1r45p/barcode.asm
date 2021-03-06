;******************************************************************************
;
; File     : BARCODE.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for the barcode drivers for
;            all customer's DT10s.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
; 1. As of DT version 2.68, the code is common between DT5, DT10, DT10W.
;    However, the barcode drivers have not been updated to include landscape
;    barcodes, so for the moment, you cannot print barcodes on a DT10W
;    wide or narrow. The only wristbander which ever printed barcodes was
;    the slave wristbander SWB and the recently modded but unreleased
;    DT10W v1.02 code before the wristband code was combined into the
;    standard DT10 code. Therefore, if you are the poor guy who has to get
;    the wristbander printing barcodes, I suggest you look at the drivers
;    from the SWB and the old WRIST directory. The code doesn't need much
;    changing from what I recall.
;******************************************************************************

;Following parameter duplicated in the config program
BCD_2OF5_HEIGHT		EQU 40	; height of the stripey bit

bcd_digitbuffer:	VAR 16	; for storing decimal digits of barcode
bcd_digitgroup:		VAR 4	; for storing parts of binary barcode data
bcd_bodies:		VAR 2	; for storing summed body count

; various parameters (like tkt_ticket) are used in the barcode, but the
; formatted requires that they are copied into bcd_ticket first and then
; formatted from there. This gets round the problem where printing a
; receipt requires an old ticket number to be formatted without destroying
; the current ticket number sequence.
bcd_ticket:		VAR 4	; ticket number for formatting

;*** DDS Demo Security ***
	IF USE_DDS
BCD_VIR_HIGH		EQU 4
BCD_VIR_LOW		EQU 1
bcd_name:		DB 24,'Directional Data Systems'
	ENDIF

;*** Paignton Security ***
	IF USE_PAIGNTON
BCD_VIR_HIGH		EQU 4 ; virtual security digit (high byte)
BCD_VIR_LOW		EQU 2 ; virtual security digit (low byte)
bcd_name:		DB 24,'      Paignton Zoo      '
	ENDIF

;*** MetroLand Security ***
	IF USE_METROLAND
BCD_VIR_HIGH		EQU 4 ; virtual security digit (high byte)
BCD_VIR_LOW		EQU 3 ; virtual security digit (low byte)
bcd_name:		DB 24,'     New Metroland      '
	ENDIF

;*** Powerscourt Security ***
	IF USE_POWERSCOURT
BCD_VIR_HIGH		EQU 4 ; virtual security digit (high byte)
BCD_VIR_LOW		EQU 4 ; virtual security digit (low byte)
bcd_name:		DB 24,'      Powerscourt       '
	ENDIF

;*** Bedford Rugby Club Security ***
	IF USE_BEDFORD
BCD_VIR_HIGH		EQU 4 ; virtual security digit (high byte)
BCD_VIR_LOW		EQU 5 ; virtual security digit (low byte)
bcd_name:		DB 24,'   Bedford Rugby Club   '
	ENDIF

	IF USE_BARCODES

;******************************************************************************
;
;  L o w   L e v e l   B a r c o d e   G e n e r a t i o n   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_GetBarPattern:
	INC	A
	MOVC	A,@A+PC
	RET
bcode2of5:
	DB 030h,088h,048h,0C0h,028h,0A0h,060h,018h,090h,050h

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_ExtrudeBarcode:
	MOV	R5,#BCD_2OF5_HEIGHT
	MOV	DPSEL,#0
	CALL	MEM_SetSource
	MOV	DPSEL,#1
	MOV	DPH,srcDPH
	MOV	DPL,srcDPL
BCD_EBloop:
	MOV	DPSEL,#0
	CALL	MEM_SetSource
	MOV	DPSEL,#1
	MOV	A,#32
	CALL	AddAtoDPTR
	CALL	MEM_SetDest
	MOV	DPSEL,#2
	MOV	R7,#32
	CALL	MEM_CopyXRAMtoXRAMsmall
	DJNZ	R5,BCD_EBloop
	RET

;******************************************************************************
;
; Function:	BCD_FormatCode2of5
; Input:	DPTR0=address in bitmap of where to start barcode
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

	IF USE_DDS_DT10W OR USE_DDS_DT10W_NETWORK OR USE_DDS_DT10W_NARROW OR USE_DDS_DT10W_NETWORK_NARROW

	IF USE_DDS_DT10W_NARROW OR USE_DDS_DT10W_NETWORK_NARROW

DIGIT_PAIRS	EQU	4
DIGITS		EQU	8
DIGITS_POS	EQU	0

	ELSE

DIGIT_PAIRS	EQU	5
DIGITS		EQU	10
DIGITS_POS	EQU	0

	ENDIF

BCD_NextDot:
	MOV	A,B
	RR	A
	CJNE	A,#080h,BCD_NDok		; wrap every 8 bits
	INC	DPTR
BCD_NDok:
	MOV	B,A
	RET

	ELSE

DIGIT_PAIRS	EQU	8
DIGITS		EQU	16
DIGITS_POS	EQU	2

BCD_NextDot:
	MOV	A,B
	RR	A
	CJNE	A,#02h,BCD_NDok		; wrap every 6 bits
	INC	DPTR
	MOV	A,#080h
BCD_NDok:
	MOV	B,A
	RET

	ENDIF

BCD_FormatCode2of5:
	PUSHDPH
	PUSHDPL

	MOVX	A,@DPTR			; start pattern
	ORL	A,#0A0h			;
	MOVX	@DPTR,A			;

	MOV	B,#008h
	MOV	DPSEL,#1
	MOV	DPTR,#bcd_digitbuffer

	MOV     R7,#DIGIT_PAIRS
BCD_FCcharloop:
	MOV	DPSEL,#1		; get 1st decimal digit
	MOVX	A,@DPTR
	CLR     C
	SUBB    A,#'0'
	INC	DPTR

	CALL	BCD_GetBarPattern
	MOV	R3,A

	MOVX	A,@DPTR			; get 2nd decimal digit
	CLR     C
	SUBB    A,#'0'
	INC	DPTR

	CALL	BCD_GetBarPattern
	MOV	R4,A


	MOV	R5,#5
	MOV	DPSEL,#0
BCD_FC5barloop:
	MOVX	A,@DPTR			; place a narrow
	ORL	A,B			; solid line
	MOVX	@DPTR,A			;
	CALL	BCD_NextDot		;

	MOV	A,R3			; check if we need
	RLC	A			; to widen it
	MOV	R3,A			;
	JNC	BCD_FCnarrow1st		;

	MOVX	A,@DPTR			; widen it
	ORL	A,B			;
	MOVX	@DPTR,A			;
	CALL	BCD_NextDot		;

BCD_FCnarrow1st:
	CALL	BCD_NextDot		; place a narrow space

	MOV	A,R4			; check if we need
	RLC	A			; to widen it
	MOV	R4,A			;
	JNC	BCD_FCnarrow2nd		;

	CALL	BCD_NextDot		; widen it

BCD_FCnarrow2nd:
	DJNZ	R5,BCD_FC5barloop

	DJNZ	R7,BCD_FCcharloop

	MOVX	A,@DPTR			; end pattern
	ORL	A,B			;
	MOVX	@DPTR,A			;
	CALL	BCD_NextDot		;
	MOVX	A,@DPTR			;
	ORL	A,B			;
	MOVX	@DPTR,A			;
	CALL	BCD_NextDot		;
	CALL	BCD_NextDot		;
	MOVX	A,@DPTR			;
	ORL	A,B			;
	MOVX	@DPTR,A			;
	CALL	BCD_NextDot		;

	POP	DPL
	POP	DPH
	CALL	BCD_ExtrudeBarcode		; extend barcode height

        MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDNUMEXCL
        JNZ	BCD_FCnodigits

	MOV	prt_field_width,#DIGITS		; place the numerical
	MOV	prt_field_mag,#0        	; version under the
	MOV	prt_field_x,#DIGITS_POS	 	; barcode
	MOV	prt_field_len,#DIGITS		;
        MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDNUMABOVE
        JNZ	BCD_FCdigitsabove
	MOV	DPTR,#ppg_oper_barcodeypos	;
	MOVX	A,@DPTR				;
	ADD	A,#BCD_2OF5_HEIGHT+2		;
        JMP	BCD_FCsetdigitpos
BCD_FCdigitsabove:
	MOV	DPTR,#ppg_oper_barcodeypos
        MOVX	A,@DPTR
        CLR	C
BCD_FCsetdigitpos:
	MOV	prt_field_y,A			;
	INC	DPTR				;
	MOVX	A,@DPTR				;
	ANL	A,#7				;
	ADDC	A,#0				;
	SWAP	A				;
	RL	A				;
	RL	A				;
	MOV	prt_field_flags,A		;
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R7,#DIGITS				;
	MOV	R0,#prt_field_str		;
BCD_FCdigloop:					;
	MOVX	A,@DPTR				;
	INC	DPTR				;
	MOV	@R0,A				;
	INC	R0				;
	DJNZ	R7,BCD_FCdigloop		;
	CALL	PRT_FormatField			;
BCD_FCnodigits:

	RET

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_GenerateBarcode:
	MOV	DPSEL,#0
	MOV	DPTR,#ppg_oper_barcodeypos
	MOVX	A,@DPTR
	MOV	B,A
	INC	DPTR
	MOVX	A,@DPTR
	ORL	A,B
	JZ	BCD_GBnobarcode

        MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDNUMABOVE
        JNZ	BCD_GBdigitsabove

	MOV     DPTR,#ppg_oper_barcodeypos
	MOVX    A,@DPTR
        JMP	BCD_GBsetbcdpos
BCD_GBdigitsabove:
	MOV	DPTR,#ppg_oper_barcodeypos
        MOVX	A,@DPTR
        ADD	A,#10				; DOESNT WORK WITH 16bit YPOS
BCD_GBsetbcdpos:
	SWAP	A
	RL	A
	PUSHACC
	ANL	A,#0E0h
	MOV	B,A
	INC	DPTR
	MOVX	A,@DPTR
	MOV	DPL,B
	SWAP	A
	RL	A
	MOV	B,A
	POP	ACC
	ANL	A,#01Fh
	ORL	A,B
	MOV	B,DPL
	MOV	DPTR,#prt_bitmap
	XCH     A,B
	CALL	AddABtoDPTR
	CALL	BCD_FormatCode2of5
BCD_GBnobarcode:
	RET

;******************************************************************************
;
;  H i g h   L e v e l   B a r c o d e   G e n e r a t i o n   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
;                        D D S   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_DDS_DT10 OR USE_DDS_DT10_NETWORK OR USE_SEAT_DEMO OR USE_ALTON

;******************************************************************************
;
; Function:	BCD_PrepareBarcode		DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

BCD_PrepareBarcode:
	MOV	DPTR,#bcd_bodies		; start with the groupqty
        CALL	MTH_LoadOp1Word			;

	MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#16				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the month
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#4				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the year
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_year			;
	MOVX	A,@DPTR				;
	ANL	A,#3				; (year % 4)
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#64				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#63				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#2				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the non-ticket
	CALL	MTH_Multiply32by16		; (add 0 = do nothing)

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store last 8 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer+7		;
	MOV	R5,#8+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_ticket		; start with the ticket
	CALL	MTH_LoadOp1Long			; number

	MOV	A,#8				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the area/zone
	CALL	MTH_Multiply32by16		;
        CALL    TKT_TSCtrl			;
        MOVX    A,@DPTR				;
        ANL	A,#7				;
        MOV	DPTR,#tkt_zone			;
        MOVX	@DPTR,A				;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store first 7 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#7+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#8				;
	MOV	B,#BCD_VIR_HIGH			;
BCD_PBloop1:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop1			;
						;
	CALL	MTH_LoadOp1Acc			;
	MOV	A,#3				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Multiply32by16		;
						;
	MOV	DPTR,#bcd_digitbuffer+1		;
	MOV	R7,#7				;
	MOV	B,#BCD_VIR_LOW			;
BCD_PBloop2:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop2			;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;
	MOV	A,#10				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Divide32by16		;
	MOV	A,mth_op2ll			;
	JZ	BCD_PBgotcheck			;
	MOV	B,A				;
	MOV	A,#10				;
	CLR	C				;
	SUBB	A,B				;
BCD_PBgotcheck:					;
	MOV	DPTR,#bcd_digitbuffer+15	;
	ADD     A,#'0'				;
	MOVX	@DPTR,A				;
	RET

;******************************************************************************
;
; Function:	BCD_FormatBarcode		DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDLASTTKT
        JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
        MOV	DPTR,#tkt_number
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
        CALL    BCD_ResetTotals
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_ResetTotals:
        CLR	A
        CALL	MTH_LoadOp1Acc
	MOV	DPTR,#bcd_bodies
	CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_AppendToTotals:
        MOV	DPTR,#bcd_bodies		; add the size of this group
	CALL	MTH_LoadOp1Word			; to the body count for this
	MOV	DPTR,#tkt_groupqty		; transaction
	CALL	MTH_LoadOp2Word			;
	CALL	MTH_AddWords			;
	MOV	DPTR,#bcd_bodies		;
	CALL	MTH_StoreWord			;
	RET

;******************************* End Of DDS **************************************
	ENDIF	; DDS

;******************************************************************************
;
;                 W r i s t b a n d   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_DDS_DT10W OR USE_DDS_DT10W_NETWORK

;******************************************************************************
;
; Function:	BCD_PrepareBarcode
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

const8192: DW 8192

BCD_PrepareBarcode:
	CALL	TKT_TSCtrl			; start with the zone
	MOVX	A,@DPTR
	ANL	A,#7				;
	CALL	MTH_LoadOp1Acc

	MOV     DPTR,#const8192			; shift up and add
	MOV     R0,#mth_operand2		; in the ticket number
	CALL    MTH_LoadConstWord		;
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#bcd_ticket		;
	CALL	MTH_LoadOp2Long			;
        CALL	MTH_AddLongs			;

	MOV	A,#32				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the day
        CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
        CALL	MTH_AddLongs

        MOV	A,#16				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the month
        CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
        CALL	MTH_LoadOp2Byte			;
        CALL	MTH_AddLongs			;

	MOV	A,#16				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#15				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store 9 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#9+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#5
	MOV	B,#BCD_VIR_HIGH
BCD_PBloop1:
	MOVX	A,@DPTR
	CLR     C
	SUBB    A,#'0'
	INC	DPTR
	INC	DPTR
	ADD	A,B
	MOV	B,A
	DJNZ	R7,BCD_PBloop1

	CALL	MTH_LoadOp1Acc
	MOV	A,#3
	CALL	MTH_LoadOp2Acc
	CALL	MTH_Multiply32by16

	MOV	DPTR,#bcd_digitbuffer+1
	MOV	R7,#4
	MOV	B,#BCD_VIR_LOW
BCD_PBloop2:
	MOVX	A,@DPTR
	CLR     C
	SUBB    A,#'0'
	INC	DPTR
	INC	DPTR
	ADD	A,B
	MOV	B,A
	DJNZ	R7,BCD_PBloop2
	CALL	MTH_LoadOp2Acc
	CALL	MTH_AddLongs
	MOV	A,#10
	CALL	MTH_LoadOp2Acc
	CALL	MTH_Divide32by16
	MOV	A,mth_op2ll
	JZ	BCD_PBgotcheck
	MOV	B,A
	MOV	A,#10
	CLR	C
	SUBB	A,B
BCD_PBgotcheck:
	MOV	DPTR,#bcd_digitbuffer+9
	ADD     A,#'0'
	MOVX	@DPTR,A
	RET

;*******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
	MOVX	A,@DPTR
	ANL	A,#MAN_BCDLASTTKT
	JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
	MOV	DPTR,#tkt_number
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#bcd_ticket
	CALL	MTH_StoreLong

	MOV	DPTR, #bcd_ticket		; bcd_ticket & 8192
	INC 	DPTR				;
	MOVX	A, @DPTR                        ;
	ANL	A, #31                          ;
	MOVX	@DPTR, A                        ;
	MOV	A, #0                           ;
	INC 	DPTR                            ;
	MOVX	@DPTR, A                        ;
	INC	DPTR                            ;
	MOVX	@DPTR, A                        ;

	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
	CALL    BCD_ResetTotals
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_ResetTotals:
	CLR	A
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#bcd_bodies
	CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_AppendToTotals:
	MOV	DPTR,#bcd_bodies		; add the size of this group
	CALL	MTH_LoadOp1Word			; to the body count for this
	MOV	DPTR,#tkt_groupqty		; transaction
	CALL	MTH_LoadOp2Word			;
	CALL	MTH_AddWords			;
	MOV	DPTR,#bcd_bodies		;
	CALL	MTH_StoreWord			;
	RET

;******************************* End Of Wristbander ******************************
	ENDIF	; Wristbander

	IF USE_DDS_DT10W_NARROW OR USE_DDS_DT10W_NETWORK_NARROW

;******************************************************************************
;
; Function:	BCD_PrepareBarcode
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

const8192: DW 8192

BCD_PrepareBarcode:
	CALL	TKT_TSCtrl			; start with the zone
	MOVX	A,@DPTR
	ANL	A,#7				;
	CALL	MTH_LoadOp1Acc

	MOV     DPTR,#const8192			; shift up and add
	MOV     R0,#mth_operand2		; in the ticket number
	CALL    MTH_LoadConstWord		;
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#bcd_ticket		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_AddLongs			;

	MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs

	MOV	A,#4				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#3				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store 9 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#7+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#4
	MOV	B,#BCD_VIR_HIGH
BCD_PBloop1:
	MOVX	A,@DPTR
	CLR     C
	SUBB    A,#'0'
	INC	DPTR
	INC	DPTR
	ADD	A,B
	MOV	B,A
	DJNZ	R7,BCD_PBloop1

	CALL	MTH_LoadOp1Acc
	MOV	A,#3
	CALL	MTH_LoadOp2Acc
	CALL	MTH_Multiply32by16

	MOV	DPTR,#bcd_digitbuffer+1
	MOV	R7,#3
	MOV	B,#BCD_VIR_LOW
BCD_PBloop2:
	MOVX	A,@DPTR
	CLR     C
	SUBB    A,#'0'
	INC	DPTR
	INC	DPTR
	ADD	A,B
	MOV	B,A
	DJNZ	R7,BCD_PBloop2
	CALL	MTH_LoadOp2Acc
	CALL	MTH_AddLongs
	MOV	A,#10
	CALL	MTH_LoadOp2Acc
	CALL	MTH_Divide32by16
	MOV	A,mth_op2ll
	JZ	BCD_PBgotcheck
	MOV	B,A
	MOV	A,#10
	CLR	C
	SUBB	A,B
BCD_PBgotcheck:
	MOV	DPTR,#bcd_digitbuffer+7
	ADD     A,#'0'
	MOVX	@DPTR,A
	RET

;*******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
	MOVX	A,@DPTR
	ANL	A,#MAN_BCDLASTTKT
	JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
	MOV	DPTR,#tkt_number
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#bcd_ticket
	CALL	MTH_StoreLong

	MOV	DPTR, #bcd_ticket		; bcd_ticket & 8192
	INC 	DPTR				;
	MOVX	A, @DPTR                        ;
	ANL	A, #31                          ;
	MOVX	@DPTR, A                        ;
	MOV	A, #0                           ;
	INC 	DPTR                            ;
	MOVX	@DPTR, A                        ;
	INC	DPTR                            ;
	MOVX	@DPTR, A                        ;

	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
	CALL    BCD_ResetTotals
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_ResetTotals:
	CLR	A
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#bcd_bodies
	CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		DDS SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_AppendToTotals:
	MOV	DPTR,#bcd_bodies		; add the size of this group
	CALL	MTH_LoadOp1Word			; to the body count for this
	MOV	DPTR,#tkt_groupqty		; transaction
	CALL	MTH_LoadOp2Word			;
	CALL	MTH_AddWords			;
	MOV	DPTR,#bcd_bodies		;
	CALL	MTH_StoreWord			;
	RET

;******************************* End Of Wristbander ******************************
	ENDIF	; Wristbander


;******************************************************************************
;
;                   P a i g n t o n   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_PAIGNTON
;******************************************************************************
;
; Function:	BCD_PrepareBarcode			PAIGNTON SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

const1024: DW 1024

BCD_PrepareBarcode:
        MOV	DPTR,#tkt_normalturnstile	; start with the
        MOVX	A,@DPTR				; normalturnstile flag
        CALL	MTH_LoadOp1Acc			;

        MOV	A,#128				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the groupqty
        CALL	MTH_Multiply32by16		;
        MOV	DPTR,#bcd_bodies		;
        CALL	MTH_LoadOp2Word			;
        CALL	MTH_AddLongs			;

        MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
        CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
        CALL	MTH_LoadOp2Byte			;
        CALL	MTH_AddLongs			;

        MOV	A,#16				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the month
        CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
        CALL	MTH_LoadOp2Byte			;
        CALL	MTH_AddLongs			;

	MOV	A,#4				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the year
        CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_year			;
        MOVX	A,@DPTR				;
        ANL	A,#3				; (year % 4)
        CALL	MTH_LoadOp2Acc			;
        CALL	MTH_AddLongs			;

        MOV	A,#64				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the node
        CALL	MTH_Multiply32by16		;
        MOV	A,sys_mynode			;
        ANL	A,#63				;
        CALL	MTH_LoadOp2Acc			;
        CALL	MTH_AddLongs			;

        MOV	A,#2				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the non-ticket
        CALL	MTH_Multiply32by16		; (add 0 = do nothing)

        MOV	DPSEL,#0			;
        MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store last 8 digits
        MOV	DPSEL,#1			; in barcodebuffer
        MOV	DPTR,#bcd_digitbuffer+7		;
        MOV	R5,#8+NUM_ZEROPAD		;
        MOV	R6,#0				;
        CALL	NUM_NewFormatDecimal32		;

	CLR	A				; zero - used to be the
        CALL	MTH_LoadOp1Acc			; entrance category

        MOV	A,#2				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the disabledturnstile
        CALL	MTH_Multiply32by16		;
        MOV	DPTR,#tkt_disabledturnstile	;
        CALL	MTH_LoadOp2Byte			;
        CALL	MTH_AddLongs			;

        MOV     DPTR,#const1024			; shift up and add
        MOV     R0,#mth_operand2		; in the ticket number
        CALL    MTH_LoadConstWord		;
	CALL	MTH_Multiply32by16		;
        MOV     DPTR,#const1024			; shift up and add
        MOV     R0,#mth_operand2		; in the ticket number
        CALL    MTH_LoadConstWord		;
        CALL	MTH_Multiply32by16		;
        MOV	DPTR,#bcd_ticket		;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_AddLongs			;

        MOV	DPSEL,#0			;
        MOV	DPTR,#bcd_digitgroup		;
        CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store first 7 digits
        MOV	DPSEL,#1			; in barcodebuffer
        MOV	DPTR,#bcd_digitbuffer		;
        MOV	R5,#7+NUM_ZEROPAD		;
        MOV	R6,#0				;
        CALL	NUM_NewFormatDecimal32		;

        ; need to generate check digit here

        MOV	DPTR,#bcd_digitbuffer
	MOV	R7,#8
        MOV	B,#4
BCD_PBloop1:
	MOVX	A,@DPTR
        CLR     C
        SUBB    A,#'0'
        INC	DPTR
        INC	DPTR
        ADD	A,B
	MOV	B,A
        DJNZ	R7,BCD_PBloop1

        CALL	MTH_LoadOp1Acc
        MOV	A,#3
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Multiply32by16

        MOV	DPTR,#bcd_digitbuffer+1
        MOV	R7,#7
        MOV	B,#2
BCD_PBloop2:
	MOVX	A,@DPTR
	CLR     C
        SUBB    A,#'0'
        INC	DPTR
        INC	DPTR
        ADD	A,B
        MOV	B,A
        DJNZ	R7,BCD_PBloop2
        CALL	MTH_LoadOp2Acc
        CALL	MTH_AddLongs
        MOV	A,#10
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Divide32by16
        MOV	A,mth_op2ll
        JZ	BCD_PBgotcheck
        MOV	B,A
        MOV	A,#10
        CLR	C
        SUBB	A,B
BCD_PBgotcheck:
	MOV	DPTR,#bcd_digitbuffer+15
        ADD     A,#'0'
        MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	BCD_FormatBarcode		PAIGNTON SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDLASTTKT
        JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
        MOV     DPTR,#tkt_year			; for paigton ticket, mask
	MOVX    A,@DPTR				; off the upper bits of
        ANL     A,#3				; the year leaving
        MOVX    @DPTR,A				; year%4
        MOV	DPTR,#tkt_number
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
	CALL	BCD_PrepareBarcode
        CALL	BCD_GenerateBarcode
        CALL	BCD_ResetTotals
BCD_FBnotlast:
        RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			PAIGNTON SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_ResetTotals:
        CLR	A
	MOV	DPTR,#tkt_normalturnstile
        MOVX	@DPTR,A
        MOV	DPTR,#tkt_disabledturnstile
        MOVX	@DPTR,A
        CALL	MTH_LoadOp1Acc
	MOV	DPTR,#bcd_bodies
        CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		PAIGNTON SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_AppendToTotals:
	CALL	TKT_TSCtrl			; set the barcode turnstile
        MOVX	A,@DPTR				; bit if this ticket is
        ANL	A,#4				; allowed through the turnstile
        RR	A				;
        RR	A				;
        MOV	B,A				;
        MOV	DPTR,#tkt_normalturnstile	;
        MOVX	A,@DPTR				;
        ORL	A,B				;
        MOVX	@DPTR,A				;

	CALL	TKT_TSCtrl			; set the barcode disabled
        MOVX	A,@DPTR				; bit if this ticket is
        ANL	A,#8				; allowed through the gate
        RR	A				;
        RR	A				;
        RR	A				;
        MOV	B,A				;
        MOV	DPTR,#tkt_disabledturnstile	;
	MOVX	A,@DPTR				;
        ORL	A,B				;
        MOVX	@DPTR,A				;

        CALL	TKT_TSCtrl			; skip appending the body
        MOVX	A,@DPTR				; count if neither the gate
        ANL	A,#0Ch				; or turnstile bits are set
        JZ	BCD_ATTnobodies			;
        MOV	DPTR,#bcd_bodies		; add the size of this group
	CALL	MTH_LoadOp1Word			; to the body count for this
        MOV	DPTR,#tkt_groupqty		; transaction
        CALL	MTH_LoadOp2Word			;
        CALL	MTH_AddWords			;
        MOV	DPTR,#bcd_bodies		;
        CALL	MTH_StoreWord			;
BCD_ATTnobodies:
	RET

;******************************* End Of PAIGNTON ******************************
	ENDIF	; PAIGNTON

;******************************************************************************
;
;                  M e t r o l a n d   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_METROLAND

;******************************************************************************
;
; Function:	BCD_PrepareBarcode		METROLAND SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

BCD_PrepareBarcode:
	CLR	A				; 8 bits blank
	CALL	MTH_LoadOp1Acc			;

	MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#16				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the month
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#4				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the year
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_year			;
	MOVX	A,@DPTR				;
	ANL	A,#3				; (year % 4)
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#64				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#63				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#2				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the non-ticket
	CALL	MTH_Multiply32by16		; (add 0 = do nothing)

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store last 8 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer+7		;
	MOV	R5,#8+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_ticket		; start with the ticket
	CALL	MTH_LoadOp1Long			; number

	MOV	A,#8				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the area/zone
	CALL	MTH_Multiply32by16		;
        CALL    TKT_TSCtrl			;
        MOVX    A,@DPTR				;
	ANL	A,#7				;
        MOV	DPTR,#tkt_zone			;
        MOVX	@DPTR,A				;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store first 7 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#7+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#8				;
	MOV	B,#BCD_VIR_HIGH			;
BCD_PBloop1:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop1			;
						;
	CALL	MTH_LoadOp1Acc			;
	MOV	A,#3				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Multiply32by16		;
						;
	MOV	DPTR,#bcd_digitbuffer+1		;
	MOV	R7,#7				;
	MOV	B,#BCD_VIR_LOW			;
BCD_PBloop2:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop2			;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;
	MOV	A,#10				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Divide32by16		;
	MOV	A,mth_op2ll			;
	JZ	BCD_PBgotcheck			;
	MOV	B,A				;
	MOV	A,#10				;
	CLR	C				;
	SUBB	A,B				;
BCD_PBgotcheck:					;
	MOV	DPTR,#bcd_digitbuffer+15	;
	ADD     A,#'0'				;
	MOVX	@DPTR,A				;
	RET

;******************************************************************************
;
; Function:	BCD_PrepareBarcodeWB		METROLAND SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

	IF USE_SLAVE
const8192: DW 8192

BCD_PrepareBarcodeWB:
	CALL	TKT_TSCtrl			; start with the zone
	MOVX	A,@DPTR
	ANL	A,#7				;
	CALL	MTH_LoadOp1Acc			;

	MOV     DPTR,#const8192			; shift up and add
	MOV     R0,#mth_operand2		; in the ticket number
	CALL    MTH_LoadConstWord		;
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#bcd_ticket		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_AddLongs			;

	MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs

	MOV	A,#16				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the month
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

        MOV	A,#16				; shift up and add
        CALL	MTH_LoadOp2Acc			; in the node
        CALL	MTH_Multiply32by16		;
        MOV	A,sys_mynode			;
        CLR	C				;
        SUBB	A,#SLAVE_NODE_SHIFT		;
        ANL	A,#15				;
        CALL	MTH_LoadOp2Acc			;
        CALL	MTH_AddLongs			;

        MOV	DPSEL,#0			;
        MOV	DPTR,#bcd_digitgroup		;
        CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store 9 digits
        MOV	DPSEL,#1			; in barcodebuffer
        MOV	DPTR,#bcd_digitbuffer		;
        MOV	R5,#9+NUM_ZEROPAD		;
        MOV	R6,#0				;
        CALL	NUM_NewFormatDecimal32		;

        MOV	DPTR,#bcd_digitbuffer		; calculate check digit
        MOV	R7,#5
        MOV	B,#BCD_VIR_HIGH
BCD_PBWBloop1:
	MOVX	A,@DPTR
        CLR     C
        SUBB    A,#'0'
        INC	DPTR
        INC	DPTR
        ADD	A,B
        MOV	B,A
        DJNZ	R7,BCD_PBWBloop1

        CALL	MTH_LoadOp1Acc
        MOV	A,#3
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Multiply32by16

        MOV	DPTR,#bcd_digitbuffer+1
        MOV	R7,#4
        MOV	B,#BCD_VIR_LOW
BCD_PBWBloop2:
	MOVX	A,@DPTR
        CLR     C
        SUBB    A,#'0'
        INC	DPTR
        INC	DPTR
        ADD	A,B
        MOV	B,A
        DJNZ	R7,BCD_PBWBloop2
        CALL	MTH_LoadOp2Acc
        CALL	MTH_AddLongs
        MOV	A,#10
        CALL	MTH_LoadOp2Acc
        CALL	MTH_Divide32by16
        MOV	A,mth_op2ll
        JZ	BCD_PBWBgotcheck
        MOV	B,A
        MOV	A,#10
        CLR	C
        SUBB	A,B
BCD_PBWBgotcheck:
	MOV	DPTR,#bcd_digitbuffer+9
        ADD     A,#'0'
        MOVX	@DPTR,A
	RET
	ENDIF	; SLAVE

;******************************************************************************
;
; Function:	BCD_FormatBarcode		METROLAND SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDLASTTKT
        JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
	IF USE_SLAVE
	CALL	TKT_TicketOutDevice		; check which type
	MOVX	A,@DPTR				; of barcode to generate
        CJNE	A,#2,BCD_FBnotslave		;
	MOV	DPTR,#tkt_slavenumber
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
        CALL	BCD_PrepareBarcodeWB		; wristband barcode, just
        RET					; prepare the ASCII string
        ENDIF	; SLAVE

BCD_FBnotslave:
        MOV	DPTR,#tkt_number
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			METROLAND SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Nothing to do, metroland's barcode do not allowed multiple tickets to be
;   encoded in a single barcode because it is a ride system (not an entry
;   system) and there is no body count within the barcode.
;
;******************************************************************************

BCD_ResetTotals:
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		METROLAND SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Nothing to do, metroland's barcode do not allowed multiple tickets to be
;   encoded in a single barcode because it is a ride system (not an entry
;   system) and there is no body count within the barcode.
;
;******************************************************************************

BCD_AppendToTotals:
	RET

;******************************* End Of METROLAND ******************************
	ENDIF	; METROLAND

;******************************************************************************
;
;              P o w e r s c o u r t   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_POWERSCOURT

;******************************************************************************
;
; Function:	BCD_PrepareBarcode		POWERSCOURT SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

BCD_PrepareBarcode:
        MOV	DPTR,#bcd_bodies		; start with the groupqty
        CALL	MTH_LoadOp1Word			;

	MOV	A,#32				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the day
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_day			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#16				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the month
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_month			;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	A,#4				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the year
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkt_year			;
	MOVX	A,@DPTR				;
	ANL	A,#3				; (year % 4)
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#64				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#63				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#2				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the non-ticket
	CALL	MTH_Multiply32by16		; (add 0 = do nothing)

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store last 8 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer+7		;
	MOV	R5,#8+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_ticket		; start with the ticket
	CALL	MTH_LoadOp1Long			; number

	MOV	A,#8				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the area/zone
	CALL	MTH_Multiply32by16		;
        CALL    TKT_TSCtrl			;
        MOVX    A,@DPTR				;
        ANL	A,#7				;
        MOV	DPTR,#tkt_zone			;
        MOVX	@DPTR,A				;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store first 7 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#7+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#8				;
	MOV	B,#BCD_VIR_HIGH			;
BCD_PBloop1:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop1			;
						;
	CALL	MTH_LoadOp1Acc			;
	MOV	A,#3				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Multiply32by16		;
						;
	MOV	DPTR,#bcd_digitbuffer+1		;
	MOV	R7,#7				;
	MOV	B,#BCD_VIR_LOW			;
BCD_PBloop2:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop2			;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;
	MOV	A,#10				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Divide32by16		;
	MOV	A,mth_op2ll			;
	JZ	BCD_PBgotcheck			;
	MOV	B,A				;
	MOV	A,#10				;
	CLR	C				;
	SUBB	A,B				;
BCD_PBgotcheck:					;
	MOV	DPTR,#bcd_digitbuffer+15	;
	ADD     A,#'0'				;
	MOVX	@DPTR,A				;
	RET

;******************************************************************************
;
; Function:	BCD_FormatBarcode		POWERSCOURT SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDLASTTKT
        JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
        MOV	DPTR,#tkt_number
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
        CALL    BCD_ResetTotals
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			POWERSCOURT SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_ResetTotals:
        CLR	A
        CALL	MTH_LoadOp1Acc
        MOV	DPTR,#bcd_bodies
        CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		POWERSCOURT SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_AppendToTotals:
        MOV	DPTR,#bcd_bodies		; add the size of this group
        CALL	MTH_LoadOp1Word			; to the body count for this
        MOV	DPTR,#tkt_groupqty		; transaction
        CALL	MTH_LoadOp2Word			;
        CALL	MTH_AddWords			;
        MOV	DPTR,#bcd_bodies		;
        CALL	MTH_StoreWord			;
	RET

;******************************* End Of POWERSCOURT ******************************
	ENDIF	; POWERSCOURT

;******************************************************************************
;
;        B e d f o r d   R u g b y   C l u b   B a r c o d e   S y s t e m
;
;******************************************************************************
	IF USE_BEDFORD

;******************************************************************************
;
; Function:	BCD_PrepareBarcode		BEDFORD SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the decimal barcode string based upon the required fields.
;   Generally this encoding is customer specific.
;
;******************************************************************************

BCD_PrepareBarcode:
        MOV	DPTR,#bcd_bodies		; start with the groupqty
        CALL	MTH_LoadOp1Word			;

	MOV	A,#64				; shift up and add in the
	CALL	MTH_LoadOp2Acc			; fixture number
	CALL	MTH_Multiply32by16		;
	MOV	A,#64				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Multiply32by16		;
	MOV	DPTR,#tkc_fixture		;
        CALL	MTH_LoadOp2Word			;
        ANL	mth_op2lh,#15			;
	CALL	MTH_AddLongs			;

	MOV	A,#64				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the node
	CALL	MTH_Multiply32by16		;
	MOV	A,sys_mynode			;
	ANL	A,#63				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;

	MOV	A,#2				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the non-ticket
	CALL	MTH_Multiply32by16		; (add 0 = do nothing)

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store last 8 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer+7		;
	MOV	R5,#8+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_ticket		; start with the ticket
	CALL	MTH_LoadOp1Long			; number

	MOV	A,#8				; shift up and add
	CALL	MTH_LoadOp2Acc			; in the area/zone
	CALL	MTH_Multiply32by16		;
        CALL    TKT_TSCtrl			;
        MOVX    A,@DPTR				;
        ANL	A,#7				;
        MOV	DPTR,#tkt_zone			;
        MOVX	@DPTR,A				;
	CALL	MTH_LoadOp2Byte			;
	CALL	MTH_AddLongs			;

	MOV	DPSEL,#0			;
	MOV	DPTR,#bcd_digitgroup		;
	CALL	MTH_StoreLong			;

	MOV	DPTR,#bcd_digitgroup		; store first 7 digits
	MOV	DPSEL,#1			; in barcodebuffer
	MOV	DPTR,#bcd_digitbuffer		;
	MOV	R5,#7+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#bcd_digitbuffer		; calculate check digit
	MOV	R7,#8				;
	MOV	B,#BCD_VIR_HIGH			;
BCD_PBloop1:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop1			;
						;
	CALL	MTH_LoadOp1Acc			;
	MOV	A,#3				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Multiply32by16		;
						;
	MOV	DPTR,#bcd_digitbuffer+1		;
	MOV	R7,#7				;
	MOV	B,#BCD_VIR_LOW			;
BCD_PBloop2:					;
	MOVX	A,@DPTR				;
	CLR     C				;
	SUBB    A,#'0'				;
	INC	DPTR				;
	INC	DPTR				;
	ADD	A,B				;
	MOV	B,A				;
	DJNZ	R7,BCD_PBloop2			;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddLongs			;
	MOV	A,#10				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_Divide32by16		;
	MOV	A,mth_op2ll			;
	JZ	BCD_PBgotcheck			;
	MOV	B,A				;
	MOV	A,#10				;
	CLR	C				;
	SUBB	A,B				;
BCD_PBgotcheck:					;
	MOV	DPTR,#bcd_digitbuffer+15	;
	ADD     A,#'0'				;
	MOVX	@DPTR,A				;
	RET

;******************************************************************************
;
; Function:	BCD_FormatBarcode		BEDFORD SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

BCD_FormatBarcode:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_BCDLASTTKT
        JZ	BCD_FBdoit
	CALL	TKT_LastTicket			;
	JNC	BCD_FBnotlast			;
BCD_FBdoit:
        MOV	DPTR,#tkt_number
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#bcd_ticket
        CALL	MTH_StoreLong
	CALL	BCD_PrepareBarcode		; dt barcode, prepare string
	CALL	BCD_GenerateBarcode		; and render into bitmap
        CALL    BCD_ResetTotals
BCD_FBnotlast:
	RET

;******************************************************************************
;
; Function:	BCD_ResetTotals			BEDFORD SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_ResetTotals:
	CLR	A
        CALL	MTH_LoadOp1Acc
        MOV	DPTR,#bcd_bodies
        CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	BCD_AppendToTotals		BEDFORD SPECIFIC
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

BCD_AppendToTotals:
        MOV	DPTR,#bcd_bodies		; add the size of this group
        CALL	MTH_LoadOp1Word			; to the body count for this
        MOV	DPTR,#tkt_groupqty		; transaction
        CALL	MTH_LoadOp2Word			;
        CALL	MTH_AddWords			;
        MOV	DPTR,#bcd_bodies		;
        CALL	MTH_StoreWord			;
	RET

;******************************* End Of BEDFORD ******************************
	ENDIF	; BEDFORD

	ENDIF	; USE_BARCODES

;******************************************************************************
;
; XQ10 Slave Barcode Scanning Demo Code
;
;******************************************************************************

bcd_scannerinput: VAR 32

BCD_CheckScannerInput:
	MOV	B,#COM_COM1			; see if any chars
	CALL	COM_Test			; in comms input buffer
	JZ	BCD_CSInoinput			;

	CALL LCD_Clear
	MOV	DPTR,#bcd_scannerinput		; start of buffer
	MOV	R7,#0				; no chars rxed yet
BCD_CSIloop:
	MOV	A,#32				; check for buffer
	CLR	C				; overflow
	SUBB	A,R7				;
	JC	BCD_CSIoverflow			;

	MOV	B,#COM_COM1			; get next char
	MOV	R5,#2				; bail out if timeout
	CALL	COM_RxCharTimeout		;
	JNC	BCD_CSItimeout			;
	MOVX	@DPTR,A				; store in buffer
	INC	DPTR
	INC	R7

	PUSHACC
	CALL	LCD_WriteData
	POP	ACC

	CJNE	A,#10,BCD_CSIloop		; loop if more

	MOV	A,#7				; make sure its
	CLR	C				; at least 8
	SUBB	A,R7				; chars long
	JNC	BCD_CSItooshort			;

	SETB	C				; LF terminated barcode
	RET					; in buffer
BCD_CSItooshort:
BCD_CSIoverflow:
BCD_CSItimeout:
BCD_CSInoinput:
	CLR	C				; no barcode received
	RET

;******************************* End Of BARCODE.ASM ***************************
;