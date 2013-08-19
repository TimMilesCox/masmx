;******************************************************************************
;
; File     : TKTPRINT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for handling the printing of
;            tickets (from the details in the subtotal table and various
;            other settings)
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;
;******************************************************************************

TRIAL_TKT_OK          EQU 1
TRIAL_TKT_FAILCOMMS   EQU 2
TRIAL_TKT_FAILRETRY   EQU 3
TRIAL_TKT_FAILPAPER   EQU 4

;******************************************************************************
;
; Function:     TRIAL_TKT_LastTicket
; Input:        tkt_subtot_current and tkt_issue_qty set accordingly
; Output:       C=1 if next printed ticket is the last in the transaction
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TRIAL_TKT_LastTicket:
	MOV     DPTR,#tkt_subtot_current        ; check if its the last
	MOVX    A,@DPTR                         ; entry in the subtotal
	INC     A                               ; table
	MOV     B,A                             ;
	MOV     DPTR,#tkt_subtot_entries        ;
	MOVX    A,@DPTR                         ;
	CJNE    A,B,TRIAL_TKT_LTnotlast               ;

	MOV     DPTR,#tkt_issue_qty             ; check if its the last
	MOVX    A,@DPTR                         ; ticket in a group of
	CJNE    A,#1,TRIAL_TKT_LTnotlast              ; identical tickets

	SETB    C                               ; both - its the last
	RET
TRIAL_TKT_LTnotlast:
	CLR     C                               ; its not the last
	RET
;******************************************************************************
;
; Function:     TRIAL_TKT_PrintTicketDetails
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TRIAL_TKT_PrintTicketDetails:
;       CALL    AUD_FetchTicketDetails
;        MOV     DPTR,#aud_tickettype
	MOVX    A,@DPTR
	MOV     DPTR,#tkt_type
	MOVX    @DPTR,A
	CALL    TKT_SetTicketDate

	IF      USE_BARCODES                    ;
	IF USE_SLAVE                            ;
	CALL    TKT_TicketOutDevice             ; check which type
	MOVX    A,@DPTR                         ; of barcode to generate
	CJNE    A,#2,TRIAL_TKT_PTDnotslave            ;
	MOV     DPTR,#aud_slaveticketnum        ; wristband barcode
	CALL    MTH_LoadOp1Long                 ;
	MOV     DPTR,#bcd_ticket                ;
	CALL    MTH_StoreLong                   ;
	CALL    BCD_PrepareBarcodeWB            ;
	JMP     TRIAL_TKT_PTDbcdok                    ;
	ENDIF                                   ;
TRIAL_TKT_PTDnotslave:                                ;
;        MOV     DPTR,#aud_ticketnum            ; ordinary barcode
	CALL    MTH_LoadOp1Long                 ;
	MOV     DPTR,#bcd_ticket                ;
	CALL    MTH_StoreLong                   ;
	CALL    BCD_PrepareBarcode              ;
TRIAL_TKT_PTDbcdok:                                   ;
	ENDIF                                   ;

	MOV     A,#24
	CALL    PRT_SetBitmapLenSmall
	CALL    PRT_ClearBitmap

	MOV     DPTR,#voi_tkttemplate
	CALL    MEM_SetSource
	MOV     DPTR,#voi_tkttmpl
	CALL    MEM_SetDest
	MOV     R7,#(voi_tkttemplate_end-voi_tkttemplate)
	CALL    MEM_CopyCODEtoXRAMsmall
	MOV     DPSEL,#2
	MOV     DPTR,#voi_tktformat
	CALL    NUM_MultipleFormat

	MOV     DPSEL,#2                        ;
;       MOV     DPTR,#aud_discount              ;
	MOVX    A,@DPTR
	JZ      TRIAL_VOI_PTDnominussign
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#voi_tkttmpl_value+2       ;
	MOV     A,#'-'
	MOVX    @DPTR,A
TRIAL_VOI_PTDnominussign:

;       MOV     DPTR,#aud_tickettype
	MOVX    A,@DPTR
	MOV     DPTR,#tkt_type
	MOVX    @DPTR,A
	CALL    TKT_TicketDesc1
	MOVX    A,@DPTR
	INC     DPTR
	CJNE    A,#22,TRIAL_VOI_PVTDcheck
TRIAL_VOI_PVTDclip:
	MOV     A,#21
	JMP     TRIAL_VOI_PVTDok
TRIAL_VOI_PVTDcheck:
	JNC     TRIAL_VOI_PVTDclip
TRIAL_VOI_PVTDok:
	MOV     R7,A
	CALL    MEM_SetSource
	MOV     DPTR,#voi_tkttmpl_desc1
	CALL    MEM_SetDest
	CALL    MEM_CopyXRAMtoXRAMsmall

	MOV     A,#16
	CALL    PRT_SetBitmapLenSmall
	MOV     DPTR,#voi_tkttmpl
	CALL    PRT_FormatBitmap

	IF USE_BARCODES
	MOV     DPTR,#man_receiptctrl
	MOVX    A,@DPTR
	ANL     A,#MAN_BCDRECEIPT
	JZ      TRIAL_TKT_PTDnobcd
	MOV     A,#24
	CALL    PRT_SetBitmapLenSmall
	MOV     DPTR,#bcd_digitbuffer           ; transfer the barcode
	MOV     R0,#prt_field_str               ; digits to internal memory
	MOV     R7,#16                          ; for formatting
	CALL    MEM_CopyXRAMtoIRAM              ;
	IF USE_SLAVE                            ;
	CALL    TKT_TicketOutDevice             ; check which type
	MOVX    A,@DPTR                         ; of barcode to generate
	CJNE    A,#2,TRIAL_TKT_PTDnotslave2           ;
	MOV     prt_field_width,#10             ; set up the formatting
	MOV     prt_field_x,#11                 ; width / xpos
	JMP     TRIAL_TKT_PTDbcdok2                   ;
	ENDIF                                   ;
