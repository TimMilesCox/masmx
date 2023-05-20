	.file	"wolverine.c"
	.section	".text"
	.align 2
	.type	jimp, @function
jimp:
	stwu 1,-16(1)
	stw 31,12(1)
	mr 31,1
	li 0,1
	mr 3,0
	lwz 11,0(1)
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	jimp, .-jimp
	.align 2
	.globl wolverine
	.type	wolverine, @function
wolverine:
	stwu 1,-16(1)
	mflr 0
	stw 31,12(1)
	stw 0,20(1)
	mr 31,1
	bl adjustment
	bl soso
	bl overcoat
	bl tractor
	bl jimp
	bl jomp
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	wolverine, .-wolverine
	.align 2
	.type	jomp, @function
jomp:
	stwu 1,-16(1)
	stw 31,12(1)
	mr 31,1
	li 0,3
	mr 3,0
	lwz 11,0(1)
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	jomp, .-jomp
	.ident	"GCC: (GNU) 4.2.1"
