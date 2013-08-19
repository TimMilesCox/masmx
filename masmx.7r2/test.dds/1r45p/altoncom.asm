;******************************************************************************
;
; File     : ALTONCOM.ASM
;
; Author   : Tony Park
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
;******************************************************************************


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
	CALL	NET_ReceivePacket
	JNZ	TKC_Imsg
	RET

TKC_Imsg:
	CJNE	A,#MSG_CRT,TKC_Inotcrt

	MOV	DPTR,#buffer+6			; grab the date
	MOVX	A,@DPTR
	MOV	DPTR,#datebuffer
	MOVX	@DPTR,A
	MOV	DPTR,#buffer+7
	MOVX	A,@DPTR
	MOV	DPTR,#datebuffer+1
	MOVX	@DPTR,A

	MOV	DPTR,#buffer+8			; grab the time
	MOVX	A,@DPTR
	MOV	DPTR,#timebuffer
	MOVX	@DPTR,A
	MOV	DPTR,#buffer+9
	MOVX	A,@DPTR
	MOV	DPTR,#timebuffer+1
	MOVX	@DPTR,A

	MOV	DPTR,#buffer+10			; grab the expire hour
	MOVX	A,@DPTR
	PUSHACC
	CALL	TKT_ExpireHour
	POP	ACC
	MOVX	@DPTR,A

	MOV	DPTR,#buffer+11			; grab the expire minutes
	MOVX	A,@DPTR
	PUSHACC
	CALL	TKT_ExpireMinute
	POP	ACC
	MOVX	@DPTR,A

	MOV	DPTR,#buffer			; got a CRT
	MOV	A,#MSG_TKS			; send an TKS
	MOVX	@DPTR,A				;
	INC	DPTR                            ;
	MOV	A,alton_tktcount                ;
	MOVX	@DPTR,A                         ;
	MOV	R7,#2				;
	MOV	DPTR,#buffer			;
	CALL	RS485_TransmitPacket		;
	MOV	alton_tktcount,#0               ;
	RET

TKC_Inotcrt:
	MOV	A,#1
	RET
