;******************************************************************************
;
; File     : COMMS.ASM
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
; Notes    :
;   1. Currently, serial port 0 is interrupt buffered on receive only.
;   2. Serial port 1 is fully unbuffered.
;   3. No serial port 1 mux a/b code exists, although the port can be
;      switched via a " CPL com_selab, CALL SBS_WriteSB1 "
;
;******************************************************************************
;
; COMMS - Quick Calling Guide
;
; Function            Input      Output  Destroyed
; COM_TxChar          B,A                A
; COM_TxStr           B,DPTR,R7          A,DPTR
; COM_RxChar          B          C,A
; COM_RxCharWait      B          A
; COM_RxCharTimeout   B,R5       C,A     R0-2/5
; COM_Test            B          A       DPTR
; COM_Flush           B                  A
;
;******************************************************************************

COM_COM0	EQU 0			; identifier for COM0
COM_COM1	EQU 1			; identifier for COM1
COM_COM1bit	EQU B.0
COM_COM2	EQU 2			; identifier for COM2
COM_COM2bit	EQU B.1

com_pkt_type:	VAR 1			; general purpose comms packet
com_pkt_len:	VAR 2			;
com_pkt_crc:	VAR 2			;
com_pkt_data:	VAR 512			;

 ALIGN VAR,ToPage
	IF USE_RS485
	ELSE
com_ser0buffer: VAR 256			; 256 byte buffers for
com_tx0buffer: VAR 256
	ENDIF
com_ser1buffer: VAR 256			; serial port 0 and 1

	IF USE_SERVANT
com_status_buffer: VAR 20
	ENDIF

	IF USE_RS485
	ELSE
com_ser0buflen: VAR 1			;
com_ser0bufptr: VAR 1			;
com_tx0buflen: VAR 1			;
com_tx0bufptr: VAR 1			;
	ENDIF
com_ser1buflen: VAR 1			;
com_ser1bufptr: VAR 1			;


;******************************************************************************
;
; Function:	COM_InitSerial
; Input:	None
; Output:	None
; Preserved:	R0-7,B
; Destroyed:	A,DPTR
; Description:
;   Sets up both serial ports at 9600 baud, clear their buffers and enable
;   their interrupts.
;
;******************************************************************************

