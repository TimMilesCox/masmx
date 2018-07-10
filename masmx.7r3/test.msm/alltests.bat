call	..\w32_dos.bat\script.bat
seeif -a	..\result.txo ..\test.o3
pushd	..\test.dds\2r1
call	.\script.bat
cd	..\1r45p
call	.\script.bat
popd
call	..\w32_dos.bat\zscript.bat
seeif -a	..\result.zo3 ..\test.zo3

