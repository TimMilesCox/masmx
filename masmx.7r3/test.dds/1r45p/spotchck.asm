;******************************************************************************
;
; File     : SPOTCHCK.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the spotcheck routine.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

	IF DT10W

SPOTCHKLEN EQU (21*6)
spt_template:
;        w   f  mag  x   y len string
  DB 255,21,01h,00h, 0,  0,21,'======SPOTCHECK======'
  DB 255,21,01h,00h, 1,  0,21,'Machine Number  xxxxx'
  DB 255,21,01h,00h, 2,  0,21,'Shift Number    xxxxx'
  DB 255,21,01h,00h, 3,  0,21,'Shift Owner       xxx'
  DB 255,21,01h,00h, 4,  0,21,'User Number       xxx'
  DB 255,21,01h,00h, 5,  0,21,'Tkts xxxxxx to xxxxxx'
  DB 255,21,01h,00h, 6,  0,21,'Cash    ccnnnnnnnnnn.'

	IF USE_TMACHS
  DB 255,21,01h,00h, 7,  0,21,'Head Count     xxxxxx'
	ENDIF

  DB 00h
spt_template_end:

	ELSE ; DT10 or DT5

	IF USE_TMACHS
SPOTCHKLEN EQU 109
	ELSE
SPOTCHKLEN EQU 96
	ENDIF

spt_template:
;        w   f  mag  x   y len string
  DB 255,21,00h,01h, 0,  0,21,'======SPOTCHECK======'
  DB 255,21,00h,00h, 0, 23,21,'Machine Number  xxxxx'
  DB 255,21,00h,00h, 0, 36,21,'Shift Number    xxxxx'
  DB 255,21,00h,00h, 0, 49,21,'Shift Owner       xxx'
  DB 255,21,00h,00h, 0, 62,21,'User Number       xxx'
  DB 255,21,00h,00h, 0, 75,21,'Tkts xxxxxx to xxxxxx'
  DB 255,21,00h,00h, 0, 88,21,'Cash    ccnnnnnnnnnn.'

	IF USE_TMACHS
  DB 255,21,00h,00h, 0,101,21,'Head Count     xxxxxx'
	ENDIF

  DB 00h
spt_template_end:

	ENDIF

spt_tmpl_text1		EQU 0100h
spt_tmpl_text2		EQU spt_tmpl_text1+FIELD_HEADER+21
spt_tmpl_dtserial	EQU spt_tmpl_text2+FIELD_HEADER+16
spt_tmpl_text3		EQU spt_tmpl_dtserial+5
spt_tmpl_shift		EQU spt_tmpl_text3+FIELD_HEADER+16
spt_tmpl_text4		EQU spt_tmpl_shift+5
spt_tmpl_owner		EQU spt_tmpl_text4+FIELD_HEADER+18
spt_tmpl_text5		EQU spt_tmpl_owner+3
spt_tmpl_user		EQU spt_tmpl_text5+FIELD_HEADER+18
spt_tmpl_text6		EQU spt_tmpl_user+3
spt_tmpl_first		EQU spt_tmpl_text6+FIELD_HEADER+5
spt_tmpl_text7		EQU spt_tmpl_first+6
spt_tmpl_last		EQU spt_tmpl_text7+4
spt_tmpl_text8		EQU spt_tmpl_last+6
spt_tmpl_cash		EQU spt_tmpl_text8+FIELD_HEADER+8

	IF USE_TMACHS
spt_tmpl_text9		EQU spt_tmpl_cash+13
spt_tmpl_bodycount	EQU spt_tmpl_text9+FIELD_HEADER+15
spt_tmpl_termination	EQU spt_tmpl_bodycount+6
	ELSE
spt_tmpl_termination	EQU spt_tmpl_cash+13
	ENDIF

spt_format:

	IF USE_TMACHS
	 DB 8
	ELSE
	 DB 7
	ENDIF

	DB 0

	DW sys_dtserial			; machine serial number
	DW spt_tmpl_dtserial
	DB 5,0,NUM_PARAM_DECIMAL32

	DW shf_shift			; shift number
	DW spt_tmpl_shift
	DB 5+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW shf_shiftowner			; shift owner number
	DW spt_tmpl_owner
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW ppg_hdr_usernum			; current user number
	DW spt_tmpl_user
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW shf_firstticket		; first ticket number
	DW spt_tmpl_first
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

	DW tkt_number			; last ticket number
	DW spt_tmpl_last
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

	DW shf_runtotal			; running cash total
	DW spt_tmpl_cash
	DB 10,0,NUM_PARAM_MONEY

	IF USE_TMACHS
	 DW lou_bodycount		; bodycount
	 DW spt_tmpl_bodycount
	 DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32
	ENDIF

;******************************************************************************
;
; Function:	SPT_LayoutSpotCheck
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Generates the layout of the spotcheck and fills in all the fields.
;
;******************************************************************************

SPT_LayoutSpotCheck:
	MOV	DPTR,#spt_template
	CALL	MEM_SetSource
	MOV	DPTR,#spt_tmpl_text1
	CALL	MEM_SetDest
	MOV	R7,#(spt_template_end-spt_template)
	CALL	MEM_CopyCODEtoXRAMsmall

	MOV	DPSEL,#2
	MOV	DPTR,#spt_format
	CALL	NUM_MultipleFormat
	RET

;******************************************************************************
;
; Function:	SPT_SpotCheck
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Main entry point for SpotCheck. Prints a spotcheck to the printer.
;
;******************************************************************************

SPT_SpotCheck:
	MOV	A,#SYS_AREA_SPOTCHECK
	CALL	SYS_SetAreaCode

	MOV	A,#MAN_EXT_SPOTCHECK
	CALL	PRT_SetPrintDevice

	CALL	PRT_StartPrint
	MOV	A,#SPOTCHKLEN
	CALL	PRT_SetBitmapLenSmall
	CALL	PRT_ClearBitmap
	CALL	SPT_LayoutSpotCheck
	MOV	A,#SPOTCHKLEN
	CALL	PRT_SetBitmapLenSmall
	MOV	DPTR,#spt_tmpl_text1
	CALL	PRT_FormatBitmap
	CALL	PRT_PrintBitmap
	CALL	PRT_FormFeed
	CALL    CUT_FireCutter
	CALL	PRT_EndPrint
	MOV	DPSEL,#0
;	MOV	DPTR,#aud_entry_spotcheck
;	CALL	AUD_AddEntry

	CLR	A
	CALL	PRT_SetPrintDevice

	CLR     A
	RET

;*************************** End Of SPOTCHCK.ASM ******************************
