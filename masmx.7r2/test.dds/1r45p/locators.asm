
;*******************************************************************************
;
;                  T i c k e t   F i e l d   L o c a t e r s
;
;*******************************************************************************

;******************************************************************************
;
; Function:     TKT_SelectTicketBase
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_SelectTicketBase:
	MOV     DPTR,#tkt_type                          ; return DPTR pointing
	MOVX    A,@DPTR                                 ; at the desc1 field
	MOV     DPTR,#ppg_oper_tkts_desc1               ; of the ticket code
	MOV     B,A                                     ; specified in
	ANL     A,#0F0h                                 ; tkt_type
	JZ      TKT_STBhotkey                           ;
	MOV     A,B                                     ;
	CLR     C                                       ;
	SUBB    A,#TKT_HOTKEY_TICKETS_MAX               ;
	MOV     DPTR,#ppg_oper_menutkts_desc1           ;
	MOV     B,A                                     ;
TKT_STBhotkey:                                          ;
	MOV     A,B                                     ;
	MOV     B,#((2*(1+PRT_MAX_HORIZ_CHARS))+16)     ;
	MUL     AB                                      ;
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TicketDesc1
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketDesc1:
	CALL    TKT_SelectTicketBase
	RET

;******************************************************************************
;
; Function:     TKT_TicketDesc2
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketDesc2:
	CALL    TKT_SelectTicketBase
	MOV     A,# LOW(ppg_oper_tkts_desc2-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_desc2-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR
	RET

;******************************************************************************
;
; Function:     TKT_TicketPrice
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketPrice:
	CALL    TKT_SelectTicketBase
	MOV     A,# LOW(ppg_oper_tkts_price-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_price-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR
	RET

;******************************************************************************
;
; Function:     TKT_TicketDiscountFlag
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketDiscountFlag:
	CALL    TKT_SelectTicketBase
	MOV     A,# LOW(ppg_oper_tkts_discountflag-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_discountflag-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR
	RET

;******************************************************************************
;
; Function:     TKT_ExpireHour
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_ExpireHour:
	CALL    TKT_SelectTicketBase
	MOV     A,# LOW(ppg_oper_tkts_expirehour-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_expirehour-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR
	RET

;******************************************************************************
;
; Function:     TKT_ExpireMinute
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_ExpireMinute:
	CALL    TKT_SelectTicketBase
	MOV     A,# LOW(ppg_oper_tkts_expiremin-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_expiremin-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR
	RET

;******************************************************************************
;
; Function:     TKT_TicketMinGroup
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketMinGroup:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_grouplimit-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_grouplimit-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TicketUnitName
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketUnitName:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_desc2+28-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_desc2+28-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TicketFixedFields
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketFixedFields:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_fixedfields-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_fixedfields-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TicketVarFields
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketVarFields:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_varfields-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_varfields-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TicketOutDevice
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TicketOutDevice:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_outdevice-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_outdevice-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_SaleLimit
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_SaleLimit:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_salelimit-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_salelimit-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_TSCtrl
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_TSCtrl:
	CALL    TKT_SelectTicketBase
	MOV     A,#LOW (ppg_oper_tkts_tsctrl-ppg_oper_tkts_desc1)
	MOV     B,#HIGH(ppg_oper_tkts_tsctrl-ppg_oper_tkts_desc1)
	CALL    AddABtoDPTR                             ;
	RET

;******************************************************************************
;
; Function:     TKT_SetTicketDate
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_SetTicketDate:
	MOV     DPTR,#datebuffer
	MOVX    A,@DPTR
	MOV     B,A
	RR      A
	RR      A
	RR      A
	ANL     A,#31
	MOV     DPTR,#tkt_day
	MOVX    @DPTR,A
	MOV     A,B
	RL      A
	ANL     A,#14
	MOV     B,A
	MOV     DPTR,#datebuffer+1
	MOVX    A,@DPTR
	RL      A
	ANL     A,#1
	ORL     A,B
	MOV     DPTR,#tkt_month
	MOVX    @DPTR,A
	MOV     DPTR,#datebuffer+1
	MOVX    A,@DPTR
	ANL     A,#127
	MOV     DPTR,#tkt_year
	MOVX    @DPTR,A
	RET

;******************************************************************************
;
; Function:     TKT_DisplayTicketDesc
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_DisplayTicketDesc:
	CALL    LCD_Clear2                              ; display ticket
	CALL    DIS_Clear                               ;
	MOV     A,#64                                   ;
	CALL    LCD_GotoXY                              ;

	CALL    TKT_TicketDesc1
	MOVX    A,@DPTR                                 ;
	INC     DPTR                                    ;
	CJNE    A,#15,TKT_DTDne                         ;
TKT_DTDge:                                              ;
	MOV     A,#15                                   ;
	JMP     TKT_DTDcontinue                         ;
TKT_DTDne:                                              ;
	JNC     TKT_DTDge                               ;
TKT_DTDcontinue:                                        ;
	MOV     R7,A                                    ;
	CALL    LCD_DisplayStringXRAM                   ; display desc1

	CALL    TKT_TicketDesc1
	MOVX    A,@DPTR
	INC     DPTR                                    ;
	CJNE    A,#16,TKT_DTDne2                        ;
TKT_DTDge2:                                             ;
	MOV     A,#16                                   ;
	JMP     TKT_DTDcontinue2                        ;
TKT_DTDne2:                                             ;
	JNC     TKT_DTDge2                              ;
TKT_DTDcontinue2:                                       ;
	MOV     R7,A                                    ;
	CALL    DIS_DisplayStringXRAM

	MOV     DPTR,#tkt_inmacro
	MOVX    A,@DPTR
	JNZ     TKT_DTnoqtyorvalue

	MOV     DPTR,#tkt_issue_qty
	MOVX    A,@DPTR
	DEC     A
	JZ      TKT_DTnoqty
	INC     A
	MOV     B,A
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     A,#'x'
	MOVX    @DPTR,A
	INC     DPTR
	MOV     R5,#2
	CALL    NUM_NewFormatDecimalB
	MOV     A,#17
	CALL    DIS_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#3
	CALL    DIS_DisplayStringXRAM
