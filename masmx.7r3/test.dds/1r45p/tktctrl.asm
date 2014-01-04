;******************************************************************************
;
; File     : TKTCTRL.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for implementing real-time
;            ticket control from a ticketing controller PC.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;
; Notes:
;
; 1. Repeatedly call TKC_Idle during the idle loop
; 2. From PrintTickets(), call TKC_InitiateTransaction to start a
;    transaction request off
; 3. From PrintTicket(), call TKC_ReceiveTicketDetails
;******************************************************************************

	IF USE_TKTCTRL
USE_TIMEOUT EQU 1

tkc_itemno:	VAR 1
tkc_seatrow:	VAR 11		; up to 10 character seat row
tkc_seatcol:	VAR 11		; up to 10 character seat column
tkc_seatblock:	VAR 22		; up to 21 character seat block name
tkc_currenttsr: VAR (4+(10*5))
tkc_blockno:	VAR 2
tkc_fixture:	VAR 2

TKC_CheckTKCtrl:
	MOV	DPTR,#man_misc2
        MOVX	A,@DPTR
        ANL	A,#MAN_USETKTCTRL
        RET

;******************************************************************************
;
; Function:	TKC_ReceiveStartupMessage
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

tkc_retrycounter:	VAR 1
tkc_retrylines:		DB '-/|',4 ; char 4 for backslash

tkc_msg_tktctrlboot1:	DB 24,'   Initialising From    '
tkc_msg_tktctrlboot2:	DB 24,'  Ticketing Controller  '

tkc_msg_tktctrlboot3:	DB 24,' Initialisation Failed  '
tkc_msg_tktctrlboot4:	DB 24,'      Retrying          '

tkc_msg_tktctrlok:	DB 17,'      Initialised'
tkc_msg_fixnum:		DB 16,'    Fixture No. '
tkc_msg_inputfixture:	DB 19,'     Emergency Mode'
tkc_msg_inputfixture2:	DB 19,'Enter Fixture No.: '


TKC_ReceiveStartupMessage:
	CALL    TKC_CheckTKCtrl
        JNZ	TKC_RSMusectrl
        CALL	LCD_Clear
        MOV	DPTR,#tkc_msg_inputfixture
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        CALL	LCD_DisplayStringCODE
        MOV	B,#64+19
        MOV	R7,#4
        CALL	NUM_GetNumber
        MOV	DPTR,#tkc_fixture
        CALL	MTH_StoreWord
        JMP     TKC_RSMgotfixture

TKC_RSMusectrl:
	CALL	COM_InitRS485
	MOV	DPTR,#tkc_retrycounter
        CLR	A
        MOVX	@DPTR,A
        MOV	A,#1
        CALL	MTH_LoadOp1Acc
        MOV	DPTR,#tkc_blockno
        CALL	MTH_StoreWord
	CALL	LCD_Clear
        MOV	DPTR,#tkc_msg_tktctrlboot1
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#tkc_msg_tktctrlboot2
        CALL	LCD_DisplayStringCODE
TKC_RSMgo:
	MOV	R3,#100
TKC_RSMwaitgrq:


	CALL	NET_ReceivePacket
        JNZ	TKC_RSMrxgrq
        MOV	R0,#1
        CALL	delay100ms
        DJNZ	R3,TKC_RSMwaitgrq
        JMP	TKC_RSMfail
TKC_RSMrxgrq:
        CJNE	A,#MSG_GRQ,TKC_RSMnotgrq



        MOV	DPTR,#buffer
        MOV	A,#MSG_SUM
        MOVX	@DPTR,A
        MOV	R7,#1
        CALL	RS485_TransmitPacket

	MOV	R3,#10
TKC_RSMwaitsum:
	CALL	NET_ReceivePacket
        JNZ	TKC_RSMrxsum
        MOV	R0,#1
        CALL	delay100ms
        DJNZ	R3,TKC_RSMwaitsum
        JMP	TKC_RSMgo
