        $list           0
        $include        "ppc_64.def"
        $include        "absomap.def"
        $list           2
	$plist		5
	$include,"$binary"	"../result.txo/scale4.txo"
$(.data::*0x00444400000e0000)
	$include		"carryon.msm"
	$store		scale5
