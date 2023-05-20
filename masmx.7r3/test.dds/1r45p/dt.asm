	$include        "8051.def"
	$list           2
;******************************************************************************
;
; File     : DT.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the main program for DT5/DT10
;
; System   : 80C537
;
; History  :
;
; 23/07/98 ATP 2307a Removed sensor code.
;
;***************************************************************************

; Declare which customer (use DDS if generating the standard version)

;DT10 and DT10W use Barcodes, DT5 doesn't.

USE_DDS_DT10            EQU 0 ; define for standard non-networked DDS version
USE_DDS_DT10_NETWORK    EQU 0 ; define for standard networked DDS version

USE_DDS_DT5             EQU 0 ; define for standard non-networked DDS version
USE_DDS_DT5_NETWORK     EQU 0 ; define for standard networked DDS version (?)

USE_DDS_DT10W           EQU 0 ; define for standard non-networked DDS version
USE_DDS_DT10W_NETWORK   EQU 0 ; define for standard networked DDS version

USE_DDS_DT10W_NARROW    EQU 0 ; define for standard non-networked DDS version
USE_DDS_DT10W_NETWORK_NARROW EQU 0 ; define for standard networked DDS version

USE_ALTON               EQU 1 ; define for Alton Towers Slave Machine


USE_PAIGNTON            EQU 0 ; define for Paignton Zoo
USE_METROLAND           EQU 0 ; define for The New Metroland
USE_POWERSCOURT         EQU 0 ; define for Powerscourt House & Gardens (Screenguard)
USE_BEDFORD             EQU 0 ; define for Bedford Rugby Club
USE_SEAT_DEMO           EQU 0 ; define for a demo version of Bedford's code
USE_TMACHS              EQU 0 ; define for Ticketing and Manual Access
			      ; Control System

USE_SERVANT             EQU 0 ; define if required to respond to serial commands



VT10    EQU     1
	INCLUDE custopts.inc

DT_VERSION* MACRO
	DB '4r1p '             ; version no. (must be 5 chars)
	MACEND

SERIAL_FASTREL EQU 0            ; Single Byte Outputs over EXAR2550 UART
				; la Rutina esta EXAR_TxL
				; EQU 1 enables EXAR_FTX which overlaps
				; transmission and buffer readout

ITRACE  EQU     0               ; when set flags last two interrupts in DIAG 
XDIAGNOSE EQU    0              ; used to trace stack, similar to DIAG_etc
TRACE_RASTER EQU 0              ; traces pixel pattern generated for print
BIGFONT EQU     0               ; uses 4*4 scalable font for magnifications
PAPERDETECT EQU 0
PREPRINT EQU    1               ; when clear does not preprint
LEDS    EQU     0
SPEAKER EQU     0
LCD_BUG EQU     1
SLEEP_IN EQU    0
ATARI   EQU     1

EXAR_BARCODE_APPLICATION EQU 0        
EXAR_TXAP       EQU 1
BARCODE_ZERO    EQU 0
BINARY72        EQU 1
PACKED          EQU 2
ASCII21         EQU 3
ASCII17         EQU 4
BARCODE_FORMAT  EQU BARCODE_ZERO       

CLEAR   EQU 1
;***********************************************************************************
Debug   MACRO   'Data'
	MOV     A,!1
	CALL    COM_TX_A
	MACEND
;*******************************************************************************
; Define Memory Configuration
; Customer Specific
; Limits set low to give early indication of code/data shortage
;*******************************************************************************
	IF USE_DDS
	MEMTRAP Hi,0C000h        ; *** 64k EPROM *** goes from 0000h to FFFFh
	MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
	ENDIF

;       IF USE_DDS_NETWORK
;       MEMTRAP Hi,9000h        ; *** 64k EPROM *** goes from 0000h to FFFFh
;       MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
;       ENDIF

	IF USE_PAIGNTON
	MEMTRAP Hi,7f00h        ; EPROM goes from 0000h to 7FFFh
	MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
	ENDIF

	IF USE_METROLAND
	MEMTRAP Hi,9000h        ; *** 64k EPROM *** goes from 0000h to FFFFh
	MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
	ENDIF

	IF USE_POWERSCOURT
	MEMTRAP Hi,9000h        ; EPROM goes from 0000h to 7FFFh
	MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
	ENDIF

	IF USE_BEDFORD
	MEMTRAP Hi,9000h        ; *** 64k EPROM *** goes from 0000h to FFFFh
	MEMTRAP VAR,Hi,7800h    ; XRAM goes from 0000h to 7FFFh
	ENDIF

	PRESET VARTYPE,ALIGN
POINTER PRESET 2
LONG    PRESET 4

VTTEST  EQU     0

	include qtrace.asm
	include fastmath.asm

	IF      ITRACE
	INCLUDE tvectors.asm
	ELSE
	INCLUDE vectors.asm
	ENDIF

	ORG VAR,0100h           ; Base address of XRAM (external RAM)

buffer: VAR 2048                ; Misc buffer (declare as largest area needed)
				; ABSOLUTELY MUST BE FIRST THING IN VAR SPACE

aud_first:      VAR 4 ; these four are declared here so that when a machine
aud_last:       VAR 4 ; has its eprom revision changed, the audit memory is
aud_uploadfrom: VAR 4 ; guaranteed to be readable, even if nothing else is.
aud_uploadto:   VAR 4 ;