TKT_DTnoqty:

	MOV     A,#64
	CALL    DIS_GotoXY
	MOV     DPSEL,#0
	CALL    TKT_TicketPrice
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     R5,#5
	CALL    NUM_NewFormatMoney
	MOV     R7,#8
	MOV     DPTR,#buffer
	CALL    DIS_DisplayStringXRAM

TKT_DTnoqtyorvalue:
	RET

;******************************************************************************
;
; Function:     TKT_DisplayTicketValue
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_DisplayTicketValue:
	MOV     DPSEL,#0                                ;
	MOV     DPTR,#tkt_value                         ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#buffer                            ;
	MOV     R5,#5                                   ;
	CALL    NUM_NewFormatMoney                      ;
	MOV     A,#64+16                                ;
	CALL    LCD_GotoXY                              ;
	MOV     DPTR,#buffer                            ;
	MOV     R7,#8                                   ;
	CALL    LCD_DisplayStringXRAM                   ; display value
	MOV     DPTR, #tkt_discount
	MOVX    A, @DPTR
	JZ      TKT_DTVend
	MOV     DPTR, #buffer
	MOV     A, #'-'
	MOVX    @DPTR, A
	MOV     A,#64+18
	CALL    LCD_GotoXY
	MOV     R7, #1
	CALL    LCD_DisplayStringXRAM                   ; display minus sign
TKT_DTVend:
	RET

;******************************************************************************
;
; Function:     TKT_DisplayMinGroup
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

msg_mingroup: DB 9,'(Min xxx)'
TKT_DisplayMinGroup:                                    ;
	MOV     A,#79                                   ;
	CALL    LCD_GotoXY                              ;
	MOV     DPTR,#msg_mingroup                      ;
	CALL    LCD_DisplayStringCODE                   ;
	MOV     A,#84                                   ;
	CALL    LCD_GotoXY                              ;
	MOV     DPSEL,#0                                ;

	CALL    TKT_TicketMinGroup
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#buffer                            ;
	MOV     R5,#3                                   ;
	CALL    NUM_NewFormatDecimal8                   ;
	MOV     R7,#3                                   ;
	MOV     DPTR,#buffer                            ;
	CALL    LCD_DisplayStringXRAM                   ;
	RET


;******************************************************************************
;
; Function:     TKT_CurrentSalesInOp1:
; Input:        ?
; Output:       C=0 ticket non-existent, C=1 mth_operand1 set
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Issues the desired ticket according to issue_method.
;   Assumes that tkt_type and tkt_issue_qty are already set.
;
;******************************************************************************

TKT_CurrentSalesInOp1:
	CALL    TKT_TicketDesc1
	MOVX    A,@DPTR
	JZ      TKT_CSIO1gotoend

	MOV     DPTR,#tkt_type                          ; check that
	MOVX    A,@DPTR                                 ; the sale limit
	MOV     DPTR,#shf_stats                         ; for this ticket
	MOV     B,#SHF_STAT_FORMAT                      ; has not been
	MUL     AB                                      ; exceeded
	CALL    AddABtoDPTR                             ;
	CALL    MTH_LoadOp1Word                         ;
	MOV     DPTR,#tkt_issue_qty                     ;
	CALL    MTH_LoadOp2Byte                         ;
	CALL    MTH_AddWords                            ;
	SETB    C
	RET

TKT_CSIO1gotoend:
	CLR     C
	RET

;******************************************************************************
;
; Function:     TKT_IssueTicket
; Input:        A = ticket type
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Issues the desired ticket according to issue_method.
;   Assumes that tkt_type and tkt_issue_qty are already set.
;
;******************************************************************************

msg_howmany: DB 10,'How Many ?'
msg_limit: DB 20,'Ticket Limit Reached'
tkt_msg_grouplimit:     DB 20,'Group Limit Exceeded'
TKT_ITnocfg:
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_noconfig
	CALL    LCD_DisplayStringCODE

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	CALL    LCD_Clear2
	JMP     TKT_ITdone2
msg_noconfig: DB 18,'No Operator Config'

TKT_ITlimit:
	CALL    LCD_Clear2
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_limit
	CALL    LCD_DisplayStringCODE

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

TKT_ITgotoend:
	CALL    LCD_Clear2
	JMP     TKT_ITdone2


TKT_IssueTicket:
	CLR     tkt_printed

	MOV     DPTR,#tkt_type                          ; set tkt_type
	MOVX    @DPTR,A                                 ;
	MOV     DPTR,#tkt_macrotype                     ; set macrotype
	MOVX    @DPTR,A                                 ;

	MOV     A,#SYS_AREA_ISSUETICKET
	CALL    SYS_SetAreaCode

	MOV     DPTR,#tkt_issue_qty
	MOVX    A,@DPTR
	JZ      TKT_ITgotoend

	MOV     DPTR,#shf_shiftowner                    ; check that an
	MOVX    A,@DPTR                                 ; operator config
	INC     DPTR                                    ; exists
	MOV     B,A                                     ;
	MOVX    A,@DPTR                                 ;
	ORL     A,B                                     ;
	JZ      TKT_ITnocfg                             ;

	CALL    TKT_CurrentSalesInOp1
	JNC     TKT_ITgotoend

	CALL    TKT_SaleLimit

	CALL    MTH_LoadOp2Word                         ;
	MOV     A,mth_op2ll
	ORL     A,mth_op2lh
	JZ      TKT_ITnolimit
	CALL    MTH_TestGTWord
	JC      TKT_ITlimit
TKT_ITnolimit:

	CLR     A
	MOV     DPTR,#tkt_inmacro
	MOVX    @DPTR,A
TKT_IssueMacro:
	MOV     DPSEL,#5
	CALL    TKT_TicketDesc2
	MOVX    A,@DPTR
	MOV     B,A                             ; store length of macro
	INC     DPTR                            ; string for just now
	MOVX    A,@DPTR
	CJNE    A,#'@',TKT_ITnotamacro_2

	MOV     A,B                             ; calculate the number of
	RRC     A                               ; items in the macro
	MOV     B,A

	MOV     DPSEL,#0
	MOV     DPTR,#tkt_subtot_entries
	MOVX    A,@DPTR

	ADD     A,B                             ; okay to become equal
	DEC     A

	CJNE    A,#TKT_MAX_SUBTOT,TKT_ITne      ;
