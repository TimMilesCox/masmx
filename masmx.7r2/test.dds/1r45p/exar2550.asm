;************************************************************************
;*       File EXAR2550.ASM                                              *
;*       Tim, 17ij2000                                                  *
;*       Runs Dual UART EXAR ST16C2550                                  *
;*                                                                      *
;*       Clever people beware: IO registers mapped in XRAM page zero    *
;*                             address space                            *
;*                             can only be accessed with a 16-bit       *
;*                             address [@dptr].                         *
;*                             If you use an 8-bit address [@r0, @r1]   *
;*                             with the MOVX instruction, you get       *
;*                             something else, maybe XRAM page zero,    *
;*                             or something else determined by Port P2  *
;************************************************************************


EXAR_COUNTING   EQU     0
EXAR_TALLYING   EQU     0
EXAR_CHANNEL    EQU     2
EXAR_RESTARTING EQU     0

;        align   VAR,ToPage
;xcom1_buffer: VAR 256   ; Input Buffer

        IF      EXAR_CHANNEL EQ 1
XCOM1   EQU     192     ; XRAM Locations of UART register sets
XCOM2   EQU     128
        ENDIF

        IF      EXAR_CHANNEL EQ 2
XCOM1   EQU     128     ; XRAM Locations of UART register sets
XCOM2   EQU     192
        ENDIF

RHR     EQU     0       ; Receive  Holding Register (Brim of FIFO)
THR     EQU     0       ; Transmit Holding Register (Cusp of FIFO)

IER     EQU     1       ; Interrupt Enable Register
IER_Rx  EQU     1       ; Receive Interrupt Enable
IER_MODEST EQU  8       ; Modem Status Interrupt Enable
IER_RLS EQU     4       ; Receive Line Status Interrupt Enable

ISR     EQU     2       ; Interrupt Status Register
ISR_Rx  EQU     1       ; Data in RHR/FIFO

FCR     EQU     2       ; FIFO Control Register
FCR_Ena EQU     1       ; Enable Rx/Tx FIFOs
FCR_RSr EQU     2       ; Reset Rx FIFO
FCR_RSt EQU     4       ; Reset Tx FIFO

LCR     EQU     3       ; Line Control Register
LCR_DLE EQU     128     ; Divisor Latch Enable for BaudRate Generator
LCR_8   EQU     3       ; 8-Bit Word, No Parity, 1 Stop Bit

MCR     EQU     4       ; Modem Control Register
MCR_IEN EQU     8       ; Enable Interrupts
MCR_DTR EQU     1
MCR_RTS EQU     2

LSR     EQU     5       ; Line Status Register
LSR_RDR EQU     0       ; Data In Receive FIFO
LSR_XOK EQU     6       ; Room In Transmit FIFO/Serialiser

MSR     EQU     6       ; Modem Status Register

SPR     EQU     7       ; Scratch Pad Register

BDLLow  EQU     0       ; BaudRate Divisor Latch Low
BDLHigh EQU     1       ; BaudRate Divisor Latch High

U9600   EQU     0
L9600   EQU     12

U57600  EQU     0
L57600  EQU     2

exar_orunI      VAR     2
exar_parityE    VAR     2
exar_frameE     VAR     2
exar_breakI     VAR     2
exar_charsI     VAR     4
exar_charsD     VAR     4

