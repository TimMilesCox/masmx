	.file	"cricket.c"
	.section	".data"
	.align 2
	.type	_nine, @object
	.size	_nine, 4
_nine:
	.long	9
	.section	".text"
	.align 2
	.type	_subroutine, @function
_subroutine:
	stwu 1,-16(1)
	stw 31,12(1)
	mr 31,1
	lis 9,_nine@ha
	lwz 0,_nine@l(9)
	mr 3,0
	lwz 11,0(1)
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	_subroutine, .-_subroutine
	.align 2
	.globl _second
	.type	_second, @function
_second:
	stwu 1,-16(1)
	mflr 0
	stw 31,12(1)
	stw 0,20(1)
	mr 31,1
	bl _subroutine
	mr 0,3
	mr 3,0
	lwz 11,0(1)
	lwz 0,4(11)
	mtlr 0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	_second, .-_second
	.comm	_unique_two,4,4
	.ident	"GCC: (GNU) 4.2.1"
