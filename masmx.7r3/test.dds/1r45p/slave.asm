;******************************************************************************
;
; File     : SLAVE.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for handling the slave ticket
;             printer code.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************
;
;                S l a v e B a n d e r   S e t u p   C o d e
;
;******************************************************************************

msg_slv_wbsetup:	DB 22,'Setting Up Wristbander'
msg_slv_sendman:	DB 23,'Sending Manager Data...'
msg_slv_sendlay:	DB 22,'Sending Layout Data...'
msg_slv_sendok:	   	DB 19,'Wristband Now Setup'
msg_slv_sendfail:  	DB 22,'Wristband Setup Failed'
                        DB 24,'No Wristbands Will Print'

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SLV_SendManagerConfig:
	CALL	LCD_Clear2			; display message
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        MOV	DPTR,#msg_slv_sendman		;
        CALL	LCD_DisplayStringCODE		;

	MOV	DPTR,#ppg_chunk_slavemanager+3	; alter slavemanager chunk
        MOV	A,#09Ah				; so that it only has the
        MOVX	@DPTR,A				; same number of bytes as
        MOV	DPTR,#ppg_chunk_slavemanager	; the slave wristbander
	CALL	CRC_GenerateChecksum		; expects

	MOV	DPTR,#ppg_chunk_slavemanager	; send manager chunk
        MOV	R6,#0				;
        MOV	R7,#09Ah ;MAN_TOTAL_SIZE	; SWB only knows about
        MOV	B,#COM_COM1			; first 0x9A bytes
        CALL	COM_NewSendPacket		;
        RET

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SLV_SendLayoutConfig:
	CALL	LCD_Clear2			; display message
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        MOV	DPTR,#msg_slv_sendlay		;
        CALL	LCD_DisplayStringCODE		;

	MOV	DPTR,#ppg_chunk_slavelayout	; send layout chunk
        MOV     R6,#HIGH(OPR_LAYOUT_SIZE)	;
        MOV     R7,#LOW(OPR_LAYOUT_SIZE)	;
        MOV	B,#COM_COM1			;
        CALL	COM_NewSendPacket		;
        RET

;******************************************************************************
;
; Function:	?
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

SLV_SendFullConfig:
	CALL	LCD_Clear			; display setup message
        MOV	DPTR,#msg_slv_wbsetup		;
        CALL	LCD_DisplayStringCODE		;

;	CLR	com_selab			; select and flush the
;        CALL	SBS_WriteSB1			; wristbander serial port
        MOV	B,#COM_COM1			;
        CALL	COM_Flush			;

        MOV	DPTR,#buffer			; send a sync packet so
        MOV	A,#'C'				; that we are sure the
        MOVX	@DPTR,A				; wristbander knows the
        MOV	R6,#0				; next packet is a manager
        MOV	R7,#1				; chunk packet
        MOV	B,#COM_COM1			;
        CALL	COM_NewSendPacket		;
        JNC	SLV_SFCfail			;

	CALL	SLV_SendManagerConfig
        JNC	SLV_SFCfail

        CALL	SLV_SendLayoutConfig
        JNC	SLV_SFCfail

        MOV	DPTR,#buffer			; wait for wristbander to
        MOV	B,#COM_COM1			; send a packet back with
        CALL	COM_NewReceivePacket		; the message 'c' to indicate
        JNC	SLV_SFCfail			; that the config was
        MOV	DPTR,#buffer			; received ok
        MOVX	A,@DPTR				;
        CJNE	A,#'c',SLV_SFCfail		;

        CALL	LCD_Clear2			; display ok message
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        MOV	DPTR,#msg_slv_sendok		;
        CALL	LCD_DisplayStringCODE		;
        MOV	R0,#10
        CALL	delay100ms
        CALL	LCD_Clear			;

;        SETB	com_selab			; restore serial port
;        CALL	SBS_WriteSB1			;
        RET

SLV_SFCfail:
;	SETB	com_selab			; restore serial port
;        CALL	SBS_WriteSB1			;

	CALL	LCD_Clear			; display error message
        MOV	DPTR,#msg_slv_sendfail		;
        CALL	LCD_DisplayStringCODE		;
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        CALL	LCD_DisplayStringCODE		;

        IF      SPEAKER
        CALL	SND_Warning			;
        ENDIF

        CALL	KBD_WaitKey			;
        RET