EXAR_Start:                     ; INITIAL SETTINGS Channel 1
        
        IF      EXAR_RESTARTING
        ;****************************************************************
        ;       First in case this is a software reset                  *
        ;       Default all registers to hardware reset values          *
        ;****************************************************************

        mov     dptr,#XCOM1+IER ;       IER = 00000000
        clr     a
        movx    @dptr,a

        inc     dptr            ;       FCR = 00000000
        movx    @dptr,a

        inc     dptr            ;       LCR = 00000000
        movx    @dptr,a

        inc     dptr            ;       MCR = 00000000
        movx    @dptr,a

        inc     dptr            ;       LSR = 01100000
        mov     a,#060h         ;       If it can be meaningfully wrote
        movx    @dptr,a

        inc     dptr            ;       MSR = xxxx0000
        clr     a               ;       If it can be meaningfully wrote
        movx    @dptr,a

        inc     dptr            ;       SPR = 11111111
        cpl     a
        movx    @dptr,a
        ENDIF
        
        
        ;****************************************************************      
        ;       Secondly Start Configuring                              *
        ;****************************************************************

        mov     dptr,#XCOM1+LCR ; set the Baud Rate
        mov     a,#LCR_DLE      ; Address the Baud Rate Registers
        movx    @dptr,a

        mov     dptr,#XCOM1+BDLLow
        mov     a,#L57600
        movx    @dptr,a
        inc     dptr
        mov     a,#U57600
        movx    @dptr,a

        mov     dptr,#XCOM1+LCR
        mov     a,#LCR_8        ; 8 Data Bits, No Parity, 1 Stop Bit
        movx    @dptr,a         ; And don't address the Baud Rate Registers

        mov     dptr,#XCOM1+FCR ;
        mov     a,#FCR_RSr OR FCR_RSt OR FCR_Ena
                                ; reset & Enable FIFOs, Trigger Level = 1
        movx    @dptr,a         ;

        mov     dptr,#XCOM1+IER
        
;        mov     a,#IER_Rx OR IER_MODEST OR IER_RLS ; enable Receive Interrupt
        mov     a,#IER_Rx OR IER_RLS ; enable Receive Interrupt
        
        movx    @dptr,a

        mov     dptr, #XCOM1+RHR
        movx    a, @dptr
        mov     dptr, #XCOM1+LSR
        movx    a, @dptr

        mov     dptr,#XCOM1+MCR ; enable all interrupts
        mov     a,#MCR_IEN      ; OR MCR_DTR OR MCR_RTS
        movx    @dptr,a
        
                                ; INITIAL SETTINGS Channel 2
        mov     dptr,#XCOM2+LCR ; set the Baud Rate
        mov     a,#LCR_DLE      ; Address the Baud Rate Registers
        movx    @dptr,a

        mov     dptr,#XCOM2+BDLLow
        mov     a,#L57600
        movx    @dptr,a
        inc     dptr
        mov     a,#U57600
        movx    @dptr,a

        mov     dptr,#XCOM2+LCR
        mov     a,#LCR_8        ; 8 Data Bits, No Parity, 1 Stop Bit
        movx    @dptr,a         ; And don't address the Baud Rate Registers

        mov     dptr,#XCOM2+FCR ;
        mov     a,#FCR_RSr OR FCR_RSt OR FCR_Ena
                                ; reset & Enable FIFOs, Trigger Level = 1
        movx    @dptr,a         ;

        mov     dptr,#XCOM2+IER
;        mov     a,#IER_Rx OR IER_MODEST OR IER_RLS ; enable Receive Interrupt
        mov     a,#IER_Rx OR IER_RLS ; enable Receive Interrupt
        movx    @dptr,a

        mov     dptr, #XCOM2+RHR
        movx    a, @dptr
        mov     dptr, #XCOM2+LSR
        movx    a, @dptr

        mov     dptr,#XCOM1+MCR ; enable all interupts
        mov     a,#MCR_IEN ;OR MCR_DTR OR MCR_RTS
        movx    @dptr,a
        
        clr     xcom1_Full
        mov     xcom1_write_cursor,#0
        mov     xcom1_read_cursor,#0
        
        IF      EXAR_BARCODE_APPLICATION
        clr     EXAR_CR_Encountered
        ENDIF
        
        mov     xcom1_wbsel, #0
        mov     xcom1_rbsel, #0
        
        mov     dptr, #buffer-2
        clr     a
        movx    @dptr, a
        inc     dptr
        movx    @dptr, a
        
        setB    EX1
        setB    IT1

        ret


        