TRIAL_TKT_PTDnotslave2:                               ;
	MOV     prt_field_width,#16             ; set up the formatting
	MOV     prt_field_x,#5                  ; width / xpos
TRIAL_TKT_PTDbcdok2:
	MOV     prt_field_len,prt_field_width   ; set up remaining formatting
	MOV     prt_field_mag,#0                ; parameters
	MOV     prt_field_y,#8+8                ;
	MOV     prt_field_flags,#0              ;
	MOV     DPTR,#bcd_digitbuffer           ;
	CALL    PRT_FormatField                 ; format the field
TRIAL_TKT_PTDnobcd:
	ENDIF

	CALL    PRT_PrintBitmap
	RET

;******************************************************************************
;
; Function:     TRIAL_TKT_SelectFields
; Input:        DPTR0=ptr to master copy of field list for ticket layout
;               DPTR1=ptr to working copy of field list for ticket layout
;               R7=number of fields
;               B=advanced layout control flag for this ticket
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Sets the ON/OFF status of each field in the working copy field list
;   according to the ON/OFF status in the master list, and the advanced
;   layout features of the ticket being issued.
;
;******************************************************************************

TRIAL_TKT_SelectFields:
	MOV     DPSEL,#0
	MOVX    A,@DPTR

;       CALL    DebugTX

	MOV     DPSEL,#1
	CJNE    A,#255,TRIAL_TKT_SFnoton
	JMP     TRIAL_TKT_SFon
TRIAL_TKT_SFnoton:
	CJNE    A,#9,TRIAL_TKT_SFnotoff
	JMP     TRIAL_TKT_SFoff
TRIAL_TKT_SFnotoff:
	JNC     TRIAL_TKT_SFoff               ; A>9
	CALL    NUM_GetBitMask
	ANL     A,B
	JNZ     TRIAL_TKT_SFon
TRIAL_TKT_SFoff:
	MOV     A,#9
	JMP     TRIAL_TKT_SFset
TRIAL_TKT_SFon:
	MOV     A,#255
TRIAL_TKT_SFset:
	MOVX    @DPTR,A
	MOV     DPSEL,#0
	INC     DPTR
	MOVX    A,@DPTR
	ADD     A,#FIELD_HEADER-1
	MOV     R6,A
TRIAL_TKT_SFincsrc:
	INC     DPTR
	DJNZ    R6,TRIAL_TKT_SFincsrc
	MOV     DPSEL,#1
	INC     A
TRIAL_TKT_SFincdest:
	INC     DPTR
	DJNZ    ACC,TRIAL_TKT_SFincdest
	DJNZ    R7,TRIAL_TKT_SelectFields
	RET

;******************************************************************************
;
; Function:     TRIAL_TKT_LayoutTicket
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************



TRIAL_TKT_LayoutTicket:
	CALL    TKT_TicketDesc1                         ; set desc 1
	CALL    MEM_SetSource                           ;
	MOV     R7,#(1+PRT_MAX_HORIZ_CHARS)             ;
	MOV     DPTR,#tkt_tmpl_desc1+FIELD_HEADER-1     ;
	CALL    MEM_SetDest                             ;
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;

	CALL    TKT_TicketDesc2                         ; set desc 2
	CALL    MEM_SetSource                           ;
	MOV     R7,#(1+PRT_MAX_HORIZ_CHARS)             ;
	MOV     DPTR,#tkt_tmpl_desc2+FIELD_HEADER-1     ;
	CALL    MEM_SetDest                             ;
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;

	MOV     DPSEL,#0                                ; set value
	MOV     DPTR,#tkt_value                         ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_price+FIELD_HEADER       ;
	MOV     R5,#5                                   ;
	CALL    NUM_NewFormatMoney                      ;
	MOV     DPTR,#tkt_tmpl_price+FIELD_HEADER-1     ;
	MOV     A,#8                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#0                                ; set value
	MOV     DPTR,#tkt_discount                      ;
	MOVX    A, @DPTR                                ; negative value
	JZ      TRIAL_TKT_LTnotnegative                       ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_price+FIELD_HEADER+2     ;
	MOV     A,#'-'                                  ;
	MOVX    @DPTR,A                                 ;

