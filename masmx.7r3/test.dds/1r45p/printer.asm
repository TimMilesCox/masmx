;******************************************************************************
;
; File     : PRINTER.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains printer independant (hopefully)
;            printing functions
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
; 1. auto call of LoadPaper removed from CheckPaper....user will have to ask
;    the machine to do a LoadPaper for the moment.
;
; 2.
;   The perfmark updated by the line feeder keeps a track of how many half
;   lines have been fed since the start of the black mark. The important
;   points along this scale are:
;
;   Black Line Start                                    0
;   Last Sensible Place To Start A Char Line            215
;   Last Sensible Place To Start A Pixel Line           215+16
;   Next Sensible Place To Print If Plain Perf Paper    215+32
;   Perforation Line At Tear Bar                        314
;   End Of Customer Logo, Ready To Print                314+headerfeed
;   End Of Physical Ticket                            < 900

;******************************************************************************

PULSE_LENGTH            EQU     12      ; a millisecond for each pulse
PULSE_DELAY             EQU     12      ; a millisecond for each pulse


;******************************************************************************
;
; Function:     PRT_CheckPaper
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************
PRT_msg_Spit    DB 7 ,'Loading'
PRT_msg_Load    DB 14,'Load Paper And'
PRT_msg_AnyKey  DB 14,'Press Any Key '
PRT_CheckPaper:

; PERF handling code - arithmetic simplified by assuming that a portion
;  of paper will be at least 256 perfcounts long

; CALL ViewPerf                         ; Used for DEBUGGING
; CALL PRT_DetectPaper                  ; Used for DEBUGGING

	MOV     A,P7                    ; read the papersense port
	MOV     C,prt_paper_sense       ; if paper present, take the quick
	JNC     PRT_IPpaperok           ; way out and update perfmark
;       MOV     prt_paperout,C
	SETB    prt_perfmode            ; black line - assume perf mode
	MOV     A,prt_perfmarkhigh      ; if perfmark <= perflinemin
	JNZ     PRT_IPwhitetoblack      ; then we are still within the allowed
	CLR     C                       ; limits for the black line
	MOV     A,prt_perflinemin       ; I.e, we must assume that paper is still
	SUBB    A,prt_perfmarklow       ; present since it is possible we are
	JNC     PRT_IPmakepaperok       ; within the black line

	CLR     C                       ; if perfmark <= perflinemax
	MOV     A,prt_perflinemax       ; then we've hit the end of the paper
	SUBB    A,prt_perfmarklow       ;
	JC      PRT_IPwhitetoblack      ;
;       SETB    prt_paperout            ;
	MOV     A,R7
	PUSHACC

	IF USE_SERVANT
	 CALL   COM_StopStatusTransmit
;        MOV    B,#0
;        MOV    A,#'b'
;        CALL   COM_TxChar
	ENDIF

;       CALL    LCD_Clear
;       MOV     DPTR,#PRT_msg_Spit
;       CALL    LCD_DisplayStringCODE


	JB      prt_paperout,PRT_CPMissOut
	MOV     R7,#0                   ; spit the last half-inch out
PRT_CPloop:
	CALL    PRT_GeneratePulse
	CALL    PRT_LineFeedDelay
	DJNZ    R7,PRT_CPloop
PRT_CPMissOut


	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
	ENDIF
	SETB    prt_paperout
	POP     ACC
	MOV     R7,A

	IF      LEDS
	CALL    LED_Led1Flash           ; signal paperout
	ENDIF

;       CALL    PRT_LoadPaper           ; and load paper
; commented out cos of the possible infinite recursion thru formfeed/checkpaper
; see note 1
	RET

PRT_IPwhitetoblack:
	MOV     prt_perfmarklow,#0      ; must have just hit a black line after a
	MOV     prt_perfmarkhigh,#0     ; substantial amount of white paper
	CLR     prt_paperout
	RET

PRT_IPmakepaperok:
	CLR     prt_paperout
PRT_IPpaperok:
	JNB     prt_paperout,PRT_IPwasok
	MOV     prt_paperout,C

	IF      LEDS
	CALL    LED_Led1On
	ENDIF

PRT_IPwasok:
	INC     prt_perfmarklow
	MOV     A,prt_perfmarklow
	JNZ     PRT_IPcheckplain
	INC     prt_perfmarkhigh
PRT_IPcheckplain:
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perffailhigh,PRT_CPne
PRT_CPlteq:
	JMP     PRT_IPplain
PRT_CPne:
	JC      PRT_IPdone
PRT_IPplain:
	CLR     prt_perfmode
	MOV     prt_perfmarklow,#0
	MOV     prt_perfmarkhigh,#0
PRT_IPdone:
	RET

;******************************************************************************
;
; Function:     PRT_LineFeed
; Input:        R7 = number of steps
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Feeds the printer's stepper motor, 8 steps = one text line
;
;******************************************************************************

PRT_LineFeed:

	IF USE_SERVANT
	 CALL   COM_StopStatusTransmit
;        MOV    B,#0
;        MOV    A,#'c'
;        CALL   COM_TxChar
	ENDIF

	MOV     A,prt_outputdevice
	JNZ     PRT_LFexternal
PRT_LFloop:
	JB      prt_paperout,PRT_LFfail
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay
	DJNZ    R7,PRT_LFloop
PRT_LFfail:
	CALL    PRT_StopMotor

	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
;        MOV    B,#0
;        MOV    A,#'C'
;        CALL   COM_TxChar
	ENDIF

	RET
PRT_LFexternal:
	JMP     ERP_CR

;******************************************************************************
;
; Function:     PRT_LineFeedDelay
; Input:        None
; Output:       None
; Preserved:    R2-7,A,DPTR
; Destroyed:    R0,R1
; Description:
;   Delay between pulses going to stepper.
;   ??? for the mo., set it to about 1.5ms
;   Altered vastly version 2.74
;
;
;******************************************************************************

; 2.74 code

PRT_LineFeedDelay:
	MOV     R0, #PULSE_LENGTH
	CALL    delay100us

	JNB     SYS_overheating, PRT_FLDend
	CALL    PRT_StopMotor
	MOV     R0, #PULSE_DELAY
	CALL    delay100us

PRT_FLDend:
	RET

; pre 2.74 code

;PRT_LineFeedDelay:             ;-------------+---------+
;       MOV     R0,#3           ;     |   1us |         |
;                               ;-----+-------+         |
;PRT_LFDloop1:                  ;     | 256*2 |         |
;       MOV     R1,#0           ; 1us | +1    | 3*      |
;PRT_LFDloop2:                  ;-----| =     | (513+2) |
;       DJNZ    R1,PRT_LFDloop2 ; 2us | 513us | +1      |
;                               ;-----+-------+ =       |
;       DJNZ    R0,PRT_LFDloop1 ;     |   2us | 1546us  |
;                               ;-------------+---------+
;       RET

