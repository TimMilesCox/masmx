;******************************************************************************
;
; File     : KEYBOARD.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the keyboard driver for the DT5
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

;void   KBD_InitKeyboard (void)
;void   KBD_DisableKeyInts (void)
;void   KBD_EnableKeyInts (void)
;ACC    KBD_ScanKeyboard (void)
;ACC    KBD_MapKeycode (ACC rawcode)
;void   KBD_ProcessKeyboard (interrupt)
;ACC    KBD_ReadKey (void)
;ACC    KBD_WaitKey (void)
;void   KBD_FlushKeyboard (void)
;ACC    KBD_OkOrCancel (void)

;********************
; Variables + Defines
;********************

KSELA   EQU P1.1
KSELB   EQU P1.2
KSELC   EQU P1.3


	IF USE_ALTONCOMMS
KBD_BUFSIZE     EQU 4   ; total characters in keyboard buffer
	ELSE
KBD_BUFSIZE     EQU 16  ; total characters in keyboard buffer
	ENDIF

KBD_WARNING     EQU 6   ; give warning when less than this value left in buffer

KBD_UP          EQU 15
KBD_DOWN        EQU 14
KBD_LEFT        EQU 13
KBD_RIGHT       EQU 16
KBD_CANCEL      EQU 19
KBD_OK          EQU 20
;KBD_FUNC       EQU 2
;KBD_MAN        EQU 1
NEWKEY          EQU 1
;******************************************************************************
;
; Function:     KBD_InitKeyboard
; Input:        None
; Output:       None
; Preserved:    All except A
; Destroyed:    A
; Description:
;
;******************************************************************************

KBD_InitKeyboard:
	CLR     A                       ; clear the keyboard buffer
	MOV     kbd_bufptr,A            ;
	MOV     kbd_buflen,A            ;
	CLR     kbd_functionkey         ;
	CLR     kbd_managerkey          ;
	CLR     kbd_shiftkey            ;
	CLR     kbd_diagskey            ;
	CLR     kbd_doublecancel

	IF VT10
	CALL    KBD_Set
	CALL    KBD_EnableKeyInts
	SETB    EX1                     ;Enable Int 1
	SETB    IT1
	MOV     DPTR,#Triggers          ;Clear Triggers
	MOV     A,#0                    ;
	MOVX    @DPTR,A                 ;
	MOV     DPTR,#Triggers2         ;Clear Triggers
	MOV     A,#0                    ;
	MOVX    @DPTR,A                 ;
	RET

	ELSE

;       SETB    P1.1                    ; prepare for interrupt
;       SETB    P1.2                    ;
;       SETB    P1.3                    ;
	SETB    KSELA                   ; prepare for interrupt
	SETB    KSELB                   ;
	SETB    KSELC                   ;

	CLR     I3FR                    ; INT3 generated on -ve edges (keypresses)
	SETB    EX3                     ; enable INT3
	RET

	ENDIF
;******************************************************************************
;
; Function:     KBD_DisableKeyInts
; Input:        None
; Output:       None
; Preserved:    All
; Destroyed:    None
; Description:
;   Disables keyboard interrupts only.
;
;******************************************************************************

KBD_DisableKeyInts:
	IF VT10

	CLR     EX2
	RET

	ELSE

	CLR     EX3
	RET

	ENDIF
;******************************************************************************
;
; Function:     KBD_EnableKeyInts
; Input:        None
; Output:       None
; Preserved:    All
; Destroyed:    None
; Description:
;   Enables keyboard interrupts
;
;******************************************************************************

KBD_EnableKeyInts:

	IF VT10
	SETB    EAL
	CLR     I2FR
	CLR     IEX2
	SETB    EX2
	RET

	ELSE

	SETB    EX3
	RET

	ENDIF
;******************************************************************************
KBD_Reset:
	PUSHACC
	MOV     A,#00111111b    ; reset keyboard decoder
	CALL    PortClrE
	POP     ACC
	RET
;******************************************************************************
KBD_Set:
	PUSHACC
	MOV     A,#00111111b
	CALL    PortSetE
	SETB    EX2
	POP     ACC
	RET
;******************************************************************************
KBD_Read:
	MOV     B,R0
	PUSHB
	CALL    PortSetE        ; Set Keyboard Select Lines to next Row
	MOV     R0,#1           ; prop. delay
	CALL    delay100us
	MOV     A,#00001111b
	CALL    PortReadA
	POP     B
	MOV     R0,B
	RET