;**************
; Include Files
;**************


	INCLUDE sfr.inc
	ALIGN   ToPage
font:
	IF DT10W
	 INCLUDE vfont.asm
	ELSE
	 INCLUDE hfont.asm
	ENDIF
	INCLUDE ddslogo.asm
	INCLUDE iram_map.inc
	INCLUDE ee_map.inc
	INCLUDE stack.asm
	IF VT10
	INCLUDE ports.asm
	ENDIF
	INCLUDE i2c.asm
	INCLUDE sbus.asm
	INCLUDE crc.asm
	
	IF      BARCODE_FORMAT EQ BINARY72
	include arith1.asm        
	ENDIF
	
	INCLUDE number.asm
	INCLUDE memory.asm
	INCLUDE math.asm
	INCLUDE prt.asm

	IF      BIGFONT
	INCLUDE drawfont.asm
	INCLUDE raster.asm
	INCLUDE printer.asm
	ELSE
	INCLUDE printer.asm
	ENDIF

	INCLUDE erp.asm
	INCLUDE card.asm
	INCLUDE cdrawer.asm
	INCLUDE custdisp.asm
	INCLUDE lcd2x24.asm
	INCLUDE system.asm

	IF      SPEAKER
	INCLUDE sound.asm
	ENDIF

	IF      LEDS
	INCLUDE leds.asm
	ENDIF

	INCLUDE keyboard.asm
	INCLUDE comms.asm
	include EXAR2550.ASM
	
	IF      EXAR_BARCODE_APPLICATION
	IF      EXAR_BARCODE_APPLICATION EQ 7
	include CHEETAH7.ASM    ; High Volume Traffic Simulator
	ELSE
	include CHEETAH1.ASM    ; Live Device Handler
	ENDIF
	ENDIF
	
	include RS232.ASM
	IF USE_RS485
	 INCLUDE rs485.asm
	ELSE
NODE_ID_INSTALL EQU 255
	ENDIF
	INCLUDE pplug.asm
	INCLUDE login.asm
	INCLUDE manager.asm
	INCLUDE operator.asm

	INCLUDE rtc.asm

	INCLUDE time.asm
	INCLUDE spotchck.asm
	INCLUDE ticket.asm
	include locators.asm
	INCLUDE tktprint.asm
	INCLUDE receipt.asm
	INCLUDE shift.asm
;       INCLUDE waybill.asm
	INCLUDE diags.asm
;       INCLUDE audit.asm
;       INCLUDE audith.asm
;       INCLUDE upload.asm
	INCLUDE menu.asm

	INCLUDE barcode.asm
	IF USE_RS485
	 INCLUDE ddsnet.asm
	ENDIF
	INCLUDE void.asm
	INCLUDE cutter2.asm
	IF USE_SLAVE
	 INCLUDE pktcomms.asm
	 INCLUDE slave.asm
	ENDIF
	IF USE_TKTCTRL
	 IF USE_ALTONCOMMS
;         INCLUDE altctrl.asm
	  INCLUDE disnae.asm
	 ELSE
	  INCLUDE tktctrl.asm
	 ENDIF
	ENDIF
	IF USE_TMACHS
	 INCLUDE loudoun.asm
	ENDIF
	IF USE_ALTON_FAST
	 INCLUDE altoncom.asm
	ENDIF

;;;     INCLUDE complink.asm
	INCLUDE delay.asm
;******************************************************************************
;
;                          D E B U G   R O U T I N E S
;
;*******************************************************************************


DebugTX:

;DebugTX2:
;       PUSHB
;       MOV     B,#1
;       CALL    COM_TxChar
;       POP     B
;       RET

TxCr:

DBG_TxChar:

DBG_TxStr:

DBG_DumpXRAM:   ; DPTR=addr, R6/R7=len
DBG_DXRloop:
	RET
DBG_DXRnoeol:

	MOVX    A,@DPTR
	PUSHACC
	SWAP    A
	CALL    HexChar
	CALL    DBG_TxChar
	POP     ACC
	CALL    HexChar
	CALL    DBG_TxChar
	MOV     A,#32
	CALL    DBG_Txchar

	INC     DPTR
	DEC     R5
	DJNZ    R7,DBG_DXRloop
	DJNZ    R6,DBG_DXRloop

	CALL    TxCr
	POP     ACC
	MOV     R5,ACC
	POP     ACC
	POP     B
	RET


DT_KeypressTimeout:

	IF      SPEAKER
	;CALL   SND_Warning
	ENDIF

DT_KTloop:
	CALL    KBD_ReadKey
	JNZ     DT_KTdone
	MOV     R0,#1
	CALL    delay100ms
	DJNZ    R7,DT_KTloop
DT_KTdone:
	RET
;******************************************************************************
;
; Function:     DT_HelloMessage
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

DT_HelloMessage:
	MOV     A,#9
	CALL    DIS_GotoXY
	MOV     DPTR,#msg_totem1
	CALL    DIS_DisplayStringCODE
	MOV     A,#64
	CALL    DIS_GotoXY
	MOV     DPTR,#msg_totem2
	CALL    LCD_LanguageStringSelect
	CALL    DIS_DisplayStringCODE
	RET

;******************************************************************************
;
; Function:     DT_DisplayCustomerName
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

	IF DT10W
msg_customer:   DB 255,21,1,0,0,0,21,'       Bob           '
	ELSE
msg_customer:   DB 255,21,0,0,0,0,21,'       Bob           '
	ENDIF

