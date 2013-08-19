;******************************************************************************
;
; File     : MANAGER.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains everything relating to manager configurations
;            and manager priceplug formats.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************
;
;                                 CHUNK_MANAGER
;
;******************************************************************************

MAN_TOTAL_SIZE EQU (5+2+1+1+1+1+1+1+6+1+1+1+1+1+1+1+1+1+(6*21)+1+2+14+1+1+1+1+1+17)

; MAN_MISC bit defs
MAN_AUTOFLUSH		EQU 1
MAN_DECLARETAKINGS	EQU 2
MAN_BCDLASTTKT		EQU 8
MAN_BCDNUMABOVE		EQU 16
MAN_BCDNUMEXCL		EQU 32
MAN_CASHTEND		EQU 64
MAN_CASHTENDCHECK	EQU 128

; MAN_MISC2 bit defs
MAN_USETKTCTRL		EQU 1
MAN_INHIBITPOWERUPMSG	EQU 2

; MAN RECEIPT bit defs
MAN_OPRMANRECEIPT	EQU 1
MAN_OPRANYRECEIPT	EQU 2
MAN_RECEIPTVATNO	EQU 32
MAN_BCDRECEIPT		EQU 64
MAN_AUTORECEIPT		EQU 128

; MAN_EXTPRTCTRL bit defs
MAN_EXT_POWERUP		EQU 1
MAN_EXT_RECEIPT		EQU 2
MAN_EXT_VOID		EQU 4
MAN_EXT_AUDIT		EQU 8
MAN_EXT_SPOTCHECK	EQU 16
MAN_EXT_WAYBILL		EQU 32

;*** Manager Configuration Chunk ***

ppg_chunk_manager:	VAR 2
ppg_chunk_man_id:	VAR 1
ppg_chunk_man_size:	VAR 2

man_currencystr:	VAR 2
man_currencyformat:	VAR 1
man_issuemethod:	VAR 1
man_wayflags:		VAR 1
man_drawerenable:	VAR 1
man_drawersense:	VAR 1
man_mancashup:		VAR 1
man_filler:		VAR 6 ; digits/dot/just/str in unpacked form...temp
man_custdispctrl:       VAR 1
man_cardctrl:           VAR 1
man_backlighttime:      VAR 1
man_voidctrl:		VAR 1
man_voidtime:		VAR 1
man_voidcount:		VAR 1
man_cutterctrl:		VAR 1
man_tktdelay:           VAR 1
man_misc:               VAR 1 ; bit 0 : autoflush
			      ; bit 1 : declaretakings
			      ; bit 2 : reserved
			      ; bit 3 : 1=bcdlasttkt
			      ; bit 4 : 1=bcdnum above barcode
			      ; bit 5 : 1=exclude bcdnum from barcode
			      ; bit 6 : used by something
			      ; bit 7 : used by something
man_cd_poweron_line1:	VAR 21
man_cd_poweron_line2:	VAR 21
man_cd_idle_line1:	VAR 21
man_cd_idle_line2:	VAR 21
man_cd_poweroff_line1:	VAR 21
man_cd_poweroff_line2:	VAR 21

man_receiptctrl:	VAR 1
man_trxgrouplimit:	VAR 2
man_vatno:              VAR 14
man_misc2:		VAR 1 ; bit 0,1 : used by something
			      ; bit 2   : extra feed after waybill

man_custdisptype:	VAR 1
man_dateformat:		VAR 1
man_extprtenable:	VAR 1
man_extprtctrl:		VAR 1

; Tony's additions
man_language:		VAR 1

man_reserved:		VAR 18

	IF USE_SLAVE
;******************************************************************************
;
;                              CHUNK_SLAVEMANAGER
;
;******************************************************************************

ppg_chunk_slavemanager:	VAR 2
ppg_chunk_slaveman_id:	VAR 1
ppg_chunk_slaveman_size:	VAR 2
ppg_chunk_slaveman_data: VAR MAN_TOTAL_SIZE-5
	ENDIF

;******************************************************************************
;
; Function:	PPG_ClearChunkManager
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkManager:
	CLR	A
        MOV	DPTR,#ppg_chunk_man_id
        MOVX	@DPTR,A
        RET

        IF USE_SLAVE
;******************************************************************************
;
; Function:	PPG_ClearChunkSlaveManager
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

PPG_ClearChunkSlaveManager:
	CLR	A
        MOV	DPTR,#ppg_chunk_slaveman_id
        MOVX	@DPTR,A
        RET
        ENDIF




;******************************************************************************
;
; Function:	MAN_ManagerMenu
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************
        IF DT5
	ELSE
