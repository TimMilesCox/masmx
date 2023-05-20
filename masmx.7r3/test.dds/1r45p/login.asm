;******************************************************************************
;
; File     : LOGIN.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the priceplug routines.
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
;******************************************************************************

;******************************************************************************
;
; Function:     LOG_NewLogin
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LOG_NewLogin:
	CALL    PPG_LoadPricePlugHeader
	JNZ     LOG_NLfail

	MOV     DPTR,#sys_stats_ppinserts       ; increment count of
	CALL    MEM_SetSource                   ; how many priceplugs
	MOV     DPTR,#EE_STATS_PPINSERTS        ; have powered up this
	CALL    MEM_SetDest                     ; machine
	CALL    SYS_UpdateStat                  ;

; cannot update insertions until it is in its own checksummed chunk
;       CALL    SYS_PricePlugPowerOn
;       CALL    SYS_DisableInts
;       MOV     DPTR,#ppg_hdr_insertions
;       CALL    MTH_IncLong
;       CALL    MEM_SetSource
;       MOV     DPTR,#128+2+2+16+1+1
;       CALL    MEM_SetDest
;       MOV     R1,#PPG_EESLAVE
;       SETB    F0
;       CLR     F1
;       MOV     R7,#4
;       CALL    MEM_CopyXRAMtoEEsmall
;       CALL    SYS_EnableInts
;       CALL    SYS_PricePlugPowerOff

	CALL    LOG_PrepareForLogin

	; log ppg read to audit
	MOV     DPSEL,#0
;       MOV     DPTR,#aud_entry_plugread
;       CALL    AUD_AddEntry

	CALL    LOG_CheckLoginAllowed
	CALL    LOG_LoadPricePlugData
	JZ      LOG_NLfail
	CALL    LOG_ProcessPricePlugData
	JZ      LOG_NLfail
	CALL    LOG_CheckChunksValid
	CALL    LOG_CheckLoginComplete

	RET

LOG_Virgin:     DB      11,'Virgin Plug'
LOG_NoPlug:     DB      7,'No Plug'
LOG_PlugHdr:    DB      11,'Plug Header'
LOG_PlugChk:    DB      10,'Plug Check'
ppg_msg_pperror: DB 255,29,0,0,0,0,19,'PricePlug Error XXX'
LOG_NLfail:
	IF VT10
	MOV     A,ppg_error
	CJNE    A,#2,LOG_No_Plug
	MOV     DPTR,#LOG_Virgin
	CALL    PRT_DisplayMessageCODE          ; DPTR = message
	JMP     LOG_EndPlug
LOG_No_Plug:
	MOV     A,ppg_error
	CJNE    A,#3,LOG_PlugHeader
	MOV     DPTR,#LOG_NoPlug
	CALL    PRT_DisplayMessageCODE          ; DPTR = message
	JMP     LOG_EndPlug
LOG_PlugHeader:
	MOV     A,ppg_error
	CJNE    A,#4,LOG_PlugCheck
	MOV     DPTR,#LOG_PlugHdr
	CALL    PRT_DisplayMessageCODE          ; DPTR = message
	JMP     LOG_EndPlug
LOG_PlugCheck:
	MOV     A,ppg_error
	CJNE    A,#5,LOG_EndPlug
	MOV     DPTR,#LOG_PlugChk
	CALL    PRT_DisplayMessageCODE          ; DPTR = message


LOG_EndPlug:

	ELSE    

	MOV     DPSEL,#1
	MOV     DPTR,#ppg_msg_pperror
	CALL    MEM_SetSource
	MOV     DPTR,#buffer
	CALL    MEM_SetDest
	MOV     R7,#26
	CALL    MEM_CopyCODEtoXRAMsmall

	MOV     DPTR,#buffer+23
	MOV     B,ppg_error
	MOV     R5,#3
	CALL    NUM_NewFormatDecimalB

	IF DT5
	 CALL   PRT_StartPrint
	 CALL   DisplayOneLiner
	 CALL    PRT_FormFeed
	 CALL   PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#buffer+7
	 MOV    R7,#19
	 CALL   LCD_DisplayStringXRAM
	ENDIF
	ENDIF

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	MOV     A,#'!'
	CALL    LCD_WriteData
	CALL    SYS_UnitPowerOff

	RET

