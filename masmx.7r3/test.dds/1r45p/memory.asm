;******************************************************************************
;
; File     : MEMORY.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the memory manipulation routines
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;***********
; Prototypes
;***********
;void MEM_SetSource (DPTR)
;void MEM_SetDest (DPTR)
;void MEM_CopyCODEtoXRAM (R6 lenhigh, R7 lenlow)
;void MEM_CopyCODEtoXRAMsmall (R7 len)
;void MEM_CopyXRAMtoXRAM (R6 lenhigh, R7 lenlow)
;void MEM_CopyXRAMtoXRAMsmall (R7 len)
;void MEM_CopyXRAMtoIRAM (DPTR xramaddr, R0 iramaddr, R7 len)
;void MEM_CopyIRAMtoXRAM (DPTR xramaddr, R0 iramaddr, R7 len)
;ACC MEM_CopyEEtoXRAM (R1 slave, F0 i2cline, F1 i2cmode, R6 lenhigh, R7 lenlow)
;ACC MEM_CopyEEtoXRAMsmall (R1 slave, F0 i2cline, F1 i2cmode, R7 len)
;ACC MEM_CopyXRAMtoEE (R1 slave, F0 i2cline, F1 i2cmode, R6 lenhigh, R7 lenlow)
;ACC MEM_CopyXRAMtoEEsmall (R1 slave, F0 i2cline, F1 i2cmode, R7 len)
;void MEM_FillXRAMsmall (DPTR xramaddr, ACC pattern, R6 lenhigh, R7 lenlow)
;DPTR AddABtoDPTR (DPTR addr, B highoffset, ACC lowoffset)
;DPTR AddAtoDPTR (DPTR addr, ACC offset)
;void MEM_MulipleXRAMCopy (DPTR0 tableaddr, R5 entries)

;**********
; Variables
;**********

; None

;******************************************************************************
;
; Function:	MEM_SetSource
; Input:	DPTR = source address for transfer
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the source address (any type of memory) for the following transfer.
;
;******************************************************************************

MEM_SetSource:
	MOV	srcDPH,DPH
	MOV	srcDPL,DPL
	RET

;******************************************************************************
;
; Function:	MEM_SetDest
; Input:	DPTR = dest address for transfer
; Output:	None
; Preserved:	All
; Destroyed:	None
; Description:
;   Sets the dest address (any type of memory, except CODE) for the following
;   transfer.
;
;******************************************************************************

MEM_SetDest:
	MOV	destDPH,DPH
	MOV	destDPL,DPL
	RET

;******************************************************************************
;
; Function:	MEM_CopyCODEtoXRAM
;           and MEM_CopyCODEtoXRAMsmall (256 bytes or less)
; Input:	R6:R7 = number of bytes to copy (R6=MSB, R7=LSB)
;               no need to set R6 if a SMALL transfer
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Copies the specified number of bytes from CODE memory to XRAM, using the
;   previously set up addresses.
;
;******************************************************************************

MEM_CopyCODEtoXRAMsmall:
	MOV	R6,#0
MEM_CopyCODEtoXRAM:
	MOV	A,R7
	JZ	MEM_CCXloop
	INC	R6
MEM_CCXloop:
	MOV	DPH,srcDPH
	MOV	DPL,srcDPL
	CLR	A
	MOVC	A,@A+DPTR
	INC	DPTR
	MOV	srcDPH,DPH
	MOV	srcDPL,DPL
	MOV	DPH,destDPH
	MOV	DPL,destDPL
	MOVX	@DPTR,A
	INC	DPTR
	MOV	destDPH,DPH
	MOV	destDPL,DPL
	DJNZ	R7,MEM_CCXloop
	DJNZ	R6,MEM_CCXloop
	RET

;******************************************************************************
;
; Function:	MEM_CopyXRAMtoXRAM
;           and MEM_CopyXRAMtoXRAMsmall (256 bytes or less)
; Input:	R6:R7 = number of bytes to copy (R6=MSB, R7=LSB)
;               no need to set R6 if a SMALL transfer
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   Copies the specified number of bytes from XRAM to XRAM, using the
;   previously set up addresses.
;
;******************************************************************************

MEM_CopyXRAMtoXRAMsmall:
	MOV	R6,#0
MEM_CopyXRAMtoXRAM:
	MOV	A,R7
	JZ	MEM_CXXloop
	INC	R6
MEM_CXXloop:
	MOV	DPH,srcDPH
	MOV	DPL,srcDPL
	MOVX	A,@DPTR
	INC	DPTR
	MOV	srcDPH,DPH
	MOV	srcDPL,DPL
	MOV	DPH,destDPH
	MOV	DPL,destDPL
	MOVX	@DPTR,A
	INC	DPTR
	MOV	destDPH,DPH
	MOV	destDPL,DPL
	DJNZ	R7,MEM_CXXloop
	DJNZ	R6,MEM_CXXloop
	RET