;******************************************************************************
;
; Function:     PRT_FormFeed
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Formfeeds a fixed amount if running in non-perfed mode, or to the next
;   black line in perf mode.
; Algorithm:
;   if (!prt_perfmode) PRT_LineFeed (50+trailerfeed);
;   else
;   {
;     if (prt_perfmark > prt_perfskipmax)
;     {
;       EjectPerf ();
;       PRT_GeneratePulse (); PRT_LineFeedDelay (); PRT_CheckPaper ();
;     }
;     EjectPerf ();
;   }
;
;   EjectPerf ()
;   {
;     while ((prt_perfmark < prt_perffail) && (prt_perfmark >= prt_perfoff))
;     {
;       PRT_GeneratePulse (); PRT_CheckPaper (); PRT_LineFeedDelay ();
;     }
;     while (prt_perfmark <= prt_perfoff)
;     {
;       if (prt_paperout) return;
;       PRT_GeneratePulse (); PRT_CheckPaper (); PRT_LineFeedDelay ();
;     }
;   }
;
;******************************************************************************

PRT_FormFeed:

	IF USE_SERVANT
	 CALL   COM_StopStatusTransmit
;        MOV    B,#0
;        MOV    A,#'d'
;        CALL   COM_TxChar
	ENDIF

	MOV     A,prt_outputdevice
	JNZ     PRT_FFeedexternal
	JB      prt_perfmode,PRT_FFperffeed

;*** unperfed feed
	MOV     DPTR,#ppg_oper_trailerfeed
	MOVX    A,@DPTR
	ADD     A,#50
	MOV     R7,A
	CALL    PRT_LineFeed
; MOV A,#'f'
; CALL DBG_TxChar

	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
;        MOV    B,#0
;        MOV    A,#'D'
;        CALL   COM_TxChar
	ENDIF

	RET

PRT_FFeedexternal:
	JMP     ERP_FormFeed

;*** perfed feed
PRT_FFperffeed:
; MOV A,#'F'
; CALL DBG_TxChar
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perfskipmaxhigh,PRT_FFperf4ne
	MOV     A,prt_perfmarklow
	CJNE    A,prt_perfskipmaxlow,PRT_FFperf4ne
PRT_FFperf4le:
	JMP     PRT_FFperf
PRT_FFperf4ne:
	JC      PRT_FFperf4le
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perfoffhigh,PRT_FFperf5ne
	MOV     A,prt_perfmarklow
	CJNE    A,prt_perfofflow,PRT_FFperf5ne
	JMP     PRT_FFperf
PRT_FFperf5ne:
	JNC     PRT_FFperf
	CALL    PRT_FFperf
	CALL    PRT_GeneratePulse
	CALL    PRT_LineFeedDelay
	CALL    PRT_CheckPaper
PRT_FFperf:
; if perfmark >= perffail goto nextportion
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perffailhigh,PRT_FFperf1ne
	MOV     A,prt_perfmarklow
	CJNE    A,prt_perffaillow,PRT_FFperf1ne
PRT_FFperf1ge:
	JMP     PRT_FFnextportion
PRT_FFperf1ne:
	JNC     PRT_FFperf1ge

;if perfmark < perfoffset goto nextportion
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perfoffhigh,PRT_FFperf2ne
	MOV     A,prt_perfmarklow
	CJNE    A,prt_perfofflow,PRT_FFperf2ne
	JMP     PRT_FFperf2
PRT_FFperf2ne:
	JC      PRT_FFnextportion
PRT_FFperf2:
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay
	JMP     PRT_FFperf

PRT_FFnextportion:
	JB      prt_paperout,PRT_FFend
; if perfmark > perfoffset goto end
	MOV     A,prt_perfmarkhigh
	CJNE    A,prt_perfoffhigh,PRT_FFperf3ne
	MOV     A,prt_perfmarklow
	CJNE    A,prt_perfofflow,PRT_FFperf3ne
PRT_FFperf3le:
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay
	JMP     PRT_FFnextportion
PRT_FFperf3ne:
	JC      PRT_FFperf3le
PRT_FFend:
	CALL    PRT_StopMotor

	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
;        MOV    B,#0
;        MOV    A,#'!'
;        CALL   COM_TxChar
	ENDIF

	RET

;******************************************************************************
;
; Function:     PRT_SkipPerf
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;
;the feed should be as follows:
;
;if (headerfeed)
;{
;  feed until perfmark >= perfoff or paperout (PRT_FFperf)
;  feed headerfeed
;}
;else
;{
;  feed (16 or 24)
;}
;

;******************************************************************************

PRT_SPend2:
	RET
PRT_SkipPerf:
	JNB     prt_perfmode,PRT_SPend2
	PUSHPSW
	PUSHACC
	PUSHB
	PUSHDPH
	PUSHDPL
	ANL     PSW,#0E7h
	ORL     PSW,#010h               ; select reg bank 2

	MOV     B,#215-5                        ;
	MOV     A,prt_zerodetect        ;
	JZ      PRT_SPlinecheck         ;
	MOV     A,#16+5                 ;
	ADD     A,B                     ;
	MOV     B,A                     ; B=minimum line to compare with

PRT_SPlinecheck:
	MOV     A,prt_perfmarkhigh      ;
	JNZ     PRT_SPmustchk           ;
	MOV     A,prt_perfmarklow       ;
	CJNE    A,B,PRT_SPminchkne      ;
	JMP     PRT_SPexit              ;
PRT_SPminchkne:                         ;
	JC      PRT_SPexit              ;
PRT_SPmustchk:
	MOV     DPTR,#ppg_oper_headerfeed
	MOVX    A,@DPTR
	JZ      PRT_SPjumpline
	MOV     B,A                     ; set R6:R7 to perfoffset+2*headerfeed
	MOV     A,prt_perfofflow        ; (i.e, skip company logo)
	ADD     A,B                     ;
	MOV     R7,A                    ;
	MOV     A,prt_perfoffhigh       ;
	ADDC    A,#0                    ;
	MOV     R6,A                    ;
	MOV     A,R7                    ;
	ADD     A,B                     ;
	MOV     R7,A                    ;
	MOV     A,R6                    ;
	ADDC    A,#0                    ;
	MOV     R6,A                    ;

	JMP     PRT_SPfeed              ;

PRT_SPjumpline:                         ; only skip the black line (no logo)
	MOV     R6,#1                   ;
	MOV     R7,#5                   ;

PRT_SPfeed:
	JB      prt_paperout,PRT_SPexit ; feed until perfmark >= r6:r7
	MOV     A,prt_perfmarkhigh
	MOV     B,R6
	CJNE    A,B,PRT_SPfeedne1

	MOV     A,prt_perfmarklow
	MOV     B,R7
	CJNE    A,B,PRT_SPfeedne2
	JMP     PRT_SPexit
PRT_SPfeedne2:
	JNC     PRT_SPexit
	JMP     PRT_SPissuepulse
PRT_SPfeedne1:
	JNC     PRT_SPexit