;******************************************************************************
;
; Function:     LOG_PrepareForLogin
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Clears out any data / structures to prepare for a new login. If that login
;   fails, we dont want old data lying around.
;
;******************************************************************************

LOG_PrepareForLogin:
	MOV     DPTR,#ppg_fixhdr_plugtype
	MOVX    A,@DPTR
	CJNE    A,#PPG_OPERATOR,LOG_PFLnotop

; Operator
	CALL    PPG_ClearChunkLayout
	CALL    PPG_ClearChunkHotkeyTickets
	CALL    PPG_ClearChunkMenuTickets
	CALL    PPG_ClearChunkDuplicateFields
	IF USE_SLAVE
	CALL    PPG_ClearChunkSlaveLayout
	ENDIF
	RET
LOG_PFLnotop:
	CJNE    A,#PPG_MANAGER,LOG_PFLnotman

; Manager
	CALL    PPG_ClearChunkManager
	IF USE_SLAVE
	CALL    PPG_ClearChunkSlaveManager
	ENDIF
LOG_PFLnotman:
	RET

;******************************************************************************
;
; Function:     LOG_CheckLoginAllowed
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Checks whether a login is allowed based upon the previous read priceplug
;   header. The only reason a login would not be allowed would be if a
;   different operator tried to login in mid-shift. In this case this function
;   displays a message and powers the unit down.
;
;******************************************************************************

msg_prevshift:  DB 255,18,0,0,0,0,18,'Operator XXX Must '
msg_prevshift2: DB 255,18,0,0,0,0,18,'End Shift XXXXX   '

LOG_CLAyes:                                     ; login allowed
	RET

LOG_CheckLoginAllowed:
	IF USE_ALTONCOMMS
	 RET                                    ;
	ENDIF

	MOV     DPTR,#ppg_fixhdr_plugtype       ; if its not an operator
	MOVX    A,@DPTR                         ; plug then its ok to login
	CJNE    A,#PPG_OPERATOR,LOG_CLAyes      ;

	MOV     DPTR,#shf_shiftowner            ; its operator.
	MOVX    A,@DPTR                         ; if there is no shift owner
	MOV     B,A                             ; then its ok to login
	INC     DPTR                            ;
	MOVX    A,@DPTR                         ;
	ORL     A,B                             ;
	JZ      LOG_CLAyes                      ;

	MOV     DPTR,#ppg_hdr_usernum           ; if the user logging in
	CALL    MTH_LoadOp1Word                 ; is the shift owner, then
	MOV     DPTR,#shf_shiftowner            ; its ok to login
	CALL    MTH_LoadOp2Word                 ;
	CALL    MTH_CompareWords                ;
	JNZ     LOG_CLAyes

	MOV     DPTR,#msg_prevshift             ; prepare the message
	CALL    MEM_SetSource                   ; indicating which user
	MOV     DPTR,#buffer                    ; must cashup first
	CALL    MEM_SetDest                     ;
	MOV     R7,#25                          ;
	CALL    MEM_CopyCODEtoXRAMsmall         ;

	MOV     DPSEL,#0                        ; insert the user number
	MOV     DPTR,#shf_shiftowner            ;
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#buffer+16                 ;
	MOV     R5,#3+NUM_ZEROPAD               ;
	CALL    NUM_NewFormatDecimal16          ;

	IF      DT5                             ;
	 CALL   PRT_StartPrint                  ;
	 CALL   DisplayOneLiner                 ;
	ELSE
	 CALL    LCD_Clear                      ;
	 MOV     DPTR,#buffer+7                 ;
	 MOV     R7,#18                         ;
	 CALL    LCD_DisplayStringXRAM          ;
	ENDIF                                   ;

	MOV     DPTR,#msg_prevshift2            ; prepare the message
	CALL    MEM_SetSource                   ; indicating which shift
	MOV     DPTR,#buffer                    ; must be cashed up
	CALL    MEM_SetDest                     ;
	MOV     R7,#25                          ;
	CALL    MEM_CopyCODEtoXRAMsmall         ;

	MOV     DPSEL,#0                        ; insert the shift number
	MOV     DPTR,#shf_shift                 ;
	MOV     DPSEL,#1                        ;
	MOV     DPTR,#buffer+17                 ;
	MOV     R5,#5+NUM_ZEROPAD               ;
	CALL    NUM_NewFormatDecimal16          ;

	IF DT5                                  ;
	 CALL   DisplayOneLiner                 ;
	 CALL    PRT_FormFeed
	 CALL   PRT_EndPrint                    ;
	ELSE
	 MOV    A,#64                           ;
	 CALL   LCD_GotoXY                      ;
	 MOV    DPTR,#buffer+7                  ;
	 MOV    R7,#18                          ;
	 CALL   LCD_DisplayStringXRAM           ;
	ENDIF                                   ;


	IF      SPEAKER
	CALL    SND_Warning                     ;
	ENDIF

	MOV     R0,#20                          ;
	CALL    delay100ms                      ;
	CALL    SYS_UnitPowerOff                ;
	RET

