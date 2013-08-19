;******************************************************************************
;
; File     : PPLUG.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the priceplug routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

PPG_EESLAVE	EQU 53h

	IF VT10
PPLUG_DETECT	EQU P1.3
	ELSE
PPLUG_DETECT	EQU P1.4
	ENDIF
; Define PricePlug Types
PPG_RESERVED	EQU 0
PPG_OPERATOR	EQU 1
PPG_MANAGER	EQU 2
PPG_DIAGNOSTICS	EQU 3

shf_shiftowner:	VAR 2 ; effective 'owner' of current shift, zero if no
		      ; shift in progress

;*****************************************************
; Generic Price Plug Header Format

PPG_FIX_HDR_SIZE		EQU (2+2+32+4+1+1+16)
ppg_fixhdr_chk:			VAR 2
ppg_fixhdr_custnum:		VAR 2
ppg_fixhdr_custname:		VAR 32
ppg_fixhdr_plugnum:		VAR 4
ppg_fixhdr_plugtype:		VAR 1
ppg_fixhdr_masterreadonly:	VAR 1
ppg_fixhdr_reserved:		VAR 16

PPG_HDR_SIZE		EQU (2+2+16+1+1+4+2+1+1+1+16)
ppg_hdr_chk:		VAR 2
ppg_hdr_usernum:	VAR 2
ppg_hdr_username:	VAR 16
ppg_hdr_prttype:	VAR 1
ppg_hdr_readonly:	VAR 1
ppg_hdr_insertions:	VAR 4
ppg_hdr_databytes:	VAR 2
ppg_hdr_datachunks:	VAR 1
ppg_hdr_formatrev:      VAR 1
ppg_hdr_programrev:     VAR 1
ppg_hdr_filename:	VAR 11
ppg_hdr_reserved:	VAR 5

; offsets

PPG_EE_CHK		EQU 0
PPG_EE_PLUGNUM		EQU 2
PPG_EE_CUSTNUM		EQU 6
PPG_EE_USERNUM		EQU 8
PPG_EE_PLUGTYPE		EQU 10
PPG_EE_PRTTYPE		EQU 11
PPG_EE_READONLY		EQU 12
PPG_EE_INSERTIONS	EQU 13
PPG_EE_USERNAME		EQU 17
PPG_EE_CUSTNAME		EQU 33
PPG_EE_RESERVED		EQU 65
PPG_EE_DATABYTES	EQU 81
PPG_EE_DATACHUNKS	EQU 83

PPG_EE_DATA		EQU 256 ; (256 thru to 8191 (0x1FFF))

;******************************************************************************
;
; Function:	PPG_CheckPricePlug
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_CheckPricePlug:
	JNB	ppg_plugchange,PPG_CPPnochange
	JNB	ppg_plugstate,ppluginsert
	CALL	SYS_UnitPowerOff
ppluginsert:
	CLR	ppg_plugchange
PPG_CPPnochange:
	RET


;******************************************************************************
;
; Function:	PPG_InitPricePlug
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_InitPricePlug:
	IF VT10
	SETB	PricePlugPol			;Invert PPP*
	MOV	ppg_error,#0
	MOV	C,PricePlugPres
	MOV	ppg_plugstate,C
	CLR	ppg_plugchange
	SETB	EX6				; enable INT6
	CALL	PPG_PrepareForChange
	RET

	ELSE

	MOV	ppg_error,#0
	MOV	C,PPLUG_DETECT
	MOV	ppg_plugstate,C
	CLR	ppg_plugchange
	SETB	0B9h				; EX2 enable INT2 (Check This !!!!! RG)
	CALL	PPG_PrepareForChange
	RET

	ENDIF


;******************************************************************************
;
; Function:	PPG_PrepareForChange
; Input:	None
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the polarity of the edge triggered PricePlug interrupt so that we
;   see a removal or an insertion.
;
;******************************************************************************

PPG_PrepareForChange:
	IF VT10

	JB	ppg_plugstate,PPG_PFCinsert
	CLR	PricePlugPol			;Non invert PPP* To Active Low (Removal Det)
	RET
