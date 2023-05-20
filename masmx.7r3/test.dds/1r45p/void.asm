;******************************************************************************
;
; File     : VOID.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the voiding routines for DT10.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

voi_msg_alreadyvoid:	DB 255,21,0,0,0,0,21,'         Already Void'

;------------------------
;012345678901234567890123
;
;Void Single Ticket
;99     999999 v � 999.99
;
;Void Transaction
;999999-999999   � 999.99
;
;------------------------

voi_msg_voidticket:
	DB 255,21,00h,01h, 0,  0,21,'=====VOID TICKET====='
voi_msg_voidtransaction:
	DB 255,21,00h,01h, 0,  0,21,'===VOID TRANSACTION=='

voi_headertemplate:
;        w   f  mag  x   y len string
  DB 255,21,00h,00h, 0,  0,21,'dd/mm/yy   99999  999' ; date,serial,user
  DB 255,21,00h,00h, 0,  8,21,'hh:mm      99999  999' ; time,shift,owner
  DB 0
voi_headertemplate_end:

voi_headertmpl			EQU 0100h
voi_headertmpl_date		EQU voi_headertmpl+FIELD_HEADER
voi_headertmpl_dtserial		EQU voi_headertmpl_date+11
voi_headertmpl_user		EQU voi_headertmpl_dtserial+7
voi_headertmpl_time		EQU voi_headertmpl_user+3+FIELD_HEADER
voi_headertmpl_shift		EQU voi_headertmpl_time+11
voi_headertmpl_owner		EQU voi_headertmpl_shift+7
voi_headertmpl_termination	EQU voi_headertmpl_owner+3

voi_headerformat:
	DB 6,0

        DW sys_dtserial				; machine serial number
        DW voi_headertmpl_dtserial
        DB 5,0,NUM_PARAM_DECIMAL32

        DW shf_shift				; shift number
        DW voi_headertmpl_shift
        DB 5+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW shf_shiftowner			; shift owner number
	DW voi_headertmpl_owner
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW ppg_hdr_usernum			; current user number
	DW voi_headertmpl_user
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW datebuffer
        DW voi_headertmpl_date			; current date
        DB 0,0,NUM_PARAM_DATE

	DW datebuffer+2
        DW voi_headertmpl_time			; current time
        DB 0,0,NUM_PARAM_TIME

voi_tkttemplate:
  DB 255,21,00h,00h, 0,  0,21,'                     ' ; ticket descr line 1
  DB 255,21,00h,00h, 0,  8,21,'99999 999999 cc999.99' ; groupqty,ticket,value
  DB 0
voi_tkttemplate_end:

voi_tkttmpl			EQU 0100h
voi_tkttmpl_desc1		EQU FIELD_HEADER
voi_tkttmpl_groupqty		EQU voi_tkttmpl_desc1+21+FIELD_HEADER
voi_tkttmpl_ticket		EQU voi_tkttmpl_groupqty+6
voi_tkttmpl_value		EQU voi_tkttmpl_ticket+7
voi_tkttmpl_termination		EQU voi_tkttmpl_value+8

voi_tktformat:
	DB 3,0

        DW 0;aud_groupqty
        DW voi_tkttmpl_groupqty
        DB 5,0,NUM_PARAM_DECIMAL16

        DW 0;aud_ticketnum
        DW voi_tkttmpl_ticket
        DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

        DW 0;aud_tkttotal
        DW voi_tkttmpl_value
        DB 5,0,NUM_PARAM_MONEY

voi_trx_template: DB 255,21,0,0,0,0,21,'       Total cc99.999'

;******************************************************************************
;
; Function:	VOI_DisplayCurrentEntry
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Displays the current entry to be voided, as picked from the scrolling list.
;
;******************************************************************************

VOI_DisplayCurrentEntry:
        MOV     DPTR,#buffer
        MOV     A,#' '
        MOV     R7,#24
        CALL    MEM_FillXRAMsmall

;	MOV	DPTR,#aud_scanctrl
        MOVX	A,@DPTR
