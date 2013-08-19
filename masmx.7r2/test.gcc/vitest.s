	.file	"vitest.c"
	.section	".data"
	.align 2
	.type	_one, @object
	.size	_one, 4
_one:
	.long	1
	.globl _two
	.section	.sdata,"aw",@progbits
	.align 2
	.type	_two, @object
	.size	_two, 4
_two:
	.long	2
	.section	".data"
	.align 2
	.type	_one.1538, @object
	.size	_one.1538, 4
_one.1538:
	.long	1
	.section	".text"
	.align 2
	.globl _add
	.type	_add, @function
_add:
	stwu 1,-48(1)
	mflr 0
	stw 31,44(1)
	stw 0,52(1)
	mr 31,1
	stw 3,24(31)
	li 0,2
	stw 0,8(31)
	lwz 9,8(31)
	lwz 0,24(31)
	add 0,9,0
	stw 0,8(31)
	lis 9,_one.1538@ha
	lwz 9,_one.1538@l(9)
	lwz 0,8(31)
	add 0,0,9
	stw 0,8(31)
	lwz 3,8(31)
	crxor 6,6,6
	bl _adagain_more
	mr 0,3
	stw 0,8(31)
	lwz 3,8(31)
	crxor 6,6,6
	bl _primary_one
	lwz 3,8(31)
	crxor 6,6,6
	bl _primary_two
	lwz 0,8(31)
	mr 3,0
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	_add, .-_add
	.section	".data"
	.align 2
	.type	_one.1550, @object
	.size	_one.1550, 4
_one.1550:
	.long	1
	.section	".text"
	.align 2
	.globl _adagain
	.type	_adagain, @function
_adagain:
	stwu 1,-48(1)
	mflr 0
	stw 31,44(1)
	stw 0,52(1)
	mr 31,1
	stw 3,24(31)
	li 0,2
	stw 0,8(31)
	lwz 9,8(31)
	lwz 0,24(31)
	add 0,9,0
	stw 0,8(31)
	lis 9,_one.1550@ha
	lwz 9,_one.1550@l(9)
	lwz 0,8(31)
	add 0,0,9
	stw 0,8(31)
	lwz 3,8(31)
	crxor 6,6,6
	bl _add_more
	mr 0,3
	stw 0,8(31)
	lwz 3,8(31)
	crxor 6,6,6
	bl _primary_three
	lwz 3,8(31)
	crxor 6,6,6
	bl _primary_four
	lwz 0,8(31)
	mr 3,0
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	_adagain, .-_adagain
	.ident	"GCC: (GNU) 4.2.1"