TKT_ITge:
	MOV     A,#64                           ; display warning that
	CALL    LCD_GotoXY                      ; subtotal table is full
	MOV     DPTR,#msg_toomanytkts           ;
	CALL    LCD_DisplayStringCODE           ;

	IF      SPEAKER
	CALL    SND_Warning                     ;
	ENDIF

	CALL    LCD_Clear2                      ;
	CALL    TKT_DisplaySubTotal             ;
	JMP     TKT_ITdone2                     ;
TKT_ITne:
	JNC     TKT_ITge

	MOV     A,#1
	MOV     DPTR,#tkt_inmacro
	MOVX    @DPTR,A

	MOV     DPSEL,#6
	MOV     DPTR,#tkt_issue_qty
	MOVX    A,@DPTR
	PUSHACC

	MOV     DPSEL,#7
	MOV     DPTR,#tkt_type
	MOVX    A,@DPTR
	PUSHACC

	MOV     R0,B

TKT_ITmacroloop:
	PUSHR0                                  ; store item count

	MOV     DPSEL,#5
	INC     DPTR
	MOVX    A,@DPTR
	JNZ     TKT_ITmacro_3
	JMP     TKT_ITmacroend

TKT_ITnotamacro_2:
	MOV     DPSEL,#0
	JMP     TKT_ITnotamacro         ;shoved in here

TKT_ITmacro_3:
	CJNE    A,#'0',TKT_ITmacro_1
	JMP     TKT_ITmacroend
TKT_ITmacro_1:
	CLR     C
	SUBB    A,#'0'
	MOV     DPSEL,#6
	MOVX    @DPTR,A

	MOV     DPSEL,#5
	INC     DPTR
	MOVX    A,@DPTR
	JZ      TKT_ITmacroend
	CJNE    A,#'0',TKT_ITmacro_2
	JMP     TKT_ITmacroend
TKT_ITmacro_2:
	CLR     C
	SUBB    A,#65
	MOV     DPSEL,#7
	MOVX    @DPTR,A

	MOV     DPSEL,#5
	PUSHDPH
	PUSHDPL
	CALL    TKT_IssueMacro
	MOV     DPSEL,#5
	POP     DPL
	POP     DPH

	POP     0
	DJNZ    R0,TKT_ITmacroloop
	PUSH    ACC                     ; push dummy to cope with next line

TKT_ITmacroend:
	POP     ACC                     ; pop the stored group count

	POP     ACC
	MOV     DPTR,#tkt_type
	MOVX    @DPTR,A

	POP     ACC
	DEC     A
	JZ      TKT_ITmacroqtydone
	MOV     DPTR,#tkt_issue_qty
	MOVX    @DPTR,A
	JMP     TKT_IssueMacro

TKT_ITmacroqtydone:
	JMP     TKT_ITdone2

TKT_ITnotamacro:
	CALL    TKT_TicketDiscountFlag
	MOVX    A, @DPTR
	MOV     DPTR,#tkt_discount              ; pick up the discount
	MOVX    @DPTR, A                        ; status of the ticket

	JZ      TKT_ITnotdiscount
	MOV     A,#1
	MOV     DPTR,#trans_discount
	MOVX    @DPTR,A
TKT_ITnotdiscount:

	CALL    TKT_TSCtrl                              ; check it its a pax
	MOVX    A,@DPTR                                 ; group - the group
	ANL     A,#16                                   ; size is fixed in
	JZ      TKT_ITnotpaxgroup                       ; the ticket config
	JMP     TKT_ITpaxgroup
TKT_ITnotpaxgroup:

	CALL    TKT_TicketMinGroup                      ; check if its
	MOVX    A,@DPTR                                 ; a group ticket
	IF      DT5                                     ;
	 CLR    A                                       ; no group tickets
	ENDIF                                           ; allowed on DT5

	JNZ     TKT_ITgroup                             ;
	JMP     TKT_ITnongroup
TKT_ITgroup:
	CALL    TKT_DisplayTicketDesc                   ; display ticket
	CALL    TKT_DisplayMinGroup                     ; and group details
	CALL    LCD_Clear1                              ;
	MOV     A,#0                                    ;
	CALL    LCD_GotoXY                              ;
	MOV     DPTR,#msg_howmany                       ;
	CALL    LCD_DisplayStringCode                   ;
	MOV     A,#19                                   ;
	CALL    LCD_GotoXY                              ;
	CALL    TKT_TicketUnitName
	MOV     R7,#5                                   ;
	CALL    LCD_DisplayStringXRAM                   ;
	MOV     B,#11                                   ;
	MOV     R7,#5
	CALL    NUM_GetNumber                           ; input group quantity
	PUSHACC                                 ;
	CALL    LCD_Clear                               ;
	SETB    tim_timerupdate                         ;
	CALL    TIM_DisplayDateTime                     ;
	POP     ACC                                     ;
	JNZ      TKT_ITgrpok                            ;
	JMP     TKT_ITdone2                             ;
TKT_ITgrpok:                                            ;
	CALL    TKT_TicketMinGroup
	CALL    MTH_LoadOp2Word
	CALL    MTH_TestGTLong
	JC      TKT_ITgrpqtyok
	CALL    MTH_CompareLongs
	JNZ     TKT_ITgrpqtyok
	JMP     TKT_ITdone2
TKT_ITgrpqtyok:
	MOV     DPTR,#tkt_groupqty                      ; calculate ticket
	CALL    MTH_StoreWord                           ; value * groupqty
	CALL    TKT_TicketPrice                         ;
	CALL    MTH_LoadOp1Long                         ;
	MOV     DPTR,#tkt_groupqty                      ;
	CALL    MTH_LoadOp2Word                         ;
	CALL    MTH_Multiply32by16                      ;
	MOV     DPTR,#tkt_value                         ;
	CALL    MTH_StoreLong                           ;

	MOV     DPTR,#tkt_discount
	MOVX    A,@DPTR
	JZ      TKT_ITvalueset
	CLR     A
	CALL    MTH_LoadOp1Acc
	MOV     DPTR,#tkt_groupqty
	CALL    MTH_StoreWord
	JMP     TKT_ITvalueset                          ;

