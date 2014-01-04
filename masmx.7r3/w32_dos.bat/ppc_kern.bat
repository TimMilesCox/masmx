pushd ..\smaragd.ppc
del .\*.txo
..\masmx yield -w
..\masmx idle -w
..\masmx smaragd.map -w
..\mmx smaragd.txo smaragd.ppc
copy smaragd.ppc ..\test.o3
popd
