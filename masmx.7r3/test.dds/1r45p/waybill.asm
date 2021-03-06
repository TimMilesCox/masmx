;******************************************************************************
;
; File     : WAYBILL.ASM
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

;*** man_wayflags settings which affect the output of the waybill ***

WAY_PRTHEADER	EQU 1		; print the header if set
WAY_PRTSTATS	EQU 2		; print the stats if set

;******************************************************************************
;
;                             W a y b i l l   H e a d e r
;
;******************************************************************************



	IF DT10W
way_header:
	DB 255, 7,01h,10h, 3,  0,7,'CASHUP '
 	DB 255, 7,01h,10h, 3,  0,7,'CASHOUT'
template_waybill:
	DB 255,20,01h,00h, 0,100,20,'Machine Number XXXXX'
	DB 255,18,01h,00h, 1,100,18,'Shift Number XXXXX'
	DB 255,15,01h,00h, 2,100,15,'Shift Owner XXX'
	DB 255,19,01h,00h, 3,100,19,'From hh:mm dd/mm/yy'
	DB 255,19,01h,00h, 4,100,19,'To   hh:mm dd/mm/yy'
	DB 255,15,01h,00h, 5,100,15,'User Number XXX'
	DB 255,21,01h,00h, 6,100,21,'Tkts XXXXXX to XXXXXX'
	DB   9,23,01h,00h, 7,100,23,'Number Of Tickets XXXXX'
	DB 0
template_waybill_end:
	ELSE
way_header:
	IF PRT_CLBM
	DB 255,32,00h,01h, 0,  0,32,'=========== DT CASHUP ==========='
	DB 255,32,00h,01h, 0,  0,32,'=========== DT CASHOUT =========='
	ENDIF
	IF PRT_CLAA
	DB 255,21,00h,01h, 0,  0,21,'===== DT CASHUP ====='
	DB 255,21,00h,01h, 0,  0,21,'===== DT CASHOUT ===='
	ENDIF
template_waybill:
	DB 255,20,00h,00h, 0, 21,20,'Machine Number XXXXX'
	DB 255,18,00h,00h, 0, 34,18,'Shift Number XXXXX'
	DB 255,15,00h,00h, 0, 47,15,'Shift Owner XXX'
	DB 255,19,00h,00h, 0, 60,19,'From hh:mm dd/mm/yy'
	DB 255,19,00h,00h, 0, 73,19,'To   hh:mm dd/mm/yy'
	DB 255,15,00h,00h, 0, 86,15,'User Number XXX'
	DB 255,21,00h,00h, 0, 99,21,'Tkts XXXXXX to XXXXXX'
	DB   9,23,00h,00h, 0,112,23,'Number Of Tickets XXXXX'
	DB 0
template_waybill_end:
	ENDIF

template_wayhdr1_text1:		EQU 0100h
template_wayhdr1_dtserial:	EQU template_wayhdr1_text1+FIELD_HEADER+15
template_wayhdr1_wayno:		EQU template_wayhdr1_dtserial+5+FIELD_HEADER+13
template_wayhdr1_owner:		EQU template_wayhdr1_wayno+5+FIELD_HEADER+12
template_wayhdr1_fromtime:	EQU template_wayhdr1_owner+3+FIELD_HEADER+5
template_wayhdr1_totime:	EQU template_wayhdr1_fromtime+14+FIELD_HEADER+5
template_wayhdr1_opernum:	EQU template_wayhdr1_totime+14+FIELD_HEADER+12
template_wayhdr1_firsttkt:	EQU template_wayhdr1_opernum+3+FIELD_HEADER+5
template_wayhdr1_lasttkt:	EQU template_wayhdr1_firsttkt+10
template_wayhdr1_numtkts:	EQU template_wayhdr1_lasttkt+6+FIELD_HEADER+18
template_wayhdr1_termination:	EQU template_wayhdr1_numtkts+5

way_hdr1_format:
	DB 10
	DB 1  ; temp ???

	DW shf_shiftowner				; the shift owner
	DW template_wayhdr1_owner
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW shf_timefrom+2				; start time
	DW template_wayhdr1_fromtime
	DB 0,0,NUM_PARAM_TIME

	DW shf_timefrom					; start date
	DW template_wayhdr1_fromtime+6
	DB 0,0,NUM_PARAM_DATE

	DW shf_timeto+2					; to time
	DW template_wayhdr1_totime
	DB 0,0,NUM_PARAM_TIME

	DW shf_timeto					; to date
	DW template_wayhdr1_totime+6
	DB 0,0,NUM_PARAM_DATE

	DW shf_firstticket				; first ticket
	DW template_wayhdr1_firsttkt
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

	DW shf_lastticket				; last ticket
	DW template_wayhdr1_lasttkt
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

	DW ppg_hdr_usernum				; user number
	DW template_wayhdr1_opernum
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

	DW sys_dtserial					; dt serial no.
	DW template_wayhdr1_dtserial
	DB 5+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32

	DW shf_shift					; shift number
	DW template_wayhdr1_wayno
	DB 5+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

