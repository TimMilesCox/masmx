	.file	"factor.c"
	.globl factor
	.section	.sdata,"aw",@progbits
	.align 2
	.type	factor, @object
	.size	factor, 4
factor:
	.long	88
	.section	".data"
	.align 2
	.type	acu, @object
	.size	acu, 4
acu:
	.long	factor
	.section	".text"
	.align 2
	.globl adjustment
	.type	adjustment, @function
adjustment:
	stwu 1,-16(1)
	stw 31,12(1)
	mr 31,1
	li 0,33
	mr 3,0
	lwz 11,0(1)
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	adjustment, .-adjustment
	.align 2
	.globl overcoat
	.type	overcoat, @function
overcoat:
	stwu 1,-16(1)
	mflr 0
	stw 31,12(1)
	stw 0,20(1)
	mr 31,1
	lis 9,acu@ha
	lwz 0,acu@l(9)
	mr 3,0
	bl soso
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	overcoat, .-overcoat
	.ident	"GCC: (GNU) 4.2.1"
