@echo off
call	..\w32_dos.bat\script.bat
echo	start diff test.o3
seeif -a	..\result.txo ..\test.o3
echo	end diff test.o3
pushd	..\test.dds\2r1
call	.\script.bat
cd	..\1r45p
call	.\script.bat
popd
call	..\w32_dos.bat\zscript.bat
echo	start diff test.zo3
seeif -a	..\result.zo3 ..\test.zo3
echo	end diff test.zo3

@echo on