;***

;******************************************************************************
;
; Function:     LOG_LoadPricePlugData
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

LOG_LoadPricePlugData: ; the new name, convert other calls later
	MOV     DPTR,#ppg_hdr_databytes         ; set up byte count
	MOVX    A,@DPTR                         ;
	MOV     R7,A                            ;
	INC     DPTR                            ;
	MOVX    A,@DPTR                         ;
	MOV     R6,A                            ;
	ORL     A,R7                            ;
	JZ      LOG_LPPDnodata                  ;
	MOV     A,R6
	ANL     A,#0E0h
	JNZ     LOG_LPPDinvalidcount

	CALL    SYS_PricePlugPowerOn            ; prepare to read priceplug
	MOV     R1,#PPG_EESLAVE                 ;
	SETB    F0                              ;
	CLR     F1                              ;

	MOV     DPTR,#PPG_EE_DATA
	CALL    MEM_SetSource
	MOV     DPTR,#prt_bitmap
	CALL    MEM_SetDest
	CALL    MEM_CopyEEtoXRAM
	JNZ     LOG_LPPDloaddatafail
	CALL    SYS_PricePlugPowerOff

LOG_LPPDnodata:
	MOV     A,#1            ; successful load of no data
	RET

LOG_LPPDloaddatafail:
	MOV     ppg_error,#7                    ; error - load data fail
	JMP     LOG_LPPDfail
LOG_LPPDinvalidcount:
	MOV     ppg_error,#6                    ; error - data count fail
	JMP     LOG_LPPDfail
LOG_LPPDfail:
	CLR     A
	RET

;*****************************************************************************

; Note: chunk types 8 and 9 are not defined unless USE_SLAVE is defined. To
; be compatible, all machines are being told about these chunks, but the
; machines which don't have the chunks point them to the non-slave versions
; of these chunks, purely so that CheckChunksValid() doesn't crap over anything
; which it shouldnt. No actual code to access the slave chunks is compiled if
; USE_SLAVE is not defined.

PPG_CHNK_LAYOUT                 EQU 1
PPG_CHNK_TICKETS                EQU 2
PPG_CHNK_MANAGERCONFIG          EQU 3
PPG_CHNK_MENU16TICKETS          EQU 4
PPG_CHNK_MENU32TICKETS          EQU 5
PPG_CHNK_MENU48TICKETS          EQU 6
PPG_CHNK_DUPLICATEFIELDS        EQU 7
PPG_CHNK_SLAVEMANAGERCONFIG     EQU 8
PPG_CHNK_SLAVELAYOUT            EQU 9
PPG_MAX_CHUNKS                  EQU 10                  ; chunk count

