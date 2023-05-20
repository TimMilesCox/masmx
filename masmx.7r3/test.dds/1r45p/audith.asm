;******************************************************************************
;
; File     : AUDITH.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the high level audit handling routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;******************************************************************************

aud_searchfor:	VAR 4

;******************************************************************************
;
;               H i g h   L e v e l   A u d i t   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	AUD_ScanUp
; Input:	A=AUD_TKT or A=AUD_TRX
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_ScanUp:
        CJNE	A,#AUD_TKT,VOI_VTTuptrx
VOI_VTTuptkt:
	CALL	AUD_FindPrevTicket
        CJNE	A,#AUD_ERROR,VOI_VTTuptktok
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ticketh
        CALL	MTH_StoreLong
        JMP	VOI_VTTuptkt
VOI_VTTuptktok:
	CJNE	A,#AUD_END,VOI_VTTupcomplete
VOI_VTTuptrx:
	MOV	DPTR,#aud_transactionh
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ptr
        CALL	MTH_StoreLong
        MOV	R6,#AUD_UP
        CALL	AUD_FindTransaction
        CJNE	A,#AUD_ERROR,VOI_VTTuptrxok
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactionh
        CALL	MTH_StoreLong
        JMP	VOI_VTTuptrx
VOI_VTTuptrxok:
	CJNE	A,#AUD_OK,VOI_VTTupcompletebeep
        CALL	AUD_FindLastTicket
        JMP	VOI_VTTupcomplete
VOI_VTTupcompletebeep:

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

        CALL    KBD_FlushKeyboard
	MOV	A,#AUD_ERROR
        RET
VOI_VTTupcomplete:
	MOV	A,#AUD_OK
        RET

;******************************************************************************
;
; Function:	AUD_ScanDown
; Input:	A=AUD_TKT or A=AUD_TRX
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

AUD_ScanDown:
        CJNE	A,#AUD_TKT,VOI_VTTdowntrx
VOI_VTTdowntkt:
	CALL	AUD_FindNextTicket
        CJNE	A,#AUD_ERROR,VOI_VTTdowntktok
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_tickett
        CALL	MTH_StoreLong
        JMP	VOI_VTTdowntkt
VOI_VTTdowntktok:
	CJNE	A,#AUD_END,VOI_VTTdowncomplete
VOI_VTTdowntrx:
	MOV	DPTR,#aud_transactiont
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ptr
        CALL	MTH_StoreLong
        MOV	R6,#AUD_DOWN
        CALL	AUD_FindTransaction
        CJNE	A,#AUD_ERROR,VOI_VTTdowntrxok
        MOV	DPTR,#aud_ptr
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_transactiont
        CALL	MTH_StoreLong
        JMP	VOI_VTTdowntrx
VOI_VTTdowntrxok:
	CJNE	A,#AUD_OK,VOI_VTTdowncompletebeep
        CALL	AUD_FindLastTicket
        CJNE	A,#AUD_OK,VOI_VTTdowncompletebeep
VOI_VTTdowngetfirst:
	CALL	AUD_FindPrevTicket
        CJNE	A,#AUD_OK,VOI_VTTdowncomplete
        JMP	VOI_VTTdowngetfirst
VOI_VTTdowncompletebeep:

        IF      SPEAKER
	CALL	SND_Warning
        END

        CALL    KBD_FlushKeyboard
        MOV	A,#AUD_ERROR
        RET
VOI_VTTdowncomplete:
	MOV	A,#AUD_OK
        RET

;******************************************************************************
;
; Function:	AUD_StartTktTrxSelection
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;
;******************************************************************************

AUD_StartTktTrxSelection:
	MOV	DPTR,#aud_last
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_ptr
        CALL	MTH_StoreLong
        MOV	R6,#AUD_UP
        CALL	AUD_FindTransaction
	CJNE	A,#AUD_OK,AUD_STTSnoentries
        CALL	AUD_FindLastTicket
        CJNE	A,#AUD_OK,AUD_STTSnoentries
        MOV	A,#AUD_OK
        RET
