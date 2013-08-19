	.file	"idle.c"
	.data
	.align	2
	.type	x, @object
	.size	x, 4
x:
	.long	99
	.text
	.align	2
	.globl	idle
	.type	idle, @function
idle:
	link.w %a6,#0
	nop
.L2:
	tst.l x
	jbeq .L5
	subq.l #1,x
.L5:
#APP
	trap #0
#NO_APP
	jbra .L2
	nop
	.size	idle, .-idle
	.ident	"GCC: (GNU) 3.3"