DT_DisplayCustomerName:
	MOV     DPTR,#msg_customer
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#FIELD_HEADER+21
	CALL    MEM_CopyCODEtoXRAMsmall

	MOV     DPTR,#buffer+FIELD_HEADER
	CALL    MEM_SetDest
	MOV     DPTR,#ppg_fixhdr_custname
	CALL    MEM_SetSource
	MOVX    A,@DPTR
	JZ      DT_DCNskip
	INC     DPTR
	MOV     R7,A
	CALL    MEM_SetSource
	CALL    MEM_CopyXRAMtoXRAMsmall
	MOV     A,#16
	CALL    PRT_SetBitmapLenSmall
	CALL    PRT_ClearBitmap
	MOV     DPTR,#buffer
	CALL    PRT_FormatXRAMField
	IF DT10W
	ELSE
	 CALL    PRT_PrintBitmap
	ENDIF
DT_DCNskip:
	RET

;******************************************************************************
;
; Function:     DT_DisplayUserName
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

	IF DT10W
msg_user:       DB 255,21,1,0,2,0,21,'User:                '
	ELSE
msg_user:       DB 255,21,0,0,0,0,21,'User:                '
	ENDIF

DT_DisplayUserName:
	MOV     DPTR,#msg_user
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#FIELD_HEADER+21
	CALL    MEM_CopyCODEtoXRAMsmall

	MOV     DPTR,#buffer+FIELD_HEADER+6
	CALL    MEM_SetDest
	MOV     DPTR,#ppg_hdr_username
	MOVX    A,@DPTR
	JZ      DT_DUNskip
	INC     DPTR
	MOV     R7,A
	CALL    MEM_SetSource
	CALL    MEM_CopyXRAMtoXRAMsmall
	IF DT10W
	ELSE
	 MOV     A,#16
	 CALL    PRT_SetBitmapLenSmall
	 CALL    PRT_ClearBitmap
	ENDIF
	MOV     DPTR,#buffer
	CALL    PRT_FormatXRAMField
	IF DT10W
	ELSE
	 CALL    PRT_PrintBitmap
	ENDIF
DT_DUNskip:
	RET

;******************************************************************************
;
; Function:     DT_CheckPowerUpMessages
; Input:        None
; Output:       A=zero if messages enabled
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

DT_CheckPowerUpMessages:
	MOV     DPTR,#man_misc2
	MOVX    A,@DPTR
	ANL     A,#MAN_INHIBITPOWERUPMSG
	RET

;******************************************************************************
; Main Program
;******************************************************************************

	IF DT10W
msg_please:     DB 255, 6,1,0,3,48, 6,'Please'
msg_wait:       DB 255, 7,1,0,4,48, 7,'Wait...'
	ENDIF
msg_pleasewait: DB 255,14,0,0,0, 0,14,'Please Wait...'
msg_ready:      DB 255, 5,0,0,0, 0, 5,'Ready'
msg_eereadfail: DB 255,15,0,0,0, 0,15,'PricePlug Error'
msg_eereadok:   DB 255,16,0,0,0, 0,16,'PricePlug Loaded'
msg_ClearDown:     DB 16,'Clearing Memory!'

msg_product:            ;language dependent message
	IF DT10W

	 DB 24, ' Totem Wristbander '
	 DT_VERSION;
	 DB 24, '  KIS Wristbander  '
	 DT_VERSION;

	ENDIF
	IF DT10
	 IF VT1

	  DB 24, 'Totem Vending VT1  '
	  DT_VERSION;
	  DB 24, ' KIS Vending VT1   '
	  DT_VERSION;

	 ELSE

	  DB 24, 'XQ10 Slave         '
	  DT_VERSION;
	  DB 24, 'XQ10 Slave         '
	  DT_VERSION;

	 ENDIF
	ENDIF

msg_totem1:     DB 3,'DDS'

msg_totem2:     DB 20,' Totem Desktop DT10 '
		DB 20,'  KIS Desktop DT10  '

	IF DT10W
msg_manplug:    DB 255,12,1,0,4,0,12,'Manager Mode'
	ELSE
msg_manplug:    DB 255,12,0,0,0,0,12,'Manager Mode'
	ENDIF

msg_issuemethods:
	IF DT10W
	 DB 255,21,1,0,6,0,21,'Instant Issue        '
	 DB 255,21,1,0,6,0,21,'Full Subtotalling    '
	 DB 255,21,1,0,6,0,21,'Instant Subtotalling '
	ELSE
	 DB 255,21,0,0,0,0,21,'Instant Issue        '
	 DB 255,21,0,0,0,0,21,'Full Subtotalling    '
	 DB 255,21,0,0,0,0,21,'Instant Subtotalling '
	ENDIF

;***************************************************************************

dt_lastscannerinput: VAR 32 ; disney test

DT_ColdBoot:
	MOV     IEN0,#0                 ; disable all interrupts
	MOV     IEN1,#0
	MOV     IEN2,#0

	CLR     F1                      ; select 13bit e2 addressing
	CLR     F0                      ; select main i2c line

	JMP     DIA_SaveBootInfo


;************

DT_WarmBoot:
	MOV     SP,#stackpointer

	MOV     A,#SYS_AREA_WARMBOOT
	CALL    SYS_SetAreaCode

	MOV     R0,#2                   ; clear internal ram
	MOV     R1,#254                 ; (except first two bytes
