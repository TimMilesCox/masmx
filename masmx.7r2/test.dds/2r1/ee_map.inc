;******************************************************************************
;
; File     : EE_MAP
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
;   Date        Who     Ver     Comments
; 14/07/99      RS      V1.30   Added EE_minimumahead & EE_periodahead
;
;******************************************************************************

EE_SLAVE EQU 051h

EE_DTSERIAL             EQU     0       ; LONG (now obsolete)

EE_STATS_POWER          EQU     4       ; LONG
EE_STATS_MANUALRESET    EQU     8       ; LONG
EE_STATS_WDOGRESET      EQU     12      ; LONG
EE_STATS_CRASHRESET     EQU     16      ; LONG
EE_STATS_PPINSERTS      EQU     20      ; LONG
EE_STATS_PPERRORS       EQU     24      ; LONG
EE_STATS_TICKETS        EQU     28      ; LONG
EE_STATS_POWERFAIL      EQU     32      ; LONG
EE_STATS_TIMEOUT        EQU     36      ; LONG
EE_STATS_UPLOADS        EQU     40      ; LONG
EE_STATS_DOWNLOADS      EQU     44      ; LONG

EE_shift                EQU     48      ; WORD
EE_ticket               EQU     50      ; LONG
EE_printoffset          EQU     54      ; BYTE
EE_printquality         EQU     55      ; BYTE
EE_perfoffset           EQU     56      ; BYTE

EE_UNITINFO             EQU     57      ; 7 bytes

EE_perflinemin          EQU     64      ; BYTE
EE_txdelay              EQU     65      ; BYTE
EE_rxdelay              EQU     66      ; BYTE
EE_dtcount              EQU     67      ; BYTE

EE_tpp                  EQU     68      ; WORD
EE_pl                   EQU     70      ; WORD
EE_qtl                  EQU     72      ; BYTE
EE_minimumahead         EQU     73      ; BYTE
EE_periodahead          EQU     74      ; WORD
EE_ldspaddr             EQU     76      ; BYTE
EE_showsahead           EQU     77      ; BYTE

EE_mintl                EQU     78      ; BYTE

EE_HeadTolerance        EQU     79      ; BYTE
EE_TailTolerance        EQU     80      ; BYTE

;;;next free space is 81

;***************************** End Of EE_MAP.ASM ******************************