TRIAL_TKT_LTnotnegative:
	MOV     DPSEL,#0                                ; set ticket number
	MOV     DPTR,#tkt_number                        ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_ticketnum+FIELD_HEADER   ;
	MOV     R5,#6+NUM_ZEROPAD                       ;
	CALL    NUM_NewFormatDecimal32                  ;
	MOV     DPTR,#tkt_tmpl_ticketnum+FIELD_HEADER-1 ;
	MOV     A,#6                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#0                                ; set group units
	CALL    TKT_TicketUnitName                      ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_groupunit+FIELD_HEADER   ;
	MOV     R5,#5                                   ;
	CALL    NUM_NewFormatString                     ;
	MOV     DPTR,#tkt_tmpl_groupunit+FIELD_HEADER-1 ;
	MOV     A,#5                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#0                                ; set group qty
	MOV     DPTR,#tkt_groupqty                      ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_groupqty+FIELD_HEADER    ;
	MOV     R5,#5                                   ;
	CALL    NUM_NewFormatDecimal16                  ;
	MOV     DPTR,#tkt_tmpl_groupqty+FIELD_HEADER-1  ;
	MOV     A,#5                                    ;
	MOVX    @DPTR,A                                 ;

	CALL    TIM_GetDateTime
	CALL    TKT_SetTicketDate

	MOV     DPSEL,#1                                ; set date
	MOV     DPTR,#tkt_tmpl_date+FIELD_HEADER        ;
	CALL    TIM_FormatDate                          ;
	MOV     DPTR,#tkt_tmpl_date+FIELD_HEADER-1      ;
	MOV     A,#8                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#1                                ; set time
	MOV     DPTR,#tkt_tmpl_time+FIELD_HEADER        ;
	CALL    TIM_FormatTime                          ;
	MOV     DPTR,#tkt_tmpl_time+FIELD_HEADER-1      ;
	MOV     A,#7                                    ;
	MOVX    @DPTR,A                                 ;

	CALL    TKT_ExpireHour                          ;
	MOVX    A, @DPTR                                ;
	MOV     R3,A
	CALL    TKT_ExpireMinute                        ;
	MOVX    A, @DPTR                                ;
	MOV     R4,A                                    ;
	MOV     DPSEL,#1                                ; set eventtime
	MOV     DPTR,#tkt_tmpl_eventtime+FIELD_HEADER   ;
	CALL    TIM_FormatAdjustedTime                  ;
	MOV     DPTR,#tkt_tmpl_eventtime+FIELD_HEADER-1 ;
	MOV     A,#7                                    ;
	MOVX    @DPTR,A                                 ;

;;;;;;;;;;;;;;;;;;;;;;
; SSM additions 7/3/99
; Note: put queue until time into text14 (which is text12 on the config
; when only 12 of the 16 fields are available!)
;;;;;;;;;;;;;;;;;;;;;;
	MOV     DPTR,#tkt_expirehours2                  ; set queue until
	MOVX    A,@DPTR                                 ; time
	MOV     R3,A                                    ;
	MOV     DPTR,#tkt_expireminutes2                ;
	MOVX    A,@DPTR                                 ;
	MOV     R4,A                                    ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_text14+FIELD_HEADER      ;
;       MOV     DPTR,#tkt_tmpl_date+FIELD_HEADER        ;
	CALL    TIM_FormatAdjustedTime                  ;
	MOV     DPTR,#tkt_tmpl_text14+FIELD_HEADER-1    ;
;       MOV     DPTR,#tkt_tmpl_date+FIELD_HEADER-1      ;
	MOV     A,#7                                    ;
	MOVX    @DPTR,A                                 ;
;;;;;;;;;;;;;;;;;;;;;;

	MOV     DPSEL,#0                                ; set desktop
	MOV     DPTR,#sys_dtserial                      ; serial number
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_dtserial+FIELD_HEADER    ;
	MOV     R5,#5+NUM_ZEROPAD                       ;
	CALL    NUM_NewFormatDecimal32                  ;
	MOV     DPTR,#tkt_tmpl_dtserial+FIELD_HEADER-1  ;
	MOV     A,#5                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#0                                ; set operator number
	MOV     DPTR,#ppg_hdr_usernum                   ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_opernum+FIELD_HEADER     ;
	MOV     R5,#3+NUM_ZEROPAD                       ;
	CALL    NUM_NewFormatDecimal16                  ;
	MOV     DPTR,#tkt_tmpl_opernum+FIELD_HEADER-1   ;
	MOV     A,#3                                    ;
	MOVX    @DPTR,A                                 ;

	MOV     DPSEL,#0                                ; set username
	MOV     DPTR,#ppg_hdr_username                  ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_username+FIELD_HEADER-1  ;
	MOV     R5,#MAX_USERNAME_LEN+1                  ;
	CALL    NUM_NewFormatString                     ;

;       MOV     DPTR,#tkt_tmpl_username+FIELD_HEADER-1
;       MOV     A,#MAX_USERNAME_LEN
;       MOVX    @DPTR,A

	MOV     DPTR,#crd_buffer                        ; set paymentref
	CALL    MEM_SetSource                           ;
	MOV     DPTR,#tkt_tmpl_paymentref+FIELD_HEADER  ;
	CALL    MEM_SetDest                             ;
	MOV     R7,#16                                  ;
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;
	MOV     DPTR,#tkt_tmpl_paymentref+FIELD_HEADER-1;
	MOV     A,#16                                   ;
	MOVX    @DPTR,A                                 ;

	CALL    TKT_TSCtrl                              ; set zone
	MOVX    A,@DPTR                                 ; (no field to display)
	ANL     A,#7                                    ;
	MOV     DPTR,#tkt_zone                          ;
	MOVX    @DPTR,A                                 ;