;*******************************************************************************

template_wayhdr2:
	IF DT10W
	 DB 255,21,41h,00h, 0, 44,21,'Totals:              '
	 DB 255,21,41h,00h, 1, 44,21,'Gross    CC9999999.99'
	 DB 255,21,41h,00h, 2, 44,21,'Void Tkts CC999999.99'
	 DB 255,21,41h,00h, 3, 44,21,'Void Othr CC999999.99'
	 DB 255,21,41h,00h, 4, 44,21,'Discount CC9999999.99'
	 DB 255,21,41h,00h, 5, 44,21,'Void Disc CC999999.99'
	 DB 255,21,41h,00h, 6, 44,21,'Nett     CC9999999.99'
	 DB 255,21,41h,00h, 7, 44,21,'Declared CC9999999.99'

	 IF USE_TMACHS
	  DB 255,21,41h,00h, 8, 44,21,'Head Count     XXXXXX'
	 ENDIF

	ELSE
	 DB 255,21,00h,01h, 0,  0,21,'-------Totals--------'
	 DB 255,21,00h,00h, 0, 24,21,'Gross    CC9999999.99'
	 DB 255,21,00h,00h, 0, 37,21,'Void Tkts CC999999.99'
	 DB 255,21,00h,00h, 0, 50,21,'Void Othr CC999999.99'
	 DB 255,21,00h,00h, 0, 63,21,'Discount CC9999999.99'
	 DB 255,21,00h,00h, 0, 76,21,'Void Disc CC999999.99'
	 DB 255,21,00h,00h, 0, 89,21,'Nett     CC9999999.99'
	 DB 255,21,00h,00h, 0,102,21,'Declared CC9999999.99'

	 IF USE_TMACHS
	  DB 255,21,00h,00h, 0,115,21,'Head Count     XXXXXX'
	 ENDIF

	ENDIF
	DB 0
template_wayhdr2_end:

template_wayhdr2_text1:		EQU 0100h
template_wayhdr2_gross:		EQU template_wayhdr2_text1+(2*FIELD_HEADER)+9+21
template_wayhdr2_voidtkt:	EQU template_wayhdr2_gross+12+FIELD_HEADER+10
template_wayhdr2_voidother:	EQU template_wayhdr2_voidtkt+11+FIELD_HEADER+10
template_wayhdr2_discount:	EQU template_wayhdr2_voidother+11+FIELD_HEADER+9
template_wayhdr2_voiddiscount:	EQU template_wayhdr2_discount+12+FIELD_HEADER+10
template_wayhdr2_nett:		EQU template_wayhdr2_voiddiscount+11+FIELD_HEADER+9
template_wayhdr2_declare:	EQU template_wayhdr2_nett+12+FIELD_HEADER+9

	IF USE_TMACHS
template_wayhdr2_bodycount:	EQU template_wayhdr2_declare+12+FIELD_HEADER+15
template_wayhdr2_termination:	EQU template_wayhdr2_bodycount+6
	ELSE
template_wayhdr2_termination:	EQU template_wayhdr2_declare+12
	ENDIF


way_hdr2_format:
	IF USE_TMACHS
	 DB 8,1
	ELSE
	 DB 7,1
	ENDIF

	DW shf_runtotal					; shift total
	DW template_wayhdr2_gross
	DB 9,0,NUM_PARAM_MONEY

	DW shf_voidtkttotal				; void ticket total
	DW template_wayhdr2_voidtkt
	DB 8,0,NUM_PARAM_MONEY

	DW shf_voidothertotal				; void other total
	DW template_wayhdr2_voidother
	DB 8,0,NUM_PARAM_MONEY

	DW shf_discounttotal				; discount total
	DW template_wayhdr2_discount
	DB 9,0,NUM_PARAM_MONEY

	DW shf_voiddiscount				; void discount total
	DW template_wayhdr2_voiddiscount
	DB 8,0,NUM_PARAM_MONEY

	DW shf_declaretakings				; declared takings
	DW template_wayhdr2_declare
	DB 9,0,NUM_PARAM_MONEY

	DW shf_netttotal				; nett total
	DW template_wayhdr2_nett
	DB 9,0,NUM_PARAM_MONEY

	IF USE_TMACHS
	 DW lou_bodycount				; body count
	 DW template_wayhdr2_bodycount
	 DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32
	ENDIF