TKT_ITpaxgroup:
	CALL    TKT_TicketMinGroup
	MOVX    A,@DPTR
	CALL    MTH_LoadOp1Acc
	JMP     TKT_ITsetnongroupqty
TKT_ITnongroup:
	MOV     A,#1
	CALL    MTH_LoadOp1Acc
TKT_ITsetnongroupqty:
	MOV     DPTR,#tkt_discount
	MOVX    A,@DPTR
	JZ      TKT_ITnotnegative
	MOV     DPTR,#tkt_groupqty
	CLR     A
	CALL    MTH_LoadOp1Acc
TKT_ITnotnegative:
	MOV     DPTR,#tkt_groupqty
	CALL    MTH_StoreWord

	CALL    TKT_TicketPrice
	CALL    MEM_SetSource                           ;
	MOV     DPTR,#tkt_value                         ;
	CALL    MEM_SetDest                             ;
	MOV     R7,#4                                   ;
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;
TKT_ITvalueset:

	MOV     DPTR,#tkt_idlestate
	MOV     A,#1
	MOVX    @DPTR,A

	MOV     DPTR,#tkt_issue_qty             ; if (issue_qty*group_qty)+
	CALL    MTH_LoadOp1Byte                 ; subtot_groupqty > grouplimit
	MOV     DPTR,#tkt_groupqty              ; or
	CALL    MTH_LoadOp2Word                 ; grouplimit = 0 then
	CALL    MTH_Multiply32by16              ; ticket is ok
	MOV     DPTR,#tkt_subtot_groupqty       ;
	CALL    MTH_LoadOp2Word                 ;
	CALL    MTH_AddWords                    ;
	MOV     DPTR,#man_trxgrouplimit         ;
	CALL    MTH_LoadOp2Word                 ;
	MOV     A,mth_op2ll                     ;
	ORL     A,mth_op2lh                     ;
	JZ      TKT_ITgrouplimitok              ;
	CALL    MTH_CompareWords                ;
	JNZ     TKT_ITgrouplimitok              ;
	CALL    MTH_TestGTWord                  ;
	JNC     TKT_ITgrouplimitok              ;

	CALL    LCD_Clear2                      ; else, transaction
	MOV     A,#64                           ; group limit exceeded
	CALL    LCD_GotoXY                      ;
	MOV     DPTR,#tkt_msg_grouplimit        ;
	CALL    LCD_DisplayStringCODE           ;

	IF      SPEAKER
	CALL    SND_Warning                     ;
	ENDIF

	CALL    LCD_Clear2                      ;
	CALL    TKT_DisplaySubtotal             ;
	JMP     TKT_ITdone2                     ;

TKT_ITgrouplimitok:
	CALL    TKT_AddtoSubTotal
	;MOV    tkt_subtotalspace,C
	JNC     TKT_ITdone2

	MOV     DPTR,#tkt_inmacro
	MOVX    A,@DPTR
	JZ      TKT_ITnotinmacro

	MOV     DPTR,#tkt_macrotype
	MOVX    A,@DPTR
	MOV     B,A
	MOV     DPTR,#tkt_type
	MOVX    A,@DPTR
	XCH     A,B
	MOVX    @DPTR,A
	CALL    TKT_DisplayTicketDesc                   ; display ticket
	MOV     A,B
	MOV     DPTR,#tkt_type
	MOVX    @DPTR,A
	JMP     TKT_ITdisplaydone

TKT_ITnotinmacro:
	CALL    TKT_DisplayTicketDesc                   ; display ticket
	CALL    TKT_DisplayTicketValue                  ; details

TKT_ITdisplaydone:
	MOV     DPTR,#man_issuemethod
	MOVX    A,@DPTR
	CJNE    A,#1,TKT_ITnot1
;*** Issue method 1
	CALL    TKT_PrintTickets
	CALL    TKT_ClearSubTotal
	IF USE_ALTONCOMMS
	 JMP    TKT_ITdone2
	ELSE
	 JMP    TKT_ITdone
	ENDIF
TKT_ITnot1:
	CJNE    A,#2,TKT_ITnot2
;*** Issue method 2
	JMP     TKT_ITdone
TKT_ITnot2:
	CJNE    A,#3,TKT_ITnot3
;*** Issue method 3
	CALL    TKT_PrintTickets
	CALL    TKT_DisplaySubtotal
	CALL    TKT_ClearSubTotalTable
	JMP     TKT_ITdone
TKT_ITnot3:
	RET
TKT_ITdone:
	MOV     A,#20
	CALL    SYS_SetTimeout
TKT_ITdone2:
	CALL    TKT_ClearQuantity

	IF USE_SERVANT
	 MOV    B,#3
	 CALL   COM_TxStatus
	ENDIF

	RET

;******************************************************************************
;
; Function:     TKT_CashTendered
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

tkt_msg_cashtender:     DB 24,'Amount Tendered:        '
tkt_msg_change:         DB 24,'Change:               OK'
tkt_msg_toolow:         DB 24,'     Amount Too Low     '
tkt_msg_total:          DB 5,'Total'
tkt_msg_displaychange:  DB 6,'Change'
tkt_amounttendered:       VAR 4
tkt_change:             VAR 4

TKT_CashTendered:
	MOV     DPTR,#man_misc
	MOVX    A,@DPTR
	ANL     A,#MAN_CASHTEND
	JNZ     TKT_CTchecknegative
	RET

TKT_CTchecknegative:
	MOV     DPTR,#tkt_subtot_negative
	MOVX    A, @DPTR
	JZ      TKT_CTgetinput

	MOV     DPTR,#tkt_subtot_value
	CALL    MTH_LoadOp1Long
	MOV     DPTR,#tkt_change
	CALL    MTH_StoreLong
	MOV     R0,#mth_operand1
	CALL    MTH_ClearOperand
	MOV     DPTR,#tkt_amounttendered
	CALL    MTH_StoreLong
	JMP     TKT_CTlowisok