EXAR_StatsInit:
        clr     A

        mov     dptr,#exar_orunI
        mov     r7,#16
EXAR_StatsInitL:
        movx    @dptr,a
        inc     dptr
        djnz    r7,EXAR_StatsInitL

        ret


ANSII_CR EQU 0Dh
ANSII_LF EQU 0Ah


        IF      EXAR_TALLYING
EXAR_DiagNose:
        call    EXAR_RxOR               ; OverRun
        call    EXAR_RxPE               ; ParityError
        call    EXAR_RxFE               ; FrameError
        call    EXAR_RxBI               ; BreakIndication
        ret

EXAR_RxOR:
        mov     a,mth_op1ll
        jb      acc.1,EXAR_RxOverRun
        ret
EXAR_RxOverRun:
        call    KBD_InitKeyBoard
        call    COM_InitSerial
        call    EXAR_Start              ; Somehow, Anyhow
        
        mov     dptr,#exar_orunI
        jmp     EXAR_TallyStat

EXAR_RxPE:
        mov     a,mth_op1ll
        jb      acc.2,EXAR_RxParityError
        ret
EXAR_RxParityError:
        mov     dptr,#XCOM1+RHR         ; Strip the Byte at FIFO Top
        movx    a,@dptr
        mov     dptr,#exar_parityE
        jmp     EXAR_TallyStat

EXAR_RxFE:
        mov     a,mth_op1ll
        jb      acc.3,EXAR_RxFramingError
        ret
EXAR_RxFramingError:
        mov     dptr,#XCOM1+RHR         ; Strip the Byte at FIFO Top
        movx    a,@dptr
        mov     dptr,#exar_frameE
        jmp     EXAR_TallyStat

EXAR_RxBI:
        mov     a,mth_op1ll
        mov     dptr,#exar_breakI
        jb      acc.4,EXAR_TallyStat
        ret

        ENDIF

EXAR_Counter:                           ; 32-bit Entry Point
        movx    a,@dptr
        inc     a
        jnz     EXAR_TallyQ             ; No Carry from b31:24
        movx    @dptr,a                 ;          Save b31:24
        inc     dptr                    ;       Address b23:16
        movx    a,@dptr
        inc     a
        jnz     EXAR_TallyQ             ; No Carry from b23:16
        movx    @dptr,a                 ;          Save b23:16
        inc     dptr                    ;       Address b15:8

EXAR_TallyStat:                         ; 16-bit Entry Point
        movx    a,@dptr
        inc     a
        jnz     EXAR_TallyQ             ; No Carry from b15:8
        movx    @dptr,a                 ;          Save b15:8
        inc     dptr                    ;       Address b7:0
        movx    a,@dptr
        inc     a
EXAR_TallyQ:
        movx    @dptr,a                 ; Write HIghest Ordered Affected
        ret                             ; Octet

ANSII_ACK EQU   6
ANSII_ETX EQU   3
ANSII_STX EQU   2
ANSII_DLE EQU   16
ANSII_NAK EQU   21

        IF      1

RS232_TransmitPacket
EXAR_FIFO_DEPTH EQU     16

EXAR_FTX:
        mov     a,r7
        jz      EXAR_FTXX
        mov     r0,#prt_field_str       ; cache the framing bytes
        mov     @r0,#0afh
        inc     r0
        mov     @r0,#0aeh
        inc     r0
        
        $if     1                       ; Generate the Checksum
        
        mov     @r0, #0
        inc     r0
        mov     @r0, #0
        dec     r0

        mov     r7, a
        add     a, #5
        push    acc
        call    ADDCRCByte
        mov     a, sys_mynode
        call    ADDCRCByte
        push    dph
        push    dpl
        call    ADDCRCBytes
        pop     dpl
        pop     dph
        pop     acc
        inc     r0
        inc     r0
        
        $else
        
        mov     @r0,#000h               ; put the checksum here sometime
        inc     r0
        mov     @r0,#000h
        inc     r0
        add     a,#5
        
        $endif
        
        mov     @r0,a
        inc     r0
        mov     @r0, #0
        inc     r0
        mov     @r0, sys_mynode
        inc     r0
        mov     prt_field_len,#EXAR_FIFO_DEPTH
        mov     b,#EXAR_FIFO_DEPTH-7
        add     a,#-EXAR_FIFO_DEPTH+7-5 ; followed by up to (FIFO-7) bytes
        mov     r7,a                    ; which will nearly always be
        jc      EXAR_FTXL1              ; the packet
        add     a,#EXAR_FIFO_DEPTH-7+5  ; and will follow 
        mov     b,a
        add     a,#2
        jmp     EXAR_FTXS               ; this path
