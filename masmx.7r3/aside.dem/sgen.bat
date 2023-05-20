del /Q 	*.txo
..\masmx soso	%1	-y
..\masmx factor %1	-y
..\masmx zactor	zactor %1	-y
..\masmx map1	%1	-y
..\masmx map2   %1	-y
..\masmx map3   %1	-y
..\masmx map4   %1	-yj
..\masmx map5   %1	-y
..\masmx gsoso gsoso %1 -y
..\masmx gfactor gfactor %1 -y
..\masmx gzactor gzactor %1 -y
..\masmx map6   %1	-y
..\masmx map7   %1	-y
..\masmx map8   %1	-y
..\masmx map9   %1	-y
..\masmx map10  %1	-y
copy *.txo ..\test.o3
rem fc /L /W ..\map.dem\image1.txo image1.txo
rem fc /L /W ..\map.dem\image2.txo image2.txo
rem fc /L /W ..\map.dem\image3.txo image3.txo
rem fc /L /W ..\map.dem\rel4.txo rel4.txo
rem fc /L /W ..\map.dem\image5.txo image5.txo
rem fc /L /W ..\map.dem\image6.txo image6.txo
rem fc /L /W ..\map.dem\image7.txo image7.txo
rem fc /L /W ..\map.dem\image8.txo image8.txo
rem fc /L /W ..\map.dem\image9.txo image9.txo
rem fc /L /W ..\map.dem\image10.txo image10.txo

