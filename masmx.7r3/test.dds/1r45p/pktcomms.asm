;******************************************************************************
;
; File     : PKTCOMMS.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for handling packet communications
;            using the rs232 code in COMMS.ASM
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;
; Notes:
; 1) Requires a byte 'com_retries' to be declared in internal RAM.
; 2) Requires a bit 'com_firstpacket' to be declared in internal RAM bitspace.
; 3) Requires a bit 'com_multipacket' to be declared in internal RAM bitspace.
;
;******************************************************************************

COM_MAX_RETRIES	EQU	3
COM_MAX_PACKET	EQU	128
COM_MULTIBIT	EQU	64 ; bit mask of where the multipacket bit is

COM_PKT_DUFF	EQU	1 ; error when packet checksum bad or rx timeout
COM_PKT_DUP	EQU	2 ; error when we get the same packet again
COM_PKT_OK	EQU	3 ; success
COM_PKT_HDR	EQU	4 ; success, packet is a multipacket header

COM_TIMEOUT1	EQU 	5 ; 0.5sec timeout for all received chars except 1st
COM_TIMEOUT2	EQU    10 ; 1sec timeout on first char of packet

com_rxcheck	VAR	2 ; RX: received checksum in packet header

com_calccheck	VAR	2 ; flying checksum calculated by ReceiveSmallPacket

com_rxlen	VAR	1 ; length as received by ReceiveSmallPacket
com_newrxpacket	VAR	1 ; new packet number as received by ReceiveSmallPacket
com_oldrxpacket	VAR	1 ; old packet number as received by ReceiveSmallPacket

com_txpacket	VAR	1 ; packet number of transmitter's packet - transmitter
			  ; needs to see an acknowledge with this number in it

; prototypes
;PSW.C	COM_GetAndCheck		(DPTR buffer, B port, R7 chars);
;void	COM_SendAcknowledge	(B port);
;ACC	COM_ReceiveSmallPacket	(DPTR buffer, B port);
;PSW.C	COM_ReceivePacket	(DPTR buffer, B port);

;*******************************************************************************

COM_InitPacketComms:
	MOV	DPTR,#com_oldrxpacket		; ensure we don't falsely
        MOV	A,#255				; believe the 1st packet we
        MOVX	@DPTR,A				; receive to be a duplicate

        MOV	DPTR,#com_txpacket		; 1st packet we transmit
        CLR	A				; will be packet number 0
        MOVX	@DPTR,A				;
	RET

COM_TxSlash:
	PUSHACC
        MOV	A,#'\'
        CALL	COM_TxChar
        POP ACC
	RET

COM_SafeTxChar:
	CJNE	A,#'\',COM_STCnotslash
        CALL	COM_TxSlash
        JMP	COM_STCchar
COM_STCnotslash:
	CJNE	A,#'s',COM_STCnots
        CALL	COM_TxSlash
        JMP	COM_STCchar
COM_STCnots:
	CJNE	A,#'t',COM_STCnott
        CALL	COM_TxSlash
COM_STCnott:
COM_STCchar:
	CALL	COM_TxChar
	RET

;******************************************************************************
;
;                  P a c k e t   R e c e i v e   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	COM_GetAndCheck
; Input:	DPTR=address of buffer to fill
;               R7=number of bytes to fetch
;               B=serial port
; Output:	C=1=ok, C=0=timeout before all chars read
; Preserved:	B
; Destroyed:	A,R0-2,R5,R7
; Description:
;   Gets the specified number of characters, tallying a flying checksum as it
;   goes. Fails if any character times out. Removes any preceeding slashes.
;
;******************************************************************************

COM_GetAndCheck:
COM_GACloop:					; get next char, if its
	MOV	R5,#COM_TIMEOUT1		; a slash, ignore it and
        CALL	COM_RxCharTimeout		; get the next char again
        JNC	COM_GACduff			;
        CJNE	A,#'\',COM_GACcharok		;
	MOV	R5,#COM_TIMEOUT1		;
        CALL	COM_RxCharTimeout		;
        JNC	COM_GACduff			;