PRT_SPissuepulse:
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay

	MOV     A,prt_perfmarkhigh      ; abort if paper not
	JNZ     PRT_SPfeed              ; long enough
	MOV     A,prt_perfmarklow       ;
	JNB     ACC.7,PRT_SPexit        ;
	JMP     PRT_SPfeed              ;
PRT_SPexit:
	POP     DPL
	POP     DPH
	POP     B
	POP     ACC
	POP     PSW
PRT_SPend:
	RET

;******************************************************************************
;
; Function:     PRT_LoadPaper
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;
;******************************************************************************

msg_paperout:   DB 9,'Paper Out'
msg_keytoload:  DB 22,'Press OK to load paper'

PRT_PaperOutMsg:
	CALL    LCD_Clear
	MOV     A,#8
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_paperout
	CALL    LCD_DisplayStringCODE
	MOV     A,#65
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_keytoload
	CALL    LCD_DisplayStringCODE

	IF USE_ALTONCOMMS
PRT_POMkeyloop:
	 CALL   TKC_Idle
	 CALL   KBD_ReadKey
	 JZ     PRT_POMkeyloop
	ELSE
	 CALL    KBD_OkOrCancel
	 JZ      PRT_POMdone
	ENDIF

	CALL    PRT_LoadPaper
PRT_POMdone:
	RET

msg_loadpaper:  DB 24,'   Auto Paper Loading   '
msg_loadpaper2: DB 24,'    Insert Paper Now    '
msg_holdpaper:  DB 24,' Push Paper Up The Slot '
msg_feeding:    DB 24,'      Feeding Paper     '

PRT_LoadPaper:
	PUSHACC
	PUSHB
;;;     ORL     PSW,#010h                       ; reg bank 2
PRT_LPreload:
	CALL    LCD_Clear                       ; load paper message
	MOV     DPTR,#msg_loadpaper
	CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_loadpaper2
	CALL    LCD_DisplayStringCODE

	CALL    PRT_StopMotor
	SETB    prt_paperout

	IF      LEDS
	CALL    LED_Led1Flash                   ; paperout
	ENDIF

PRT_LPload:
	ORL     P7,#00010000b
	MOV     A,P7
	JNB     prt_paper_sense,PRT_LPpap       ; wait for paper to appear

	call    TKC_Idle                        ; Tim 29ix99

	CALL    KBD_ReadKey                     ; abort if cancel pressed
	CJNE    A,#KBD_CANCEL,PRT_LPload        ;
	JMP     PRT_LPcancel
PRT_LPpap:

	IF      LEDS
	CALL    LED_Led1Off
	ENDIF

	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_holdpaper
	CALL    LCD_DisplayStringCODE
	MOV     R7,#75                          ; small delay
PRT_LPdelay:                                    ;
	CALL    KBD_ReadKey                     ;
	CJNE    A,#KBD_CANCEL,PRT_LPnc          ; terminate the delay...
	JMP     PRT_LPcancel                    ; ...if CANCEL pressed
PRT_LPnc:                                       ;
	CJNE    A,#KBD_OK,PRT_LPnotok           ; skip the delay...
	JMP     PRT_LPfeed                      ; ...if OK pressed
PRT_LPnotok:                                    ;
	MOV     R0,#0                           ;
PRT_LPdelay2:                                   ;
	MOV     R1,#80                          ;
PRT_LPdelay3:                                   ;
	DJNZ    R1,PRT_LPdelay3                 ;
	DJNZ    R0,PRT_LPdelay2                 ;


	IF      LEDS
	CPL     led_led1                        ; rapid flash
	ENDIF

	IF      VT10

	IF      LEDS
	MOV     A,Led1
	JB      led_led1,PRT_LP_LedOn
	CALL    PortClrD
	JMP     PRT_LP_LedEnd
PRT_LP_LedOn:
	CALL    PortSetD
PRT_LP_LedEnd:
	ENDIF

	ELSE
	CALL    SBS_WriteSB2                    ;
	ENDIF

	DJNZ    R7,PRT_LPdelay                  ;

PRT_LPfeed:
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#msg_feeding
	CALL    LCD_DisplayStringCODE

	MOV     R7,#96                          ; small feed to let paper
PRT_LPfeedloop:                                 ; catch
	CALL    PRT_GeneratePulse               ;
	CALL    PRT_LineFeedDelay               ;
	CALL    PRT_LineFeedDelay               ;
	CALL    PRT_LineFeedDelay               ;
	CALL    PRT_LineFeedDelay               ;
	DJNZ    R7,PRT_LPfeedloop               ;
	ORL     P7,#00010000b
	MOV     A,P7
	JNB     prt_paper_sense,PRT_LPcarryon
	JMP     PRT_LPreload
PRT_LPcarryon:
	CLR     prt_paperout

	IF      LEDS
	CALL    LED_Led1On
	ENDIF

	MOV     R7,prt_perffaillow              ; look for perfmark
	MOV     R6,prt_perffailhigh             ; timeout after perffail
	INC     R6                              ; pulses
	MOV     prt_perfmarklow,#0              ;
	MOV     prt_perfmarkhigh,#0             ;

PRT_LPptst:                                     ;
	CALL    PRT_GeneratePulse               ;
	CALL    PRT_LineFeedDelay               ;
	CALL    PRT_LineFeedDelay               ;
	MOV     A,P7
	JB      prt_paper_sense,PRT_LPpfmk      ;
	DJNZ    R7,PRT_LPptst                   ;
	DJNZ    R6,PRT_LPptst                   ;

	CLR     prt_perfmode
; MOV A,#'n'
; CALL DBG_TxChar
	CLR     C
	JMP     PRT_LPend
PRT_LPpfmk:
	CALL    PRT_FormFeed
	CLR     C
	JMP     PRT_LPend
PRT_LPcancel:
	SETB    C
PRT_LPend:
;;;     ANL     PSW,#0E7h                       ; restore to reg bank 0
	POP     B
	POP     ACC
;       JMP     DT_ColdBoot
	RET

;******************************************************************************
;
;                      P r i n t i n g   F u n c t i o n s
;
;******************************************************************************

;******************************************************************************
;
; Function:     PRT_SetBitmapLenSmall
; Input:        A=bitmaplen
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_SetBitmapLenSmall:
	PUSHDPH
	PUSHDPL
	MOV     DPTR,#prt_bitmaplen
	MOVX    @DPTR,A
	INC     DPTR
	CLR     A
	MOVX    @DPTR,A
	POP     DPL
	POP     DPH
	RET

;******************************************************************************
;
; Function:     PRT_SetBitmapLen
; Input:        B:A = bitmaplen (B=high,A=low)
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_SetBitmapLen:
	PUSHDPH
	PUSHDPL
	MOV     DPTR,#prt_bitmaplen
	MOVX    @DPTR,A
	INC     DPTR
	MOV     A,B
	MOVX    @DPTR,A
	POP     DPL
	POP     DPH
	RET

