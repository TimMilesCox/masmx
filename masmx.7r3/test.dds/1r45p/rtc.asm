;*******************************************************************************
;
; File     : RTC.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the realtime clock driver routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
; 1.
;   The TIM_GetDateTime () and TIM_GetDateTimeCustom (DPTR buffer) functions
;   both read the current date/time from the real time clock into a 4 byte
;   buffer in XRAM. (The Custom version allows the buffer to be specified).
;
;   All of the values stored in the buffer are in binary and the format of the
;   buffer is:
;
;       1st byte        2nd byte        3rd byte        4th byte
;   +---------------+---------------+---------------+---------------+
;   |d|d|d|d|d|m|m|m|m|y|y|y|y|y|y|y| | | | | |h|h|h|h|h|m|m|m|m|m|m|
;   +---------------+---------------+---------------+---------------+
;
; 2.
;   The RTC only maintains a year count between 0 and 3. Two bytes of free RAM
;   within the RTC are used to generate a year between 00 and 99. Location 010h
;   holds the actual calculated year in binary between 0 and 99. Location 011h
;   holds the lowest two bits of the year read from the RTC (loc 05h). When the
;   RTC is read, if the two bits from the RTC do not equal the cached two bits
;   at location 011h, we obviously need to update locations 010h and 011h.
;
; 3.
;   The one minute interrupt (to update the LCD date/time display) is achieved
;   by setting a one minute timer to generate an interrupt. The interrupt
;   routine reloads the timer. The side effect of doing it this way is that
;   although an interrupt comes through every minute, it is not synchronised
;   to the seconds counter, so the time seen by the user could be + or - one
;   minute from what the RTC is, but the RTC never falls behind, so its not
;   a problem.
;
;*******************************************************************************

RTC_SLAVE       EQU 050h        ; philips 8583 RTC slave address

datebuffer:     VAR 2           ; default date buffer
timebuffer:     VAR 2           ; default time buffer

timer_control   EQU 1+2+8+64    ; timer, minutes, minutes
timer_reload    EQU 99h         ; 1 minute timeout

;******************************************************************************
;
; Function:     TIM_InitialiseClock
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Sets up the real time clock to generate interrupts every minute, providing
;   the timer reloading is done from the interrupt routine.
;
;******************************************************************************

TIM_InitialiseClock:
	IF DT5
	ELSE
	 CALL   TIM_StopCounting                ; stop clock

	 MOV    R1,#RTC_SLAVE                   ; set timer mode
	 MOV    DPTR,#8                         ; to minutes
	 MOV    B,#timer_control                ;
	 CALL   I2C_Write8                      ;

	 MOV    R1,#RTC_SLAVE                   ; set reload value
	 MOV    DPTR,#7                         ; to get 1 minute
	 MOV    B,#timer_reload                 ; intervals
	 CALL   I2C_Write8                      ;

	 CALL   TIM_StartCounting               ; start clock
	 SETB   EX1                             ; enable INT1 from the RTC
	 SETB   IT1                             ; look for falling edge
	 SETB   tim_timerenabled
	ENDIF
	RET

;******************************************************************************
;
; Function:     TIM_EnableTimer
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;
;******************************************************************************
	IF DT5
	ELSE
TIM_EnableTimer:
	SETB    tim_timerenabled
	SETB    tim_timerupdate
	RET

;******************************************************************************
;
; Function:     TIM_DisableTimer
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;
;******************************************************************************

TIM_DisableTimer:
	CLR     tim_timerenabled
	RET
	ENDIF

;******************************************************************************
;
; Function:     TIM_StartCounting
; Input:        None
; Output:       A=0 if ok, A<>0 if not ok
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Starts the real time clock in count mode.
;
;******************************************************************************

TIM_StartCounting:
	MOV     R1,#RTC_SLAVE                   ; disable counting and alarm
	MOV     DPTR,#0                         ;
	MOV     B,#5                            ;
	CALL    I2C_Write8                      ;
	RET

;******************************************************************************
;
; Function:     TIM_StopCounting
; Input:        None
; Output:       A=0 if ok, A<>0 if not ok
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Stops the real time clock counting, allowing counters to be written to.
;
;******************************************************************************

