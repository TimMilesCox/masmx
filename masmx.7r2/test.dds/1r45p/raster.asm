;************************************************************************
;*      File    RASTER.ASM      Tim, 27i2000                            *
;*      Driven by the magnitude code in a print field to select from    *
;*      compiled-in large raster fonts.                                 *
;*      Magnification is encoded  HHHH VVVV                             *
;*      Where HHHH = 0000 = No Horizontal Magnification = *1            *
;*            VVVV = 0000 = No Vertical Magnification = *1              *
;*      Nonzero xxHHxxVV causes branch to this raster font handler      *
;*            0010 0010 = *3*3 using XFONT33                            *
;*            0010 0001 = *3*2 using XFONT32                            *
;*            0001 0010 = *2*3 using XFONT23                            *
;*            0001 0001 = *2*2 using XFONT22                            *
;*      Any  magnitude code that does not fit one of these is handled   *
;*      algorithmically as before. The point of these that the fonts can*
;*      vary and be tuned as source code.                               *
;*      When any of these four routines receives control,               *
;*              The field and its controls are in prt_field_etc         *
;*              DPTR0 = Start Position in Bit Map                       *
;*              R0 = &first char                                        *
;*              R7 = char count                                         *
;************************************************************************

RAS_xpand:                    ; Pixels = H24*V24
        mov     spare2dph,dph
        mov     spare2dpl,dpl
        push    dpsel
        mov     dpsel,#0
        mov     dph,spare2dph
        mov     dpl,spare2dpl

RAS_XL:
        mov     a,@r0
        inc     r0

        push    dph            ; save the bitmap pointer
        push    dpl


        mov     dpsel,#XFONTP
        clr     c
        rrc     a
        mov     b,#0
        mov     b.7,C
        mov     dpl,B
        add     a,#xfont SHR 8
        mov     dph,a

        mov     r5,#8          ; do the following 8 times
RAS_Thixel:                    ; draw 1, 2, 3 or 4 Pixel Lines
        mov     b,prt_field_mag

        jb      b.1,RAS_4Deep? ; 11=4/4 raster lines, 10=3/4, 01=1/2, 00 = 1/4
        jmp     RAS_2Deep?
RAS_4Deep?:
        jb      b.0,RAS_4Deep
        jmp     RAS_3Deep
RAS_4Deep:
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSlice
        call    RAS_Distribute
        jmp     RAS_Cursor
RAS_3Deep:
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSkip
        jmp     RAS_Cursor
RAS_2Deep?:
        jnb     b.0,RAS_1Deep
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSkip
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSkip
        jmp     RAS_Cursor
RAS_1Deep:
        call    RAS_DrawSkip
        call    RAS_DrawSlice
        call    RAS_Distribute
        call    RAS_DrawSkip
        call    RAS_DrawSkip
        jmp     RAS_Cursor
RAS_ThixelGO
        jmp     RAS_Thixel
RAS_Cursor:
        djnz    r5,RAS_ThixelGO
        mov     dpsel,#0
        mov     b,prt_field_flags
        jnb     b.0,RAS_Across          ; Not Vertical Text
        dec     sp
        dec     sp                      ; Vertical Text
        jmp     Ras_LineCount
RAS_Across:
        pop     dpl
        pop     dph
        mov     a,prt_field_mag
        swap    a
        anl     a,#15
        setB    C                       ; i.e. add one more than #
        addc    a,dpl
        mov     dpl,a
        clr     a
        addc    a,dph
        mov     dph,a
        jmp     RAS_LineCount
RAS_XLoop:
        jmp     RAS_XL
RAS_LineCount:
        djnz    r7,RAS_XLoop
RAS_TrapOut:
        pop     dpsel
        mov     dph,spare2dph
        mov     dpl,spare2dpl
        ret


RAS_Distribute
        mov     dpsel,#0
        mov     b,prt_field_mag
        jb      b.5,RAS_4PixWide
        jmp     RAS_2PixWide
RAS_4PixWide:
        jnb     b.4,RAS_3PixWide

        mov     r1,#prt_fontchrdata
        movx    a,@dptr
        orl     a,@r1
        movx    @dptr,a         ; XXXX XXxx
        inc     dptr
        inc     r1
        mov     a,b
        anl     a,#3
        rr      a
        rr      a
        mov     b,a             ; xx00 0000
        mov     a,@r1           ; YYYY yyyy
        swap    a               ; yyyy YYYY
        push    acc
        anl     a,#15           ; 0000 YYYY
        rl      a
        rl      a
        orl     b,a             ; xxYY YY00
        movx    a,@dptr
        orl     a,b
        movx    @dptr,a
        inc     dptr
        inc     r1
        pop     b
        anl     b,#240          ; yyyy 0000
        mov     a,@r1           ; ZZZZ zzzz
        push    acc
        swap    a               ; zzzz ZZZZ
        anl     a,#12           ; 0000 ZZ00
        orl     b,a             ; yyyy ZZ00
        movx    a,@dptr
        orl     a,b
        movx    @dptr,a         ;
        inc     dptr
        pop     acc             ; ZZZZ zzzz
        rl      a
        rl      a               ; ZZzz zzZZ
        mov     b,a
        movx    a,@dptr
        orl     a,b
        movx    @dptr,a         ; XXXX_xx[xx] xxYY_YY00 yyyy_ZZ00 ZZzz_zz[ZZ]

        mov     a,#29
        add     a,dpl
        mov     dpl,a

        clr     a
        addc    a,dph
        mov     dph,a
        ret

RAS_3PixWide:
        mov     r1,#prt_fontchrdata
