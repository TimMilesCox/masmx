;******************************************************************************
;
; File     : LCD2X24.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the LCD driver for the HD44780
;            24x2 character display.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;***********
; Prototypes
;***********

;void LCD_Init (void)
;void LCD_SetBacklightIntensity (ACC intensity)
;void LCD_TurnBacklightOn (void)
;void LCD_SetTimeout (void)
;void LCD_ActivityDetected (void)
;ACC LCD_ReadStatus (void)
;void LCD_WriteData (ACC char)
;void LCD_WriteCommand (ACC command)
;void LCD_TurnBlinkOn (void)
;void LCD_TurnBlinkOff (void)
;void LCD_DisplayStringXRAM (DPTR *string, R7 len)
;void LCD_DisplayStringCODE (DPTR *string)
;void LCD_GotoXY (A xy)
;void LCD_Clear1 (void)
;void LCD_Clear2 (void)
;void LCD_Clear (void)

;********************
; Variables + Defines
;********************

LCD_BACKLIGHT_ON        EQU 200         ; set default backlight intensity

lcd_cmd_clear           EQU     001h
lcd_cmd_home            EQU     002h
lcd_cmd_entryset        EQU     004h
lcd_cmd_disponoff       EQU     008h
lcd_cmd_shift           EQU     010h
lcd_cmd_funcset         EQU     020h
lcd_cmd_setcgaddr       EQU     040h
lcd_cmd_setddaddr       EQU     080h

lcd_8bitmode            EQU     16
lcd_4bitmode            EQU     0
lcd_2lines              EQU     8
lcd_5x7dots             EQU     0
lcd_increment           EQU     2
lcd_dispon              EQU     4
lcd_cursoron            EQU     2
lcd_blinkon             EQU     1

	IF VT10

lcd_initstr:
;          c  d  c  d (c=code, d=delay in 100us)
	DB 3,50         ; Function Set, 8 bits
	DB 3, 1         ; Function Set, 8 bits
	DB 3, 1         ; Function Set, 8 bits
	DB 2, 1         ; Function Set, 4 bits
	DB 2, 1, 8, 1   ; Function Set, 4 bits, 2 lines, 5x7 dots
	DB 0, 1,12,50   ; Display On, disp, no cursor, no blink
	DB 0, 1, 6, 1   ; Entry Mode Set, Increment
	DB 0, 1, 1,20   ; Clear Display

	ELSE

lcd_initstr:
;          c  d  c  d (c=code, d=delay in 100us)
	DB 3,41         ; Function Set, 8 bits
	DB 3, 1         ; Function Set, 8 bits
	DB 3, 1         ; Function Set, 8 bits
	DB 2, 1         ; Function Set, 4 bits
	DB 2, 1, 8, 1   ; Function Set, 4 bits, 2 lines, 5x7 dots
	DB 0, 1, 8, 1   ; Display On/Off, no disp, no cursor, no blink
	DB 0,17, 1,17   ; Clear Display
	DB 0, 1, 6, 1   ; Entry Mode Set, Increment
	DB 0, 1,12, 1   ; Display On/Off, disp, no cursor, no blink

	ENDIF

lcd_charset:
	DB 006h,009h,009h,01Ch,008h,008h,01Fh,000h ; pound sign
	DB 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,000h ; black
	DB 000h,004h,00Eh,015h,004h,004h,000h,000h ; up arrow
	DB 000h,004h,004h,015h,00Eh,004h,000h,000h ; down arrow
	DB 000h,010h,008h,004h,002h,001h,000h,000h ; backslash
	DB 000h,000h,000h,000h,000h,000h,000h,000h ; spare
	DB 000h,000h,000h,000h,000h,000h,000h,000h ; spare
	DB 0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh,000h ; solid block

;******************************************************************************
;
; Function:     LCD_Init
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Initialises the LCD into 4-bit mode, clears the display, moves the
;   cursor to position 0, turns off blink and cursor.
;
;******************************************************************************

LCD_Init:

	IF VT10

	CALL    LCD_TurnBacklightOn

	MOV     R0,#150
	CALL    delay100us      ; 15ms delay

	MOV     DPTR,#lcd_initstr
	MOV     R7,#12
LCD_Iloop:
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	MOV     B,A
	CALL    SBS_Write
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	MOV     R0,A
	CALL    delay100us
	DJNZ    R7,LCD_Iloop
	RET     

	ELSE

	CALL    LCD_TurnBacklightOn

	MOV     R0,#150
	CALL    delay100us      ; 15ms delay

	MOV     DPTR,#lcd_initstr
	MOV     R7,#14
LCD_Iloop:
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	MOV     B,A
	MOV     A,#SB0
	CALL    SBS_Write
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	MOV     R0,A
	CALL    delay100us
	DJNZ    R7,LCD_Iloop
	RET     

	ENDIF

;********************************************************************************
LCD_LoadCharSet:

	MOV     DPTR,#lcd_charset
	MOV     A,#lcd_cmd_setcgaddr
	CALL    LCD_WriteCommand
	MOV     R7,#64
