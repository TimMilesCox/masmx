;******************************************************************************
;
; File     : RS485.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the serial communications code
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;       *****************************************************************
;       *       Tim     26viij99        *********************************
;       *****************************************************************
;       *       RS485_TIME_STAMP        *********************************
;       *       when asserted, append 1/16th-sec sys_tick to all xmit   *
;       *       packets, and include it in length and CRC               *
;       *****************************************************************

RS485_TIME_STAMP EQU    0



;******************************************************************************
;
; Function:     COM_InitRS485
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;
;******************************************************************************

COM_InitRS485:
	MOV     rs485_lastchar,#0
	clr     rs485_inpacket
	MOV     rs485_curpktlen,#0
	MOV     rs485_packets,#0
	MOV     rs485_startbuf,#0
	MOV     rs485_endbuf,#0
	RET

RS485_EnableReceive:
	IF VT10
	ORL     IEN2,#00000001b         ; enable serial 1 interrupt (SETB ES1)
	RET
	ELSE
	SETB    ES0                     ; enable serial 0 interrupt
	RET
	ENDIF

RS485_DisableReceive:
	IF VT10
	ANL     IEN2,#11111110b         ; disable serial 1 interrupt (CLR ES1)
	RET
	ELSE
	CLR     ES0                     ; disable serial 0 interrupt
	RET
	ENDIF

DLE EQU 175
STX EQU 174

RS485_BUFSIZE EQU 256

 ALIGN VAR,ToPage
rs485_buffer    VAR RS485_BUFSIZE ; the rs485 character buffer

AddCRCByte: ; R0=crcaddr, A=byte
	PUSHB
	MOV     B,A
	MOV     A,@R0
	ADD     A,B
	MOV     @R0,A
	INC     R0
	MOV     A,@R0
	ADDC    A,#0
	MOV     @R0,A
	DEC     R0
	POP     B
	RET

AddCRCBytes: ; DPTR=addr, R7=count, R0=crcaddr
	MOVX    A,@DPTR
	INC     DPTR
	CALL    AddCRCByte
	DJNZ    R7,AddCRCBytes
	RET


MTH_IncLongIRAM: ; R0=iramaddr
MTH_ILIinc:
	INC     @R0
	MOV     A,@R0
	JZ      MTH_ILIagain
	RET
MTH_ILIagain:
	INC     R0
	JMP     MTH_ILIinc




;**********************************************************************

RS485_Rx:
	PUSHPSW
	PUSHACC
	PUSHB
	PUSHDPH
	PUSHDPL
	MOV    A,R0
	PUSHACC

	IF VT10
	MOV     A,S1CON
	ANL     S1CON,#11111100b        ; Clear Tx + Rx Interrupt
	JB      ACC.1,RS485_Rtx2        ; ignore transmit interrupts
	ELSE
	JNB     RI0,RS485_Rtx2          ; ignore transmit interrupts 
	ENDIF

;       CALL    SYS_DisableInts

	IF VT10
	MOV     A,S1BUF
	ELSE
	MOV     A,S0BUF
	ENDIF
	MOV     rs485_ch,A


	MOV     B,#1                            ; insert = TRUE;

	CJNE    A,#DLE,RS485_Rnotdle            ; if (rs485_ch == DLE)
	MOV     A,rs485_lastchar                ; {
	CJNE    A,#DLE,RS485_Rlastnotdle        ;  if (rs485_lastchar == DLE)
	MOV     rs485_lastchar,#0               ;   rs485_lastchar = 0;
	JMP     RS485_Rdlestxok                 ;  else
RS485_Rtx2: JMP RS485_Rtx
RS485_Rlastnotdle:                              ;  {
	MOV     rs485_lastchar,#DLE             ;   rs485_lastchar = DLE;
	MOV     B,#0                            ;   insert = FALSE;
	JMP     RS485_Rdlestxok                 ;  }
						; }
RS485_Rnotdle:
	CJNE    A,#STX,RS485_Rdlestxok          ; if (rs485_ch == STX)
	MOV     A,rs485_lastchar                ; {
	CJNE    A,#DLE,RS485_Rdlestxok          ;  if (rs485_lastchar == DLE)
	MOV     B,#0                            ;  {
	MOV     A,rs485_curpktlen               ;   insert = FALSE;
	JZ      RS485_Rpktfinished              ;   if (rs485_curpktlen)
	MOV     R0,#rs485_rxerrors              ;   {
	CALL    MTH_IncLongIRAM                 ;    rs485_rxerrors++;
	MOV     rs485_endbuf,rs485_pktpos       ;    rs485_endbuf = rs485_pktpos;
RS485_Rpktfinished:                             ;   }
	CLR     A                               ;   rs485_curpktlen = 0;
	MOV     rs485_curpktlen,A               ;   rs485_actpktlen = 0;
	MOV     rs485_actpktlen,A               ;   rs485_inpacket = TRUE;
	setB    rs485_inpacket                  ;   rs485_pktpos = rsr85_endbuf;
	MOV     rs485_pktpos,rs485_endbuf       ;   rs485_lastchar = 0;
	MOV     rs485_lastchar,A                ;   rs485_flyingcrc = 0;
	MOV     rs485_flyingcrcl,A              ;  }
	MOV     rs485_flyingcrch,A              ; }

