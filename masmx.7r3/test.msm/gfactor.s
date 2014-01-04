	.file	"factor.c"
	.globl factor
	.section	.sdata,"aw",@progbits
	.align 2
	.type	factor, @object
	.size	factor, 4
factor:
	.int	88
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
	enter64	32
	return64,__immediate	33
	.size	adjustment, .-adjustment
	.align 2
	.globl overcoat
	.type	overcoat, @function
overcoat:
	enter64	32
	ld	9, __literal(	__upper48	acu@ha)
	ld	0, acu@l(9)
	mr	3,0
	bl	soso
	leave64
	.size	overcoat, .-overcoat
	.ident	"GCC: (GNU) 4.2.1"