;******************************************************************************
;
; Function:     KBD_ScanKeyboard
; Input:        None
; Output:       A=scancode
; Preserved:    ?
; Destroyed:    B,R0
; Description:
;   etc
;
;******************************************************************************

KBD_ScanKeyboard:

	IF VT10

	CALL    KBD_Reset
	
	push    1               ; absolute 1 = bank 0, R1
				; KBD_Read calls Delay routines which use r1
	MOV     A,#KeySelect0   ; and this is called from interrupt code
	CALL    KBD_Read
	CALL    KBD_Row1
	JNZ     KBD_ScanKeyExit

	CALL    KBD_Reset
	MOV     A,#KeySelect1
	CALL    KBD_Read
	CALL    KBD_Row2
	JNZ     KBD_ScanKeyExit

	CALL    KBD_Reset
	MOV     A,#Keyselect2
	CALL    KBD_Read
	CALL    KBD_Row3
	JNZ     KBD_ScanKeyExit

	CALL    KBD_Reset
	MOV     A,#KeySelect3
	CALL    KBD_Read
	CALL    KBD_Row4
	JNZ     KBD_ScanKeyExit

	CALL    KBD_Reset
	MOV     A,#KeySelect4
	CALL    KBD_Read
	CALL    KBD_Row5
	JNZ     KBD_ScanKeyExit

	CALL    KBD_Reset
	MOV     A,#KeySelect5
	CALL    KBD_Read
	CALL    KBD_Row6
	JNZ     KBD_ScanKeyExit

	CLR     A

KBD_ScanKeyExit:

	pop     1               ; absolute 1 = Bank 0, R1
				; KBD_Read calls delay routines which use R1
	CALL    KBD_Set         ; and this is called from interrupt code
	CALL    KBD_MapKeycode
	RET


;************************************************************************************
KBD_Row1:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,1,2,0,3,0,0,0,4,0,0,0,0,0,0,0

;************************************************************************************
KBD_Row2:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,5,6,0,7,0,0,0,8,0,0,0,0,0,0,0

;************************************************************************************
KBD_Row3:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,9,10,0,11,0,0,0,12,0,0,0,0,0,0,0

;************************************************************************************
KBD_Row4:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,13,14,0,15,0,0,0,16,0,0,0,0,0,0,0

;************************************************************************************
KBD_Row5:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,17,18,0,19,0,0,0,20,0,0,0,0,0,0,0

;************************************************************************************
KBD_Row6:
	ANL     A,#00001111b
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,21,22,0,23,0,0,0,24,0,0,0,0,0,0,0

;************************************************************************************
	ELSE

	MOV     R0,#7
	MOV     B,#0            ; no keycode yet
KBD_SKloop:
	MOV     A,#7
	CLR     C
	SUBB    A,R0
	RL      A
	ANL     P1,#0F1h                ; reset keyboard decoder
	ORL     P1,A            ; set keyboard decoder to next row
	NOP                     ; prop. delay
	NOP
	NOP
	MOV     A,P7
	CALL    KBD_ScanRow
	JZ      KBD_SKrowclear
	XCH     A,B
	JNZ     KBD_SKkeyjam    ; more than 1 key down
	MOV     A,#7
	CLR     C
	SUBB    A,R0
	RL      A
	RL      A
	ORL     A,B
	MOV     B,A
KBD_SKrowclear:
	DJNZ    R0,KBD_SKloop
	MOV     A,B
	CALL    KBD_MapKeycode
KBD_SKend:
;       SETB    P1.1            ; prepare for interrupt
;       SETB    P1.2
;       SETB    P1.3
	SETB    KSELA                   ; prepare for interrupt
	SETB    KSELB                   ;
	SETB    KSELC                   ;
	RET
KBD_SKkeyjam:
	ANL     P1,#0F1h                ; reset keyboard decoder
	ORL     P1,#10          ; set keyboard decoder to 3rd row
	NOP
	NOP
	NOP
	NOP
	MOV     A,P7
	ANL     A,#7
	CJNE    A,#5,KBD_SKjam
	ANL     P1,#0F1h
	ORL     P1,#8
	NOP
	NOP
	NOP
	NOP
	MOV     A,P7
	ANL     A,#7
	CJNE    A,#3,KBD_SKjam

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	JMP     DT_ColdBoot
KBD_SKjam:
	CLR     A
	JMP     KBD_SKend

