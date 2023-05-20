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

F1	EQU 0D1h
DPSEL	EQU 092h

ADCON0	EQU 0D8h
ADCON1	EQU 0DCh
ADDAT	EQU 0D9h
DAPR	EQU 0DAh

IEN0	EQU 0A8h
ES0	EQU 0ACh
WDT     EQU 0AEh
EAL	EQU 0AFh
IEN1	EQU 0B8h
SWDT	EQU 0BEh
EX3	EQU 0BAh
IEN2	EQU 09Ah
CTCON	EQU 0E1h
IP0	EQU 0A9h
IP1	EQU 0B9h
;IRCON	EQU 0C0h
IEX3	EQU 0C2h
;TCON	EQU 088h
T2CON  EQU 0C8h
T2I0    EQU 0C8h
I3FR	EQU 0CEh

ex6     equ     0bdh
ex2     equ     0b9h
i2fr    equ     0cdh
iex2    equ     0c1h


;ARCON	EQU 0EFh
MD0	EQU 0E9h
MD1	EQU 0EAh
MD2	EQU 0EBh
MD3	EQU 0ECh
MD4	EQU 0EDh
MD5	EQU 0EEh

;CCEN	EQU 0C1h
;CC4EN	EQU 0C9h
;CCH1	EQU 0C3h
;CCH2	EQU 0C5h
;CCH3	EQU 0C7h
;CCH4	EQU 0CFh
;CCL1	EQU 0C2h
;CCL2	EQU 0C4h
;CCL3	EQU 0C6h
;CCL4	EQU 0CEh
CMEN	EQU 0F6h
CMH0	EQU 0D3h
CMH1	EQU 0D5h
CMH2	EQU 0D7h
CMH3	EQU 0E3h
;CMH4	EQU 0E5h
;CMH5	EQU 0E7h
;CMH6	EQU 0F3h
;CMH7	EQU 0F5h
CML0	EQU 0D2h
CML1	EQU 0D4h
CML2	EQU 0D6h
CML3	EQU 0E2h
;CML4	EQU 0E4h
;CML5	EQU 0E6h
;CML6	EQU 0F2h
;CML7	EQU 0F4h
CMSEL	EQU 0F7h
;CRCH	EQU 0CBh
;CRCL	EQU 0CAh
CTRELH	EQU 0DFh
CTRELL	EQU 0DEh
TH2    EQU 0CDh
TL2    EQU 0CCh

TL1     equ     08bh
TH1     equ     08dh


ET1     equ     0abh
TF1     equ     08fh

P4	EQU 0E8h
P4.0	EQU 0E8h
P4.1	EQU 0E9h
P4.2	EQU 0EAh
P4.3	EQU 0EBh
P4.4	EQU 0ECh
P4.5	EQU 0EDh
P4.6	EQU 0EEh
P4.7	EQU 0EFh

P5	EQU 0F8h
;P5.0	EQU 0F8h
;P5.1	EQU 0F9h
;P5.2	EQU 0FAh
;P5.3	EQU 0FBh
P5.4	EQU 0FCh
P5.5	EQU 0FDh
P5.6	EQU 0FEh
P5.7	EQU 0FFh

P6	EQU 0FAh

p6.0    equ     p6
p6.1    equ     p6
p6.2    equ     p6
p6.3    equ     p6
p6.4    equ     p6
p6.5    equ     p6
p6.6    equ     p6
p6.7    equ     p6

P7	EQU 0DBh
P8	EQU 0DDh

p8.0    equ p8
p8.1    equ p8
p8.2    equ p8
p8.3    equ p8
p8.4    equ p8
p8.5    equ p8
p8.6    equ p8
p8.7    equ p8

bP7 EQU 020h
P7.0 EQU 00h
P7.1 EQU 01h
P7.2 EQU 02h
P7.3 EQU 03h
P7.4 EQU 04h
P7.5 EQU 05h
P7.6 EQU 06h
P7.7 EQU 07h

PCON EQU 087h
S0BUF	EQU 099h
S0CON	EQU 098h
RI0	EQU 098h
TI0	EQU 099h
REN0	EQU 09Ch
S1BUF	EQU 09Ch
S1CON	EQU 09Bh
S1REL	EQU 09Dh

;	p3      equ     0B0H
P3.0    EQU     0B0H
P3.1    EQU     0B1H
P3.2    EQU     0B2H
P3.3    EQU     0B3H
P3.4    EQU     0B4H
P3.5    EQU     0B5H
P3.6    EQU     0B6H
P3.7    EQU     0B7H

;	p1      equ     090H
P1.0    EQU     090H
P1.1    EQU     091H
P1.2    EQU     092H
P1.3    EQU     093H
P1.4    EQU     094H
P1.5    EQU     095H
P1.6    EQU     096H
P1.7    EQU     097H


;******************************* End Of SFR.INC ********************************