;******************************************************************************
;
; Function:     PRT_GetBitmapLen
; Input:        None
; Output:       R6:R7 = bitmaplen
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_GetBitmapLen:
	MOV     DPTR,#prt_bitmaplen
	MOVX    A,@DPTR
	MOV     R7,A
	INC     DPTR
	MOVX    A,@DPTR
	ANL     A,#7            ; only allow tktlen up to 1023
	MOV     R6,A
;       MOV     A,R7
;       JZ      PRT_GBLok
;       INC     R6
;PRT_GBLok:
	RET

;******************************************************************************
;
; Function:     PRT_ClearBitmap
; Input:        None
; Output:       None
; Preserved:    R0-5, B
; Destroyed:    A, DPTR, R6-7
; Description:
;   Clears the portion of the bitmap down to prt_bitmaplen
;
;******************************************************************************

PRT_ClearBitmap:
	CALL    PRT_GetBitmapLen
	MOV     A,R7
	JZ      PRT_CBok
	INC     R6
PRT_CBok:
	MOV     DPTR,#prt_bitmap
	CLR     A
PRT_CBloopa:
	MOV     R5,#PRT_MAX_HORIZ_CHARS
PRT_CBloopb:
	MOVX    @DPTR,A
	INC     DPTR
	DJNZ    R5,PRT_CBloopb
	DJNZ    R7,PRT_CBloopa
	DJNZ    R6,PRT_CBloopa
	RET

;******************************************************************************
;
; Function:     PRT_SetPrintDevice
; Input:        A=external printer select mask
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Tells the print engine where the next print will go. Set to zero for the
;   internal printer, or set to the control mask
;
;******************************************************************************

PRT_SetPrintDevice:
	MOV     B,A
	MOV     DPTR,#man_extprtctrl
	MOVX    A,@DPTR
	ANL     A,B
	JZ      PRT_SPDinternal
	MOV     DPTR,#man_extprtenable
	MOVX    A,@DPTR
	JNB     ACC.0,PRT_SPDinternal
	JMP     PRT_SPDsave
PRT_SPDinternal:
	CLR     A
PRT_SPDsave:
	MOV     prt_outputdevice,A
	RET

;******************************************************************************
;
; Function:     PRT_FormatXRAMField
; Input:        DPTR = address in XRAM of field in template to format
; Output:       DPTR = address in XRAM of next field in template
;               A = 0 if end of template, <> 0 if more entries
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Generates the image of the specified field into the bitmap according
;   to the various flags and parameters defined in the field.
;
;******************************************************************************

PRT_FormatXRAMField:
	MOVX    A,@DPTR                 ; check if end of template
	JZ      PRT_FXFendtemplate
	CJNE    A,#9,PRT_FXFenabled     
	INC     DPTR
	MOVX    A,@DPTR
	ADD     A,#6
	MOV     R7,A                    ; R7 = char count of entire field
	MOV     R0,#prt_field_width     ; copy entire field to IRAM
	CALL    MEM_CopyXRAMtoIRAM
	MOV     A,#1
	RET                             ; ignore field, DPTR at next field
PRT_FXFenabled:
	INC     DPTR
	MOVX    A,@DPTR
	ADD     A,#6
	MOV     R7,A                    ; R7 = char count of entire field
	MOV     R0,#prt_field_width     ; copy entire field to IRAM
	CALL    MEM_CopyXRAMtoIRAM
	MOV     srcDPH,DPH              ; DPTR now pointing at start of next
	MOV     srcDPL,DPL              ; field, so save it somewhere handy

	CALL    PRT_FormatField         ; Do the formatting

	MOV     DPH,srcDPH              ; retrieve the saved DPTR so that it
	MOV     DPL,srcDPL              ; points at the next field in template
	MOV     A,#1
PRT_FXFendtemplate:
	RET

;******************************************************************************
;
; Function:     PRT_FormatCODEField
; Input:        DPTR = address in CODE (EPROM) of field in template to format
; Output:       DPTR = address in CODE of next field in template
;               A = 0 if end of template, <> 0 if more entries
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Generates the image of the specified field into the bitmap according
;   to the various flags and parameters defined in the field.
;
;******************************************************************************

PRT_FormatCODEField:
	CLR     A
	MOVC    A,@A+DPTR               ; check if end of template
	JZ      PRT_FCFendtemplate
	CJNE    A,#9,PRT_FCFenabled
	INC     DPTR
	CLR     A
	MOVC    A,@A+DPTR
	ADD     A,#6
PRT_FCFlose:
	INC DPTR
	DJNZ    ACC,PRT_FCFlose
	MOV     A,#1
	RET                             ; ignore field, DPTR at next field
PRT_FCFenabled:
	INC     DPTR
	CLR     A
	MOVC    A,@A+DPTR
	ADD     A,#6
	MOV     R1,A                    ; R1 = char count of entire field
	MOV     R0,#prt_field_width     ; copy entire field to IRAM
PRT_FCFcopyloop:                        ;
	CLR     A
	MOVC    A,@A+DPTR               ;
	INC     DPTR                    ;
	MOV     @R0,A                   ;
	INC     R0                      ;
	DJNZ    R1,PRT_FCFcopyloop      ;
	MOV     srcDPH,DPH              ; DPTR now pointing at start of next
	MOV     srcDPL,DPL              ; field, so save it somewhere handy

	CALL    PRT_FormatField         ; Do the formatting

	MOV     DPH,srcDPH              ; retrieve the saved DPTR so that it
	MOV     DPL,srcDPL              ; points at the next field in template
	MOV     A,#1
PRT_FCFendtemplate:
	RET

;******************************************************************************
;
; Function:     PRT_FormatField
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Generates the image of the field stored in IRAM into the bitmap according
;   to the various flags and parameters defined in that field.
;
;******************************************************************************
PRT_FFdone:
PRT_FFdisabled:
	RET
PRT_FormatField:
	MOV     A,prt_field_width       ; check if field disabled
	JB      ACC.7,PRT_FFdisabled    ; exit if so

	MOV     A,prt_outputdevice
	JZ      PRT_FFinternal
	JMP     PRT_FFexternal

PRT_FFinternal:
	MOV     R0,#prt_field_x         ; Set DPTR to the address in the
	MOV     A,@R0   ; x             ; bitmap corresponding to the
	INC     R0                      ; (x,y) location specified in the
	MOV     R2,A                    ; field pointed to by R0
	MOV     A,@R0   ; y             ;
	INC     R0                      ;
	RR      A                       ;
	RR      A                       ;
	RR      A                       ;
	MOV     R3,A                    ;
	ANL     A,#0E0h                 ;
	ORL     A,R2                    ;
	MOV     DPTR,#prt_bitmap        ; set DPH to base of bitmap
	MOV     DPL,A                   ;
	MOV     A,prt_field_flags
	RR      A
	ANL     A,#060h
	XCH     A,R3
	ANL     A,#01Fh
	ORL     A,R3
	ADD     A,DPH                   ; allow bitmap at any page aligned addr
	MOV     DPH,A                   ;

	MOV     R7,prt_field_len        ; Mainloop, R7 = char count
	MOV     A,R7
	JZ      PRT_FFdone
	INC     R0                      ; R0 = 1st char of string

	IF      TRACE_RASTER
	IF      QTRACE_ON
	mov     a,prt_field_mag
	cjne    a,#11h,PRT_FFnoTrace
	push    dph
	push    dpl
	clr     a
	mov     dptr,#qtrack
	movx    @dptr,a
	pop     dpl
	pop     dph
