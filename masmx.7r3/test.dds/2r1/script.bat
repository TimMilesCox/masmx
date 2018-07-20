del /Q  abs\*.*
..\..\masmz master abs\master
..\..\imx abs\master.txo abs\master.hex
..\..\masmx master abs\aside
..\..\imx abs\aside.txo abs\aside.hex
seeif -as 2r1.hex abs\master.hex
seeif -as abs\master.hex abs\aside.hex