DT_ClearIRAM:                           ;  which are R0 and R1)
	MOV     @R0,#0FFh               ;
	INC     R0                      ;
	DJNZ    R1,DT_ClearIRAM         ;
	MOV     sys_intnest,#1
;       CALL    SYS_IntPriority
	MOV     R0,#PortMirrorA
	MOV     @R0,#0
	MOV     R0,#PortMirrorB
	MOV     @R0,#0
	MOV     R0,#PortMirrorC
	MOV     @R0,#0
	MOV     R0,#PortMirrorD
	MOV     @R0,#0
	MOV     R0,#PortMirrorE
	MOV     @R0,#0
	MOV     R0,#10
	CALL    delay100ms
	CALL    SYS_ReadSystemStats
	MOV     kbd_rxpkt_state,#0
	CLR     cdopen
	CLR     sys_ppon
	CLR     sys_aon
	CLR     sys_prnon
	CLR     SYS_overheating
	CLR     alt_bpressed
	MOV     SYS_heatcount,#0
	MOV     com_txok,#0
	MOV     A,#0
	CALL    MTH_LoadOp1Acc
	MOV     DPTR,#sys_pulsecount
	CALL    MTH_StoreLong
	MOV     lcd_delaybacklite,#0


;       CALL    SYS_UnitPowerOn
	MOV     TMOD,#011h              ; timers 0 and 1 in mode 1 (16 bit)
	ORL     TCON,#050h              ; timers 0 and 1 on
	ORL     IEN0,#002h              ; timers 0 and 1 interrupt enabled
;       CALL    CUT_UnlockTurnstile
	CALL    KBD_InitKeyboard
;       CALL    AUD_InitAudit
	CALL    COM_InitSerial
	IF USE_SLAVE
	CALL    COM_InitPacketComms
	ENDIF
	IF USE_RS485
	 CALL   COM_InitRS485
	ENDIF

	IF      SPEAKER
	CALL    SND_InitSound
	ENDIF

	CALL    LCD_Init
	CALL    LCD_LoadCharSet
       CALL    SYS_DetectRAM

	IF      LEDS
	MOV     led_leds,#0             ; all LEDS off
	CALL    LED_LED1On
	CALL    LED_LED2Off
	CALL    LED_LED3Flash
	CALL    LED_LED4Off
	ENDIF

	CALL    CUT_FireCutter          ;Cycle Cutter
	IF CLEAR

	CALL    KBD_ScanKeyboard
	CJNE    A,#20,SkipClearDown
	MOV     DPTR,#msg_ClearDown
	CALL    LCD_DisplayStringCODE
	CALL    testdelay
	MOV     A,#0
	MOV     DPTR,#0100h
ClearDownLoop
	MOVX    @DPTR,A
	INC     DPTR
	MOV     A,DPH
	CJNE    A,#080h,ClearDownLoop

SkipClearDown
	ENDIF

	IF USE_TMACHS
	 CALL   LOU_TurnstileClickSetup
	ENDIF

	IF USE_SERVANT
	MOV     B,#1
	CALL    COM_TxStatus            ; transmit initial status
	ENDIF

	CALL    SYS_EnableInts          ; turn master interrupts on


	IF DT5
	ELSE

	 MOV    DPTR, #msg_product
	 CALL   LCD_LanguageStringSelect
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#bcd_name
	 CALL   LCD_DisplayStringCODE
	ENDIF
	CALL    DIS_Init
	CALL    LCD_TurnBacklightOff
	CALL    DT_HelloMessage

	CALL    SYS_ReadUnitInfo


	MOV     DPSEL,#0
;       MOV     DPTR,#aud_entry_switchon
;       CALL    AUD_AddEntry

; assume some values for just now
	CALL    PRT_GetPrintOffset
	CALL    PRT_GetPrintQuality
;       MOV     prt_stepdelay3,#10
;       MOV     DPTR,#prt_density
;       MOV     A,#10
;       MOVX    @DPTR,A

	CLR     prt_paperout
	SETB    prt_perfmode
	IF DT10W
	 MOV     prt_perfoffhigh,#00h ; now duplicated in GetPerfOffset
	 MOV     prt_perfofflow,#0f8h ;
	 CALL    PRT_GetPerfOffset
	 CALL    PRT_TweakPerfOffset
	 MOV     prt_perfmarkhigh,prt_perfoffhigh
	 MOV     prt_perfmarklow,prt_perfofflow
	 MOV     prt_perffailhigh,#07h
	 MOV     prt_perffaillow,#08h
	 MOV     prt_perflinemin,#60    ; duplicated in GetPerfLineSize
	 MOV     prt_perflinemax,#70    ;
	 CALL    PRT_GetPerfLineSize
	ELSE
	 MOV     prt_perfoffhigh,#01h ; now duplicated in GetPerfOffset
	 MOV     prt_perfofflow,#03ah ;
	 CALL    PRT_GetPerfOffset
	 CALL    PRT_TweakPerfOffset
	 MOV     prt_perfmarkhigh,prt_perfoffhigh
	 MOV     prt_perfmarklow,prt_perfofflow
	 MOV     prt_perffailhigh,#03h
	 MOV     prt_perffaillow,#0E8h ; was 084h
	 MOV     prt_perflinemin,#50    ; duplicated in GetPerfLineSize
	 MOV     prt_perflinemax,#60    ;
	 CALL    PRT_GetPerfLineSize
	ENDIF
	MOV     prt_perfskipminhigh,#0
	MOV     prt_perfskipminlow,#215
	MOV     prt_perfskipmaxhigh,#1
	MOV     prt_perfskipmaxlow,#10

	MOV     R1,#PRT_PHASE_SEQ
	MOV     R2,#PRT_INPUT0_SEQ
	MOV     R3,#PRT_INPUT1_SEQ
	IF VT10
	MOV     A,#0
	ELSE
	MOV     A,#MAN_EXT_POWERUP
	ENDIF
	CALL    PRT_SetPrintDevice
	CALL    PRT_Initialise

