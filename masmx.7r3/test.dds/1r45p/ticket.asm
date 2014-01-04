;******************************************************************************
;
; File     : TICKET.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the ticket issueing routines
;
; System   : 80C51
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;; size of these two values multiplied together MUST be less than 256
TKT_MAX_SUBTOT          EQU 10  ; Maximum entries in subtotaling (1 - 63)
TKT_SUBTOT_SIZE         EQU 10  ; Size of each entry in subtotal table


TKT_NUM_FIXED_FIELDS    EQU 16
TKT_NUM_VAR_FIELDS      EQU 18
;TKT_NUM_VAR_FIELDS2    EQU 4
;NUM_DUP_FIELDS         EQU 22
TKT_NUM_VAR_FIELDS2     EQU 3
NUM_DUP_FIELDS          EQU 21

cloakroom:      VAR 1

tkt_subtot_value:       VAR 4   ; subtotal money value
tkt_subtot_tktqty:      VAR 2   ; subtotal ticket count
tkt_subtot_groupqty:    VAR 2   ; subtotal group quantity
tkt_subtot_negative:    VAR 1   ; flag

tkt_subtot_entries:     VAR 1   ; number of subtotal entries in use
tkt_subtot_printed:     VAR 1   ; number of tickets printed so far in this transaction
tkt_subtot_valueprinted: VAR 4  ; subtotal value printed so far in this transaction
tkt_subtot_negativeprinted: VAR 1       ; flag

tkt_subtot_current:     VAR 1   ; pointer to current entry (printing only)
tkt_subtot_table:       VAR (TKT_MAX_SUBTOT*TKT_SUBTOT_SIZE); (1+1+2+4+1+1))    ; the subtotal table

tkt_idlestate:          VAR 1
tkt_printstatus:        VAR 1

tkt_type:               VAR 1   ; current ticket type           ;-------------+
tkt_issue_qty:          VAR 1   ; current ticket qty            ;group these 6|
tkt_groupqty:           VAR 2   ; current ticket group qty      ;             |
tkt_value:              VAR 4   ; current ticket value          ;             |
tkt_discount:           VAR 1   ; current ticket / discount flag;             |
tkt_inmacro:            VAR 1   ; flag for whether in macro     ;             |
								;-------------+
trans_discount:         VAR 1   ; set if anything in trans disc.

tkt_macrotype:          VAR 1   ; current ticket type

tkt_paymenttype:        VAR 1   ; current payment type

tkt_number:             VAR 4   ; current ticket serial number
tkt_slavenumber:        VAR 4   ; current slave ticket serial number
tkt_vat:                VAR 1   ; current ticket vat code
tkt_day:                VAR 1
tkt_month:              VAR 1
tkt_year:               VAR 1
tkt_zone:               VAR 1
	IF USE_PAIGNTON
tkt_normalturnstile:    VAR 1
tkt_disabledturnstile:  VAR 1
	ENDIF
tkt_hotkey_tickets:     VAR 1   ; count of how many hotkey tickets are in use
tkt_menu_tickets:       VAR 1   ; count of how many menu tickets are in use

tkt_expirehours2        VAR 1
tkt_expireminutes2      VAR 1

tkt_qty: DB 'Qty:'

tkt_shitfiller:   VAR 50