AUD_STTSnoentries:
	MOV	A,#AUD_NONE
        RET

;******************************************************************************
;
; Function:	AUD_TktTrxSelect
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

voi_msg_searching:	DB 12,'Searching...'
voi_msg_enternumber:	DB 14,'Enter Number: '
voi_msg_notfound:	DB 16,'Ticket Not Found'

AUD_Searching:
	CALL	LCD_Clear2
	MOV	A,#64
        CALL	LCD_GotoXY
	MOV	DPTR,#voi_msg_searching
        CALL    LCD_DisplayStringCODE
	RET

AUD_TktTrxSelect:
        CALL	KBD_WaitKey
        CJNE	A,#KBD_CANCEL,VOI_VTTnotcancel
;*******
; CANCEL
;*******
        MOV	A,#AUD_ABORT
	RET
VOI_VTTnotcancel:
	CJNE	A,#KBD_OK,VOI_VTTnotok
;***
; OK
;***
	MOV	A,#AUD_OK
	RET
VOI_VTTnotok:
	PUSHACC
        CALL	AUD_Searching
        POP	ACC
	CJNE	A,#KBD_DOWN,VOI_VTTnotdown
;*****
; DOWN
;*****
	MOV	DPTR,#aud_scanctrl
        MOVX	A,@DPTR
	CALL	AUD_ScanDown
	MOV	A,#AUD_REPEAT
        RET
VOI_VTTnotdown:
	CJNE	A,#KBD_UP,VOI_VTTnotup
;***
; UP
;***
	MOV	DPTR,#aud_scanctrl
        MOVX	A,@DPTR
        CALL	AUD_ScanUp
	MOV	A,#AUD_REPEAT
        RET
VOI_VTTnotup:
	CJNE	A,#10,VOI_VTTnot0		; work out if its
	JMP	VOI_VTTdigit			; number key
VOI_VTTnot0:					;
	JC	VOI_VTTdigit			;
        MOV	A,#AUD_REPEAT
        RET
VOI_VTTdigit:
	PUSHACC
	CALL	KBD_FlushKeyboard
        POP	ACC
	CALL	KBD_ForceKey
	CALL	LCD_Clear2
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#voi_msg_enternumber
        CALL	LCD_DisplayStringCODE
        MOV	B,#64+14
        MOV	R7,#6
        CALL	NUM_GetNumber
        JNZ	VOI_VTTgotnumber
        CALL	LCD_Clear2
        MOV	A,#AUD_REPEAT
        RET
VOI_VTTgotnumber:
	MOV	DPTR,#aud_searchfor
        CALL	MTH_StoreLong
        CALL	AUD_Searching
        CALL	AUD_StartTktTrxSelection
VOI_VTTsearchloop:
	CALL	AUD_FetchTicketDetails
        MOV	DPTR,#aud_ticketnum
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_searchfor
        CALL	MTH_LoadOp2Long
        CALL	MTH_CompareLongs
        JNZ	VOI_VTTmatch
        MOV	A,#AUD_TKT
        CALL	AUD_ScanUp
        CJNE	A,#AUD_ERROR,VOI_VTTsearchloop
        CALL	LCD_Clear2
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#voi_msg_notfound
        CALL	LCD_DisplayStringCODE
        MOV	R0,#10
        CALL	delay100ms

        IF      SPEAKER
        CALL	SND_Warning
        ENDIF

VOI_VTTmatch:
        MOV	A,#AUD_REPEAT
        RET

;******************************************************************************
;
; Function:	AUD_DisplayAuditEntry
; Input:	DPTR = pointer to audit entry number
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Prints the specified audit entry to the printer.
;
;******************************************************************************

