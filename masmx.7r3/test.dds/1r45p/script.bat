del /Q  abs\*
..\..\masmz dt.asm abs\dt
..\..\imx abs\dt.txo abs\dt.hex
..\..\masmx dt.asm abs\aside
..\..\imx abs\aside.txo abs\aside.hex
seeif -as 1r45pq.hex abs\dt.hex
seeif -as abs\dt.hex abs\aside.hex