tkt_tmpl_text1:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_text2:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_text3:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_text4:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_text5:         VAR FIELD_HEADER+16
tkt_tmpl_text6:         VAR FIELD_HEADER+16
tkt_tmpl_text7:         VAR FIELD_HEADER+16
tkt_tmpl_text8:         VAR FIELD_HEADER+16
tkt_tmpl_text9:         VAR FIELD_HEADER+16
tkt_tmpl_text10:        VAR FIELD_HEADER+16
tkt_tmpl_text11:        VAR FIELD_HEADER+8
tkt_tmpl_text12:        VAR FIELD_HEADER+8
tkt_tmpl_text13:        VAR FIELD_HEADER+8
tkt_tmpl_text14:        VAR FIELD_HEADER+8
tkt_tmpl_text15:        VAR FIELD_HEADER+8
tkt_tmpl_text16:        VAR FIELD_HEADER+8
tkt_tmpl_desc1:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_desc2:         VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_price:         VAR FIELD_HEADER+MAX_MONEY_LEN
tkt_tmpl_date:          VAR FIELD_HEADER+MAX_DATE_LEN
tkt_tmpl_time:          VAR FIELD_HEADER+MAX_TIME_LEN
tkt_tmpl_dtserial:      VAR FIELD_HEADER+MAX_DTSERIAL_LEN
tkt_tmpl_opernum:       VAR FIELD_HEADER+MAX_OPERNUM_LEN
tkt_tmpl_ticketnum:     VAR FIELD_HEADER+MAX_TICKETNO_LEN
tkt_tmpl_groupunit:     VAR FIELD_HEADER+MAX_GROUPUNIT_LEN
tkt_tmpl_groupqty:      VAR FIELD_HEADER+MAX_GROUPQTY_LEN
tkt_tmpl_payment:       VAR FIELD_HEADER+MAX_PAYMENT_LEN
tkt_tmpl_paymentref:    VAR FIELD_HEADER+MAX_PAYMENTREF_LEN
tkt_tmpl_user1:         VAR FIELD_HEADER+MAX_USER1_LEN
tkt_tmpl_user2:         VAR FIELD_HEADER+MAX_USER2_LEN
tkt_tmpl_vatrate:       VAR FIELD_HEADER+MAX_VATRATE_LEN
tkt_tmpl_eventdate:     VAR FIELD_HEADER+MAX_EVENTDATE_LEN
tkt_tmpl_eventtime:     VAR FIELD_HEADER+MAX_EVENTTIME_LEN
tkt_tmpl_username:      VAR FIELD_HEADER+MAX_USERNAME_LEN
tkt_tmpl_block:         VAR FIELD_HEADER+MAX_BLOCK_LEN
tkt_tmpl_seatrow:       VAR FIELD_HEADER+MAX_SEATROW_LEN
tkt_tmpl_seatcol:       VAR FIELD_HEADER+MAX_SEATCOL_LEN
;tkt_tmpl_tktcount:     VAR FIELD_HEADER+MAX_TKTCOUNT_LEN
tkt_tmpl_termination:   VAR 1

tkt_tmpl_dupdesc1:      VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_dupdesc2:      VAR FIELD_HEADER+PRT_MAX_HORIZ_CHARS
tkt_tmpl_dupprice:      VAR FIELD_HEADER+MAX_MONEY_LEN
tkt_tmpl_dupdate:       VAR FIELD_HEADER+MAX_DATE_LEN
tkt_tmpl_duptime:       VAR FIELD_HEADER+MAX_TIME_LEN
tkt_tmpl_dupdtserial:   VAR FIELD_HEADER+MAX_DTSERIAL_LEN
tkt_tmpl_dupopernum:    VAR FIELD_HEADER+MAX_OPERNUM_LEN
tkt_tmpl_dupticketnum:  VAR FIELD_HEADER+MAX_TICKETNO_LEN
tkt_tmpl_dupgroupunit:  VAR FIELD_HEADER+MAX_GROUPUNIT_LEN
tkt_tmpl_dupgroupqty:   VAR FIELD_HEADER+MAX_GROUPQTY_LEN
tkt_tmpl_duppayment:    VAR FIELD_HEADER+MAX_PAYMENT_LEN
tkt_tmpl_duppaymentref: VAR FIELD_HEADER+MAX_PAYMENTREF_LEN
tkt_tmpl_dupuser1:      VAR FIELD_HEADER+MAX_USER1_LEN
tkt_tmpl_dupuser2:      VAR FIELD_HEADER+MAX_USER2_LEN
tkt_tmpl_dupvatrate:    VAR FIELD_HEADER+MAX_VATRATE_LEN
tkt_tmpl_dupeventdate:  VAR FIELD_HEADER+MAX_EVENTDATE_LEN
tkt_tmpl_dupeventtime:  VAR FIELD_HEADER+MAX_EVENTTIME_LEN
tkt_tmpl_dupusername:   VAR FIELD_HEADER+MAX_USERNAME_LEN
tkt_tmpl_dupblock:      VAR FIELD_HEADER+MAX_BLOCK_LEN
tkt_tmpl_dupseatrow:    VAR FIELD_HEADER+MAX_SEATROW_LEN
tkt_tmpl_dupseatcol:    VAR FIELD_HEADER+MAX_SEATCOL_LEN
;tkt_tmpl_duptktcount:  VAR FIELD_HEADER+MAX_TKTCOUNT_LEN
tkt_tmpl_termination2:  VAR 1

;******************************************************************************
;
; Function:     TKT_Init
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_Init:
	CALL    TKT_ClearSubTotal
	CLR     A
	MOV     DPTR,#tkt_tmpl_termination
	MOVX    @DPTR,A
	MOV     DPTR,#tkt_tmpl_termination2
	MOVX    @DPTR,A
	CALL    TKT_ClearQuantity
	CLR     A
	MOV     DPTR,#tkt_vat
	MOVX    @DPTR,A
	RET