COM_InitSerial:
	IF VT10

	MOV	S1CON,#090h		; serial port 1, mode B, rx enabled
	MOV	S1REL,#0D9h		; serial port 1, baud 9615 approx.
        CALL	COM_DefaultSerialMux	;
	CLR	A			; empty serial 1 circular buffer
	MOV	DPTR,#com_ser1buflen	;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOVX	@DPTR,A			;
	ORL	IEN2,#00000001b		; enable serial 1 interrupt (SETB ES1)

	; Setup Uart A
	mov	DPTR,#00083h	; LCR
	mov	A,#10000111b	; D7 = 1 : enable access to baud
				;          rate divisors
				; D6 = 0 : break off
				; D5 = 0 : disable sticky parity bit
				; D4 = 0 : not used
				; D3 = 0 : disable parity
				; D2 = 1 : 2 stop bits
				; D1,D0 = 11 : 8 data bits
	movx	@DPTR,A

	mov	DPTR,#00080h	; DLL (LSB divisor)
	mov	A,#00ch
	movx	@DPTR,A
	inc	DPTR		; DLM (MSB divisor)
	mov	A,#000h
	movx	@DPTR,A		; 000ch = 9600 baud

	mov	DPTR,#00083h	; LCR
	mov	A,#00000111b	; D7 = 0 : disable access to divisors
	movx	@DPTR,A

	mov	DPTR,#00084h	; MCR
	mov	A,#00000000b
	movx	@DPTR,A

	mov	DPTR,#00082h	; FCR
	mov	A,#00000011b	; D0 = 1 ie. FIFO enabled
					; D1 = 1 ie. clear RX FIFO
	movx	@DPTR,A

	mov	DPTR,#00081h	; IER
	mov	A,#00000000b	; clear interrupt enables
	movx	@DPTR,A

	; Setup Uart B

	mov	DPTR,#000c3h	; LCR
	mov	A,#10000111b	; D7 = 1 : enable access to baud
				;          rate divisors
				; D6 = 0 : break off
				; D5 = 0 : disable sticky parity bit
				; D4 = 0 : not used
				; D3 = 0 : disable parity
				; D2 = 1 : 2 stop bits
				; D1,D0 = 11 : 8 data bits
	movx	@DPTR,A

	mov	DPTR,#000c0h	; DLL (LSB divisor)
	mov	A,#00ch
	movx	@DPTR,A
	inc	DPTR		; DLM (MSB divisor)
	mov	A,#000h
	movx	@DPTR,A		; 000ch = 9600 baud

	mov	DPTR,#000c3h	; LCR
	mov	A,#00000111b	; D7 = 0 : disable access to divisors
	movx	@DPTR,A

	mov	DPTR,#000c4h	; MCR
	mov	A,#00000000b
	movx	@DPTR,A
	mov	DPTR,#000c2h	; FCR
	mov	A,#00000011b	; D0 = 1 ie. FIFO enabled
				; D1 = 1 ie. clear RX FIFO
	movx	@DPTR,A

	mov	DPTR,#000c1h	; IER
	mov	A,#00000000b	; clear interrupt enables

	movx	@DPTR,A

	MOV	DPTR,#00084h
	MOV	A,#00001000b
	MOVX	@DPTR,A


	MOV	DPTR,#000C4h
	MOV	A,#00001000b
	MOVX	@DPTR,A





	RET

	



	ELSE

	MOV	S0CON,#050h		; serial port 0, mode 1, rx enabled
	ORL	ADCON0,#080h		; serial port 0, dedicated baud gen.
	ORL	PCON,#080h		; serial port 0, 9600 baud
	MOV	S1CON,#090h		; serial port 1, mode B, rx enabled
	MOV	S1REL,#0D9h		; serial port 1, baud 9615 approx.
        CALL	COM_DefaultSerialMux	;
	ENDIF

	IF USE_RS485
	ELSE
	CLR	A			; empty serial 0 circular buffer
	MOV	DPTR,#com_ser0buflen	;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOVX	@DPTR,A			;
	MOV	DPTR,#com_tx0buflen	;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOVX	@DPTR,A			;
	ENDIF

	CLR	A			; empty serial 1 circular buffer
	MOV	DPTR,#com_ser1buflen	;
	MOVX	@DPTR,A			;
	INC	DPTR			;
	MOVX	@DPTR,A			;

;;;	SETB	ES0			; enable serial 0 interrupt
;;;only enabled when needed
	ORL	IEN2,#1			; enable serial 1 interrupt (SETB ES1)
	RET

;******************************************************************************
;
; Function:	COM_TxChar
; Input:	A = char to transmit
;               B = serial port to transmit on
; Output:	?
; Preserved:	All
; Destroyed:	None
; Description:
;   Sends the specified character up the specified serial port.
;
;******************************************************************************

COM_TxChar:
	IF VT10
	JB	COM_COM1bit,COM_TxCharCOM1
	JB	COM_COM2bit,COM_TxCharCOM2
	JMP	COM_RS485_TX			;Force COM0 Writes to COM2 RS485
	ELSE
	JB	COM_COM1bit,COM_TxCharCOM1
	JB	COM_COM2bit,COM_TxCharCOM2
	ENDIF
;*****
; COM0
;*****

	IF USE_RS485

	 MOV	S0BUF,A			; write the data