man_manmenu:
 IF USE_UPLOAD
 DB 13	; remove clear ticket/shift on rs485 linked systems
 ELSE
 DB 15
 ENDIF
 DB '=====Manager Menu====='
 DW 0
 DB 'Feed Paper            '
 DW PRT_PaperFeed
 DB 'Hang Count            '
 DW MAN_HangCount
 DB 'Set Date              '
 DW TIM_ChangeDate
 DB 'Set Time              '
 DW TIM_ChangeTime
 DB 'Set Print Intensity   '
 DW PRT_SetPrintIntensity
 DB 'Set Print Quality     '
 DW PRT_SetPrintQuality
 DB 'Set Perforation Offset'
 DW PRT_SetPerfOffset
 DB 'Set Black Mark Size   '
 DW PRT_SetPerfLineSize
 DB 'Set Node Number       '
 DW MAN_SetNodeNumber
 IF USE_UPLOAD
 ELSE
 DB 'Reset Ticket Number   '
 DW TKT_ManagerCleardown
 DB 'Reset Shift Number    '
 DW SHF_ManagerCleardown
 ENDIF
 DB 'DDS Diagnostics       '
 DW DIA_Diagnostics
 DB 'Demo Ticketing Loop   '
 DW TEST_LoopTickets

MAN_ManagerMenu:
	CLR     kbd_managerkey		; disable last option

	CALL	MNU_NewMenu		; if the ZERO key is held
	MOV     R7,#0			; down, let the user into
MAN_MMtestdiags:			; the DDS diagnostics screen
	MOV     R0,#20			; and the demo ticket mode
	CALL    delay100us		;
	CALL    KBD_ScanKeyboard	;
	CJNE    A,#1,MAN_MMloop		;
	DJNZ    R7,MAN_MMtestdiags	;

	SETB	kbd_managerkey		; activate last option
MAN_MMloop:
	MOV	DPTR,#man_manmenu
	CALL	MNU_LoadMenuCODE
	JB	kbd_managerkey,MAN_MMdiags

	MOV	DPTR,#buffer+1024	; three less entry in
	MOVX	A,@DPTR			; this menu
	DEC	A			;
	DEC     A
	DEC	A
	MOVX	@DPTR,A			;

MAN_MMdiags:
	CALL	MNU_SelectMenuOption
	JNB	ACC.7,MAN_MMloop
	CLR	A
	CLR     kbd_managerkey
	RET
	ENDIF


msg_newnn:	DB 16,'New Node Number?'
msg_nn:		DB 'Currently '

MAN_SetNodeNumber:
	CALL	MAN_DisplayNN

	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	DPTR,#msg_newnn
	CALL	LCD_DisplayStringCODE
	MOV	A,#20
	CALL	LCD_GotoXY

	MOV	DPSEL,#0
	MOV	DPTR,#buffer
	MOV	B,#82
	MOV     R7,#2
	CALL	NUM_GetNumber
	JZ	MAN_SNNabort
	MOV	A,mth_op1ll
	MOV	DPTR,#sys_nodeno
	MOVX	@DPTR,A
	MOV	sys_mynode,A
	CALL    SYS_WriteUnitInfo

MAN_SNNabort:
	CALL	LCD_Clear
	SETB	tim_timerupdate
	CLR     A
	RET

MAN_DisplayNN:
	MOV	DPTR,#msg_nn
	CALL	MEM_SetSource
	MOV	DPTR,#buffer
	CALL	MEM_SetDest
	MOV	R7,#10
	CALL	MEM_CopyCODEtoXRAMsmall
	MOV	DPSEL,#1
	MOV	DPTR,#buffer+10
	MOV	R5,#2
	MOV	DPSEL,#0
	MOV	DPTR,#sys_nodeno
	CALL	NUM_NewFormatDecimal8

	CALL	LCD_Clear
	MOV	DPTR,#buffer
	MOV	R7,#12
	CALL	LCD_DisplayStringXRAM
	RET
;******************************************************************************
MAN_ViewNodeNumber
	CALL	MAN_DisplayNN
	CALL	KBD_WaitKey
	RET
;******************************************************************************
MAN_HangCount:
	PUSHDPH
	PUSHDPL
	MOV	DPSEL,#0
	MOV	DPTR,#tkc_hangcount
	MOV	DPSEL,#1
	MOV	DPTR,#buffer
	MOV	R5,#5
	CALL	NUM_NewFormatDecimal16
	CALL	LCD_Clear
	MOV	DPTR,#buffer
	MOV	R7,#5
	CALL	LCD_DisplayStringXRAM
	CALL	KBD_WaitKey
	CJNE	A,#20,MAN_NoClear
	MOV	DPTR,#tkc_hangcount
	MOV	A,#0			;Clear hang count
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOVX	@DPTR,A			;
MAN_NoClear:
	POP	DPL
	POP	DPH
	RET
;****************************** End Of MANAGER.ASM ****************************
