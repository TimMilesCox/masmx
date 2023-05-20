;*******************************************************************************
;
; File     : IRAM.INC
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the internal RAM (IRAM) memory map layout.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;*******************************************************************************

;*******************************************************************************
; 80C537 Internal RAM
; Hex Addr   Dec Addr   Usage
; ---------  ---------  --------------------------------------------------------
; 00h - 07h    0 -   7  Register Bank 0
; 08h - 0Fh    8 -  15  Register Bank 1 (Free RAM if bank 1 not used)
; 10h - 17h   16 -  23  Register Bank 2 (Free RAM if bank 2 not used)
; 18h - 1Fh   24 -  31  Register Bank 3 (Free RAM if bank 3 not used)
; 20h - 2Fh   32 -  47  Free RAM, direct/indirect byte addressable
;                       also bit addressable as 00h - 7Fh (20h - 2Fh)
;                                                 0 - 127 ( 32 -  47)
; 30h - 7Fh   48 - 127  Free RAM, direct/indirect byte addressable
; 80h - FFh  128 - 255  Free RAM, indirect byte addressable
;*******************************************************************************

;***************************** BIT addressable IRAM ****************************
;                  BYTEaddr
;                       BITaddr
;                  ---  ---

; bits of loc 32 used by SFR bP7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;kbd_scan    EQU 33
;;;;kbd_scan0   EQU     8       ; bit 0 of 33;
;;;;kbd_scan1   EQU     9       ; bit 1 of 33;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kbd_pkt_data    EQU 33

led_leds        EQU 34          ; flash status byte (bit n = LEDn+1 flashing)
led_led1flsh    EQU     16      ; bit 0 of 34
led_led2flsh    EQU     17      ; bit 1 of 34
led_led3flsh    EQU     18      ; bit 2 of 34
led_led4flsh    EQU     19      ; bit 3 of 34
; RESERVED      EQU     20      ; bit 4 of 34 } RESERVED...
; RESERVED      EQU     21      ; bit 5 of 34 } ...FOR...

EXAR_CR_Encountered EQU 21
RS485_Inpacket  EQU     22
XCOM1_Full      EQU     23

; RESERVED      EQU     22      ; bit 6 of 34 } ...MORE...
; RESERVED      EQU     23      ; bit 7 of 34 } ...LEDS
alt_specialcut  EQU     23      ; hyjack the fucking reserved bit
				; ^probably means hijack. T, 17iij2000
;               EQU 35
tkt_subtotalspace EQU   24
kbd_managerkey  EQU     25      ; bit 1 of 35 (DT5:man key, DT10:diags mode)
kbd_shiftkey    EQU     26      ; bit 2 of 35
ppg_plugstate   EQU     27      ; bit 3 of 35 (0 = priceplug inserted)
alton_sensorwait EQU    28
alt_bpressed    EQU     29
prt_perfmode    EQU     30      ; bit 6 of 35
tim_timerupdate EQU     31      ; bit 7 of 35

SB2data         EQU 36          ; SlowBus address 2
sys_prnon       EQU     32      ; bit 0 of 36, printer power
sys_ppon        EQU     33      ; bit 1 of 36, priceplug power
sys_uon         EQU     34      ; bit 2 of 36, unit power
sys_aon         EQU     35      ; bit 3 of 36, accessory power
cdopen          EQU     36
led_led1        EQU     37      ; bit 5 of 36, led 1
led_led2        EQU     38      ; bit 6 of 36, led 2
led_led3        EQU     39      ; bit 7 of 36, led 3

SB1data         EQU 37          ; SlowBus address 1
com_selab       EQU     45      ; bit 5 of 37, comm1 sel a/b