COM_TC0wait:
	 JNB	TI0,COM_TC0wait		; wait for transmit
	 CLR	TI0			; buffer empty
	 RET

	ELSE

	 PUSHDPL
	 PUSHDPH
	 PUSHB
	 PUSHR0
	 PUSHACC

	 MOV	R0,A

	 MOV	DPTR,#com_tx0buflen	; test length of buffer
	 MOVX	A,@DPTR			; and increment if not full
	 INC	A
	 JZ	COM_TC0bufferfull
	 MOVX	@DPTR,A
	 MOV	B,A

	 INC	DPTR			; find correct place in buffer
	 MOVX	A,@DPTR			; for new character
	 ADD	A,B
	 MOV	DPTR,#com_tx0buffer
	 MOV	DPL,A

	 MOV	A,R0			; add character to buffer
	 MOVX	@DPTR,A

	 MOV	DPTR,#com_tx0buflen	; check if interrupt
	 MOVX	A,@DPTR			; needs a kick start
	 DEC	A
	 JNZ	COM_TC0bufferfull
	 SETB	TI0

COM_TC0bufferfull:
	 POP	ACC
	 POP	0
	 POP	B
	 POP	DPH
	 POP	DPL
	 RET

	ENDIF  ;; USE_RS485

;*****
; COM1
;*****
COM_TxCharCOM1:

	MOV	S1BUF,A			; write the data
COM_TC1wait:
	MOV	A,S1CON			; wait for transmit
	ANL	A,#00000010b		; buffer empty
	JZ	COM_TC1wait		;
	MOV	A,S1CON			;
	ANL	A,#11111101b		;
	MOV	S1CON,A			;
	RET


;*****
; COM2
;*****
COM_TxCharCOM2:
	IF VT10
	RET

COM_RS485_TX:
	CALL	COM_DefaultSerialMux	; Set to Com 2
;	ANL	IEN2,#11111110b		; disable serial 1 interrupt (CLR ES1)
	CALL	COM_RS485TxOn		; Turn TX On.
	CALL	COM_TxCharCOM1		; Output Char
	CALL	COM_RS485TxOff		; Turn Tx Off
	ANL	S1CON,#11111100b	; Clear Tx + Rx Interrupt
;	ORL	IEN2,#00000001b		; enable serial 1 interrupt (SETB ES1)
	RET

	ELSE

	PUSHB
	CLR	com_selab
        CALL	SBS_WriteSB1
        POP	B
        CALL	COM_TxCharCOM1
	CALL	COM_DefaultSerialMux
	RET

	ENDIF

;******************************************************************************
;
; Function:	COM_DefaultSerialMUX
; Input:	None
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Sets the default state of the serial port 1 multiplexer. As of when
;   Stephen left, this defaults to port 1A. In the future, someone may want
;   to make it programmable or compile option variable for some wierd serial
;   port setup.
;
;******************************************************************************

COM_DefaultSerialMUX:
	IF VT10

	PUSHACC	
	MOV	A,#RS485_232Select
	CALL	PortSetC		;Select RS485
	POP	ACC
	RET

	ELSE

	PUSHB
	CLR	com_selab		; default serial 1 to 1B
        CALL	SBS_WriteSB1
	POP	B
	RET

	ENDIF
;******************************************************************************
;
; Function:	COM_TxStr
; Input:	DPTR = address of string in XRAM, R7 = num chars
;               B = serial port
; Output:	None
; Preserved:	All, except A
; Destroyed:	None, except A
; Description:
;   Transmits the specified number of characters from the specified XRAM
;   address up the specified serial port.
;
;******************************************************************************

COM_TxStr:
	MOVX	A,@DPTR
	INC	DPTR
	CALL	COM_TxChar
	DJNZ	R7,COM_TxStr
	RET

COM_TxStrCODE:
	CLR	A
	MOVC	A,@A+DPTR
	MOV	R7,A
COM_TSCloop:
	INC	DPTR
        CLR	A
        MOVC	A,@A+DPTR
	CALL	COM_TxChar
	DJNZ	R7,COM_TSCloop
        RET

COM_TxStrIRAM:
	MOV	A,@R0
	INC	R0
        CALL	COM_TxChar
        DJNZ	R7,COM_TxStrIRAM
        RET