;******************************************************************************
;
; Function:	WAY_PrintWaybillTitle
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

WAY_PrintWaybillTitle:
	MOV	DPTR,#man_wayflags
	MOVX	A,@DPTR
	JZ	WAY_PWTdone
	MOV	DPTR,#way_header
	CALL	PRT_LanguageStringSelect

	IF DT10W
	 CALL	PRT_FormatCODEField
	ELSE
	 CALL	PRT_DisplayMessageCODE
	ENDIF
WAY_PWTdone:
	RET

;******************************************************************************
;
; Function:	WAY_PrintWaybillHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

WAY_PrintWaybillHeader:
	MOV	DPTR,#man_wayflags		; check if we should
        MOVX	A,@DPTR				; print the waybill
        ANL	A,#WAY_PRTHEADER		; header
        JZ	WAY_PWHdone			;

	MOV	DPTR,#template_waybill
	CALL	MEM_SetSource
	MOV	DPTR,#template_wayhdr1_text1
	CALL	MEM_SetDest
	MOV	R7,#LOW(template_waybill_end-template_waybill)
	MOV	R6,#HIGH(template_waybill_end-template_waybill)
	CALL	MEM_CopyCODEtoXRAM

	MOV	DPSEL,#2			; format all the
	MOV	DPTR,#way_hdr1_format		; parameters in
	CALL	NUM_MultipleFormat		; the waybill header

        IF DT10W
         MOV	DPTR,#template_wayhdr1_text1
         CALL	PRT_FormatBitmap
        ELSE
         MOV	A,#115				; format and print
         CALL	PRT_SetBitmapLenSmall		; the bitmap
	 CALL	PRT_ClearBitmap			;
	 MOV	DPTR,#template_wayhdr1_text1	;
	 CALL	PRT_FormatBitmap		;
	 CALL	PRT_PrintBitmap			;
         CALL	PRT_FormFeed			;
        ENDIF
WAY_PWHdone:
	RET

WAY_PrintWaybillHeader2:
	MOV	DPTR,#template_wayhdr2
	CALL	MEM_SetSource
	MOV	DPTR,#template_wayhdr2_text1
	CALL	MEM_SetDest
	MOV	R7,#LOW(template_wayhdr2_end-template_wayhdr2)
	MOV	R6,#HIGH(template_wayhdr2_end-template_wayhdr2)
	CALL	MEM_CopyCODEtoXRAM

	MOV	DPSEL,#2			; format all the
	MOV	DPTR,#way_hdr2_format		; parameters in
	CALL	NUM_MultipleFormat		; the waybill header

	MOV	DPTR,#shf_negative
	MOVX	A,@DPTR
	JZ	WAY_PWHnotnegative
	MOV	DPTR,#template_wayhdr2_nett+2
	MOV	A,#'-'
	MOVX	@DPTR,A
WAY_PWHnotnegative:

        IF DT10W
         MOV	A,#0
         MOV	B,#2
         CALL	PRT_SetBitmapLen
        ELSE
         IF DT5
          MOV	A,#36
         ELSE
	  IF USE_TMACHS
	   MOV	A,#123				; format and print
	  ELSE
	   MOV	A,#110
	  ENDIF
         ENDIF
         CALL	PRT_SetBitmapLenSmall		; the bitmap
	 CALL	PRT_ClearBitmap			;
        ENDIF
	MOV	DPTR,#template_wayhdr2_text1	;
	CALL	PRT_FormatBitmap		;
	CALL	PRT_PrintBitmap			;
        CALL	PRT_FormFeed			;
	RET

WAY_FinishWristbandHeader:
	MOV	A,#0
        MOV	B,#2
        CALL	PRT_SetBitmapLen
        CALL	PRT_PrintBitmap
        CALL	PRT_FormFeed
	RET

;******************************************************************************
;
;                       W a y b i l l   S t a t i s t i c s
;
;                                      DT10W
;
;******************************************************************************

        IF DT10W

msg_way_hotkey:		DB 255, 6,1,10h,2, 0, 6,'Hotkey'
msg_way_menu:		DB 255, 4,1,10h,2, 0, 4,'Menu'
msg_way_tickets:        DB 255, 7,1,10h,4, 0, 7,'Tickets'

way_line_template:	DB 255,27,1,0,0,54,27,'xx xxxxx xxxxxxx cc99999.99'
way_line: VAR FIELD_HEADER+27

