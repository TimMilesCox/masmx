QTRACE_ON       EQU     0
QTRACE  MACRO
        IF      QTRACE_ON
        push    dph
        push    dpl
        mov     dptr,#qtrack+!1
        movx    @dptr,a
        push    acc
        mov     a,b
        inc     dptr
        movx    @dptr,a
        pop     acc
        pop     dpl
        pop     dph
        ENDIF
        MACEND

XQTRACE MACRO
        IF      QTRACE_ON
        LMACRO  LIST
        push    dph
        push    dpl
        push    acc
        push    b

        mov     dptr,#!2
        movx    a,@dptr
        inc     dptr
        mov     b,a
        movx    a,@dptr
        push    acc
        mov     a,b
        mov     dptr,#qtrack+!1
        movx    @dptr,a
        pop     acc
        inc     dptr
        movx    @dptr,a

        pop     b
        pop     acc
        pop     dpl
        pop     dph
        ENDIF
        MACEND
