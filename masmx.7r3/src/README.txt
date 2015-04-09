        gcc -m32 -funsigned-char -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -o masmz masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -o masmz masm.c
        cl  /J /DMS /DMSW /Fe..\masmz masm.c
        cl  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c
        bcc -K -N -mc -Z -DMS -DDOS -DSUPERSET -emasmx.exe -w- masm.c
        bcc -K -N -mc -Z -DMS -DDOS -emasmz.exe -w- masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUSE -DSUPERSET -o masmx masm.c
        gcc -m32 -funsigned-char -DINTEL -DSUSE -o masmz masm.c

