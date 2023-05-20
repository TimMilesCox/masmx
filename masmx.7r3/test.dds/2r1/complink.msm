;******************************************************************************
;
; File     : COMPLINK.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the "Computer Link-Up Mode" routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

CLM_REQHDR		EQU	1
CLM_PPCHANGE		EQU	2
CLM_LLFORMAT		EQU	3
CLM_HLFORMAT		EQU	4
CLM_PROGPP		EQU	5
CLM_SCANPP		EQU	6
CLM_READRAM		EQU	7
CLM_ERROR		EQU	99

CLM_SUCCESS		EQU	1
CLM_FAIL		EQU	0

clm_linkupmode:		DB 255,21,0,0,0,0,21,'Computer Link-Up Mode'
clm_msgidle:	DB 4,'Idle'
clm_msgbusy:	DB 4,'Busy'

CLM_ComTest:
	MOV	B,#COM_COM1
        JMP	COM_Test

CLM_Flush:
	MOV	B,#COM_COM1
        JMP	COM_Flush

CLM_SendPacket:
	MOV	B,#COM_COM1
        JMP	COM_SendPacket

CLM_ReceivePacket:
	MOV	B,#COM_COM1
        JMP	COM_ReceivePacket

CLM_RxCharTimeout:
	MOV	B,#COM_COM1
        JMP	COM_RxCharTimeout

CLM_TxChar:
	MOV	B,#COM_COM1
        JMP	COM_TxChar
CLM_RxChar:
	MOV	B,#COM_COM1
        JMP	COM_RxChar


CLM_Idle:
	CALL	LCD_Clear2
        MOV	A,#74
        CALL	LCD_GotoXY
        MOV	DPTR,#clm_msgidle
        CALL	LCD_DisplayStringCODE
        RET

CLM_Busy:
	CALL	LCD_Clear2
        MOV	A,#74
        CALL	LCD_GotoXY
        MOV	DPTR,#clm_msgbusy
        CALL	LCD_DisplayStringCODE
        RET


;******************************************************************************
;
; Function:	CLM_ComputerLinkupMode
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   The main entry point for computer linkup mode. Puts the DT10 into slave
;   mode and acts upon the requests from the PC. Upon termination of this
;   mode, the DT10 is powered down. I.e, this routine never returns.
;
;******************************************************************************

CLM_ComputerLinkupMode:
	IF DT5
         CALL	PRT_StartPrint				;
         MOV	DPTR,#clm_linkupmode			;
         CALL	PRT_DisplayMessageCODE			;
         CALL	PRT_FormFeed				;
         CALL	PRT_EndPrint				;
        ELSE
	 CALL	LCD_Clear				; tell user we're
	 MOV	A,#1					; in slave mode
	 CALL	LCD_GotoXY				;
	 MOV	DPTR,#clm_linkupmode+6			;
	 CALL	LCD_DisplayStringCODE			;
	ENDIF						;

        CALL	CLM_Busy
	JMP	CLM_CLMnewplug

CLM_CLMmainagain:
	CALL	CLM_Idle
CLM_CLMmain:
	MOV	A,#SYS_AREA_CLM_MAIN			; diagnostics
        CALL	SYS_SetAreaCode				;

	JB	ppg_plugchange,CLM_CLMnewplug		; check for priceplug
							; insertion/removal

	CALL	CLM_ComTest				; check for host
	JNZ	CLM_CLMcomms				; commands

	CALL	KBD_ReadKey				; check for keyboard
	JZ	CLM_CLMmain				; cancel command
	CJNE	A,#KBD_CANCEL,CLM_CLMmain		;
	IF DT5
        ELSE
	 CALL	LCD_Clear				; abort if pressed
	ENDIF						;
	JMP	SYS_UnitPowerOff			;

;****************************
; PricePlug Insertion/Removal
;****************************

CLM_CLMnewplug:
	CALL	CLM_Busy
	CLR	ppg_plugchange				; prepare to send
	MOV	DPTR,#com_pkt_type			; a CLM_PPCHANGE
	MOV	A,#CLM_PPCHANGE				; command which
	MOVX	@DPTR,A					; indicates whether
	INC	DPTR					; a priceplug has
	MOV	A,#1					; been inserted (1)
	MOVX	@DPTR,A					; or removed (0)
	CLR	A					;
	INC	DPTR					;
	MOVX	@DPTR,A					;
	INC	DPTR					;
	INC	DPTR					;
	INC	DPTR					;
	CLR	A					;
	JB	ppg_plugstate,CLM_CLMchange		;
	MOV	A,#1					;