;******************************************************************************
;
; Function:     TKT_CalcTicketCounts
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_CalcTicketCount:
	MOV     R6,#0
	MOV     R5,#0
TKT_CTCloop:
	INC     R5
	MOVX    A,@DPTR
	JZ      TKT_CTCblank
	MOV     A,R5
	MOV     R6,A
TKT_CTCblank:

	MOV     A,#82
	MOV     B,#0
	CALL    AddABtoDPTR

	DJNZ    R7,TKT_CTCloop
	MOV     A,R6
	RET

TKT_CalcTicketCounts:
	MOV     DPTR,#ppg_oper_tkts_desc1
	MOV     R7,#TKT_HOTKEY_TICKETS_MAX
	CALL    TKT_CalcTicketCount
	MOV     DPTR,#tkt_hotkey_tickets
	MOVX    @DPTR,A

	MOV     DPTR,#ppg_chunk_menu_tickets+2
	MOVX    A,@DPTR                         ; menu_ticket chunk code
	CLR     C
	SUBB    A,#PPG_CHNK_MENU16TICKETS-1
	SWAP    A                               ; A=16,32 or 48

	MOV     DPTR,#ppg_oper_menutkts_desc1
	MOV     R7,A
	CALL    TKT_CalcTicketCount
	MOV     DPTR,#tkt_menu_tickets
	MOVX    @DPTR,A

	RET

;******************************************************************************
;
; Function:     TKT_ClearSubTotalTable
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_ClearSubTotalTable:
	CLR     A                               ; set subtotal table
	MOV     DPTR,#tkt_subtot_entries        ; entries to zero
	MOVX    @DPTR,A                         ;
	MOV     DPTR,#tkt_subtot_printed        ;
	MOVX    @DPTR,A                         ;
	MOV     DPTR,#tkt_subtot_negativeprinted        ;
	MOVX    @DPTR,A
	MOV     DPTR,#trans_discount
	MOVX    @DPTR,A                 ;
	CALL    MTH_LoadOp1Acc                  ;
	MOV     DPTR,#tkt_subtot_valueprinted   ;
	CALL    MTH_StoreLong                   ;

;       MOV     A,#TKT_MAX_SUBTOT               ;
;       MOV     B,#TKT_SUBTOT_SIZE              ; clear out the
;       MUL     AB                              ; sub total table
;       MOV     R0,A                            ;
;       CLR     A                               ;
;TKT_CSTTloop:                                   ;
;       MOV     DPTR,#tkt_subtot_table          ;
;       MOV     @DPTR,A                         ;
;       DJNZ    R0,TKT_CSTTloop                 ;

	RET                                     ;

;******************************************************************************
;
; Function:     TKT_ClearSubTotal
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_ClearSubTotal:
	MOV     R0,#mth_operand1                ; clear subtotal value
	CALL    MTH_ClearOperand                ;
	MOV     DPTR,#tkt_subtot_value          ;
	CALL    MTH_StoreLong                   ;
	MOV     DPTR,#tkt_subtot_tktqty         ; and ticket qty
	CALL    MTH_StoreLong                   ;
	MOV     DPTR,#tkt_subtot_groupqty       ; and group quantity
	CALL    MTH_StoreLong                   ;
	MOV     DPTR,#tkt_subtot_negative       ; and negative flag
	CALL    MTH_StoreLong                   ;
	CALL    TKT_ClearSubTotalTable          ; and table size
	CALL    CRD_ClearCardNumber
	RET

;******************************************************************************
;
; Function:     TKT_AddtoSubTotal
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Add the current ticket description to the subtotal table.
;   The fields which must already be set are:
;   tkt_type, tkt_issue_qty, tkt_group_qty, tkt_value, tkt_discount
;       tkt_inmacro
;
;******************************************************************************

msg_toomanytkts:        DB 24,'Maximum Subtotal Reached'

TKT_AddToSubTotal:
	MOV     DPTR,#tkt_subtot_entries        ; check that subtotal
	MOVX    A,@DPTR                         ; table is not full
	CJNE    A,#TKT_MAX_SUBTOT,TKT_ATSTne    ;
TKT_ATSTge:
	MOV     A,#64                           ; display warning that
	CALL    LCD_GotoXY                      ; subtotal table is full
	MOV     DPTR,#msg_toomanytkts           ;
	CALL    LCD_DisplayStringCODE           ;

	IF      SPEAKER
	CALL    SND_Warning                     ;
	ENDIF

	CALL    LCD_Clear2                      ;
	CALL    TKT_DisplaySubTotal             ;
	CLR     C                               ;
	RET                                     ;
