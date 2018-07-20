echo this should be MSW 32-Bit

cl  /J /DMS /DMSW /DSUPERSET /Fe..\masmx masm.c
cl  /J /DMS /DMSW /Fe..\masmz masm.c
copy ..\masmx.exe ..\masmx.7r3\hosts\win32
copy ..\masmz.exe ..\masmx.7r3\hosts\win32
copy ..\masmx.7r3\hosts\win32\imx.exe ..
copy ..\masmx.7r3\hosts\win32\mmx.exe ..

@echo off
echo		+
echo		alltests.bat calls utility seeif to check test results
echo		if you don't have seeif, read web page http://TimMilesCox.github.io/util
echo		download utilities from there and add them to your path
echo		+
echo		cd ..\test.msm and run .\alltests.bat
echo		+
@echo on