TIM_StopCounting:
	MOV     R1,#RTC_SLAVE                   ; disable counting and alarm
	MOV     DPTR,#0                         ;
	MOV     B,#128                          ;
	CALL    I2C_Write8                      ;
	RET

;******************************************************************************
;
; Function:     TIM_ClockAlarm
; Input:        INTERRUPT
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Called once a minute. Reloads the timer alarm for the next minute.
;
;******************************************************************************

TIM_ClockAlarm:
	PUSHPSW                         ; save regs
	PUSHACC                         ;
	PUSHB                           ;
	PUSHDPH                         ;
	PUSHDPL                         ;
	
;        IF      LCD_BUG EQ 'K'
;        mov     b,#'K'
;        call    LCD_BugA
;        ENDIF
	
	ANL     PSW,#0E7h                       ; and switch
	ORL     PSW,#008h                       ; to reg bank 1

;        JNB    lcd_backlight,TIM_CAnobacklight ; handle the delayed
;        MOV    A,lcd_delaybacklite             ; backlight powerdown
;        JZ     TIM_CAnobacklight               ;
;        DEC    A                               ;
;        MOV    lcd_delaybacklite,A             ;
;        JNZ     TIM_CAnobacklight              ;
;        CLR    lcd_backlight                   ;
;        CALL   LCD_SetBacklightIntensity       ;
;TIM_CAnobacklight:                             ;

	SETB    tim_timerupdate                 ; indicate LCD update required

;??? maybe remove this?
	MOV     R1,#RTC_SLAVE                   ; set timer control byte
	MOV     DPTR,#8                         ; for minute timing
	MOV     B,#timer_control                ;
	CALL    I2C_Write8                      ;
;??
	MOV     R1,#RTC_SLAVE                   ; set timer reload
	MOV     DPTR,#7                         ; value for one minute
	MOV     B,#timer_reload                 ;
	CALL    I2C_Write8                      ;

	MOV     R1,#RTC_SLAVE                   ; read the status and
	MOV     DPTR,#0                         ; toggle the timer interrupt
	CALL    I2C_Read8                       ; bit
	MOV     A,B                             ;
	XRL     A,#1                            ; (8583 interrupts are not
	MOV     B,A                             ; proper interrupts, they
	MOV     DPTR,#0                         ; toggle the interrupt line,
	MOV     R1,#RTC_SLAVE                   ; rather than pulsing it)
	CALL    I2C_Write8                      ;

	POP     DPL                             ; restore registers
	POP     DPH                             ;
	POP     B                               ;
	POP     ACC                             ;
	POP     PSW                             ; restore reg bank
	RETI

;******************************************************************************
;
; Function:     TIM_SetDate
; Input:        DPTR=address of 4 byte date buffer
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Sets the date in the real time clock to that specified by the contents of
;   the 4 byte (binary) buffer specified by DPTR.
;
;******************************************************************************

TIM_SetDate:
	PUSHDPH
	PUSHDPL
	CALL    TIM_StopCounting
	POP     DPL
	POP     DPH

	CALL    MTH_LoadOp1Long
	MOV     A,#100
	CALL    MTH_LoadOp2Acc
	CALL    MTH_Divide32by16                ; op2 = year
	MOV     A,mth_op2ll
	PUSHACC

	MOV     R1,#RTC_SLAVE                   ; store year
	MOV     DPTR,#010h                      ; in location 010h
	MOV     B,A                             ;
	CALL    I2C_Write8                      ;

	POP     ACC                             ; store year mod 4
	ANL     A,#3                            ; in location 011h
	PUSHACC                         ;
	MOV     DPTR,#011h                      ;
	MOV     B,A                             ;
	MOV     R1,#RTC_SLAVE                   ;
	CALL    I2C_Write8                      ;

	MOV     DPTR, #man_dateformat
	MOVX    A, @DPTR
	JNZ     TIM_SetDateUSA

	MOV     A,#100
	CALL    MTH_LoadOp2Acc
	CALL    MTH_Divide32by16                ; Brit: op1=day, op2=month
	MOV     A,mth_op2ll                     ;  USA: op1=month, op2=day
	CALL    BINtoBCD                        ;

	MOV     B,A                             ; store months
	MOV     DPTR,#06h                       ;
	MOV     R1,#RTC_SLAVE                   ;
	CALL    I2C_Write8                      ;