KBD_ScanRow:
	ANL     A,#7
	XRL     A,#7
	INC     A
	MOVC    A,@A+PC
	RET
	DB      0,1,2,0,3,0,0,0
	
	ENDIF
;******************************************************************************
;
; Function:     KBD_MapKeycode
; Input:        A=raw keycode
; Output:       A=mapped keycode
; Preserved:    All
; Destroyed:    None
; Description:
;   Converts a raw keycode to a DT5 keycode.
;
;******************************************************************************

KBD_MapKeycode:
	INC     A
	MOVC    A,@A+PC
	RET

kbd_keytable:   ; must follow the RET above

	IF VT10
	IF NEWKEY
	DB 0,2,3,4,13,5,6,7,14,8,9,10,15,19,1,20,16,11,12,13,14,12,12,20,19
	ELSE
	DB 0,13,12, 1,11,14,10, 9, 8,15, 7
	DB    6, 5,16, 4, 3, 2,17,18,19,20
	DB   17,18,19,20
	ENDIF
	ELSE

	DB 0,21,13,2,0, 17, 1,6,0, 15,11,4,0, 20,9,8,0
	DB   14,12,3,0, 18,10,7,0, 16,19,5,0,  0,0,0,0

	ENDIF
;******************************************************************************
;
; Function:     KBD_ProcessKeyboard
; Input:        INTERRUPT
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Interrupt routine called on detection of keypress. Scans the keyboard
;   matrix to see which key was pressed and adds it to the keyboard buffer.
;
;******************************************************************************

KBD_ProcessKeyboard:

	IF VT10

	PUSHPSW
	PUSHACC
;       PUSHR0
	MOV     A,R0
	PUSHACC
	PUSHB
	PUSHDPH
	PUSHDPL

	CALL    KBD_ScanKeyboard

	CALL    KBD_ProcessInternals
	CALL    LCD_ActivityDetected

	POP     DPL
	POP     DPH
	POP     B
	POP     ACC
;       POP     0
	MOV     R0,A
	POP     ACC
	POP     PSW
	CLR     IEX2
	CALL    KBD_Set
	RETI

	ELSE

	PUSHPSW
	PUSHACC
	MOV     A,R0
	PUSHACC
	PUSHB
	PUSHDPH
	PUSHDPL

	;CALL    LCD_ActivityDetected   ;junk call for backlight timeout

	CALL    KBD_ScanKeyboard
	CALL    KBD_ProcessInternals

	POP     DPL
	POP     DPH
	POP     B
	POP     ACC
	MOV     R0,A
	POP     ACC
	POP     PSW
	CLR     IEX3            ; clear any further INT3 interrupts which
;       SETB    P1.1            ; came in while processing this one and
;       SETB    P1.2            ; prepare for next interrupt on INT3
;       SETB    P1.3
	SETB    KSELA                   ; prepare for interrupt
	SETB    KSELB                   ;
	SETB    KSELC                   ;
	RETI

	ENDIF
;*********************************************************************************
KBD_ProcessInternals:
	MOV     B,A                     ; store the keycode in B
	CJNE    A,#KBD_CANCEL,KBD_PKnotcan
	JB      kbd_1stcancel,KBD_PKgot1stcan
	SETB    kbd_1stcancel
	JMP     KBD_PKcancelok
KBD_PKgot1stcan:
	SETB    kbd_doublecancel
	JMP     KBD_PKcancelok
KBD_PKnotcan:
	CLR     kbd_doublecancel
	CLR     kbd_1stcancel
KBD_PKcancelok:

	MOV     A,kbd_buflen            ; test for keyboard buffer full
	CLR     C                       ;
	SUBB    A,#KBD_BUFSIZE          ;
	JNB     ACC.7,KBD_PKkbfull      ;

	MOV     A,kbd_buflen
	CJNE    A,#(KBD_BUFSIZE-KBD_WARNING),KBD_PKchk
KBD_PKwarning:
	MOV     A,#200                  ; keyboard warning bleep
	PUSHB                   ;
	MOV     B,#50                   ;

	IF      SPEAKER
	CALL    SND_Beep                ;
	ENDIF

	POP     B                       ;
	JMP     KBD_PKbleepsdone
