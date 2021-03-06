;******************************************************************************
;
; File     : OPERATOR.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains ...
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

	IF DT10W
msg_newshift: DB 255,21,1,0,4,0,21,'Shift XXXXX started  '
msg_oldshift: DB 255,21,1,0,4,0,21,'Shift XXXXX continued'
        ELSE
msg_newshift: DB 255,21,0,0,0,0,21,'Shift XXXXX started  '
msg_oldshift: DB 255,21,0,0,0,0,21,'Shift XXXXX continued'
	ENDIF

;******************************************************************************
;
;                                 CHUNK_LAYOUT
;
;******************************************************************************

;OPR_LAYOUT_SIZE EQU (749+20+62+12)
OPR_LAYOUT_SIZE EQU (749+20+62)

MAX_DATE_LEN		EQU 17
MAX_TIME_LEN		EQU 7
MAX_DTSERIAL_LEN	EQU 5
MAX_OPERNUM_LEN		EQU 3
MAX_TICKETNO_LEN	EQU 6
MAX_GROUPUNIT_LEN	EQU 5
MAX_GROUPQTY_LEN	EQU 5
MAX_PAYMENT_LEN		EQU 15
MAX_PAYMENTREF_LEN	EQU 19
MAX_USER1_LEN		EQU 10
MAX_USER2_LEN		EQU 10
MAX_MONEY_LEN		EQU 13
MAX_VATRATE_LEN		EQU 7
MAX_EVENTDATE_LEN 	EQU 17
MAX_EVENTTIME_LEN	EQU 7
MAX_USERNAME_LEN	EQU 15

MAX_BLOCK_LEN		EQU 21
MAX_SEATROW_LEN		EQU 10
MAX_SEATCOL_LEN		EQU 10
;MAX_TKTCOUNT_LEN	EQU 5

;*** Fixed Text Fields ***
ppg_chunk_layout:	VAR 2
ppg_chunk_layout_id:	VAR 1
ppg_chunk_layout_size:	VAR 2
ppg_oper_text1:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_text2:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_text3:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_text4:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_text5:		VAR FIELD_HEADER+16
ppg_oper_text6:		VAR FIELD_HEADER+16
ppg_oper_text7:		VAR FIELD_HEADER+16
ppg_oper_text8:		VAR FIELD_HEADER+16
ppg_oper_text9:		VAR FIELD_HEADER+16
ppg_oper_text10:	VAR FIELD_HEADER+16
ppg_oper_text11:	VAR FIELD_HEADER+8
ppg_oper_text12:	VAR FIELD_HEADER+8
ppg_oper_text13:	VAR FIELD_HEADER+8
ppg_oper_text14:	VAR FIELD_HEADER+8
ppg_oper_text15:	VAR FIELD_HEADER+8
ppg_oper_text16:	VAR FIELD_HEADER+8

;*** Variable Data Fields ***
ppg_oper_desc1:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_desc2:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_oper_price:		VAR FIELD_HEADER+MAX_MONEY_LEN
ppg_oper_date:		VAR FIELD_HEADER+MAX_DATE_LEN
ppg_oper_time:		VAR FIELD_HEADER+MAX_TIME_LEN
ppg_oper_dtserial:	VAR FIELD_HEADER+MAX_DTSERIAL_LEN
ppg_oper_opernum:	VAR FIELD_HEADER+MAX_OPERNUM_LEN
ppg_oper_ticketnum:	VAR FIELD_HEADER+MAX_TICKETNO_LEN
ppg_oper_groupunit:	VAR FIELD_HEADER+MAX_GROUPUNIT_LEN
ppg_oper_groupqty:	VAR FIELD_HEADER+MAX_GROUPQTY_LEN
ppg_oper_payment:	VAR FIELD_HEADER+MAX_PAYMENT_LEN	; not used yet
ppg_oper_paymentref:	VAR FIELD_HEADER+MAX_PAYMENTREF_LEN	; not used yet
ppg_oper_user1:		VAR FIELD_HEADER+MAX_USER1_LEN		; not used yet
ppg_oper_user2:		VAR FIELD_HEADER+MAX_USER2_LEN		; not used yet
ppg_oper_vatrate:	VAR FIELD_HEADER+MAX_VATRATE_LEN	; not used yet
ppg_oper_eventdate:	VAR FIELD_HEADER+MAX_EVENTDATE_LEN	; not used yet
ppg_oper_eventtime:	VAR FIELD_HEADER+MAX_EVENTTIME_LEN	; not used yet
ppg_oper_username:	VAR FIELD_HEADER+MAX_USERNAME_LEN

