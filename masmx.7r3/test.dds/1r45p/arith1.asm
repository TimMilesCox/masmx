;************************************************************************
;                                                                       *
;       ARITH_B2I72     Tim, 11v2000                                    *
;                                                                       *
;       Translate       [R7] ASCII Decimal Digits @ *[DPTR]             *
;              to       72 Bits Unsigned Binary Integer in prt_field_str*         
;                                                                       *
;       72-Bit Result Field Can Represent up to 21 Decimal Digits       *
;       Literal Byte Count 9 is Placed in prt_field_len                 *
;                                                                       *
;       changes R0, A, B, mth_op1l                                      *
;                                                                       *
;************************************************************************



ARITH_CARRY     EQU     mth_op1ll
ARITH_COUNT     EQU     mth_op1lh
ARITH_BINARY    EQU     72
ARITH_FIELD     EQU     ARITH_BINARY/8
ARITH_B2I72:
        mov     r0,#prt_field_str               ; Zero Length-1 Bytes
        mov     ARITH_COUNT,#ARITH_FIELD-1      ; of the Result
        clr     A
ARITH_BIL1:     
        mov     @r0,a
        inc     r0
        djnz    ARITH_COUNT,ARITH_BIL1

        movx    a,@dptr                         ; Zero Add the First Digit
        anl     a,#15                           ; Numeric Bits Only
        mov     @r0,a
        jmp     ARITH_BIL72                     ; Any More?

ARITH_BIL2:
        mov     ARITH_CARRY,#0                  ; Upper Product Staging Reg.
        mov     ARITH_COUNT,#ARITH_FIELD        ; Process All Result Bytes
        mov     r0,#prt_field_str+ARITH_FIELD-1 ; Starting From Starboard
ARITH_BIL3:
        mov     a,@r0                           ; Multiply by 10
        mov     b,#10
        mul     ab
        add     a,ARITH_CARRY                   ; Add Previous Upper Product
        mov     @r0,a                           ; to New LS Product and Store
        mov     a,b                             ; 
        addc    a,#0                            ;  
        mov     ARITH_CARRY,a                   ; Save New Upper Product
        dec     r0                              ; Winch to Port
        djnz    ARITH_COUNT,ARITH_BIL3

        movx    a,@dptr                         ; Read Next External Digit
        anl     a,#15                           ; Strip Zone
        mov     ARITH_COUNT,ARITH_FIELD-1       ; Carries may Reach Length-1
        mov     r0,#prt_field_str+ARITH_FIELD-1 ; Add Numeric to Starboard
        add     a,@r0                           ; Result Byte
        mov     @r0,a
ARITH_BIL4:
        jnc     ARITH_BIL72                     ; Finished if No Carry
        dec     r0                              ; Elsewise Winch to Port
        clr     a                               ; Add Accumulated Field
        addc    a,@r0                           ; To An Array of Zero+Carry
        mov     @r0,a
        djnz    ARITH_COUNT,ARITH_BIL4
ARITH_BIL72:
        inc     dptr                            ; *External String++
        djnz    R7,ARITH_BIL2                   ;
        ret

        End     
