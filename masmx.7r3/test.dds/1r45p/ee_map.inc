;******************************************************************************
;
; File     : EE_MAP.INC
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the memory map for the DT5 motherboard EEPROM.
;
; System   : 80C51
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

EE_SLAVE EQU 051h

EE_DTSERIAL		EQU 0	; LONG (now obsolete)

EE_STATS_POWER		EQU 4	; LONG
EE_STATS_MANUALRESET	EQU 8	; LONG
EE_STATS_WDOGRESET	EQU 12	; LONG
EE_STATS_CRASHRESET	EQU 16	; LONG
EE_STATS_PPINSERTS	EQU 20	; LONG
EE_STATS_PPERRORS	EQU 24	; LONG
EE_STATS_TICKETS	EQU 28	; LONG
EE_STATS_POWERFAIL	EQU 32	; LONG
EE_STATS_TIMEOUT	EQU 36	; LONG
EE_STATS_UPLOADS	EQU 40	; LONG
EE_STATS_DOWNLOADS	EQU 44	; LONG

EE_shift	EQU	48	; WORD
EE_ticket	EQU	50	; LONG
EE_printoffset	EQU	54	; BYTE
EE_printquality	EQU	55	; BYTE
EE_perfoffset	EQU	56	; BYTE

EE_UNITINFO		EQU 57	; 7 bytes

EE_perflinemin	EQU	64	; BYTE

;***************************** End Of EE_MAP.ASM ******************************