CLM_CLMchange:						;
	MOVX	@DPTR,A					;
	CALL	CLM_SendPacket				;
	JMP	CLM_CLMmainagain			;

;**************
; Host Commands
;**************

CLM_CLMcomms:
	CALL	CLM_Busy
	CALL	CLM_ReceivePacket			; receive a CLM
	JNC	CLM_invalidcommand			; command and
	MOV	DPTR,#com_pkt_type			; jump to the
	MOVX	A,@DPTR					; relevant handler
	MOV	DPTR,#clm_commandtable			;
	MOV	B,A					;
	ANL	A,#0F0h					;
	JNZ	CLM_invalidcommand			;
	MOV	A,B					;
	RL	A					;
	CALL	CLM_CLMlaunch				;
	JMP	CLM_CLMmainagain			;
CLM_CLMlaunch:						;
	JMP	@A+DPTR					;
CLM_invalidcommand:					;
	CALL	SND_Warning				;
	JMP	CLM_CLMmainagain			;

 align topage
 nop
 align topage
CLM_Unused:						; dummy handler
	MOV	A,#100					; for unused or
	MOV	B,#200					; unrecognised
	CALL	SND_Beep				; CLM commands
	RET						;

CLM_SendError:						; routine for
	MOV	DPTR,#com_pkt_data			; notifying PC
	MOVX	@DPTR,A					; of any errors
        MOV	DPTR,#com_pkt_type			; affecting the
        MOV	A,#CLM_ERROR				; operation of
        MOVX	@DPTR,A					; a CLM command
        INC	DPTR					;
        MOV	A,#1					;
        MOVX	@DPTR,A					;
        INC	DPTR					;
        CLR	A					;
        MOVX	@DPTR,A					;
        CALL	CLM_SendPacket				;
        RET						;

clm_commandtable:
	AJMP	CLM_Unused		; 0
	AJMP	CLM_RequestHeader	; 1 (CLM_REQHDR)
	AJMP	CLM_Unused		; 2 (CLM_PPCHANGE txed only)
	AJMP	CLM_LowLevelFormat	; 3 (CLM_LLFORMAT)
	AJMP	CLM_HighLevelFormat	; 4 (CLM_HLFORMAT)
	AJMP	CLM_ProgramPricePlug	; 5 (CLM_REQPROGPP)
	AJMP	CLM_UpLoad		; 6 (CLM_SCANPP)
	AJMP	CLM_ReadXRAM		; 7 (CLM_READRAM)
	AJMP	CLM_SetSerial		; 8
	AJMP	CLM_Unused		; 9
	AJMP	CLM_Unused		; 10
	AJMP	CLM_Unused		; 11
	AJMP	CLM_Unused		; 12
	AJMP	CLM_Unused		; 13
	AJMP	CLM_Unused		; 14
	AJMP	CLM_Unused		; 15

;******************************************************************************
;
;              C o m p u t e r   L i n k - U p   C o m m a n d s
;
;******************************************************************************

;******************************************************************************
;
; Function:	CLM_RequestHeader
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_RequestHeader:
	CALL	PPG_LoadPricePlugHeader
	JNZ	CLM_RHhdrfail

        MOV     DPTR,#ppg_fixhdr_chk
        CALL    MEM_SetSource
        MOV     DPTR,#com_pkt_data
        CALL    MEM_SetDest
        MOV     R7,#PPG_FIX_HDR_SIZE
        CALL    MEM_CopyXRAMtoXRAMsmall

        MOV     DPTR,#ppg_hdr_chk
        CALL    MEM_SetSource
        MOV     DPTR,#com_pkt_data+PPG_FIX_HDR_SIZE
        CALL    MEM_SetDest
        MOV     R7,#PPG_HDR_SIZE
        CALL    MEM_CopyXRAMtoXRAMsmall

	MOV	DPTR,#com_pkt_type
	MOV	A,#CLM_REQHDR
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#PPG_FIX_HDR_SIZE+PPG_HDR_SIZE
	MOVX	@DPTR,A
	INC	DPTR
	CLR	A
	MOVX	@DPTR,A
	CALL	CLM_SendPacket
	RET