way_grformat:
	DB 4
        DB 2

        DW way_tkttype
        DW way_line+FIELD_HEADER
        DB 0,0,NUM_PARAM_TICKETTYPE

        DW way_grqty
        DW way_line+FIELD_HEADER+3
        DB 5,0,NUM_PARAM_DECIMAL16

	DW way_grunits
	DW way_line+FIELD_HEADER+9
	DB 7,0,NUM_PARAM_DECIMAL32

        DW way_grval
        DW way_line+FIELD_HEADER+17
        DB 7,0,NUM_PARAM_MONEY

way_tkttype: VAR 1
way_grqty: VAR 2
way_grunits: VAR 4
way_grval: VAR 4

;******************************************************************************
;
; Function:	WAY_PrintStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Prints R3 no. of stats starting from the address in DPTR2
;
;******************************************************************************

WAY_PrintStats:
	MOV	R4,#0
WAY_PSloop:
        CALL	MEM_SetSource
        MOV	DPTR,#way_grqty
        CALL	MEM_SetDest
        MOV	R7,#SHF_STAT_FORMAT
        CALL	MEM_CopyXRAMtoXRAMsmall
        MOV	DPH,srcDPH
        MOV	DPL,srcDPL
        PUSHDPH
        PUSHDPL
	MOV	DPTR,#way_grformat

	MOV	A,R4
        PUSHACC
        CALL	NUM_MultipleFormat
        POP	ACC
        MOV     R4,A

        MOV	DPTR,#way_line+2		; if in the first half of
        MOV	A,R4				; the current 16 tickets, clear
        ANL	A,#8				; the flags bit 7 to zero
        RL	A				; to indicate a ypos of less
        RL	A				; than 256, if in second half
        RL	A				; set flags bit 7 to indicate
        MOV	B,A				; a position over 256
        MOVX	A,@DPTR				;
        ANL	A,#03Fh				;
        ORL	A,B				;
        MOVX	@DPTR,A				;

        MOV	DPTR,#way_line+4
        MOV	A,R4
        ANL	A,#7
        MOVX	@DPTR,A

        MOV	A,R4
        PUSHACC
        MOV	A,R3
	PUSHACC
	MOV	DPTR,#way_line
	CALL	PRT_FormatXRAMField
; MOV	A,#255
; MOV	B,#1
; CALL	PRT_SetBitmapLen
; CALL	PRT_PrintBitmap
	POP	ACC
	MOV	R3,A
        POP	ACC
        MOV	R4,A
	MOV	DPSEL,#2
        POP	DPL
        POP	DPH

        MOV	DPSEL,#1
        MOV     DPTR,#way_tkttype
        MOVX    A,@DPTR
        INC     A
        MOVX    @DPTR,A

        INC	R4
	MOV	DPSEL,#2
	DJNZ	R3,WAY_PSloop2

	MOV	A,#255
	MOV	B,#1
	CALL	PRT_SetBitmapLen
	CALL	PRT_PrintBitmap
	CALL	PRT_FormFeed
	MOV	A,#255
        MOV	B,#1
        CALL	PRT_SetBitmapLen
	PUSHDPH
        PUSHDPL
	CALL	PRT_ClearBitmap
        POP	DPL
        POP	DPH
        RET
WAY_PSloop2:
	JMP	WAY_PSloop ; out of range for straight jump
;******************************************************************************
;
; Function:	WAY_PrintWaybillStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

WAY_MenuTicketLogo:
	PUSHACC
        PUSHDPH
        PUSHDPL
	MOV	DPTR,#msg_way_menu		;
        CALL	PRT_FormatCODEField		;
        MOV	DPTR,#msg_way_tickets		;
        CALL	PRT_FormatCODEField		;
        POP	DPL
        POP	DPH
        POP	ACC
	RET

WAY_PrintWaybillStats:
	MOV	DPTR,#man_wayflags		; check if we should
        MOVX	A,@DPTR				; print the waybill
        ANL	A,#WAY_PRTSTATS			; statistics
        JNZ	WAY_PWSok			;
	RET
WAY_PWSok:
;        MOV	A,#24
;        CALL	PRT_SetBitmapLenSmall
;	CALL	PRT_ClearBitmap
;	MOV	DPTR,#msg_way_stats
;	CALL	PRT_FormatCODEField
;	CALL	PRT_PrintBitmap

	MOV	DPTR,#way_line
	CALL	MEM_SetDest
	MOV	DPTR,#way_line_template
	CALL	MEM_SetSource
	MOV	R7,#FIELD_HEADER+27
	CALL	MEM_CopyCODEtoXRAMsmall

	MOV	A,#255
        MOV	B,#1
        CALL	PRT_SetBitmapLen
	CALL	PRT_ClearBitmap

