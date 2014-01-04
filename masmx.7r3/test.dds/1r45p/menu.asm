;******************************************************************************
;
; File     : MENU.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains routines to provide scrolling menu lists.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
; 1.
;   Menus are currently copied into ram at buffer+1024 so that titles and/or
;   menu items can be tweaked according to various run-time options.
; 2.
;   A menu's previous position is stacked when a sub-menu is called, so there
;   is a reasonably small limit to the level of menu nesting achievable.
;******************************************************************************

MNU_LEFT	EQU 3
MNU_RIGHT	EQU 4

;*************************
; Example Menu Declaration
;*************************
;test_menu:
;	DB 3				; number of entries (inc title)
;	DB '======Menu Title======'	; title
;	DW 0				; always 0 (no function to call)
;	DB 'Option 1              '	; 22 character entry description
;	DW func1				; function to call for this entry
;	DB 'Option 2              '	; repeat for...
;	DW func2				; ...all other entries
;
;func1:
;	code here
;	CLR	A	; return A=0 if menu is to repeat
;	RET
;func2:
;	code here
;	MOV	A,#1	; return A=1 if menu is to terminate
;	RET
;*******************
; Example Menu Usage
;*******************
;	CALL	MNU_NewMenu		; position to top of menu
;loop:
;	MOV	DPTR,#tst_ramtestmenu	; load up...
;	CALL	MNU_LoadMenuCODE	; ...the menu
;
;	; modify the menu in ram here to suit options etc
;
;	CALL	MNU_SelectMenuOption	; menu handler...returns 0 if this
;	JZ	loop			; menu is to be done again
;
;	CLR	A			; get previous menu to repeat (A=0)
;	RET				; or to abort (A=1)
;******************************************************************************

mnu_curr:	VAR 1	; the current item in the menu, 0 < curr < numitems
mnu_numitems:	VAR 1	; the number of items in the current menu

;******************************************************************************
;
; Function:	MNU_NewMenu
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

MNU_NewMenu:
	MOV	A,#1			; position menu list at first item
        MOV	DPTR,#mnu_curr		; (item 0 is the title)
        MOVX	@DPTR,A			;
        RET

;******************************************************************************
;
; Function:	MNU_LoadMenuCODE
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

MNU_LoadMenuCODE:
	CLR	A			; calculate menu size
	MOVC	A,@A+DPTR		; (numitems * 24) + 1
	MOV	B,#24			;
	MUL	AB			;
	INC	A			;
	JNZ	MNU_LMCok		;
	INC	B			;
MNU_LMCok:
	MOV	R6,B			; copy menu to XRAM
	MOV	R7,A			;
	CALL	MEM_SetSource		;
	MOV	DPTR,#buffer+1024		;
	CALL	MEM_SetDest		;
	CALL	MEM_CopyCODEtoXRAM	;
	RET

;******************************************************************************
;
; Function:	MNU_AddMenuItem
; Input:	DPTR=address of menu item (22 byte name, 16-bit addr)
; Output:	None
; Preserved:	?
; Destroyed:	?
; Description:
;   Adds the single menu item pointed to by DPTR to an existing XRAM based
;   menu. Menu's can be loaded either with a single call to LoadMenuCODE or
;   with a call to LoadMenuCODE (to do the menu header) plus numerous calls
;   to AddMenuItem.
;
;******************************************************************************

MNU_AddMenuItem:
	CALL	MEM_SetSource
        MOV	DPTR,#buffer+1024
        MOVX	A,@DPTR
        MOV	B,#24
        MUL	AB
        INC	A
        JNZ	MNU_AMIok
	INC	B
MNU_AMIok:
	CALL	AddABtoDPTR
        CALL	MEM_SetDest
        MOV	R7,#24
        CALL	MEM_CopyCODEtoXRAMsmall
        MOV	DPTR,#buffer+1024
        MOVX	A,@DPTR
        INC	A
        MOVX	@DPTR,A
	RET

;******************************************************************************
;
; Function:	MNU_DisplayMenu
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

MNU_DisplayMenu:
	CALL	LCD_Clear
	MOV	A,#1
	CALL	LCD_GotoXY
	MOV	DPTR,#mnu_curr
        MOVX	A,@DPTR
        DEC	A
        MOV	DPTR,#buffer+1024
        INC	DPTR
        MOV	B,#24
        MUL	AB
        CALL	AddABtoDPTR
	MOV	R7,#22
        CALL	LCD_DisplayStringXRAM
	MOV	DPTR,#mnu_curr
        MOVX	A,@DPTR
