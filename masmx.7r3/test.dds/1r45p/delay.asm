testdelay:    ; approx 0.5 sec  ;------------------------+------------+
	MOV     R0,#4           ;             |      1us |            |
testdelay1:                     ;-------------+----------+            |
	MOV     R1,#0           ;     |   1us |          | 4*         |
				;-----+-------+          | (131329+2) |
testdelay2:                     ;     | 256*2 | 256*     | +1         |
	MOV     R2,#0           ; 1us | +1    | (513+2)  | =          |
testdelay3:                     ;-----| =     | +1       | 525325us   |
	DJNZ    R2,testdelay3   ; 2us | 513us | =        |            |
				;-----+-------+ 131329us |            |
	DJNZ    R1,testdelay2   ;     |   2us |          |            |
				;-------------+----------+            |
	DJNZ    R0,testdelay1   ;     |       |      2us |            |
	RET                     ;------------------------+------------+

;******************************************************************************
;
; Function:     delay10us
; Input:        R0=no. of 10us to delay
; Output:       ?
; Preserved:    ?
; Destroyed:    R0
; Description:
;
;
;******************************************************************************

delay10us:
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	DJNZ    R0,delay10us
	RET

;******************************************************************************
;
; Function:     delay100us
; Input:        R0=no. of 100us to delay
; Output:       ?
; Preserved:    ?
; Destroyed:    R0,R1
; Description:
;
;
;******************************************************************************

delay100us: 
		                        ;-----+-----+-----+
	MOV     R1,#49                  ; 1us |48*2 |R0*  |
delay100usloop:                         ;-----++1   |100  |
	DJNZ    R1,delay100usloop       ; 2us |=97us|+2   |
					;-----+-----+     |
	NOP                             ;      1us  +     |
	DJNZ    R0,delay100us           ;      2us  |     |
					;-----------+-----+
	RET                             

;******************************************************************************
;
; Function:     delay100ms
; Input:        R0=no. of 100ms to delay
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

delay100ms:                             ;-----------+-------+-------+
	MOV     R1,#194                 ;      1us  |194*515|R0*    |
delay100msloop2:                        ;-----+-----++1     |100000 |
	MOV     R2,#0                   ; 1us |256*2|=      |+2     |
delay100msloop:                         ;-----++1   |99911us|       |
	DJNZ    R2,delay100msloop       ; 2us |=513 |       |       |
					;-----+-----+       |       |
	DJNZ    R1,delay100msloop2      ;      2us  |       |       |
					;-----------+-------+       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
	NOP                             ;            1us    |       |
					;-------------------+       |
	DJNZ    R0,delay100ms           ;            2us    |       |
	RET                             ;-------------------+-------+
;=============================================================================
;
delay_xms:
		call	delay_1ms
		djnz	ACC,delay_xms
		ret

delay_1ms:				; excluding CALL and RET (!)
		PUSHACC
		mov	a,#250
delay1:		djnz	ACC,delay1	; 500us at 12MHz
		mov	a,#250
delay2:		djnz	ACC,delay2	; another 500us
		pop	ACC
		ret
;*****************************************************************************
delay_40us	
	MOV	R0,#4			
	CALL	delay10us
	RET