;********************
; Hotkey Ticket Stats
;********************
	CALL	PPG_TestChunkHotkeyTickets	; check for existance of
        JZ      WAY_PWSnohotkeys		; hotkey tickets

        MOV	DPTR,#msg_way_hotkey		;
        CALL	PRT_FormatCODEField		;
        MOV	DPTR,#msg_way_tickets		;
        CALL	PRT_FormatCODEField		;

        MOV	DPSEL,#2

        MOV     DPTR,#way_tkttype
        CLR     A
        MOVX    @DPTR,A
	MOV     DPTR,#tkt_hotkey_tickets
        MOVX    A,@DPTR
        DEC     A				; reduce to 16 if
        ANL     A,#15				; more than 16, just
        INC     A				; in case
        MOV     R3,A
        MOV     DPTR,#shf_stats
        CALL	WAY_PrintStats
        JB	prt_paperout,WAY_PWSdone

;******************
; Menu Ticket Stats
;******************
WAY_PWSnohotkeys:
	IF DT5
         CLR	C
        ELSE
	 CALL	PPG_TestChunkMenuTickets	; check for existance of
         CLR     C				; menu tickets
         JZ	WAY_PWSnomenu			;

         MOV	DPTR,#way_tkttype
         MOV	A,#TKT_HOTKEY_TICKETS_MAX
         MOVX	@DPTR,A
         MOV	DPTR,#tkt_menu_tickets
         MOVX	A,@DPTR
         JZ	WAY_PWSnomenu
         CALL	WAY_MenuTicketLogo
         DEC	A
         MOV	R3,#16
         ANL	A,#0F0h
         JNZ	WAY_PWSmenu1
         MOVX	A,@DPTR
         MOV	R3,A
WAY_PWSmenu1:
         MOV	DPTR,#shf_stats+(TKT_HOTKEY_TICKETS_MAX*SHF_STAT_FORMAT)
         CALL	WAY_PrintStats
         JB	prt_paperout,WAY_PWSdone

         MOV	DPTR,#way_tkttype
         MOV	A,#TKT_HOTKEY_TICKETS_MAX+16
         MOVX	@DPTR,A
         MOV	DPTR,#tkt_menu_tickets
         MOVX	A,@DPTR
         CLR	C
         SUBB	A,#16
         JC	WAY_PWSnomenu
         CALL	WAY_MenuTicketLogo
         DEC	A
         MOV	R3,#16
         ANL	A,#0F0h
         JNZ	WAY_PWSmenu2
         MOVX	A,@DPTR
         CLR	C
         SUBB	A,#16
         MOV	R3,A
WAY_PWSmenu2:
         MOV	DPTR,#shf_stats+((TKT_HOTKEY_TICKETS_MAX+16)*SHF_STAT_FORMAT)
         CALL	WAY_PrintStats
         JB      prt_paperout,WAY_PWSdone

         MOV	DPTR,#way_tkttype
         MOV	A,#TKT_HOTKEY_TICKETS_MAX+32
         MOVX	@DPTR,A
         MOV	DPTR,#tkt_menu_tickets
         MOVX	A,@DPTR
         CLR	C
         SUBB	A,#32
	 JC	WAY_PWSnomenu
         CALL	WAY_MenuTicketLogo
         DEC	A
         ANL	A,#15
         INC	A
         MOV	R3,A
         MOV	DPTR,#shf_stats+((TKT_HOTKEY_TICKETS_MAX+32)*SHF_STAT_FORMAT)
         CALL	WAY_PrintStats

WAY_PWSnomenu:
	ENDIF ; if DT10W
WAY_PWSdone:
        RET

;******************************************************************************
;
;                       W a y b i l l   S t a t i s t i c s
;
;                                 DT5 / DT10
;
;******************************************************************************

        ELSE ; not DT10W

	IF PRT_CLBM
;msg_way_stats:		DB 255,32,0,1, 0, 0,32,'--------Ticket Statistics-------'
msg_way_hotkey:		DB 255,32,0,1, 0, 0,32,'---------Hotkey Tickets---------'
msg_way_menu:		DB 255,32,0,1, 0, 0,32,'----------Menu Tickets----------'
msg_way_headings:	DB 255,22,0,0, 0,24,22,'Type Qty UnitQty Value'
			DB 0
	ENDIF
	IF PRT_CLAA