TKT_ATSTne:
	JNC     TKT_ATSTge

	MOV     DPTR,#tkt_subtot_table          ; ok to add to table
	MOV     B,#TKT_SUBTOT_SIZE              ;
	MUL     AB                              ;
	CALL    AddABtoDPTR                     ; DPTR now at correct entry
	CALL    MEM_SetDest                     ;
	MOV     DPTR,#tkt_type                  ; copy type,qty,groupqty,flag
	CALL    MEM_SetSource                   ; into table
	MOV     R7,#TKT_SUBTOT_SIZE             ;
	CALL    MEM_CopyXRAMtoXRAMsmall         ;

	MOV     DPTR,#tkt_subtot_entries        ; increment number of
	MOVX    A,@DPTR                         ; entries currently in table
	INC     A                               ;
	MOVX    @DPTR,A                         ;

	MOV     DPTR,#tkt_value                 ; update subtotal value
	CALL    MTH_LoadOp1Long                 ;
	MOV     DPTR,#tkt_issue_qty             ;
	CALL    MTH_LoadOp2Byte                 ;
	CALL    MTH_Multiply32by16              ;
	MOV     DPTR,#tkt_subtot_value          ;
	CALL    MTH_LoadOp2Long                 ;

	MOV     DPTR,#tkt_discount
	MOVX    A,@DPTR
	JNZ     TKT_ATSThandlediscount

	MOV     DPTR,#tkt_subtot_negative
	MOVX    A,@DPTR
	JNZ     TKT_ATSThandlenegative

TKT_ATSThandlediscountnegative:
	CALL    MTH_AddLongs                    ;
	JMP     TKT_ATSTstorevalue              ;

TKT_ATSThandlenegative:
	CALL    MTH_SwapOp1Op2
	CALL    MTH_TestGTLong
	JNC     TKT_ATSTsubgoingpositive
	CALL    MTH_SubLongs
	JMP     TKT_ATSTstorevalue

TKT_ATSTsubgoingpositive:
	CLR     A
	MOV     DPTR,#tkt_subtot_negative
	MOVX    @DPTR,A

	CALL    MTH_SwapOp1Op2
	CALL    MTH_SubLongs
	JMP     TKT_ATSTstorevalue              ;

TKT_ATSThandlediscount:
	MOV     DPTR,#tkt_subtot_negative
	MOVX    A,@DPTR
	JNZ     TKT_ATSThandlediscountnegative

	CALL    MTH_TestGTLong
	JC      TKT_ATSTsubgoingnegative
	CALL    MTH_SwapOp1Op2
	CALL    MTH_SubLongs
	JMP     TKT_ATSTstorevalue              ;

TKT_ATSTsubgoingnegative:
	MOV     A,#1
	MOV     DPTR,#tkt_subtot_negative
	MOVX    @DPTR,A

	CALL    MTH_SubLongs
	JMP     TKT_ATSTstorevalue              ;

TKT_ATSTstorevalue:                             ;
	MOV     DPTR,#tkt_subtot_value          ;
	CALL    MTH_StoreLong                   ;

	MOV     DPTR,#tkt_subtot_tktqty         ; update subtotal tkt qty
	CALL    MTH_LoadOp1Word                 ;
	MOV     DPTR,#tkt_issue_qty             ;
	CALL    MTH_LoadOp2Byte                 ;
	CALL    MTH_AddWords                    ;
	MOV     DPTR,#tkt_subtot_tktqty         ;
	CALL    MTH_StoreWord                   ;

	MOV     DPTR,#tkt_subtot_groupqty       ; update subtotal group qty
	CALL    MTH_LoadOp1Word                 ;
	MOV     DPTR,#tkt_groupqty              ;
	CALL    MTH_LoadOp2Word                 ;
	CALL    MTH_AddWords                    ;
	MOV     DPTR,#tkt_subtot_groupqty       ;
	CALL    MTH_StoreWord                   ;

	SETB    C
	RET

TKT_LoadUpTicket:
	MOV     DPTR,#tkt_subtot_table          ; load up next entry
	MOV     B,#TKT_SUBTOT_SIZE              ;
	MUL     AB                              ;
	CALL    AddABtoDPTR                     ;
	CALL    MEM_SetSource                   ;
	MOV     DPTR,#tkt_type                  ;
	CALL    MEM_SetDest                     ;
	MOV     R7,#TKT_SUBTOT_SIZE             ;
	CALL    MEM_CopyXRAMtoXRAMsmall         ;
	RET

;