TKC_RSMrxsum:
        CJNE	A,#MSG_SUM,TKC_RSMgo
        CALL	LCD_Clear
        MOV	DPTR,#buffer+6
        CALL	MTH_LoadOp1Word
        MOV	DPTR,#tkc_fixture
        CALL	MTH_StoreWord

TKC_RSMgotfixture:
        CALL	LCD_Clear			; display what fixture
        MOV	DPTR,#tkc_msg_tktctrlok		; number we are using
        CALL	LCD_DisplayStringCODE		;
        MOV	A,#64				;
        CALL	LCD_GotoXY			;
        MOV	DPTR,#tkc_msg_fixnum		;
        CALL	LCD_DisplayStringCODE		;
        MOV	DPSEL,#0
        MOV	DPTR,#tkc_fixture
        MOV	DPSEL,#1
        MOV	DPTR,#buffer
        MOV	R5,#4+NUM_ZEROPAD
        CALL	NUM_NewFormatDecimal16
        MOV	DPTR,#buffer
        MOV	R7,#4
        CALL	LCD_DisplayStringXRAM
        MOV	R0,#20
        CALL	delay100ms
        CALL	LCD_Clear
        RET

TKC_RSMnotgrq:
	CJNE	A,#MSG_TPI,TKC_RSMwaitgrq
        CALL	TKC_SendTSCFail
	JMP	TKC_RSMwaitgrq
TKC_RSMfail:




	CALL	LCD_Clear
        MOV	DPTR,#tkc_msg_tktctrlboot3
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#tkc_msg_tktctrlboot4
        CALL	LCD_DisplayStringCODE
        MOV	A,#64+15
        CALL	LCD_GotoXY
        MOV	DPTR,#tkc_retrycounter
        MOVX	A,@DPTR
        INC	A
        ANL	A,#3
        MOVX	@DPTR,A
        MOV	DPTR,#tkc_retrylines
        MOVC	A,@A+DPTR
        CALL	LCD_WriteData
	CALL	PPG_CheckPricePlug
        MOV	R3,#2
        JMP	TKC_RSMwaitgrq

;******************************************************************************
;
; Function:	TKC_SendTSCFail
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

TKC_SendTSCFail:
        MOV	DPTR,#buffer			; got a TPI
        MOV	A,#MSG_TSC			; send back a TSC fail
        MOVX	@DPTR,A				; with id=0
        INC	DPTR				;
        CLR	A
        MOVX	@DPTR,A				;
        INC	DPTR
        MOVX	@DPTR,A				;
        MOV	DPTR,#buffer			;
        MOV	R7,#3				;
        CALL	RS485_TransmitPacket		;
	RET

;******************************************************************************
;
; Function:	TKC_Idle
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Called repeatedly during main loop idle state so that the PC gets an idle
;   response from the DT whenever possible and also so that the final TSD
;   acknowledge can be sent again, should the PC miss the original TSD.
;
;******************************************************************************

TKC_Idle:
	CALL	TKC_CheckTKCtrl
        JZ	TKC_Idone
	CALL	NET_ReceivePacket
        JNZ	TKC_Imsg
TKC_Idone:
        RET

TKC_Imsg:
        CJNE	A,#MSG_GRQ,TKC_Inotgrq
	MOV	DPTR,#buffer			; got a GRQ

	JNB	prt_paperout,TKT_IsendIDL
	MOV	A,#MSG_PI
	JMP	TKT_Isendmessage

TKT_IsendIDL:
	MOV	A,#MSG_IDL			; send an IDL

TKT_Isendmessage:
	MOVX	@DPTR,A				;
	MOV	R7,#1				;
	CALL	RS485_TransmitPacket		;
	RET					;

TKC_Inotgrq:
	CJNE	A,#MSG_TSD,TKC_Inottsd
	MOV	DPTR,#buffer+5			; got a TSD
	MOV	R7,#1				; send a TSD
        CALL	RS485_TransmitPacket		;
        RET					;