PRT_FFnoTrace:
	ENDIF
	ENDIF

	IF      BIGFONT

	mov     a,prt_field_mag         ; If the horizontal magnification
	anl     a,#240                  ; is 2 or 3 or 4
	cjne    a,#48,PRT_FFNot4PixWide ; and the vertical magnification
	jmp     PRT_RasterPixelWidth    ; is < 5, the field will be 
PRT_FFNot4PixWide:                      ; generated from the meant-to-be
	cjne    a,#32,PRT_FFNot3PixWide ; -scalable 4*4 raster font.
	jmp     PRT_RasterPixelWidth    ; Otherwise the dot font is
PRT_FFNot3PixWide:                      ; expanded algorithmically
	cjne    a,#16,PRT_FFNotRasterFont
PRT_RasterPixelWidth:
	mov     a,prt_field_mag
	anl     a,#15                   ; Is the vertical magnification
	add     a,#-5                   ; > *4? If so, leave it to
	jc      PRT_FFNotRasterFont     ; algorithmic expansion of dot font

	call    RAS_Xpand
	ret
PRT_FFNotRasterFont:

	ENDIF

PRT_FFloop:
	MOV     A,@R0                   ; A = char to print
	INC     R0

	CJNE    A,#127,PRT_FFcarryon1   ; correct pound signs
PRT_FFclra:
	CLR     A                       ;
	SETB    C
PRT_FFcarryon1:
	JNC     PRT_FFclra
	CLR     C

	MOV     spare2DPH,DPH           ; save bitmap location, we need DPTR
	MOV     spare2DPL,DPL           ; for copying the font image to IRAM

	MOV     R1,A                    ; set DPTR to address of fontdata
	MOV     DPTR,#font              ; for this character
	SWAP    A                       ;
	RR      A                       ;
	ANL     A,#07h                  ;
	ADD     A,DPH                   ;
	MOV     DPH,A                   ;
	MOV     A,R1                    ;
	SWAP    A                       ;
	RR      A                       ;
	ANL     A,#0F8h                 ;
	MOV     DPL,A                   ;

	MOV     R6,#8                   ; copy font description for this
	MOV     R1,#prt_fontchrdata     ; character into IRAM
	CLR     A                       ;
	MOV     R5,A                    ;
PRT_FFreadfont:                         ;
	MOV     A,R5                    ;
	MOVC    A,@A+DPTR               ;
	MOV     @R1,A                   ;
	INC     R1                      ;
	INC     R5                      ;
	DJNZ    R6,PRT_FFreadfont       ;

	MOV     A,prt_field_flags       ; if the inverse flag is set,
	ANL     A,#02h                  ; then complement every byte
	JZ      PRT_FFnoinv             ; in the font description for
	MOV     R6,#8                   ; this character
	MOV     R1,#prt_fontchrdata     ;
PRT_FFinv:                              ;
	MOV     A,@R1                   ;
	XRL     A,#0FFh                 ;
	MOV     @R1,A                   ;
	INC     R1                      ;
	DJNZ    R6,PRT_FFinv            ;

PRT_FFnoinv:
	MOV     A,prt_field_mag         ; jump to different stub if
	SWAP    A                       ; there is any x magnification
	ANL     A,#15                   ;
	JNZ     PRT_FFxmag              ;

; JMP PRT_FFxmag

PRT_FFnorm:
	IF DT10W                        ; copy the font description for this
	 MOV    R6,#6                   ; char from IRAM out to the bitmap
	ELSE                            ;
	 MOV    R6,#8                   ;
	ENDIF                           ;
	MOV     R1,#prt_fontchrdata     ;
	MOV     DPH,spare2DPH           ;
	MOV     DPL,spare2DPL           ;
PRT_FFwritefont:                        ;
	MOV     A,prt_field_mag         ;
	ANL     A,#15                   ;
	INC     A                       ;
	MOV     R5,A                    ;
PRT_FFvertmag:                          ;
	MOV     A,@R1                   ;
	MOVX    @DPTR,A                 ;
	MOV     A,DPL                   ;
	ADD     A,#PRT_MAX_HORIZ_CHARS  ;
	MOV     DPL,A                   ;
	MOV     A,DPH                   ;
	ADDC    A,#0                    ;
	MOV     DPH,A                   ;
	DJNZ    R5,PRT_FFvertmag        ;
	INC     R1                      ;
	DJNZ    R6,PRT_FFwritefont      ;

PRT_FFnextchar:
	MOV     A,prt_field_flags       ; skip the next block if we are
	ANL     A,#01                   ; doing vertical text
	JNZ     PRT_FFvertical          ;

	MOV     A,prt_field_mag         ; move into next column in bitmap
	SWAP    A                       ;
	ANL     A,#15                   ;
	INC     A                       ;
	MOV     DPH,spare2DPH           ;
	MOV     DPL,spare2DPL           ;
	CALL    AddAtoDPTR              ;
	MOV     spare2DPH,DPH           ;
	MOV     spare2DPL,DPL           ;
PRT_FFvertical:

	DJNZ    R7,PRT_FFloopext        ; repeat for all characters
	RET
PRT_FFloopext:
	JMP     PRT_FFloop

PRT_FFxmag:
	IF DT10W                        ; copy the font description for this
	 MOV    R6,#6                   ; char from IRAM out to the bitmap
	ELSE                            ;
	 MOV    R6,#8                   ;
	ENDIF                           ;
	MOV     R1,#prt_fontchrdata     ;
	MOV     DPH,spare2DPH           ;
	MOV     DPL,spare2DPL           ;
PRT_FFvloop:
	MOV     A,prt_field_mag
	ANL     A,#15
	INC     A
	MOV     R5,A
PRT_FFyloop:
	PUSHDPH
	PUSHDPL
	MOV     B,#080h
	MOV     A,@R1
	MOV     R2,A
	IF DT10W
	 MOV    R4,#8
	ELSE
	 MOV    R4,#6
	ENDIF
PRT_FFhloop:
	MOV     A,R2
	RL      A
	MOV     R2,A
	MOV     C,ACC.0
	MOV     F0,C
	MOV     A,prt_field_mag
	SWAP    A
	ANL     A,#15
	INC     A
	MOV     R3,A