EXAR_FTXL:
        mov     r0,#prt_field_str       ; use the printer IRAM locations
        mov     prt_field_len,#EXAR_FIFO_DEPTH  ; A Lot, Maybe
        mov     b,#EXAR_FIFO_DEPTH      ;
        add     a,#-EXAR_FIFO_DEPTH     ; A Lot, Really?
        mov     r7,a                    ; Remember how much more
        jc      EXAR_FTXL1              ; Really a lot
        add     a,#EXAR_FIFO_DEPTH      ; No: flip count back thru zero
        mov     b,a                     ; Count for XRAM->IRAM Xfer
EXAR_FTXS:        
        mov     prt_field_len,a         ; Count for IRAM->UART Xfer
        mov     r7,#0                   ; And No More After
EXAR_FTXL1:
        movx    a,@dptr                 ; read packet data
        inc     dptr                    ; address next byte
        mov     @r0,a                   ; write IRAM cache while UART FIFO
        inc     r0                      ; transmits the previous 16
        djnz    b,EXAR_FTXL1            ; or the previous packet
        push    dph
        push    dpl
        mov     dptr,#XCOM1+LSR         ; Fix Gaze on UART Status 
EXAR_FTXL2:
        movx    a,@dptr                 ; Read UART Status
        jnb     acc.6,EXAR_FTXL2        ; Until We Agree With It
        mov     r0,#prt_field_str       ; Address Line of Data in IRAM
        mov     dptr,#xcom1+THR         ; Fix Gaze on Cusp of Xmit FIFO
EXAR_FTXL3:
        mov     a,@r0                   ; Read IRAM
        movx    @dptr,a                 ; write UART
        inc     r0                      ; Increment IRAM Address
        djnz    prt_field_len,EXAR_FTXL3; 
        pop     dpl
        pop     dph
        mov     a,r7                    ; Loop Control: any data still to go?
        jnz     EXAR_FTXL               ; Yes
EXAR_FTXX:
        ret                             ; No

        endif
        if      0

HOST_Ping:
        mov     dptr,#XCOM1+LSR
        movx    a,@dptr
        jnb     acc.6,HOST_Ping
        mov     dptr,#XCOM1+THR
        mov     a,#ANSII_ACK
        movx    @dptr,a
        mov     a,#ANSII_ETX
        movx    @dptr,a
        ret

HOST_ErrPing:
        mov     dptr,#XCOM1+LSR
        movx    a,@dptr
        jnb     acc.6,HOST_ErrPing
        mov     dptr,#XCOM1+THR
        mov     a,#ANSII_NAK
        movx    @dptr,a
        mov     a,#ANSII_ETX
        movx    @dptr,a
        ret

        endif

        IF 0

EXAR_Tx:                                ; SINGLE BYTE TRANSMIT SUBROUTINE
        push    DPH                     ; Calling Routine is almost certainly 
        push    DPL                     ; traversing an output buffer with DP.
        push    ACC                     ; Save the data for a moment
        mov     dptr,#XCOM1+LSR         ; Is there space in the Output
        movx    a,@dptr                 ; FIFO/Serialiser?
        jb      acc.6,EXAR_TxY          ; Yes: Write Data to FIFO
        pop     ACC                     ; data of stack
        pop     DPL                     ; user pointer off stack
        pop     DPH
        setB    C                       ; Overflow: Data Not on FIFO
        ret