PPG_PFCinsert:
	SETB	PricePlugPol			;Invert PPP* To Active High  (Insertion Det)
	RET

	ELSE

	JB	ppg_plugstate,PPG_PFCinsert
	ORL	T2CON,#020h		; want to see a removal
	RET
PPG_PFCinsert:
	ANL	T2CON,#0DFh		; want to see an insertion
	RET

	ENDIF
;******************************************************************************
;
; Function:	PPG_PricePlugChange
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Called upon insertion or removal of PricePlug.
;   Updates plugstate and plugchange.
;
;******************************************************************************

PPG_PricePlugChange:
	PUSHPSW
	MOV	C,PPLUG_DETECT

	IF VT10
	JNB	PricePlugPol,PPG_NonInvert
	CPL	C
PPG_NonInvert:
	ENDIF

	MOV	ppg_plugstate,C
	SETB	ppg_plugchange
	CALL	PPG_PrepareForChange
	POP	PSW
	RETI

;******************************************************************************
;
; Function:	PPG_ConfirmFixedHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ConfirmFixedHeader: ;ret a=0=fail
	PUSHDPH
        PUSHDPL
        PUSHDPH
        PUSHDPL
        INC	DPTR
        INC	DPTR
	MOV	R7,#PPG_FIX_HDR_SIZE-2
        MOV	R6,#0
        CALL	CRC_ComputeChecksum
        POP	DPL
        POP	DPH
        CALL	MTH_LoadOp2Word
        CALL	MTH_CompareWords
        POP	DPL
        POP	DPH
	RET

;******************************************************************************
;
; Function:	PPG_ConfirmHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ConfirmHeader: ;ret a=0=fail
	PUSHDPH
        PUSHDPL
        PUSHDPH
        PUSHDPL
        INC	DPTR
        INC	DPTR
	MOV	R7,#PPG_HDR_SIZE-2
        MOV	R6,#0
        CALL	CRC_ComputeChecksum
        POP	DPL
        POP	DPH
        CALL	MTH_LoadOp2Word
        CALL	MTH_CompareWords
        POP	DPL
        POP	DPH
	RET

;******************************************************************************
;
; Function:	PPG_ChecksumHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ChecksumHeader:
	PUSHDPH
        PUSHDPL
        INC	DPTR
        INC	DPTR
        MOV	R7,#PPG_HDR_SIZE-2
        MOV	R6,#0
        CALL	CRC_ComputeChecksum
        POP	DPL
        POP	DPH
        CALL	MTH_StoreWord
	RET

;******************************************************************************
;
; Function:	PPG_LoadPricePlugHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_LoadPricePlugHeader:
        MOV     DPTR,#ppg_fixhdr_plugtype		; ensure no
        CLR     A					; previous plugtype
        MOVX    @DPTR,A					; can have effect
	IF VT10
	JNB	ppg_plugstate,PPG_LPPHnoplug
	ELSE
	JB	ppg_plugstate,PPG_LPPHnoplug		; prepare to
	ENDIF
	CALL	SYS_PricePlugPowerOn			; read the
	CALL	testdelay				; priceplug
	MOV	R1,#PPG_EESLAVE				; headers
	SETB	F0					;
	CLR	F1					;

	MOV	DPTR,#0					; read the
	CALL	MEM_SetSource				; fixed header
        MOV     DPTR,#ppg_fixhdr_chk			;
        CALL    MEM_SetDest				;
	MOV	R7,#PPG_FIX_HDR_SIZE			;
	CALL	MEM_CopyEEtoXRAMsmall			;
	JNZ	PPG_LPPHloadfail			;

	MOV	DPTR,#128				; read the
	CALL	MEM_SetSource				; header
        MOV     DPTR,#ppg_hdr_chk			;
        CALL    MEM_SetDest				;
	MOV	R7,#PPG_HDR_SIZE			;
	CALL	MEM_CopyEEtoXRAMsmall			;
	JNZ	PPG_LPPHloadfail			;

	CALL	SYS_PricePlugPowerOff			; finished with pp

        MOV	DPTR,#ppg_fixhdr_chk			; if the fixed
	MOV	R7,#PPG_FIX_HDR_SIZE			; header is all