;******************************************************************************
;
; Function:	COM_RxChar
; Input:	B = serial port
; Output:	C set and A=char, or C clear if no char available.
; Preserved:	R0-7,DPTR,B
; Destroyed:    None
; Description:
;   Returns the next character from the specified serial port.
;
;******************************************************************************

COM_RxChar:
	IF USE_RS485
        JMP	COM_RxCharCOM1
	ELSE
	JB	COM_COM1bit,COM_RxCharCOM1
	ENDIF
;*****
; COM0
;*****
	IF USE_RS485
	ELSE
	PUSHDPH
	PUSHDPL
	MOV	DPTR,#com_ser0buflen
	CLR	ES0				; disable serial 0 interrupt

	MOVX	A,@DPTR				; check for any chars
	JZ	COM_R0Cempty			; in buffer

	DEC	A				; yes...decrement count
	MOVX	@DPTR,A				;

        PUSHB				;
	INC	A				; calculate where to
	INC	DPTR				; find next character
	MOV	B,A				;
	MOVX	A,@DPTR				;
	CLR	C				;
	SUBB	A,B				;
	MOV	DPTR,#com_ser0buffer		;
	MOV	DPL,A				; DPTR=buffer+(ptr-len)
        POP	B				;

	MOVX	A,@DPTR				; get the character

	SETB	ES0				; restore serial 0 interrupt
	POP	DPL
	POP	DPH
	SETB	C				; success
	RET
COM_R0Cempty:
	SETB	ES0				; restore serial 0 interrupt
	POP	DPL
	POP	DPH
	CLR	C				; failure
	RET
        ENDIF
;*****
; COM1
;*****
COM_RxCharCOM1:
	PUSHDPH
	PUSHDPL
	MOV	DPTR,#com_ser1buflen
	ANL	IEN2,#11111110b			; CLR ES1 (dis. com1 ints)

	MOVX	A,@DPTR				; check for any chars
	JZ	COM_R1Cempty			; in buffer

	DEC	A				; yes...decrement count
	MOVX	@DPTR,A				;

        PUSHB				;
	INC	A				; calculate where to
	INC	DPTR				; find next character
	MOV	B,A				;
	MOVX	A,@DPTR				;
	CLR	C				;
	SUBB	A,B				;
	MOV	DPTR,#com_ser1buffer		;
	MOV	DPL,A				; DPTR=buffer+(ptr-len)
        POP	B				;

	MOVX	A,@DPTR				; get the character

	ORL	IEN2,#00000001b			; SETB ES1 (en. ser 1 ints)
	POP	DPL
	POP	DPH
	SETB	C				; success
	RET
COM_R1Cempty:
	ORL	IEN2,#1				; SETB ES1 (en. ser 1 ints)
	POP	DPL
	POP	DPH
	CLR	C				; failure
	RET

;******************************************************************************
;
; Function:	COM_RxCharWait
; Input:	B=serial port
; Output:	A=next char
; Preserved:	R0-7,DPTR,B
; Destroyed:	None
; Description:
;   Returns the next character from the specified serial port. If a character
;   is already in the buffer, it is returned. If no characters are available,
;   the routine will wait for a character to arrive.
;
;******************************************************************************

COM_RxCharWait:
	CALL	COM_RxChar
	JNC	COM_RxCharWait
	RET

;******************************************************************************
;
; Function:	COM_RxCharTimeout
; Input:	R5 = number of 100ms in timeout.
;               B=serial port
; Output:	C set and A=char, or C clear if no char available.
; Preserved:	R3/4/6/7,DPTR,B
; Destroyed:	R0-2/5
; Description:
;   Returns the next character from the specified serial port. If a character
;   is already in the buffer, it is returned. If no characters are available,
;   the routine will wait for a character to arrive. The routine will timeout
;   after R5 number of 100ms timeouts.
;
;******************************************************************************

COM_RxCharTimeout:
	CALL	COM_RxChar
	JC	COM_RxCTdone
	MOV	R0,#1
	CALL	delay100ms
	DJNZ	R5,COM_RxCharTimeout
	CLR	C