ppg_chunk_table:
	DW 0,0
	DW OPR_LAYOUT_SIZE,ppg_chunk_layout
	DW 5+1312,ppg_chunk_tickets
	DW MAN_TOTAL_SIZE,ppg_chunk_manager
	DW 5+1312,ppg_chunk_menu_tickets                ; chunk type 4
	DW 5+2624,ppg_chunk_menu_tickets                ; chunk type 5
	DW 5+3936,ppg_chunk_menu_tickets                ; chunk type 6
	DW OPR_DUPFIELDS_SIZE,ppg_chunk_dupfields       ; chunk type 7
	IF USE_SLAVE
	DW MAN_TOTAL_SIZE,ppg_chunk_slavemanager        ; chunk type 8
	DW OPR_LAYOUT_SIZE,ppg_chunk_slavelayout        ; chunk type 9
	ELSE
	DW MAN_TOTAL_SIZE,ppg_chunk_manager             ; chunk type 8
	DW OPR_LAYOUT_SIZE,ppg_chunk_layout             ; chunk type 9
	ENDIF

;******************************************************************************
;
; Function:     LOG_ProcessPricePlugData
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************


LOG_PPPDnochunks2: JMP LOG_PPPDnochunks         ; rel jump out of range

LOG_ProcessPricePlugData:
	MOV     DPTR,#ppg_hdr_datachunks
	MOVX    A,@DPTR
	JZ      LOG_PPPDnochunks2
	MOV     DPTR,#prt_bitmap
	CALL    MEM_SetSource
LOG_PPPDloop:
	PUSHACC
	CALL    CRC_ConfirmChecksum
	JZ      LOG_PPPDchkfail
	MOV     DPL,srcDPL                      ;
	MOV     DPH,srcDPH                      ;
	INC     DPTR                            ; get chunk id
	INC     DPTR                            ;
	MOVX    A,@DPTR                         ;

;;;;;;;;;newtestcode
	PUSHACC
	INC     DPTR
	CALL    MTH_LoadOp2Word
	POP     ACC
;;;;;;;;;endofnewtestcode

	MOV     DPL,srcDPL                      ;
	MOV     DPH,srcDPH                      ;

	CJNE    A,#PPG_MAX_CHUNKS,LOG_PPPDne    ; if this version of
	JMP     LOG_PPPDprocess                 ; the code knows about
LOG_PPPDne:                                     ; this chunk type
	JC      LOG_PPPDprocess                 ; then process it
	JMP     LOG_PPPDskipchunk               ;

LOG_PPPDchkfail: ; was at end, but JZ wont reach
	POP     ACC
	CLR     A
	MOV     ppg_error,#8            ; error - data chk fail
	RET

;;;;;;;;;newtestcode
LOG_PPPDoldformat:
	POP     DPL
	POP     DPH
	POP     ACC
	CLR     A
	MOV     ppg_error,#9
	RET
;;;;;;;;;endofnewtestcode

LOG_PPPDprocess:
	PUSHDPH                         ; save start
	PUSHDPL                         ; of chunk
	MOV     B,#4                    ; find chunk type
	MUL     AB                      ; in table
	MOV     DPTR,#ppg_chunk_table   ;
	CALL    AddABtoDPTR             ;

;;;;;;;;;newtestcode
	PUSHDPH
	PUSHDPL
	MOV     R0,#mth_operand1
	CALL    MTH_LoadConstWord
	POP     DPL
	POP     DPH
	CALL    MTH_TestGTWord
	JC      LOG_PPPDoldformat