AUD_DisplayAuditEntry:
	PUSHDPH				; set up a blank output
	PUSHDPL				; line to the printer
	MOV	DPTR,#aud_template		;
	CALL	MEM_SetSource			;
	MOV	DPTR,#aud_line			;
	CALL	MEM_SetDest			; ??? there MUST be a better
	MOV	R7,#3*(FIELD_HEADER+32)		; way to do this...
	CALL	MEM_CopyCODEtoXRAMsmall		;
	POP	DPL				;
	POP	DPH				;

	CALL	AUD_AuditEntryAddr		; copy the specified audit
	CALL	MEM_SetSource			; entry into a fixed
	MOV	DPTR,#aud_buf			; work buffer in XRAM
	CALL	MEM_SetDest			;
	MOV	R7,#AUDIT_ENTRY_SIZE		;
	CALL	MEM_CopyXRAMtoXRAMsmall		;

	CALL	AUD_FormatEntry			; generate the ASCII audit line
        JC      AUD_DAEmaskedoff

        MOV     DPTR,#prt_bitmaplen
        MOVX    A,@DPTR
        MOV     R7,A                            ; reduce bitmap size
	RR	A				; according to number
	RR	A				; of lines worth
	RR	A				; formatting
	MOV	B,#FIELD_HEADER+32		;
	MUL	AB				;
	MOV	DPTR,#aud_line			;
	CALL	AddABtoDPTR			;
	CLR	A				;
	MOVX	@DPTR,A				;

	MOV	A,#3
	ADD	A,R7
        CALL    PRT_SetBitmapLenSmall

	CALL	PRT_ClearBitmap			; print the audit entry
	MOV	DPTR,#aud_line			;
	CALL	PRT_FormatBitmap			;
	CALL	PRT_PrintBitmap			;
AUD_DAEmaskedoff:
	RET

;******************************************************************************
;
; Function:	AUD_FormatEntry
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Formats the ASCII representation of an audit record. The record must be
;   stored in aud_buf in binary and will be written to aud_line in ASCII.
;
;******************************************************************************

AUD_FormatEntry:
	MOV	DPSEL,#0			; output the 2 digit audit code
	MOV	DPTR,#aud_buf			;
	MOV	DPSEL,#1			;
	MOV	DPTR,#aud_line+FIELD_HEADER	;
	MOV	R5,#2				;
	CALL	NUM_NewFormatDecimal8		;

        MOV     A,#1
        CALL    PRT_SetBitmapLenSmall
	MOV	DPTR,#aud_buf			; output the remaining fields
	MOVX	A,@DPTR				; according to the format
        CJNE	A,#AUD_MAX_CODE,AUD_FEnotmax	; specification indexed by
AUD_FEle:					; the current audit code
	JMP	AUD_FEok			;
AUD_FEnotmax:					;
        JC	AUD_FEle			;
        CLR     A
AUD_FEok:					;
	MOV	DPSEL,#2			;
	MOV	DPTR,#aud_format_master		;
	RL	A				;
	PUSHACC				;
	MOVC	A,@A+DPTR			;
	MOV	B,A				;
	POP	ACC				;
	INC	A				;
	MOVC	A,@A+DPTR			;
	MOV	DPH,A				;
	MOV	DPL,B				; DPTR2 = aud_format_???

; MOV DPTR,#aud_format_test ; used to print entry numbers in audit roll

        CLR     A
        MOVC	A,@A+DPTR
	INC	DPTR
	MOV	DPSEL,#1			;
        MOV	DPTR,#aud_displayparam
        MOV	B,A
        MOVX	A,@DPTR
        ANL	A,B
        JZ	AUD_Finvisible

        MOV	DPTR,#aud_line			;
        CALL	NUM_MultipleFormat		;
        MOV	DPSEL,#0			;
        CLR     C
	RET
AUD_Finvisible:
	SETB	C
        RET

;******************************************************************************
;
; Function:	AUD_DisplayAuditRoll
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