; bedford additional fields
	IF USE_SEATS
	MOV     DPTR,#tkc_seatblock                     ; set seat block name
	CALL    MEM_SetSource                           ;
	MOVX    A,@DPTR                                 ;
	INC     A                                       ;
	MOV     R7,A                                    ;
	MOV     DPTR,#tkt_tmpl_block+FIELD_HEADER-1     ;
	CALL    MEM_SetDest
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;

	MOV     DPTR,#tkc_seatrow                       ; set seat row name
	CALL    MEM_SetSource                           ;
	MOVX    A,@DPTR                                 ;
	INC     A                                       ;
	MOV     R7,A                                    ;
	MOV     DPTR,#tkt_tmpl_seatrow+FIELD_HEADER-1   ;
	CALL    MEM_SetDest
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;

	MOV     DPTR,#tkc_seatcol                       ; set seat col name
	CALL    MEM_SetSource                           ;
	MOVX    A,@DPTR                                 ;
	INC     A                                       ;
	MOV     R7,A                                    ;
	MOV     DPTR,#tkt_tmpl_seatcol+FIELD_HEADER-1   ;
	CALL    MEM_SetDest
	CALL    MEM_CopyXRAMtoXRAMsmall                 ;
	ENDIF


	CALL    TKT_TicketFixedFields                   ; turn on the
	MOVX    A,@DPTR                                 ; relevant fixed
	MOV     B,A                                     ; fields
	MOV     R7,#TKT_NUM_FIXED_FIELDS                ;
	MOV     DPSEL,#0                                ;
	MOV     DPTR,#ppg_oper_text1                    ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_text1                    ;
	CALL    TKT_SelectFields                        ;

	CALL    TKT_TicketVarFields                     ; turn on the
	MOVX    A,@DPTR                                 ; relevant variable
	MOV     B,A                                     ; fields
	MOV     R7,#TKT_NUM_VAR_FIELDS                  ;
	MOV     DPSEL,#0                                ;
	MOV     DPTR,#ppg_oper_desc1                    ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_desc1                    ;
	CALL    TKT_SelectFields                        ;

	CALL    TKT_TicketVarFields                     ; turn on the
	MOVX    A,@DPTR                                 ; relevant variable
	MOV     B,A                                     ; fields
	MOV     R7,#TKT_NUM_VAR_FIELDS2                 ; (extended layout
	MOV     DPSEL,#0                                ;  fields of
	MOV     DPTR,#ppg_oper_block                    ;  v2.65 and v2.77)
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_block                    ;
	CALL    TRIAL_TKT_SelectFields                        ;

	CALL    PPG_TestChunkDuplicateFields
	JZ      TRIAL_TKT_LTnodupfields

	MOV     DPSEL,#0                                ; copy variable data
	MOV     DPTR,#tkt_dupdatalist                   ; to duplicate fields
	MOV     R5,#NUM_DUP_FIELDS                      ;
	CALL    MEM_MultipleXRAMCopy                    ;

	CALL    TKT_TicketVarFields                     ; turn on the
	MOVX    A,@DPTR                                 ; relevant variable
	MOV     B,A                                     ; fields
	MOV     R7,#NUM_DUP_FIELDS                      ;
	MOV     DPSEL,#0                                ;
	MOV     DPTR,#ppg_dup_desc1                     ;
	MOV     DPSEL,#1                                ;
	MOV     DPTR,#tkt_tmpl_dupdesc1                 ;
	CALL    TRIAL_TKT_SelectFields                        ;

TRIAL_TKT_LTnodupfields:
	RET

;******************************************************************************
;
; Function:     TRIAL_TKT_PrintTicket
; Input:        A = ticket type
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************
TRIAL_TKT_PrintTicket:
	CALL    TKT_GenerateTicketNumber        ; get next ticket number

	IF USE_SLAVE                            ; fail if its a wristband
	 JNZ    TRIAL_TKT_PTnumok                     ; and a wristband ticket
						; number couldnt be given
	CALL    LCD_Clear                       ;
	MOV     DPTR,#msg_slaveexceed           ;
	CALL    LCD_DisplayStringCODE           ;
	MOV     A,#64                           ;
	CALL    LCD_GotoXY                      ;
	CALL    LCD_DisplayStringCODE           ;

	IF      SPEAKER
	CALL    SND_Warning                     ;
	ENDIF

	CALL    KBD_WaitKey                     ;
	JMP     TRIAL_TKT_PTfail                      ;
	ENDIF
	IF USE_BARCODES
	CALL    BCD_AppendToTotals
	ENDIF
TRIAL_TKT_PTnumok:



;*******************************
; Prepare Bitmap Image of Ticket
;*******************************
TRIAL_TKT_PTretry:
	CALL    TRIAL_TKT_LayoutTicket                ; fill in the fields

	MOV     DPTR,#ppg_oper_ticketlen        ; set up the correct
	MOVX    A,@DPTR                         ; ticket length
	INC     DPTR                            ;
	MOV     B,A                             ;
	MOVX    A,@DPTR                         ;
	XCH     A,B                             ;
	CALL    PRT_SetBitmapLen                ;

	CALL    PRT_ClearBitmap                 ; clear and then format
	MOV     DPTR,#tkt_tmpl_text1            ; the bitmap
	CALL    PRT_FormatBitmap                ;

	CALL    PPG_TestChunkDuplicateFields    ; format the duplicate
	JZ      TRIAL_TKT_PTnodupfields               ; var fields if they
	MOV     DPTR,#tkt_tmpl_dupdesc1         ; are enabled
	CALL    PRT_FormatBitmap                ;
TRIAL_TKT_PTnodupfields:                              ;

	IF USE_BARCODES                         ; format the barcode
	 CALL   BCD_FormatBarcode               ; if it exists
	ENDIF                                   ;

;******************************
; Issue Ticket on Output Device
;******************************
	
	
	
	
	CALL    TKT_TicketOutDevice             ; see where to print
	
	
	
	
	MOVX    A,@DPTR                         ; the ticket
	CJNE    A,#2,TRIAL_TKT_PTnotslave             ;
