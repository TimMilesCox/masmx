pushd ..\smaragd.68k
del /Q  .\*.txo
..\masmx coldfire -wy
..\masmx coldfir@ -wy
fc /w yield.txo yield@.txo
copy yield.txo ..\test.o3
copy yield@.txo ..\test.o3
popd