RS485_Rdlestxok:
	MOV     A,B                             ; if (insert && rs485_inpacket)
	JZ      RS485_Rnoinsert2                ; {
	jnb     rs485_inpacket,RS485_Rnoinsert2 ;  if (rs485_lastchar == DLE)
	MOV     A,rs485_lastchar                ;   rs485_rxerrors++;
	CJNE    A,#DLE,RS485_Rvalidch           ;   rs485_lastchar = 0;
	MOV     R0,#rs485_rxerrors              ;  }
	CALL    MTH_IncLongIRAM                 ; }
	MOV     rs485_lastchar,#0               ; else
	JMP     RS485_Rnoinsert                 ;
RS485_Rnoinsert2:
	JMP     RS485_Rnoinsert
RS485_Rvalidch:
	MOV     A,rs485_endbuf                  ; if (((rs485_endbuf +1) &
	INC     A                               ;  RS485_BUFSIZE-1) ==
	CJNE    A,rs485_startbuf,RS485_Rbufok   ;  rs485_startbuf)
	MOV     R0,#rs485_rxerrors              ; {
	CALL    MTH_IncLongIRAM                 ;   rxerrors++; /* buf full */
	MOV     B,#0                            ;   insert = FALSE;
	JMP     RS485_Rnoinsert                 ; }
