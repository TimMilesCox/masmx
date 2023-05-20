	.file	"idle.c"
	.section	".data"
	.align 2
	.type	x, @object
	.size	x, 4
x:
	.long	99
	.section	".text"
	.align 2
	.globl idle
	.type	idle, @function
idle:
	stwu 1,-16(1)
	stw 31,12(1)
	mr 31,1
.L2:
	lis 9,x@ha
	lwz 0,x@l(9)
	cmpwi 7,0,0
	beq 7,.L3
	lis 9,x@ha
	lwz 9,x@l(9)
	addi 0,9,-1
	lis 9,x@ha
	stw 0,x@l(9)
.L3:
	sc
	b .L2
	.size	idle, .-idle
	.ident	"GCC: (GNU) 4.2.1"