;	CJNE	A,#AUD_TKT,VOI_DCEtrxext
	JMP	VOI_DCEtkt
VOI_DCEtrxext:
	JMP	VOI_DCEtrx

VOI_DCEtkt:
;        CALL	AUD_FetchTicketDetails

        MOV	DPSEL,#0			; display ticket type
;        MOV	DPTR,#aud_tickettype		;
        MOV	DPSEL,#1			;
        MOV	DPTR,#buffer			;
        MOV	R5,#0				;
	MOV	R6,#0				;
	CALL	NUM_NewFormatTicketType		;

	MOV	DPSEL,#0			; display ticket number
;	MOV	DPTR,#aud_ticketnum		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+7			;
	MOV	R5,#6+NUM_ZEROPAD		;
        MOV	R6,#0				;
        CALL	NUM_NewFormatDecimal32		;

	MOV	DPSEL,#0			; display ticket value
;	MOV	DPTR,#aud_tkttotal		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+16			;
	MOV	R5,#5				;
	MOV	R6,#0				;
	CALL	NUM_NewFormatMoney		;

	MOV	DPSEL,#0			; display minus sign
;	MOV	DPTR,#aud_discount		;
	MOVX	A,@DPTR
	JZ      VOI_DCEnominussign
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+18			;
	MOV	A,#'-'
	MOVX	@DPTR,A
VOI_DCEnominussign:

;	MOV	DPTR,#aud_disctrans
	MOVX	A,@DPTR
	JZ	VOI_DCEnotdisctrans
	MOV	DPTR,#buffer+14
	MOV	A,#'d'
	MOVX	@DPTR,A
VOI_DCEnotdisctrans:

;	MOV	DPTR,#aud_macrotkt
	MOVX	A,@DPTR
	JZ	VOI_DCEnotmacrotkt
	MOV	DPTR,#buffer+14
	MOV	A,#'m'
	MOVX	@DPTR,A
VOI_DCEnotmacrotkt:

;	MOV	DPTR,#aud_tkttime		;
	MOVX	A,@DPTR
	ANL	A,#128
	JZ	VOI_DCEnotvoid
	MOV	DPTR,#buffer+14
	MOV	A,#'v'
	MOVX	@DPTR,A
VOI_DCEnotvoid:

	CALL	LCD_Clear2
	MOV     A,#64				;
	CALL    LCD_GotoXY			;
	MOV	DPTR,#buffer			;
	MOV	R7,#24				;
	CALL	LCD_DisplayStringXRAM		;
	RET

VOI_DCEtrx:
;	CALL	AUD_FetchTransactionDetails	;

VOI_DCEfindfirst:
;	CALL	AUD_FindPrevTicket
;	CJNE	A,#AUD_OK,VOI_DCEgotfirst
	JMP	VOI_DCEfindfirst
VOI_DCEgotfirst:
;	CALL	AUD_FetchTicketDetails
	MOV	DPSEL,#0			;
;	MOV	DPTR,#aud_ticketnum		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer			;
	MOV	R5,#6+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

;	CALL	AUD_FindLastTicket
;	CALL	AUD_FetchTicketDetails
	MOV	DPSEL,#0			;
;	MOV	DPTR,#aud_ticketnum		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+7			;
	MOV	R5,#6+NUM_ZEROPAD		;
	MOV	R6,#0				;
	CALL	NUM_NewFormatDecimal32		;

	MOV	DPTR,#buffer+6
	MOV	A,#'-'
	MOVX	@DPTR,A

	MOV	DPSEL,#0			; display trx value
;	MOV	DPTR,#aud_trxtotal		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+16			;
	MOV	R5,#5				;
	MOV	R6,#0				;
	CALL	NUM_NewFormatMoney		;

	MOV	DPSEL,#0			; display minus sign
;	MOV	DPTR,#aud_trxnegative		;
	MOVX	A,@DPTR
	JZ      VOI_DCEnominussign2
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+18			;
	MOV	A,#'-'
	MOVX	@DPTR,A