TKT_CTgetinput:
	CALL    LCD_Clear1
	CLR     A
	CALL    LCD_GotoXY
	MOV     DPTR,#tkt_msg_cashtender
	CALL    LCD_DisplayStringCODE

	MOV     R7,#5
	MOV     B,#16
	MOV     DPSEL,#0
	MOV     DPTR,#tkt_amounttendered
	CALL    NUM_GetMoney
	JNZ     TKT_CTgotvalue

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	RET

TKT_CTgotvalue:
	CLR     A
	CALL    MTH_LoadOp1Acc
	MOV     DPTR,#tkt_change
	CALL    MTH_StoreLong

	MOV     DPTR,#tkt_amounttendered
	CALL    MTH_LoadOp1Long
	MOV     DPTR,#tkt_subtot_value
	CALL    MTH_LoadOp2Long
	CALL    MTH_TestGTLong
	JC      TKT_CTvaluegood
	CALL    MTH_CompareLongs
	JZ      TKT_CTtoolow

TKT_CTvaluegood:
	CALL    MTH_SubLongs
	MOV     DPTR,#tkt_change
	CALL    MTH_StoreLong
	JMP     TKT_CTlowisok

TKT_CTtoolow:
	MOV     DPTR,#man_misc
	MOVX    A,@DPTR
	ANL     A,#MAN_CASHTENDCHECK
	JNZ     TKT_CTlowisok
	CALL    LCD_Clear1
	CLR     A
	CALL    LCD_GotoXY
	MOV     DPTR,#tkt_msg_toolow
	CALL    LCD_DisplayStringCODE

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	MOV     R0,#10
	CALL    delay100ms
	JMP     TKT_CTgetinput

TKT_CTlowisok:
	MOV     DPSEL,#0
;        MOV    DPTR,#aud_entry_tendered
;        CALL   AUD_AddEntry

	CALL    LCD_Clear1
	CLR     A
	CALL    LCD_GotoXY
	MOV     DPTR,#tkt_msg_change
	CALL    LCD_DisplayStringCODE
	MOV     DPSEL,#0
	MOV     DPTR,#tkt_change
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     R5,#5
	MOV     R6,#0
	CALL    NUM_NewFormatMoney
	MOV     A,#9
	CALL    LCD_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#8
	CALL    LCD_DisplayStringXRAM

	CALL    DIS_Clear                       ; display total and
	CLR     A                               ; change on the
	CALL    DIS_GotoXY                      ; customer display
	MOV     DPTR,#tkt_msg_total
	CALL    DIS_DisplayStringCODE
	MOV     A,#64+7
	CALL    DIS_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#8
	CALL    DIS_DisplayStringXRAM
	MOV     A,#64
	CALL    DIS_GotoXY
	MOV     DPTR,#tkt_msg_displaychange
	CALL    DIS_DisplayStringCODE
	MOV     DPSEL,#0
	MOV     DPTR,#tkt_amounttendered
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     R5,#5
	MOV     R6,#0
	CALL    NUM_NewFormatMoney
	MOV     A,#7
	CALL    DIS_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#8
	CALL    DIS_DisplayStringXRAM
	RET

TKT_WaitCashDrawerClose:
	MOV     DPTR,#man_misc
	MOVX    A,@DPTR
	ANL     A,#MAN_CASHTEND
	JZ      TKT_WCDCnowait
	CALL    KBD_OkOrCancel
TKT_WCDCnowait:
	RET

;******************************************************************************
;
; Function:     TKT_CheckTimeout
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_CheckTimeout:
	CALL    SYS_CheckTimeout
	JNC     TKT_CTnotyet
	MOV     DPTR,#tkt_idlestate
	MOVX    A,@DPTR
	CJNE    A,#1,TKT_CTnotyet
;        MOV    DPTR,#man_issuemethod
;        MOVX   A,@DPTR
;        CJNE   A,#2,TKT_CTnot3
;        MOV    A,#2
;        JMP    TKT_CTsetidle
;TKT_CTnot3:
	CLR     A
;TKT_CTsetidle:
	MOV     DPTR,#tkt_idlestate
	MOVX    @DPTR,A
	CALL    TKT_DisplayIdleState
TKT_CTnotyet:
	RET

;******************************************************************************
;
; Function:     TKT_DisplayIdleState
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_DisplayIdleState:
	CALL    TIM_ForceDisplayDateTime
	MOV     DPTR,#tkt_idlestate
	MOVX    A,@DPTR
	JNZ     TKT_DISnotidle
	MOV     DPTR,#tkt_qtystrlen
	MOVX    A,@DPTR
	JZ      TKT_DIStrysubt
	CALL    TKT_DisplayQuantity
	RET

TKT_DIStrysubt:
	CALL    TKT_DisplaySubTotal
	MOV     DPTR,#man_issuemethod
	MOVX    A,@DPTR
	CJNE    A,#3,TKT_DISnotidle
	CALL    LCD_Clear2

TKT_DISnotidle:
	RET

;       MOV     DPTR,#tkt_idlestate
;       MOVX    A,@DPTR
;       CJNE    A,#2,TKT_DISnot2
;;*** idle state 2
;       RET
;TKT_DISnot2:
;;*** idle state 1 or 3
;       CALL    LCD_Clear2
;       RET

;******************************************************************************
;
; Function:     TKT_ClearQuantity
; Input:        None
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Clears the ticket quantity back to 1.
;
;******************************************************************************

tkt_qtystrlen:  VAR 1
tkt_qtystr:     VAR 2

TKT_ClearQuantity:
	MOV     DPTR,#tkt_qtystrlen             ; set quantity string
	CLR     A                               ; to "00" with a length
	MOVX    @DPTR,A                         ; of zero.
	INC     DPTR                            ;
	MOV     A,#'0'                          ;
	MOVX    @DPTR,A                         ;
	INC     DPTR                            ;
	MOVX    @DPTR,A                         ;

	MOV     DPTR,#tkt_issue_qty             ; set issue_qty to 1
	MOV     A,#1                            ;
	MOVX    @DPTR,A                         ;
	RET