;       CALL    DIA_CheckBootInfo


;        CALL   DT_CheckPowerUpMessages
;        JNZ    DT_nomsg1
	CALL    PRT_StartPrint                  ; initial formfeed to see if
;       CALL    PRT_FormFeed                    ; there is any paper in and
	MOV     R7,#125
	CALL    PRT_LineFeed
	CALL    PRT_EndPrint                    ; if its perfed or plain
	CALL    CUT_FireCutter                  ; Cycle Cutter
;       CALL    DIA_TestPrint
;       CALL    SYS_PowerUpMessage
;       CALL    DIA_TestPrint
DT_nomsg1:
	CALL    PPG_InitPricePlug
	CALL    TIM_InitialiseClock
	CALL    TKT_Init
	CALL    PRT_StartPrint

	IF DT5                                  ; display please wait
	ELSE                                    ; message on DT10/DT10W
	 CALL   LCD_Clear2                      ;
	 MOV    A,#64                           ;
	 CALL   LCD_GotoXY                      ;
	 MOV    DPTR,#msg_pleasewait+6          ;
	 CALL   LCD_DisplayStringCODE           ;
	ENDIF                                   ;
	CALL    DT_CheckPowerUpMessages
	JNZ     DT_nomsg2
	MOV     R7,#8
	CALL    PRT_LineFeed
	IF DT10W                                ; print please wait message
	 MOV    A,#96                           ;
	 CALL   PRT_SetBitmapLenSmall           ;
	 CALL   PRT_ClearBitmap                 ;
	 MOV    DPTR,#msg_please                ;
	 CALL   PRT_FormatCODEField             ;
	 MOV    DPTR,#msg_wait                  ;
	 CALL   PRT_FormatCODEField             ;
	 CALL   PRT_PrintBitmap                 ;
	ELSE                                    ;
	 MOV    DPTR,#msg_pleasewait            ;
	 CALL   PRT_DisplayMessageCODE          ;
	 CALL   PRT_FormFeed                    ;
	ENDIF                                   ;
DT_nomsg2:
;       CALL    DIS_PowerOnMessage

	CALL    LOG_NewLogin

	IF DT10W                                ;
	 MOV    A,#(21*6)                       ;
	 CALL   PRT_SetBitmapLenSmall           ;
	 CALL   PRT_ClearBitmap                 ;
	ENDIF                                   ;

	CALL    DT_CheckPowerUpMessages
	JNZ     DT_nomsg3
	CALL    DT_DisplayCustomerName          ; print the customer name
	CALL    DT_DisplayUserName              ; print the user name
DT_nomsg3:
	MOV     DPTR,#ppg_fixhdr_plugtype
	MOVX    A,@DPTR
	CJNE    A,#PPG_OPERATOR,DTnotop
	CALL    TKT_CalcTicketCounts
	CALL    OPR_LoadOperatorConfig
	JMP     DTnotman
DTnotop:
	CJNE    A,#PPG_MANAGER,DTnotman
	CALL    DT_CheckPowerUpMessages
	JNZ     DT_nomsg4
	MOV     DPTR,#msg_manplug
	IF DT10W
	 CALL   PRT_FormatCODEField
	ELSE
	 CALL   PRT_DisplayMessageCODE
	ENDIF
DT_nomsg4:
DTnotman:
	CALL    DT_CheckPowerUpMessages
	JNZ     DT_nomsg5
	IF DT10W
	 MOV    A,#(21*6)
	 CALL   PRT_SetBitmapLenSmall
	ELSE
	 MOV    A,#8
	 CALL   PRT_SetBitmapLenSmall
	 CALL   PRT_ClearBitmap
	ENDIF
	MOV     DPTR,#man_issuemethod
	MOVX    A,@DPTR
	DEC     A
	MOV     B,#28
	MUL     AB
	MOV     DPTR,#msg_issuemethods
	CALL    AddABtoDPTR
	CALL    PRT_FormatCODEField
	CALL    PRT_PrintBitmap
DT_nomsg5:
;****************
	CALL    PRT_EndPrint

	IF DT5 OR USE_ALTONCOMMS                ; force instant
	 MOV    DPTR,#man_issuemethod           ; issue if
	 MOV    A,#1                            ; compiling for
	 MOVX   @DPTR,A                         ; DT5
	 MOV    DPTR,#ppg_chunk_manager         ;
	 CALL   CRC_GenerateChecksum            ;
	ENDIF                                   ;

	IF DT5
	ELSE
	 CALL   LCD_Clear
;        CALL   DIS_IdleMessage
	ENDIF
	CALL    DT_CheckPowerUpMessages
	JNZ     DT_nomsg6
	CALL    PRT_StartPrint
	CALL    PRT_FormFeed
	CALL    PRT_EndPrint