COM_RxCTdone:
	RET

;******************************************************************************
;
; Function:	COM_Test
; Input:	B = serial port
; Output:	A = number of characters in specified serial port buffer.
; Preserved:	All except DPTR,A
; Destroyed:	DPTR
; Description:
;   Determines whether any characters are immediately available from the
;   specified serial port's buffer and returns a count of exacly how many are
;   there.
;
;******************************************************************************

COM_Test:
	IF USE_RS485
	JMP	COM_TestCOM1
	ELSE
	JB	COM_COM1bit,COM_TestCOM1
	ENDIF
;*****
; COM0
;*****
	IF USE_RS485
        ELSE
	MOV	DPTR,#com_ser0buflen
	MOVX	A,@DPTR
	RET
        ENDIF
;*****
; COM1
;*****
COM_TestCOM1:
	MOV	DPTR,#com_ser1buflen
	MOVX	A,@DPTR
	RET

;******************************************************************************
;
; Function:	COM_Flush
; Input:	B=serial port
; Output:	None
; Preserved:	R0-7,DPTR,B
; Destroyed:	A
; Description:
;   Flushes all characters from the specified serial port buffer. Will never
;   return if the buffer is being continually filled while it is being flushed.
;
;******************************************************************************

COM_Flush:
	CALL	COM_RxChar
	JC	COM_Flush
	RET


;******************************************************************************
;
; Function:	COM_Rx0Int
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   COM0 receive interrupt. Maintains a 256 byte circular buffer of what
;   arrives at serial port 0. Ignores (and loses) characters received when
;   the buffer is full.
;
;******************************************************************************

	IF USE_RS485
	ELSE
COM_Rx0Int:
	PUSHPSW			; save regs
	PUSHACC			;
	PUSHDPH			;
	PUSHDPL			;

	JNB	RI0,COM_R0Itx		; ignore transmit interrupts

	MOV	DPTR,#com_ser0buflen	; check for serial buffer 0 full
	MOVX	A,@DPTR			;
	INC	DPTR			;
	INC	A			;
	JZ	COM_R0Ifull		;

	MOVX	A,@DPTR			; Calculate address to store
	MOV	DPTR,#com_ser0buffer	; next character at:
	MOV	DPL,A			;   DPTR = #buffer+bufptr

	MOV	A,S0BUF			; store the received char
	MOVX	@DPTR,A			;

	MOV	DPTR,#com_ser0buflen	; increment buffer len
	MOVX	A,@DPTR			;
	INC	A			;
	MOVX	@DPTR,A			;

	INC	DPTR			; increment buffer ptr
	MOVX	A,@DPTR			;
	INC	A			;
	MOVX	@DPTR,A			;
COM_R0Ifull:
	CLR	RI0
	JMP	COM_R0Iend

COM_R0Itx:
	MOV	DPTR,#com_tx0buflen	; check if more to transmit
	MOVX	A,@DPTR
	JZ	COM_R0Itxempty

	INC	DPTR			; if so, find correct character
	MOVX	A,@DPTR
	MOV	DPTR,#com_tx0buffer
	MOV	DPL,A

	MOVX	A,@DPTR			; transmit character
	MOV	S0BUF,A

	MOV	DPTR,#com_tx0buflen	; decrement buffer length
	MOVX	A,@DPTR
	DEC	A
	MOVX	@DPTR,A

	INC	DPTR			; increment buffer pointer
	MOVX	A,@DPTR
	INC	A
	MOVX	@DPTR,A

COM_R0Itxempty:
	CLR	TI0			; clear the interrupt flag

COM_R0Iend:
	POP	DPL			; restore regs
	POP	DPH			;
	POP	ACC			;
	POP	PSW			;
	RETI				;
	ENDIF

;******************************************************************************
;
; Function:	COM_Rx1Int
; Input:	INTERRUPT
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   COM1 receive interrupt. Maintains a 256 byte circular buffer of what
;   arrives at serial port 1. Ignores (and loses) characters received when
;   the buffer is full.
;
;******************************************************************************