;******************************************************************************
;
; Function:     TKT_SetQuantity
; Input:        A = quantity
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Sets and displays the ticket quantity for the next ticket to be issued.
;
;******************************************************************************

TKT_SetQuantity:
	MOV     B,A                             ; update qtystrlen
	MOV     DPTR,#tkt_issue_qty             ;
	MOVX    A,@DPTR                         ;
	MOV     DPTR,#tkt_qtystrlen             ;
	IF      DT10
	 JZ      TKT_SQcreate                   ;
	 MOVX   A,@DPTR                         ;
	 CJNE   A,#2,TKT_SQappend               ;
	ENDIF
TKT_SQcreate:                                   ;
	CLR     A                               ;
TKT_SQappend:                                   ;
	INC     A                               ;
	MOVX    @DPTR,A                         ;

TKT_SQfindigit:                                 ; store the
	INC     DPTR                            ; new digit
	DJNZ    ACC,TKT_SQfindigit              ; in qtystr
	MOV     A,B                             ;
	ADD     A,#'0'                          ;
	MOVX    @DPTR,A                         ;

	MOV     DPTR,#tkt_qtystrlen             ; convert to
	CALL    NUM_ConvertNumber               ; issue_qty
	MOV     DPTR,#tkt_issue_qty             ;
	CALL    MTH_StoreByte                   ;

;;      MOV     DPTR,#tkt_idlestate
;;      MOV     A,#3
;;      MOVX    @DPTR,A
;       fall thru to next routine

;******************************************************************************
;
; Function:     TKT_DisplayQuantity
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_DisplayQuantity:
	CALL    LCD_Clear2
	MOV     DPTR,#tkt_qtystrlen
	MOVX    A,@DPTR
	JNZ     TKT_DQnonzero
	RET
TKT_DQnonzero:
	MOV     DPSEL,#0
	MOV     DPTR,#tkt_issue_qty
	MOVX    A,@DPTR
	MOV     B,A
	MOV     DPSEL,#1
	MOV     DPTR,#buffer+4
	MOV     R5,#2
	CALL    NUM_NewFormatDecimalB
	MOV     DPTR,#tkt_qty
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#4
	CALL    MEM_CopyCODEtoXRAM
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#6
	CALL    LCD_DisplayStringXRAM
	RET

;******************************************************************************
;
; Function:     TKT_GenerateTicketNumber
; Input:        None
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

tkt_ticketrollover: DD 999999   ; seems a good idea in the next version
tkt_slaverollover: DD 8191      ; to declare these in the manager plug

TKT_GenerateTicketNumber:
	IF USE_SLAVE
	 CALL   TKT_TicketOutDevice             ; skip next bit if its
	 MOVX   A,@DPTR                         ; not a slave ticket
	 CJNE   A,#2,TKT_GTNmainnum             ;

	 MOV    DPTR,#tkt_slavenumber           ; increment the slave
	 CALL   MTH_LoadOp1Long                 ; ticket number
	 MOV    A,#1                            ;
	 CALL   MTH_LoadOp2Acc                  ; if it passes 8191
	 CALL   MTH_AddLongs                    ; then return a fail code
	 MOV    DPTR,#tkt_slaverollover         ;
	 MOV    R0,#mth_operand2                ;
	 CALL   MTH_LoadConstLong               ;
	 CALL   MTH_TestGTLong                  ;
	 JNC    TKT_GTNslavetktnumok            ;
	 CLR    A                               ;
	 RET                                    ;
TKT_GTNslavetktnumok:                           ;
	 MOV    DPTR,#tkt_slavenumber           ;
	 CALL   MTH_StoreLong                   ;
	ENDIF

TKT_GTNmainnum:
	MOV     DPTR,#tkt_number                ; increment the main
	CALL    MTH_LoadOp1Long                 ; ticket number
	MOV     A,#1                            ;
	CALL    MTH_LoadOp2Acc                  ; if it passes 999999
	CALL    MTH_AddLongs                    ; then wrap it back
	MOV     DPTR,#tkt_ticketrollover        ; to 000001
	MOV     R0,#mth_operand2                ;
	CALL    MTH_LoadConstLong               ;
	CALL    MTH_TestGTLong                  ;
	JNC     TKT_GTNtktnumok                 ;
	MOV     A,#1                            ;
	CALL    MTH_LoadOp1Acc                  ;
TKT_GTNtktnumok:                                ;
	MOV     DPTR,#tkt_number                ;
	CALL    MTH_StoreLong                   ;

	MOV     A,#1                            ; success
	RET

;******************************************************************************
;
; Function:     TKT_DisplaySubTotal
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

tkt_subt: DB 'Tkts:xxx  Total cc999.99'
tkt_subt2: DB 9,'Tickets: '

TKT_DisplaySubTotal:
	MOV     DPTR,#tkt_subtot_tktqty         ; check if there
	MOVX    A,@DPTR                         ; are any tickets
	INC     DPTR                            ; in the subtotal
	MOV     B,A                             ;
	MOVX    A,@DPTR                         ;
	ORL     A,B                             ;
	JNZ     TKT_DSTtkts                     ;

	MOV     A,#9                            ; Subtotal table is empty.
	CALL    LCD_GotoXY                      ; Blank off the areas of
	MOV     R7,#8                           ; the LCD which may contain
TKT_DSTspaces:                                  ; previous totals
	MOV     A,#32                           ;
	CALL    LCD_WriteData                   ;
	DJNZ    R7,TKT_DSTspaces                ;
	CALL    LCD_Clear2                      ;
	CALL    DIS_IdleMessage
	RET                                     ;

