echo this should be MSW 32-Bit

rem	set	CL32=c:\Program Files\Microsoft Visual Studio 10.0\VC\bin\x86_amd64\cl.exe
rem	or similar

CL32  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c
CL32  /J /DMS /DMSW /Fe..\masmz masm.c
CL32  /J /DMS /DMSW /Fe..\imx imx.c
CL32  /J /DMS /DMSW /Fe..\mmx mmx.c
CL32  /J /DMS /DMSW /Fe..\symbol symbol.c
copy ..\masmx.exe ..\masmx.7r3\hosts\win32
copy ..\masmz.exe ..\masmx.7r3\hosts\win32
rem	copy ..\masmx.7r3\hosts\win32\imx.exe ..
rem	copy ..\masmx.7r3\hosts\win32\mmx.exe ..
copy ..\imx.exe ..\masmx.7r3\hosts\win32
copy ..\mmx.exe ..\masmx.7r3\hosts\win32
copy ..\symbol.exe ..\masmx.7r3\hosts\win32

@echo off
echo		+
echo		alltests.bat calls utility seeif to check test results
echo		if you don't have seeif, read web page http://TimMilesCox.github.io/util
echo		download utilities from there and add them to your path
echo		+
echo		cd ..\test.msm and run .\alltests.bat
echo		+
@echo on