PPG_LPPHcheckvirgin:					; filled with 255's
	MOVX	A,@DPTR					; then it is a
	INC	DPTR					; virgin plug
	CJNE	A,#255,PPG_LPPHnotvirgin		;
	DJNZ	R7,PPG_LPPHcheckvirgin			;
	JMP	PPG_LPPHvirgin				;

PPG_LPPHnotvirgin:					; non virgin plug
	MOV	DPTR,#ppg_fixhdr_chk			; so confirm the
	CALL	PPG_ConfirmFixedHeader			; header's checksums
	JZ	PPG_LPPHchkfail				;
	MOV	DPTR,#ppg_hdr_chk			;
	CALL	PPG_ConfirmHeader			;
	JZ	PPG_LPPHchkfail				;

	CLR	A					; success
	RET						;

PPG_LPPHvirgin:
	MOV	ppg_error,#2				; error - virgin plug
	JMP	PPG_LPPHfail				;
PPG_LPPHnoplug:
	MOV	ppg_error,#3				; error - no plug
        JMP	PPG_LPPHfail				;
PPG_LPPHloadfail:
	CALL	SYS_PricePlugPowerOff			;
        MOV	ppg_error,#4				; error - load hdr fail
	JMP	PPG_LPPHfail				;
PPG_LPPHchkfail:
	MOV	ppg_error,#5				; error - hdr chk fail
	JMP	PPG_LPPHfail				;
PPG_LPPHfail:
	MOV	A,#1					; return error code
	RET

;******************************************************************************
;
; Function:	PPG_SavePricePlugFixedHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_SavePricePlugFixedHeader:
	CALL	MEM_SetSource
	CALL	SYS_PricePlugPowerOn

	MOV	R1,#PPG_EESLAVE
	SETB	F0
	CLR	F1
	MOV	DPTR,#0
	CALL	MEM_SetDest
	MOV	R7,#PPG_FIX_HDR_SIZE
	CALL	MEM_CopyXRAMtoEEsmall
	PUSHACC
	CALL	SYS_PricePlugPowerOff
	POP	ACC
	RET

;******************************************************************************
;
; Function:	PPG_SavePricePlugHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_SavePricePlugHeader:
	CALL	MEM_SetSource
	CALL	SYS_PricePlugPowerOn

	MOV	R1,#PPG_EESLAVE
	SETB	F0
	CLR	F1
	MOV	DPTR,#128
	CALL	MEM_SetDest
	MOV	R7,#PPG_HDR_SIZE
	CALL	MEM_CopyXRAMtoEEsmall
	PUSHACC
	CALL	SYS_PricePlugPowerOff
	POP	ACC
	RET

;******************************************************************************
;
; Function:	PPG_ChangeChunkSize
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ChangeChunkSize: ; DPTR=chunk, R6/R7=newsize
;	CALL DCH
 	PUSHDPH 	; change the chunk size
 	PUSHDPL	; to the size that
 	INC	DPTR	; this version of
 	INC	DPTR	; the code is interested
 	INC	DPTR	; in
 	MOV	A,R7	;
 	MOVX	@DPTR,A	;
 	INC	DPTR	;
 	MOV	A,R6	;
 	MOVX	@DPTR,A	;
 	POP	DPL	;
 	POP	DPH	;

 	PUSHDPH 	; recompute the checksum
 	PUSHDPL	; on the modified chunk
 	CALL	CRC_GenerateChecksum	;
 	POP	DPL	;
 	POP	DPH	;
; 	CALL DCH
 RET

;******************************************************************************
;
; Function:	PPG_ReadChunkSize
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ReadChunkSize: ;DPTR=chunk, output R6/R7=size, DPTR preserved
	PUSHDPH			; get chunk size
	PUSHDPL			;
	INC	DPTR			;
	INC	DPTR			;
	INC	DPTR			;
	MOVX	A,@DPTR			;
	MOV	R7,A			;
	INC	DPTR			;
	MOVX	A,@DPTR			;
	MOV	R6,A			;
	POP	DPL			;
	POP	DPH			;
	RET

;****************************** End Of PPLUG.ASM *****************************