TKC_Inottsd:
	CJNE	A,#MSG_TPI,TKC_Inottpi		; got a TPI
        CALL	TKC_SendTSCFail			; send a TSC fail (id=0)
TKC_Inottpi:
	RET					; unknown message - ignore

;******************************************************************************
;
; Function:	TKC_InitiateTransaction
; Input:	None
; Output:	A=0=fail and abort transaction
;               A=1=ok, first ticket details cached ready for printing
; Preserved:	?
; Destroyed:	?
; Description:
;   Initiate a transaction yb waiting to be polled and passing the
;   transaction request to the PC. On failure, report error to user and
;   return error code indicating an aborted transaction. On success, cache
;   the details of the first ticket ready for printing.
;
;******************************************************************************

tkc_msg_whatblock:	DB 24,'Enter Block:     (OK=  )'
tkc_msg_tktctrlfail:	DB 24,'Ticket Controller Failed'
tkc_msg_tktctrlfail2:	DB 24,'  Report To Supervisor  '

TKC_InitiateTransaction:
	CALL	TKC_CheckTKCtrl			; check if we are running
        JNZ	TKC_ITusectrl			; in fail-safe or whether
        CLR	A
        MOV	DPTR,#tkc_seatrow
        MOVX	@DPTR,A
        MOV	DPTR,#tkc_seatcol
        MOVX	@DPTR,A
        MOV	DPTR,#tkc_seatblock
        MOVX	@DPTR,A
        MOV	A,#1				; we actually want to use
        RET					; the ticketing controller

TKC_ITusectrl:
	CALL	LCD_Clear2			; ask the user for the
        MOV	A,#64				; block number
        CALL	LCD_GotoXY			;
        MOV	DPTR,#tkc_msg_whatblock		;
        CALL	LCD_DisplayStringCODE		;
        MOV	DPSEL,#1
        MOV	DPTR,#buffer
        MOV	DPSEL,#0
        MOV	DPTR,#tkc_blockno
        MOV	R5,#2
        CALL	NUM_NewFormatDecimal16
        MOV	A,#64+21
        CALL	LCD_GotoXY
        MOV	DPTR,#buffer
        MOV	R7,#2
        CALL	LCD_DisplayStringXRAM
        MOV	R7,#3				;
        MOV	B,#64+13			;
        CALL	NUM_GetNumber			;
        JNZ	TKC_ITblockok			;
        RET					;

TKC_ITnoctrl:
	MOV	A,#1
        RET

TKC_ITblockok:
	MOV	A,mth_op1ll
        ORL	A,mth_op1lh
        JZ	TKC_ITuselastblock

	MOV	DPTR,#tkc_blockno		; save block number
        CALL	MTH_StoreWord			; for later use
TKC_ITuselastblock:

	MOV	DPSEL,#0

        MOV	DPTR,#tkt_subtot_current	; start at first item
        CLR	A				; in subtotal table
        MOVX	@DPTR,A				;

        MOV	A,#MSG_TSR			; setup the MSG_TSR
	MOV	DPTR,#tkc_currenttsr		;
        MOVX	@DPTR,A				;

        MOV	DPTR,#tkt_subtot_entries	; setup the itemcount
        MOVX	A,@DPTR				;
	MOV	DPTR,#tkc_currenttsr+1		;
	MOVX	@DPTR,A				;
	INC	DPTR				;

        MOV	DPTR,#tkc_fixture		; setup the fixture number
        CALL	MTH_LoadOp1Word			;
        MOV	DPTR,#tkc_currenttsr+2		;
        CALL	MTH_StoreWord			;

TKC_ITloop:
	MOV	DPSEL,#1
	MOV     DPTR,#tkt_subtot_entries        ; check if more entries
	MOVX    A,@DPTR                         ;
	MOV     B,A                             ;
	MOV     DPTR,#tkt_subtot_current        ;
	MOVX    A,@DPTR                         ;
	CJNE    A,B,TKC_ITmore                  ;
        JMP	TKC_ITflush
