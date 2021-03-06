;******************************************************************************
;
; File     : RECEIPT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for printing credit card receipts.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

tkt_sales_retailer:
;        len f  mag  x   y string
  DB 255,19,00h,01h, 1,  0,19,'Credit Card Receipt'
  DB 255, 8,00h,00h, 0, 34, 8,'dd/mm/yy'
  DB 255, 5,00h,00h,16, 34, 5,'hh:mm'
  DB 255,21,00h,00h, 2, 52,21,'                     '
  DB 255,13,00h,00h, 8, 70,13,'     ccnnn.nn'
  DB 255,19,00h,00h, 0, 88,19,'Customer Signature:'
  DB 255,21,00h,00h, 0,120,21,'.....................'
  DB 255,19,00h,00h, 1,140,19,'** Retailer Copy **'
  DB 0
tkt_sales_retailer_end:

tkt_tmpl_retsale	EQU 0100h
tkt_tmpl_rsdate		EQU tkt_tmpl_retsale+FIELD_HEADER+19+FIELD_HEADER
tkt_tmpl_rstime		EQU tkt_tmpl_rsdate+8+FIELD_HEADER
tkt_tmpl_rscardnum	EQU tkt_tmpl_rstime+5+FIELD_HEADER
tkt_tmpl_rsvalue	EQU tkt_tmpl_rscardnum+21+FIELD_HEADER
tkt_tmpl_rsmisc1	EQU tkt_tmpl_rsvalue+13+FIELD_HEADER
tkt_tmpl_rsmisc2	EQU tkt_tmpl_rsmisc1+19+FIELD_HEADER
tkt_tmpl_rsmisc3	EQU tkt_tmpl_rsmisc2+21+FIELD_HEADER
tkt_tmpl_rstermination	EQU tkt_tmpl_rsmisc3+19

tkt_retsalelayout:
	DB 4,0
        DW datebuffer			; the date
        DW tkt_tmpl_rsdate
        DB 0,0,NUM_PARAM_DATE
        DW timebuffer			; the time
        DW tkt_tmpl_rstime
        DB 0,0,NUM_PARAM_TIME
        DW crd_buffer			; the card number
        DW tkt_tmpl_rscardnum
        DB 16,0,NUM_PARAM_STRING
        DW tkt_subtot_value		; the transaction total
        DW tkt_tmpl_rsvalue+5
        DB 5,0,NUM_PARAM_MONEY

;******************************************************************************
;
; Function:	TKT_LayoutSalesReceipt
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

TKT_LayoutSalesReceipt:
	MOV	DPTR,#tkt_sales_retailer
        CALL	MEM_SetSource
        MOV	DPTR,#tkt_tmpl_retsale
        CALL	MEM_SetDest
        MOV	R7,#LOW(tkt_sales_retailer_end-tkt_sales_retailer)
        MOV	R6,#HIGH(tkt_sales_retailer_end-tkt_sales_retailer)
        CALL	MEM_CopyCODEtoXRAM
	MOV	DPSEL,#2
        MOV	DPTR,#tkt_retsalelayout
        CALL	NUM_MultipleFormat
	RET

tkt_sales_customer:
;        len f  mag  x   y string
  DB 255,19,00h,01h, 1,  0,19,'Credit Card Receipt'
  DB 255, 8,00h,00h, 0, 34, 8,'dd/mm/yy'
  DB 255, 5,00h,00h,16, 34, 5,'hh:mm'
  DB 255,21,00h,00h, 2, 52,21,'                     '
  DB 255,13,00h,00h, 8, 70,13,'     ccnnn.nn'
  DB 255,19,00h,00h, 1, 90,19,'** Customer Copy **'
  DB 0
tkt_sales_customer_end:

tkt_tmpl_cussale	EQU 0100h
tkt_tmpl_csdate		EQU tkt_tmpl_cussale+FIELD_HEADER+19+FIELD_HEADER
tkt_tmpl_cstime		EQU tkt_tmpl_csdate+8+FIELD_HEADER
tkt_tmpl_cscardnum	EQU tkt_tmpl_cstime+5+FIELD_HEADER
tkt_tmpl_csvalue	EQU tkt_tmpl_cscardnum+21+FIELD_HEADER
tkt_tmpl_csmisc1	EQU tkt_tmpl_csvalue+13+FIELD_HEADER
tkt_tmpl_cstermination	EQU tkt_tmpl_csmisc1+19


tkt_cussalelayout:
	DB 4,0
        DW datebuffer			; the date
        DW tkt_tmpl_csdate
        DB 0,0,NUM_PARAM_DATE
        DW timebuffer			; the time
        DW tkt_tmpl_cstime
        DB 0,0,NUM_PARAM_TIME
        DW crd_buffer			; the card number
        DW tkt_tmpl_cscardnum
        DB 16,0,NUM_PARAM_STRING
        DW tkt_subtot_value		; the transaction total
        DW tkt_tmpl_csvalue+5
        DB 5,0,NUM_PARAM_MONEY