;;;;;;;;;endofnewtestcode

	CLR     A                       ; read byte count
	MOVC    A,@A+DPTR               ;
	INC     DPTR                    ;
	MOV     R7,A                    ;
	CLR     A                       ;
	MOVC    A,@A+DPTR               ;
	INC     DPTR                    ;
	MOV     R6,A                    ;

	ORL     A,R7                    ; give up if chunk size zero
	JZ      LOG_PPPDabort           ; (chunk unknown by this code)

	MOV     A,R6                    ; save chunk size
	PUSHACC                         ; for later
	MOV     A,R7                    ;
	PUSHACC                         ;

	CLR     A                       ; read dest address
	MOVC    A,@A+DPTR               ;
	MOV     B,A                     ;
	INC     DPTR                    ;
	CLR     A                       ;
	MOVC    A,@A+DPTR               ;
	MOV     DPH,A                   ;
	MOV     DPL,B                   ;
	CALL    MEM_SetDest             ;

	PUSHDPH                         ; transfer the chunk
	PUSHDPL                         ;
	CALL    MEM_CopyXRAMtoXRAM      ;
	POP     DPL                     ;
	POP     DPH                     ;

	POP     ACC                     ; modify chunk size
	MOV     R7,A                    ; to the size understood
	POP     ACC                     ; by this version of
	MOV     R6,A                    ; the code
	CALL   PPG_ChangeChunkSize      ;

LOG_PPPDabort:
	POP     DPL                     ; restore DPTR to
	POP     DPH                     ; start of chunk

LOG_PPPDskipchunk:
	CALL    PPG_ReadChunkSize

	MOV     A,R7                    ; skip past chunk
	JZ      LOG_PPPDskip            ;
	INC     R6                      ;
LOG_PPPDskip:                           ;
	INC     DPTR                    ;
	DJNZ    R7,LOG_PPPDskip         ;
	DJNZ    R6,LOG_PPPDskip         ;
	MOV     srcDPH,DPH
	MOV     srcDPL,DPL
	POP     ACC
	DJNZ    ACC,LOG_PPPDloopreach
LOG_PPPDnochunks:
	MOV     A,#1
	RET
LOG_PPPDloopreach:
	JMP     LOG_PPPDloop

;******************************************************************************
;
; Function:     LOG_CheckChunksValid
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   goto all chunks, if the chunk exists, confirm the checksum. if the
;   checksum fails, zero the header so that checklogincomplete will not see
;   that chunk (and subsequently shutdown if that chunk was required)
;
;******************************************************************************

LOG_CheckChunksValid:
	MOV     DPTR,#ppg_chunk_table+4
	MOV     R4,#PPG_MAX_CHUNKS-1
LOG_CCVloop:
	PUSHDPH
	PUSHDPL

	INC     DPTR                            ; skip 'our' length field
	INC     DPTR                            ; incase pp format is newer

	CLR     A
	MOVC    A,@A+DPTR                       ; get the chunk
	MOV     B,A                             ; data address
	INC     DPTR                            ;
	CLR     A                               ;
	MOVC    A,@A+DPTR                       ;
	MOV     DPH,A                           ;
	MOV     DPL,B                           ;

	PUSHDPH                         ; skip the checksum
	PUSHDPL                         ; and read the
	INC     DPTR                            ; chunktype code
	INC     DPTR                            ;
	MOVX    A,@DPTR                         ;
	POP     DPL                             ;
	POP     DPH                             ;
	JZ      LOG_CCVempty
	PUSHDPH
	PUSHDPL
	CALL    CRC_ConfirmChecksum
	POP     DPL
	POP     DPH
	JNZ     LOG_CCVchunkok

LOG_CCVempty:
	MOV     R7,#5                           ; checksum failed
	CLR     A                               ; zero the header
LOG_CCVzerohdr:                                 ; of the failed
	MOVX    @DPTR,A                         ; block so it looks
	INC     DPTR                            ; like the block
	DJNZ    R7,LOG_CCVzerohdr                       ; doesnt exist