COM_GACcharok:
	MOVX	@DPTR,A				; store char in buffer
        INC	DPTR				;
        CALL	MTH_LoadOp2Acc			;
	MOV	A,R7				;
        PUSHACC					;
        PUSHDPH					; update the flying checksum
        PUSHDPL					;
        PUSHB					;
        MOV	DPTR,#com_calccheck		;
        CALL	MTH_LoadOp1Word			;
        CALL	MTH_AddWords			;
        MOV	DPTR,#com_calccheck		;
        CALL	MTH_StoreWord			;
        POP	B				;
        POP	DPL				;
        POP	DPH				;
        POP	ACC				;
        MOV	R7,A				;

        DJNZ	R7,COM_GACloop			; repeat for all chars
        SETB	C				; return success
        RET					;

COM_GACduff:					; return fail - timeout
	CLR	C				;
        RET					;

;******************************************************************************
;
; Function:	COM_SendAcknowledge
; Input:	B=serial port
; Output:	?
; Preserved:	B
; Destroyed:	A,DPTR
; Description:
;   Sends a packet with the bytes 128,<newpacket>,0,128
;
;******************************************************************************

COM_SendAcknowledge:
	MOV	A,#128
        CALL	COM_TxChar
        MOV     DPTR,#com_newrxpacket
        MOVX    A,@DPTR
        CALL	COM_TxChar
        CLR	A
        CALL	COM_TxChar
        MOV	A,#128
        CALL	COM_TxChar
	RET

;******************************************************************************
;
; Function:	COM_ReceiveSmallPacket
; Input:	DPTR=address of where to store small packet
;               B=serial port to use
; Output:	A=result (DUFF, DUP, OK, or HDR)
; Preserved:	?
; Destroyed:	A,DPTR,R0-2,5,R7
; Description:
;   Waits for a 'start sequence' in the input stream (fail on timeout). It then
;   waits to receive the whole packet (fail on timeout). If the checksum is
;   bad, it returns DUFF, else it sends back an acknowledge and returns HDR or
;   OK depending on if its a multipacket header or not.
;
;******************************************************************************

COM_RSPdufflong: JMP COM_RSPduff	; LONG jump to RSPduff

COM_ReceiveSmallPacket:
	PUSHDPH
        PUSHDPL
COM_RSPloop:
	MOV	R5,#COM_TIMEOUT2 		; wait for the start
	CALL	COM_RxCharTimeout		; sequence 'st'
        JNC	COM_RSPdufflong			;
        CJNE	A,#'\',COM_RSPnotslash		; dont fall for \s\t
        MOV	R5,#COM_TIMEOUT1		;
        CALL	COM_RxCharTimeout		; timeout if any char
        JNC	COM_RSPdufflong			; fails to come in on time
        JMP	COM_RSPloop			;