DT_nomsg6:
	CLR     A
	CALL    PRT_SetPrintDevice

;       CALL    CUT_FireCutter
	IF USE_SLAVE
	 CALL   SLV_SendFullConfig
	ENDIF
	CALL    TKT_DisplaySubtotal

	CALL    LCD_SetTimeout

	IF      LEDS
	CALL    LED_Led3On
	ENDIF

	IF USE_UPLOAD
	 CALL    UPL_WaitToUpload
	ENDIF



	call    EXAR_Start
	call    EXAR_StatsInit

	IF USE_TKTCTRL
	 CALL   RS485_EnableReceive
	 CALL   TKC_ReceiveStartupMessage
	ENDIF

	IF      QTRACE_ON
	mov     dptr,#qtrack
	clr     a
	mov     b,#QTRACE_ON
DT_IniTrace:
	movx    @dptr,a
	inc     dptr
	djnz    b,DT_IniTrace
	ENDIF
	IF USE_ALTON_FAST
	 CALL   RS485_EnableReceive
	ENDIF


	IF      PAPERDETECT
	mov     a,#17
	call    PortSetD
	ENDIF

	IF      EXAR_BARCODE_APPLICATION
	
	call    CHEETAH_Initial

	ENDIF

;**************************
;
; T h e   M a i n   L o o p
;
;**************************
DT_MainLoop:


	IF USE_TKTCTRL

	 CALL   TKC_Idle
	ELSE
	 IF USE_ALTON_FAST
DT_MLgetpacketloop:
	  CALL  TKC_Idle
	  JNZ   DT_MLgetpacketloop
	 ELSE
	  IF USE_RS485
	   CALL  NET_ReceivePacket
	  ENDIF
	 ENDIF
	ENDIF

	IF USE_UPLOAD
	 CALL   AUD_CheckAuditWarning
	ENDIF

	MOV     A,#SYS_AREA_MAINLOOP
	CALL    SYS_SetAreaCode
	CALL    TKT_CheckTimeout
	CALL    PPG_CheckPricePlug
	CALL    CRD_DetectCard

	CALL    BCD_CheckScannerInput           ; Disney Test
	JNC     DT_nobcd                        ;
	MOV     DPSEL,#0
	MOV     DPTR,#bcd_scannerinput
	MOV     DPSEL,#1
	MOV     DPTR,#dt_lastscannerinput
	MOV     R7,#32
	CALL    MEM_CompareXRAMsmall
	JC      DT_nobcd
	MOV     DPTR,#bcd_scannerinput
	CALL    MEM_SetSource
	MOV     DPTR,#dt_lastscannerinput
	CALL    MEM_SetDest
	MOV     R7,#32
	CALL    MEM_CopyXRAMtoXRAMsmall
	MOV     A,#11                           ;

	JMP DT_MLkeypress                       ;

DT_nobcd:
	
	IF      EXAR_BARCODE_APPLICATION

	call    CHEETAH_State
	jnc     DT_EXAR_NoTraffic
	mov     a,#11
	jmp     DT_MLkeyPress
DT_EXAR_NoTraffic:
	
	ENDIF
	
	IF USE_TMACHS
	 CALL   LOU_CheckTurnstileClick
	ENDIF

	IF DT5
	ELSE


	 CALL   TIM_DisplayDateTime
	ENDIF



;       ;Put Line A B Detection In here.
;       CALL    KBD_Read_Triggers


	CALL    KBD_ReadKey
	JZ      DT_MainLoop             ;Back to MAIN LOOP if no keypress

DT_MLkeypress:
	PUSHACC
	MOV     DPTR,#tkt_idlestate
	MOVX    A,@DPTR
	JZ      DT_NotIdle
	CALL    LCD_Clear
	CALL    TKT_DisplayIdleState
DT_NotIdle:
	CLR     A
	MOVX    @DPTR,A
	POP     ACC
	JB      kbd_functionkey,DT5_DoFunctionKey
	IF DT5
	JB      kbd_managerkey,DT5_DoManagerKey
	ENDIF
;******************
; Normal keypresses
;******************
DT5_DoNormalKey:
	CALL    DT5_NormalKey


	JMP     DT5_Continue
DT5_NormalKey:
	MOV     DPTR,#normalkeytable
	DEC     A
	RL      A
	JMP     @A+DPTR
;**************
; Function Keys
;**************
DT5_DoFunctionKey:
	CALL    DT5_FunctionKey
	CLR     kbd_functionkey
	JMP     DT5_Continue
DT5_FunctionKey:
	MOV     DPTR,#functionkeytable
	DEC     A
	RL      A
	JMP     @A+DPTR

	IF DT5
;*************
; Manager Keys
;*************
DT5_DoManagerKey:
	CALL    DT5_ManagerKey
	CLR     kbd_managerkey
	JMP     DT5_Continue
DT5_ManagerKey:
	MOV     DPTR,#managerkeytable
	DEC     A
	RL      A
	RL      A
	JMP     @A+DPTR
	ENDIF

DT5_Continue:


	JB      kbd_functionkey,DT5_FuncLed
	JB      kbd_managerkey,DT5_ManLed
	JB      kbd_shiftkey,DT5_FuncLed

	IF      LEDS
	CALL    LED_Led2Off
	ENDIF

	MOV     DPTR,#tkt_idlestate
	MOVX    A,@DPTR
	JNZ     DT_NoClear


	CALL    LCD_Clear
