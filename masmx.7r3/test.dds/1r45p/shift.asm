;******************************************************************************
;
; File     : SHIFT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routine for doing the Waybill, and the
;            handling of the statistical records of ticket sales.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************

;                           S h i f t   S t a t i s t i c s

;******************************************************************************


SHF_STAT_FORMAT		EQU (2+4+4)
SHF_STATS_FORMAT	EQU ((TKT_MENU_TICKETS_MAX+TKT_HOTKEY_TICKETS_MAX)*(2+4+4))

shf_runtotal:		VAR 4
shf_voidtkttotal:	VAR 4
shf_voidothertotal:	VAR 4
shf_discounttotal:	VAR 4
shf_voiddiscount:	VAR 4
shf_stats:		VAR SHF_STATS_FORMAT

shf_timefrom:		VAR 4	; date/time of shift start
shf_timeto:		VAR 4	; date/time of shift end
shf_firstticket:	VAR 4	; ticket no. of 1st ticket
shf_lastticket:		VAR 4	; ticket no. of last ticket
shf_shift:		VAR 4	; shift number (UWORD+2 dummy bytes)
shf_declaretakings:	VAR 4
shf_netttotal:		VAR 4	; calc'ed at end shift = runtotal-voidtotals
shf_negative:		VAR 1

;******************************************************************************
;
; Function:	SHF_ClearStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Clears out the shift statistics, running total and void total(s).
;
;******************************************************************************

SHF_ClearStats:
	MOV	DPTR,#shf_runtotal
	MOV	R7,#LOW(SHF_STATS_FORMAT+20)
	MOV     R6,#HIGH(SHF_STATS_FORMAT+20)
	CLR     A
	CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	SHF_RecordTicket
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Records the ticket in the shift statistics based upon the current setting
;   of various ticketing parameters: tkt_type, tkt_count and tkt_value
;
;******************************************************************************

SHF_RecordTicket:
	MOV	DPTR,#tkt_type			;
	MOVX	A,@DPTR				;
	MOV	B,#SHF_STAT_FORMAT		;
	MUL	AB				;
	MOV	DPTR,#shf_stats			;
        CALL    AddABToDPTR			;

	PUSHDPH		; DPTR = ptr to count field in stats
	PUSHDPL
	CALL	MTH_LoadOp1Word
	MOV	A,#1
	CALL	MTH_LoadOp2Acc
	CALL	MTH_AddWords
	POP	DPL
	POP	DPH
	CALL	MTH_StoreWord

        PUSHDPH		; DPTR = ptr to groupqty field in stats
        PUSHDPL
	CALL	MTH_LoadOp1Long
        MOV	DPTR,#tkt_groupqty
        CALL	MTH_LoadOp2Word
        CALL	MTH_AddLongs
        POP	DPL
        POP	DPH
        CALL	MTH_StoreLong

	PUSHDPH		; DPTR = ptr to value field in stats
	PUSHDPL
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#tkt_value
	CALL	MTH_LoadOp2Long
	CALL	MTH_AddLongs
	POP	DPL
	POP	DPH
	CALL	MTH_StoreLong

	MOV	DPTR, #tkt_discount
	MOVX	A, @DPTR
	JNZ     SHF_RTdiscount

	MOV	DPTR,#shf_runtotal	; update running total
	CALL	MTH_LoadOp1Long		;
	CALL	MTH_AddLongs		;
	MOV	DPTR,#shf_runtotal	;
	CALL	MTH_StoreLong		;
	RET

SHF_RTdiscount:
	MOV	DPTR,#shf_discounttotal	; update running total
	CALL	MTH_LoadOp1Long		;
	CALL	MTH_AddLongs		;
	MOV	DPTR,#shf_discounttotal	;
	CALL	MTH_StoreLong		;
	RET

;******************************************************************************
;
; Function:	SHF_CancelTicket
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Voids a ticket from the waybill. The statistics for the ticket are
;   decremented and the void total is incremented.
;
;******************************************************************************

SHF_CancelTicket:
;	MOV	DPTR,#aud_tickettype		;
	MOVX	A,@DPTR				;
	MOV	B,#SHF_STAT_FORMAT		;
	MUL	AB				;
	MOV	DPTR,#shf_stats			;
        CALL    AddABToDPTR			;

	PUSHDPH		; DPTR = ptr to count field in stats
	PUSHDPL
	CALL	MTH_LoadOp1Word
	MOV	A,#1
	CALL	MTH_LoadOp2Acc
	CALL	MTH_SubWords
	POP	DPL
	POP	DPH
	CALL	MTH_StoreWord

        PUSHDPH		; DPTR = ptr to groupqty field in stats
        PUSHDPL
	CALL	MTH_LoadOp1Long
;        MOV	DPTR,#aud_groupqty
        CALL	MTH_LoadOp2Word
        CALL	MTH_SubLongs
        POP	DPL
	POP	DPH
	CALL	MTH_StoreLong

	PUSHDPH		; DPTR = ptr to value field in stats
	PUSHDPL
	CALL	MTH_LoadOp1Long
;	MOV	DPTR,#aud_tkttotal
	CALL	MTH_LoadOp2Long
	CALL	MTH_SubLongs
	POP	DPL
	POP	DPH
	CALL	MTH_StoreLong

;	MOV	DPTR, #aud_discount
	MOVX	A, @DPTR
	JNZ     SHF_CTdiscount

	MOV	DPTR,#shf_voidtkttotal		; update void ticket total
	CALL	MTH_LoadOp1Long			;
	CALL	MTH_AddLongs			;
	MOV	DPTR,#shf_voidtkttotal		;
	CALL	MTH_StoreLong			;
	RET