ppg_oper_headerfeed:	VAR 1
ppg_oper_trailerfeed:	VAR 1
ppg_oper_ticketlen:	VAR 2
ppg_oper_barcodeypos:	VAR 2
ppg_oper_barcodexpos:	VAR 1 ; takes length to 747 inc. chunk header
ppg_oper_barcodeypos2:  VAR 2 ; takes length to 749 inc. chunk header
ppg_oper_reserved:	VAR 20

; additional layout fields as of V2.65
ppg_oper_block:		VAR FIELD_HEADER+MAX_BLOCK_LEN
ppg_oper_seatrow:	VAR FIELD_HEADER+MAX_SEATROW_LEN
ppg_oper_seatcol:	VAR FIELD_HEADER+MAX_SEATCOL_LEN

;additional field as of v2.77
;ppg_oper_tktcount:	VAR FIELD_HEADER+MAX_TKTCOUNT_LEN


;******************************************************************************
;
;                              CHUNK_SLAVELAYOUT
;
;******************************************************************************

; Slave Layout only used if DT10 is controlling a slave machine

	IF USE_SLAVE
ppg_chunk_slavelayout:		VAR 2
ppg_chunk_slavelayout_id:	VAR 1
ppg_chunk_slavelayout_size:	VAR 2
ppg_oper_slavetext1:		VAR OPR_LAYOUT_SIZE-5
        ENDIF

;******************************************************************************
;
;                            CHUNK_DUPLICATEFIELDS
;
;******************************************************************************

OPR_DUPFIELDS_SIZE	EQU (356+62)

ppg_chunk_dupfields:	VAR 2
ppg_chunk_dupfields_id:	VAR 1
ppg_chunk_dupfields_size:	VAR 2

;*** Variable Data Fields ***
ppg_dup_desc1:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_dup_desc2:		VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
ppg_dup_price:		VAR FIELD_HEADER+MAX_MONEY_LEN
ppg_dup_date:		VAR FIELD_HEADER+MAX_DATE_LEN
ppg_dup_time:		VAR FIELD_HEADER+MAX_TIME_LEN
ppg_dup_dtserial:	VAR FIELD_HEADER+MAX_DTSERIAL_LEN
ppg_dup_opernum:	VAR FIELD_HEADER+MAX_OPERNUM_LEN
ppg_dup_ticketnum:	VAR FIELD_HEADER+MAX_TICKETNO_LEN
ppg_dup_groupunit:	VAR FIELD_HEADER+MAX_GROUPUNIT_LEN
ppg_dup_groupqty:	VAR FIELD_HEADER+MAX_GROUPQTY_LEN
ppg_dup_payment:	VAR FIELD_HEADER+MAX_PAYMENT_LEN	; not used yet
ppg_dup_paymentref:	VAR FIELD_HEADER+MAX_PAYMENTREF_LEN	; not used yet
ppg_dup_user1:		VAR FIELD_HEADER+MAX_USER1_LEN		; not used yet
ppg_dup_user2:		VAR FIELD_HEADER+MAX_USER2_LEN		; not used yet
ppg_dup_vatrate:	VAR FIELD_HEADER+MAX_VATRATE_LEN	; not used yet
ppg_dup_eventdate:	VAR FIELD_HEADER+MAX_EVENTDATE_LEN	; not used yet
ppg_dup_eventtime:	VAR FIELD_HEADER+MAX_EVENTTIME_LEN	; not used yet
ppg_dup_username:	VAR FIELD_HEADER+MAX_USERNAME_LEN	; takes length to 356

; additional layout fields as of V2.65
ppg_dup_block:		VAR FIELD_HEADER+MAX_BLOCK_LEN
ppg_dup_seatrow:	VAR FIELD_HEADER+MAX_SEATROW_LEN
ppg_dup_seatcol:	VAR FIELD_HEADER+MAX_SEATCOL_LEN	; adds 62 bytes to len

;additional fields as of v2.77
;ppg_dup_tktcount:	VAR FIELD_HEADER+MAX_TKTCOUNT_LEN

;******************************************************************************
;
;                                 CHUNK_TICKETS
;
;******************************************************************************

TKT_HOTKEY_TICKETS_MAX	EQU 16
TKT_MENU_TICKETS_MAX	EQU 48

TKT_ENTRY_SIZE          EQU ((2*(1+PRT_MAX_HORIZ_CHARS))+16)

ppg_chunk_tickets:		VAR 2
ppg_chunk_tkts_id:		VAR 1
ppg_chunk_tkts_size:		VAR 2