VOI_DCEnominussign2:
	CALL	LCD_Clear2
	MOV	A,#64				;
	CALL	LCD_GotoXY			;
	MOV	DPTR,#buffer			;
        MOV	R7,#24				;
        CALL	LCD_DisplayStringXRAM		;
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

VOI_MarkTicketVoid:
;	MOV	DPTR,#aud_ticketh
        CALL	MTH_LoadOp1Long
;        MOV	DPTR,#aud_ptr
        CALL	MTH_StoreLong
VOI_MTVloop:
;	MOV	DPTR,#aud_ptr
;        CALL	AUD_AuditEntryAddr
        MOVX	A,@DPTR
        CJNE	A,#50,VOI_MTVnot50
	JMP	VOI_MTVmark
VOI_MTVnot50:
        CJNE	A,#51,VOI_MTVnot51
	JMP	VOI_MTVmark
VOI_MTVnot51:
        CJNE	A,#53,VOI_MTVnot53
	JMP	VOI_MTVmark
VOI_MTVnot53:
        CJNE	A,#54,VOI_MTVnot54
	JMP	VOI_MTVmark
VOI_MTVnot54:
;        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
 ;       MOV	DPTR,#aud_tickett
        CALL	MTH_LoadOp2Long
        CALL	MTH_CompareLongs
        JNZ	VOI_MTVdone
;        MOV	DPTR,#aud_ptr
;        CALL	AUD_NextEntry
        JMP	VOI_MTVloop
VOI_MTVdone:
	RET
VOI_MTVmark:
	INC	DPTR
        MOVX	A,@DPTR				; set the void bit
        ORL	A,#128				; as bit 7 in the time field
	MOVX	@DPTR,A				;
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

VOI_PrintVoidTitle:
;        MOV     DPTR,#aud_scanctrl
        MOVX    A,@DPTR
;        CJNE    A,#AUD_TKT,VOI_PVTtrx
        MOV     DPTR,#voi_msg_voidticket
        JMP     VOI_PVTtitle
VOI_PVTtrx:
	MOV	DPTR,#voi_msg_voidtransaction
VOI_PVTtitle:
        CALL    PRT_DisplayMessageCODE
        RET

;******************************************************************************
;
; Function:	VOI_PrintVoidHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

VOI_PrintVoidHeader:
        MOV	A,#21				;
        CALL	PRT_SetBitmapLenSmall		;
        CALL	PRT_ClearBitmap			;

        CALL	TIM_GetDateTime			;
	MOV	DPTR,#voi_headertemplate	;
	CALL	MEM_SetSource			;
	MOV	DPTR,#voi_headertmpl		;
	CALL	MEM_SetDest			;
	MOV	R7,#(voi_headertemplate_end-voi_headertemplate)
	CALL	MEM_CopyCODEtoXRAMsmall		;
        MOV	DPSEL,#2			;
        MOV	DPTR,#voi_headerformat		;
        CALL	NUM_MultipleFormat		;

        MOV	A,#21				; print the void header
        CALL	PRT_SetBitmapLenSmall		; details
        MOV	DPTR,#voi_headertmpl		;
        CALL	PRT_FormatBitmap		;
        CALL	PRT_PrintBitmap			;
        RET

;******************************************************************************
;
; Function:	VOI_PrintVoidTicketDetails
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

VOI_PrintVoidTicketDetails:
	CALL	TKT_PrintTicketDetails
;        MOV	DPTR,#aud_tkttime
        MOVX	A,@DPTR
        ANL	A,#128
        JZ	VOI_PVTDdone
        MOV	DPTR,#voi_msg_alreadyvoid
        CALL	PRT_DisplayMessageCODE
VOI_PVTDdone:
	RET

;******************************************************************************
;
; Function:	VOI_PrintVoidSlip
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
VOI_PVSerror2:	JMP	VOI_PVSerror		; long jump to error

VOI_PrintVoidSlip:
	MOV	A,#SYS_AREA_VOIDPRINT
        CALL	SYS_SetAreaCode

        MOV	A,#MAN_EXT_VOID
        CALL	PRT_SetPrintDevice

        IF DT10W
        MOV	A,prt_outputdevice
        JNZ	VOI_PVSdeviceok
        JMP	PRT_IllegalDevice