;******************************************************************************
;
; Function:	TKT_LayoutCustomerSalesReceipt
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

TKT_LayoutCustomerSalesReceipt:
	MOV	DPTR,#tkt_sales_customer
        CALL	MEM_SetSource
        MOV	DPTR,#tkt_tmpl_cussale
        CALL	MEM_SetDest
        MOV	R7,#LOW(tkt_sales_customer_end-tkt_sales_customer)
        MOV	R6,#HIGH(tkt_sales_customer_end-tkt_sales_customer)
        CALL	MEM_CopyCODEtoXRAM
	MOV	DPSEL,#2
        MOV	DPTR,#tkt_cussalelayout
        CALL	NUM_MultipleFormat
	RET

;******************************************************************************
;
; Function:	TKT_PrintSalesReceipt
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

TKT_PrintSalesReceipt:
        CALL	PRT_StartPrint

	CALL	TKT_LayoutSalesReceipt
        MOV     A,#148
        CALL    PRT_SetBitmapLenSmall
        CALL	PRT_ClearBitMap
        MOV	DPTR,#tkt_tmpl_retsale
        CALL	PRT_FormatBitmap
        CALL	PRT_PrintBitmap
        CALL    PRT_FormFeed

	CALL	TKT_LayoutCustomerSalesReceipt
        MOV     A,#98
        CALL    PRT_SetBitmapLenSmall
        CALL	PRT_ClearBitMap
        MOV	DPTR,#tkt_tmpl_cussale
        CALL	PRT_FormatBitmap
        CALL	PRT_PrintBitmap
        CALL    PRT_FormFeed

        CALL	PRT_EndPrint
        RET

rec_msg_receipt:
	DB 255,21,00h,01h, 0,  0,21,'=======RECEIPT======='

rec_trx_template: DB 255,21,0,0,0,0,21,'       Total cc99.999'

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

REC_PrintReceiptTitle:
	MOV	DPTR,#rec_msg_receipt
        CALL    PRT_DisplayMessageCODE
        RET

;******************************************************************************
;
; Function:	REC_PrintReceiptSlip
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

rec_msg_vatno: DB 255,21,0,0,0,0,21,'VAT No:              '

REC_PrintReceiptSlip:
	MOV	A,#SYS_AREA_RECEIPTPRINT
        CALL	SYS_SetAreaCode

        MOV	A,#MAN_EXT_RECEIPT
        CALL	PRT_SetPrintDevice

        IF DT10W
        MOV	A,prt_outputdevice
        JNZ	REC_PRSdeviceok
        JMP	PRT_IllegalDevice
REC_PRSdeviceok:
        ENDIF

	CALL	PRT_StartPrint			; print the title line
        CALL	REC_PrintReceiptTitle		;
        MOV     R7,#5				;
        CALL    PRT_LineFeed			;
        CALL	VOI_PrintVoidHeader		; print the header (use VOID)

        MOV	DPTR,#man_receiptctrl
        MOVX	A,@DPTR
        ANL	A,#MAN_RECEIPTVATNO
        JZ	REC_PRStrx

        MOV	A,#8
        CALL	PRT_ClearBitmap
        MOV	DPTR,#rec_msg_vatno
        CALL	MEM_SetSource
        MOV	DPTR,#buffer
        CALL	MEM_SetDest
        MOV	R7,#FIELD_HEADER+21
        CALL	MEM_CopyCODEtoXRAMsmall
        MOV	DPTR,#man_vatno
        MOVX	A,@DPTR
        JZ	REC_PRSzerolenvatno
        INC	DPTR
        MOV	R7,A
        CALL	MEM_SetSource
        MOV	DPTR,#buffer+15
        CALL	MEM_SetDest
        CALL    MEM_CopyXRAMtoXRAMsmall
REC_PRSzerolenvatno:
        MOV	DPTR,#buffer
        CALL	PRT_FormatXRAMField
        CALL	PRT_PrintBitmap
REC_PRStrx:					; receipt a transaction
;	CALL	AUD_FindLastTicket		; of tickets
;        CJNE	A,#AUD_OK,REC_PRSerror		;
REC_PRStrxtktloop:				;
        CALL	TKT_PrintTicketDetails		;
;        CALL	AUD_FindPrevTicket		;
;        CJNE	A,#AUD_OK,REC_PRScheck		;
	JMP	REC_PRStrxtktloop		;
REC_PRScheck:					;
;	CJNE	A,#AUD_ERROR,REC_PRSsubtotal	;
        JMP	REC_PRSerror			;
REC_PRSsubtotal:				;
	MOV	R7,#5				; print the subtotal
        CALL	PRT_LineFeed			;
	MOV	DPTR,#rec_trx_template		;
        CALL	MEM_SetSource			;
        MOV	DPTR,#buffer			;
        CALL	MEM_SetDest			;
        MOV	R7,#28				;
        CALL	MEM_CopyCODEtoXRAMsmall		;