DRAW_3: mov     a,@r1           ; XXXz YYYz
        mov     b,a
        anl     a,#14           ; 0000 YYY0
        rl      a               ; 000Y YY00
        anl     b,#0E0h         ; XXX0 0000
        orl     b,a             ; XXXY YY00
        movx    a,@dptr
        orl     a,b
        movx    @dptr,a

        inc     dptr
        inc     r1
        cjne    r1,#prt_fontchrdata+3,DRAW_3

        mov     a,#29
        add     a,dpl
        mov     dpl,a

        clr     a
        addc    a,dph
        mov     dph,a
        ret

RAS_2PixWide:
        mov     r1,#prt_fontchrdata
        mov     a,@r1           ; read 1 quarter of Pixel Line
        inc     r1
        mov     b,a
        anl     a,#022h         ; 00X000x0
        anl     b,#088h         ; Y000y000
        rl      a               ; 0X000x00
        orl     a,b             ; YX00yx00
        mov     b,a
        rl      a
        rl      a               ; 00yx00YX
        orl     a,b             ; YXyx00yx
        anl     a,#240          ; YXyx0000
        push    acc

        mov     a,@r1           ; read another quarter of Pixel Line
        inc     r1
        rr      a               ; ?Y?X?y?x
        mov     b,a
        rr      a               ; x?Y?X?y?
        anl     a,#22h          ; 00Y000y0
        anl     b,#11h          ; 000X000x
        orl     a,b             ; 00YX00yx
        mov     b,a
        rr      a
        rr      a               ; yx00YX00
        orl     a,b             ; yx00YXyx
        anl     a,#15           ; 0000YXyx

        pop     b               ; YXyx0000
        orl     b,a             ; YXyxYXyx
        
        movx    a,@dptr
        orl     a,b
        movx    @dptr,a
        inc     dptr

        IF      TRACE_RASTER
        IF      QTRACE_ON
        mov     a,prt_field_mag
        cjne    a,#11h,RAS_FFnoTrace
        cjne    r7,#8,RAS_FFnoTrace
        push    dph
        push    dpl

        mov     dptr,#qtrack
        movx    a,@dptr
        inc     a
        movx    @dptr,a
        mov     dpl,a
        mov     a,b
        movx    @dptr,a

        pop     dpl
        pop     dph
RAS_FFnoTrace:
        ENDIF
        ENDIF

        anl     b,#3            ; 000000yx
        mov     a,@r1           ; Y_X_y_x_
        inc     r1              ; 
        push    b
        mov     b,a
        anl     a,#88h          ; Y___y___
        anl     b,#22h          ; __X___x_
        rr      a               ; _Y___y__
        orl     a,b             ; _YX__yx_
        rl      a               ; YX__yx__
        mov     b,a
        anl     b,#12           ; ____yx__
        rr      a
        rr      a               ; __YX__yx
        anl     a,#48           ; __YX____
        orl     b,a             ; __YXyx__
        pop     acc             ; 000000yx
        rr      a
        rr      a               ; yx000000
        orl     b,a             ; yxYXyx00
        movx    a,@dptr         ;
        orl     a,b
        movx    @dptr,a

        IF      TRACE_RASTER
        IF      QTRACE_ON
        mov     a,prt_field_mag
        cjne    a,#11h,RAS_FFnoTrace2
        cjne    r7,#8,RAS_FFnoTrace2
        push    dph
        push    dpl

        mov     dptr,#qtrack
        movx    a,@dptr
        inc     a
        movx    @dptr,a
        mov     dpl,a
        mov     a,b
        movx    @dptr,a

        pop     dpl
        pop     dph
RAS_FFnoTrace2:
        ENDIF
        ENDIF

        mov     a,#31
        add     a,dpl
        mov     dpl,a

        clr     a
        addc    a,dph
        mov     dph,a

        ret

;       *****************************************************************
;       *                                                               *
;       *       RAS_DrawSlice                                           *
;       *                                                               *
;       *       Selects the DPTR used for the compiled-in 4*4 Font      *
;       *       Table. Loads a 32-bit Pixel Row from the selected       *
;       *       font bitmap into half of IRAM prt_fontchrdata.          *
;       *                                                               *
;       *       The other half of these eight locations will get used   *
;       *       if we ever take to 64-bit Pixel Rows.                   *
;       *                                                               *
;       *       Lastly advances DPTR by 4 in order to                   *
;       *       advance to the next pixel row.                          *
;       *       To repeat the pixel row, don't call this                *
;       *       routine again, because the data is already in IRAM.     *
;       *                                                               *
;       *****************************************************************

RAS_DrawSlice:
        mov     dpsel,#XFONTP
        mov     r1,#prt_fontchrdata     ; 
        mov     a,prt_field_flags
        mov     b,#0                    ; do not negate
        jnb     acc.1,RAS_DrawSliceL
        mov     b,#-1                   ; negate
RAS_DrawSliceL:
        mov     a,r1
        anl     a,#3
        movc    a,@a+dptr
        xrl     a,b                     ; negate if inverse
        mov     @r1,a
        inc     r1
        cjne    r1,#prt_fontchrdata+4,RAS_DrawSliceL
              
;       *****************************************************************
;       *                                                               *
;       *       RAS_DrawSKIP                                            *
;       *                                                               *
;       *       Selects the DPTR used for the compiled-in 4*4 Font      *
;       *       Table, and skips a Pixel Row in code memory.            *
;       *                                                               *
;       *       Used when vertical magnification is less than *4        *
;       *                                                               *
;       *****************************************************************

RAS_DrawSkip:
        mov     dpsel,#XFONTP
        mov     a,#4                    ; increment external pointer by 4 
        add     a,dpl                   
        mov     dpl,a                   
        ret

        End