;??? comment which two fields are being ORed here
	POP     ACC                             ;
	RR      A                               ;
	RR      A                               ;
	PUSHACC                         ;
	MOV     A,mth_op1ll                     ;
	CALL    BINtoBCD                        ;
	POP     B                               ;
	ORL     A,B                             ;

	MOV     B,A                             ; store ??? here
	MOV     DPTR,#05h                       ;
	MOV     R1,#RTC_SLAVE                   ;
	CALL    I2C_Write8                      ;

	CALL    TIM_StartCounting
	RET

TIM_SetDateUSA:
	MOV     A,#100
	CALL    MTH_LoadOp2Acc
	CALL    MTH_Divide32by16                ; Brit: op1=day, op2=month
	MOV     A,mth_op1ll                     ;  USA: op1=month, op2=day
	CALL    BINtoBCD                        ;

	MOV     B,A                             ; store months
	MOV     DPTR,#06h                       ;
	MOV     R1,#RTC_SLAVE                   ;
	CALL    I2C_Write8                      ;

;??? comment which two fields are being ORed here
	POP     ACC                             ;
	RR      A                               ;
	RR      A                               ;
	PUSHACC                         ;
	MOV     A,mth_op2ll                     ;
	CALL    BINtoBCD                        ;
	POP     B                               ;
	ORL     A,B                             ;

	MOV     B,A                             ; store ??? here
	MOV     DPTR,#05h                       ;
	MOV     R1,#RTC_SLAVE                   ;
	CALL    I2C_Write8                      ;

	CALL    TIM_StartCounting
	RET

;******************************************************************************
;
; Function:     TIM_SetTime
; Input:        DPTR=address of 4 byte time value
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Sets the time in the real time clock to that specified by the contents of
;   the 4 byte (binary) buffer specified by DPTR.
;
;******************************************************************************

TIM_SetTime:
	CALL    TIM_StopCounting
	CALL    MTH_LoadOp1Long
	MOV     A,#100
	CALL    MTH_LoadOp2Acc
	CALL    MTH_Divide32by16                ; op1=hours, op2 = minutes
	MOV     A,mth_op2ll
	CALL    BINtoBCD

	MOV     B,A                             ; store the minutes
	MOV     R1,#RTC_SLAVE                   ;
	MOV     DPTR,#003h                      ;
	CALL    I2C_Write8                      ;

	MOV     A,mth_op1ll
	CALL    BINtoBCD

	MOV     B,A                             ; store the hours
	MOV     R1,#RTC_SLAVE                   ;
	MOV     DPTR,#004h                      ;
	CALL    I2C_Write8                      ;

	MOV     R1,#RTC_SLAVE                   ; reset seconds to zero
  MOV DPTR,#002h
	MOV     B,#000h
	CALL    I2C_Write8                      ;

	CALL    TIM_StartCounting
	RET

;******************************************************************************
;
; Function:     TIM_GetDateTime
; Input:        None
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Reads the current date & time from the real time clock into the standard
;   date/time buffer.
;
;******************************************************************************

TIM_GetDateTime:
        IF USE_ALTONCOMMS OR USE_ALTON_FAST
        $note true
	ELSE
        $note false
	MOV     DPSEL,#0
	MOV     DPTR,#datebuffer

	ENDIF
        $note anyway
;       fall thru to next routine

;******************************************************************************
;
; Function:     TIM_GetDateTimeCustom
; Input:        DPTR0 = where to store date/time stamp.
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Reads the current date & time from the real time clock.
;
;******************************************************************************