DT_NoClear:


	CALL    TKT_DisplayIdleState
	SETB    tim_timerupdate
	SETB    tim_timerenabled


	JMP     DT_MainLoop
DT5_ManLed:

	IF      LEDS
	CALL    LED_Led2Flash
	ENDIF

	CLR     tim_timerenabled
	JMP     DT_MainLoop
DT5_FuncLed:

	IF      LEDS
	CALL    LED_Led2On
	ENDIF

	JMP     DT_MainLoop

DT_Unused:
	RET
;*******************************************************************************
	ALIGN   ToPage
normalkeytable:
	AJMP    DT_Key0
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey
	AJMP    DT_NumberKey

	IF USE_ALTONCOMMS
	 AJMP   DT_KeyA
	ELSE
	 AJMP   DT_TicketKey
	ENDIF

	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_TicketKey
	AJMP    DT_KeyCancel
	AJMP    DT_KeyOk

	IF USE_ALTONCOMMS
	 AJMP   DT_KeyA
	ELSE
	 AJMP   DT_ExternalKey
	ENDIF

;***
DT_ExternalKey:
	RET


	IF USE_ALTONCOMMS
DT_KeyA:
	MOV     A,#0
	CALL    DT_Ticket

	CALL    COM_InitRS485

;       SETB    alt_specialcut
;       CALL    CUT_FireCutter
;       CLR     alt_specialcut
	
	RET
	ENDIF

DT_Key0:
	MOV     DPTR,#tkt_qtystrlen
	MOVX    A,@DPTR
	JZ      DT_Key0Func
	CLR     A
	JMP     DT_NumberKey
DT_Key0Func:
;       MOV     DPTR,#tkt_idlestate
;       CLR     A
;       MOVX    @DPTR,A
	SETB    kbd_functionkey

	IF      LEDS
	CALL    LED_Led2On
	ENDIF

	RET
DT_NumberKey:
	IF USE_ALTONCOMMS
	 RET
	ELSE
	 RR      A
	 JMP     TKT_SetQuantity
	ENDIF
DT_TicketKey:
	RR      A
	CLR     C
	SUBB    A,#10
	JMP     DT_Ticket
DT_KeyOk:
	CALL    TKT_PrintTickets
	CALL    TKT_ClearQuantity
	CALL    TKT_ClearSubTotal
	CALL    TKT_DisplaySubtotal
	RET

DT_KeyCancel:
	IF USE_ALTONCOMMS
	 RET
	ELSE


	IF      LEDS
	CALL    LED_Led2On
	ENDIF

	CALL    KBD_WaitKey                     ; read first keystroke
	CJNE    A,#KBD_CANCEL,DT_KCnotcancel    ; HERE
	CALL    TKT_ClearQuantity
	CALL    TKT_ClearSubTotal
;       CALL    DIS_Clear
	CALL    TKT_DisplaySubTotal
	CLR     A
	MOV     DPTR,#tkt_idlestate
	MOVX    @DPTR,A
	JMP     DT_KCabort
DT_KCnotcancel:
	CJNE    A,#18,DT_KCnotH                 ; work out if its
	JMP     DT_KChotkey                     ; a hotkey or a numbered
DT_KCnotH:                                      ; ticket
	JNC     DT_KCabort                      ;
	CJNE    A,#11,DT_KCnotA                 ;
	JMP     DT_KChotkey                     ;