;	CALL	AUD_FetchTransactionDetails	;
        MOV	DPSEL,#0			;
;        MOV	DPTR,#aud_trxtotal		;
        MOV	DPSEL,#1			;
        MOV	DPTR,#buffer+20			;
        MOV	R5,#5				;
        MOV	R6,#0				;
        CALL	NUM_NewFormatMoney		;
	MOV	DPSEL,#0			;
;	MOV	DPTR,#aud_trxnegative		;
	MOVX	A,@DPTR
	JZ	REC_PRSnominussign
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+22			;
	MOV	A,#'-'
	MOVX	@DPTR,A
REC_PRSnominussign:
	CALL	PRT_DisplayOneLiner		;

REC_PRSprinted:					; print the void end line
        MOV     R7,#5				;
        CALL    PRT_LineFeed			;
        CALL	REC_PrintReceiptTitle		;
        MOV	C,prt_paperout
        JMP	REC_PRSdone

REC_PRSerror:
	SETB	C
REC_PRSdone:
	PUSHPSW
        CALL	PRT_FormFeed			; finished using the printer
        CALL	CUT_FireCutter			;
        CALL	PRT_EndPrint			;
        CLR	A
        CALL	PRT_SetPrintDevice
        POP	PSW
	RET

;******************************************************************************
;
; Function:	REC_ReceiptTransaction
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

rec_msg_receipttrx:	DB 19,'Transaction Receipt'
rec_msg_noentries:	DB 22,'No Receiptable Entries'

REC_ReceiptTransaction:
	CALL	LCD_Clear
        MOV	DPTR,#rec_msg_receipttrx
        CALL	LCD_DisplayStringCODE
;        MOV     A,#AUD_TRX			; can receipt transactions only
;        MOV     DPTR,#aud_scanctrl		;
        MOVX    @DPTR,A				;

REC_RTok:
	MOV	A,#SYS_AREA_RECEIPTSELECT
        CALL	SYS_SetAreaCode

;	CALL	AUD_StartTktTrxSelection	; start scanning the audit for
;        CJNE	A,#AUD_OK,REC_RTnotkts		; previous tickets/transactions
REC_RTloop:
	CALL	VOI_DisplayCurrentEntry		; display current entry
;        CALL	AUD_TktTrxSelect		; see what user wants to do
;        CJNE	A,#AUD_OK,REC_RTnotok

	CALL	REC_PrintReceiptSlip		; OK pressed
        PUSHPSW
        CALL	LCD_Clear			; Print the receipt slip
        POP	PSW
	RET					;
REC_RTnotok:					;
;	CJNE	A,#AUD_ABORT,REC_RTnotcancel	;

	CALL	LCD_Clear			; CANCEL pressed, do nothing
        SETB	C
	RET					;

REC_RTnotcancel:				; UP/DOWN pressed, loop
	JMP	REC_RTloop			;

REC_RTnotkts:
	CALL	LCD_Clear
        MOV	DPTR,#rec_msg_noentries
        CALL	LCD_DisplayStringCODE

        IF      SPEAKER
        CALL	SND_Warning
        ENDIF

        SETB	C
        RET

;******************************************************************************
;
; Function:
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

REC_ReceiptLastTransaction:
;        MOV     A,#AUD_TRX			; can receipt transactions only
;        MOV     DPTR,#aud_scanctrl		;
        MOVX    @DPTR,A				;
;	CALL	AUD_StartTktTrxSelection	; scan audit for last trx
;        CJNE	A,#AUD_OK,REC_RLTnotkts		;
	CALL	REC_PrintReceiptSlip		; print the receipt
        RET
REC_RLTnotkts:
	SETB	C
	RET

;******************************************************************************
;
; Function:
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

REC_AutoReceipt:
	MOV	DPTR,#man_receiptctrl
        MOVX	A,@DPTR
        ANL	A,#MAN_AUTORECEIPT
        JZ	REC_ARnoautorec
        CALL	REC_ReceiptLastTransaction
REC_ARnoautorec:
        RET

;******************************************************************************
;
; Function:
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

REC_Receipt:
	MOV	DPTR,#ppg_fixhdr_plugtype
        MOVX	A,@DPTR
        CJNE	A,#PPG_MANAGER,REC_Rnotman
REC_Rany:
        CALL	REC_ReceiptTransaction
        JNC	REC_Rlog
        RET
REC_Rnotman:
	MOV	DPTR,#man_receiptctrl
        MOVX	A,@DPTR
        ANL	A,#MAN_OPRMANRECEIPT
        JZ	REC_Roprfail
        MOVX	A,@DPTR
        ANL	A,#MAN_OPRANYRECEIPT
        JNZ	REC_Rany
        CALL	REC_ReceiptLastTransaction
        JNC	REC_Rlog
REC_Roprfail:
        RET
REC_Rlog:
	MOV	DPSEL,#0
;        MOV	DPTR,#aud_entry_receipt
;        CALL	AUD_AddEntry
        RET

;***************************** End Of RECEIPT.ASM ******************************