TIM_GetDateTimeCustom:

        IF USE_ALTONCOMMS OR USE_ALTON_FAST
        $note TRUE
	ELSE
        $note FALSE
	MOV     R1,#RTC_SLAVE           ; prepare to use I2C RTC

	MOV     DPSEL,#1                ; read the days
	MOV     DPTR,#05h               ;
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail2            ;
	MOV     A,B                     ;
	ANL     A,#03Fh                 ;
	CALL    BCDtoBIN                ; days in binary
	RL      A                       ;
	RL      A                       ;
	RL      A                       ;
	MOV     DPSEL,#0                ;
	MOVX    @DPTR,A                 ; store days

	MOV     DPSEL,#1                ; read the months
	MOV     DPTR,#06h               ;
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail2            ;
	MOV     A,B                     ;
	ANL     A,#01Fh                 ;
	CALL    BCDtoBIN                ; months in binary
	PUSHACC                 ;
	RR      A                       ;
	ANL     A,#7                    ;
	MOV     B,A                     ;
	MOV     DPSEL,#0                ;
	MOVX    A,@DPTR                 ; store upper 3 bits of months
	ORL     A,B                     ;
	MOVX    @DPTR,A                 ;
	INC     DPTR                    ;
	POP     ACC                     ;
	ANL     A,#001h                 ;
	RR      A                       ;
	MOVX    @DPTR,A                 ; store lower 1 bit of months

	MOV     DPSEL,#1                ; put our cached 2 bit year code
	MOV     DPTR,#11h               ; on the stack
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail2            ;
	MOV     A,B                     ;
	PUSHACC                 ;
	MOV     DPTR,#05h               ; read the 2 bit year code from the RTC
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail2            ;
	MOV     A,B                     ;
	ANL     A,#0C0h                 ;
	RL      A                       ;
	RL      A                       ;
	MOV     B,A                     ;
	POP     ACC                     ;
	CJNE    A,B,TIM_GDTyearnotok    ; if both 2 bit year codes
	JMP     TIM_GDTyearok           ; are different
;---
TIM_GDTfail2:
	JMP     TIM_GDTfail
;---
TIM_GDTyearnotok:                       ; then
	MOV     DPTR,#11h               ; cache the new 2 bit year code
	CALL    I2C_Write8              ;
	JNZ     TIM_GDTfail2            ;
	MOV     DPTR,#10h               ; and increment the year count...
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail             ;
	MOV     A,B                     ;
	INC     A                       ;
	CJNE    A,#100,TIM_GDTnowrap    ; ...wrapping from 99 to 0
	MOV     A,#0                    ; if necessary
TIM_GDTnowrap:                          ;
	MOV     B,A                     ;
	MOV     DPTR,#10h               ;
	CALL    I2C_Write8              ;
	JNZ     TIM_GDTfail             ;
;??? can probably remove next 4 lines since B holds new year count
TIM_GDTyearok:                          ; finally, re-read the new year count
	MOV     DPTR,#10h               ;
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail             ;
	MOV     DPSEL,#0                ;
	MOVX    A,@DPTR                 ;
	ORL     A,B                     ;
	MOVX    @DPTR,A                 ; store the year
	INC     DPTR                    ;

	MOV     DPSEL,#1                ; read the hours
	MOV     DPTR,#04h ; was 4 ???   ;
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail             ;
	MOV     A,B                     ;
	ANL     A,#03Fh                 ;
	CALL    BCDtoBIN                ;
	PUSHACC                         ;
	RR      A                       ;
	RR      A                       ;
	ANL     A,#7                    ;
	MOV     DPSEL,#0                ;
	MOVX    @DPTR,A                 ; store upper 3 bits of hours
	INC     DPTR                    ;
	POP     ACC                     ;
	ANL     A,#3                    ;
	RR      A                       ;
	RR      A                       ;
	MOVX    @DPTR,A                 ; store lower 2 bits of hours

	MOV     DPSEL,#1                ; read the minutes
	MOV     DPTR,#03 ; ??? was 3    ;
	CALL    I2C_Read8               ;
	JNZ     TIM_GDTfail             ;
	MOV     A,B                     ;
	ANL     A,#07Fh                 ;
	CALL    BCDtoBIN                ;
	MOV     B,A                     ;
	MOV     DPSEL,#0                ;
	MOVX    A,@DPTR                 ;
	ORL     A,B                     ;
	MOVX    @DPTR,A                 ; store minutes

	ENDIF ;ALTONCOMMS
        $NOTE  ANYWAY
TIM_GDTfail:
	RET

;******************************* End Of RTC.ASM ******************************