VOI_PVSdeviceok:
        ENDIF

	CALL	PRT_StartPrint			; print the void title line
        CALL	VOI_PrintVoidTitle		;
        MOV     R7,#5				;
        CALL    PRT_LineFeed			;
        CALL	VOI_PrintVoidHeader		; print the header

;        MOV     DPTR,#aud_scanctrl		; decide if its ticket
        MOVX    A,@DPTR				; or transaction mode
;        CJNE    A,#AUD_TKT,VOI_PVStrx		;

        CALL    VOI_PrintVoidTicketDetails	; void a single ticket
        JMP     VOI_PVSprinted			;

VOI_PVStrx:					; void a transaction
;	CALL	AUD_FindLastTicket		; of tickets
;        CJNE	A,#AUD_OK,VOI_PVSerror2		;
VOI_PVStrxtktloop:				;
        CALL	VOI_PrintVoidTicketDetails	;
;        CALL	AUD_FindPrevTicket		;
;        CJNE	A,#AUD_OK,VOI_PVScheck		;
	JMP	VOI_PVStrxtktloop		;
VOI_PVScheck:					;
;	CJNE	A,#AUD_ERROR,VOI_PVSsubtotal	;
	JMP	VOI_PVSerror			;
VOI_PVSsubtotal:				;
	MOV	R7,#5				; print the subtotal
	CALL	PRT_LineFeed			;
	MOV	DPTR,#voi_trx_template		;
	CALL	MEM_SetSource			;
	MOV	DPTR,#buffer			;
	CALL	MEM_SetDest			;
	MOV	R7,#28				;
	CALL	MEM_CopyCODEtoXRAMsmall		;
;	CALL	AUD_FetchTransactionDetails	;
	MOV	DPSEL,#0			;
;	MOV	DPTR,#aud_trxtotal		;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+20			;
	MOV	R5,#5				;
	MOV	R6,#0				;
	CALL	NUM_NewFormatMoney		;
	MOV	DPSEL,#0			;
;	MOV	DPTR,#aud_trxnegative		;
	MOVX	A,@DPTR
	JZ	VOI_PVSnominussign
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+22			;
	MOV	A,#'-'
	MOVX	@DPTR,A
VOI_PVSnominussign:
	CALL	PRT_DisplayOneLiner		;

VOI_PVSprinted:					; print the void end line
        MOV     R7,#5				;
        CALL    PRT_LineFeed			;
        CALL	VOI_PrintVoidTitle		;

;        MOV     DPTR,#aud_scanctrl		; decide if its ticket
        MOVX    A,@DPTR				; or transaction mode
;        CJNE    A,#AUD_TKT,VOI_PVSaudittrx	;

;        MOV     DPTR,#aud_tkttime		; abort if ticket
        MOVX    A,@DPTR				; already voided
        ANL     A,#128				;
        JNZ     VOI_PVSauditdone		;

        CALL	SHF_CancelTicket		; update waybill and audit
        CALL    VOI_MarkTicketVoid		;
        MOV	DPSEL,#0			; for a single ticket
;        MOV	DPTR,#aud_entry_voidtkt		;
;        CALL	AUD_AddEntry			;
        JMP	VOI_PVSauditdone		;

VOI_PVSaudittrx:				; update waybill and audit
;	CALL	AUD_FindLastTicket		; for a transaction of
 ;       CJNE	A,#AUD_OK,VOI_PVSerror		; tickets
VOI_PVSaudtrxtktloop:				;
;	CALL	AUD_FetchTicketDetails		;

;        MOV     DPTR,#aud_tkttime		; abort if ticket
        MOVX    A,@DPTR				; already voided
        ANL     A,#128				;
        JNZ     VOI_PVSnexttkt			;

	CALL	SHF_CancelTicket		;
	CALL	VOI_MarkTicketVoid		;
        MOV	DPSEL,#0			;
