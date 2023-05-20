echo this should be MSW 64-Bit

rem	set CL64=c:\Program Files (x86)\Microsoft visual Studio 10.0\VC\bin\amd64\cl.exe
rem	or similar

CL64  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c
CL64  /J /DMS /DMSW /Fe..\masmz masm.c
CL64  /J /DMS /DMSW /Fe..\imx imx.c
CL64  /J /DMS /DMSW /Fe..\mmx mmx.c
CL64  /J /DMS /DMSW /Fe..\symbol symbol.c
copy ..\masmx.exe ..\masmx.7r3\hosts\win64
copy ..\masmz.exe ..\masmx.7r3\hosts\win64
rem	copy ..\masmx.7r3\hosts\win64\imx.exe ..
rem	copy ..\masmx.7r3\hosts\win64\mmx.exe ..
copy ..\imx.exe ..\masmx.7r3\hosts\win64
copy ..\mmx.exe ..\masmx.7r3\hosts\win64
copy ..\symbol.exe ..\masmx.7r3\hosts\win64

@echo off
echo		+
echo		alltests.bat calls utility seeif to check test results
echo		if you don't have seeif, read web page http://TimMilesCox.github.io/util
echo		download utilities from there and add them to your path
echo		+
echo		cd ..\test.msm and run .\alltests.bat
echo		+
@echo on