TKC_ITmore:
	CALL	TKT_LoadUpTicket
        MOV	DPTR,#tkt_issue_qty
        MOVX	A,@DPTR
        MOV	DPSEL,#0
        MOVX	@DPTR,A				; store the qty
        INC	DPTR
        MOV	DPSEL,#1
        MOV	DPTR,#tkt_type
        MOVX	A,@DPTR
        MOV	DPSEL,#0
        MOVX	@DPTR,A				; store the ticket type
        INC	DPTR
        MOV	DPSEL,#1
        CALL	TKT_TSCtrl
        MOVX	A,@DPTR
	ANL	A,#7
        MOV	DPSEL,#0
        MOVX	@DPTR,A				; store the zone
        INC	DPTR
        MOV	DPSEL,#1
        MOV	DPTR,#tkc_blockno
        MOVX	A,@DPTR
        MOV	DPSEL,#0
        MOVX	@DPTR,A				; store the block
        INC	DPTR
        MOV	DPSEL,#1
        MOV	DPTR,#tkt_groupqty
        MOVX	A,@DPTR
        MOV	DPSEL,#0
        MOVX	@DPTR,A				; store the groupqty
        INC	DPTR
        MOV	DPSEL,#1

        MOV	DPTR,#tkt_subtot_current
        MOVX	A,@DPTR
        INC	A
        MOVX	@DPTR,A
        JMP	TKC_ITloop

TKC_ITflush:
	CALL	COM_InitRS485
TKC_ITstartwaitpoll:
        MOV	R3,#100
TKC_ITwaitpoll:
        CALL	NET_ReceivePacket		; wait for a general
        JNZ	TKC_ITpolled			; request poll
        MOV	R0,#1
        CALL	delay100ms
        DJNZ	R3,TKC_ITwaitpoll
        CALL	SND_Warning
        IF USE_TIMEOUT = 0
         JMP	TKC_ITstartwaitpoll
        ENDIF
        JMP	TKC_NetworkFailure

TKC_ITpolled:
	CJNE	A,#MSG_GRQ,TKC_ITwaitpoll	;

        MOV	DPTR,#tkc_currenttsr+1		; send the tsr request
        MOVX	A,@DPTR				;
        MOV	B,#5				;
        MUL	AB				;
        INC	A				;
        INC	A				;
        INC	A				;
        INC	A				;
        MOV	R7,A				;
        MOV	DPTR,#tkc_currenttsr		;
        CALL	RS485_TransmitPacket		;
        JMP	TKC_GNTwaittpi			;

;******************************************************************************
;
; Function:	TKC_GetNextTicket
; Input:	A=1 if last ticket printed ok, else A=0
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

;test: DB 21,'ABCDEFGHIJKLMNOPQRSTU'

TKC_GetNextTicket:
	CALL	TKC_CheckTKCtrl			; check if we are running
        JNZ	TKC_GNTusectrl			; in fail-safe or whether
        MOV	A,#1				; we actually want to use
        RET					; the ticketing controller

TKC_GNTusectrl:
	MOV	DPTR,#tkt_printstatus
        MOVX	@DPTR,A
	CALL	COM_InitRS485
TKC_GNTstartwaittpi:
        MOV	R3,#100
TKC_GNTwaittpi:
	CALL	NET_ReceivePacket		; wait to be polled
        JNZ	TKC_GNTgotpkt			; with a TPI message
        MOV	R0,#1
        CALL	delay100ms
        DJNZ	R3,TKC_GNTwaittpi
        CALL	SND_Warning
        IF USE_TIMEOUT = 0
         JMP	TKC_GNTstartwaittpi
        ENDIF
        JMP	TKC_NetworkFailure