PRT_FFxloop:
	JNB     F0,PRT_FFnopixel
	MOVX    A,@DPTR
	ORL     A,B
	MOVX    @DPTR,A
PRT_FFnopixel:
	MOV     A,B
	RR      A
	IF DT10W
	 CJNE   A,#080h,PRT_FFnodwrap
	ELSE
	 CJNE   A,#2,PRT_FFnodwrap
	ENDIF
	MOV     A,#080h
	INC     DPTR
PRT_FFnodwrap:
	MOV     B,A
	DJNZ    R3,PRT_FFxloop
	DJNZ    R4,PRT_FFhloop
	POP     DPL
	POP     DPH

	MOV     A,#32
	CALL    AddAtoDPTR
	DJNZ    R5,PRT_FFyloopGO
	INC     R1
	DJNZ    R6,PRT_FFvloopGO
	JMP     PRT_FFnextchar
PRT_FFvloopGO:
	jmp     PRT_FFvloop
PRT_FFyloopGO:
	jmp     PRT_FFyloop
PRT_FFexternal:
	RR      A
	ANL     A,#3
	MOV     B,A
	MOV     A,prt_field_len
	JZ      PRT_FFextdone
	MOV     R7,A
	MOV     R0,#prt_field_str
	PUSHB
	CALL    ERP_TxStrIRAM
	POP     B
	CALL    ERP_CR
PRT_FFextdone:
	RET

;******************************************************************************
;
; Function:     PRT_FormatBitmap
; Input:        DPTR = pointer to template
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;******************************************************************************

PRT_FormatBitmap:
PRT_FBloop:
	CALL    PRT_FormatXRAMField
	JNZ     PRT_FBloop
	RET

;******************************************************************************
;
; Function:     PRT_FormatBitmapCODE
; Input:        DPTR = pointer to template
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;******************************************************************************

PRT_FormatBitmapCode:
PRT_FBCloop:
	CALL    PRT_FormatCODEField
	JNZ     PRT_FBCloop
	RET

;******************************************************************************
;
; Function:     PRT_PaperFeed
; Input:        None
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   The main paper feed routine. Lets the user feed paper as long as the FEED
;   key is held down. After the key is released, if it is pressed again within
;   a small time limit, the feed will be continued.
;******************************************************************************

PRT_PaperFeed:

	IF USE_SERVANT
	 CALL   COM_StopStatusTransmit
;        MOV    B,#0
;        MOV    A,#'h'
;        CALL   COM_TxChar
	ENDIF

	CALL    PRT_StartPrint
	JB      prt_paperout,PRT_PFloadpaper
PRT_PFfeedloop:
	CALL    PRT_GeneratePulse
	CALL    PRT_CheckPaper
	CALL    PRT_LineFeedDelay
	CALL    KBD_ScanKeyboard
	CJNE    A,#20,PRT_PFnomorefeed
	JMP     PRT_PFfeedloop
PRT_PFnomorefeed:
	CALL    KBD_FlushKeyboard
	CALL    PRT_StopMotor

	IF      LEDS
	CALL    LED_Led1On
	ENDIF

	JNB     prt_paperout,PRT_PFpapok

	IF      LEDS
	CALL    LED_Led1Flash
	ENDIF

PRT_PFpapok:
	MOV     R7,#0
PRT_PFmorefeed:
	CALL    KBD_ScanKeyboard
	CJNE    A,#4,PRT_PFmorefeedtimeout
	JMP     PRT_PFfeedloop
PRT_PFmorefeedtimeout:
	MOV     R0,#30
	CALL    delay100us
	DJNZ    R7,PRT_PFmorefeed
	CALL    PRT_EndPrint
	MOV     A,#100
	MOV     B,#200

	IF      SPEAKER
	CALL    SND_Beep
	ENDIF

	CALL    KBD_FlushKeyboard

	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
;        MOV    B,#0
;        MOV    A,#'?'
;        CALL   COM_TxChar
	ENDIF

	RET
PRT_PFloadpaper:
	CALL    PRT_LoadPaper
	CALL    PRT_EndPrint

	IF USE_SERVANT
	 CALL   COM_StartStatusTransmit
;        MOV    B,#0
;        MOV    A,#'H'
;        CALL   COM_TxChar
	ENDIF

	RET

;******************************************************************************
;
; Function:     PRT_GetPrintOffset
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_GetPrintOffset:
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_printoffset
	CALL    I2C_Read8
	MOV     A,B
	ANL     A,#0F0h
	JZ      PRT_GPOinrange
	MOV     A,#8
	JMP     PRT_GPOok
PRT_GPOinrange:
	MOV     A,B
	ANL     A,#00Fh
	CJNE    A,#4,PRT_GPOnot4
PRT_GPOle4:
	MOV     A,#5
	JMP     PRT_GPOok
PRT_GPOnot4:
	JC      PRT_GPOle4
PRT_GPOok:
	MOV     DPTR,#prt_density
	MOVX    @DPTR,A
	RET

;******************************************************************************
;
; Function:     PRT_GetPrintQuality
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_GetPrintQuality:
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_printquality
	CALL    I2C_Read8
	MOV     A,B
	ANL     A,#0C0h
	JZ      PRT_GPQinrange
	CLR     A
	JMP     PRT_GPQok
PRT_GPQinrange:
	MOV     A,B
	ANL     A,#63
PRT_GPQok:
	ADD     A,#10
	MOV     prt_stepdelay3,A
	RET

;******************************************************************************
;
; Function:     PRT_DisplayPrintIntensity
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

msg_printintensity: DB 255,20,0,0,0,0,20,'Print Intensity: xxx'
	IF DT5
msg_enterintensity: DB 255,20,0,0,0,0,20,'Enter New Intensity:'
	ELSE
msg_newintensity: DB 14,'New Intensity:'
	ENDIF

PRT_DisplayPrintIntensity:
	MOV     DPTR,#msg_printintensity
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#27
	CALL    MEM_CopyCODEtoXRAMsmall
	MOV     DPSEL,#0
	MOV     DPTR,#prt_density
	MOV     DPSEL,#1
	MOV     DPTR,#buffer+24
	MOV     R5,#3
	CALL    NUM_NewFormatDecimal8

	IF DT5
	 CALL   PRT_StartPrint
	 CALL   DisplayOneLiner
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#buffer+7
	 MOV    R7,#20
	 CALL   LCD_DisplayStringXRAM
	ENDIF

	RET

;******************************************************************************
;
; Function:     PRT_SetPrintIntensity
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_SetPrintIntensity:
	MOV     A,#SYS_AREA_SETDENSITY
	CALL    SYS_SetAreaCode
	CALL    PRT_DisplayPrintIntensity
	IF DT5
	 MOV    DPTR,#msg_enterintensity
	 CALL   PRT_DisplayMessageCODE
	 CALL   PRT_MessageFeed
	 CALL   PRT_EndPrint
	ELSE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#msg_newintensity
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#17
	 CALL   LCD_GotoXY
	ENDIF

	MOV     DPSEL,#0
	MOV     DPTR,#buffer
	MOV     B,#79
	MOV     R7,#3
	CALL    NUM_GetNumber
	JZ      PRT_SPIabort
	MOV     A,mth_op1ll
	ANL     A,#15           ; for safety
	MOV     DPTR,#prt_density
	MOVX    @DPTR,A
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_printoffset
	MOV     B,A
	CALL    I2C_Write8