;msg_way_stats:		DB 255,21,0,1, 0, 0,21,'--Ticket Statistics--'
msg_way_hotkey:		DB 255,21,0,1, 0, 0,21,'---Hotkey Tickets----'
msg_way_menu:		DB 255,21,0,1, 0, 0,21,'----Menu Tickets-----'
msg_way_headings:	DB 255,16,0,0, 0,16,16,'Type Qty UnitQty'
			DB 255, 5,0,0,16,24, 5,'Value'
			DB 0
	ENDIF

way_line_template:	DB 255,32,0,0,0, 0,32,'xx xxxxx xxxxxxx                '
			DB 255,32,0,0,0, 8,32,'                                '
way_line: VAR 2*(FIELD_HEADER+32)

way_grformat:
	DB 4
        DB 2

        DW way_tkttype
        DW way_line+FIELD_HEADER
        DB 0,0,NUM_PARAM_TICKETTYPE

        DW way_grqty
        DW way_line+FIELD_HEADER+3
        DB 5,0,NUM_PARAM_DECIMAL16

	DW way_grunits
	DW way_line+FIELD_HEADER+9
	DB 7,0,NUM_PARAM_DECIMAL32

        DW way_grval
	DW way_line+FIELD_HEADER+32+FIELD_HEADER+9
        DB 9,0,NUM_PARAM_MONEY

way_tkttype: VAR 1
way_grqty: VAR 2
way_grunits: VAR 4
way_grval: VAR 4

;******************************************************************************
;
; Function:	WAY_PrintStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Prints R3 no. of stats starting from the address in DPTR2
;
;******************************************************************************

WAY_PrintStats:
WAY_PSloop:
        CALL	MEM_SetSource
        MOV	DPTR,#way_grqty
        CALL	MEM_SetDest
        MOV	R7,#SHF_STAT_FORMAT
        CALL	MEM_CopyXRAMtoXRAMsmall
        MOV	DPH,srcDPH
        MOV	DPL,srcDPL
        PUSHDPH
        PUSHDPL
        MOV	DPTR,#way_grformat

        CALL	NUM_MultipleFormat

	MOV	A,R3
	PUSHACC
	CALL	PRT_ClearBitmap
	MOV	DPTR,#way_line
	CALL	PRT_FormatXRAMField
	CALL	PRT_FormatXRAMField
	CALL	PRT_PrintBitmap
        JC      WAY_PSpaperout
        MOV	R7,#5
        CALL	PRT_LineFeed
	POP	ACC
	MOV	R3,A
	MOV	DPSEL,#2
        POP	DPL
        POP	DPH

        MOV	DPSEL,#1
        MOV     DPTR,#way_tkttype
	MOVX    A,@DPTR
        INC     A
        MOVX    @DPTR,A

	MOV	DPSEL,#2
	DJNZ	R3,WAY_PSloop
	CLR	C
	RET
WAY_PSpaperout:
	POP	ACC
        POP	DPL
        POP	DPH
        SETB	C
        RET

;******************************************************************************
;
; Function:	WAY_PrintWaybillStats
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

WAY_PrintWaybillStats:
	MOV	DPTR,#man_wayflags		; check if we should
        MOVX	A,@DPTR				; print the waybill
        ANL	A,#WAY_PRTSTATS			; statistics
        JNZ	WAY_PWSok			;
	RET
WAY_PWSok:
;        MOV	A,#24
;        CALL	PRT_SetBitmapLenSmall
;	CALL	PRT_ClearBitmap
;	MOV	DPTR,#msg_way_stats
;	CALL	PRT_FormatCODEField
;	CALL	PRT_PrintBitmap

	MOV	A,#12
	CALL	PRT_SetBitmapLenSmall
	MOV	DPTR,#way_line
	CALL	MEM_SetDest
	MOV	DPTR,#way_line_template
	CALL	MEM_SetSource
	MOV	R7,#2*(FIELD_HEADER+32)
	CALL	MEM_CopyCODEtoXRAMsmall

;********************
; Hotkey Ticket Stats
;********************
	CALL	PPG_TestChunkHotkeyTickets	; check for existance of
	JZ      WAY_PWSnohotkeys		; hotkey tickets

	MOV	A,#32				; print the hotkey ticket
	CALL	PRT_SetBitmapLenSmall		; stat headings
	CALL	PRT_ClearBitmap			;
	MOV	DPTR,#msg_way_hotkey		;
	CALL	PRT_FormatCODEField		;
	MOV	DPTR,#msg_way_headings		;
	CALL	PRT_FormatBitmapCODE		;
	CALL	PRT_PrintBitmap			;

	MOV	DPSEL,#2

	MOV     DPTR,#way_tkttype
	CLR     A
	MOVX    @DPTR,A
	MOV     DPTR,#tkt_hotkey_tickets
        MOVX    A,@DPTR
        DEC     A				; reduce to 16 if
        ANL     A,#15				; more than 16, just
        INC     A				; in case
        MOV     R3,A
        MOV     DPTR,#shf_stats
        CALL	WAY_PrintStats
        MOV	R7,#8
        CALL	PRT_LineFeed

