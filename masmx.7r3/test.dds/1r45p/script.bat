del abs\*
..\..\masmz dt.asm abs\dt
..\..\imx abs\dt.txo abs\dt.hex
..\..\masmx dt.asm abs\aside
..\..\imx abs\aside.txo abs\aside.hex
fc /L /W 1r45pq.hex abs\dt.hex
fc /L /W abs\dt.hex abs\aside.hex

