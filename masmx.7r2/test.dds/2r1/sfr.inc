;******************************************************************************
;
; File     : SFR.INC
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the SFR layout for the 80C537
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

F1      EQU 0D1h
DPSEL   EQU 092h

ADCON0  EQU 0D8h
ADCON1  EQU 0DCh
ADDAT   EQU 0D9h
DAPR    EQU 0DAh

IEN0    EQU 0A8h
ES0     EQU 0ACh
WDT     EQU 0AEh
EAL     EQU 0AFh
IEN1    EQU 0B8h
SWDT    EQU 0BEh
EX3     EQU 0BAh
IEN2    EQU 09Ah
CTCON   EQU 0E1h
IP0     EQU 0A9h
IP1     EQU 0B9h
;IRCON  EQU 0C0h
IEX3    EQU 0C2h
;TCON   EQU 088h
;T2CON  EQU 0C8h
T2I0    EQU 0C8h
I3FR    EQU 0CEh

I2FR    EQU 0CDh
IEX2    EQU 0C1h
EX2     EQU 0B9h
EX6     EQU 0BDh

;ARCON  EQU 0EFh
MD0     EQU 0E9h
MD1     EQU 0EAh
MD2     EQU 0EBh
MD3     EQU 0ECh
MD4     EQU 0EDh
MD5     EQU 0EEh

;CCEN   EQU 0C1h
;CC4EN  EQU 0C9h
;CCH1   EQU 0C3h
;CCH2   EQU 0C5h
;CCH3   EQU 0C7h
;CCH4   EQU 0CFh
;CCL1   EQU 0C2h
;CCL2   EQU 0C4h
;CCL3   EQU 0C6h
;CCL4   EQU 0CEh
CMEN    EQU 0F6h
CMH0    EQU 0D3h
CMH1    EQU 0D5h
CMH2    EQU 0D7h
CMH3    EQU 0E3h
;CMH4   EQU 0E5h
;CMH5   EQU 0E7h
;CMH6   EQU 0F3h
;CMH7   EQU 0F5h
CML0    EQU 0D2h
CML1    EQU 0D4h
CML2    EQU 0D6h
CML3    EQU 0E2h
;CML4   EQU 0E4h
;CML5   EQU 0E6h
;CML6   EQU 0F2h
;CML7   EQU 0F4h
CMSEL   EQU 0F7h
;CRCH   EQU 0CBh
;CRCL   EQU 0CAh
CTRELH  EQU 0DFh
CTRELL  EQU 0DEh
;TH2    EQU 0CDh
;TL2    EQU 0CCh

P4      EQU 0E8h

BIT$EQUATE$ equ 1
	
	IF      BIT$EQUATE$

P4.0    EQU 0E8h
P4.1    EQU 0E9h
P4.2    EQU 0EAh
P4.3    EQU 0EBh
P4.4    EQU 0ECh
P4.5    EQU 0EDh
P4.6    EQU 0EEh
P4.7    EQU 0EFh

	endif

P5      EQU 0F8h
	
	IF      BIT$EQUATE$



p1.0    equ     090h
p3.0    equ     0b0h
p1.1    equ     091h
p3.1    equ     0b1h
p1.2    equ     092h
p3.2    equ     0b2h
p1.3    equ     093h
p3.3    equ     0b3h
p1.4    equ     094h
p3.4    equ     0b4h
p1.5    equ     095h
p3.5    equ     0b5h
p1.6    equ     096h
p3.6    equ     0b6h
p1.7    equ     097h
p3.7    equ     0b7h





;P5.0   EQU 0F8h
;P5.1   EQU 0F9h
;P5.2   EQU 0FAh
;P5.3   EQU 0FBh
P5.4    EQU 0FCh
P5.5    EQU 0FDh
P5.6    EQU 0FEh
P5.7    EQU 0FFh

	endif

P6      EQU 0FAh
	
	IF      BIT$EQUATE$

P6.0    EQU 0FAh
P6.1    EQU 0FAh
P6.2    EQU 0FAh
P6.3    EQU 0FAh
P6.4    EQU 0FAh
P6.5    EQU 0FAh
P6.6    EQU 0FAh
P6.7    EQU 0FAh

	endif

P7      EQU 0DBh
P8      EQU 0DDh
	
	IF      BIT$EQUATE$

P8.0    EQU 0DDh
P8.1    EQU 0DDh
P8.2    EQU 0DDh
P8.3    EQU 0DDh

	endif


bP7 EQU 020h
	
	IF      BIT$EQUATE$

P7.0 EQU 00h
P7.1 EQU 01h
P7.2 EQU 02h
P7.3 EQU 03h
P7.4 EQU 04h
P7.5 EQU 05h
P7.6 EQU 06h
P7.7 EQU 07h

PX.0    EQU 001h
PX.1    EQU 002h
PX.2    EQU 004h
PX.3    EQU 008h
PX.4    EQU 010h
PX.5    EQU 020h
PX.6    EQU 040h
PX.7    EQU 080h

	else
PX      EQU     20h
	endif


;PCON EQU 087h
S0BUF   EQU 099h
S0CON   EQU 098h
RI0     EQU 098h
TI0     EQU 099h
REN0    EQU 09Ch
S1BUF   EQU 09Ch
S1CON   EQU 09Bh
S1REL   EQU 09Dh

;******************************* End Of SFR.INC ********************************