;******************************************************************************
;
; Function:	MEM_CopyXRAMtoIRAM
; Input:	DPTR = address in XRAM of 1st byte to copy
;               R0 = address in IRAM
;               R7 = num of bytes to copy
; Output:	DPTR = address in XRAM of the byte after the last byte copied
;               R0 = address in IRAM of the byte after the last byte copied to
;               R7 = 0
; Preserved:	R1-R6,B
; Destroyed:	A
; Description:
;   Copies the specified number of bytes from the specified address in XRAM to
;   the specified address in IRAM.
;
;******************************************************************************


MEM_CopyXRAMtoIRAM:
MEM_CXIloop:
	MOVX	A,@DPTR
	INC	DPTR
	MOV	@R0,A
	INC	R0
	DJNZ	R7,MEM_CXIloop
	RET

;******************************************************************************
;
; Function:	MEM_CopyIRAMtoXRAM
; Input:	DPTR = address in XRAM to copy to
;               R0 = address in IRAM of 1st byte to copy
;               R7 = num of bytes to copy
; Output:	DPTR = address in XRAM of the byte after the last byte copied to
;               R0 = address in IRAM of the byte after the last byte copied
;               R7 = 0
; Preserved:	R1-R6,B
; Destroyed:	A
; Description:
;   Copies the specified number of bytes from the specified address in IRAM to
;   the specified address in XRAM.
;
;******************************************************************************

MEM_CopyIRAMtoXRAM:
MEM_CIXloop:
	MOV	A,@R0
	INC	R0
	MOVX	@DPTR,A
	INC	DPTR
	DJNZ	R7,MEM_CIXloop
	RET

;******************************************************************************
;
; Function:	MEM_CopyEEtoXRAM
;	     and MEM_CopyEEtoXRAMsmall (256 bytes or less)
; Input:	R1 = EE slave device/page number
;		F0 = I2C line to use (0=main, 1=ext)
;		F1 = I2C addressing to use (0=13bit, 1=8bit)
;		srcDPTR = EE internal address to start copying from
;		destDPTR = XRAM address to copy to
;		R6:R7 = number of bytes to copy (R6 = MSB, R7 = LSB)
;		no need to set R6 if a SMALL transfer
; Output:	If Success, A = 0
;		  destDPTR=1st unused byte of dest
;		  srcDPTR=1st unused byte of source
;		If Fail, A <> 0
;		  destDPTR = 1st unused byte of dest
;		  srcDPTR = byte of source which failed to be READ
; Preserved:	?
; Destroyed:	R3
; Description:
;   etc
;
;******************************************************************************

MEM_CopyEEtoXRAMsmall:
	MOV	R6,#0
MEM_CopyEEtoXRAM:
	MOV	A,R7
	JZ	MEM_CEXloop
	INC	R6
MEM_CEXloop:
	MOV	DPH,srcDPH
	MOV	DPL,srcDPL
	CALL	I2C_Read
	JNZ	MEM_CEXfail
	INC	DPTR
	MOV	srcDPH,DPH
	MOV	srcDPL,DPL
	MOV	DPH,destDPH
	MOV	DPL,destDPL
	MOV	A,B
	MOVX	@DPTR,A
	INC	DPTR
	MOV	destDPH,DPH
	MOV	destDPL,DPL
	DJNZ	R7,MEM_CEXloop
	DJNZ	R6,MEM_CEXloop
	CLR	A
MEM_CEXfail:
	RET

;******************************************************************************
;
; Function:	MEM_CopyXRAMtoEE
;	     and MEM_CopyXRAMtoEEsmall (256 bytes or less)
; Input:	R1 = EE slave device/page number
;		F0 = I2C line to use (0=main, 1=ext)
;		F1 = I2C addressing to use (0=13bit, 1=8bit)
;		srcDPTR = XRAM address to start copying from
;		destDPTR = EE interal address to start copying to
;		R6:R7 = number of bytes to copy (R6 = MSB, R7 = LSB)
;		no need to set R6 if a SMALL transfer
; Output:	If Success, A = 0
;		  srcDPTR=1st unused byte of source
;		  destDPTR=1st unused byte of dest
;		If Fail, A <> 0
;		  srcDPTR = 1st uncopied byte of source
;		  destDPTR = byte of dest which failed to WRITE
; Preserved:	?
; Destroyed:	R3
; Description:
;   etc
;
;******************************************************************************

MEM_CopyXRAMtoEEsmall:
	MOV	R6,#0
MEM_CopyXRAMtoEE:
	MOV	A,R7
	JZ	MEM_CXEloop
	INC	R6
MEM_CXEloop:
	MOV	DPH,srcDPH
	MOV	DPL,srcDPL
	MOVX	A,@DPTR
	INC	DPTR
	MOV	srcDPH,DPH
	MOV	srcDPL,DPL
	MOV	DPH,destDPH
	MOV	DPL,destDPL
	MOV	B,A
	CALL	I2C_Write
	JNZ	MEM_CXEfail
	INC	DPTR
	MOV	destDPH,DPH
	MOV	destDPL,DPL
	DJNZ	R7,MEM_CXEloop
	DJNZ	R6,MEM_CXEloop
	CLR	A