ppg_oper_tkts_desc1:		VAR (1+PRT_MAX_HORIZ_CHARS)
ppg_oper_tkts_desc2:		VAR (1+PRT_MAX_HORIZ_CHARS)
ppg_oper_tkts_price:		VAR 4
ppg_oper_tkts_vatcode:		VAR 1
ppg_oper_tkts_grouplimit:	VAR 1
ppg_oper_tkts_salelimit:	VAR 2
ppg_oper_tkts_fixedfields:	VAR 1
ppg_oper_tkts_varfields:	VAR 1
ppg_oper_tkts_outdevice:	VAR 1
ppg_oper_tkts_reserved1:	VAR 1
ppg_oper_tkts_discountflag:	VAR 1  ;added v2.71
ppg_oper_tkts_expirehour:	VAR 1  ;added v2.71
ppg_oper_tkts_expiremin:	VAR 1  ;added v2.71
ppg_oper_tkts_tsctrl:		VAR 1
ppg_oper_tkts_therest:		VAR TKT_ENTRY_SIZE*(TKT_HOTKEY_TICKETS_MAX-1)

;*******************************

ppg_chunk_menu_tickets:		VAR 2
ppg_chunk_menu_tkts_id:		VAR 1
ppg_chunk_menu_tkts_size:	VAR 2

ppg_oper_menutkts_desc1:	VAR (1+PRT_MAX_HORIZ_CHARS)
ppg_oper_menutkts_desc2:	VAR (1+PRT_MAX_HORIZ_CHARS)
ppg_oper_menutkts_price:	VAR 4
ppg_oper_menutkts_vatcode:	VAR 1
ppg_oper_menutkts_grouplimit:	VAR 1
ppg_oper_menutkts_salelimit:	VAR 2
ppg_oper_menutkts_fixedfields:	VAR 1
ppg_oper_menutkts_varfields:	VAR 1
ppg_oper_menutkts_outdevice:	VAR 1
ppg_oper_menutkts_reserved1:	VAR 1
ppg_oper_menu_reserved2:	VAR 2
ppg_oper_menu_reserved3:	VAR 1
ppg_oper_menu_tsctrl:		VAR 1
ppg_oper_menu_therest:		VAR TKT_ENTRY_SIZE*(TKT_MENU_TICKETS_MAX-1)

;******************************************************************************
;
; Function:	PPG_ClearChunkHotkeyTickets
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkHotkeyTickets:
	MOV	DPTR,#ppg_chunk_tkts_id
        CLR	A
        MOVX	@DPTR,A
        MOV	DPTR,#tkt_hotkey_tickets
        MOVX	@DPTR,A
        MOV     DPTR,#ppg_oper_tkts_desc1
        CLR     A
        MOV     R7,#LOW(TKT_HOTKEY_TICKETS_MAX*TKT_ENTRY_SIZE)
        MOV     R6,#HIGH(TKT_HOTKEY_TICKETS_MAX*TKT_ENTRY_SIZE)
        CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	PPG_TestChunkHotkeyTickets
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_TestChunkHotkeyTickets:
	MOV	DPTR,#ppg_chunk_tkts_id
        MOVX	A,@DPTR
	RET

;******************************************************************************
;
; Function:	PPG_ClearChunkMenuTickets
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkMenuTickets:
	MOV	DPTR,#ppg_chunk_menu_tkts_id
        CLR	A
        MOVX	@DPTR,A
        MOV	DPTR,#tkt_menu_tickets
        MOVX	@DPTR,A
        MOV     DPTR,#ppg_oper_menutkts_desc1
        CLR     A
        MOV     R7,#LOW(TKT_MENU_TICKETS_MAX*TKT_ENTRY_SIZE)
        MOV     R6,#HIGH(TKT_MENU_TICKETS_MAX*TKT_ENTRY_SIZE)
        CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	PPG_TestChunkMenuTickets
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_TestChunkMenuTickets:
	MOV	DPTR,#ppg_chunk_menu_tkts_id
        MOVX	A,@DPTR
	RET

;******************************************************************************
;
; Function:	PPG_ClearChunkLayout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkLayout:
	MOV	DPTR,#ppg_chunk_layout_id
        CLR	A
        MOVX	@DPTR,A
        MOV     DPTR,#ppg_chunk_layout
        CLR     A
        MOV     R7,#LOW(OPR_LAYOUT_SIZE)
        MOV     R6,#HIGH(OPR_LAYOUT_SIZE)
        CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	PPG_TestChunkLayout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_TestChunkLayout:
	MOV	DPTR,#ppg_chunk_layout_id
        MOVX	A,@DPTR
	RET

	IF USE_SLAVE
;******************************************************************************
;
; Function:	PPG_ClearChunkSlaveLayout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkSlaveLayout:
	MOV	DPTR,#ppg_chunk_slavelayout_id
        CLR	A
        MOVX	@DPTR,A
        MOV     DPTR,#ppg_chunk_slavelayout
        CLR     A
        MOV     R7,#LOW(OPR_LAYOUT_SIZE)
        MOV     R6,#HIGH(OPR_LAYOUT_SIZE)
        CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	PPG_TestChunkSlaveLayout
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_TestChunkSlaveLayout:
	MOV	DPTR,#ppg_chunk_slavelayout_id
        MOVX	A,@DPTR
	RET

        ENDIF

