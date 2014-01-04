del *.txo
..\masmx soso soso		%1	-y
..\masmx factor factor		%1	-y
..\masmx wolverine wolverine	%1	-y
..\masmx submarine submarine	%1	-y
..\masmx hard hard		%1	-y
..\masmx zactor zactor		%1	-y
..\masmx centre2.map ce5	%1	%2	-y	
..\masmx part2.map o  		%1	%2	-y
..\masmx part33.map z4 		%1	%2	-y
..\masmx z5.map z5  		%1	%2	-y
copy	z4.txo	..\test.o3
copy	z5.txo	..\test.o3
fc /L /W ..\result.txo\z4.txo z4.txo
fc /L /W ..\result.txo\z5left.txo z5.txo