MEM_CXEfail:
	RET

;******************************************************************************
;
; Function:	MEM_CompareXRAM
; Input:	DPTR0 = address in XRAM of first buffer
;               DPTR1 = address in XRAM of second buffer
;               R6/R7 = number of bytes to compare
; Output:	C = 1 if identical, otherwise C=0
; Preserved:	?
; Destroyed:	?
; Description:
;   Compares two XRAM buffers for identical match
;
;******************************************************************************

MEM_CompareXRAMsmall:
	MOV	R6,#0
MEM_CompareXRAM:
	MOV	A,R7
	JZ	MEM_CXloop
	INC	R6
MEM_CXloop:
	MOV	DPSEL,#1
	MOVX	A,@DPTR
	INC	DPTR
	MOV	B,A
	MOV	DPSEL,#0
	MOVX	A,@DPTR
	INC	DPTR
	CJNE	A,B,MEM_CXfail
	DJNZ	R7,MEM_CXloop
	DJNZ	R6,MEM_CXloop
	SETB	C
	RET
MEM_CXfail:
	CLR	C
	RET

;******************************************************************************
;
; Function:	MEM_FillXRAM
; Input:	DPTR = address in XRAM to copy to
;               R6/R7 = number of bytes to fill
;               A = pattern
; Output:	DPTR = address in XRAM of the byte after the last byte copied to
; Preserved:	?
; Destroyed:	?
; Description:
;   Fills the specified number of bytes from the specified address in XRAM with
;   the specified pattern in A.
;
;******************************************************************************

MEM_FillXRAMsmall:
	MOV	R6,#0
MEM_FillXRAM:
	PUSHACC
	MOV	A,R7
	JZ	MEM_FXgo
	INC	R6
MEM_FXgo:
        POP	ACC
MEM_FXloop:
	MOVX	@DPTR,A
	INC	DPTR
	DJNZ	R7,MEM_FXloop
	DJNZ	R6,MEM_FXloop
	RET

;******************************************************************************
;
; Function:	AddABtoDPTR
; Input:	DPTR = address (any address space)
;               B:A = 16 bit offset to add to address (B=high,A=low)
; Output:	DPTR = address with offset added
; Preserved:	All except C
; Destroyed:	C
; Description:
;   Adds the 16bit offset stored in B:A to the address in DPTR.
;
;******************************************************************************

AddABtoDPTR:	; adds the 16bit number B:A to DPTR
	ADD	A,DPL
	MOV	DPL,A
	MOV	A,B
	ADDC	A,DPH
	MOV	DPH,A
	RET

;******************************************************************************
;
; Function:	AddAtoDPTR
; Input:	DPTR = address (any address space)
;               A = 8 bit offset to add to address
; Output:	DPTR = address with offset added
; Preserved:	All except C
; Destroyed:	C
; Description:
;   Adds the 8bit offset stored in ACC to the address in DPTR.
;
;******************************************************************************

AddAtoDPTR:
	ADD	A,DPL
        MOV	DPL,A
        CLR	A
        ADDC	A,DPH
        MOV	DPH,A
        RET

;******************************************************************************
;
; Function:	MEM_MultipleXRAMCopy
; Input:	DPTR0=address of copy table
;               R5 = number of entries in table
; Output:       ?
; Preserved:	?
; Destroyed:	?
; Description:
;   Copies a series of memory blocks (all XRAM). The format of the table is:
;     source:16, dest:16, len:8, source:16, dest:16, len:8, etc
;
;******************************************************************************

MEM_MultipleXRAMCopy:
	MOV	DPSEL,#0			; get source address
        CLR	A				;
        MOVC	A,@A+DPTR			;
        MOV	B,A				;
        INC	DPTR				;
        CLR	A				;
        MOVC	A,@A+DPTR			;
        INC	DPTR				;
        MOV	DPSEL,#1			;
        MOV	DPH,A				;
        MOV	DPL,B				;
        CALL	MEM_SetSource			;

	MOV	DPSEL,#0			; get dest address
        CLR	A				;
        MOVC	A,@A+DPTR			;
        MOV	B,A				;
        INC	DPTR				;
        CLR	A				;
        MOVC	A,@A+DPTR			;
        INC	DPTR				;
        MOV	DPSEL,#1			;
        MOV	DPH,A				;
        MOV	DPL,B				;
        CALL	MEM_SetDest			;

	MOV	DPSEL,#0			; get length
        CLR	A				;
        MOVC	A,@A+DPTR			;
        INC	DPTR				;
        MOV	R7,A				;

        MOV	DPSEL,#1			; do the copy
        CALL	MEM_CopyXRAMtoXRAMsmall		;

        DJNZ	R5,MEM_MultipleXRAMCopy		; repeat for other entries
	RET					; in table

;***************************** End Of MEMORY.ASM ******************************