aud_msg_praudit:	DB 24,'Printing Audit Roll.....'
aud_msg_paused:		DB 255,12,0,0,0,0,12,'** Paused **'
aud_msg_memused:	DB 255,16,0,0,0,0,16,'Audit Used: XXX%'
	IF USE_UPLOAD
aud_msg_tobeuploaded:	DB 255,20,0,0,0,0,20,'To Be Uploaded: XXX%'
	ENDIF

AUD_DisplayAuditRoll:
	MOV	DPTR,#aud_displayparam		; set the display mask
	MOVX	@DPTR,A				;

	MOV	A,#SYS_AREA_AUDITROLL		; diagnostics
        CALL	SYS_SetAreaCode			;

        MOV	A,#MAN_EXT_AUDIT
        CALL	PRT_SetPrintDevice

        IF DT10W
        MOV	A,prt_outputdevice
        JNZ	AUD_DARdeviceok
        JMP	PRT_IllegalDevice
AUD_DARdeviceok:
        ENDIF

	CALL	PRT_StartPrint			; print audit roll title
	MOV	DPTR,#msg_auditroll		;
	CALL	PRT_DisplayMessageCODE		;

        MOV     DPTR,#aud_first			; check if start pointer
        CALL    MTH_LoadOp1Long			; of audit roll has been
        MOV     DPTR,#aud_total_entries		; corrupted (out of audit
        MOV     R0,#mth_operand2		; memory space)
        CALL    MTH_LoadConstLong		;
        CALL    MTH_TestGTLong			;
        JNC     AUD_DARok			;

        MOV     DPTR,#aud_last			; its corrupt, move the
        CALL    MTH_LoadOp1Long			; start pointer to be
        MOV     DPTR,#aud_first			; the furthest valid point
        CALL    MTH_StoreLong			; away from the end pointer
        MOV     DPTR,#aud_first			;
        CALL    MTH_IncLong			;
        MOV     DPTR,#msg_auditcorrupt		; tell him the pointer
        CALL    PRT_DisplayMessageCODE		; was corrupt

AUD_DARok:
	MOV	DPTR,#aud_msg_memused
        CALL	MEM_SetSource
        MOV	DPTr,#buffer
        CALL	MEM_SetDest
        MOV	R7,#23
        CALL	MEM_CopyCODEtoXRAMsmall
        CALL	AUD_CalcMemoryUsed
        MOV	DPSEL,#1
        MOV	DPTR,#buffer+19
        MOV	B,A
        MOV	R5,#3
        MOV	R6,#0
        CALL	NUM_NewFormatDecimalB
	CALL	PRT_DisplayOneLiner

        IF USE_UPLOAD
	MOV	DPTR,#aud_msg_tobeuploaded
        CALL	MEM_SetSource
        MOV	DPTr,#buffer
        CALL	MEM_SetDest
        MOV	R7,#27
        CALL	MEM_CopyCODEtoXRAMsmall
        CALL	AUD_CalcMemoryToBeUploaded
        MOV	DPSEL,#1
        MOV	DPTR,#buffer+23
        MOV	B,A
        MOV	R5,#3
        MOV	R6,#0
        CALL	NUM_NewFormatDecimalB
	CALL	PRT_DisplayOneLiner
        ENDIF

	MOV	DPTR,#aud_last			; load up our pointer to
	CALL	MTH_LoadOp1Long			; the end of the used
	MOV	DPTR,#aud_ptr			; audit memory
	CALL	MTH_StoreLong			;

AUD_DARagain:
        CALL	LCD_Clear			; tell him we're printing
        MOV	DPTR,#aud_msg_praudit		; the audit memory
        CALL	LCD_DisplayStringCODE		;