KBD_PKchk:
	JNC     KBD_PKwarning
	MOV     A,#200                  ; normal keyboard bleep
	PUSHB                   ;
	MOV     B,#20                   ;

	IF      SPEAKER
	CALL    SND_Beep                ;
	ENDIF

	POP     B                       ;
KBD_PKbleepsdone:

	MOV     A,#kbd_keybuffer        ;
	ADD     A,kbd_bufptr            ; calculate insert address to keyboard buffer
	MOV     R0,A                    ;
	MOV     @R0,B                   ; insert the keypress
	INC     kbd_buflen              ;
	MOV     A,kbd_bufptr            ;
	INC     A                       ;
	ANL     A,#(KBD_BUFSIZE-1)      ;
	MOV     kbd_bufptr,A            ;

	IF USE_SERVANT
	 MOV    B,#2
	 CALL   COM_TxStatus
	ENDIF

	JMP     KBD_PKnokey             ;

KBD_PKkbfull:
	MOV     A,#200                  ; keyboard buffer full
	PUSHB                   ;
	MOV     B,#200                  ;

	IF      SPEAKER
	CALL    SND_Beep                ;
	ENDIF

	POP     B                       ;

	IF USE_SERVANT
	 MOV    B,#5
	 CALL   COM_TxStatus
	ENDIF

KBD_PKnokey:
	RET


;******************************************************************************
;
; Function:     KBD_ReadKey
; Input:        None
; Output:       A = keycode, or ZERO if no key available
; Preserved:    All except R0
; Destroyed:    R0
; Description:
;   Returns the keycode of the next keypress in the keyboard buffer
;   or ZERO if there are no keys in the keyboard buffer.
;
;******************************************************************************

KBD_ReadKey:

KBD_OLD EQU     2

	IF      KBD_OLD

	MOV     A,kbd_buflen            ; check if there are any chars in the
	JZ      KBD_RKfail              ; keyboard buffer
	MOV     A,kbd_bufptr
	ADD     A,#KBD_BUFSIZE
	SUBB    A,kbd_buflen
	ANL     A,#(KBD_BUFSIZE-1)
	ADD     A,#kbd_keybuffer
	MOV     R0,A                    ; R0 = address of char to remove
	MOV     A,@R0                   ; get the char
	DEC     kbd_buflen              ; one less char in buffer now

	IF      KBD_OLD EQ 2
	cjne    a,#11,kbd_not11
	jmp     kbd_11_12_13_14
kbd_not11:
	cjne    a,#12,kbd_not12
	jmp     kbd_11_12_13_14
kbd_not12:
	cjne    a,#13,kbd_not13
	jmp     kbd_11_12_13_14
kbd_not13:
	cjne    a,#14,kbd_nothing_new
kbd_11_12_13_14:
	add     a,#-10
	push    dph
	push    dpl
	mov     dptr,#tkt_printstatus
	movx    @dptr,a
	pop     dpl
	pop     dph
	add     a,#10
kbd_nothing_new:
	ENDIF
	    
KBD_RKfail:
	RET
	   
	ELSE

	PUSHDPH
	PUSHDPL
	MOV     A,kbd_buflen            ; check if there are any chars in the
	JZ      KBD_RKfail              ; keyboard buffer
	MOV     A,kbd_bufptr
	ADD     A,#KBD_BUFSIZE
	SUBB    A,kbd_buflen
	ANL     A,#(KBD_BUFSIZE-1)
	ADD     A,#kbd_keybuffer
	MOV     R0,A                    ; R0 = address of char to remove
	MOV     A,@R0                   ; get the char
	DEC     kbd_buflen              ; one less char in buffer now
	MOV     DPTR,#tkt_printstatus
	CJNE    A,#11,KBD_RK_B
	MOV     A,#1
	MOVX    @DPTR,A
KBD_RK_B:
	CJNE    A,#12,KBD_RK_C
	MOV     A,#2
	MOVX    @DPTR,A
KBD_RK_C:
	CJNE    A,#13,KBD_RK_D
	MOV     A,#3
	MOVX    @DPTR,A
KBD_RK_D:
	CJNE    A,#14,KBD_RKfail
	MOV     A,#4
	MOVX    @DPTR,A
	MOV     A,@R0
KBD_RKfail:
	POP     DPL
	POP     DPH
	RET
	ENDIF