;******
; SLAVE
;******
	IF USE_SLAVE
	CALL    SLV_PrintSlaveTicket            ; tell wristbander what
	CJNE    A,#TRIAL_TKT_OK,TRIAL_TKT_PTnotok
	ENDIF
; OK
	JMP     TRIAL_TKT_PTprintok
TRIAL_TKT_PTnotok:
	CJNE    A,#TRIAL_TKT_FAILCOMMS,TRIAL_TKT_PTnotcomms
; FAILCOMMS
	JMP     TRIAL_TKT_PTfailrecordlog
TRIAL_TKT_PTnotcomms:
	CJNE    A,#TRIAL_TKT_FAILPAPER,TRIAL_TKT_PTnotpaper
; FAILPAPER
	JMP     TRIAL_TKT_PTfaillog
TRIAL_TKT_PTnotpaper:
	CJNE    A,#TRIAL_TKT_FAILRETRY,TRIAL_TKT_PTnotretry
; RETRY
	JMP     TRIAL_TKT_PTretry
TRIAL_TKT_PTnotretry:
	JMP     TRIAL_TKT_PTfailrecordlog


TRIAL_TKT_PTnotslave:
	CJNE    A,#0,TRIAL_TKT_PTnotdt
;***
; DT
;***
	CALL    TRIAL_TKT_PrintDTTicket
	CJNE    A,#TRIAL_TKT_OK,TRIAL_TKT_PTnotok2
; OK
	JMP     TRIAL_TKT_PTprintok
TRIAL_TKT_PTnotok2:
	CJNE    A,#TRIAL_TKT_FAILPAPER,TRIAL_TKT_PTnotpaper2
; FAILPAPER
	JMP     TRIAL_TKT_PTfaillog
TRIAL_TKT_PTnotpaper2:
	CJNE    A,#TRIAL_TKT_FAILRETRY,TRIAL_TKT_PTnotretry2
; RETRY
	JMP     TRIAL_TKT_PTretry
TRIAL_TKT_PTnotretry2:
	JMP     TRIAL_TKT_PTfailrecordlog

TRIAL_TKT_PTnotdt:
;*************
; NON-PRINTING
;*************
	JMP     TRIAL_TKT_PTnonprint                  ; nonprint - don't do anything

TRIAL_TKT_PTprintok:
	JNB     SYS_overheating,TRIAL_TKT_PTendapresprint
	CALL    LCD_Clear
	MOV     DPTR,#msg_cooling
	CALL    LCD_DisplayStringCODE
	MOV     R0,#SYS_COOLINGDELAY
	CALL    delay100ms
	CALL    LCD_Clear

TRIAL_TKT_PTendapresprint:
TRIAL_TKT_PTnonprint:
	CALL    TRIAL_TKT_RecordTicket
	MOV     A,#1
	RET

TRIAL_TKT_PTfailrecordlog:
	CALL    TRIAL_TKT_RecordTicket
TRIAL_TKT_PTfaillog:
	MOV     DPSEL,#0
;       MOV     DPTR,#aud_entry_ticketfail
;       CALL    AUD_AddEntry
TRIAL_TKT_PTfail:
	CALL    LCD_Clear
	CALL    TKT_DisplayIdleState
	CLR     A
	RET

;******************************************************************************
;
; Function:     ?
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************


TRIAL_TKT_PrintDTTicket:
	CALL    PRT_CheckPaper                  ; make sure there is paper
	JB      prt_paperout,TRIAL_TKT_PDTTpaperout   ;
						;
	MOV     DPTR,#ppg_oper_headerfeed       ; do the headerfeed
	MOVX    A,@DPTR                         ; if appropriate
	JZ      TRIAL_TKT_PDTTnohdrfeed               ;
	MOV     R7,A                            ;
	CALL    PRT_LineFeed                    ;
TRIAL_TKT_PDTTnohdrfeed:                              ;
	CALL    PRT_PrintBitmap                 ; print the ticket
	JC      TRIAL_TKT_PDTTpaperout                ;
	CALL    PRT_FormFeed                    ;
	MOV     A,#TRIAL_TKT_OK
	RET

TRIAL_TKT_PDTTpaperout:
	CALL    PRT_PaperOutMsg
	JB      prt_paperout,TRIAL_TKT_PDTTfailpaper
	CALL    LCD_Clear
	MOV     DPTR,#msg_printagain
	CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	CALL    LCD_DisplayStringCODE
	CALL    KBD_WaitKey
	CALL    LCD_Clear
	CALL    TKT_DisplayIdleState
	MOV     A,#TRIAL_TKT_FAILRETRY
	RET
TRIAL_TKT_PDTTfailpaper:
	CALL    LCD_Clear
	CALL    TKT_DisplayIdleState
	MOV     A,#TRIAL_TKT_FAILPAPER
	RET