COM_RSPnotslash:				;
	CJNE	A,#'s',COM_RSPloop		;
	MOV	R5,#COM_TIMEOUT1		;
        CALL	COM_RxCharTimeout		;
        JNC	COM_RSPdufflong			;
        CJNE	A,#'t',COM_RSPloop		;

        MOV	DPTR,#com_rxcheck		; pull in the checksum
        MOV	R7,#2				; from the packet header
        CALL	COM_GetAndCheck			;
        JNC	COM_RSPduff			;

        MOV	DPTR,#com_calccheck		; reset calccheck
        CLR	A				;
        CALL	MTH_LoadOp1Acc			;
        CALL	MTH_StoreWord			;

	MOV	DPTR,#com_rxlen			; pull in the
        MOV	R7,#2				; length and newpacket
        CALL	COM_GetAndCheck			; values from the packet
        JNC	COM_RSPduff			; header

        MOV	DPTR,#com_rxlen			; pull in the rest
        MOVX	A,@DPTR				; of the packet
        MOV	R7,A				;
        POP	DPL				;
        POP	DPH				;
	CALL	COM_GetAndCheck			;
        JNC	COM_RSPduff2			;
	MOV	DPTR,#com_rxcheck		; fail if the two checksums
        CALL	MTH_LoadOp1Word			; do not match
        MOV	DPTR,#com_calccheck		;
        CALL	MTH_LoadOp2Word			;
        PUSHB					;
	CALL	MTH_CompareWords		;
        POP	B				;
        JZ      COM_RSPduff2			;

        MOV	com_retries,#COM_MAX_RETRIES	; reset retries and
        CALL	COM_SendAcknowledge		; send acknowledge

        PUSHB
        MOV	DPTR,#com_newrxpacket		; if its the same packet
        MOVX	A,@DPTR				; return PKT_DUP
        MOV	B,A				; else
        MOV	DPTR,#com_oldrxpacket		;
        MOVX	A,@DPTR				;
        CJNE	A,B,COM_RSPnotdup		;
        POP	B
        MOV	A,#COM_PKT_DUP			;
        RET					;
COM_RSPnotdup:					;
	MOV	A,B				; oldrxpacket = newrxpacket
        MOVX	@DPTR,A				;
        ANL	A,#COM_MULTIBIT			;
        JZ	COM_RSPok			;
        POP	B				;
        MOV	A,#COM_PKT_HDR			;
        RET					; return PKT_HDR
COM_RSPok:					; or
	POP	B				;
	MOV	A,#COM_PKT_OK			; return PKT_OK
	RET					;

COM_RSPduff:					; return PKT_DUFF
	POP	DPL				; (jumped to from various
	POP	DPH				;  points in this function)
COM_RSPduff2:					;
	MOV	A,#COM_PKT_DUFF			;
	RET


;******************************************************************************
;
; Function:	COM_ReceivePacket
; Input:	DPTR=address of where to store packet
;               B=serial port
; Output:	C=1=valid packet in buffer, C=0=error or timeout
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

COM_NewReceivePacket:
	MOV	com_retries,#COM_MAX_RETRIES
        SETB	com_firstpacket
        CLR	com_multipacket
        MOV	R3,#1				; parts = 1

COM_RPretryloop:
	PUSHDPH
        PUSHDPL
	CALL	COM_ReceiveSmallPacket
        POP	DPL
        POP	DPH
        CJNE	A,#COM_PKT_DUFF,COM_RPnotduff
;******
;* DUFF
;******
	MOV	A,com_retries
        JZ	COM_RPfail
        DEC	com_retries
	JMP	COM_RPrepeat
COM_RPnotduff:
	CJNE	A,#COM_PKT_HDR,COM_RPnothdr
;****
; HDR
;****
	JNB	com_multipacket,COM_RPnotmulti
        JMP	COM_RPfail
COM_RPnotmulti:
	SETB	com_multipacket
        PUSHDPH
        PUSHDPL
        MOVX	A,@DPTR
        MOV	R4,A				; R4=firstlen
        INC	DPTR
        MOVX	A,@DPTR
        INC	A
        MOV	R3,A				; r3=parts
        POP	DPL
        POP	DPH
        JMP	COM_RPrepeat

COM_RPnothdr:
	CJNE	A,#COM_PKT_OK,COM_RPnotok
;***
; OK
;***
	DEC	R3
        JB	com_firstpacket,COM_RPfirst
        MOV	A,#COM_MAX_PACKET
        JMP	COM_RPnextaddr
COM_RPfirst:
	MOV	A,R4
COM_RPnextaddr:
	CALL	AddAtoDPTR
        CLR	com_firstpacket
COM_RPnotok:
COM_RPrepeat:
	MOV	A,R3
	JZ	COM_RPdone
	JMP	COM_RPretryloop