CLM_RHhdrfail:
	MOV	A,ppg_error
        JMP	CLM_SendError

;******************************************************************************
;
; Function:	CLM_LowLevelFormat
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_LowLevelFormat:
	MOV	DPTR,#com_pkt_data
        CALL	PPG_ConfirmFixedHeader
        JZ	CLM_LLFfail
        MOV     DPTR,#com_pkt_data+PPG_FIX_HDR_SIZE
        CALL    PPG_ConfirmHeader
        JZ      CLM_LLFfail

        MOV     DPTR,#com_pkt_data
	CALL	PPG_SavePricePlugFixedHeader
        JNZ	CLM_LLFfail

        MOV     DPTR,#com_pkt_data+PPG_FIX_HDR_SIZE
        CALL    PPG_SavePricePlugHeader
        JNZ	CLM_LLFfail

	MOV	B,#1
	JMP	CLM_LLFok
CLM_LLFfail:
	CALL	SND_Warning
	MOV	B,#0
CLM_LLFok:
	MOV	DPTR,#com_pkt_data
	MOV	A,B
	MOVX	@DPTR,A
	MOV	DPTR,#com_pkt_type
	MOV	A,#CLM_LLFORMAT
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#1
	MOVX	@DPTR,A
	INC	DPTR
	CLR	A
	MOVX	@DPTR,A
	CALL	CLM_SendPacket
	RET

;******************************************************************************
;
; Function:	CLM_HighLevelFormat
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_HighLevelFormat:
        CALL	PPG_LoadPricePlugHeader
        JNZ	CLM_HLFfail

	MOV	DPTR,#com_pkt_data	;
	CALL	MEM_SetSource		;

	MOV	DPTR,#ppg_hdr_usernum	; copy user number
	CALL	MEM_SetDest		;
	MOV	R7,#2			;
	CALL	MEM_CopyXRAMtoXRAMsmall	;

	MOV	DPTR,#ppg_hdr_username	; copy user name
	CALL	MEM_SetDest		;
	MOV	R7,#16			;
	CALL	MEM_CopyXRAMtoXRAMsmall	;

	MOV	DPTR,#ppg_hdr_prttype	; copy printer type
	CALL	MEM_SetDest		;
	MOV	R7,#1			;
	CALL	MEM_CopyXRAMtoXRAMsmall	;

	MOV	DPTR,#ppg_hdr_formatrev ; copy format revision
	CALL	MEM_SetDest		;
	MOV	R7,#1			;
	CALL	MEM_CopyXRAMtoXRAMsmall	;

        MOV	DPTR,#ppg_hdr_chk
        CALL	PPG_ChecksumHeader

        MOV	DPTR,#ppg_hdr_chk
        CALL	PPG_SavePricePlugHeader
        JNZ	CLM_HLFfail

	MOV	B,#1
	JZ	CLM_HLFok
CLM_HLFfail:
	MOV	B,#0
CLM_HLFok:
	MOV	DPTR,#com_pkt_data
	MOV	A,B
	MOVX	@DPTR,A
	MOV	DPTR,#com_pkt_type
	MOV	A,#CLM_HLFORMAT
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#1
	MOVX	@DPTR,A
	INC	DPTR
	CLR	A
	MOVX	@DPTR,A
	CALL	CLM_SendPacket
        CALL	SYS_PricePlugPowerOff
	RET

;******************************************************************************
;
; Function:	CLM_ProgramPricePlug
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_ProgramPricePlug:
 	MOV	DPTR,#com_pkt_data		; copy databytes and
        CALL	MEM_SetSource			; datachunks
        MOV	DPTR,#ppg_hdr_databytes		; into our copy of the
        CALL	MEM_SetDest			; priceplug header
        MOV	R7,#3				;
        CALL	MEM_CopyXRAMtoXRAMsmall		;

        MOV     DPTR,#ppg_hdr_programrev        ; copy programrev into
        CALL    MEM_SetDest			; our copy of the
        MOV	R7,#1				; priceplug header
        CALL	MEM_CopyXRAMtoXRAMsmall		;

        MOV     DPTR,#ppg_hdr_chk		; then write the new
        CALL    PPG_ChecksumHeader		; header back to the
        MOV     DPTR,#ppg_hdr_chk		; priceplug
        CALL    PPG_SavePricePlugHeader		;
        JNZ     CLM_DLfail			;

	CALL	SYS_PricePlugPowerOn

        MOV	DPTR,#ppg_hdr_databytes		; R7/R6 = databytes
        MOVX	A,@DPTR				;
        MOV	R7,A				;
        INC	DPTR				;
        MOVX	A,@DPTR				;
        MOV	R6,A				;
        INC	DPTR				;
        MOVX	A,@DPTR				; R5 = datachunks
        MOV	R5,A				;

        MOV	DPTR,#PPG_EE_DATA		; prepare to write R7/R6
	MOV	A,R7				; bytes to the data section
	JZ	CLM_DLloop			; within the priceplug
	INC	R6				;
