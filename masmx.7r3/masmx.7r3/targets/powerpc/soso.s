	.file	"soso.c"
	.globl clanjamfrie
	.section	.sdata,"aw",@progbits
	.align 2
	.type	clanjamfrie, @object
	.size	clanjamfrie, 4
clanjamfrie:
	.long	55
	.section	".data"
	.align 2
	.type	yasimi, @object
	.size	yasimi, 4
yasimi:
	.long	99
	.align 2
	.type	cu, @object
	.size	cu, 4
cu:
	.long	startfromhere
	.lcomm	clearly_so.1543,8,8
	.type	clearly_so.1543, @object
	.align 2
	.type	separate_static_item.1542, @object
	.size	separate_static_item.1542, 4
separate_static_item.1542:
	.long	-1515870811
	.section	".text"
	.align 2
	.globl soso
	.type	soso, @function
soso:
	stwu 1,-32(1)
	mflr 0
	stw 31,28(1)
	stw 0,36(1)
	mr 31,1
	lis 9,startfromhere@ha
	lwz 9,startfromhere@l(9)
	stw 9,8(31)
	addi 0,9,1
	lis 9,startfromhere@ha
	stw 0,startfromhere@l(9)
	lis 9,factor@ha
	lwz 9,factor@l(9)
	lwz 0,8(31)
	mullw 0,0,9
	stw 0,8(31)
	lis 9,cu@ha
	lwz 0,cu@l(9)
	mr 3,0
	bl adjustment
	mr 9,3
	lwz 0,8(31)
	add 0,0,9
	stw 0,8(31)
	lis 9,yasimi@ha
	lwz 9,yasimi@l(9)
	lwz 0,8(31)
	subf 0,9,0
	stw 0,8(31)
	lwz 0,8(31)
	mr 3,0
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	soso, .-soso
	.lcomm	startfromhere,4,4
	.type	startfromhere, @object
	.ident	"GCC: (GNU) 4.2.1"