TKC_GNTgotpkt:
        CJNE	A,#MSG_TPI,TKC_GNTnottpi	;

    	MOV	DPTR,#tkc_itemno		; store the item number
        MOVX	A,@DPTR				; from the TSI in the
        MOV	DPTR,#buffer+1			; TSC message
        MOVX	@DPTR,A				;

        MOV	DPTR,#tkt_printstatus		; store the print status
        MOVX	A,@DPTR				; (A=1=ok, A=0=fail) in
        MOV	DPTR,#buffer+2			; the TSC message
        MOVX	@DPTR,A				;

        MOV	DPTR,#buffer			; in buffer and transmit
        MOV	A,#MSG_TSC			; the TSC status
        MOVX	@DPTR,A				;
        MOV	R7,#3				;
        CALL	RS485_TransmitPacket		;
        JNZ	TKC_GNTwaittpi			;
        RET

TKC_GNTnottpi:
        CJNE	A,#MSG_TSI,TKC_GNTnottsi

        MOV	DPTR,#buffer+6			; got a TSI, grab the
        MOVX	A,@DPTR				; item number for later use
        MOV	DPTR,#tkc_itemno		;
        MOVX	@DPTR,A				;

        MOV	DPTR,#buffer+7			; grab the seat row string
        CALL	MEM_SetSource			;
        MOVX	A,@DPTR				;
        INC	A				;
        MOV	R7,A				;
        MOV	DPTR,#tkc_seatrow		;
        CALL	MEM_SetDest			;
        CALL	MEM_CopyXRAMtoXRAMsmall		;

        MOV	DPH,srcDPH			; grab the seat col string
        MOV	DPL,srcDPL			;
        MOVX	A,@DPTR				;
        INC	A				;
        MOV	R7,A				;
        MOV	DPTR,#tkc_seatcol		;
        CALL	MEM_SetDest			;
        CALL	MEM_CopyXRAMtoXRAMsmall		;

        MOV	DPH,srcDPH			; grab the block name
        MOV	DPL,srcDPL			;
        MOVX	A,@DPTR				;
        INC	A				;
        MOV	R7,A				;
        MOV	DPTR,#tkc_seatblock		;
        CALL	MEM_SetDest			;
        CALL	MEM_CopyXRAMtoXRAMsmall		;

;       MOV	DPTR,#test
;       CALL	MEM_SetSource
;       MOV	DPTR,#tkc_seatblock
;       CALL	MEM_SetDest
;       MOV	R7,#22
;       CALL	MEM_CopyCODEtoXRAMsmall

        MOV	A,#1				; further ticket(s) to print
        RET

TKC_GNTnottsi:
	CJNE	A,#MSG_TSD,TKC_GNTnottsd	; got a TSD
        MOV	R7,#1				; send it back
        MOV	DPTR,#buffer+5			;
        CALL	RS485_TransmitPacket		;
        CLR	A				; ticket printing finished
        RET					;

TKC_GNTnottsd:
	CJNE	A,#MSG_TSF,TKC_GNTnottsf
        CALL	LCD_Clear			; got a TSF
        MOV	DPTR,#buffer+6			;
        MOV	R7,#24				;
        CALL	LCD_DisplayStringXRAM		;
        MOV	A,#64				;
        CALL	LCD_GotoXY
        MOV	DPTR,#buffer+6+24
        MOV	R7,#24
        CALL	LCD_DisplayStringXRAM
        CALL	SND_Warning			;
        CALL	KBD_WaitKey			;
        CLR	A				; ticket printing finished
        RET

TKC_GNTnottsf:
	JMP	TKC_GNTwaittpi

;******************************************************************************
;
; Function:	TKC_NetworkFailure
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

TKC_NetworkFailure:
        CALL	LCD_Clear
        MOV	DPTR,#tkc_msg_tktctrlfail
        CALL	LCD_DisplayStringCODE
        MOV	A,#64
        CALL	LCD_GotoXY
        MOV	DPTR,#tkc_msg_tktctrlfail2
        CALL	LCD_DisplayStringCODE
        CALL	KBD_WaitKey
        CLR	A
        RET

        ENDIF	; USE_TKTCTRL

;****************************** End Of TKTCTRL.ASM ****************************