CLM_DLloop:
	MOV	R5,#10
	CALL	CLM_RxCharTimeout		; read next byte
	JNC	CLM_DLfail			; from serial port 0

	CALL	CLM_TxChar			; echo the byte for handshake

	MOV	B,A				; write the byte
	CALL	I2C_Write13			; to the priceplug
	JNZ	CLM_DLfail			;

	INC	DPTR
	CPL	led_led2
	CALL	SBS_WriteSB2
	DJNZ	R7,CLM_DLloop
	DJNZ	R6,CLM_DLloop
	JMP	CLM_DLdone
CLM_DLfail:
	CALL	SND_Warning
CLM_DLdone:
	CALL	SYS_PricePlugPowerOff
	RET

;******************************************************************************
;
; Function:	CLM_Upload
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_UpLoad:	; for the moment, send all 8K
	CALL	SYS_PricePlugPowerOn
	CALL	CLM_Flush
	MOV	R0,#5
	CALL	delay100ms

	MOV	R6,#32
	MOV	R7,#0
	MOV	DPTR,#0

	MOV	R1,#PPG_EESLAVE
	MOV	A,R7
	JZ	CLM_ULloop
	INC	R6
CLM_ULloop:
	CALL	I2C_Read13
        JNZ	CLM_ULfail
        MOV	A,B
	CALL	CLM_TxChar
	INC	DPTR
	CPL	led_led2
	CALL	SBS_WriteSB2
	DJNZ	R7,CLM_ULloop
	DJNZ	R6,CLM_ULloop
	JMP	CLM_ULdone
CLM_ULfail:
	CALL	SND_Warning
CLM_ULdone:
	CALL	SYS_PricePlugPowerOff
	RET

;******************************************************************************
;
; Function:	CLM_ReadXRAM
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_ReadXRAM:
	MOV	DPTR,#sys_ramsize
        MOVX	A,@DPTR
	MOV	R7,A
        CALL	CLM_TxChar
	ANL	SB1data,#0E0h ; page 0
	CALL	SBS_WriteSB1
CLM_RRpageloop:
	MOV	DPTR,#08000h
	MOV	R6,#128
CLM_RRbytehiloop:
	MOV	R5,#0
	CPL	led_led1
	CALL	SBS_WriteSB2
CLM_RRbyteloloop:
	MOVX	A,@DPTR
;        MOV     B,A
;	CALL	SND_SoundOn
	CALL	CLM_TxChar
        CALL    CLM_RxChar
        JC	CLM_RRabort
	INC	DPTR
	DJNZ	R5,CLM_RRbyteloloop
	DJNZ	R6,CLM_RRbytehiloop
	MOV	A,SB1data
	INC	A        ; next page
;	MOV	SB1data,A
;	CALL	SBS_WriteSB1
	DJNZ	R7,CLM_RRpageloop
	CALL	SND_SoundOff
	RET
CLM_RRabort:
	CALL	SND_Warning
        RET

;******************************************************************************
;
; Function:	CLM_SetSerial
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;
;******************************************************************************

CLM_SetSerial:
	CLR	F0
	SETB	F1
	MOV	R1,#EE_SLAVE
	MOV	DPTR,#com_pkt_data
	CALL	MEM_SetSource
	MOV	DPTR,#EE_DTSERIAL
	CALL	MEM_SetDest
	MOV	R7,#4
	CALL	MEM_CopyXRAMtoEEsmall
	RET

;***************************** End Of COMPLINK.ASM ****************************
;