AUD_DARloop:
	CALL	KBD_ReadKey			; process keyboard if required
	JNZ	AUD_DARkey			;

        JB	prt_paperout,AUD_DARnopaper	; check for paper out

	MOV	DPTR,#aud_ptr			; check for reaching end
	CALL	MTH_LoadOp1Long			; of used audit memory
	MOV	DPTR,#aud_first			;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_CompareLongs		;
	JNZ	AUD_DARdone			;

	MOV	DPTR,#aud_ptr			; move back to previous
	CALL	AUD_PrevEntry			; entry
	MOV	DPTR,#aud_ptr			;
	CALL	AUD_DisplayAuditEntry		; display it
	JMP	AUD_DARloop			; repeat for all entries

AUD_DARkey:
	CJNE	A,#KBD_CANCEL,AUD_DARpause
AUD_DARdone:
	MOV	A,prt_outputdevice
        JZ	AUD_DARnoabort
	CALL	ERP_Abort
AUD_DARnoabort:
	CALL	PRT_FormFeed
        CALL    CUT_FireCutter
	CALL	PRT_EndPrint
        CLR	A
        CALL	PRT_SetPrintDevice
        MOV	A,#1
	RET
AUD_DARpause:
	IF DT5
         MOV	DPTR,#aud_msg_paused
         CALL	PRT_DisplayMessageCODE
         CALL	PRT_MessageFeed
         CALL	PRT_EndPrint
        ELSE
	 CALL	PRT_EndPrint
	 CALL	LCD_Clear2
	 MOV	A,#64+6
         CALL	LCD_GotoXY
         MOV	DPTR,#aud_msg_paused+6
         CALL	LCD_DisplayStringCODE
        ENDIF
        CALL	KBD_WaitKey
        PUSHACC
        CALL	PRT_StartPrint
        POP	ACC
        CJNE	A,#KBD_CANCEL,AUD_DARagain
        JMP	AUD_DARdone
AUD_DARnopaper:
	IF USE_SERVANT
	 CALL	COM_StopStatusTransmit
	ENDIF
	CALL	PRT_LoadPaper
	IF USE_SERVANT
	 CALL	COM_StartStatusTransmit
	ENDIF
	JC      AUD_DARdone
        JB      prt_paperout,AUD_DARnopaper
        JMP	AUD_DARpause

;******************************************************************************

	IF USE_UPLOAD
aud_msg_needupload1:	DB 24,'90% Audit Limit Exceeded'
aud_msg_needupload2:	DB 24,'Upload Required Urgently'
aud_msg_needupload3:	DB 24,'95% Audit Limit Exceeded'
aud_msg_needupload4:	DB 24,'  Cashup & Upload NOW   '
aud_msg_needupload5:	DB 24,'   Audit Memory Full    '
aud_msg_needupload6:	DB 24,'     Forcing Cashup     '

AUD_CheckAuditWarning:
        CALL	AUD_CalcMemoryToBeUploaded	; see if we are >= 99%
        CJNE	A,#98,AUD_CAWcheckfatal		; memory full
        JMP     AUD_CAWwarningonly		;
AUD_CAWcheckfatal:				;
	JC	AUD_CAWwarningonly		;

        MOV     DPTR,#shf_shiftowner		; if there is a shift
        MOVX    A,@DPTR				; in progress then need
        MOV     B,A				; to force a cashup
        INC     DPTR				;
        MOVX    A,@DPTR				;
        ORL     A,B				;
        JZ      AUD_CAWnotmidshift		;

        CALL	LCD_Clear			; tell user we
        MOV	DPTR,#aud_msg_needupload5	; are forcing him
        CALL	LCD_DisplayStringCODE		; to cashup
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        CALL	LCD_DisplayStringCODE		;

        IF      SPEAKER
        CALL	SND_Warning			;
        CALL	SND_Warning			;
        ENDIF

        CALL	KBD_WaitKey			;
        CALL	WAY_PrintWaybill		; force a cashup...
        CALL	SYS_UnitPowerOff		; ...and powerdown

AUD_CAWnotmidshift:
        RET