COM_RPdone:
	SETB	C
        RET
COM_RPfail:
	CLR	C
        RET

;******************************************************************************
;
;               P a c k e t   T r a n s m i t   R o u t i n e s
;
;******************************************************************************

;******************************************************************************
;
; Function:	COM_ReceiveAcknowledge
; Input:	B=serial port
;               R4=txpacketnum
; Output:	C=1=received acknowledge. C=0=fail
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

COM_ReceiveAcknowledge:
	MOV	R5,#COM_TIMEOUT1		; look for 128
	CALL	COM_RxCharTimeout		;
	JNC	COM_RAfail			;
	CJNE	A,#128,COM_RAfail		;

	MOV	R5,#COM_TIMEOUT1		; look for txpacketnum
	CALL	COM_RxCharTimeout		;
	JNC	COM_RAfail			;
	CLR	C				;
	SUBB	A,R4				;
	JNZ	COM_RAfail			;

	MOV	R5,#COM_TIMEOUT1		; look for 0
	CALL	COM_RxCharTimeout		;
	JNC	COM_RAfail			;
	CJNE	A,#0,COM_RAfail			;

	MOV	R5,#COM_TIMEOUT1		; look for 128
	CALL	COM_RxCharTimeout		;
	JNC	COM_RAfail			;
	CJNE	A,#128,COM_RAfail		;

	SETB	C
	RET
COM_RAfail:
	CLR	C
	RET

;******************************************************************************
;
; Function:	COM_SendSmallPacket
; Input:	DPTR=address of data to transmit as a packet
;               R7=length of data
;               B=serial port
;               R6=0=non-headerpacket, R6=64=headerpacket
; Output:	C=1=packet received, C=0=fail or timeout
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

COM_SendSmallPacket:
	MOV	A,R4
        PUSHACC
	PUSHDPH
	PUSHDPL

	MOV	DPTR,#com_txpacket		; set txpacketnum in R4
	MOVX	A,@DPTR				;
	ADD	A,R6				;
	MOV	R4,A				;
	POP     DPL
	POP     DPH

	PUSHDPH
	PUSHDPL
	PUSHB
	MOV	A,R7
	PUSHACC

	MOV	R6,#0				; calculate checksum
	CALL	CRC_ComputeChecksum		; leave checksum in mth_op1
	POP     ACC
	PUSHACC ; A=len from stack
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddWords			;
	MOV	A,R4				;
	CALL	MTH_LoadOp2Acc			;
	CALL	MTH_AddWords			;
	POP	ACC
	MOV	R7,A
	POP	B
	POP	DPL
	POP	DPH

	PUSHDPH
	PUSHDPL
	MOV	DPTR,#com_txpacket		; txpacket = (txpacket+1)%64
	MOVX	A,@DPTR				;
	INC	A				;
	ANL	A,#63				;
	MOVX	@DPTR,A				;
	POP	DPL
	POP	DPH

	MOV	com_retries,#COM_MAX_RETRIES
COM_SSPloop:
	CALL	COM_Flush			; flush buffer and
	MOV	A,#'s'				; send packet start header
	CALL	COM_TxChar			;
	MOV	A,#'t'				;
	CALL	COM_TxChar			;

	MOV	A,mth_op1ll			; send check low byte
	CALL	COM_SafeTxChar			;
	MOV	A,mth_op1lh			; send check high byte
	CALL	COM_SafeTxChar			;
	MOV	A,R7				; send length byte
	CALL	COM_SafeTxChar			;
	MOV	A,R4				; send txpacketnum
	CALL	COM_SafeTxChar			;

	MOV	A,R7				; skip packet data if
	JZ	COM_SSPack			; length zero
	PUSHDPH					; send packet data
	PUSHDPL					;
	MOV	A,R7				;
	MOV	R6,A				;
