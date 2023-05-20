;       ****************************************************************
;       *       File: FASTMATH.ASM                                     *
;       *       Tim   20ix99                                           *
;       *       MACROs, not subroutines                                *
;       ****************************************************************

;       ****************************************************************
;       *       QADS: quick add double to store                        *
;       *       adds 16 bits in A, B to storage location               *
;       *       named in MACRO argument 1.                             *
;       *       A = MSbyte. B = LSbyte.                                *
;       *       Storage target is little-endian                        *
;       *       Result is also kept big-endian in AB                   *
;       ****************************************************************


TWOS_COMPLEMENT EQU 1


qads    MACRO
        LMACRO  LIST
        mov     dptr,#qads(1,1) ; Address the Target
        push    acc             ; Save MSB of Increment
        movx    a,@dptr         ; Read LSB of Target
        add     a,b             ; Add LSB of Increment
        pop     b               ; Recover MSB of Increment
        push    acc             ; save LSB result
        movx    @dptr,a         ; Write LSB of Result to Left Location
        inc     dptr            ; Address MSB of Target
        movx    a,@dptr         ; Read MSB of Target
        addc    a,b             ; Add MSB of Increment + C
        movx    @dptr,a         ; Write MSB of Result to Right Location
        pop     b               ; LSB result in B; MSB result in A
        MACEND


;       ****************************************************************
;       *       QDANS: quick double add negative to store              *
;       *       subtracts 16 bits in A, B from storage location        *
;       *       named in MACRO argument 1.                             *
;       *       A = MSbyte. B = LSbyte.                                *
;       *       Storage target is little-endian                        *
;       ****************************************************************


qdans   MACRO
        LMACRO  LIST
        mov     dptr,#qdans(1,1); Address the Target
        cpl     a               ; Build 1s-complement
        xrl     b,#-1           ;
        push    acc             ; Save MSB of Increment
        movx    a,@dptr         ; Read LSB of Target

        IF      TWOS_COMPLEMENT
        setB    C               ; cause 2s-complement to be added
        ELSE                    ; or
        clr     C               ; cause 1s-complement to be added
        ENDIF

        addc    a,b             ; Add LSB of Increment
        pop     b               ; Retrieve MSB of Increment
        movx    @dptr,a         ; Write LSB of Result to Left Location
        inc     dptr            ; Address MSB of Target
        movx    a,@dptr         ; Read MSB of Target
        addc    a,b             ; Add MSB of Increment + C
        movx    @dptr,a         ; Write MSB of Result to Right Location
        MACEND


;       ****************************************************************
;       *       QDAN: quick double add negative                        *
;       *       subtracts 16 bits in storage location from A, B        *
;       *       storage location named in MACRO argument 1.            *
;       *       A = MSbyte. B = LSbyte.                                *
;       *       Storage source is little-endian                        *
;       ****************************************************************


qdan    MACRO
        LMACRO  LIST
        mov     dptr,#qdan(1,1) ; Address the Target
        push    acc             ; save MS byte Op1
        movx    a,@dptr         ; read LS byte Op2
        cpl     a               ; Build 1s-complement

        IF      TWOS_COMPLEMENT
        setB    C
        ELSE
        clr     C
        ENDIF

        addc    a,b             ; subtracts LS bytes
        pop     b               ; retrieve MS byte Op1
        push    acc             ; save LS byte result

        inc     dptr            ; read MS byte Op2
        movx    a,@dptr         ; Read MSB of Op2
        cpl     a               ; make 1s-complement

        addc    a,b             ; Subtract MSB of Decrement
        pop     b               ; Retrieve LSB of Result
        MACEND

;       ****************************************************************
;       *       QDANIR: quick double add negative from Internal Ram    *
;       *       subtracts 16 bits in IRAM from A, B                    *
;       *       IRAM location named in MACRO argument 1.               *
;       *       A = MSbyte. B = LSbyte.                                *
;       *       Storage source is little-endian                        *
;       ****************************************************************