;******************
; Menu Ticket Stats
;******************
WAY_PWSnohotkeys:
	IF DT5
         CLR	C
        ELSE
	 CALL	PPG_TestChunkMenuTickets	; check for existance of
         CLR     C				; menu tickets
	 JZ	WAY_PWSnomenu			;

         MOV	A,#32				; print the menu ticket
         CALL	PRT_SetBitmapLenSmall		; stat headings
         CALL	PRT_ClearBitmap			;
         MOV	DPTR,#msg_way_menu		;
         CALL	PRT_FormatCODEField		;
         MOV	DPTR,#msg_way_headings		;
         CALL	PRT_FormatBitmapCODE		;
         CALL	PRT_PrintBitmap			;

         MOV     DPTR,#way_tkttype
         MOV	A,#TKT_HOTKEY_TICKETS_MAX
         MOVX	@DPTR,A
         MOV     DPTR,#tkt_menu_tickets
         MOVX    A,@DPTR
         DEC     A				; reduce to 64 if
         ANL     A,#63				; more than 64, just
         INC     A				; in case
         MOV     R3,A
         MOV	DPTR,#shf_stats+(TKT_HOTKEY_TICKETS_MAX*SHF_STAT_FORMAT)
         CALL	WAY_PrintStats
WAY_PWSnomenu:
WAY_PWSdone:
	ENDIF ; if DT5
        RET

        ENDIF ; if DT10W else

;******************************************************************************
;
; Function:	WAY_DeclareTakings
; Input:	None
; Output:	A=1=if required, takings declared and audit code 13 written
;               A=0=required takings cancelled
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

way_msg_declare: DB 16,'Declare Takings:'

WAY_DeclareTakings:
	MOV	DPTR,#man_misc
        MOVX	A,@DPTR
        ANL	A,#MAN_DECLARETAKINGS
        JZ	WAY_DTnotakings

        CALL	LCD_Clear
        MOV	DPTR,#way_msg_declare
        CALL	LCD_DisplayStringCODE

        MOV	R7,#7
        MOV	B,#64+14
        MOV	DPSEL,#0
	MOV	DPTR,#shf_declaretakings
        CALL	NUM_GetMoney
        JZ	WAY_DTcancel
        CALL	LCD_Clear
        JMP     WAY_DTaudit

WAY_DTnotakings:
	MOV	A,#0
        CALL	MTH_LoadOp1Acc
        MOV	DPTR,#shf_declaretakings
        CALL	MTH_StoreLong
WAY_DTaudit:
	MOV	DPSEL,#0
        MOV	DPTR,#aud_entry_declaretakings
        CALL	AUD_AddEntry
        MOV	A,#1
	RET
WAY_DTcancel:
	CALL	LCD_Clear
	CLR	A
        RET

;******************************************************************************
;
; Function:	WAY_PrintWaybill
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

msg_printingwaybill:	DB 19,'Printing DT Cashup '
			DB 19,'Printing DT Cashout'
msg_waybillprinted:	DB 19,'DT Cashup Printed  '
			DB 19,'DT Cashout Printed '
msg_okorcancel:		DB 18,'Press OK or CANCEL'

WAY_PWcancelled2:	JMP WAY_PWcancelled

WAY_PrintWaybill:
	MOV	A,#SYS_AREA_WAYBILL		; for diagnostics
        CALL	SYS_SetAreaCode			;

	IF USE_ALTONCOMMS
	ELSE

	MOV	A,#MAN_EXT_WAYBILL		; switch to external
	CALL	PRT_SetPrintDevice		; printer if appropriate

	CALL	SHF_EndShift			; close the shift

	CALL    WAY_DeclareTakings		; if required, input the
	JZ      WAY_PWcancelled2		; operators takings

	IF DT5					; inform users with LCDs
	ELSE					; that we are printing
	 CALL	LCD_Clear			; the waybill
	 MOV	A,#0				;
	 CALL	LCD_GotoXY			;
	 MOV	DPTR,#msg_printingwaybill	;
	 CALL	LCD_LanguageStringSelect
	 CALL	LCD_DisplayStringCODE		;
	ENDIF					;

	MOV	DPTR,#man_wayflags		; skip if there is no
	MOVX	A,@DPTR				; printing enabled
	JZ	WAY_PWprinted			;

	CALL	PRT_StartPrint			;
	IF DT10W				;
	 MOV	A,#0				;
	 MOV	B,#2				;
	 CALL	PRT_SetBitmapLen		;
	 CALL	PRT_ClearBitmap			;
	ENDIF					;
	MOV	DPTR,#man_wayflags		; check if we should
	MOVX	A,@DPTR				; print the waybill
	ANL	A,#WAY_PRTHEADER		; header
	JZ	WAY_PWnohdr			;
	CALL	WAY_PrintWaybillTitle		;
	CALL	WAY_PrintWaybillHeader		;