;        CJNE	A,B,MNU_DM2ndrow
;	RET
MNU_DM2ndrow:
        MOV	DPTR,#buffer+1024
        INC	DPTR
        MOV	B,#24
        MUL	AB
        CALL	AddABtoDPTR
	MOV	A,#65
	CALL	LCD_GotoXY
	MOV	R7,#22
        CALL	LCD_DisplayStringXRAM

	MOV	DPTR,#mnu_curr
	MOVX	A,@DPTR
	DEC	A
	JZ	MNU_DMnoup
	MOV	A,#23			; draw the up symbol
	CALL	LCD_GotoXY		;
	MOV	A,#2			;
	CALL	LCD_WriteData		;
MNU_DMnoup:
	MOV	DPTR,#mnu_numitems
	MOVX	A,@DPTR
	MOV	B,A
	MOV	DPTR,#mnu_curr
	MOVX	A,@DPTR
	INC	A
	CJNE	A,B,MNU_DMup
MNU_DMtherest:
	MOV	A,#64
	CALL	LCD_GotoXY
	MOV	A,#'>'
	CALL	LCD_WriteData
;	MOV	A,#87
;	CALL	LCD_GotoXY
;	MOV	A,#'<'
;	CALL	LCD_WriteData
	RET
MNU_DMup:
	MOV	A,#87			; draw the down symbol
	CALL	LCD_GotoXY		;
	MOV	A,#3			;
	CALL	LCD_WriteData		;
	JMP	MNU_DMtherest

;******************************************************************************
;
; Function:	MNU_SelectMenuOption
; Input:	?
; Output:	?
; Preserved:	?
; Destroyed:	?
; Description:
;   etc
;
;******************************************************************************

MNU_SelectMenuOption:
	MOV	DPTR,#buffer+1024		; get item count
	MOVX	A,@DPTR			;
        MOV	DPTR,#mnu_numitems	;
        MOVX	@DPTR,A			;

MNU_SMOmainloop:
	CALL	MNU_DisplayMenu			; display menu from current
        CALL	KBD_WaitKey			; position and get next
        CJNE	A,#KBD_DOWN,MNU_SMOnotdown		; keypress
;*****
; DOWN
;*****
	MOV	DPTR,#mnu_numitems		; down, move to next
        MOVX	A,@DPTR				; entry in menu
        MOV	B,A				;
	MOV	DPTR,#mnu_curr			;
        MOVX	A,@DPTR				;
        INC	A				;
        CJNE	A,B,MNU_SMOdownok			;
        DEC	A				;
MNU_SMOdownok:					;
        MOVX	@DPTR,A				;
	JMP	MNU_SMOmainloop			;

MNU_SMOnotdown:
	CJNE	A,#KBD_UP,MNU_SMOnotup
;***
; UP
;***
	MOV	DPTR,#mnu_curr			; up, move to previous
        MOVX	A,@DPTR				; entry in menu
        DEC	A				;
        JZ	MNU_SMOupfail			;
        MOVX	@DPTR,A				;
MNU_SMOupfail:				;
	JMP	MNU_SMOmainloop			;

MNU_SMOnotup:
	CJNE	A,#KBD_LEFT,MNU_SMOnotleft
;*****
; LEFT
;*****
	MOV	A,#MNU_LEFT			; return "left pressed" code
        RET

MNU_SMOnotleft:
	CJNE	A,#KBD_RIGHT,MNU_SMOnotright
;******
; RIGHT
;******
	MOV	A,#MNU_RIGHT			; return "right pressed" code
        RET

MNU_SMOnotright:
	CJNE	A,#KBD_OK,MNU_SMOnotok
;***
; OK
;***
	MOV	DPTR,#mnu_curr			; OK pressed
	MOVX	A,@DPTR
	JZ	MNU_SMOmainloop
	PUSHACC

	MOV	DPTR,#buffer+1024+1+22		; get address of
	MOV	B,#24				; function to call
	MUL	AB				;
	CALL	AddABtoDPTR			;

	MOVX	A,@DPTR
	MOV	B,A
	INC	DPTR
	MOVX	A,@DPTR
	MOV	DPL,B
	MOV	DPH,A
	CLR	A
	CALL	MNU_InvokeFunction		; call the function
	POP	B
	JNZ	MNU_SMOnotagain
	MOV	A,B
	MOV	DPTR,#mnu_curr
	MOVX	@DPTR,A
	MOV	A,#2
	RET

MNU_InvokeFunction:
	JMP	@A+DPTR

MNU_SMOnotok:
	CJNE	A,#KBD_CANCEL,MNU_SMOnotcancel
;*******
; CANCEL
;*******
	MOV	A,#128
	RET
MNU_SMOnotcancel:
	JMP	MNU_SMOmainloop
MNU_SMOnotagain:
	MOV	A,#129
        RET

;******************************* End Of MENU.ASM ******************************
;