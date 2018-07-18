del /Q  *.txo
..\masmz soso soso		%1
..\masmz factor factor 	%1
..\masmz wolverine wolverine	%1
..\masmz submarine submarine	%1
..\masmz hard hard		%1
..\masmz zactor zactor		%1
..\masmz centre2.map ce5 	%1	%2
..\masmz part2.map o 		%1	%2
..\masmz part33.map z4		%1	%2
..\masmz z5.map z5		%1	%2
copy	z4.txo	..\test.o3\z4right.txo
copy	z5.txo	..\test.o3\z5right.txo
fc /L /W ..\result.txo\z4right.txo z4.txo
fc /L /W ..\result.txo\z5right.txo z5.txo