AUD_CAWwarningonly:				;
        CJNE	A,#95,AUD_CAWnot95		; see if we need to give
AUD_CAWgivewarning2:				; the 95% warning
	MOV	DPTR,#aud_msg_needupload3	;
        MOV	A,#2				;
        JMP     AUD_CAWgivewarning		;
AUD_CAWnot95:					;
	JNC	AUD_CAWgivewarning2		;

        CJNE    A,#90,AUD_CAWnot90		; see if we need to give
AUD_CAWgivewarning1:				; the 90% warning
	MOV	DPTR,#aud_msg_needupload1	;
        MOV	A,#1				;
        JMP	AUD_CAWgivewarning		;
AUD_CAWnot90:					;
	JNC	AUD_CAWgivewarning1		;
	RET

AUD_CAWgivewarning:
	PUSHDPH
        PUSHDPL
        MOV	DPTR,#aud_warning
        XCH	A,B
        MOVX	A,@DPTR
        ANL	A,B
        JNZ	AUD_CAWhadwarning
        MOVX	A,@DPTR
        ORL	A,B
        MOVX	@DPTR,A
        POP	DPL
        POP	DPH
        CALL	LCD_Clear
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        CALL	LCD_DisplayStringCODE
        CALL	KBD_FlushKeyboard

        IF      SPEAKER
        CALL	SND_Warning
        ENDIF

        CALL	KBD_WaitKey
        CALL    LCD_Clear
        SETB	tim_timerupdate
        RET
AUD_CAWhadwarning:
	POP	DPL
        POP	DPH
        RET

        ENDIF

;******************************************************************************
;
; Function:	AUD_ManagerCleardown
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Asks the user if a manager cleardown is to be executed, and if requested,
;   does a manager cleardown.
;
;******************************************************************************

AUD_ManagerCleardown:
	CALL	LCD_Clear
	MOV	DPTR,#msg_audclear
	CALL	LCD_DisplayStringCODE
	CALL	KBD_OkOrCancel
	JZ	AUD_MCno
	CALL	AUD_ClearAudit
	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	DPTR,#msg_audcleared
	CALL	LCD_DisplayStringCODE

        IF      SPEAKER
	CALL	SND_Warning
        ENDIF

AUD_MCno:
	CALL	LCD_Clear
	SETB	tim_timerupdate
	RET

;******************************************************************************
;
; Function:	AUD_SelectAudit
; Input:	None
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   The main entry point for displaying audit rolls on a DT10. Lets the user
;   select which type of audit roll to display, then calls appropriate routine.
;******************************************************************************

aud_auditmenu:
	DB 5
	DB '====Display Options==='
	DW 0
	DB 'All Entries           '
	DW AUD_FullAudit
	DB 'Shift Entries Only    '
	DW AUD_ShiftAudit
        DB 'System Entries Only   '
        DW AUD_SystemAudit
        DB 'All Non-Ticket Entries'
        DW AUD_NonTicketAudit

AUD_SelectAudit:
	CALL	MNU_NewMenu
AUD_SAagain:
	MOV	DPTR,#aud_auditmenu
	CALL	MNU_LoadMenuCODE
	CALL	MNU_SelectMenuOption
        JNB     ACC.7,AUD_SAagain
	CLR	A
	RET

AUD_FullAudit:
	MOV	A,#AUD_MASK_ALL
        JMP	AUD_DisplayAuditRoll
AUD_ShiftAudit:
	MOV	A,#AUD_MASK_SHIFT
        JMP	AUD_DisplayAuditRoll
AUD_SystemAudit:
	MOV	A,#AUD_MASK_SYSTEM
        JMP     AUD_DisplayAuditRoll
AUD_NonTicketAudit:
	MOV	A,#AUD_MASK_NONTKT
        JMP	AUD_DisplayAuditRoll

;***************************** End Of AUDITH.ASM ******************************