;******************************************************************************
;
; Function:     KBD_WaitKey
; Input:        None
; Output:       ACC = key pressed
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

KBD_WaitKey:
	CALL    KBD_ReadKey
	JZ      KBD_WaitKey
	RET

;******************************************************************************
;
; Function:     KBD_FlushKeyboard
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Flushes all characters from the keyboard buffer including any that come in
;   while the routine is running.
;
;******************************************************************************

KBD_FlushKeyboard:
	CALL    KBD_ReadKey
	JNZ     KBD_FlushKeyboard
	RET

;******************************************************************************
;
; Function:     KBD_OkOrCancel
; Input:        None
; Output:       A=KBD_OK or A=0
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Waits for OK or CANCEL to be pressed
;
;******************************************************************************

KBD_OkOrCancel:
	CALL    KBD_ReadKey
	JZ      KBD_OkOrCancel
	CJNE    A,#KBD_OK,KBD_OOCnotok
	RET
KBD_OOCnotok:
	CJNE    A,#KBD_CANCEL,KBD_OkOrCancel
	CLR     A
	RET

;******************************************************************************
;
; Function:     KBD_ForceKey
; Input:        A=key to force into keyboard buffer
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

KBD_ForceKey:
	PUSHACC
	PUSHB
;       PUSHR0
	MOV     B,R0
	PUSHB
	MOV     B,A
	MOV     A,kbd_buflen
	CJNE    A,#KBD_BUFSIZE,KBD_FK_DoIt
	JMP     KBD_FKExit
KBD_FK_DoIt:
	MOV     A,#kbd_keybuffer        ;
	ADD     A,kbd_bufptr            ; calculate insert address to keyboard buffer
	MOV     R0,A                    ;
	MOV     @R0,B                   ; insert the keypress
	INC     kbd_buflen              ;
	MOV     A,kbd_bufptr            ;
	INC     A                       ;
	ANL     A,#(KBD_BUFSIZE-1)      ;
	MOV     kbd_bufptr,A            ;
KBD_FKExit:
;       POP     0
	POP     B
	MOV     R0,B
	POP     B
	POP     ACC
	RET

;**************************** End Of KEYBOARD.ASM *****************************
;Active Low Inputs !
;This Routine Detects a falling edge and stuffs 'A' or 'B' into the keyboard buffer.
;
Triggers:       VAR     1
KBD_Read_Triggers:


	RET

;**************************************************************************************
;Active Low Inputs !
;This Routine Detects a falling edge and stuffs 'A' or 'B' into the keyboard buffer.
;
Triggers2:      VAR     1
Riktus          VAR     1

KBD_Read_Triggers2:

	PUSHPSW                         ; save regs
	PUSHACC
	PUSHB                           ;
	PUSHDPH                         ;
	PUSHDPL                         ;
	
	mov     a,p7
	jb      acc.0,KBD_RT_SkipSerialInput
	call    EXAR_RxInt
	orl     p7,#1
KBD_RT_SkipSerialInput:
	
	MOV     A,P7
	JB      ACC.2,KBD_RT_SkipRtc

	ANL     PSW,#0E7h                       ; and switch
	ORL     PSW,#008h                       ; to reg bank 1

	SETB    tim_timerupdate                 ; indicate LCD update required

;??? maybe remove this?
	
	MOV     R1,#RTC_SLAVE                   ; set timer control byte
	MOV     DPTR,#8                         ; for minute timing
	MOV     B,#timer_control                ;
	CALL    I2C_Write8                      ;
;??
	
	mov     a,p7
	jb      acc.0,KBD_RT_1SkipSerialInput
	call    EXAR_RxInt
	orl     p7,#1
KBD_RT_1SkipSerialInput:
	
	MOV     R1,#RTC_SLAVE                   ; set timer reload
	MOV     DPTR,#7                         ; value for one minute
	MOV     B,#timer_reload                 ;
	CALL    I2C_Write8                      ;

	
	mov     a,p7
	jb      acc.0,KBD_RT_2SkipSerialInput
	call    EXAR_RxInt
	orl     p7,#1