PRT_SPIabort:
	IF DT5
	 CALL   PRT_DisplayPrintIntensity
	 CALL    PRT_FormFeed
	 CALL    PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	ENDIF
	SETB    tim_timerupdate
	CLR     A
	RET

;******************************************************************************
;
; Function:     PRT_DisplayPrintQuality
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

msg_printquality: DB 255,18,0,0,0,0,18,'Print Quality: xxx'
	IF DT5
msg_enterquality: DB 255,18,0,0,0,0,18,'Enter New Quality:'
	ELSE
msg_newquality: DB 12,'New Quality:'
	ENDIF

PRT_DisplayPrintQuality:
	MOV     DPTR,#msg_printquality
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#27
	CALL    MEM_CopyCODEtoXRAMsmall
	MOV     DPSEL,#1
	MOV     DPTR,#buffer+22
	MOV     R5,#3
	MOV     A,prt_stepdelay3
	CLR     C
	SUBB    A,#10
	MOV     B,A
	CALL    NUM_NewFormatDecimalB

	IF DT5
	 CALL   PRT_StartPrint
	 CALL   DisplayOneLiner
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#buffer+7
	 MOV    R7,#18
	 CALL   LCD_DisplayStringXRAM
	ENDIF
	RET

;******************************************************************************
;
; Function:     PRT_SetPrintQuality
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_SetPrintQuality:
	MOV     A,#SYS_AREA_SETQUALITY
	CALL    SYS_SetAreaCode
	CALL    PRT_DisplayPrintQuality
	IF DT5
	 MOV    DPTR,#msg_enterquality
	 CALL   PRT_DisplayMessageCODE
	 CALL   PRT_MessageFeed
	 CALL   PRT_EndPrint
	ELSE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#msg_newquality
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#17
	 CALL   LCD_GotoXY
	ENDIF

	MOV     DPSEL,#0
	MOV     DPTR,#buffer
	MOV     B,#79
	MOV     R7,#3
	CALL    NUM_GetNumber
	JZ      PRT_SPQabort
	MOV     A,mth_op1ll
	ANL     A,#63           ; for safety
	MOV     B,A
	ADD     A,#10
	MOV     prt_stepdelay3,A
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_printquality
	CALL    I2C_Write8
PRT_SPQabort:
	IF DT5
	 CALL   PRT_DisplayPrintQuality
	 CALL    PRT_FormFeed
	 CALL    PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	ENDIF
	SETB    tim_timerupdate
	CLR     A
	RET

;******************************************************************************
;
; Function:     PRT_GetPerfOffset
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_GetPerfOffset:
	MOV     prt_perfoffhigh,#01h
	MOV     prt_perfofflow,#03ah
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_perfoffset
	CALL    I2C_Read8
	MOV     A,B
	MOV     prt_perfofflow,A

	CJNE    A,#80,PRT_GPOnot80              ; if perfofflow not between
PRT_GPOperfok:                                  ; 10 and 80, then set it
	RET                                     ; to the default of 58
PRT_GPOnot80:                                   ;
	JNC     PRT_GPOfail                     ;
	CJNE    A,#10,PRT_GPOnot10              ;
	JMP     PRT_GPOperfok                   ;
PRT_GPOnot10:                                   ;
	JC      PRT_GPOfail                     ;
	JMP     PRT_GPOperfok                   ;
PRT_GPOfail:                                    ;
	MOV     prt_perfofflow,#03Ah            ;
	CALL    PRT_WritePerfOffset             ;
	RET

PRT_GetPerfLineSize:
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_perflinemin
	CALL    I2C_Read8
	MOV     A,B
	MOV     prt_perflinemin,A
	ADD     A,#10
	MOV     prt_perflinemax,A
	CJNE    A,#35,PRT_GPLSnot50             ; if less than 25, set
PRT_GPLSok:                                     ; to 50 (standard DT10)
	RET
PRT_GPLSnot50:
	JNC     PRT_GPLSok
	MOV     prt_perflinemin,#50
	MOV     prt_perflinemax,#60
	CALL    PRT_WritePerfLineSize           ;
	RET

;******************************************************************************
;
; Function:     PRT_TweakPerfOffset
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Tweaks the perforation offset to a value usable by the print engine.
;   On a vending machine this involves doubling the value in the low byte
;     and carrying it into the high so that our range of permitted values
;     gives us the necessary spread to conver the gap between the printer
;     and the paper cutter.
;   On a wristbander, this involves subtracting 62 from the low byte to put
;     the 16 bit perfoffset into a usable range.
;
;   Note: all of this is purely to save converting the storage of the perf
;     offset to 16bit. The high byte always starts at 01h before the tweak.
;
;******************************************************************************

PRT_TweakPerfOffset: ; left-shift required for vending demo only
	IF DT10W
	ELSE
	 IF VT1 OR USE_ALTONCOMMS
	  MOV   A,prt_perfofflow
	  RLC   A
	  MOV   prt_perfofflow,A
	  JNC   PRT_TPOdone
	  INC   prt_perfoffhigh
PRT_TPOdone:
	 ENDIF
	ELSE
	 MOV    mth_op1ll,prt_perfofflow
	 MOV    mth_op1lh,prt_perfoffhigh
	 MOV    A,#62
	 CALL   MTH_LoadOp2Acc
	 CALL   MTH_SubWords
	 MOV    prt_perfofflow,mth_op1ll
	 MOV    prt_perfoffhigh,mth_op1lh
	ENDIF
	RET

;******************************************************************************
;
; Function:     PRT_DisplayPerfOffset
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

msg_perfoffset: DB 255,16,0,0,0,0,16,'Perf Offset: xxx'
	IF DT5
msg_enteroffset: DB 255,17,0,0,0,0,17,'Enter New Offset:'
	ELSE
msg_newoffset: DB 11,'New Offset:'
	ENDIF

msg_perflinesize: DB 255,19,0,0,0,0,19,'Perf Line Size: xxx'
	IF DT5
msg_enterlinesize: DB 255,20,0,0,0,0,20,'Enter New Line Size:'
	ELSE
msg_newlinesize: DB 14,'New Line Size:'
	ENDIF

PRT_DisplayPerfOffset:
	MOV     DPTR,#msg_perfoffset
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#23
	CALL    MEM_CopyCODEtoXRAMsmall
	MOV     DPSEL,#1
	MOV     DPTR,#buffer+20
	MOV     R5,#3
	MOV     B,prt_perfofflow
	CALL    NUM_NewFormatDecimalB

	IF DT5
	 CALL   PRT_StartPrint
	 CALL   DisplayOneLiner
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#buffer+7
	 MOV    R7,#16
	 CALL   LCD_DisplayStringXRAM
	ENDIF
	RET

