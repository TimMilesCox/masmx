pushd ..\smaragd.ppc
del /Q  .\*.txo
del /Q  smaragd.ppc
..\masmx yield -w
..\masmx idle -w
..\masmx smaragd.map -w
..\mmx smaragd.txo smaragd.ppc
copy smaragd.ppc ..\test.o3
popd