COM_Rx1Int:
	PUSHPSW			; save regs
	PUSHACC			;
	PUSHDPH			;
	PUSHDPL			;

	MOV	A,S1CON			; test RI1
	JNB	ACC.0,COM_R1Itx		; ignore transmit interrupts

	MOV	DPTR,#com_ser1buflen	; check for serial buffer 1 full
	MOVX	A,@DPTR			;
	INC	DPTR			;
	INC	A			;
	JZ	COM_R1Ifull		;

	MOVX	A,@DPTR			; Calculate address to store
	MOV	DPTR,#com_ser1buffer	; next character at:
	MOV	DPL,A			;   DPTR = #buffer+bufptr

	MOV	A,S1BUF			; store the received char
	MOVX	@DPTR,A			;

	MOV	DPTR,#com_ser1buflen	; increment buffer len
	MOVX	A,@DPTR			;
	INC	A			;
	MOVX	@DPTR,A			;

	INC	DPTR			; increment buffer ptr
	MOVX	A,@DPTR			;
	INC	A			;
	MOVX	@DPTR,A			;
COM_R1Ifull:
	ANL	S1CON,#0FEh		; CLR RI1
COM_R1Itx:
	POP	DPL			; restore regs
	POP	DPH			;
	POP	ACC			;
	POP	PSW			;
	RETI				;



;******************************************************************************
;
; Function:	COM_TxStatusAgain
; Input:
; Output:
; Preserved:
; Destroyed:
; Description:
;	Transmits the last status packet transmitted again...
;
;******************************************************************************

	IF USE_SERVANT

COM_StopStatusTransmit:
	INC	com_txok
	RET

COM_StartStatusTransmit:
	MOV	A,com_txok
	JZ	COM_SSTend
	DEC	com_txok
COM_SSTend:
	RET

COM_TxStatusAgain:
	MOV	A,com_txok
	JNZ	COM_TSAdebug

	MOV	DPTR,#com_tx0buflen
	MOVX	A,@DPTR
	JNZ	COM_TSAend

	MOV	DPTR,#com_status_buffer
	MOV	B,#0

	MOV	R0,#6			; length of header
COM_TSAloop1:
	MOVX	A,@DPTR
	CALL	COM_TxChar
	INC	DPTR
	DJNZ	R0,COM_TSAloop1

	INC	A			; A contains length of data
	MOV	R0,A			; inc to include check byte
COM_TSAloop2:
	MOVX	A,@DPTR
	CALL	COM_TxChar
	INC	DPTR
	DJNZ	R0,COM_TSAloop2

COM_TSAdebug:
;	MOV	B,#0
;	CALL	COM_TxChar

COM_TSAend:
	RET

;******************************************************************************
;
; Function:	COM_TxStatus
; Input:	B = packet type
; Output:
; Preserved:
; Destroyed:	DPTR, A, R0, R1 (pkt type 2 only), R7 (pkt type 3,4 only)
; Description:
;	Transmits a status packet...
;
;******************************************************************************

COM_TxStatus:
	MOV	DPSEL,#0
	MOV	DPTR,#com_status_buffer

	MOV	A,#'s'
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#'t'
	MOVX	@DPTR,A
	INC	DPTR
	MOV	A,#'a'
	MOVX	@DPTR,A
	INC	DPTR


	MOV	A,servant_status
	MOVX	@DPTR,A
	INC	DPTR
	MOV	R0,A			; start forming check byte in R0

	MOV	A,B
	ADD	A,R0			; add packet type to check digit
	MOV	R0,A

	MOV	A,B   		  	; add packet type to data packet
	MOVX	@DPTR,A
	INC	DPTR

	MOV	DPSEL,#1                ; jump depending upon packet type
	MOV	DPTR,#txpkttypetable
	RL	A
	JMP	@A+DPTR