EXAR_TxY:
        pop     ACC                     ; Data off Stack
        mov     dptr,#XCOM1+THR         ; write to Transmit Holding Register
        movx    @dptr,a
        pop     DPL
        pop     DPH
        clr     C                       ; Not Overflow: Data Accepted by FIFO
        ret

EXAR_TxL:                               ; LOCKED TRANSMIT FOR SINGLE-THREAD
        call    EXAR_Tx                 ; SYSTEMS
        jc      EXAR_TxL                ; No: Poll Again
        ret
        
        ENDIF

        $if     0

EXAR_Read1:                             ; USER ROUTINE TO READ SERIAL INPUT
        mov     a, xcom1_rbsel
        cjne    a, xcom1_wbsel, EXAR_Read1Y
        mov     a,xcom1_read_cursor
        cjne    a,xcom1_write_cursor,EXAR_Read1X ; Buffer Not Empty, so do it
        clr     C                       ; Status No Data
        ret
EXAR_Read1X:
        mov     a, xcom1_rbsel
EXAR_Read1Y:
        orl     a, #xcom1_buffer SHR 8 ;
        push    DPH                     ; User is certainly scanning a buffer
        push    DPL                     ; using dptr, so save/restore it

        mov     dph, A                  ; add on the page select
        
        mov     a, xcom1_read_cursor
        mov     dpl,a                   ; i.e. buffer read_cursor
        inc     a
        mov     xcom1_read_cursor, A
        jnz     EXAR_SamePage
        inc     xcom1_rbsel
        anl     xcom1_rbsel, #7
        mov     a, xcom1_wbsel
        cjne    a, xcom1_rbsel, EXAR_SamePage
        clr     xcom1_full              ; advanced to current write page
                                        ; we have < 256 bytes
EXAR_SamePage
        movx    a,@dptr                 ; so read some data at last
        pop     DPL
        pop     DPH
        setB    C                       ; Status Data (in case UART is
        ret                             ; capable of delivering zero bytes)


EXAR_HowMany?:                          ; USER ROUTINE TO READ SERIAL INPUT
                                        ; CAPTURE COUNT
        mov     C,xcom1_full
        jc      EXAR_ThatMany
        mov     a,xcom1_read_cursor     ; subtract read cursor
        cpl     a                       ; from write cursor
        setB    C
        addc    a,xcom1_write_cursor    ; or unsigned result is 0..255
        clr     C
EXAR_ThatMany:        
        ret

EXAR_Index:                             ; USER ROUTINE TO SAMPLE FORWARD 
                                        ; INPUT BYTE IN BUFFER
        add     a,xcom1_read_cursor     ; wraparound
        push    dph
        push    dpl
        mov     dph, #xcom1_Buffer/*8
        mov     dpl, a
        mov     a, xcom1_rbsel
        addc    a, #0
        anl     a, #7
        orl     dph, A
        movx    a,@dptr
        pop     dpl
        pop     dph
        ret
        

EXAR_RxInt:                             ; RECEIVE INTERRUPT
                                        ; Register/State Saves have been 
                                        ; done in the Keyboard Interrupt
        mov     dptr,#XCOM1+ISR
        movx    a,@dptr
        jb      acc.0,EXAR_RxIZ
        anl     a,#15
        jz      EXAR_RxNotLSR
        call    EXAR_RxIL
        jmp     EXAR_RxInt
EXAR_RxNotLSR:
        
        IF      LCD_BUG EQ 6
        push    acc
        swap    a
        call    hexchar
        mov     B,A
        call    LCD_BugA
        pop     acc
        call    hexchar
        mov     b,a
        call    LCD_BugB
        ENDIF

        jmp     EXAR_RxInt