;******************************************************************************
;
; Function:     ?
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TRIAL_TKT_RecordTicket:
	SETB    tkt_printed

	IF USE_SERVANT
	 MOV    B,#4
	 CALL   COM_TxStatus
	ENDIF

	CALL    SHF_RecordTicket

	MOV     DPTR,#tkt_subtot_printed        ; update the number of
	MOVX    A,@DPTR                         ; tickets printed so far
	INC     A                               ; in this transaction
	MOVX    @DPTR,A                         ;

	;MOV     DPTR,#tkt_subtot_valueprinted   ; update the value of
	;CALL    MTH_LoadOp1Long                 ; tickets printed so far
	;MOV     DPTR,#tkt_value                 ; in this transaction
	;CALL    MTH_LoadOp2Long                 ;
	;CALL    MTH_AddLongs                    ;
	;MOV     DPTR,#tkt_subtot_valueprinted   ;
	;CALL    MTH_StoreLong                   ;


	MOV     DPTR,#tkt_value                 ;
	CALL    MTH_LoadOp1Long                 ;
	MOV     DPTR,#tkt_subtot_valueprinted   ;
	CALL    MTH_LoadOp2Long                 ;

	MOV     DPTR,#tkt_discount
	MOVX    A,@DPTR
	JNZ     TTRTHdiscount

	MOV     DPTR,#tkt_subtot_negativeprinted
	MOVX    A,@DPTR
	JNZ     TTRTHnegative

TTRTHdiscountnegative:
	CALL    MTH_AddLongs                    ;
	JMP     TRIAL_TKT_RTstorevalue                ;

TTRTHnegative:
	CALL    MTH_SwapOp1Op2
	CALL    MTH_TestGTLong
	JNC     TRIAL_TKT_RTsubgoingpositive
	CALL    MTH_SubLongs
	JMP     TRIAL_TKT_RTstorevalue

TRIAL_TKT_RTsubgoingpositive:
	CLR     A
	MOV     DPTR,#tkt_subtot_negativeprinted
	MOVX    @DPTR,A

	CALL    MTH_SwapOp1Op2
	CALL    MTH_SubLongs
	JMP     TRIAL_TKT_RTstorevalue                ;

TTRTHdiscount:
	MOV     DPTR,#tkt_subtot_negativeprinted
	MOVX    A,@DPTR
	JNZ     TTRTHdiscountnegative

	CALL    MTH_TestGTLong
	JC      TRIAL_TKT_RTsubgoingnegative
	CALL    MTH_SwapOp1Op2
	CALL    MTH_SubLongs
	JMP     TRIAL_TKT_RTstorevalue                ;

TRIAL_TKT_RTsubgoingnegative:
	MOV     A,#1
	MOV     DPTR,#tkt_subtot_negativeprinted
	MOVX    @DPTR,A

	CALL    MTH_SubLongs
	;JMP    TRIAL_TKT_RTstorevalue                ;

TRIAL_TKT_RTstorevalue:                               ;
	MOV     DPTR,#tkt_subtot_valueprinted   ;
	CALL    MTH_StoreLong                   ;


	MOV     DPSEL,#0                        ; add ticket entry to audit
	MOV     DPTR,#man_issuemethod           ;
	MOVX    A,@DPTR                         ; if ((instantissue) ||
	CJNE    A,#2,TRIAL_TKT_PTsingletkt            ;    (instantsubtotalling) ||
	MOV     DPTR,#tkt_subtot_tktqty         ;    (fullsubtotalling &&
	CALL    MTH_LoadOp1Word                 ;     tktqty == 1))
	MOV     A,#1                            ; {
	CALL    MTH_LoadOp2Acc                  ;   if (lastticket &&
	CALL    MTH_TestGTWord                  ;     (want codes 53/54))
	JNC     TRIAL_TKT_PTsingletkt                 ;     add a SINGLE+BCD entry
	MOV     DPTR,#man_misc                  ;   else
	MOVX    A,@DPTR                         ;
	ANL     A,#MAN_BCDLASTTKT               ;
	JZ      TRIAL_TKT_PTmultnotlast               ;
	CALL    TRIAL_TKT_LastTicket                  ;     add a SINGLE entry
	JNC     TRIAL_TKT_PTmultnotlast               ; }