KBD_RT_2SkipSerialInput:
	
	MOV     R1,#RTC_SLAVE                   ; read the status and
	MOV     DPTR,#0                         ; toggle the timer interrupt
	CALL    I2C_Read8                       ; bit
	MOV     A,B                             ;
	XRL     A,#1                            ; (8583 interrupts are not
	MOV     B,A                             ; proper interrupts, they
	MOV     DPTR,#0                         ; toggle the interrupt line,
	MOV     R1,#RTC_SLAVE                   ; rather than pulsing it)
	CALL    I2C_Write8                      ;

	
	mov     a,p7
	jb      acc.0,KBD_RT_3SkipSerialInput
	call    EXAR_RxInt
	orl     p7,#1
KBD_RT_3SkipSerialInput:
	
KBD_RT_SkipRtc:

	MOV     DPTR,#Triggers          ;Read Triggers
	MOVX    A,@DPTR                 ;
	JB      ACC.0,KBD_RT_A_Active   ;Check Bit 0
	MOV     A,#ProtSwIn1            ;Test Trigger
	CALL    PortReadD
	JNC     KBD_RT_A_End            ;End if Inactive
	MOVX    A,@DPTR
	ORL     A,#00000001b            ;Set Bit in Triggers
	MOVX    @DPTR,A
	MOV     A,#11                   ;Stuff 'A' int Key Buffer
	CALL    KBD_ForceKey
	JMP     KBD_RT_A_End            ;End
KBD_RT_A_Active:
	MOV     A,#ProtSwIn1            ;Test Trigger
	CALL    PortReadD
	JC      KBD_RT_A_End            ;End if Active
	MOVX    A,@DPTR                 ;Clear Bit in Triggers                  
	ANL     A,#11111110b
	MOVX    @DPTR,A
KBD_RT_A_End    

	MOV     DPTR,#Triggers
	MOVX    A,@DPTR
	JB      ACC.1,KBD_RT_B_Active
	MOV     A,#ProtSwIn2    
	CALL    PortReadD
	JNC     KBD_RT_B_End
	MOVX    A,@DPTR
	ORL     A,#00000010b
	MOVX    @DPTR,A
	MOV     A,#12
	CALL    KBD_ForceKey
	JMP     KBD_RT_B_End
KBD_RT_B_Active:
	MOV     A,#ProtSwIn2
	CALL    PortReadD
	JC      KBD_RT_B_End
	MOVX    A,@DPTR
	ANL     A,#11111101b
	MOVX    @DPTR,A
KBD_RT_B_End    



	MOV     DPTR,#Triggers
	MOVX    A,@DPTR
	JB      ACC.2,KBD_RT_C_Active
	MOV     A,#ProtSwIn3    
	CALL    PortReadD
	JNC     KBD_RT_C_End
	MOVX    A,@DPTR
	ORL     A,#00000100b
	MOVX    @DPTR,A
	MOV     A,#13
	CALL    KBD_ForceKey
	JMP     KBD_RT_C_End
KBD_RT_C_Active:
	MOV     A,#ProtSwIn3
	CALL    PortReadD
	JC      KBD_RT_C_End
	MOVX    A,@DPTR
	ANL     A,#11111011b
	MOVX    @DPTR,A
KBD_RT_C_End    

	MOV     DPTR,#Triggers
	MOVX    A,@DPTR
	jb      acc.3,KBD_RT_D_Active
	MOV     A,#ProtSwIn4 OR ProtSwin3 OR ProtSwin2 OR ProtSwin1
	CALL    PortReadD
	JNC     KBD_RT_D_End
				    ; T,15x99 ^---- Mask All The Button Bits
	jb      acc.4,KBD_RT_D_End  ; T,15x99 Temp Fix -If A bit set skip
	jb      acc.5,KBD_RT_D_End  ; T,15x99 Temp Fix -If B bit set skip
	jb      acc.6,KBD_RT_D_End  ; T,15x99 Temp Fix -If C bit set skip

	MOVX    A,@DPTR
	orl     a,#00001000b
	MOVX    @DPTR,A
	MOV     A,#14
	CALL    KBD_ForceKey
	JMP     KBD_RT_D_End
KBD_RT_D_Active:
	MOV     A,#ProtSwIn4
	CALL    PortReadD
	JC      KBD_RT_D_End
	MOVX    A,@DPTR
	anl     a,#11110111b
	MOVX    @DPTR,A
KBD_RT_D_End 



	POP     DPL
	POP     DPH
	pop     b
	POP     ACC
	pop     psw
	RETI
;*****************************************************************************

	END



