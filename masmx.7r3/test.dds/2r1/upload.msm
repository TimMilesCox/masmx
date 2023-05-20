;******************************************************************************
;
; File     : UPLOAD.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for upload mode
;
; System   : 80C51
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

	IF USE_UPLOAD

upl_msg_waitupload: 	DB 24,'   Waiting to Upload    '
			DB 24,' Press CANCEL to Abort  ' ; follow on
upl_msg_uploaddone:	DB 24,'    Upload Complete     '
upl_msg_goupload:       DB 24,'   Upload in Progress   '
			DB 24,'     Please Wait...     ' ; follow on
upl_msg_uploadabort:	DB 24,'    Upload Aborted      '

UPL_WaitToUpload:
	MOV	DPTR,#aud_uploadfrom		; see if theres anything
	CALL	MTH_LoadOp1Long			; to upload
	MOV	DPTR,#aud_uploadto		;
	CALL	MTH_LoadOp2Long			;
	CALL	MTH_CompareLongs		;
	JNZ	UPL_WTUnothing			; abort if not

	CALL	LCD_Clear			; display message saying we
	MOV	DPTR,#upl_msg_waitupload	; are waiting to upload
	CALL	LCD_DisplayStringCODE		; and pressing cancel
	MOV	A,#64				; will abort
	CALL	LCD_GotoXY			;
	CALL	LCD_DisplayStringCODE		;

	CALL	RS485_EnableReceive
UPL_WTUloop:
	CALL	KBD_ReadKey			; if cancel pressed
        CJNE	A,#KBD_CANCEL,UPL_WTUnotcancel	; then abort
	MOV	DPTR,#aud_upload_result
	MOV	A,#UPLOAD_ABORT
	MOVX	@DPTR,A
	CALL	LCD_Clear
	MOV     DPTR,#upl_msg_uploadabort
	CALL    LCD_DisplayStringCODE
	MOV	R7,#10
	CALL	DT_KeypressTimeout
UPL_WTUnormal:
	CALL    LCD_Clear
	SETB	tim_timerupdate
	CALL	TIM_GetDateTime
	MOV	DPSEL,#0
	MOV	DPTR,#aud_entry_commsupload
	CALL	AUD_AddEntry
UPL_WTUnothing:					;
	CALL	RS485_DisableReceive
	RET					;

UPL_WTUnotcancel:
	CALL	NET_ReceivePacket
        JZ	UPL_WTUnopkt

;*****************************************
; Check For Application Dependant Messages
;*****************************************

	CJNE	A,#MSG_SSR,UPL_RPnotssr
        CALL	UPL_SystemSummaryRequest
        JMP	UPL_WTUloop
UPL_RPnotssr:
	CJNE	A,#MSG_MBR,UPL_RPnotmbr
        CALL	UPL_MemoryBlockRequest
        JMP	UPL_WTUloop
UPL_RPnotmbr:
	CJNE	A,#MSG_ATR,UPL_RPnotatr
	CALL	UPL_AuditTransferRequest
        CALL	LCD_Clear
        MOV	DPTR,#upl_msg_goupload
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        CALL	LCD_DisplayStringCODE
        JMP	UPL_WTUloop
UPL_RPnotatr:
	CJNE	A,#MSG_ARR,UPL_RPnotarr
        CALL	UPL_AuditRecordRequest
        JMP	UPL_WTUloop
UPL_RPnotarr:
	CJNE	A,#MSG_AMT,UPL_RPnotamt
        CALL	UPL_AuditMemoryTransferred
        MOV	DPTR,#aud_upload_result
        MOV	A,#UPLOAD_SUCCESS
        MOVX	@DPTR,A
        CALL	LCD_Clear
        MOV	DPTR,#upl_msg_uploaddone
        CALL	LCD_DisplayStringCODE

        IF      SPEAKER
        CALL	SND_Warning
        ENDIF

        MOV	R7,#30
        CALL	DT_KeypressTimeout
        JMP	UPL_WTUnormal
UPL_RPnotamt:
	CJNE	A,#MSG_SSN,UPL_RPnotssn
        CALL	UPL_SetShiftNumber
        JMP	UPL_WTUloop
UPL_RPnotssn:
	CJNE	A,#MSG_STN,UPL_RPnotstn
        CALL	UPL_SetTicketNumber
        JMP	UPL_WTUloop
UPL_RPnotstn:
UPL_WTUnopkt:
	JMP	UPL_WTUloop

;**************************
; Application Message - SSR
;**************************