TKT_DSTtkts:
	MOV     DPTR,#tkt_subt                  ; set up the subtotal
	CALL    MEM_SetSource                   ; message
	MOV     DPTR,#buffer                    ;
	CALL    MEM_SetDest                     ;
	MOV     R7,#24                          ;
	CALL    MEM_CopyCODEtoXRAMsmall         ;

	MOV     DPSEL,#0                        ; insert the "Total" field
	MOV     DPTR,#tkt_subtot_value          ;
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#buffer+16                 ;
	MOV     R5,#5                           ;
	CALL    NUM_NewFormatMoney              ;

	MOV     DPSEL,#0                        ; insert negative sign
	MOV     DPTR,#tkt_subtot_negative       ;
	MOVX    A,@DPTR                         ;
	JZ      TKT_DSTnotnegative              ;
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#buffer+18                 ;
	MOV     A,#'-'                          ;
	MOVX    @DPTR,A                         ;

TKT_DSTnotnegative:
	MOV     DPSEL,#0                        ; insert the "Tkts" field
	MOV     DPTR,#tkt_subtot_tktqty         ;
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#buffer+5                  ;
	MOV     R5,#3                           ;
	CALL    NUM_NewFormatDecimal16          ;

	MOV     DPTR,#man_issuemethod
	MOVX    A,@DPTR
	CJNE    A,#2,TKT_DSTnot2
;*** issue method 2                             ; Full subtotaling.
	MOV     A,#64                           ; Display the entire
	CALL    LCD_GotoXY                      ; subtotal on the
	MOV     DPTR,#buffer                    ; LCD's bottom line
	MOV     R7,#24                          ;
	CALL    LCD_DisplayStringXRAM           ;
	CALL    DIS_Clear
	CLR     A
	CALL    DIS_GotoXY
	MOV     DPTR,#tkt_subt2
	CALL    DIS_DisplayStringCODE
	MOV     DPTR,#buffer+5
	MOV     R7,#3
	CALL    DIS_DisplayStringXRAM
	MOV     A,#64
	CALL    DIS_GotoXY
	MOV     DPTR,#buffer+10
	MOV     R7,#14
	CALL    DIS_DisplayStringXRAM
	RET
TKT_DSTnot2:
	CJNE    A,#3,TKT_DSTnot3
;*** issue method 3                             ; Instant subtotaling.
	MOV     A,#9                            ; Display only the money
	CALL    LCD_GotoXY                      ; field between the
	MOV     DPTR,#buffer+16                 ; date and time
	MOV     R7,#8                           ;
	CALL    LCD_DisplayStringXRAM           ;
	RET
TKT_DSTnot3:
;*** issue method 1                             ; Instant issue.
	RET                                     ; No subtotals displayed

;******************************************************************************
;
; Function:     TKT_ManagerCleardown
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

msg_tktnoclear:         DB 24,'Clear TICKET NUMBER, OK?'
msg_tktnocleared:       DB 24,' TICKET NUMBER CLEARED  '

TKT_ManagerCleardown:
	CALL    LCD_Clear
	MOV     DPTR,#msg_tktnoclear
	CALL    LCD_DisplayStringCODE
	CALL    KBD_OkOrCancel
	JZ      TKT_MCno
	CALL    TKT_ClearTicketNo
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_tktnocleared
	CALL    LCD_DisplayStringCODE

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

TKT_MCno:
	CALL    LCD_Clear
	SETB    tim_timerupdate
	RET

;******************************************************************************
;
; Function:     TKT_ClearTicketNo
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;
;******************************************************************************

TKT_SetTicketNumber:
	MOV     DPTR,#tkt_number                ;
	CALL    MTH_StoreLong                   ;
	CLR     F0                              ;
	SETB    F1                              ;
	MOV     R1,#EE_SLAVE                    ;
	MOV     DPTR,#tkt_number                ;
	CALL    MEM_SetSource                   ;
	MOV     DPTR,#EE_ticket                 ;
	CALL    MEM_SetDest                     ;
	MOV     R7,#4                           ;
	CALL    MEM_CopyXRAMtoEEsmall           ;
	RET

TKT_ClearTicketNo:
	MOV     R0,#mth_operand1                ; set tkt_number and
	CALL    MTH_ClearOperand                ; EE_ticket to zero
	CALL    TKT_SetTicketNumber

	MOV     DPSEL,#0                        ; add audit entry telling us
;       MOV     DPTR,#aud_entry_tktnoclear      ; the ticket number was reset
;       CALL    AUD_AddEntry                    ;
	RET

;******************************************************************************
;
;                      M e n u   T i c k e t i n g   C o d e
;
;******************************************************************************


tkt_submenu:    VAR 1

;******************************************************************************
;
; Function:     TKT_IssueMenuTicket
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKT_IssueMenuTicket:
	CALL    LCD_Clear                       ;
	SETB    tim_timerupdate                 ;
	CALL    TIM_DisplayDateTime             ;

	MOV     DPTR,#tkt_submenu
	MOVX    A,@DPTR
	SWAP    A
	RR      A
	MOV     B,A
	MOV     DPTR,#mnu_curr                  ; Issue a ticket
	MOVX    A,@DPTR                         ; between no.s
	ADD     A,B
	ADD     A,#TKT_HOTKEY_TICKETS_MAX-1     ; 16 and 63
	JMP     TKT_IssueTicket                 ; (menu tickets)

;******************************************************************************
;
; Function:     TKT_SetupTicketMenu
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

tkt_ticketmenumsg: DB '=====Ticket Menu X===='

TKT_SetupTicketMenu:
	MOV     A,#SYS_AREA_MENUTICKET          ; diagnostics
	CALL    SYS_SetAreaCode                 ;

	MOV     DPSEL,#1                        ; clear the menu buffer
	MOV     DPTR,#buffer+1024               ;
	MOV     A,#32                           ;
	MOV     R6,#HIGH(217)                   ; 8 24byte menu entries
	MOV     R7,#LOW(217)                    ; plus a byte count
	CALL    MEM_FillXRAM

	MOV     DPTR,#tkt_ticketmenumsg         ; set menu title
	CALL    MEM_SetSource                   ;
	MOV     DPTR,#buffer+1024+1             ;
	CALL    MEM_SetDest                     ;
	MOV     R7,#22                          ;
	CALL    MEM_CopyCODEtoXRAMsmall         ;

	MOV     A,#8                            ; set menu length
	MOV     DPTR,#buffer+1024               ;
	INC     A                               ;
	MOVX    @DPTR,A                         ;
	MOV     A,#25                           ;
	MOV     B,#0                            ;
	CALL    AddABtoDPTR                     ; dptr now at 1st char
	MOV     DPSEL,#0                        ; of 1st option

	MOV     DPTR,#tkt_submenu
	MOVX    A,@DPTR
	PUSHACC
	MOV     DPTR,#buffer+1024+18
	ADD     A,#'A'
	MOVX    @DPTR,A
	POP     ACC

	PUSHACC                         ; set number of
	SWAP    A                               ; first ticket
	RR      A                               ;
	ADD     A,#(TKT_HOTKEY_TICKETS_MAX+1)   ;
	MOV     R3,A                            ;
	POP     ACC                             ;

	MOV     DPTR,#ppg_oper_menutkts_desc1   ; find appropriate
	JZ      TKT_STMfirstmenu                ; bank of 8 tickets
	MOV     R0,A                            ;
