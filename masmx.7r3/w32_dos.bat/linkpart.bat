pushd ..\test.map
call	.\mverify	-wy
copy z5.txo ..\test.o3\z5left.txo
call	.\zferify	-w	-j
copy z5.txo ..\test.o3\z5right.txo
rem cd ..\test3.map
rem call	.\sure34	-wy
rem copy p44.txo ..\test.o3\p44left.txo
rem call	.\zure34	-w	-j
rem copy p44.txo ..\test.o3\p44right.txo
cd ..\test.gcc
call	.\dothis	-wy
copy outerm.txo ..\test.o3
cd ..\aside.dem
call	.\sgen		-wy
copy image*.txo ..\test.o3
copy rel4.txo ..\test.o3
..\masmx intune intune -wy
..\masmx detune detune -wy
copy intune.txo ..\test.o3
copy detune.txo ..\test.o3
cd ..\trabble
call	.\trabble	-w
popd
call	.\bojo		-w
rem	copy agito2.txo ..\test.o3