qdanir  MACRO
        LMACRO  LIST
        push    acc             ; save MS byte Op1
        mov     a,qdanir(1,1)   ; read LS byte Op2
        cpl     a               ; Build 1s-complement

        IF      TWOS_COMPLEMENT
        setB    C
        ELSE
        clr     C
        ENDIF

        addc    a,b             ; subtract LS bytes
        pop     b               ; retrieve MS byte Op1
        push    acc             ; save LS byte result

        mov     a,qdanir(1,1)+1 ; Read MSB of Op2
        cpl     a               ; make 1s-complement

        addc    a,b             ; Subtract MSB of Decrement
        pop     b               ; Retrieve LSB of Result
        MACEND


;       ****************************************************************
;       *       QINC: quick increment                                  *
;       *       increments 16 bit word in storage location             *
;       *       named in MACRO argument 1.                             *
;       *       Storage target is little-endian                        *
;       ****************************************************************

qinc*   MACRO	*
        LMACRO  LIST
        mov     dptr,#qinc(1,1) ; Address the Target
        movx    a,@dptr         ; Read LSB of Target
        inc     a               ; +1
        jnz     qix             ; A=0=Carry=1
        movx    @dptr,a         ; Just Once in 256 Times
        inc     dptr            ; This is Little End Land
        movx    a,@dptr         ; 
        inc     a               ;                        
qix     movx    @dptr,a         ;
        MACEND

;       ****************************************************************
;       *       QDEC: quick decrement                                  *
;       *       decrements 16 bit word in storage location             *
;       *       named in MACRO argument 1.                             *
;       *       Storage target is little-endian                        *
;       ****************************************************************

qdec*   MACRO
        LMACRO  LIST
        mov     dptr,#qdec(1,1) ; Address the Target
        movx    a,@dptr         ; Read LSB of Target
        dec     a               ; -1
        cjne    a,#255,qdx
        movx    @dptr,a         ; Just Once in 256 Times
        inc     dptr            ; This is Little End Land
        movx    a,@dptr         ; 
        dec     a               ;                        
qdx     movx    @dptr,a         ;
        MACEND


;       ****************************************************************
;       *       QANBX: quick add negative byte                         * 
;       *       subtracts byte in storage location from AB             *
;       *       AB is big-endian. Storage location is                  *
;       *       macro argument 1                                       *
;       ****************************************************************

qanbx   MACRO
        LMACRO  LIST
        push    acc
        mov     dptr,#qanbx(1,1)
        movx    a,@dptr
        cpl     a

        IF      TWOS_COMPLEMENT
        setB    c
        ENDIF

        addc    a,b
        mov     b,a
        pop     acc
        addc    a,#255
        MACEND


;       ****************************************************************
;       *       QABX: quick add byte                                   * 
;       *       adds byte in storage location to AB                    *
;       *       AB is big-endian. Storage location is                  *
;       *       macro argument 1                                       *
;       ****************************************************************

qabx    MACRO
        LMACRO  LIST
        push    acc
        mov     dptr,#qabx(1,1)
        movx    a,@dptr
        add     a,b
        mov     b,a
        pop     acc
        addc    a,#0
        MACEND

;       ****************************************************************
;       *       QM168: quick multiply 16*8                             *
;       *       multiplies 16 bits in AB by 8 bits in XRAM             *
;       *           giving 16 bits (product bits 23:16 are discarded)  *
;       *       storage location named in MACRO argument 1.            *
;       *       A = MSbyte. B = LSbyte, before and after               *
;       ****************************************************************

qm168   MACRO
        LMACRO  LIST
        mov     dptr,#qm168(1,1); address the multiplier
        push    b               ; save LSB multiplicand
        mov     b,a             ; position MSB multiplicand
        movx    a,@dptr         ; read multiplier
        mov     r0,sp           ; save place in stack of LSB multiplicand
        push    acc             ; save multiplier
        mul     ab              ; multiply MSB of multiplicand * multiplier
        mov     b,@r0           ; overwrite product 23:16 with LSB multiplicand
        mov     @r0,a           ; save LSB of upper product
        pop     acc             ; retrieve multiplier
        mul     ab              ; multiply LSB of multiplicand by multiplier
        push    acc             ; get this rubbish the right way round
        mov     a,b
        pop     b
        add     a,@r0           ; add LSB upper result to MSB this result
        dec     sp              ; clear the stack
        MACEND

        END