;               EQU 38
tim_timerenabled EQU    48      ; bit 0 of 38
kbd_diagskey    EQU     49      ; bit 1 of 38
lcd_backlight   EQU     50      ; bit 2 of 38
SYS_overheating EQU     51
com_firstpacket EQU     52      ; bit 4 of 38
com_multipacket EQU     53      ; bit 5 of 38
lou_tsjammedon  EQU     54      ; bit 6 of 38
lou_ledon       EQU     55      ; bit 7 of 38

stackcheck      EQU 39          ; byte used to check for stack overflow
stackcheck7     EQU     63      ; bit 7 of 39

com_retries     EQU 40

lou_statecount  EQU 41          ; this is a whole byte
lou_littlebc    EQU 42          ; this is a whole byte too
lou_ledcount    EQU 43

SYS_heatcount   EQU 44

servant_status  EQU 45
tkt_printed     EQU     104     ; bit 0 of 45
kbd_functionkey EQU     105     ; bit 1 of 45
kbd_doublecancel EQU    106     ; bit 2 of 45
kbd_1stcancel   EQU     107     ; bit 3 of 45
ppg_plugchange  EQU     108     ; bit 4 of 45
prt_paperout    EQU     109     ; bit 5 of 45 (1 = paper out)
sys_batlowwarn  EQU     110     ; bit 6 of 45

kbd_rxpkt_state EQU 46
com_txok        EQU 47


;**************************** BYTE addressable IRAM ****************************

sys_mynode              EQU 48
	IF USE_RS485
rs485_startbuf          EQU 49  ; start position of chars in rs485 buffer
rs485_endbuf            EQU 50  ; end position of chars in rs485 buffer
rs485_pktpos            EQU 51  ; start position in buffer of packet being built
rs485_ch                EQU 52  ; the rxed char currently being processed
rs485_lastchar          EQU 53  ; the last char (if it was a DLE) else 0
rs485_curpktlen         EQU 54  ; the len of packet received so far
rs485_actpktlen         EQU 55  ; the actual length of the packet
xcom1_write_cursor      equ     56
;rs485_inpacket          EQU 56  ; flag set if rx in middle of a packet
rs485_rxerrors          EQU 57  ; the count of errors on the RS485 rx line

			$if     0
rs485_actpktcrcl        EQU 58  ; the actual crc of the packet
rs485_actpktcrch        EQU 59  ;
			$endif

xcom1_rbsel             equ     58
xcom1_wbsel             equ     59

rs485_flyingcrcl        EQU 60  ; crc built up as packet received
rs485_flyingcrch        EQU 61  ;
rs485_packets           EQU 62  ; valid packet count in buffer
rs485_to                EQU 63  ; id of expected receiver
rs485_txcrcl            EQU 64
rs485_txcrch            EQU 65
rs485_txlen             EQU 66
rs485_txto              EQU 67
rs485_txfrom            EQU 68
;rs485_retries           EQU 69
xcom1_read_cursor       EQU     69        
	ELSE
; FREE                  EQU 49
; FREE                  EQU 50
; FREE                  EQU 51
; FREE                  EQU 52
; FREE                  EQU 53
; FREE                  EQU 54
; FREE                  EQU 55
; FREE                  EQU 56
; FREE                  EQU 57
; FREE                  EQU 58
; FREE                  EQU 59
; FREE                  EQU 60
; FREE                  EQU 61
; FREE                  EQU 62
; FREE                  EQU 63
; FREE                  EQU 64
; FREE                  EQU 65
; FREE                  EQU 66
; FREE                  EQU 67
; FREE                  EQU 68
; FREE                  EQU 69
	ENDIF

sys_intnest             EQU 70

;*** DT ***
spare2DPH               EQU 71
spare2DPL               EQU 72
srcDPH                  EQU 73
srcDPL                  EQU 74
destDPH                 EQU 75
destDPL                 EQU 76

;*** KEYBOARD ***
kbd_bufptr              EQU 77
kbd_buflen              EQU 78

;*** SYSTEM ***
sys_tick                EQU 79  ; system tick count