;******************************************************************************
;
; Function:	PPG_ClearChunkDupFields
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkDuplicateFields:
	MOV	DPTR,#ppg_chunk_dupfields_id
        CLR	A
        MOVX	@DPTR,A
        MOV     DPTR,#ppg_chunk_dupfields
        CLR     A
        MOV     R7,#LOW(OPR_DUPFIELDS_SIZE)
        MOV     R6,#HIGH(OPR_DUPFIELDS_SIZE)
        CALL    MEM_FillXRAM
	RET

;******************************************************************************
;
; Function:	PPG_TestChunkDuplicateFields
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_TestChunkDuplicateFields:
	MOV	DPTR,#ppg_chunk_dupfields_id
        MOVX	A,@DPTR
	RET

;******************************************************************************
;
; Function:	OPR_LoadOperatorConfig
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

OPR_LoadOperatorConfig:
	MOV	DPTR,#ppg_oper_text1		; copy ticket layout
	CALL	MEM_SetSource			; (lose the 5 chunkheader
	MOV	DPTR,#tkt_tmpl_text1		;  bytes)
	CALL	MEM_SetDest			;
	MOV	R7,#LOW(749-9-5)		; (lose the 9 bytes which
	MOV	R6,#HIGH(749-9-5)		;  are not part of the
	CALL	MEM_CopyXRAMtoXRAM		;  field list)

        MOV	DPTR,#ppg_oper_block		; copy v2.65 extended layout
        CALL	MEM_SetSource			; (lose the 749 bytes of
        MOV	DPTR,#tkt_tmpl_block		;  pre v2.65 data plus the
	CALL	MEM_SetDest			;  20 bytes of post v2.65)
        MOV	R7,#LOW(OPR_LAYOUT_SIZE-749-20)	;  so that we are just looking
        MOV	R6,#HIGH(OPR_LAYOUT_SIZE-749-20);  at the new layout fields)
        CALL	MEM_CopyXRAMtoXRAM		;

        MOV	DPTR,#ppg_dup_desc1		; copy duplicate fields
        CALL	MEM_SetSource			; (lose the 5 bytes of header)
        MOV	DPTR,#tkt_tmpl_dupdesc1		;
        CALL	MEM_SetDest			;
        MOV	R7,#LOW(OPR_DUPFIELDS_SIZE-5)	;
        MOV	R6,#HIGH(OPR_DUPFIELDS_SIZE-5)	;
        CALL	MEM_CopyXRAMtoXRAM		;

	MOV	DPTR,#shf_shiftowner		; check if continuing
	MOVX	A,@DPTR				; or starting a new
	INC	DPTR				; shift
	MOV	B,A				;
	MOVX	A,@DPTR				;
	ORL	A,B				;
	JNZ	OPR_LOColdshift			;

;**********
; new shift
;**********

	CALL	SHF_StartShift			; copy over new
	MOV	DPTR,#ppg_hdr_usernum		; shift owner
        CALL	MEM_SetSource			; number
        MOV	DPTR,#shf_shiftowner		;
        CALL	MEM_SetDest			;
        MOV	R7,#2				;
        CALL	MEM_CopyXRAMtoXRAMsmall		;

	MOV	DPTR,#msg_newshift		; new shift message
        JMP	OPR_LOCdisplay

;****************
; continued shift
;****************
OPR_LOColdshift:
	MOV	DPTR,#msg_oldshift		; old shift message

OPR_LOCdisplay:
	CALL	MEM_SetSource			; display new/old
	MOV	DPTR,#buffer			; shift message
	CALL	MEM_SetDest			;
	MOV	R7,#FIELD_HEADER+21		;
	CALL	MEM_CopyCODEtoXRAMsmall		;
	MOV	DPSEL,#0			;
	MOV	DPTR,#shf_shift			;
	MOV	DPSEL,#1			;
	MOV	DPTR,#buffer+FIELD_HEADER+6	;
	MOV	R5,#5+NUM_ZEROPAD		;
	CALL	NUM_NewFormatDecimal16		;
;        CALL	DT_CheckPowerUpMessages
        JNZ	OPR_LOCnomsg
        IF DT10W				;
         MOV	DPTR,#buffer			;
         CALL	PRT_FormatXRAMField		;
        ELSE					;
	 CALL	PRT_DisplayOneLiner		;
        ENDIF					;
OPR_LOCnomsg:
	RET

;*************************** End Of OPERATOR.ASM *****************************
;