EXAR_RxIZ:
        
        IF      EXAR_RESTARTING
        mov     dptr,#XCOM1+IER
        mov     a,#IER_Rx OR IER_MODEST OR IER_RLS ; enable Receive Interrupt
        movx    @dptr,a
        ENDIF

        ret

EXAR_RxIL:
        mov     dptr,#XCOM1+LSR         ; Is there data on COM1 input FIFO?
        movx    a,@dptr
        
        IF      EXAR_TALLYING
        jnb     acc.7,EXAR_RxINormal
        mov     mth_op1ll,a             
        call    EXAR_DiagNose
        mov     a,mth_op1ll
EXAR_RxINormal:
        ENDIF

        jnb     acc.0,EXAR_RxIX         ; No more so exit
        mov     dpl,#XCOM1+RHR          ; Yes
        movx    a,@dptr                 ; Read
;        jb      xcom1_Full,EXAR_RxID    ; Buffer Full, Drop the Data
        mov     dpl,xcom1_write_cursor  ; By Means of the Running Cursor
        
        
        mov     dph, a
        mov     a,#xcom1_buffer SHR 8 ; Find Place in Circular Input Buffer
        orl     a, xcom1_wbsel
        
        $if     0
        push    acc
        swap    a
        call    hexchar
        mov     b,a
        call    LCD_BugA
        pop     acc
        push    acc
        call    hexchar
        mov     b,a
        call    LCD_BugB
        pop     acc
        $endif
        
        xch     A, dph 
        movx    @dptr,a                 ; Write the Data to XRAM
        
        IF      EXAR_COUNTING
        mov     dptr,#exar_charsI
        call    EXAR_Counter
        ENDIF

        inc     xcom1_write_cursor      ; Advance the Input Cursor
        mov     a,xcom1_read_cursor     ; If write starts to equal read
        cjne    a,xcom1_write_cursor,EXAR_RxIL
        setB    xcom1_Full              ; Stop reading from FIFO to XRAM
;        call    RS232_AreYouGoingToDoAnythingAboutThis?
        
        inc     xcom1_wbsel        
        anl     xcom1_wbsel, #7

        mov     b, #'*'
        call    LCD_BugA
        
        jmp     EXAR_RxIL               ; Is there any more?

EXAR_RxID:                              ; Dropped Character
        mov     dptr,#exar_charsD
        call    EXAR_Counter
        jmp     EXAR_RxIL

EXAR_RxIX:
        
BUGLE2  EQU     0        
        IF      BUGLE2
        push    b
        push    acc
        swap    a
        call    hexchar    
        mov     b,a
        call    LCD_BugA
        pop     acc
        push    acc
        call    hexchar
        mov     b,a
        call    LCD_BugB
        pop     acc
        pop     b
        ENDIF
                                        
                                        ; Keyboard ISR does
                                        ; Register/State Restores
        ret                             ; Not RETI. 
                                        ; KeyBoard ISR called this Routine

        $else

EXAR_Read1:                             ; USER ROUTINE TO READ SERIAL INPUT
        mov     a,xcom1_read_cursor
        jb      xcom1_Full,EXAR_Read1Y  ; Buffer Full, so do it
        cjne    a,xcom1_write_cursor,EXAR_Read1Y ; Buffer Not Empty, so do it
        clr     C                       ; Status No Data
        ret
EXAR_Read1Y:
        push    DPH                     ; User is certainly scanning a buffer
        push    DPL                     ; using dptr, so save/restore it
        mov     dpl,a                   ; i.e. buffer read_cursor
        mov     dph,#xcom1_buffer SHR 8 ;
        movx    a,@dptr                 ; so read some data at last
        pop     DPL
        pop     DPH
        inc     xcom1_read_cursor       ; Next In
        clr     xcom1_Full              ; not full now if it was
        setB    C                       ; Status Data (in case UART is
        ret                             ; capable of delivering zero bytes)