;*** PPLUG ***
ppg_error               EQU 80

;*** NUMBER ***
n0                      EQU 81  ; individual nibbles for
n1                      EQU 82  ; the number formatting
n2                      EQU 83  ; routines
n3                      EQU 84  ;
n4                      EQU 85  ;
n5                      EQU 86  ;
n6                      EQU 87  ;
n7                      EQU 88  ;

;*** LCD ***
lcd_delaybacklite       EQU 89

;*** MATHS ***
mth_operand1            EQU 90  ; operand 1 for the maths routines
mth_op1ll               EQU 90
mth_op1lh               EQU 91
mth_op1hl               EQU 92
mth_op1hh               EQU 93
mth_operand2            EQU 94  ; operand 2 for the maths routines
mth_op2ll               EQU 94
mth_op2lh               EQU 95
mth_op2hl               EQU 96
mth_op2hh               EQU 97

;*** PRT ***
prt_powerdelay          EQU 98
prt_stepdelay           EQU 99
prt_stepdelay2          EQU 100
prt_stepdelay3          EQU 101
prt_perfskipminhigh     EQU 102
prt_perfskipminlow      EQU 103
prt_perfskipmaxhigh     EQU 104
prt_perfskipmaxlow      EQU 105
prt_perfoffhigh         EQU 106
prt_perfofflow          EQU 107
prt_perffailhigh        EQU 108
prt_perffaillow         EQU 109
prt_perflinemin         EQU 110 ; minimum pulses to reach end of perfmark
prt_perflinemax         EQU 111 ; maximum pulses to reach end of perfmark
prt_perfmarklow         EQU 112 ; pulses since perfmark (low byte)
prt_perfmarkhigh        EQU 113 ; pulses since perfmark (high byte)
prt_outputdevice        EQU 114 ; current output device (0=internal printer)
prt_zerodetect          EQU 115 ; used in bitmap transfer to detect blank lines
prt_phase               EQU 116 ; current 2-bit phase pattern
prt_input0              EQU 117 ; current 2-bit input0 pattern
prt_input1              EQU 118 ; current 2-bit input1 pattern
prt_phaseseq            EQU 119 ; phase sequence (4x2bit)
prt_input0seq           EQU 120 ; input0 sequence (4x2bit)
prt_input1seq           EQU 121 ; input1 sequence (4x2bit)
prt_field_width         EQU 122 ; max char width of current field
prt_field_flags         EQU 123 ; flags for current field
prt_field_mag           EQU 124 ; magnification for current field
prt_field_x             EQU 125 ; x coord for current field
prt_field_y             EQU 126 ; y coord for current field
prt_field_len           EQU 127 ; length of contents of current field

;************************** INDIRECT BYTE ADDRESSABLE *******************************

prt_field_str           EQU 128 ; string representation of current field
				; (allowed for PRT_MAX_HORIZ_CHARS here)
prt_fontchrdata         EQU 160 ; the 8 font bytes for the current char image

;Output Data latch Mirrors to keep track of latch states
PortMirrorA     EQU 168
PortMirrorB     EQU 169
PortMirrorC     EQU 170
PortMirrorD     EQU 171
PortMirrorE     EQU 172

	IF USE_ALTONCOMMS
;*** KEYBOARD ***
kbd_keybuffer           EQU 173 ; circular keyboard buffer
				; (allowed for 4 bytes here (173-176)

;******
stackpointer            EQU 177 ; stack space (loc 177 not used (pre-inc))
				; (allowed for 79 bytes, 177-255)
	ELSE
;*** KEYBOARD ***
kbd_keybuffer           EQU 173 ; circular keyboard buffer
				; (allowed for 16 bytes here (173-188)

;******
stackpointer            EQU 188 ; stack space (loc 188 not used (pre-inc))
				; (allowed for 67 bytes, 188-255)
	ENDIF

;****************************** End Of IRAM.ASM ********************************