DT_KCnotA:                                      ;
	JNC     DT_KChotkey                     ;

	DEC     A                               ; its a number, store it
	JZ      DT_KCmenustart                  ; (possible jump straight
	MOV     DPTR,#tkt_type                  ;  into menu from here)
	MOVX    @DPTR,A                         ;

	CALL    KBD_WaitKey                     ; read next keystroke
	CJNE    A,#11,DT_KCnotA2                ; HERE
	JMP     DT_KCabort
DT_KCnotA2:
	JNC     DT_KCabort

	DEC     A                               ; its a number, append it
	PUSHACC                                 ; to the previous one to
	MOV     DPTR,#tkt_type                  ; generate a 2 digit number
	MOVX    A,@DPTR                         ;
	MOV     B,#10
	MUL     AB
	POP     B
	ADD     A,B                             ;
	DEC     A
DT_KCmenustart:
	IF DT5
	ELSE
	CALL    TKT_MenuTicket
	ENDIF
	JMP     DT_KCdone

DT_KChotkey:                                    ; its a hotkey ticket
	PUSHACC                                 ;
;        CALL   LCD_Clear                       ;
	POP     ACC                             ;
	CLR     C                               ;
	SUBB    A,#3                            ;
	CALL    DT_Ticket                       ;
	JMP     DT_KCdone

DT_KCabort:
	CALL    LCD_Clear
DT_KCdone:

	IF      LEDS
	CALL    LED_Led2Off
	ENDIF

	RET

	ENDIF ;;;;;;;;;;;; not USE_ALTONCOMMS

DT_Ticket:
	MOV     B,A
	CALL    PPG_TestChunkHotkeyTickets
	JZ      DT_TktNone


	MOV     A,B
	
	CALL    TKT_IssueTicket


DT_TktNone:
	RET

;*******************************************************************************
	ALIGN   ToPage
functionkeytable:
	AJMP    DT5_Func0
	AJMP    DT5_Func1
	AJMP    DT5_Func2
	AJMP    DT5_Func3
	AJMP    DT5_Func4
	AJMP    DT5_Func5
	AJMP    DT5_Func6
	AJMP    DT5_Func7
	AJMP    DT5_Func8
	AJMP    DT5_Func9
	AJMP    DT5_FuncA
	AJMP    DT5_FuncB
	AJMP    DT5_FuncC
	AJMP    DT5_FuncD
	AJMP    DT5_FuncE
	AJMP    DT5_FuncF
	AJMP    DT5_FuncG
	AJMP    DT5_FuncH
	AJMP    DT5_FuncCancel
	AJMP    DT5_FuncOk
	AJMP    DT_FuncExternalKey


DT5_Func0:
	IF USE_ALTONCOMMS
	ELSE
	 MOV     DPTR,#ppg_fixhdr_plugtype
	 MOVX    A,@DPTR
	 CJNE    A,#PPG_MANAGER,DT5_OkNoMan
	ENDIF

	IF DT5
	 SETB   kbd_managerkey

	 IF      LEDS
	 CALL   LED_Led2Flash
	 ENDIF

	ELSE
	 CALL   MAN_ManagerMenu
	ENDIF

	RET
DT5_OkNoMan:

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	RET

DT5_Func1:
	IF USE_ALTONCOMMS
;        CALL   WAY_PrintWaybill
	 RET
	ELSE
	 MOV     DPTR,#man_mancashup
	 MOVX    A,@DPTR
	 JZ      DT5_Func1Ok
	 MOV     DPTR,#ppg_fixhdr_plugtype
	 MOVX    A,@DPTR
	 CJNE    A,#PPG_MANAGER,DT5_Func1NoMan
DT5_Func1Ok:
	 CALL    WAY_PrintWaybill
DT5_Func1NoMan:
	 RET
	ENDIF

DT5_Func2:
	CALL    SYS_UnitPowerOff
	RET
DT5_Func3:
	CALL    PRT_PaperFeed
	RET
DT5_Func4:
	IF DT5 OR USE_ALTONCOMMS
	ELSE
	CALL    VOI_Void
	ENDIF
	RET
DT5_Func5:
	IF DT5 OR USE_ALTONCOMMS
	ELSE
	CALL    REC_Receipt
	ENDIF
	RET
DT5_Func6:
DT5_Func7:
DT5_Func8:
	CALL    CUT_FireCutter
	RET
DT5_Func9:
	MOV     A,#MAN_EXT_POWERUP
	CALL    PRT_SetPrintDevice
	CALL    PRT_FormFeed
	MOV     A,#0
	CALL    PRT_SetPrintDevice
	RET
DT5_FuncA:
DT5_FuncB:
DT5_FuncC:
DT5_FuncD:
DT5_FuncE:
DT5_FuncF:
DT5_FuncG:
DT5_FuncH:
DT5_FuncCancel:
DT5_FuncOk:
DT_FuncExternalKey:
	RET

;*******************************************************************************

	IF DT5
managerkeytable:
	LJMP    DIA_Diagnostics                 ; Manager 0
	NOP
	LJMP    AUD_FullAudit                   ; Manager 1
	NOP
	LJMP    SPT_SpotCheck                   ; Manager 2
	NOP
	LJMP    TIM_ChangeDate                  ; Manager 3
	NOP
	LJMP    TIM_ChangeTime                  ; Manager 4
	NOP
	LJMP    PRT_SetPrintIntensity           ; Manager 5
	NOP
	LJMP    PRT_SetPrintQuality             ; Manager 6
	NOP
	LJMP    PRT_SetPerfOffset               ; Manager 7
	NOP
	LJMP    PRT_SetPerfLineSize             ; Manager 8
	NOP
	LJMP    DT_Unused                       ; Manager 9
	NOP
	LJMP    DT_Unused                       ; Manager A
	NOP
	LJMP    DT_Unused                       ; Manager B
	NOP
	LJMP    DT_Unused                       ; Manager C
	NOP
	LJMP    DT_Unused                       ; Manager D
	NOP
	LJMP    DT_Unused                       ; Manager E
	NOP
	LJMP    DT_Unused                       ; Manager F
	NOP
	LJMP    DT_Unused                       ; Manager G
	NOP
	LJMP    DT_Unused                       ; Manager H
	NOP
	LJMP    DT_Unused                       ; Manager CANCEL
	NOP
	LJMP    DT_Unused                       ; Manager OK
	NOP
	LJMP    DT_Unused                       ; Manager External
	NOP
	ENDIF

;        align   var,topage        
;xcom1_buffer    var     256     ;
	
	IF      QTRACE_ON
qfill   VAR     ((@+256) AND (-256))-@
qtrack  VAR     QTRACE_ON
	ENDIF

	IF      XDIAGNOSE
xfill   VAR     ((@+256) AND (-256))-@
xtrack  VAR     XDIAGNOSE
	ENDIF

	IF      BIGFONT

	db      -1 dup (($+255) AND (-256))-$
	include \dev\xq10\slave\fonts\extra\xfont1.asm
	include \dev\xq10\slave\fonts\extra\xfont2.asm
	include \dev\xq10\slave\fonts\extra\xfont3.asm
	include \dev\xq10\slave\fonts\extra\xfont4.asm

	ENDIF


UDP_IP  EQU     0
	IF      UDP_IP
	INCLUDE sum1.asm
	ENDIF

$(1:32768-2048)
xcom1_buffer $res 2048
	END

;****** End DT.ASM ***************************************************        