LOG_CCVchunkok:
	POP     DPL
	POP     DPH
	INC     DPTR
	INC     DPTR
	INC     DPTR
	INC     DPTR

	DJNZ    R4,LOG_CCVloop
	RET

;******************************************************************************
;
; Function:     LOG_CheckLoginComplete
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Makes sure that all the necessary data chunks (dependant on type of
;   priceplug) are loaded and checksummed ready for use. If any of the
;   required data chunks are missing, tell the user and do a shutdown.
;
;******************************************************************************

msg_nomancfg:   DB 255,18,0,0,0,0,18,'No Manager Config '
msg_nooprcfg:   DB 255,18,0,0,0,0,18,'No Operator Config'

LOG_CheckLoginComplete:
	MOV     DPTR,#ppg_chunk_manager+2       ; check
	MOVX    A,@DPTR                         ; for manager
	JZ      LOG_CLCmanfail                  ; chunk

	IF USE_SLAVE
	MOV     DPTR,#ppg_chunk_slavemanager+2  ; check
	MOVX    A,@DPTR                         ; for slavemanager
	JZ      LOG_CLCmanfail                  ; chunk
	ENDIF

	MOV     DPTR,#ppg_fixhdr_plugtype
	MOVX    A,@DPTR
	CJNE    A,#PPG_OPERATOR,LOG_CLCnotop

	MOV     DPTR,#ppg_chunk_layout+2        ; check for
	MOVX    A,@DPTR                         ; layout
	JZ      LOG_CLCopfail                   ; chunk

	IF USE_SLAVE
	MOV     DPTR,#ppg_chunk_slavelayout+2   ; check for
	MOVX    A,@DPTR                         ; slavelayout
	JZ      LOG_CLCopfail                   ; chunk
	ENDIF

	MOV     DPTR,#ppg_chunk_tickets+2       ; check for
	MOVX    A,@DPTR                         ; tickets
	JNZ     LOG_CLCok                       ; chunk
	MOV     DPTR,#ppg_chunk_menu_tickets+2  ; or
	MOVX    A,@DPTR                         ; menu chunk
	JZ      LOG_CLCopfail

LOG_CLCok:
LOG_CLCnotop:
	RET

LOG_CLCopfail:
	IF DT5
	 CALL   PRT_StartPrint
	 MOV    DPTR,#msg_nooprcfg
	 CALL   PRT_DisplayMessageCODE
	 CALL    PRT_FormFeed
	 CALL   PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#msg_nooprcfg+6            ;
	 CALL   LCD_DisplayStringCODE           ;
	 CALL   LCD_Clear2                      ;
	ENDIF
	JMP     LOG_CLCloginfail
LOG_CLCmanfail:
	IF DT5
	 CALL   PRT_StartPrint
	 MOV    DPTR,#msg_nomancfg
	 CALL   PRT_DisplayMessageCODE
	 CALL    PRT_FormFeed
	 CALL   PRT_EndPrint
	ELSE
	 CALL   LCD_Clear
	 MOV    DPTR,#msg_nomancfg+6            ;
	 CALL   LCD_DisplayStringCODE           ;
	 CALL   LCD_Clear2                      ;
	
E2PROBLEM EQU   1        
	
	IF      E2PROBLEM
	
	mov     dpl,#127
Lulu:   mov     dph,#50h
	movx    a,@dptr
	mov     dph,#07fh
	movx    @dptr,a
	djnz    dpl,Lulu
	mov     a,#0aah
	movx    @dptr,a
	
	ENDIF
	
	ENDIF
LOG_CLCloginfail:

	IF      SPEAKER
	CALL    SND_Warning
	ENDIF

	MOV     R0,#5
	CALL    delay100ms
	CALL    SYS_UnitPowerOff
	RET

;****************************** End Of LOGIN.ASM *****************************
;


	end