;        MOV	DPTR,#aud_entry_voidtkt		;
 ;       CALL	AUD_AddEntry			;
VOI_PVSnexttkt:
  ;      CALL	AUD_FindPrevTicket		;
;        CJNE	A,#AUD_OK,VOI_PVSaudcheck	;
	JMP	VOI_PVSaudtrxtktloop		;
VOI_PVSaudcheck:				;
;	CJNE	A,#AUD_ERROR,VOI_PVSauditdone	;
        JMP	VOI_PVSerror			;

VOI_PVSauditdone:

VOI_PVSerror:
        CALL	PRT_FormFeed			; finished using the printer
        CALL	CUT_FireCutter			;
        CALL	PRT_EndPrint			;
        CLR	A
        CALL	PRT_SetPrintDevice
	RET

;******************************************************************************
;
; Function:	VOI_VoidTicket & VOI_VoidTransaction
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Lets the user scan up and down looking for a transaction or ticket to void.
;   Calls VOI_PrintVoidSlip when the user has picked the ticket/transaction.
;
;******************************************************************************

voi_msg_voidtkt:	DB 11,'Void Ticket'
voi_msg_voidtrx:	DB 16,'Void Transaction'
voi_msg_noentries:	DB 19,'No Voidable Entries'
voi_msg_voidmacro1:	DB 22,'Cannot Void Individual'
voi_msg_voidmacro2:	DB 13,'Macro Tickets'
voi_msg_voiddisctrans1:	DB 22,'Cannot Void Tickets In'
voi_msg_voiddisctrans2:	DB 22,'Discounted Transaction'

VOI_VoidTicket:
	CALL	LCD_Clear
	MOV	DPTR,#voi_msg_voidtkt
	CALL	LCD_DisplayStringCODE
;	MOV     A,#AUD_TKT			; can void any single ticket
;	MOV     DPTR,#aud_scanctrl		;
	MOVX    @DPTR,A				;
	JMP	VOI_VTok

VOI_VoidTransaction:
	CALL	LCD_Clear
	MOV	DPTR,#voi_msg_voidtrx
	CALL	LCD_DisplayStringCODE
;	MOV     A,#AUD_TRX			; can void transactions only
;	MOV     DPTR,#aud_scanctrl		;
	MOVX    @DPTR,A				;

VOI_VTok:
	MOV	A,#SYS_AREA_VOIDSELECT
	CALL	SYS_SetAreaCode

;	CALL	AUD_StartTktTrxSelection	; start scanning the audit for
;	CJNE	A,#AUD_OK,VOI_VTnotkts		; previous tickets/transactions
VOI_VTloop:
	CALL	VOI_DisplayCurrentEntry		; display current entry
;	CALL	AUD_TktTrxSelect		; see what user wants to do
;	CJNE	A,#AUD_OK,VOI_VTnotok

;	MOV	DPTR,#aud_macrotkt              ; disallow voiding of
	MOVX	A,@DPTR                         ; individual macro tickets
	JZ	VOI_VTnotmacro                  ;
;	MOV	DPTR,#aud_scanctrl		; allow voiding of macro
	MOVX	A,@DPTR                         ; transactions
;	CJNE	A,#AUD_TKT,VOI_VTnotmacro       ;

	CALL	LCD_Clear	                ;
	MOV	DPTR,#voi_msg_voidmacro1	;
	CALL	LCD_DisplayStringCODE		;
	MOV	A,#64                           ;
	CALL	LCD_GotoXY                      ;
	MOV	DPTR,#voi_msg_voidmacro2	;
	CALL	LCD_DisplayStringCODE		;

        IF      SPEAKER
	CALL	SND_Warning                     ;
        ENDIF

	MOV	R0,#10                          ;
	CALL	delay100ms                      ;
	CALL	LCD_Clear
	RET

VOI_VTnotmacro:
;	MOV	DPTR,#aud_disctrans 		; disallow voiding of
	MOVX	A,@DPTR                         ; individual tickets in
	JZ	VOI_VTnotdisctrans 		; transactions with discounts