COM_SSPdataloop:				;
	MOVX	A,@DPTR				;
	INC	DPTR				;
	CALL	COM_SafeTxChar			;
	DJNZ	R6,COM_SSPdataloop		;
	POP	DPL				;
	POP	DPH				;

COM_SSPack:
	CALL	COM_ReceiveAcknowledge		; look for acknowledge
	JC	COM_SSPdone			; return success if we get it

	MOV	A,com_retries			; check for retries
	JZ	COM_SSPfail			; return fail if we have
	DEC	com_retries			; exhausted our retries, else
	JMP	COM_SSPloop			; jump back and retry packet

COM_SSPdone:
	POP	ACC
	MOV	R4,A
	SETB	C
	RET

COM_SSPfail:
	POP	ACC
	MOV	R4,A
	CLR	C
	RET

;******************************************************************************
;
; Function:	COM_SendPacket
; Input:	DPTR=address of data to transmit as packet(s)
;               B=serial port
;               R6/R7 = length (R6 high, R7 low)
; Output:	C=1=data transmitted and acknowledged
;               C=0=fail
; Preserved:	?
; Destroyed:	?
; Description:
;   Transmits the specified data to the specified serial port as a packet or a
;   number of sub-packets, acknowledging each sub-packet transfer.
;
;******************************************************************************


COM_NewSendPacket:
	PUSHB					; work out if the data
	MOV	mth_op1ll,R7			; can be sent as one
	MOV	mth_op1lh,R6			; packet or if it has to
	MOV	mth_op2ll,#LOW(COM_MAX_PACKET)	; be split into multipackets
	MOV	mth_op2lh,#HIGH(COM_MAX_PACKET)	;
	CALL	MTH_TestGTWord			;
	JC	COM_SPlarge			;
	POP	B

	MOV	R7,mth_op1ll			; just send one packet
	JMP	COM_SendSmallPacket		;

COM_SPlarge:
	MOV	A,#1				; Calculate:
	CALL	MTH_LoadOp2Acc			; parts=(len-1)/MAX_PKT
	CALL	MTH_SubWords			; firstlen=len-(parts*MAX_PKT)

	MOV	mth_op2ll,#LOW(COM_MAX_PACKET)	;
	MOV	mth_op2lh,#HIGH(COM_MAX_PACKET)	;
	MOV	mth_op1hl,#0			;
	MOV	mth_op1hh,#0			;
	CALL	MTH_Divide32by16		;
	MOV	R3,mth_op1ll			; R3=parts
	MOV	R4,mth_op2ll			;
	INC	R4				; R4=firstlen
	POP	B

	PUSHDPH					; send multipacket header
	PUSHDPL					;
	MOV	DPTR,#buffer			;
	MOV	A,R4				;
	MOVX	@DPTR,A				;
	INC	DPTR				;
	MOV	A,R3				;
	MOVX	@DPTR,A				;
	MOV	DPTR,#buffer			;
	MOV 	R6,#64				;
	MOV	R7,#2				;
	CALL	COM_SendSmallPacket		;
	POP	DPL				;
	POP	DPH				;
	JNC	COM_SPfail			;

	MOV	A,R4
	MOV	R7,A				; send first packet
	MOV	R6,#0				;
	CALL	COM_SendSmallPacket		;
	JNC	COM_SPfail			;

	MOV	A,R4				; send remaining packets
	CALL	AddAtoDPTR			;
COM_SPloop:					;
	MOV	R7,#COM_MAX_PACKET		;
	MOV	R6,#0				;
	CALL	COM_SendSmallPacket		;
	JNC	COM_SPfail			;
	MOV	A,#COM_MAX_PACKET		;
	CALL	AddAtoDPTR			;
	DJNZ	R3,COM_SPloop			;

	SETB	C				; return success
	RET					;

COM_SPfail:					; return fail
	CLR	C				;
	RET					;



;**************************** End Of PKTCOMMS.ASM *****************************