TKT_STMbankloop:                                ;
	MOV     A,#LOW(8*82)                    ;
	MOV     B,#HIGH(8*82)                   ;
	CALL    AddABtoDPTR                     ;
	DJNZ    R0,TKT_STMbankloop              ;
TKT_STMfirstmenu:

	MOV     R4,#8
TKT_STMloop:
	MOV     DPSEL,#1
	MOV     B,R3
	MOV     R5,#2
	CALL    NUM_NewFormatDecimalB
	INC     DPTR
	INC     DPTR
	INC     DPTR
	MOV     DPSEL,#0

	PUSHDPH
	PUSHDPL
	MOVX    A,@DPTR
	CJNE    A,#19,TKT_STMnot19
	JMP     TKT_STMlenok
TKT_STMnot19:
	JC      TKT_STMlenok
	MOV     A,#19
TKT_STMlenok:
	MOV     R7,A
	INC     DPTR
	CALL    MEM_SetSource
	MOV     DPSEL,#1
	CALL    MEM_SetDest
	JZ      TKT_STMblanktkt
	PUSHDPH
	PUSHDPL
	CALL    MEM_CopyXRAMtoXRAMsmall
	POP     DPL
	POP     DPH
TKT_STMblanktkt:
	MOV     A,#19
	MOV     B,#0
	CALL    AddABtoDPTR

	MOV     A,#LOW(TKT_IssueMenuTicket)             ; set the
	MOVX    @DPTR,A                                 ; 'func' entry
	INC     DPTR                                    ; in the menu
	MOV     A,#HIGH(TKT_IssueMenuTicket)            ; option
	MOVX    @DPTR,A                                 ;
	INC     DPTR                                    ;

	MOV     DPSEL,#0
	POP     DPL
	POP     DPH
	MOV     A,#82
	MOV     B,#0
	CALL    AddABtoDPTR
	INC     R3
	DJNZ    R4,TKT_STMloop
	RET

;******************************************************************************
;
; Function:     TKT_MenuTicket
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

; Limits currently set as 32 menu tickets (17-48), can go to 48 (17-64)

TKT_MenuTicket:
	PUSHACC
	MOV     DPTR,#tkt_menu_tickets
	MOVX    A,@DPTR
	ADD     A,#TKT_HOTKEY_TICKETS_MAX
	DEC     A
	MOV     B,A
	POP     ACC
	CJNE    A,B,TKT_MTnot48                 ; make sure ticket
	JMP     TKT_MThighok                    ; number entered is
TKT_MTnot48:                                    ; not greater than 48
	JC      TKT_MThighok                    ;
	MOV     A,B                             ;

TKT_MThighok:                                   ; make sure ticket
	CJNE    A,#16,TKT_MTnot17               ; number entered is
	JMP     TKT_MTlowok                     ; not less than 17
TKT_MTnot17:                                    ;
	JNC     TKT_MTlowok                     ;
	MOV     A,#16                           ;

TKT_MTlowok:
	CLR     C                               ; menu ticket number
	SUBB    A,#16                           ; between 0 and 47

	MOV     B,A                             ; set submenu
	SWAP    A                               ;
	RL      A                               ;
	ANL     A,#7                            ;
	MOV     DPTR,#tkt_submenu               ;
	MOVX    @DPTR,A                         ;

	MOV     A,B
	ANL     A,#7
	INC     A
	MOV     DPTR,#mnu_curr
	MOVX    @DPTR,A

	CALL    PPG_TestChunkMenuTickets        ; abort if no menu
	JZ      TKT_MTnomenutkts                ; tickets exist

TKT_MTnewmenu:
	CALL    TKT_SetupTicketMenu

	MOV     DPTR,#buffer+1024
;        CALL   MNU_NewMenu
TKT_MTagain:
	MOV     DPTR,#buffer+1024
	CALL    MNU_SelectMenuOption
	CJNE    A,#MNU_LEFT,TKT_MTnotleft
;*****
; LEFT
;*****
	MOV     DPTR,#tkt_submenu
	MOVX    A,@DPTR
	JZ      TKT_MTfarleft
	DEC     A
	MOVX    @DPTR,A
TKT_MTfarleft:
	JMP     TKT_MTgotonewmenu
TKT_MTnotleft:
	CJNE    A,#MNU_RIGHT,TKT_MTnotright
;******
; RIGHT
;******
	MOV     DPTR,#tkt_menu_tickets
	MOVX    A,@DPTR
	DEC     A
	RR      A
	RR      A
	RR      A
	ANL     A,#7
	MOV     B,A
	MOV     DPTR,#tkt_submenu
	MOVX    A,@DPTR
	CJNE    A,B,TKT_MTrightok               ; 3=32tickets, 5=48tickets
	JMP     TKT_MTgotonewmenu
TKT_MTrightok:
	INC     A
	MOVX    @DPTR,A
	JMP     TKT_MTgotonewmenu
TKT_MTnotright
	JNB     ACC.7,TKT_MTagain
;        CALL   LCD_Clear
TKT_MTnomenutkts:
	RET
TKT_MTgotonewmenu:
	MOV     DPTR,#mnu_curr
	MOV     A,#1
	MOVX    @DPTR,A
	JMP     TKT_MTnewmenu

;***************************** End Of TICKET.ASM ******************************
;


