	.file	"soso.c"
	.globl clanjamfrie
	.section	.sdata,"aw",@progbits
	.align 2
	.type	clanjamfrie, @object
	.size	clanjamfrie, 4
clanjamfrie:
	.int	55
	.section	".data"
	.align 2
	.type	yasimi, @object
	.size	yasimi, 4
yasimi:
	.int	99
	.align 2
	.type	cu, @object
	.size	cu, 8
cu:
	.quad	startfromhere
	.lcomm	clearly_so.1543,8,8
	.type	clearly_so.1543, @object
	.align 2
	.type	separate_static_item.1542, @object
	.size	separate_static_item.1542, 4
separate_static_item.1542:
	.int	-1515870811
	.section	".text"
	.align 2
	.globl soso
	.type	soso, @function

x	$equf	16, 31	# dynamic integer in the stack frame

soso:
	stdu	1, -64(1)
	mflr	0
	std   31, 56(1)	# save r31 just below the previous stack frame 
	std   0, 72(1)	# save LR value inside the previous stack frame
	mr    31, 1	# use a frame pointer in case the stack is pushed
	std	30, 48(31)	# save the literals base register

	bl	__haulup
	+	.absolute(__base36):d
__haulup
	mflr	30	# .literal segment 36 holds __literal table
			# which is accessed base_displacement with r30
	
	ld	30, 0(30) # LR was pointing to the pointer

	ld	9, __literal(	__upper48	startfromhere@ha)
	lwa	9, startfromhere@l(9)
	stw	9, x

	addi	0, 9, 1

	ld	9, __literal(	__upper48	startfromhere@ha)
	stw	0, startfromhere@l(9)

	ld	9, __literal(	__upper48	factor@ha)
	lwa	9, factor@l(9)
	lwa	0, x

	mullw	0, 0, 9
	stw	0, x

	ld	9, __literal(	__upper48	cu@ha)
	ld	0, cu@l(9)
	mr	3, 0

	bl	adjustment
	mr	9, 3
	lwz	0, x

	add	0, 0, 9
	stw	0, x

	ld	9, __literal(	__upper48	yasimi@ha)
	lwa	9, yasimi@l(9)

	lwa	0, x
	subf	0, 9, 0

#	stw	0, x
#	lwz	0, x	# the compiler had these lines in

	mr	3, 0	# this ABI has r3 for results

#	the geography of the stack frame is
#	LOW ADDRESS REPRESENTED HERE    ______________________________
#	STACK TOP R31 points to ------> |   saved SP (r1) 8 bytes    |
#					|............................|
#				+ 8	| next LR save area 8 bytes  |
#					|............................|
#				+ 16	| var x 4 bytes|/////////////|
#					|..............|.............|



#				+ 48	|     saved r30 8 bytes      |
#					|............................|
#				+ 56	|     saved r31 8 bytes      |
#					|____________________________|
#	PREVIOUS STACK FRAME ---------> | previous saved r1 8 bytes  |
#					|............................|
#				+ 72	|  actual saved LR 8 bytes   |



	ld	11, 0(1)	# there is complete confidence r1 unchanged
	ld	0, 8(11)	# pick up LR
	mtlr	0
	ld	30, 48(31)
	ld	31, -8(11)

	mr	1,11

	blr

	.size	soso, .-soso
	.lcomm	startfromhere,4,4
	.type	startfromhere, @object
	.ident	"GCC: (GNU) 4.2.1"