LCD_Iloop2:
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	CALL    LCD_WriteData
	DJNZ    R7,LCD_Iloop2

	MOV     A,#lcd_cmd_setddaddr
	CALL    LCD_WriteCommand
	RET

;******************************************************************************
;
; Function:     LCD_SetBacklightIntensity
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_SetBacklightIntensity:
	ORL     CMEN,#008h
	ORL     CMSEL,#008h
	MOV     CMH3,A
	MOV     CML3,#0
	RET

;******************************************************************************
;
; Function:     LCD_TurnBacklightOn
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_TurnBacklightOn:
;       MOV     A,#LCD_BACKLIGHT_ON
;        CALL   LCD_SetBacklightIntensity
;        SETB   lcd_backlight
;        CALL   LCD_SetTimeout
	CLR     BackLight
	RET
;******************************************************************************
;
; Function:     LCD_TurnBacklightOff
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_TurnBacklightOff:
;       MOV     A,#LCD_BACKLIGHT_ON
;        CALL   LCD_SetBacklightIntensity
;        SETB   lcd_backlight
;        CALL   LCD_SetTimeout
	SETB    BackLight
	RET

;******************************************************************************
;
; Function:     LCD_SetTimeout
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_SetTimeout:
	IF      VT10
	MOV     A,#4
	MOV     lcd_delaybacklite,A
	RET
	ELSE
	MOV     DPTR,#man_backlighttime
	MOVX    A,@DPTR
	JZ      LCD_STok
	INC     A
LCD_STok:
	MOV     lcd_delaybacklite,A
	RET
	ENDIF
;******************************************************************************
;
; Function:     LCD_ActivityDetected
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_ActivityDetected:
	SETB    lcd_backlight
	CALL    LCD_TurnBacklightOn
	CALL    LCD_SetTimeout
	RET

;******************************************************************************
;
; Function:     LCD_ReadStatus
; Input:        None
; Output:       A=status byte
; Preserved:    ?
; Destroyed:    A,B
; Description:
;   etc
;
;******************************************************************************
; suspect this doesnt work...check it out sometime. 
LCD_ReadStatus:

	IF VT10
	PUSHB
	MOV     P5,#01100000b   ; ask for busy flag / address
	CLR     LCDEnableStrobe
	MOV     P5,#00101111b   ; Pull up Inputs !!!
	MOV     A,P5            ; read the data (high nibble)
	SETB    LCDEnableStrobe ;
	ANL     A,#00001111b
	SWAP    A
	MOV     B,A
	CLR     LCDEnableStrobe ; fire the clock
	MOV     A,P5            ; read the data (low nibble)
	SETB    LCDEnableStrobe ;
	ANL     A,#00001111b
	ORL     A,B
	POP     B
	RET

	ELSE

	CALL    SYS_DisableInts
	ANL     P4,#09Fh        ; select LCD on SBUS address
	MOV     P5,#32          ; ask for busy flag / address
	CLR     P4.7            ; fire the clock
	MOV     A,P5            ; read the data (high nibble)
	SETB    P4.7            ;
	ANL     A,#00Fh
	SWAP    A
	MOV     B,A
	CLR     P4.7            ; fire the clock
	MOV     A,P5            ; read the data (low nibble)
	SETB    P4.7            ;
	ANL     A,#00Fh
	ORL     A,B
	CALL    SYS_EnableInts
	RET

	ENDIF
;******************************************************************************
;
; Function:     LCD_WriteData
; Input:        A=character to write
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Outputs the specified character at the current lcd position.
;
;******************************************************************************
LCD_WriteData
	IF VT10

	PUSHACC
	CALL    delay_40us
	SWAP    A
	ANL     A,#00001111b
	ORL     A,#01010000b    ; set RS
	MOV     P5,A            ; write high nibble
	CLR     LCDEnableStrobe ; fire the clock
	SETB    LCDEnableStrobe ;
	POP     ACC
	PUSHACC
	ANL     A,#00001111b
	ORL     A,#01010000b    ; set RS
	MOV     P5,A            ; write low nibble
	CLR     LCDEnableStrobe ; fire the clock
	SETB    LCDEnableStrobe ;
	POP     ACC
	RET

	ELSE

	PUSHACC
LCD_WDloop:
	CALL    LCD_ReadStatus
	ANL     A,#128
	JNZ     LCD_WDloop
	POP     ACC
	MOV     B,A
	SWAP    A
	ANL     A,#00Fh
	ORL     A,#16           ; set RS
	CALL    SYS_DisableInts
	ANL     P4,#09Fh                ; select LCD on SBUS address
	MOV     P5,A            ; write high nibble
	CLR     P4.7            ; fire the clock
	SETB    P4.7            ;
	MOV     A,B
	ANL     A,#00Fh
	ORL     A,#16           ; set RS
	MOV     P5,A            ; write low nibble
	CLR     P4.7            ; fire the clock
	SETB    P4.7            ;
	CALL    SYS_EnableInts
	RET

	ENDIF