;******************************************************************************
;
;         S l a v e B a n d e r   T i c k e t   P r i n t i n g   C o d e
;
;******************************************************************************

msg_slaveexceed:	DB 21,'Daily Wristband Limit'
msg_slaveexceed2:	DB 19,'Exceeded...Press OK'
msg_slavepaperout:	DB 21,'Wristbander Paper Out'
msg_slavecommsfail:	DB 20,'   Wristbander Fault'
                        DB 23,'Report Error To Manager'

tkt_slavefields:
	DW	tkt_value,com_pkt_data+66
        DB	4
        DW      datebuffer,com_pkt_data+70
        DB	4
        DW      sys_dtserial,com_pkt_data+74
        DB	4
        DW      ppg_hdr_usernum,com_pkt_data+78
        DB	2
        DW	tkt_number,com_pkt_data+80
        DB	4
        DW	tkt_groupqty,com_pkt_data+84
        DB	2
        DW      ppg_hdr_username,com_pkt_data+86
        DB	16
        DW	bcd_digitbuffer,com_pkt_data+102
        DB	10
        DW	tkt_slavenumber,com_pkt_data+112
        DB	4

msg_printwb: DB 21,'Printing Wristband...'

SLV_PrintSlaveTicket:
;****************************
; generate the ticket request
;****************************
	CALL	LCD_Clear
        MOV	DPTR,#msg_printwb
        CALL	LCD_DisplayStringCODE

	CALL	TKT_TicketDesc1
        CALL	MEM_SetSource
	MOV	DPTR,#com_pkt_data
        CALL	MEM_SetDest
        MOV	R7,#(33+33)
        CALL	MEM_CopyXRAMtoXRAMsmall
        MOV	DPSEL,#0
        MOV	DPTR,#tkt_slavefields
        MOV	R5,#9
        CALL	MEM_MultipleXRAMCopy

;******************
; issue the request
;******************

;	CLR	com_selab			; select wristbander
;        CALL    SBS_WriteSB1			; serial port

        MOV     DPTR,#com_pkt_data
        MOV     R7,#116
        MOV     R6,#0
        MOV     B,#COM_COM1
        CALL    COM_SendSmallPacket
;        JNC     SLV_PSTcommsfail

;***************
; wait for reply
;***************

        MOV	R0,#20				; the wristbander
        CALL	delay100ms			;
        MOV     B,#COM_COM1
        MOV     DPTR,#com_pkt_data
	CALL	COM_NewReceivePacket		;
        JNC	SLV_PSTcommsfail

	SETB	com_selab			; select customer display
;        CALL    SBS_WriteSB1			; (default) serial port

	CALL	LCD_Clear			; go back to displaying
	CALL	TKT_DisplayIdleState		; subtotal screen

        MOV	DPTR,#com_pkt_data		;
        MOVX	A,@DPTR				;
        JZ	SLV_PSTpaperout
        MOV	A,#TKT_OK
        RET

SLV_PSTcommsfail:
;	SETB	com_selab			; select customer display
;        CALL    SBS_WriteSB1			; (default) serial port

	CALL	LCD_Clear			; display comms fail
        MOV	DPTR,#msg_slavecommsfail	; message
        CALL	LCD_DisplayStringCODE		;
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        CALL	LCD_DisplayStringCODE		;

        IF      SPEAKER
	CALL	SND_Warning			; beep warning
        ENDIF

        CALL	KBD_OkOrCancel			; wait for key
        MOV	A,#TKT_FAILCOMMS		; return FAILCOMMS
        RET					;

SLV_PSTpaperout:
	CALL	LCD_Clear
        MOV	DPTR,#msg_slavepaperout
        CALL	LCD_DisplayStringCODE

        IF      SPEAKER
        CALL	SND_Warning
        ENDIF

        MOV     R0,#10
        CALL    delay100ms
        CALL	LCD_Clear
        MOV	DPTR,#msg_printagain
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#msg_printagain2
        CALL	LCD_DisplayStringCODE
        CALL    KBD_OkOrCancel
        JZ      SLV_PSTfailpaper
        MOV	A,#TKT_FAILRETRY
        RET
SLV_PSTfailpaper:
	MOV	A,#TKT_FAILPAPER
        RET

;******************************* End Of SLAVE.ASM ******************************
