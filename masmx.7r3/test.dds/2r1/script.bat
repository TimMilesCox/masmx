del abs\*.*
..\..\masmz master abs\master
..\..\imx abs\master.txo abs\master.hex
..\..\masmx master abs\aside
..\..\imx abs\aside.txo abs\aside.hex
fc /L /W 2r1.hex abs\master.hex
fc /L /W abs\master.hex abs\aside.hex