;******************************************************************************
;
; Function:     LCD_WriteCommand
; Input:        A=command to send to lcd
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************
LCD_WriteCommand:

	IF VT10

	PUSHACC
	CALL    delay_40us
	SWAP    A
	ANL     A,#00001111b
	ORL     A,#01000000b
	MOV     P5,A            ; write high nibble
	CLR     LCDEnableStrobe ; fire the clock
	SETB    LCDEnableStrobe ;
	POP     ACC
	PUSHACC
	ANL     A,#00001111b
	ORL     A,#01000000b
	MOV     P5,A            ; write low nibble
	CLR     LCDEnableStrobe ; fire the clock
	SETB    LCDEnableStrobe ;
	POP     ACC
	RET

	ELSE

	PUSHACC
LCD_WCloop:
	CALL    LCD_ReadStatus
	ANL     A,#128
	JNZ     LCD_WCloop
	POP     ACC
	MOV     B,A
	SWAP    A
	ANL     A,#00Fh
	CALL    SYS_DisableInts
	ANL     P4,#09Fh        ; select LCD on SBUS address
	MOV     P5,A            ; write high nibble
	CLR     P4.7            ; fire the clock
	SETB    P4.7            ;
	MOV     A,B
	ANL     A,#00Fh
	MOV     P5,A            ; write low nibble
	CLR     P4.7            ; fire the clock
	SETB    P4.7            ;
	CALL    SYS_EnableInts
	RET

	ENDIF

;******************************************************************************
;
; Function:     LCD_TurnBlinkOn
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_TurnBlinkOn:
	MOV     A,#15
	CALL    LCD_WriteCommand
	RET

;******************************************************************************
;
; Function:     LCD_TurnBlinkOff
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_TurnBlinkOff:
	MOV     A,#12
	CALL    LCD_WriteCommand
	RET

;******************************************************************************
;
; Function:     LCD_DisplayStringXRAM
; Input:        DPTR=address of string in XRAM, R7 = number of chars
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_DisplayStringXRAM:
	MOVX    A,@DPTR
	INC     DPTR
	CJNE    A,#127,LCD_DSXok
	CLR     A
LCD_DSXok:
	CALL    LCD_WriteData
	DJNZ    R7,LCD_DisplayStringXRAM
	RET

;******************************************************************************
;
; Function:     LCD_DisplayStringCODE
; Input:        DPTR=address of string in CODE (1st byte = len)
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_DisplayStringCODE:
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	MOV     R7,A
LCD_DSCloop:
	CLR     A
	MOVC    A,@A+DPTR
	INC     DPTR
	CJNE    A,#127,LCD_DSCok
	CLR     A
LCD_DSCok:
	CALL    LCD_WriteData
	DJNZ    R7,LCD_DSCloop
	RET

;******************************************************************************
;
; Function:     LCD_GotoXY
; Input:        A=(y,x) position. Y in high 2 bits, X in bottom 6 bits
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Moves the current cursor position on the LCD.
;
;******************************************************************************

LCD_GotoXY:
	ORL     A,#lcd_cmd_setddaddr
	CALL    LCD_WriteCommand
	RET


;******************************************************************************
;
; Function:     LCD_Clear1 & LCD_Clear2
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************
LCD_Clear1:
	MOV     A,#0
	JMP     LCD_ClearLine
LCD_Clear2:
	MOV     A,#64
LCD_ClearLine:
	CALL    LCD_GotoXY
	MOV     R7,#24
LCD_CLloop:
	MOV     A,#32
	CALL    LCD_WriteData
	DJNZ    R7,LCD_CLloop
	RET

;******************************************************************************
;
; Function:     LCD_Clear
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LCD_Clear:
;;      MOV     A,#lcd_cmd_clear
;;      CALL    LCD_WriteCommand
 CALL LCD_Clear1
 CALL LCD_Clear2
	MOV     A,#0
	CALL    LCD_GotoXY
	RET

;******************************************************************************
;
; Function:     LCD_LanguageStringSelect
; Input:        DPTR - start of strings table
; Output:       DPTR - correct entry in strings table
; Preserved:    ?
; Destroyed:    A, B
; Description:
;   Selects the correct string from the string table for this output
;       depending on the setting of man_language
;
;******************************************************************************

LCD_LanguageStringSelect:

	CLR     A                       ; store size of table entries in B
	MOVC    A, @A+DPTR              ;
	INC     A                       ;
	MOV     B, A                    ;
	PUSHDPL
	PUSHDPH
	MOV     DPTR, #man_language     ; get the current langauge
	MOVX    A, @DPTR                ;
	MUL     AB                      ;
	POP     DPH
	POP     DPL
	CALL    AddABtoDPTR             ; set the DPTR to the correct string
	RET

	IF      LCD_BUG
LCD_BugA:
	mov     a,#64+16
	jmp     LCD_Bug1
LCD_BugB:
	mov     a,#64+17
	jmp     LCD_Bug1
LCD_BugC:
	mov     a,#64+18
	jmp     LCD_Bug1
LCD_Qbug:
	mov     a,#18
LCD_Bug1:
	push    B
	call    LCD_GoToXY
	pop     acc
	call    LCD_WriteData
	ret
	ENDIF


;******************************** End Of LCD.ASM ******************************
;

	End