;       MOV     DPTR,#aud_entry_ticketmultibcd  ; else
	JMP     TRIAL_TKT_PTdoaudit                   ; {
TRIAL_TKT_PTmultnotlast:                              ;   if (lastticket &&
;       MOV     DPTR,#aud_entry_ticketmulti     ;     (want codes 53/54))
	JMP     TRIAL_TKT_PTdoaudit                   ;     add a MULTI+BCD entry
TRIAL_TKT_PTsingletkt:                                ;   else
	MOV     DPTR,#man_misc                  ;     add a MULTI entry
	MOVX    A,@DPTR                         ;
	ANL     A,#MAN_BCDLASTTKT               ;
	JZ      TRIAL_TKT_PTsglnotlast                ;
	CALL    TRIAL_TKT_LastTicket                  ; }
	JNC     TRIAL_TKT_PTsglnotlast                ;
;       MOV     DPTR,#aud_entry_ticketsinglebcd ;
	JMP     TRIAL_TKT_PTdoaudit                   ;
TRIAL_TKT_PTsglnotlast:                               ;
;       MOV     DPTR,#aud_entry_ticketsingle    ;
TRIAL_TKT_PTdoaudit:                                  ;
;       CALL    AUD_AddEntry                    ;

	MOV     DPTR,#tkt_groupqty              ; check if there is a
	CALL    MTH_LoadOp1Word                 ; group quantity
	MOV     A,mth_op1ll                     ;
	ORL     A,mth_op1lh                     ;
	JZ      TRIAL_TKT_PTextinfonextcheck
	MOV     A,mth_op1lh                     ;
	JNZ     TRIAL_TKT_PTextinfo                   ;
	MOV     A,mth_op1ll                     ;
	CJNE    A,#1,TRIAL_TKT_PTextinfo              ;
	JMP     TRIAL_TKT_PTextinfonextcheck

TRIAL_TKT_PTextinfo:
	MOV     DPSEL,#0                        ; add an extended info
;       MOV     DPTR,#aud_entry_ticketextinfo   ; record for this ticket
;       CALL    AUD_AddEntry                    ;
	JMP     TRIAL_TKT_PTextinfodone

TRIAL_TKT_PTextinfonextcheck:
	MOV     DPTR,#tkt_discount
	MOVX    A, @DPTR                        ; negative value
	JNZ     TRIAL_TKT_PTextinfo                   ;
	MOV     DPTR,#tkt_inmacro
	MOVX    A, @DPTR                        ; in macro flag
	JNZ     TRIAL_TKT_PTextinfo                   ;
	MOV     DPTR,#trans_discount
	MOVX    A, @DPTR                        ; discount transaction flag
	JNZ     TRIAL_TKT_PTextinfo                   ;
TRIAL_TKT_PTextinfodone:

	CALL    TKT_TicketOutDevice             ; check if its a wristband
	MOVX    A,@DPTR                         ; ticket
	CJNE    A,#2,TRIAL_TKT_PTnotslave2            ;
	IF USE_SLAVE                            ;
	MOV     DPSEL,#0                        ; add a SLAVE_TICKET entry
	MOV     DPTR,#aud_entry_slaveticket     ; to the audit
	CALL    AUD_AddEntry                    ;
	ENDIF                                   ;
TRIAL_TKT_PTnotslave2:
	RET

;******************************************************************************
;
; Function:     TRIAL_TKT_PrintTickets
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
; Note : the algorithm is:
;void PrintTickets (void)
;{
;       TRIAL_TKT_DisplaySubtotal ();
;       if (tkt_subtot_entries)
;       {
;               if (man_drawerenable & DRAWER_BEFORE) CDR_OpenCashDrawer ();
;               PRT_StartPrint ();
;               for (cur=0; cur<tkt_subtot_entries; cur++)
;               {
;                       if (doublecancel pressed) break;
;                       memcpy (tkt_type,tkt_subtot_table[cur],TRIAL_TKT_SUBTOT_SIZE);
;                       PrintTicket (tkt_type);
;               }
;               PRT_EndPrint ();
;               if (man_issuemethod == FULL_SUBTOTALLING)
;               {
;                       if (tkt_subtot_qty > 1) AUD_AddEntry (aud_entry_transaction);
;               }
;               if (crd_buffer[0]) TRIAL_TKT_PrintSalesReceipt ();
;               if (man_drawerenable & DRAWER_AFTER) CDR_OpenCashDrawer ();
;       }
;       else if (man_drawerenable & DRAWER_MANUAL)
;       {
;               CDR_OpenCashDrawer ();
;               AUD_AddEntry (aud_entry_cashdrawer);
;       }
;}
;******************************************************************************
TRIAL_TKT_PTnotkts2:  JMP     TRIAL_TKT_PTnotkts
TRIAL_TKT_PTnoflush2: JMP     TRIAL_TKT_PTnoflush

TRIAL_TKT_PrintTickets:

	MOV     A,#SYS_AREA_PRINTTICKET         ; diagnostics
	CALL    SYS_SetAreaCode                 ;

	IF USE_BARCODES
	 CALL   BCD_ResetTotals
	ENDIF

	CALL    TKT_DisplaySubtotal             ; forget it if there are
	MOV     DPTR,#tkt_subtot_entries        ; no tickets to print
	MOVX    A,@DPTR                         ;
	JZ      TRIAL_TKT_PTnotkts2                   ;

	IF USE_TKTCTRL                          ; if using ticket controller
	CALL    TKC_InitiateTransaction         ; send the transaction and
	JZ      TRIAL_TKT_PTnoflush2                  ; give up if no response


	ENDIF                                   ;

	CALL    CDR_GetEnableStatus             ; if required, input the
	JNB     ACC.0,TRIAL_TKT_PTnocdbefore          ; cash tendered before the
	CALL    TKT_CashTendered                ; cash drawer opens

	CALL    CDR_GetEnableStatus             ; if required, open the
	JNB     ACC.1,TRIAL_TKT_PTnocdbefore          ; cash drawer before the
	CALL    CDR_OpenCashDrawer              ; tickets are printed
TRIAL_TKT_PTnocdbefore:                               ;

	CALL    PRT_StartPrint
	MOV     DPTR,#tkt_subtot_current        ; start at first entry
	MOV     A,#0                            ;
	MOVX    @DPTR,A                         ;


TRIAL_TKT_PTloop:
	JB      kbd_doublecancel,TRIAL_TKT_PTabort


	MOV     DPTR,#tkt_subtot_entries        ; check if more entries
	MOVX    A,@DPTR                         ;
	MOV     B,A                             ;
	MOV     DPTR,#tkt_subtot_current        ;
	MOVX    A,@DPTR                         ;
	CJNE    A,B,TRIAL_TKT_PTmore2          ;
TRIAL_TKT_PTabort:
	CALL    PRT_EndPrint

	MOV     DPTR,#man_issuemethod           ; insert a final transaction
	MOVX    A,@DPTR                         ; code if we are running in
	CJNE    A,#2,TRIAL_TKT_PTnotrans              ; full subtotaling mode and
	MOV     DPTR,#tkt_subtot_tktqty         ; there is more than 1 ticket.
	CALL    MTH_LoadOp1Word                 ;
	MOV     A,#1                            ;
	CALL    MTH_LoadOp2Acc                  ;
	CALL    MTH_TestGTWord
	JNC     TRIAL_TKT_PTnotrans

	MOV     DPSEL,#0
;       MOV     DPTR,#aud_entry_transaction
;       CALL    AUD_AddEntry

	MOV     DPTR,#tkt_subtot_negativeprinted
	MOVX    A,@DPTR
	JZ      TRIAL_TKT_PTnotrans

	MOV     DPSEL,#0
;       MOV     DPTR,#aud_entry_transextinfo
;       CALL    AUD_AddEntry

TRIAL_TKT_PTnotrans:
	IF DT5
	ELSE
	CALL    REC_AutoReceipt
	ENDIF
	MOV     DPTR,#crd_buffer
	MOVX    A,@DPTR
	CLR     C
	SUBB    A,#32
	JZ      TRIAL_TKT_PTnoreceipt
	CALL    TKT_PrintSalesReceipt
TRIAL_TKT_PTnoreceipt:
	CALL    CDR_GetEnableStatus             ; if required, input the
	JB      ACC.0,TRIAL_TKT_PTnocdafter           ; cash tendered after the
	CALL    TKT_CashTendered                ; tickets have printed

	CALL    CDR_GetEnableStatus             ; if required, open the
	JNB     ACC.1,TRIAL_TKT_PTnocdafter           ; cash drawer after the
	CALL    CDR_OpenCashDrawer              ; tickets are printed
TRIAL_TKT_PTnocdafter:                                ;
	CALL    TKT_WaitCashDrawerClose
TRIAL_TKT_PTgotoidle:
;;;     CALL    DIS_IdleMessage

	MOV     DPTR,#man_tktdelay              ; do 'tktdelay' seconds delay
	MOVX    A,@DPTR                         ; if required
	JZ      TRIAL_TKT_PTnodelay                   ;
	MOV     R7,A                            ;
TRIAL_TKT_PTsecdelay:                                 ;
	CALL    testdelay                       ;
	CALL    testdelay                       ;
	DJNZ    R7,TRIAL_TKT_PTsecdelay               ;
TRIAL_TKT_PTnodelay:                                  ;

	MOV     DPTR,#man_misc                  ; do keyboard flush if
	MOVX    A,@DPTR                         ; required
	ANL     A,#MAN_AUTOFLUSH                ;
	JZ      TRIAL_TKT_PTnoflush                   ;
	CALL    KBD_FlushKeyboard               ;
TRIAL_TKT_PTnoflush:                                  ;
	RET                                     ;

TRIAL_TKT_PTmore2:
	JMP     TRIAL_TKT_PTmore

TRIAL_TKT_PTnotkts:                                   ; no tickets to print, check
	MOV     DPTR,#man_drawerenable          ; if user allowed to
	MOVX    A,@DPTR                         ; open cash drawer
	ANL     A,#4                            ; manually
	JZ      TRIAL_TKT_PTnomancd                   ;
	CALL    CDR_OpenCashDrawer              ;
	CALL    TIM_GetDateTime                 ; log the opening of
	MOV     DPSEL,#0                        ; the cash drawer
;       MOV     DPTR,#aud_entry_cashdrawer      ;
;       CALL    AUD_AddEntry                    ;
TRIAL_TKT_PTnomancd:                                  ;
	JMP     TRIAL_TKT_PTgotoidle                  ;


TRIAL_TKT_PTmore:
	CALL    TKT_LoadUpTicket                ; load up next ticket

TRIAL_TKT_PTqtyloop:

	IF USE_ALTON_FAST
TRIAL_TKT_PTgetpacketloop:
	 CALL   TKC_Idle
	 JNZ    TRIAL_TKT_PTgetpacketloop
	ENDIF

	CALL    TRIAL_TKT_PrintTicket                 ; print the ticket
	PUSHACC

	IF USE_ALTON_FAST
	 INC    alton_tktcount
	ENDIF

	IF USE_ALTONCOMMS
	 CALL   CUT_FireCutter
	ELSE
	 CALL   CUT_FireCutter                  ; fire the paper cutter
	ENDIF

	IF      PREPRINT
	CALL    PRT_StartPrint
	MOV     DPTR,#tkt_tmpl_text1
	CALL    PRT_PrintOperatorField
	MOV     DPTR,#tkt_tmpl_text2
	CALL    PRT_PrintOperatorField
	CALL    PRT_EndPrint
	ENDIF

	POP     ACC

	IF      USE_TKTCTRL
	CALL    TKC_GetNextTicket

; need to tell difference here between
; 1) giving up because out of paper
; 2) giving up because PC sent TSF
; 3) giving up because DT/PC out of sync and DT got a TSD unexpectedly

	ENDIF
	JNZ     TRIAL_TKT_PTnext                      ; dont print any more if
	JMP     TRIAL_TKT_PTabort                     ; there was a failure

TRIAL_TKT_PTnext:
	MOV     DPTR,#tkt_issue_qty             ; decrement the required
	MOVX    A,@DPTR                         ; ticket quantity
	DEC     A                               ;
	MOVX    @DPTR,A                         ; repeat if any more of
	JNZ     TRIAL_TKT_PTqtyloop                   ; same type of ticket

; if printed, record the stats/audit roll here
	MOV     DPTR,#tkt_subtot_current        ; move on to next entry
	MOVX    A,@DPTR                         ;
	INC     A                               ;
	MOVX    @DPTR,A                         ;
	JMP     TRIAL_TKT_PTloop


	END


;******************************** End Of TKTPRINT.ASM **************************



