WAY_PWnohdr:					;

	MOV	DPTR,#man_wayflags		; check if we should
	MOVX	A,@DPTR				; print the waybill
	ANL	A,#WAY_PRTSTATS			; statistics
	JZ	WAY_PWnostats			;
	CALL	WAY_PrintWaybillHeader2		;
	CALL	WAY_PrintWaybillStats		;
	JMP	WAY_PWstatsdone			;
WAY_PWnostats:					;
	IF	DT10W				;
	 CALL	WAY_FinishWristbandHeader	;
	ENDIF					;
WAY_PWstatsdone:				;

	JB	prt_paperout,WAY_PWpaperout
	IF DT10W
	ELSE
	 CALL	PRT_FormFeed
	ENDIF
	CALL    CUT_FireCutter
	CALL	PRT_EndPrint

WAY_PWprinted:					; tell the user the waybill
	IF DT5					; has been printed
	ELSE					;
	 MOV	A,#0				; tell the user to press
	 CALL	LCD_GotoXY			; OK to accept waybill or
	 MOV	DPTR,#msg_waybillprinted	; CANCEL to reject waybill
	 CALL	LCD_LanguageStringSelect
	 CALL	LCD_DisplayStringCODE		;
	 MOV	A,#64				;
	 CALL	LCD_GotoXY			;
	 MOV	DPTR,#msg_okorcancel		;
	 CALL	LCD_DisplayStringCODE		;
	ENDIF					;

	CALL	KBD_OkOrCancel			; wait for OK or CANCEL
	JZ	WAY_PWcancelled			;

	;do the extra feed to prevent ticket wrapping if bit set
	MOV	DPTR, #man_misc2
	MOVX	A, @DPTR
	ANL	A, #4				; check bit 2
	JZ	WAY_PWnoextrafeed
	MOV	R7, #80
	CALL	PRT_LineFeed

	ENDIF ;;;; NOT USE_ALTONCOMMS

WAY_PWnoextrafeed:
	MOV	DPSEL,#0			; add the end shift
	MOV	DPTR,#aud_entry_voidtkttotal	; record(s) to the audit
	CALL	AUD_AddEntry			;

	IF USE_TMACHS
	 MOV	DPSEL,#0			; add the end shift
	 MOV	DPTR, #aud_entry_tstotal
	 CALL	AUD_AddEntry

	 MOV	DPTR, #lou_bodycount    	; set loudoun's bodycount
	 CALL	MTH_LoadOp1Acc			; to zero at the shift end
	 CALL	MTH_StoreLong
	ENDIF

	MOV	DPSEL,#0			;
	MOV	DPTR,#aud_entry_endshift	;
	CALL	AUD_AddEntry			;

	MOV	DPTR,#shf_shiftowner		; clear shf_shiftowner to
	CLR	A				; signal new shift on next
	MOVX	@DPTR,A				; operator logon
	INC	DPTR				;
	MOVX	@DPTR,A				;

	MOV     DPTR,#aud_last			; update the available
	CALL    MTH_LoadOp1Long			; uploadable memory to
	MOV     DPTR,#aud_uploadto		; include this shift
	CALL    MTH_StoreLong			;
	CALL	DIS_PowerOffMessage		;
	IF USE_UPLOAD				;
	 CALL	UPL_WaitToUpload		;
	ENDIF					;

	CALL	SYS_UnitPowerOff

WAY_PWpaperout:
	CALL	PRT_EndPrint
WAY_PWcancelled:
	MOV	DPSEL,#0
	MOV	DPTR,#aud_entry_endshiftabort
	CALL	AUD_AddEntry
	IF DT5
	ELSE
	 CALL	LCD_Clear
	 CALL	TKT_DisplaySubTotal
	 CALL	TIM_EnableTimer
	ENDIF
	CLR	A
	CALL	PRT_SetPrintDevice
	RET

;****************************** End Of WAYBILL.ASM ****************************