PRT_DisplayPerfLineSize:
	MOV     DPTR,#msg_perflinesize
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#26
	CALL    MEM_CopyCODEtoXRAMsmall
	MOV     DPSEL,#1
	MOV     DPTR,#buffer+23
	MOV     R5,#3
	MOV     B,prt_perflinemin
	CALL    NUM_NewFormatDecimalB

	IF DT5
	 CALL   PRT_StartPrint
	 CALL   DisplayOneLiner
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#buffer+7
	 MOV    R7,#19
	 CALL   LCD_DisplayStringXRAM
	ENDIF
	RET

;******************************************************************************
;
; Function:     PRT_SetPerfOffset
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_WritePerfOffset:
	MOV     B,prt_perfofflow
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_perfoffset
	CALL    I2C_Write8
	RET

PRT_WritePerfLineSize:
	MOV     B,prt_perflinemin
	MOV     R1,#EE_SLAVE
	MOV     DPTR,#EE_perflinemin
	CALL    I2C_Write8
	RET

PRT_SetPerfOffset:
	CALL    PRT_GetPerfOffset
	CALL    PRT_DisplayPerfOffset
	IF DT5
	 MOV    DPTR,#msg_enteroffset
	 CALL   PRT_DisplayMessageCODE
	 CALL   PRT_MessageFeed
	 CALL   PRT_EndPrint
	ELSE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#msg_newoffset
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#17
	 CALL   LCD_GotoXY
	ENDIF

	MOV     DPSEL,#0
	MOV     DPTR,#buffer
	MOV     B,#79
	MOV     R7,#3
	CALL    NUM_GetNumber
	JZ      PRT_SPOabort
	MOV     prt_perfofflow,mth_op1ll
	CALL    PRT_WritePerfOffset

PRT_SPOabort:
	IF DT5
	 CALL   PRT_DisplayPerfOffset
	 CALL    PRT_FormFeed
	 CALL    PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	ENDIF
	SETB    tim_timerupdate
	CALL    PRT_GetPerfOffset
	CALL    PRT_TweakPerfOffset
	CLR     A
	RET

PRT_SetPerfLineSize:
	CALL    PRT_GetPerfLineSize
	CALL    PRT_DisplayPerfLineSize
	IF DT5
	 MOV    DPTR,#msg_enterlinesize
	 CALL   PRT_DisplayMessageCODE
	 CALL   PRT_MessageFeed
	 CALL   PRT_EndPrint
	ELSE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#msg_newlinesize
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#20
	 CALL   LCD_GotoXY
	ENDIF

	MOV     DPSEL,#0
	MOV     DPTR,#buffer
	MOV     B,#82
	MOV     R7,#3
	CALL    NUM_GetNumber
	JZ      PRT_SPLSabort
	MOV     prt_perflinemin,mth_op1ll
	CALL    PRT_WritePerfLineSize

PRT_SPLSabort:
	IF DT5
	 CALL   PRT_DisplayPerfLineSize
	 CALL    PRT_FormFeed
	 CALL    PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	ENDIF
	SETB    tim_timerupdate
	CALL    PRT_GetPerfLineSize
	CLR     A
	RET

;******************************************************************************
;
; Function:     PRT_IllegalDevice
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Routine called when an attempt is made to print something to a type
;   of printer it is not appropriate for. Simply displays an error message
;   on the operator's LCD.
;
;******************************************************************************

prt_msg_illegal1:       DB 24,'Command may only be used'
prt_msg_illegal2:       DB 24,'with an external printer'

PRT_IllegalDevice:
	CALL    LCD_Clear
	MOV     DPTR,#prt_msg_illegal1
	CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	CALL    LCD_DisplayStringCODE

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	MOV     R7,#40
;        CALL   DT_KeypressTimeout
	CALL    LCD_Clear
	RET

;******************************************************************************
;
; Function:     PRT_DisplayMessageCODE
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_DisplayMessageCODE:         ; DPTR = message
	PUSHDPH
	PUSHDPL
	INC     DPTR
	INC     DPTR
	INC     DPTR
	CLR     A
	MOVC    A,@A+DPTR
	ANL     A,#15
	INC     A
	SWAP    A
	RR      A
	CALL    PRT_SetBitmapLenSmall
	CALL    PRT_ClearBitmap
	POP     DPL
	POP     DPH
	CALL    PRT_FormatCODEField
	CALL    PRT_PrintBitmap
	RET

;******************************************************************************
;
; Function:     PRT_DisplayOneLiner
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_DisplayOneLiner:
DisplayOneLiner:
	MOV     A,#8
	CALL    PRT_SetBitmapLenSmall
	CALL    PRT_ClearBitmap
	MOV     DPTR,#buffer
	CALL    PRT_FormatXRAMField
	CALL    PRT_PrintBitmap
	RET

;******************************************************************************
;
; Function:     PRT_MessageFeed
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

PRT_MessageFeed:
	MOV     R7,#48
	CALL    PRT_LineFeed
	RET


;******************************************************************************
;
; Function:     PRT_LanguageStringSelect
; Input:        DPTR = start of string table
; Output:       DPTR = correct entry in string table
; Preserved:    ?
; Destroyed:    A, B
; Description:
;   Finds the correct printer string in a table of printer strings,
;       depending on the setting of man_language
;
;******************************************************************************

PRT_LanguageStringSelect:

	PUSHDPL
	PUSHDPH
	INC     DPTR
	CLR     A                       ; store size of table entries in B
	MOVC    A, @A+DPTR              ;
	ADD     A, #7
	MOV     B, A
	MOV     DPTR, #man_language
	MOVX    A, @DPTR
	MUL     AB
	POP     DPH
	POP     DPL
	CALL    AddABtoDPTR
	RET


;****************************** End Of PRINTER.ASM ****************************
;******************************************************************************
;       DPTR Holds Manager Field Pointer
PRT_PrintOperatorField:
	MOV     A,#255                          ;Turn Field On
	MOVX    @DPTR,A                         ;
	PUSHDPL
	PUSHDPH
	INC     DPTR                            ;Select Mag Byte
	INC     DPTR                            ;
	INC     DPTR                            ;
	MOVX    A,@DPTR
	ANL     A,#00Fh                         ;Mask Off Y
	INC     A
	RL      A                               ;X Times 8
	RL      A
	RL      A
	INC     DPTR
	INC     DPTR
	MOV     B,A
	MOVX    A,@DPTR
	ADD     A,B                             ;Plus X Offset
	CALL    PRT_SetBitmapLenSmall
	CALL    PRT_ClearBitmap
	POP     DPH
	POP     DPL
	CALL    PRT_FormatXRAMField
	CALL    PRT_PrintBitmap
	RET

;
	End