UPL_SystemSummaryRequest:
	MOV	DPTR,#buffer		; set up the SSI return message
        MOV	A,#MSG_SSI		;
        MOVX	@DPTR,A			;
        INC	DPTR			;
        CALL	MEM_SetDest		;

        MOV	DPTR,#sys_dtserial	; insert the serial number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#sys_nodeno	; insert the node number
        CALL	MEM_SetSource		;
        MOV	R7,#1			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#sys_ramsize	; insert the ramsize number
        CALL	MEM_SetSource		;
        MOV	R7,#1			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#shf_shift		; insert the shift number
        CALL	MEM_SetSource		;
        MOV	R7,#2			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#tkt_number	; insert the ticket number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#ppg_hdr_usernum	; insert the user number
        CALL	MEM_SetSource		;
        MOV	R7,#2			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#aud_total_entries	; insert the aud_total_entries number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyCODEtoXRAMsmall	;

        MOV	DPTR,#aud_first		; insert the aud_first number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#aud_last		; insert the aud_last number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#aud_uploadfrom	; insert the aud_uploadfrom number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#aud_uploadto	; insert the aud_uploadto number
        CALL	MEM_SetSource		;
        MOV	R7,#4			;
        CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#buffer
        MOV	R7,#35
        CALL	RS485_TransmitPacket
        RET

;**************************
; Application Message - MBR
;**************************

UPL_MemoryBlockRequest:
	MOV	DPTR,#buffer+7		; set the paged ram to
        MOVX	A,@DPTR			; the correct page
;	ANL	SB1data,#32		;
;	ANL	A,#31			;
;	ORL	A,SB1data		;
;	MOV	SB1data,A		;
;	CALL	SBS_WriteSB1		;

        MOV	DPTR,#buffer+6
        MOVX	A,@DPTR
        MOV	B,#128
        MUL	AB
        MOV	DPTR,#08000h
        CALL	AddABtoDPTR
        CALL	MEM_SetSource
        MOV	DPTR,#buffer
        MOV	A,#MSG_MBD
        MOVX	@DPTR,A
        INC	DPTR
        CALL	MEM_SetDest
        MOV	R7,#128
        CALL	MEM_CopyXRAMtoXRAMsmall

        MOV	DPTR,#buffer
        MOV	R7,#129
        CALL	RS485_TransmitPacket
        RET

;**************************
; Application Message - ATR
;**************************

UPL_AuditTransferRequest:
; should check it its ok to upload, for just now, return a YES

	MOV	DPTR,#buffer+6
        MOV	A,#1
        MOVX	@DPTR,A
        MOV	DPTR,#buffer+5
        MOV	R7,#2
        CALL	RS485_TransmitPacket
	RET

;**************************
; Application Message - ARR
;**************************

UPL_AuditRecordRequest:
	MOV	DPTR,#buffer+6
        CALL	AUD_AuditEntryAddr
        CALL	MEM_SetSource
        MOV	DPTR,#buffer
        MOV	A,#MSG_ARD
        MOVX	@DPTR,A
        INC	DPTR
        MOV	A,#AUDIT_ENTRY_SIZE
        MOVX	@DPTR,A
        INC	DPTR
        CALL	MEM_SetDest
        MOV	R7,A
        PUSHACC
        CALL	MEM_CopyXRAMtoXRAMsmall
        MOV	DPTR,#buffer
	POP	ACC
        INC	A
        INC	A
        MOV	R7,A
        CALL	RS485_TransmitPacket
	RET

;**************************
; Application Message - AMT
;**************************

UPL_AuditMemoryTransferred:
	MOV	DPTR,#aud_uploadto
        CALL	MTH_LoadOp1Long
        MOV	DPTR,#aud_uploadfrom
        CALL	MTH_StoreLong
	RET

;**************************
; Application Message - SSN
;**************************

UPL_SetShiftNumber:
	MOV	DPTR,#buffer+6
        CALL	MTH_LoadOp1Word
        CALL	SHF_SetShiftNumber
        MOV	DPTR,#buffer+6
        MOV	A,#1
        MOVX	@DPTR,A
        MOV	DPTR,#buffer+5
        MOV	R7,#2
        CALL	RS485_TransmitPacket
	RET

;**************************
; Application Message - STN
;**************************

UPL_SetTicketNumber:
	MOV	DPTR,#buffer+6
        CALL	MTH_LoadOp1Long
        CALL	TKT_SetTicketNumber
        MOV	DPTR,#buffer+6
        MOV	A,#1
        MOVX	@DPTR,A
        MOV	DPTR,#buffer+5
        MOV	R7,#2
        CALL	RS485_TransmitPacket
	RET

        ENDIF

;******************************* End Of UPLOAD.ASM *****************************
