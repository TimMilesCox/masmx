;******************************************************************************
;
; File     : AUDIT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the low level audit handling routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
; 1.
;   To remove the ram daughter board from a DT5/DT10 without losing its
;   contents:
;     With power on, connect backup battery, push switch, power off, remove
;   To reconnect a ram daughterboard:
;     Connect board, power on, release switch remove external backup battery.
;   (Most boards don't now have switches, they have a 2 pin shortable jumper)
; 2.
;   If the aud_last pointer becomes corrupted during operation and points to an
;     entry which does not exist (i.e, > total_entries) the pointer will be
;     restored (when the next audit roll is printed) to the entry furthest from
;     aud_first such that the next audit roll printed will be the entire memory
;     (since it is unknown where the actual end is). Corruption of aud_last
;     affects little else, although later it will obviously very much affect
;     transaction uploading. If it is corrupted to a valid entry number, the
;     audit roll will appear to be either longer or shorter than it should be.
; 3.
;   If the aud_first pointer becomes corrupted during operation and points to
;     an entry which does not exist (i.e, > total_entries) the pointer will
;     automatically be reset to zero after the next entry is added. This means
;     the next entry is lost (and probably spewed over another entry somewhere
;     in audit memory), but all entries after that are ok, although the
;     aud_last pointer is somewhat meaningless. If it is corrupted to a valid
;     entry number, the audit roll will appear to 'jump' to a different point
;     in time, and the length is fairly meaningless too.
; 4.
;   Cleardown of audit roll (manager level function) will cure both.
;
;******************************************************************************

;******************
; Audit Functions *
;******************

;void AUD_InitAudit (void)
;void AUD_ClearAudit (void)
;DPTR AUD_AuditEntryAddr (DPTR)
;void AUD_NextEntry (DPTR)
;void AUD_PrevEntry (DPTR)
;void AUD_AddEntry (DPTR0)
;void AUD_DisplayAuditEntry (DPTR)
;void AUD_FormatEntry (void)
;void AUD_DisplayAuditRoll (void)
;void AUD_ManagerCleardown (void)

;**********
; Variables
;**********

AUD_TKT			EQU 0
AUD_TRX			EQU 1

AUD_UP			EQU 1	; direction flags used in
AUD_DOWN		EQU 0	; audit traversal routines

AUD_OK			EQU 1	; status flags
AUD_END			EQU 2	; used in audit
AUD_ERROR		EQU 3	; traversal routines
AUD_NONE		EQU 4
AUD_REPEAT		EQU 5
AUD_ABORT		EQU 6

AUDIT_ENTRY_SIZE	EQU 16		; was 9
AUDIT_ENTRIES_PER_PAGE	EQU 2048	; was 3640	; 32K/9
AUDIT_TOTAL_PAGES	EQU 8		; 256K/32K
AUD_MAX_CODE	        EQU 71		; the last used audit code

; aud_first:		VAR 4 ; (declr in DT.ASM for just now)
; aud_last:		VAR 4
aud_buf:		VAR AUDIT_ENTRY_SIZE
aud_line:		VAR (3*(FIELD_HEADER+32))+1

aud_code:		VAR 1
aud_ptr:		VAR 4 ; general purpose audit record pointer
aud_transactionh:	VAR 4 ; head ptr of transaction (for void, receipt)
aud_transactiont:	VAR 4 ; tail ptr of transaction (for void, receipt)
aud_ticketh:		VAR 4 ; head ptr of ticket (for void, receipt)
aud_tickett:		VAR 4 ; tail ptr of ticket (for void, receipt)

aud_scanctrl:           VAR 1 ; used for scanning the audit

aud_ticketnum:		VAR 4 ; values set by AUD_FetchTicketDetails
aud_slaveticketnum:	VAR 4 ; which are used for functions like
aud_tickettype:		VAR 1 ; void and receipt
aud_groupqty:		VAR 2 ;
aud_discount:		VAR 1 ;
aud_macrotkt:		VAR 1 ;
aud_disctrans:		VAR 1 ;

aud_tkttotal:		VAR 4 ;
aud_trxtotal:		VAR 4 ;
aud_trxtotal40:		VAR 4 ;
aud_tkttime:		VAR 2 ;
aud_trxnegative:	VAR 1 ;
aud_lastdiscount:	VAR 1 ;
aud_lastvalue:		VAR 4 ;

aud_displayparam:	VAR 1
aud_warning:		VAR 1 ; has the user had the 90% warning yet ?
aud_upload_result:	VAR 1 ; 1=success, 2=abort, 3=fail
UPLOAD_SUCCESS EQU 1
UPLOAD_ABORT EQU 2
;UPLOAD_FAIL EQU 3

aud_total_entries:	DD (AUDIT_ENTRIES_PER_PAGE*AUDIT_TOTAL_PAGES)
aud_template:		DB 255,32,0,0,0,0,32,'                                '
			DB 255,32,0,0,0,8,32,'                                '
			DB 255,32,0,0,0,16,32,'                                '
			DB 0
asterisks:		DB '********************************'
msg_auditroll:		DB 255,20,0,1,0,0,20,'=====Audit Roll====='
msg_auditcorrupt:       DB 255,21,0,0,0,0,21,'Audit Pointer Corrupt'
msg_audclear:		DB 24,'Clear AUDIT MEMORY - OK?'
msg_audcleared:		DB 24,'  AUDIT MEMORY CLEARED  '

set_10_40_51_52_54_55:	DB 10,40,51,52,54,55,0
set_50_52_53_55:	DB 50,52,53,55,0
set_40_51_54:		DB 40,51,54,0
set_40_50_53:		DB 40,50,53,0
set_50_53:		DB 50,53,0
set_51_54:		DB 51,54,0
set_52_55:		DB 52,55,0

;******************************************************************************
;
;              A u d i t   R o l l   D i s p l a y   F o r m a t s
;
;******************************************************************************
;
; aud_format_<name>: DB <displaymask>
;                    DB <num params>
;                    DB <print lines (1 or 2)>
;
; for each param-->  DW <param addr>,DW <dest addr>
;                    DB <R5 format>,<R6 format>,<param type>
;
;******************************************************************************

AUD_MASK_ALL	EQU 1
AUD_MASK_SYSTEM EQU 2
AUD_MASK_SHIFT	EQU 4
AUD_MASK_NONTKT EQU 8

aud_msg_invalid:	DB 'Invalid Audit Line'

aud_format_unused:
aud_format_invalid:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_SHIFT+AUD_MASK_NONTKT,1,1
	DW aud_msg_invalid
	DW aud_line+FIELD_HEADER+3
	DB 18,0,NUM_PARAM_STRINGCODE

;*** SYSTEM CONTROL - 00's ***

	IF PRT_CLAA
aud_format_switchon:
aud_format_switchoff:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; date
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5			; serial
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+16
	DB 5,0,NUM_PARAM_DECIMAL32
	ENDIF

aud_format_booterror:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_NONTKT,3,1
	DW aud_buf+1			; areacode
	DW aud_line+FIELD_HEADER+3
	DB 3,0,NUM_PARAM_DECIMAL8
	DW aud_buf+2			; hardware powerup status
	DW aud_line+FIELD_HEADER+7
	DB 3,0,NUM_PARAM_DECIMAL8
	DW aud_buf+3			; powerfail signal
	DW aud_line+FIELD_HEADER+11
	DB 1,0,NUM_PARAM_DECIMAL8

;*** SHIFT CODES - 10's ***

	IF PRT_CLBM
aud_format_startshift:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,3,1
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; date
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5			; shift
	DW aud_line+FIELD_HEADER+18
	DB 5,0,NUM_PARAM_DECIMAL16
	ENDIF
	IF PRT_CLAA
aud_format_startshift:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,4,3
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; date
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5			; shift
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+0
	DB 5,0,NUM_PARAM_DECIMAL16
	DW asterisks
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+32+FIELD_HEADER
	DB 32,0,NUM_PARAM_STRINGCODE
	ENDIF

;*****

	IF PRT_CLBM
aud_format_endshift:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,3,1
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; shift
	DW aud_line+FIELD_HEADER+9
	DB 5,0,NUM_PARAM_DECIMAL16
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+15
	DB 8,0,NUM_PARAM_MONEY
	ENDIF
	IF PRT_CLAA
aud_format_endshift:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; shift
	DW aud_line+FIELD_HEADER+9
	DB 5,0,NUM_PARAM_DECIMAL16
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+10
	DB 8,0,NUM_PARAM_MONEY
	ENDIF

	IF PRT_CLAA
aud_format_endshiftabort:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; shift
	DW aud_line+FIELD_HEADER+9
	DB 5,0,NUM_PARAM_DECIMAL16
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+10
	DB 8,0,NUM_PARAM_MONEY
	ENDIF

	IF PRT_CLAA
aud_format_declaretakings:
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; shift
	DW aud_line+FIELD_HEADER+9
	DB 5,0,NUM_PARAM_DECIMAL16
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+10
	DB 8,0,NUM_PARAM_MONEY
	ENDIF

;*** PRICEPLUG CODES - 20's ***

aud_format_plugread:
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,2,1
	DW aud_buf+1			; plugnum
	DW aud_line+FIELD_HEADER+3
	DB 6,0,NUM_PARAM_DECIMAL32
	DW aud_buf+5			; opernum
	DW aud_line+FIELD_HEADER+10
	DB 3,0,NUM_PARAM_DECIMAL16

aud_format_plugconfig:
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,1,1
	DW aud_buf+1			; config_filename
	DW aud_line+FIELD_HEADER+3
	DB 11,0,NUM_PARAM_STRING

;*** VOIDING / RECEIPTING CODSE - 30's ***

aud_format_voidtkt: ; 30
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; ticketnum
	DW aud_line+FIELD_HEADER+9
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32
	DW aud_buf+7			; value
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+12
	DB 6,2,NUM_PARAM_MONEY

aud_format_voidtkttotal: ; 31
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT,2,1
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; void_tkt_total
	DW aud_line+FIELD_HEADER+10
	DB 8,2,NUM_PARAM_MONEY

aud_format_receipt: ; 39
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; firstticket
	DW aud_line+FIELD_HEADER+9
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32
	DW aud_buf+7			; total
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+11
	DB 7,2,NUM_PARAM_MONEY

;*** TRANSACTIONS CODES - 40's ***

aud_format_multitkt:
	DB AUD_MASK_ALL,3,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3			; count
	DW aud_line+FIELD_HEADER+9
	DB 3,0,NUM_PARAM_DECIMAL8
	DW aud_buf+4			; value
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+11
	DB 7,2,NUM_PARAM_MONEY

aud_format_tendered:
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,2,2
	DW aud_buf+1			; tendered
	DW aud_line+FIELD_HEADER+3
	DB 7,2,NUM_PARAM_MONEY
	DW aud_buf+5			; change
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+11
	DB 7,2,NUM_PARAM_MONEY

aud_format_transextinfo: ; 42
	DB AUD_MASK_ALL,1,1
	DW aud_buf+1			; negative flag
	DW aud_line+FIELD_HEADER+3
	DB 5,0,NUM_PARAM_DECIMAL8

;*** TICKETING CODES - 50's ***

	IF PRT_CLAA
aud_format_ticketmulti: ; 50
aud_format_ticketsingle: ; 51
aud_format_ticketfail: ; 59
	DB AUD_MASK_ALL,4,2
	DW aud_buf+1			; time
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
;;; DB 5,2,NUM_PARAM_DECIMAL16
	DW aud_buf+3			; type
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_TICKETTYPE
	DW aud_buf+4			; number
	DW aud_line+FIELD_HEADER+12
	DB 6+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL32
	DW aud_buf+9			; value
	DW aud_line+FIELD_HEADER+32+FIELD_HEADER+12
	DB 6,2,NUM_PARAM_MONEY
	ENDIF
	IF PRT_CLBM
; do it later
	ENDIF

aud_format_ticketextinfo: ; 52
	DB AUD_MASK_ALL,4,1
	DW aud_buf+1			; groupqty
	DW aud_line+FIELD_HEADER+3
	DB 5,0,NUM_PARAM_DECIMAL16
	DW aud_buf+3			; discount flag
	DW aud_line+FIELD_HEADER+9
	DB 1,0,NUM_PARAM_DECIMAL8
	DW aud_buf+4			; macro flag
	DW aud_line+FIELD_HEADER+11
	DB 1,0,NUM_PARAM_DECIMAL8
	DW aud_buf+5			; discount transaction flag
	DW aud_line+FIELD_HEADER+13
	DB 1,0,NUM_PARAM_DECIMAL8

aud_format_slaveticket: ; 55
	DB AUD_MASK_ALL,1,1
	DW aud_buf+1			; slave ticket number
	DW aud_line+FIELD_HEADER+3
	DB 6,0,NUM_PARAM_DECIMAL32

;*** MISC FUNCTIONS - 60's ***

aud_format_spotcheck:
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,2,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE

aud_format_changetime:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_NONTKT,2,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_TIME

aud_format_changedate:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_NONTKT,2,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+12
	DB 0,0,NUM_PARAM_DATE

aud_format_memclear:
aud_format_tktnoclear:
aud_format_waynoclear:
	DB AUD_MASK_ALL+AUD_MASK_SYSTEM+AUD_MASK_NONTKT,3,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+18
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

;*** MISC OPERATOR FUNCTIONS - 70's ***

aud_format_cashdrawer: ; 70
	DB AUD_MASK_ALL+AUD_MASK_NONTKT,3,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+18
	DB 3+NUM_ZEROPAD,0,NUM_PARAM_DECIMAL16

aud_format_commsupload: ;71
	DB AUD_MASK_ALL+AUD_MASK_NONTKT+AUD_MASK_SYSTEM,3,1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0,0,NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 0,0,NUM_PARAM_DATE
	DW aud_buf+5
	DW aud_line+FIELD_HEADER+18
	DB 1,0,NUM_PARAM_DECIMAL8

	IF USE_TMACHS
;*** TURNSTILE FUNCTIONS - 80's ***

aud_format_tsclick:	;80
	DB AUD_MASK_ALL+AUD_MASK_NONTKT, 2, 1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0, 0, NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 6, 0, NUM_PARAM_DECIMAL8

aud_format_tstotal:	;81
	DB AUD_MASK_ALL+AUD_MASK_SHIFT+AUD_MASK_NONTKT, 2, 1
	DW aud_buf+1
	DW aud_line+FIELD_HEADER+3
	DB 0, 0, NUM_PARAM_TIME
	DW aud_buf+3
	DW aud_line+FIELD_HEADER+9
	DB 6, 0, NUM_PARAM_DECIMAL32
	ENDIF


aud_format_master:
	DW	aud_format_invalid		; audit code 0
	DW	aud_format_switchon		; audit code 1
	DW	aud_format_switchoff		; audit code 2
	DW	aud_format_unused		; audit code 3
	DW	aud_format_unused		; audit code 4
	DW	aud_format_unused		; audit code 5
	DW	aud_format_unused		; audit code 6
	DW	aud_format_unused		; audit code 7
	DW	aud_format_unused		; audit code 8
	DW	aud_format_booterror		; audit code 9
	DW	aud_format_startshift		; audit code 10
	DW	aud_format_endshift		; audit code 11
	DW	aud_format_endshiftabort	; audit code 12
	DW	aud_format_declaretakings	; audit code 13
	DW	aud_format_unused		; audit code 14
	DW	aud_format_unused		; audit code 15
	DW	aud_format_unused		; audit code 16
	DW	aud_format_unused		; audit code 17
	DW	aud_format_unused		; audit code 18
	DW	aud_format_unused		; audit code 19
	DW	aud_format_plugread		; audit code 20
	DW	aud_format_plugconfig		; audit code 21
	DW	aud_format_unused		; audit code 22
	DW	aud_format_unused		; audit code 23
	DW	aud_format_unused		; audit code 24
	DW	aud_format_unused		; audit code 25
	DW	aud_format_unused		; audit code 26
	DW	aud_format_unused		; audit code 27
	DW	aud_format_unused		; audit code 28
	DW	aud_format_unused		; audit code 29
	DW	aud_format_voidtkt		; audit code 30
	DW	aud_format_voidtkttotal		; audit code 31
	DW	aud_format_unused		; audit code 32
	DW	aud_format_unused		; audit code 33
	DW	aud_format_unused		; audit code 34
	DW	aud_format_unused		; audit code 35
	DW	aud_format_unused		; audit code 36
	DW	aud_format_unused		; audit code 37
	DW	aud_format_unused		; audit code 38
	DW	aud_format_receipt		; audit code 39
	DW	aud_format_multitkt		; audit code 40
	DW	aud_format_tendered		; audit code 41
	DW	aud_format_transextinfo		; audit code 42
	DW	aud_format_unused		; audit code 43
	DW	aud_format_unused		; audit code 44
	DW	aud_format_unused		; audit code 45
	DW	aud_format_unused		; audit code 46
	DW	aud_format_unused		; audit code 47
	DW	aud_format_unused		; audit code 48
	DW	aud_format_unused		; audit code 49
	DW	aud_format_ticketmulti		; audit code 50
	DW	aud_format_ticketsingle		; audit code 51
	DW	aud_format_ticketextinfo	; audit code 52
	DW	aud_format_ticketmulti		; audit code 53
	DW	aud_format_ticketsingle		; audit code 54
	DW	aud_format_slaveticket		; audit code 55
	DW	aud_format_unused		; audit code 56
	DW	aud_format_unused		; audit code 57
	DW	aud_format_unused		; audit code 58
	DW	aud_format_ticketfail		; audit code 59
	DW	aud_format_unused		; audit code 60
	DW	aud_format_unused		; audit code 61
	DW	aud_format_spotcheck		; audit code 62
	DW	aud_format_changetime		; audit code 63
	DW	aud_format_changedate		; audit code 64
	DW	aud_format_memclear		; audit code 65
	DW	aud_format_tktnoclear		; audit code 66
	DW	aud_format_waynoclear		; audit code 67
	DW	aud_format_unused		; audit code 68
	DW	aud_format_unused		; audit code 69
	DW	aud_format_cashdrawer		; audit code 70
	DW	aud_format_commsupload		; audit code 71
	IF USE_TMACHS
	 DW	aud_format_tsclick		; audit code 80
	 DW	aud_format_tstotal		; audit code 81
	ENDIF

;*******************************************************************************
;
;                          Audit Table Entry Formats
;
;*******************************************************************************
;
; aud_entry_<name>: DB <auditcode>,<num params>
;
; for each param--> DB <param size>
;               --> DW <param addr in xram>
;
;*******************************************************************************

;*** SYSTEM CONTROL CODES - 00's ***

aud_entry_switchon:
	DB 1,3			; time date serial
        DB 2
        DW timebuffer
        DB 2
        DW datebuffer
        DB 4
        DW sys_dtserial

aud_entry_switchoff:
	DB 2,3			; time date serial
	DB 2
        DW timebuffer
        DB 2
        DW datebuffer
        DB 4
        DW sys_dtserial

aud_entry_reset:
	DB 3,2			; time date ??? ADD reason later
	DB 2
        DW timebuffer
        DB 2
        DW datebuffer

aud_entry_shutdown:
	DB 4,2			; time date ??? ADD reason later
        DB 2
        DW timebuffer
        DB 2
        DW datebuffer

aud_entry_booterror:
        DB 9,3			; areacode powerupstatus powerfail
        DB 1
        DW dia_boot_area
        DB 1
        DW dia_boot_powerup
        DB 1
        DW dia_boot_powerfail

;*** SHIFT CODES - 10's ***

aud_entry_startshift:
	DB 10,3			; time date shift
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 2
	DW shf_shift

aud_entry_endshift:
	DB 11,3			; time shift total
	DB 2
	DW shf_timeto+2 ;timebuffer
	DB 2
	DW shf_shift
	DB 4
	DW shf_runtotal

aud_entry_endshiftabort:
	DB 12,3			; time shift total
	DB 2
	DW shf_timeto+2 ;timebuffer
	DB 2
	DW shf_shift
	DB 4
	DW shf_runtotal

aud_entry_declaretakings:
	DB 13,3			; time shift total
	DB 2
	DW shf_timeto+2 ;timebuffer
	DB 2
	DW shf_shift
	DB 4
	DW shf_declaretakings

;*** PRICEPLUG CODES - 20's ***

aud_entry_plugread:
	DB 20,2			; plugnum opernum
	DB 4
	DW ppg_fixhdr_plugnum
	DB 2
	DW ppg_hdr_usernum

aud_entry_plugconfig:
	DB 21,1			; config_filename
        DB 11
        DW ppg_hdr_filename

;*** VOIDING / RECEIPTING CODES - 30's ***

aud_entry_voidtkt:
	DB 30,3			; time ticketnum value
        DB 2
        DW timebuffer
        DB 4
        DW aud_ticketnum
        DB 4
        DW aud_tkttotal

aud_entry_voidtkttotal:
	DB 31,2			; time voidtkttotal
        DB 2
        DW timebuffer
        DB 4
        DW shf_voidtkttotal

aud_entry_receipt:
	DB 39,3			; time firstticket total
	DB 2
        DW timebuffer
        DB 4
        DW aud_ticketnum
        DB 4
        DW aud_trxtotal

;*** TRANSACTIONS CODES - 40's ***

aud_entry_transaction:
	DB 40,3			; time count value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_subtot_printed
	DB 4
	DW tkt_subtot_valueprinted

aud_entry_tendered:
	DB 41,2			; tendered change
	DB 4
	DW tkt_amounttendered
	DB 4
	DW tkt_change

aud_entry_transextinfo:
	DB 42,1			; time negative_flag
	DB 1
	DW tkt_subtot_negativeprinted


;*** TICKETING CODES - 50's ***

aud_entry_ticketmulti:
	DB 50,5			; time type number vat value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_type
	DB 4
	DW tkt_number
	DB 1
	DW tkt_vat
	DB 4
	DW tkt_value

aud_entry_ticketsingle:
	DB 51,5			; time type number vat value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_type
	DB 4
	DW tkt_number
	DB 1
	DW tkt_vat
	DB 4
	DW tkt_value

aud_entry_ticketextinfo:
	DB 52,4			; groupqty
	DB 2
	DW tkt_groupqty
	DB 1
	DW tkt_discount		; discount flag
	DB 1
	DW tkt_inmacro		; macro flag
	DB 1
	DW trans_discount	; discount transaction flag

aud_entry_ticketmultibcd:
	DB 53,5			; time type number vat value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_type
	DB 4
	DW tkt_number
	DB 1
	DW tkt_vat
	DB 4
	DW tkt_value

aud_entry_ticketsinglebcd:
	DB 54,5			; time type number vat value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_type
	DB 4
	DW tkt_number
	DB 1
	DW tkt_vat
	DB 4
	DW tkt_value

aud_entry_slaveticket:
	DB 55,1			; slaveticket
	DB 4
	DW tkt_slavenumber

aud_entry_ticketfail:
	DB 59,5			; time type number vat value
	DB 2
	DW timebuffer
	DB 1
	DW tkt_type
	DB 4
	DW tkt_number
	DB 1
	DW tkt_vat
	DB 4
	DW tkt_value

;*** MISC MANAGER/PROGRAMMER FUNCTIONS - 60's ***

aud_entry_spotcheck:
	DB 62,2			; time date
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer

aud_entry_changetime:
	DB 63,2			; time oldtime
	DB 2
	DW timebuffer
	DB 2
	DW oldtimebuffer

aud_entry_changedate:
	DB 64,2			; date olddate
        DB 2
	DW datebuffer
	DB 2
	DW olddatebuffer

aud_entry_memclear:
	DB 65,3			; time date user
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 2
	DW ppg_hdr_usernum

aud_entry_tktnoclear:
	DB 66,3			; time date user
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 2
	DW ppg_hdr_usernum

aud_entry_waynoclear:
	DB 67,3			; time date user
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 2
	DW ppg_hdr_usernum

;*** MISC OPERATOR FUNCTIONS - 70's ***

aud_entry_cashdrawer:
	DB 70,3			; time date user
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 2
	DW ppg_hdr_usernum

aud_entry_commsupload:
	DB 71,3			; time date result
	DB 2
	DW timebuffer
	DB 2
	DW datebuffer
	DB 1
	DW aud_upload_result

	IF USE_TMACHS
;*** TURNSTILE FUNCTIONS - 80's ***

aud_entry_tsclick:
	DB 80, 2		; time little bodycount
	DB 2
	DW timebuffer
	DB 1
	DW lou_tempbc

aud_entry_tstotal:
	DB 81, 2		; time bodycount
	DB 2
	DW timebuffer
	DB 4
	DW lou_bodycount
	ENDIF


;******************************************************************************
;
;                L o w   L e v e l   A u d i t   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	AUD_InitAudit
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_InitAudit:
	CLR	A
        MOV	DPTR,#aud_warning
        MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	AUD_ClearAudit
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_ClearAudit:
	CLR	A				; reset audit ptr to entry 0
	CALL	MTH_LoadOp1Acc			;
	MOV	DPTR,#aud_first			;
	CALL	MTH_StoreLong			;
	MOV	DPTR,#aud_last			;
	CALL	MTH_StoreLong			;
        MOV	DPTR,#aud_uploadfrom		;
        CALL	MTH_StoreLong			;
        MOV	DPTR,#aud_uploadto		;
        CALL	MTH_StoreLong			;

	MOV	DPSEL,#0			; add an entry telling us the
	MOV	DPTR,#aud_entry_memclear	; audit memory was cleared
	CALL	AUD_AddEntry			;

	RET

;******************************************************************************
;
; Function:	AUD_AuditEntryAddr
; Input:	DPTR = address of long audit entry number
; Output:	DPTR = offset of audit entry (8000h to ffffh)
; Preserved:	?
; Destroyed:	?
; Description:
;   Calculates the address of a specified audit roll entry and leaves DPTR
;   pointing to the offset within the required page (page is output to the
;   decoding circuitry). I.e, audit entry ready to access at location DPTR.
;
;******************************************************************************

AUD_AuditEntryAddr:
	CALL	MTH_LoadOp1Long
	MOV	mth_op2ll,#LOW(AUDIT_ENTRIES_PER_PAGE)
	MOV	mth_op2lh,#HIGH(AUDIT_ENTRIES_PER_PAGE)
	CALL	MTH_Divide32by16		; op1 = entrynum/numperpage
	ANL	SB1data,#32
	MOV	A,mth_op1ll
	ANL	A,#31			; page in lower 5 bits
;	ORL	A,SB1data
;	MOV	SB1data,A
;	CALL	SBS_WriteSB1
	MOV	A,#AUDIT_ENTRY_SIZE
	CALL	MTH_LoadOp1Acc
	CALL	MTH_Multiply32by16	; op1=(entrynum%numperpage)*entrysize
	MOV	DPL,mth_op1ll
	MOV	A,mth_op1lh
	ORL	A,#080h
	MOV	DPH,A			; DPTR=offset+8000h
	RET

;******************************************************************************
;
; Function:	AUD_NextEntry
; Input:	DPTR=pointer to audit entry number
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   The 4 byte audit entry number pointed to by DPTR is updated to point to the
;   next entry, wrapping back to the first if necessary.
;
;******************************************************************************

AUD_NextEntry:
	PUSHDPH
	PUSHDPL
	CALL	MTH_IncLong
	MOV	DPTR,#aud_total_entries
	MOV	R0,#mth_operand2
	CALL	MTH_LoadConstLong
	POP	DPL
	POP	DPH
	CALL	MTH_CompareLongs		; test for audentry =
	JNZ	AUD_NEwrap			; aud_total_entries

        CALL    MTH_TestGTLong			; test for audentry >
        JNC	AUD_NEnowrap			; aud_total_entires
AUD_NEwrap:
	MOV	A,#0				; reset to first entry
	CALL	MTH_LoadOp1Acc			;
	CALL	MTH_StoreLong			;
AUD_NEnowrap:
        CALL	AUD_CheckInRange
	RET

;******************************************************************************
;
; Function:	AUD_PrevEntry
; Input:	DPTR=pointer to audit entry number
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   The 4 byte audit entry number pointed to by DPTR is updated to point to the
;   previous entry, wrapping back to the last if necessary.
;
;******************************************************************************

AUD_PrevEntry:
	PUSHDPH
	PUSHDPL
	CALL	MTH_LoadOp1Long
	MOV	A,#0
	CALL	MTH_LoadOp2Acc
	CALL	MTH_CompareLongs
	JZ	AUD_PEnowrap
	MOV	DPTR,#aud_total_entries
	MOV	R0,#mth_operand1
	CALL	MTH_LoadConstLong
	POP	DPL
	POP	DPH
	PUSHDPH
	PUSHDPL
	CALL	MTH_StoreLong
AUD_PEnowrap:
	POP	DPL
	POP	DPH
AUD_PEdec:
	CALL	MTH_DecLong
        CALL	AUD_CheckInRange
	RET

;******************************************************************************
;
; Function:	AUD_CheckInRange
; Input:	None
; Output:       A=1=ok, A=0=fail
; Preserved:	?
; Destroyed:	?
; Description:
;   Checks if aud_ptr is pointing a to an audit record between aud_first
;   and aud_last.
; Note:
;   Uses algorithm:
;	if ptr >= first
;		if first>last ok
;		if last>=ptr ok
;		fail
;	else
;		if last>first fail
;		if ptr>=last fail
;		ok
;******************************************************************************

AUD_CheckInRange:
	MOV	DPTR,#aud_ptr			; if (ptr>=first) goto else
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_last			;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_CompareLongs		;
        JNZ	AUD_CIRelse			;
        CALL	MTH_TestGTLong			;
        JC	AUD_CIRelse			;

	MOV	DPTR,#aud_first			; if (first>last) ok
        CALL	MTH_LoadOp1Long			;
        MOV	DPTr,#aud_last			;
	CALL	MTH_LoadOp2Long			;
        CALL	MTH_TestGTLong			;
        JC	AUD_CIRok			;

        MOV	DPTR,#aud_last			; if (last>=ptr) ok
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_ptr			;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_CompareLongs		;
        JNZ	AUD_CIRok			;
        CALL	MTH_TestGTLong			;
        JC	AUD_CIRok			;

        JMP	AUD_CIRfail			; fail

AUD_CIRelse:
	MOV	DPTR,#aud_last			; if (last>first) fail
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_first			;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_TestGTLong			;
        JC	AUD_CIRfail			;

        MOV	DPTR,#aud_ptr			; if (ptr>=last) fail
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_last			;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_CompareLongs		;
        JNZ	AUD_CIRfail			;
        CALL	MTH_TestGTLong			;
        JC	AUD_CIRfail			;
AUD_CIRok:
	MOV	A,#1				; ok
	RET
AUD_CIRfail:
	CLR	A				; fail
        RET

;******************************************************************************
;
; Function:	AUD_InSet
; Input:	B=auditcode
;               DPTR=ptr to auditcode set
; Output:	C=1=code is in the set, C=0=code is not in the set
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_InSet: ; B=byte, DPTR=set
	CLR	A
	MOVC	A,@A+DPTR
	JZ	AUD_ISfail
	INC	DPTR
	CJNE	A,B,AUD_InSet
	SETB	C
	RET
AUD_ISfail:
	CLR	C
	RET

;******************************************************************************
;
; Function:	AUD_SearchSet
; Input:	DPTR=ptr to auditcode set
;               R3=direction to search (0=next, 1=prev)
; Output:	C=1=ok, found auditcode in the set
;               C=0=hit end of memory
; Preserved:	?
; Destroyed:	?
; Description:
;   Traverses audit memory looking for any audit code in the defined set.
;   Returns C=1 and aud_ptr, aud_code looking at the audit record in question
;   or returns C=0 if we ran off the end of memory.
;
;******************************************************************************

AUD_SearchSet:
	PUSHDPH
	PUSHDPL
	MOV	A,R3
	JZ	AUD_SSdown

	MOV	DPTR,#aud_ptr
	CALL	AUD_PrevEntry
	JZ	AUD_SSfail
	JMP	AUD_SSgetcode
AUD_SSdown:
	MOV	DPTR,#aud_ptr
	CALL	AUD_NextEntry
	JZ	AUD_SSfail
AUD_SSgetcode:
	MOV	DPTR,#aud_ptr
	CALL	AUD_AuditEntryAddr
	MOVX	A,@DPTR
	MOV	DPTR,#aud_code
	MOVX	@DPTR,A

	POP	DPL
	POP	DPH
	MOV	B,A
	PUSHDPH
	PUSHDPL
	CALL	AUD_InSet
	POP	DPL
	POP	DPH
	JNC	AUD_SearchSet
	SETB	C
	RET
AUD_SSfail:
	POP	DPL
	POP	DPH
	CLR	C
	RET

;******************************************************************************
;
; Function:	AUD_SkipSet
; Input:	DPTR=ptr to auditcode set
;               R3=direction to search (0=next, 1=prev)
; Output:	C=1=ok, skipped all codes in set
;               C=0=end of memory
; Preserved:	?
; Destroyed:	?
; Description:
;   Traverses audit memory skipping all audit codes which are in the defined
;   set. It returns with C=1 and aud_ptr and aud_code looking at the first
;   audit code which was not in the set, or C=0 if it runs off the end of the
;   audit memory.
;
;******************************************************************************

AUD_SkipSet:
	PUSHDPH
        PUSHDPL
	JMP	AUD_SkSgetcode
AUD_SkSloop:
	PUSHDPH
	PUSHDPL
	MOV	A,R3
	JZ	AUD_SkSdown

	MOV	DPTR,#aud_ptr
	CALL	AUD_PrevEntry
	JZ	AUD_SkSfail
	JMP	AUD_SkSgetcode
AUD_SkSdown:
	MOV	DPTR,#aud_ptr
	CALL	AUD_NextEntry
	JZ	AUD_SkSfail
AUD_SkSgetcode:
	MOV	DPTR,#aud_ptr
	CALL	AUD_AuditEntryAddr
	MOVX	A,@DPTR
	MOV	DPTR,#aud_code
	MOVX	@DPTR,A

	POP	DPL
	POP	DPH
	MOV	B,A
	PUSHDPH
	PUSHDPL
	CALL	AUD_InSet
	POP	DPL
	POP	DPH
	JC	AUD_SkSloop
	SETB	C
	RET
AUD_SkSfail:
	POP	DPL
	POP	DPH
	CLR	C
	RET

;******************************************************************************
;
; Function:	AUD_FindTransaction
; Input:	R6=direction (0=Next, 1=Prev)
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Starting from the audit record pointer to by aud_ptr, find the previous or
;   next transaction head/tail pointers. Returns TRX_OK if successful, TRX_END
;   if we run off the end of memory (or past a shift start in Prev mode) or
;   TRX_ERROR if there was an error detected. In error conditions, aud_ptr
;   points to the error and FindTransaction may be called again in the same
;   direction to skip the transaction with the error to find another one.
;
;******************************************************************************

AUD_FindTransaction:
	MOV	A,R6
        JZ	AUD_FTdown

        MOV	DPTR,#set_10_40_51_52_54_55	;
	MOV	R3,#AUD_UP			;
        CALL	AUD_SearchSet			;
        JNC	AUD_FTend			;
        JMP	AUD_FTsettail			;

AUD_FTdown:					;
	MOV	DPTR,#set_40_51_54		;
	MOV	R3,#AUD_DOWN			;
        CALL	AUD_SearchSet			;
        JNC	AUD_FTend			;
        MOV	DPTR,#aud_code			;
        MOVX	A,@DPTR				;
        CJNE	A,#40,AUD_FTcheck_52_55		;
        JMP	AUD_FTsettail			;
AUD_FTcheck_52_55:				;
	MOV	DPTR,#aud_ptr			;
        CALL	AUD_NextEntry			;
        MOV	DPTR,#set_52_55			;
        MOV	R3,#AUD_DOWN			;
        CALL	AUD_SkipSet			;
        JNC	AUD_FTend			;
        MOV	DPTR,#aud_ptr			;
        CALL	AUD_PrevEntry			;
        MOV	DPTR,#aud_ptr			;
        CALL	AUD_AuditEntryAddr		;
        MOVX	A,@DPTR				;
        MOV	DPTR,#aud_code			;
        MOVX	@DPTR,A				;

AUD_FTsettail:
	MOV	DPTR,#aud_code
        MOVX	A,@DPTR
        CJNE	A,#10,AUD_FTinshift
	JMP	AUD_FTend
AUD_FTinshift:
	MOV	DPTR,#aud_ptr			;
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_transactiont		;
        CALL	MTH_StoreLong			;

	MOV	DPTR,#aud_code			;
        MOVX	A,@DPTR				;
        CJNE	A,#40,AUD_FTnot40		;
        JMP	AUD_FTcase40			;
AUD_FTnot40:					;
	CJNE	A,#51,AUD_FTnot51		;
        JMP	AUD_FTcase51_54			;
AUD_FTnot51:					;
	CJNE	A,#54,AUD_FTnot54		;
        JMP	AUD_FTcase51_54			;
AUD_FTnot54:					;
	CJNE	A,#52,AUD_FTnot52		;
        JMP	AUD_FTcase52_55			;
AUD_FTnot52:					;
	CJNE	A,#55,AUD_FTnot55		;
	JMP	AUD_FTcase52_55			;
AUD_FTnot55:
AUD_FTerror:
	MOV	A,#AUD_ERROR			;
	RET
AUD_FTend:
	MOV	A,#AUD_END
        RET
AUD_FTok:
	MOV	A,#AUD_OK
	RET

AUD_FTcase40:
	MOV	DPTR,#aud_ptr
        CALL	AUD_PrevEntry
        MOV	DPTR,#set_50_52_53_55
        MOV	R3,#AUD_UP
        CALL	AUD_SkipSet
        JNC	AUD_FTend
        MOV	DPTR,#aud_ptr
        CALL	AUD_NextEntry
        MOV	DPTR,#set_52_55
	MOV	R3,#AUD_DOWN
        CALL	AUD_SkipSet
        MOV	DPTR,#aud_code
        MOVX	A,@DPTR
        MOV	B,A
        MOV	DPTR,#set_50_53
        CALL	AUD_InSet
        JNC	AUD_FTerror
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactionh
        CALL	MTH_StoreLong
        JMP	AUD_FTok

AUD_FTcase51_54:
	MOV	DPTR,#aud_transactiont
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactionh
        CALL	MTH_StoreLong
        JMP	AUD_FTok

AUD_FTcase52_55:
	MOV	DPTR,#set_52_55
        MOV	R3,#AUD_UP
        CALL	AUD_SkipSet
        JNC	AUD_FTend
        MOV	DPTR,#aud_code
        MOVX    A,@DPTR
        MOV	B,A
        MOV	DPTR,#set_51_54
        CALL	AUD_InSet
        JNC	AUD_FTerror
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactionh
        CALL	MTH_StoreLong
        JMP	AUD_FTok

;******************************************************************************
;
; Function:	AUD_FindLastTicket
; Input:	None
; Output:	A=AUD_OK or AUD_ERROR
; Preserved:	?
; Destroyed:	?
; Description:
;   Using the current transaction head/tail pointers, find the last ticket in
;   that transaction.
;
;******************************************************************************

AUD_FindLastTicket:
	MOV	DPTR,#aud_transactiont
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ptr
	CALL	MTH_StoreLong
        MOV	DPTR,#aud_ptr
        CALL	AUD_AuditEntryAddr
        MOVX	A,@DPTR
        CJNE	A,#40,AUD_FLTsingletkt

AUD_FLTmultitkt:
	MOV	DPTR,#aud_ptr
        CALL	AUD_PrevEntry
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_tickett
        CALL	MTH_StoreLong
        MOV	DPTR,#set_52_55
        MOV	R3,#AUD_UP
        CALL	AUD_SkipSet
        MOV	DPTR,#aud_code
        MOVX	A,@DPTR
        MOV	B,A
        MOV	DPTR,#set_50_53
        CALL	AUD_InSet
        JC	AUD_FLTsethead
        MOV	A,#AUD_ERROR
        RET
AUD_FLTsethead:
	MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ticketh
        CALL	MTH_StoreLong
        MOV	A,#AUD_OK
	RET

AUD_FLTsingletkt:
	MOV	DPTR,#aud_transactionh
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ticketh
        CALL	MTH_StoreLong
	MOV	DPTR,#aud_transactiont
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_tickett
        CALL	MTH_StoreLong
        MOV	A,#AUD_OK
        RET

;******************************************************************************
;
; Function:	AUD_FindPrevTicket
; Input:	None
; Output:	A=AUD_OK or AUD_ERROR or AUD_END
; Preserved:	?
; Destroyed:	?
; Description:
;   Using the current transaction/ticket head/tail pointers, find the previous
;   ticket to the one we are currently pointing at.
;
;******************************************************************************

AUD_FindPrevTicket:
	MOV	DPTR,#aud_ticketh
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactionh
        CALL	MTH_LoadOp2Long
        CALL	MTH_CompareLongs
        JNZ	AUD_FPTatfirst

        MOV	DPTR,#aud_ptr
	CALL	MTH_StoreLong
        JMP	AUD_FLTmultitkt

AUD_FPTatfirst:
	MOV	A,#AUD_END
	RET

;******************************************************************************
;
; Function:	AUD_FindNextTicket
; Input:	None
; Output:	A=AUD_OK, AUD_END or AUD_ERROR
; Preserved:	?
; Destroyed:	?
; Description:
;   Using the current transaction/ticket head/tail pointers, find the next
;   ticket to the one we are currently pointing at.
;
;******************************************************************************

AUD_FindNextTicket:
	MOV	DPTR,#aud_transactiont		; if tickett == transactiont
        CALL	MTH_LoadOp1Long			; or tickett == transactiont-1
        MOV	DPTR,#aud_tickett		; then already at last ticket
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_CompareLongs		;
        JNZ	AUD_FNTatlast			;
        MOV	A,#1				;
        CALL	MTH_LoadOp2Acc			;
        CALL	MTH_SubLongs			;
        MOV	DPTR,#aud_tickett		;
        CALL	MTH_LoadOp2Long			;
        CALL	MTH_CompareLongs		;
	JNZ	AUD_FNTatlast			;

        MOV	DPTR,#aud_tickett		; aud_ptr = tickett
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_ptr			;
        CALL	MTH_StoreLong			;
        MOV	DPTR,#aud_ptr			; NextEntry (aud_ptr)
        CALL	AUD_NextEntry			;
        MOV	DPTR,#aud_ptr			; ticketh = aud_ptr
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_ticketh		;
        CALL	MTH_StoreLong			;

        MOV	DPTR,#aud_ptr			; if current audit code not
	CALL	AUD_AuditEntryAddr		; a 50 or 53, then error
        MOVX	A,@DPTR				;
        MOV	B,A				;
	MOV	DPTR,#set_50_53			;
        CALL	AUD_InSet			;
        JNC	AUD_FNTerror			;

        MOV	DPTR,#aud_ptr			; NextEntry (aud_ptr)
        CALL	AUD_NextEntry			;
        MOV	DPTR,#set_52_55			; skip any 52's or 55's
        MOV	R3,#AUD_DOWN			;
        CALL	AUD_SkipSet			;
        MOV	DPTR,#aud_code			; if current audit code not
        MOVX	A,@DPTR				; a 40, 50 or 53, then error
        MOV	B,A				;
        MOV	DPTR,#set_40_50_53		;
        CALL	AUD_InSet			;
        JNC	AUD_FNTerror			;
        MOV	DPTR,#aud_ptr			; PrevEntry (aud_ptr)
	CALL	AUD_PrevEntry			;
        MOV	DPTR,#aud_ptr			; tickett = aud_ptr
        CALL	MTH_LoadOp1Long			;
        MOV	DPTR,#aud_tickett		;
        CALL	MTH_StoreLong			;
        MOV	A,#AUD_OK			; return OK
        RET

AUD_FNTerror:
	MOV	A,#AUD_ERROR
        RET

AUD_FNTatlast:
	MOV	A,#AUD_END
	RET

;******************************************************************************
;
; Function:	AUD_FetchTransactionDetails
; Input:	aud_transactionh and aud_transactiont pointing to transaction
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_FetchTransactionDetails:
	CLR	A
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#aud_trxtotal
	CALL	MTH_StoreLong
	MOV	DPTR,#aud_trxtotal40
	CALL	MTH_StoreLong
	MOV	DPTR,#aud_trxnegative
	MOVX	@DPTR,A
	MOV	DPTR,#aud_lastdiscount
	MOVX	@DPTR,A

	MOV	DPTR,#aud_transactionh		; ptr = transactionh
	CALL	MTH_LoadOp1Long			;
	MOV	DPTR,#aud_ptr			;
	CALL	MTH_StoreLong			;

AUD_FTrDloop:
	MOV	DPTR,#aud_ptr			; get audit code at aud_ptr
	CALL	AUD_AuditEntryAddr		;
	MOVX	A,@DPTR				;
	CJNE	A,#40,AUD_FTrDnot40
;**********************
; Code 40 - Transaction
;**********************
	MOV	A,#4				; grab the transaction total
	CALL	AddAtoDPTR			; from the code 40
	CALL	MTH_LoadOp1Long			;
	MOV	DPTR,#aud_trxtotal40		;
	CALL	MTH_StoreLong			;
	JMP	AUD_FTrDnext

AUD_FTrDnot40:
	CJNE	A,#50,AUD_FTrDnot50
	JMP	AUD_FTrDdo50_51_53_54
AUD_FTrDnot50:
	CJNE	A,#51,AUD_FTrDnot51
	JMP	AUD_FTrDdo50_51_53_54
AUD_FTrDnot51:
	CJNE	A,#53,AUD_FTrDnot53
	JMP	AUD_FTrDdo50_51_53_54
AUD_FTrDnot53:
	CJNE	A,#54,AUD_FTrDnot54
	JMP	AUD_FTrDdo50_51_53_54
AUD_FTrDnot54:
	JMP	AUD_FTrDnext


AUD_FTrDdo50_51_53_54:
;********************************
; Codes 50,51,53,54 - Ticket Info
;********************************

	MOV	DPTR,#aud_ptr
	CALL	AUD_NextEntry
	MOV	DPTR,#aud_ptr			; get audit code at aud_ptr
	CALL	AUD_AuditEntryAddr		;
	MOVX	A,@DPTR				;

	CJNE	A,#52,AUD_FTrDnot52
	INC	DPTR
	INC	DPTR
	INC	DPTR
	MOVX	A,@DPTR
	MOV     DPTR,#aud_lastdiscount
	MOVX	@DPTR,A
AUD_FTrDnot52:

	MOV	DPTR,#aud_ptr
	CALL	AUD_PrevEntry
	MOV	DPTR,#aud_ptr			; get audit code at aud_ptr
	CALL	AUD_AuditEntryAddr		;

	;MOV	A,#9
	;CALL	AddAtoDPTR
	;CALL	MTH_LoadOp2Long			; add the ticket total
	;MOV	DPTR,#aud_trxtotal
	;CALL	MTH_LoadOp1Long
	;CALL	MTH_AddLongs
	;MOV	DPTR,#aud_trxtotal		;
	;CALL	MTH_StoreLong			; from audit code 50,51,53,54

	MOV	A,#9
	CALL	AddAtoDPTR
	CALL    MTH_LoadOp1Long                 ;
	MOV	DPTR,#aud_trxtotal		;
	CALL	MTH_LoadOp2Long			;

	MOV	DPTR,#aud_lastdiscount
	MOVX	A,@DPTR
	JNZ     AUD_FTrDhandlediscount

	MOV	DPTR,#aud_trxnegative
	MOVX	A,@DPTR
	JNZ	AUD_FTrDhandlenegative

AUD_FTrDhandlediscountnegative:
	CALL	MTH_AddLongs			;
	JMP	AUD_FTrDstorevalue		;

AUD_FTrDhandlenegative:
	CALL	MTH_SwapOp1Op2
	CALL	MTH_TestGTLong
	JNC	AUD_FTrDsubgoingpositive
	CALL	MTH_SubLongs
	JMP	AUD_FTrDstorevalue

AUD_FTrDsubgoingpositive:
	CLR	A
	MOV	DPTR,#aud_trxnegative
	MOVX	@DPTR,A

	CALL	MTH_SwapOp1Op2
	CALL	MTH_SubLongs
	JMP	AUD_FTrDstorevalue		;

AUD_FTrDhandlediscount:
	MOV	DPTR,#aud_trxnegative
	MOVX	A,@DPTR
	JNZ	AUD_FTrDhandlediscountnegative

	CALL	MTH_TestGTLong
	JC	AUD_FTrDsubgoingnegative
	CALL	MTH_SwapOp1Op2
	CALL	MTH_SubLongs
	JMP	AUD_FTrDstorevalue		;

AUD_FTrDsubgoingnegative:
	MOV	A,#1
	MOV	DPTR,#aud_trxnegative
	MOVX	@DPTR,A

	CALL	MTH_SubLongs
	;JMP	AUD_FTrDstorevalue		;

AUD_FTrDstorevalue:				;
	MOV	DPTR,#aud_trxtotal		;
	CALL	MTH_StoreLong			;

	CLR	A				;reset the negative flag
	MOV	DPTR,#aud_lastdiscount
	MOVX	@DPTR,A


AUD_FTrDnext:
	MOV	DPTR,#aud_ptr
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#aud_transactiont
	CALL	MTH_LoadOp2Long
	CALL	MTH_CompareLongs
	JNZ	AUD_FTrDdone
	MOV	DPTR,#aud_ptr
	CALL	AUD_NextEntry
	JMP	AUD_FTrDloop

AUD_FTrDdone:
	RET

;******************************************************************************
;
; Function:	AUD_FetchTicketDetails
; Input:	aud_ticketh and and_tickett pointing to ticket required
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_FetchTicketDetails:
	CLR	A
	CALL	MTH_LoadOp1Acc
	MOV	DPTR,#aud_ticketnum
	CALL	MTH_StoreLong
	MOV	DPTR,#aud_slaveticketnum
	CALL	MTH_StoreLong
	MOV	DPTR,#aud_tickettype
	CALL	MTH_StoreByte
	MOV	DPTR,#aud_tkttotal
	CALL	MTH_StoreLong
	MOV	DPTR,#aud_discount
	CALL	MTH_StoreByte
	MOV	DPTR,#aud_macrotkt
	CALL	MTH_StoreByte
	MOV	DPTR,#aud_disctrans
	CALL	MTH_StoreByte
	MOV	DPTR,#aud_tkttime
	CALL	MTH_StoreWord
	MOV     A,#1
	CALL    MTH_LoadOp1Acc
	MOV	DPTR,#aud_groupqty
	CALL	MTH_StoreWord

	MOV	DPTR,#aud_ticketh
	CALL	MTH_LoadOp1Long
	MOV	DPTR,#aud_ptr
	CALL	MTH_StoreLong

AUD_FTDloop:
	MOV	DPTR,#aud_ptr
	CALL	AUD_AuditEntryAddr
	MOVX	A,@DPTR
	CJNE	A,#52,AUD_FTDnot52ext
	JMP	AUD_FTDis52
AUD_FTDnot52ext:
	JMP	AUD_FTDnot52
;*******************************
; Code 52 - Ticket Extended Info
;*******************************
AUD_FTDis52:
	INC	DPTR				; grab the group quantity
	PUSHDPH
	PUSHDPL
	CALL	MTH_LoadOp1Word			; from the code 52
	MOV	DPTR,#aud_groupqty		;
	CALL	MTH_StoreWord			;
	POP	DPL
	POP	DPH
	INC	DPTR
	INC	DPTR
	PUSHDPH
	PUSHDPL
	MOVX	A, @DPTR   		; grab discount flag
	MOV	DPTR,#aud_discount
	MOVX	@DPTR, A
	POP	DPL
	POP	DPH
	INC	DPTR
	PUSHDPH
	PUSHDPL
	MOVX	A, @DPTR   		; grab macro flag
	MOV	DPTR,#aud_macrotkt
	MOVX	@DPTR, A
	POP	DPL
	POP	DPH
	INC	DPTR
	PUSHDPH
	PUSHDPL
	MOVX	A, @DPTR   		; grab discounted transaction flag
	MOV	DPTR,#aud_disctrans
	MOVX	@DPTR, A
	POP	DPL
	POP	DPH
	JMP	AUD_FTDnext
AUD_FTDnot52:
	CJNE	A,#55,AUD_FTDnot55
;***************************
; Code 55 - SlaveBander Info
;***************************
	INC	DPTR				; grab the slave ticket number
	CALL	MTH_LoadOp1Word			; from the code 55
	MOV	DPTR,#aud_slaveticketnum	;
	CALL	MTH_StoreWord			;
	JMP	AUD_FTDnext
AUD_FTDnot55:
	CJNE	A,#50,AUD_FTDnot50
	JMP	AUD_FTDdo50_51_53_54
AUD_FTDnot50:
	CJNE	A,#51,AUD_FTDnot51
	JMP	AUD_FTDdo50_51_53_54
AUD_FTDnot51:
	CJNE	A,#53,AUD_FTDnot53
	JMP	AUD_FTDdo50_51_53_54
AUD_FTDnot53:
	CJNE	A,#54,AUD_FTDnot54
        JMP	AUD_FTDdo50_51_53_54
AUD_FTDnot54:
	JMP	AUD_FTDnext
AUD_FTDdo50_51_53_54:
;********************************
; Codes 50,51,53,54 - Ticket Info
;********************************
	INC	DPTR				;
        PUSHDPH					;
        PUSHDPL					;
        CALL	MTH_LoadOp1Word			; grab the ticket time
        MOV	DPTR,#aud_tkttime		; (and void status)
        CALL	MTH_StoreWord			;
        POP	DPL				;
        POP	DPH				;
        INC	DPTR				;
        INC	DPTR				;
        PUSHDPH					;
        PUSHDPL					;
        MOVX	A,@DPTR				; grab the ticket type
        MOV	DPTR,#aud_tickettype		;
        MOVX	@DPTR,A				;
        POP	DPL				;
        POP	DPH				;
        INC	DPTR				;
        CALL	MTH_LoadOp1Long			;
        PUSHDPH					;
        PUSHDPL					;
	MOV	DPTR,#aud_ticketnum		; the ticket number
        CALL	MTH_StoreLong			;
        POP	DPL				;
        POP	DPH				;
        INC	DPTR				;
        CALL	MTH_LoadOp1Long			; and the ticket total
        MOV	DPTR,#aud_tkttotal		;
	CALL	MTH_StoreLong			; from audit code 50,51,53,54
AUD_FTDnext:
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_tickett
        CALL	MTH_LoadOp2Long
        CALL	MTH_CompareLongs
        JNZ	AUD_FTDdone
        MOV	DPTR,#aud_ptr
        CALL	AUD_NextEntry
        JMP	AUD_FTDloop
AUD_FTDdone:
	RET

;******************************************************************************
;
; Function:	AUD_AddEntry
; Input:	DPTR0=address of relevant aud_entry
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_AddEntry:
	CLR	A			; store audit code in the first
	MOVC	A,@A+DPTR		; byte of the audit buffer
	INC	DPTR			;
	MOV	DPSEL,#1		;
	MOV	DPTR,#aud_buf		;
	MOVX	@DPTR,A			;
	INC	DPTR			;

	MOV	DPSEL,#0		; set up the loop counter R5
	CLR	A			; with the number of fields
	MOVC	A,@A+DPTR		; to transfer
	INC	DPTR			;
	MOV	R5,A			;

AUD_AEloop:
	CLR	A			; read the field length
	MOVC	A,@A+DPTR		;
	INC	DPTR			;
	MOV	R7,A			;

	CLR	A			; read the field address
	MOVC	A,@A+DPTR		; (LOW) -> B
	INC	DPTR			;
	MOV	B,A			;
	CLR	A			;
	MOVC	A,@A+DPTR		; (HIGH) -> A
	INC	DPTR			;

	MOV	DPSEL,#1		; do the transfer
	CALL	MEM_SetDest		;
	MOV	DPL,B			; Do the transfer
	MOV	DPH,A			;
	CALL	MEM_SetSource		;
	CALL	MEM_CopyXRAMtoXRAMsmall	;
	MOV	DPSEL,#0		;

	DJNZ	R5,AUD_AEloop		; repeat for all fields

	MOV	DPTR,#aud_last		; insert current audit entry
	CALL	AUD_AuditEntryAddr	; at the end of the audit roll
	CALL	MEM_SetDest		;
	MOV	DPTR,#aud_buf		;
	CALL	MEM_SetSource		;
	MOV	R7,#AUDIT_ENTRY_SIZE	;
	CALL	MEM_CopyXRAMtoXRAMsmall	;

	MOV	DPTR,#aud_last		; update end of audit roll to point
	CALL	AUD_NextEntry		; to next entry

	MOV	DPTR,#aud_first		; check if end has overlapped
	CALL	MTH_LoadOp1Long		; the start, if so, increment
	MOV	DPTR,#aud_last		; the start
	CALL	MTH_LoadOp2Long		;
	CALL	MTH_CompareLongs	;
	JZ	AUD_AEnoovflw		;
	MOV	DPTR,#aud_first		;
	CALL	AUD_NextEntry		;
AUD_AEnoovflw:
	RET

;******************************************************************************
;
; Function:	AUD_CalcMemoryUsed
; Input:	None
; Output:	A=% of total audit memory in use
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_CalcMemoryUsed:
	MOV	DPTR,#aud_last		;
        CALL	MTH_LoadOp1Long		;
        MOV	DPTR,#aud_first		;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_CompareLongs	;
        JNZ	AUD_CMUorderok		;
        CALL	MTH_TestGTLong		;
        JC	AUD_CMUorderok		;

        MOV	DPTR,#aud_total_entries	; used=(total+last-first)*100/total
        MOV	R0,#mth_operand1	;
        CALL	MTH_LoadConstLong	;
        JMP	AUD_CMUtherest		;

AUD_CMUorderok:
        CLR	A			; used=(last-first)*100/total
        CALL	MTH_LoadOp1Acc

AUD_CMUtherest:
	MOV	DPTR,#aud_last		;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_AddLongs		;
        MOV	DPTR,#aud_first		;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_SubLongs		;
        MOV	A,#100			;
        CALL	MTH_LoadOp2Acc		;
        CALL	MTH_Multiply32by16	;
        MOV	DPTR,#aud_total_entries	;
        MOV	R0,#mth_operand2	;
        CALL	MTH_LoadConstLong	;
        CALL	MTH_Divide32by16	;
	MOV	A,mth_op1ll		;
	RET

;******************************************************************************
;
; Function:	AUD_CalcMemoryToBeUploaded
; Input:	None
; Output:	A=% of total audit memory which is still to be uploaded
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_CalcMemoryToBeUploaded:
	MOV	DPTR,#aud_last		;
        CALL	MTH_LoadOp1Long		;
        MOV	DPTR,#aud_uploadfrom	;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_CompareLongs	;
        JNZ	AUD_CMTBUorderok	;
        CALL	MTH_TestGTLong		;
        JC	AUD_CMTBUorderok	;

        MOV	DPTR,#aud_total_entries	; used=(total+last-upload)*100/total
        MOV	R0,#mth_operand1	;
        CALL	MTH_LoadConstLong	;
        JMP	AUD_CMTBUtherest	;

AUD_CMTBUorderok:
        CLR	A			; used=(last-upload)*100/total
        CALL	MTH_LoadOp1Acc

AUD_CMTBUtherest:
	MOV	DPTR,#aud_last		;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_AddLongs		;
        MOV	DPTR,#aud_uploadfrom	;
        CALL	MTH_LoadOp2Long		;
        CALL	MTH_SubLongs		;
        MOV	A,#100			;
        CALL	MTH_LoadOp2Acc		;
        CALL	MTH_Multiply32by16	;
        MOV	DPTR,#aud_total_entries	;
	MOV	R0,#mth_operand2	;
	CALL	MTH_LoadConstLong	;
	CALL	MTH_Divide32by16	;
	MOV	A,mth_op1ll		;
	RET

;****************************** End Of AUDIT.ASM ******************************  