RS485_Rbufok:                                   ; else {
	MOV     A,rs485_curpktlen               ;  switch (rs485_curpktlen)
	CJNE    A,#0,RS485_Rlennot0             ;  {
	
	$if     0
	MOV     rs485_actpktcrcl,rs485_ch       ;   case 0:
	$endif
	
	JMP     RS485_Rstore                    ;    rs485_actpktcrc = (UWORD)rs485_ch;
RS485_Rlennot0:                                 ;    break;
	CJNE    A,#1,RS485_Rlennot1             ;   case 1:
	
	$if     0
	MOV     rs485_actpktcrch,rs485_ch       ;    rs485_actpktcrc = (((UWORD)rs485_ch)<<8)+rs485_actpktcrc;
	$endif
	
	JMP     RS485_Rstore                    ;    break;
RS485_Rlennot1:                                 ;   case 2:
	CJNE    A,#2,RS485_Rlennot2             ;    rs485_actpktlen = rs485_ch;
	MOV     rs485_actpktlen,rs485_ch        ;    break;     
	JMP     RS485_Rstore                    ;   case 3:
RS485_Rlennot2:                                 ;    rs485_to = rs485_ch;
	CJNE    A,#3,RS485_Rstore               ;    if ((rs485_to != sys_mynode)
	MOV     rs485_to,rs485_ch               ;
	MOV     A,rs485_to                      ;      && (rs485_to != NODE_ID_ALLNODES)
	CJNE    A,sys_mynode,RS485_Rtryins      ;      && (rs485_to != NODE_ID_ALLTS)
	JMP     RS485_Rstore                    ;    {
RS485_Rtryins:                                  ;
						;     rs485_inpacket = FALSE;
						;    }
	CJNE    A,#NODE_ID_ALLNODES,RS485_Rtrytyp ;  break;
	JMP     RS485_Rstore
RS485_Rtrytyp:
	CJNE    A,#NODE_ID_ALLTS,RS485_Rwrongid ;
	JMP     RS485_Rstore                    ;
RS485_Rwrongid:                                 ;
	clr     rs485_inpacket                  ;
RS485_Rstore:                                   ;  }

	MOV     DPTR,#rs485_buffer              ;  rs485_buffer[rs485_endbuf++] = rs485_ch;
	MOV     DPL,rs485_endbuf                ;
	MOV     A,rs485_ch                      ;
	MOVX    @DPTR,A                         ;
	INC     rs485_endbuf                    ;  rs485_endbuf &= RS485_BUFSIZE - 1;
	MOV     A,B                             ;  if (insert)
	JZ      RS485_Rnoinsert2                ;  {
	INC     rs485_curpktlen;                ;   rs485_curpktlen++;
	MOV     A,rs485_curpktlen               ;   if (rs485_curpktlen > 2)
	CJNE    A,#2,RS485_Rcheckcrc            ;    addcrcbyte (rs485_flyingcrc,rs485_ch);
	JMP     RS485_Rnocrc                    ;
RS485_Rcheckcrc:                                ;
	JC      RS485_Rnocrc                    ;
	MOV     R0,#rs485_flyingcrcl            ;
	MOV     A,rs485_ch                      ;
	CALL    AddCRCByte                      ;

RS485_Rnocrc:
	MOV     A,rs485_curpktlen                 ; if (rs485_curpktlen ==
	CJNE    A,rs485_actpktlen,RS485_Rnoinsert ;   rs485_actpktlen)
	
	$if     0
	MOV     A,rs485_actpktcrcl                ;
	CJNE    A,rs485_flyingcrcl,RS485_Rcrcfail ; if (rs485_actpktcrc ==
	MOV     A,rs485_actpktcrch                ;   rs485_flyingcrc)
	CJNE    A,rs485_flyingcrch,RS485_Rcrcfail ;
	$endif
	
	INC     rs485_packets                   ;    rs485_packets++;
	JMP     RS485_Rnopacket                 ;   else
RS485_Rcrcfail:                                 ;   {
	MOV     R0,#rs485_rxerrors              ;     rs485_rxerrors++;
	CALL    MTH_IncLongIRAM                 ;     rs485_endbuf = rs485_pktpos;
	MOV     rs485_endbuf,rs485_pktpos       ;   }
RS485_Rnopacket:
	clr     rs485_inpacket                  ;   rs485_inpacket = FALSE;
	MOV     rs485_curpktlen,#0              ;   rs485_curpktlen = 0;
	MOV     rs485_lastchar,#0               ;   rs485_lastchar = 0;
RS485_Rnoinsert:
;       CLR     RI0
;       CALL    SYS_EnableInts
RS485_Rtx:

; MOV DPTR,#08000h
; MOV A,#000h
; MOVX @DPTR,A
	POP     ACC
	MOV     R0,A
	POP     DPL
	POP     DPH
	POP     B                               ;
	POP     ACC                             ;
	POP     PSW                             ;
	RETI                                    ;

RS485_RxChar:
	MOV     A,rs485_endbuf
	CJNE    A,rs485_startbuf,RS485_RCbufok
	CLR     C
	RET
RS485_RCbufok:
	PUSHDPH
	PUSHDPL
	MOV     DPTR,#rs485_buffer
	MOV     DPL,rs485_startbuf
	MOVX    A,@DPTR
	INC     rs485_startbuf
	SETB    C
	POP     DPL
	POP     DPH
	RET

RS485_ReceivePacket: ;DPTR=packet
	MOV     A,rs485_packets
	JZ      RS485_RPnopkts
	DEC     rs485_packets

	PUSHDPH
	PUSHDPL

	MOV     R7,#5
RS485_RPloop1:
	CALL    RS485_RxChar
	JNC     RS485_RPnopkts2
	MOVX    @DPTR,A
	INC     DPTR
	DJNZ    R7,RS485_RPloop1
	POP     DPL                     ; Reload DPTR
	POP     DPH
	INC     DPTR
	INC     DPTR
	MOVX    A,@DPTR                 ; Move Length into A
	CLR     C
	SUBB    A,#5                    ; Subract header
	MOVX    @DPTR,A
	INC     DPTR
	INC     DPTR
	INC     DPTR

	MOV     R7,A
RS485_RPloop2:
	CALL    RS485_RxChar
	JNC     RS485_RPnopkts
	MOVX    @DPTR,A
	INC     DPTR
	DJNZ    R7,RS485_RPloop2

	MOV     A,#1
	RET
RS485_RPnopkts2:
	POP     DPL
	POP     DPH
RS485_RPnopkts:
	CLR     A
	RET

;/*******************************************************************************
;
;        R S 4 8 5   T r a n s m i t   R o u t i n e s
;
;*******************************************************************************/

MYNODE EQU 1
MASTERNODE EQU 0

;DPTR=data, R7=len

RS485_TransmitPacket:

;       ***************************************************************
;       *       Tim     26viij99        ***********Start***************
;       ***************************************************************
;       *       append timestamp (approx 15th sec) to packet          *
;       ***************************************************************

	IF      RS485_TIME_STAMP
	mov     a,sys_tick
	cjne    a,#DLE,RS485_NotAnotherDLE
	mov     a,#DLE-1        ; an approximation is adequate
RS485_NotAnotherDLE:
	pushacc                 ; save it to append to the packet
	mov     rs485_txcrcl,a  ; and prime the CRC with it
	ENDIF

;       ***************************************************************
;       *       Tim     26viij99        **************End**************
;       ***************************************************************

	PUSHDPH
	PUSHDPL
	MOV     A,R7
	PUSHACC

	IF VT10
	ANL     IEN2,#11111110b         ; disable serial 1 interrupt (CLR ES1)
	ELSE
	ANL     P6,#0F7h                ; CLR P6.3 => enable rs485 tx
	CLR     REN0                    ; disable rx
	ENDIF

;       ***************************************************************
;       *       Tim     26viij99        **Lower CRC is already set*****
;       ***************************************************************

	IF      RS485_TIME_STAMP EQ 0
	MOV     rs485_txcrcl,#0         ; clear transmit crc
	ENDIF

	MOV     rs485_txcrch,#0         ;

	MOV     A,R7                    ; set "len" = len+headerlen


;       ***************************************************************
;       *       Tim     26viij99        * include the timestamp       *
;       ***************************************************************

	IF      RS485_TIME_STAMP
	add     a,#6
	ELSE
	ADD     A,#5                    ;
	ENDIF

	MOV     rs485_txlen,A           ;

	MOV     rs485_txto,#MASTERNODE  ; set "to"
	MOV     rs485_txfrom,sys_mynode ; set "from"

	MOV     R0,#rs485_txcrcl
	MOV     A,rs485_txlen
	CALL    AddCRCByte
	MOV     A,rs485_txto
	CALL    AddCRCByte
	MOV     A,rs485_txfrom
	CALL    AddCRCByte

	POP     ACC
	MOV     R7,A
	POP     DPL
	POP     DPH

	PUSHDPH
	PUSHDPL
	MOV     A,R7
	PUSHACC

	CALL    AddCRCBytes             ; add len data bytes to crc

	MOV     B,#COM_COM0             ; transmit a DLE

	MOV     A,#DLE                  ;
	CALL    COM_TxChar              ;

	MOV     A,#STX                  ; transmit a STX
	CALL    COM_TxChar              ;

	MOV     R0,#rs485_txcrcl        ; transmit the header
	MOV     R7,#5                   ; (duplicate any DLEs)
RS485_TPhloop:                          ;
	MOV     A,@R0                   ;
	INC     R0                      ;
	CJNE    A,#DLE,RS485_TPhnotdle  ;
	CALL    COM_TxChar              ;
	MOV     A,#DLE                  ;
RS485_TPhnotdle:                        ;
	CALL    COM_TxChar              ;
	DJNZ    R7,RS485_TPhloop        ;

	POP     ACC
	MOV     R7,A
	POP     DPL
	POP     DPH

RS485_TPdloop:                          ; transmit the data
	MOVX    A,@DPTR                 ; (duplicate any DLEs)
	INC     DPTR                    ;
	CJNE    A,#DLE,RS485_TPdnotdle  ;
	CALL    COM_TxChar              ;
	MOV     A,#DLE                  ;
RS485_TPdnotdle:                        ;
	CALL    COM_TxChar              ;
	DJNZ    R7,RS485_TPdloop        ;

;       **************************************************************
;       *       Tim     26viij99        *********Start****************
;       **************************************************************
;       *       append timestamp (approx 15th second) to packet      *
;       **************************************************************

	IF      RS485_TIME_STAMP
	pop     acc
	call    COM_TxChar
	ENDIF

;       **************************************************************
;       *       Tim     26viij99        *********End******************
;       **************************************************************


	IF VT10
	ANL     S1CON,#11111100b        ; Clear Tx + Rx Interrupt
	ORL     IEN2,#00000001b         ; enable serial 1 interrupt (SETB ES1)
	ELSE
	ORL     P6,#8                   ; disable rs485 tx (SETB P6.3)
	CLR     RI0                     ; lose any bytes that came in
	SETB    REN0                    ; re-enable rx
	ENDIF

	RET

;msg_gotpacket: DB 12,'Got Packet',13,10
;RS485_Test:
;       MOV     DPTR,#buffer
;       CALL    RS485_ReceivePacket
;       JZ      RS485_Tnopkt
;
;        MOV     A,#1
;        MOV     B,#70
;        CALL    SND_Beep
;
;       MOV     B,#COM_COM1
;       MOV     DPTR,#msg_gotpacket
;       CALL    COM_TxStrCODE
;RS485_Tnopkt:
;       RET
;****************************** End Of RS485.ASM *******************************
;