;	MOV	DPTR,#aud_scanctrl		; allow voiding of discount
	MOVX	A,@DPTR                         ; transactions
;	CJNE	A,#AUD_TKT,VOI_VTnotdisctrans

	CALL	LCD_Clear	                ;
	MOV	DPTR,#voi_msg_voiddisctrans1	;
	CALL	LCD_DisplayStringCODE		;
	MOV	A,#64                           ;
	CALL	LCD_GotoXY                      ;
	MOV	DPTR,#voi_msg_voiddisctrans2	;
	CALL	LCD_DisplayStringCODE		;

        IF      SPEAKER
	CALL	SND_Warning                     ;
        ENDIF

	MOV	R0,#10                          ;
	CALL	delay100ms                      ;
	CALL	LCD_Clear
	RET

VOI_VTnotdisctrans:
	CALL	VOI_PrintVoidSlip		; OK pressed
	CALL	LCD_Clear			; Print the void slipped
	RET					;

VOI_VTnotok:					;
;	CJNE	A,#AUD_ABORT,VOI_VTnotcancel	;

	CALL	LCD_Clear			; CANCEL pressed, do nothing
	RET					;

VOI_VTnotcancel:				; UP/DOWN pressed, loop
	JMP	VOI_VTloop			;

VOI_VTnotkts:
	CALL	LCD_Clear
	MOV	DPTR,#voi_msg_noentries
        CALL	LCD_DisplayStringCODE

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

        RET

;******************************************************************************
;
; Function:	VOI_VoidOther
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Void Other Amount is not coded yet.
;
;******************************************************************************

VOI_VoidOther:

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

	RET

;******************************************************************************
;
; Function:	VOI_Void
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Main entry point for voiding. Display the appropriate menu for voiding.
;
;******************************************************************************

voi_menu_title:		DB 1
			DB '=======Void Menu======'
			DW 0
voi_menu_ticket:	DB 'Void Ticket           '
			DW VOI_VoidTicket
voi_menu_transaction:	DB 'Void Transaction      '
			DW VOI_VoidTransaction
voi_menu_other: 	DB 'Void Other Amount     '
			DW VOI_VoidOther

VOI_Void:
	CALL	MNU_NewMenu			; load up the menu title
        MOV	DPTR,#voi_menu_title		;
        CALL	MNU_LoadMenuCODE		;

	MOV	DPTR,#ppg_fixhdr_plugtype	; generate a mask which
	MOVX	A,@DPTR				; defines which void
        CJNE	A,#PPG_MANAGER,VOI_Vopr		; options we are allowed
        MOV	A,#070h				; based on the manager
	JMP	VOI_Vmask			; config and the current
VOI_Vopr:					; type of priceplug
	MOV	A,#007h				;
VOI_Vmask:					;
	MOV	B,A				;
        MOV	DPTR,#man_voidctrl		;
        MOVX	A,@DPTR				;
        ANL	A,B				;
        MOV	B,A				;
        SWAP	A				;
        ORL	A,B				;
        ANL	A,#7				;
        JZ      VOI_Vnotallowed			;
        PUSHACC					; add "Void Ticket"
        JNB	ACC.0,VOI_Vnotkt		; if allowed
        MOV	DPTR,#voi_menu_ticket		;
        CALL	MNU_AddMenuItem			;
VOI_Vnotkt:					;
	POP	ACC				;
	PUSHACC					; add "Void Transaction"
	JNB	ACC.1,VOI_Vnotrx		; if allowed
	MOV	DPTR,#voi_menu_transaction	;
	CALL	MNU_AddMenuItem			;
VOI_Vnotrx:					;
	POP	ACC				;
	PUSHACC					; add "Void Other Amount"
	JNB	ACC.2,VOI_Vnoother		; if allowed
	MOV	DPTR,#voi_menu_other		;
	CALL	MNU_AddMenuItem			;
VOI_Vnoother:					;
	POP	ACC				;
	CALL	MNU_SelectMenuOption		; let user choose option
	RET
VOI_Vnotallowed:

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

	RET

        End
;****************************** End Of VOID.ASM *******************************