SHF_CTdiscount:
	MOV	DPTR,#shf_voiddiscount		; update void discount total
	CALL	MTH_LoadOp1Long			;
	CALL	MTH_AddLongs			;
	MOV	DPTR,#shf_voiddiscount		;
	CALL	MTH_StoreLong			;
	RET

;******************************************************************************
;
; Function:	SHF_StartShift
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SHF_StartShift:
	CALL	SHF_ClearStats
	MOV	DPSEL,#0
	MOV	DPTR,#shf_timefrom	; set from time
	CALL	TIM_GetDateTimeCustom

	MOV	DPTR,#tkt_number		; set firstticket
	CALL	MEM_SetSource
	MOV	DPTR,#shf_firstticket
	CALL	MEM_SetDest
	MOV	R7,#4
	CALL	MEM_CopyXRAMtoXRAM
	MOV	DPTR,#shf_firstticket
	CALL	MTH_IncLong

        IF USE_SLAVE
         CLR	A
         CALL	MTH_LoadOp1Acc
         MOV	DPTR,#tkt_slavenumber		;
         CALL	MTH_StoreLong			;
        ENDIF

	CLR	F0
	SETB	F1
	MOV	R1,#EE_SLAVE
	MOV	DPTR,#EE_shift
	CALL	MEM_SetSource
	MOV	DPTR,#shf_shift
	CALL	MEM_SetDest
	MOV	R7,#2
	CALL	MEM_CopyEEtoXRAMsmall

	MOV	DPTR,#shf_shift		; set shift
	CALL	MTH_IncLong

	CLR	F0
	SETB	F1
	MOV	R1,#EE_SLAVE
	MOV	DPTR,#EE_shift
	CALL	MEM_SetDest
	MOV	DPTR,#shf_shift
	CALL	MEM_SetSource
	MOV	R7,#2
	CALL	MEM_CopyXRAMtoEEsmall

	MOV	DPTR,#cloakroom
	CLR	A
	MOVX	@DPTR,A

	MOV	DPSEL,#0
;	MOV	DPTR,#aud_entry_startshift
;	CALL	AUD_AddEntry

;        MOV	DPTR,#aud_entry_plugconfig
;        CALL	AUD_AddEntry
	RET

;******************************************************************************
;
; Function:	SHF_EndShift
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SHF_EndShift:
	MOV	DPSEL,#0			; set the shift end time
	MOV	DPTR,#shf_timeto		;
	CALL	TIM_GetDateTimeCustom		;

	MOV	DPTR,#tkt_number		; set the last ticket number
	CALL	MEM_SetSource			;
	MOV	DPTR,#shf_lastticket		;
	CALL	MEM_SetDest			;
	MOV	R7,#4				;
	CALL	MEM_CopyXRAMtoXRAM		;

        MOV	DPTR,#shf_voidtkttotal		; check that the gross cash
        CALL	MTH_LoadOp1Long			; minus the ticket voids
	MOV	DPTR,#shf_voidothertotal	; minus the other voids
	CALL	MTH_LoadOp2Long			; does not go negative
	CALL	MTH_AddLongs			;
	MOV	DPTR,#shf_discounttotal		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_AddLongs			;
	MOV	DPTR,#shf_voiddiscount		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_SubLongs			;

	MOV	DPTR,#shf_runtotal		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_TestGTLong			;
	JC	SHF_ESnegative			;

	CALL	MTH_SwapOp1Op2
	CALL	MTH_SubLongs
	MOV	DPTR,#shf_netttotal
	CALL	MTH_StoreLong

	MOV	DPTR,#shf_negative
	CLR	A
	MOVX	@DPTR,A
	RET

SHF_ESnegative:
	CALL	MTH_SubLongs
	MOV	DPTR,#shf_netttotal
	CALL	MTH_StoreLong

	MOV	DPTR,#shf_negative
	MOV	A,#1
	MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	SHF_ManagerCleardown
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_waynoclear:		DB 23,'Clear SHIFT NUMBER, OK?'
msg_waynocleared:	DB 24,' SHIFT NUMBER CLEARED  '

SHF_ManagerCleardown:
	CALL	LCD_Clear
	MOV	DPTR,#msg_waynoclear
	CALL	LCD_DisplayStringCODE
	CALL	KBD_OkOrCancel
	JZ	SHF_MCno
        CALL	SHF_ClearShiftNo
	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	DPTR,#msg_waynocleared
	CALL	LCD_DisplayStringCODE

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

SHF_MCno:
	CALL	LCD_Clear
	SETB	tim_timerupdate
	RET

;******************************************************************************
;
; Function:	SHF_ClearShiftNo
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SHF_SetShiftNumber:
	MOV	DPTR,#shf_shift			;
	CALL	MTH_StoreWord			;
	CLR	F0				;
	SETB	F1				;
	MOV	R1,#EE_SLAVE			;
	MOV	DPTR,#shf_shift			;
	CALL	MEM_SetSource			;
	MOV	DPTR,#EE_shift			;
	CALL	MEM_SetDest			;
	MOV	R7,#2				;
	CALL	MEM_CopyXRAMtoEEsmall		;
        RET

SHF_ClearShiftNo:
	MOV	R0,#mth_operand1		;
	CALL	MTH_ClearOperand		;
        CALL	SHF_SetShiftNumber

 	MOV	DPSEL,#0			; add audit entry telling us
;	MOV	DPTR,#aud_entry_waynoclear	; that the shift number was
;	CALL	AUD_AddEntry			; cleared

	RET

;****************************** End Of SHIFT.ASM ******************************
        End