EXAR_HowMany?:                          ; USER ROUTINE TO READ SERIAL INPUT
                                        ; CAPTURE COUNT
        mov     C,xcom1_full
        jc      EXAR_ThatMany
        mov     a,xcom1_read_cursor     ; subtract read cursor
        cpl     a                       ; from write cursor
        setB    C
        addc    a,xcom1_write_cursor    ; or unsigned result is 0..255
        clr     C
EXAR_ThatMany:        
        ret

EXAR_Index:                             ; USER ROUTINE TO SAMPLE FORWARD 
                                        ; INPUT BYTE IN BUFFER
        add     a,xcom1_read_cursor     ; wraparound
        push    dph
        push    dpl
        mov     dph, #xcom1_Buffer/*8
        mov     dpl, a
        movx    a,@dptr
        pop     dpl
        pop     dph
        ret
        

EXAR_RxInt:                             ; RECEIVE INTERRUPT
                                        ; Register/State Saves have been 
                                        ; done in the Keyboard Interrupt
        mov     dptr,#XCOM1+ISR
        movx    a,@dptr
        jb      acc.0,EXAR_RxIZ
        anl     a,#15
        jz      EXAR_RxNotLSR
        call    EXAR_RxIL
        jmp     EXAR_RxInt
EXAR_RxNotLSR:
        
        IF      LCD_BUG EQ 6
        push    acc
        swap    a
        call    hexchar
        mov     B,A
        call    LCD_BugA
        pop     acc
        call    hexchar
        mov     b,a
        call    LCD_BugB
        ENDIF

        jmp     EXAR_RxInt
EXAR_RxIZ:
        
        IF      EXAR_RESTARTING
        mov     dptr,#XCOM1+IER
        mov     a,#IER_Rx OR IER_MODEST OR IER_RLS ; enable Receive Interrupt
        movx    @dptr,a
        ENDIF

        ret

EXAR_RxIL:
        mov     dptr,#XCOM1+LSR         ; Is there data on COM1 input FIFO?
        movx    a,@dptr
        
        IF      EXAR_TALLYING
        jnb     acc.7,EXAR_RxINormal
        mov     mth_op1ll,a             
        call    EXAR_DiagNose
        mov     a,mth_op1ll
EXAR_RxINormal:
        ENDIF
        
        jnb     acc.0,EXAR_RxIX         ; No more so exit
        mov     dpl,#XCOM1+RHR          ; Yes
        movx    a,@dptr                 ; Read
        jb      xcom1_Full,EXAR_RxID    ; Buffer Full, Drop the Data
        mov     dph,#xcom1_buffer SHR 8 ; Find Place in Circular Input Buffer
        mov     dpl,xcom1_write_cursor  ; By Means of the Running Cursor
        movx    @dptr,a                 ; Write the Data to XRAM
        
        IF      EXAR_COUNTING
        mov     dptr,#exar_charsI
        call    EXAR_Counter
        ENDIF

        inc     xcom1_write_cursor      ; Advance the Input Cursor
        mov     a,xcom1_read_cursor     ; If write starts to equal read
        cjne    a,xcom1_write_cursor,EXAR_RxIL
        setB    xcom1_Full              ; Stop reading from FIFO to XRAM
        call    RS232_AreYouGoingToDoAnythingAboutThis?
        
        jmp     EXAR_RxIL               ; Is there any more?

EXAR_RxID:                              ; Dropped Character
        mov     dptr,#exar_charsD
        call    EXAR_Counter
        jmp     EXAR_RxIL

EXAR_RxIX:
        
BUGLE2  EQU     0        
        IF      BUGLE2
        push    b
        push    acc
        swap    a
        call    hexchar    
        mov     b,a
        call    LCD_BugA
        pop     acc
        push    acc
        call    hexchar
        mov     b,a
        call    LCD_BugB
        pop     acc
        pop     b
        ENDIF
                                        ; Keyboard ISR does
                                        ; Register/State Restores
        ret                             ; Not RETI. 
                                        ; KeyBoard ISR called this Routine

        $endif
        
        END