txpkttypetable:
	AJMP	COM_TXSnodata		; not allowed
	AJMP	COM_TXSnodata		; startup / reset - no data
	AJMP	COM_TXStype2		; keypress
	AJMP	COM_TXStype3		; ticket issued
	AJMP	COM_TXStype4		; ticket printed
	AJMP	COM_TXSnodata		; keypress (buffer full) - no data

COM_TXSnodata:
	MOV	DPSEL,#0		;
	MOV	A,#0                    ; data length zero
	MOVX	@DPTR,A                 ;
	INC	DPTR                    ; no change to check byte
	JMP	COM_TXSdoit             ;

COM_TXStype2:				; keyboard
	MOV	DPSEL,#0
	MOV	A,#1                    ; data length 1
	MOVX	@DPTR,A                 ;
	INC	DPTR                    ;
	INC	R0                      ; add 1 to check byte
	MOV	A,#kbd_keybuffer	;
	ADD	A,kbd_bufptr		; calculate  address of recent key
	DEC 	A
	MOV	R1,A			;
	MOV	A,@R1			; get the keypress
	MOVX	@DPTR,A			; add to buffer
	INC	DPTR			;
	ADD	A,R0			; add to check byte
	MOV	R0,A			;
	JMP	COM_TXSdoit

COM_TXStype3:
	MOV	DPTR,#tkt_subtot_entries	;
	MOVX	A,@DPTR
	DEC	A				;
	MOV	DPTR,#tkt_subtot_table		;
	MOV	B,#TKT_SUBTOT_SIZE		;
	MUL	AB				;
	CALL	AddABtoDPTR			; DPTR now at correct entry
	MOV	R7,#TKT_SUBTOT_SIZE		;
	JMP	COM_TXScopydata

COM_TXStype4:
	MOV	DPTR,#tkt_number
	MOV	R7,#4

COM_TXScopydata:
	MOV	DPSEL,#0
	MOV	A,R7                    ; data length R7
	MOVX	@DPTR,A                 ;
	INC	DPTR                    ;
	ADD	A,R0			; add length to check byte
	MOV	R0,A                    ;
COM_TXScopyloop:
	 MOV	DPSEL,#1
	 MOVX	A,@DPTR
	 INC	DPTR
	 MOV	DPSEL,#0
	 MOVX	@DPTR,A
	 INC	DPTR
	 ADD	A,R0
	 MOV	R0,A
	DJNZ	R7,COM_TXScopyloop

COM_TXSdoit:
	MOV	A,R0			; add check byte
	MOVX	@DPTR,A                 ;
	CALL	COM_TxStatusAgain	; TRANSMIT!!!
	RET

	ENDIF	;;SERVANT
;*******************************************************************************
COM_RS485TxOn:
	PUSHACC
	MOV	A,#RS485TxOn
	CALL 	PortSetC
	POP	ACC
	RET
;*******************************************************************************
COM_RS485TxOff
	PUSHACC
	MOV	A,#RS485TxOn
	CALL	PortClrC
	POP	ACC
	RET
;*******************************************************************************
COM_TX_A:
	PUSHDPH
	PUSHDPL
	PUSHACC
	mov	dptr,#00085h		; LSR
COM_TX_A_Wait:
	movx	A,@DPTR
	jnb	ACC.5,COM_TX_A_Wait
	mov	dptr,#00080h		; TX buffer
	POP	ACC
	MOVX	@DPTR,A
	POP	DPL
	POP	DPH
	RET
;*******************************************************************************
COM_TX_B:
	PUSHDPH
	PUSHDPL
	PUSHACC
	mov	dptr,#000c5h		; LSR
COM_TX_B_Wait:
	movx	A,@DPTR
	jnb	ACC.5,COM_TX_B_Wait
	MOV	dptr,#000c0h		; TX buffer
	POP	ACC
	MOVX	@DPTR,A
	POP	DPL
	POP	DPH
	RET
;*******************************************************************************


;*******************************************************************************



;****************************** End Of COMMS.ASM *******************************
