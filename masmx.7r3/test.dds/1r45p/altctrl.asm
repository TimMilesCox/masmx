;******************************************************************************
;
; File     : ALTCTRL.ASM
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the routines for implementing real-time
;            ticket control from a ticketing controller PC.
;
; System   : 80C537
;
; History  :
;   Date     Who  Ver  Comments
;
;   12viij99 TimC 1r27 Prints text3 of plug config when master transaction times out.  
;                      text3 is an * at the time of writing, and may be changed in the
;                      plug program to a   for invisibility.
;
;                      File name in header comment changed from TKTCTRL to ALTCTRL
;                      so that suckers looking at a print file will know they have
;                      compiled this, not TKTCTRL. ALT means Alton, not Alternative.
;
; Notes:
;
; 1. Repeatedly call TKC_Idle during the idle loop
; 2. From PrintTickets(), call TKC_InitiateTransaction to start a
;    transaction request off
; 3. From PrintTicket(), call TKC_ReceiveTicketDetails
;******************************************************************************

	IF USE_TKTCTRL
USE_TIMEOUT EQU 0                       ;Controls Polling TimeOut.
DUAL_POLL_POLICY EQU 1
STARRED_EMERGENCY EQU 0


IDL_APPEND EQU 0

tkc_itemno:     VAR 1
tkc_currenttsr: VAR (4+(10*5))
tkc_hangcount:  VAR 2

tkc_eTickets    VAR 2
tkc_recent_tsc  VAR 3

	IF USE_SEATS

tkc_seatrow:    VAR 11          ; up to 10 character seat row
tkc_seatcol:    VAR 11          ; up to 10 character seat column
tkc_seatblock:  VAR 22          ; up to 21 character seat block name
tkc_blockno:    VAR 2
tkc_fixture:    VAR 2
TKC_CheckTKCtrl:
	MOV     DPTR,#man_misc2
	MOVX    A,@DPTR
	ANL     A,#MAN_USETKTCTRL
	RET

	ENDIF   ; USE_SEATS


;******************************************************************************
;
; Function:     TKC_ReceiveStartupMessage
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

tkc_retrycounter:       VAR 1
tkc_retrylines:         DB '-/|',4 ; char 4 for backslash

tkc_msg_tktctrlboot1:   DB 24,'   Initialising From    '
tkc_msg_tktctrlboot2:   DB 24,'  Ticketing Controller  '

tkc_msg_tktctrlboot3:   DB 24,' Initialisation Failed  '
tkc_msg_tktctrlboot4:   DB 24,'      Retrying          '

tkc_msg_tktctrlok:      DB 17,'      Initialised'

	IF USE_SEATS
tkc_msg_fixnum:         DB 16,'    Fixture No. '
	ELSE
	IF USE_ALTONCOMMS
tkc_msg_fixnum:         DB 16,'         Okay   '
	ENDIF
	ENDIF

	IF USE_SEATS

tkc_msg_inputfixture:   DB 19,'     Emergency Mode'
tkc_msg_inputfixture2:  DB 19,'Enter Fixture No.: '

	ENDIF

TKC_ReceiveStartupMessage:

	mov     dptr,#tkc_eTickets
	clr     a
	movx    @dptr,a
	inc     dptr
	movx    @dptr,a

	IF USE_SEATS

	CALL    TKC_CheckTKCtrl
	JNZ     TKC_RSMusectrl
	CALL    LCD_Clear
	MOV     DPTR,#tkc_msg_inputfixture
	CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	CALL    LCD_DisplayStringCODE
	MOV     B,#64+19
	MOV     R7,#4
	CALL    NUM_GetNumber
	MOV     DPTR,#tkc_fixture
	CALL    MTH_StoreWord
	JMP     TKC_RSMgotfixture

	ENDIF   ; USE_SEATS

TKC_RSMusectrl:
	CALL    COM_InitRS485
	MOV     DPTR,#tkc_retrycounter
	CLR     A
	MOVX    @DPTR,A

	IF USE_SEATS

	MOV     A,#1
	CALL    MTH_LoadOp1Acc
	MOV     DPTR,#tkc_blockno
	CALL    MTH_StoreWord

	ENDIF   ; USE_SEATS

	CALL    LCD_Clear
	MOV     DPTR,#tkc_msg_tktctrlboot1
	CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#tkc_msg_tktctrlboot2
	CALL    LCD_DisplayStringCODE

TKC_RSMgo:

;        MOV     R3,#100
	mov     r2,#255         ; Tim, 3ix99
	mov     r3,#255         ; Tim, 3ix99
TKC_RSMwaitgrq:
	CALL    KBD_ReadKey
	CJNE    A,#KBD_CANCEL,TKC_RSMcontinue
	CALL    MAN_SetNodeNumber
TKC_RSMcontinue:

;       *****************************************************************
;       *       Tim     3ix99   *****************************************
;       *****************************************************************
;       *       Do not call delay100ms when wanting a master packet. ****
;       *       The master waits a very short time for the reply     ****
;       *       nose DLE_STX to appear. Make the delay consist entirely *
;       *       of polling for an input message up to 65000 approx times*
;       *****************************************************************

TKC_RSMcontinue1:
	CALL    NET_ReceivePacket
	JNZ     TKC_RSMrxgrq


	MOV     R0,#1
;        CALL    delay100ms     ; _Tim, 3ix99
	DJNZ    R3,TKC_RSMwaitgrq
	djnz    r2,tkc_rsmwaitgrq    ; Tim, 3ix99
	JMP     TKC_RSMfail

;       MOV     R3,#100         ; Someone else has boiled out this
;TKC_RSMwaitgrq:                ; load of rubbish at an earlier time
;       CALL    NET_ReceivePacketEx ; Note you don't need RPackEX if
;       JNZ     TKC_RSMrxgrq        ; if you are doing your own loop
;       DJNZ    R3,TKC_RSMwaitgrq   ; T,3ix99
;       JMP     TKC_RSMfail

TKC_RSMrxgrq:
	CJNE    A,#MSG_GRQ,TKC_RSMnotgrq
	MOV     A,#MSG_SUM
	MOVX    @DPTR,A
	MOV     R7,#1
        CALL    DDSNET_TransmitPacket



;       *****************************************************************
;       *       Tim     3ix99   *****************************************
;       *****************************************************************
;       *       Do not call delay100ms when wanting a master packet. ****
;       *       The master waits a very short time for the reply     ****
;       *       nose DLE_STX to appear. Make the delay consist entirely *
;       *       of polling for an input message up to 65000 approx times*
;       *****************************************************************

	mov     r2,#255         ; T,3ix99
	mov     r3,#255         ; T,3ix99
;        MOV     R3,#10         ; _T,3ix99
TKC_RSMwaitsum:
	CALL    NET_ReceivePacket
	JNZ     TKC_RSMrxsum
	MOV     R0,#1
;        CALL    delay100ms     ; _T,3ix99
	DJNZ    R3,TKC_RSMwaitsum
	DJNZ    R2,TKC_RSMwaitsum   ; T,3ix99
	JMP     TKC_RSMgo
TKC_RSMrxsum:
	CJNE    A,#MSG_SUM,TKC_RSMgo
	CALL    LCD_Clear

	IF USE_SEATS

	MOV     DPTR,#buffer+6
	CALL    MTH_LoadOp1Word
	MOV     DPTR,#tkc_fixture
	CALL    MTH_StoreWord

	ENDIF   ; USE_SEATS

TKC_RSMgotfixture:
	CALL    LCD_Clear                       ; display what fixture
	MOV     DPTR,#tkc_msg_tktctrlok         ; number we are using
	CALL    LCD_DisplayStringCODE           ;
	MOV     A,#64                           ;
	CALL    LCD_GotoXY                      ;
	MOV     DPTR,#tkc_msg_fixnum            ;
	CALL    LCD_DisplayStringCODE           ;

	IF USE_SEATS

	MOV     DPSEL,#0
	MOV     DPTR,#tkc_fixture
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     R5,#4+NUM_ZEROPAD
	CALL    NUM_NewFormatDecimal16
	MOV     DPTR,#buffer
	MOV     R7,#4
	CALL    LCD_DisplayStringXRAM

	ENDIF   ; USE_SEATS

	MOV     R0,#20
	CALL    delay100ms
	CALL    LCD_Clear
	RET

TKC_RSMnotgrq:
	CJNE    A,#MSG_TPI,TKC_RSMwaitgrq
	CALL    TKC_SendTSCFail
	JMP     TKC_RSMwaitgrq
TKC_RSMfail:
	CALL    LCD_Clear
;       MOV     DPTR,#tkc_msg_tktctrlboot3
;       CALL    LCD_DisplayStringCODE
	MOV     A,#64
	CALL    LCD_GotoXY
	MOV     DPTR,#tkc_msg_tktctrlboot4
	CALL    LCD_DisplayStringCODE
	MOV     A,#64+15
	CALL    LCD_GotoXY
	MOV     DPTR,#tkc_retrycounter
	MOVX    A,@DPTR
	INC     A
	ANL     A,#3
	MOVX    @DPTR,A
	MOV     DPTR,#tkc_retrylines
	MOVC    A,@A+DPTR
	CALL    LCD_WriteData
	CALL    PPG_CheckPricePlug
	MOV     R3,#2
	JMP     TKC_RSMwaitgrq

;******************************************************************************
;
; Function:     TKC_SendTSCFail
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKC_SendTSCFail:
	MOV     DPTR,#buffer                    ; got a TPI
	MOV     A,#MSG_TSC                      ; send back a TSC fail
	MOVX    @DPTR,A                         ; with id=0
	INC     DPTR                            ;
	CLR     A
	MOVX    @DPTR,A                         ;
	INC     DPTR
	MOVX    @DPTR,A                         ;
	MOV     DPTR,#buffer                    ;
	MOV     R7,#3                           ;
        CALL    DDSNET_TransmitPacket            ;
	RET

;******************************************************************************
;
; Function:     TKC_Idle
; Input:        None
; Output:       None
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Called repeatedly during main loop idle state so that the PC gets an idle
;   response from the DT whenever possible and also so that the final TSD
;   acknowledge can be sent again, should the PC miss the original TSD.
;
;******************************************************************************

TKC_Idle:

	IF USE_SEATS

	CALL    TKC_CheckTKCtrl
	JZ      TKC_Idone

	ENDIF

	CALL    NET_ReceivePacket
	JNZ     TKC_Imsg
TKC_Idone:
	RET


TKC_GRQ?:
	jmp     TKC_Inotgrq
TKC_Imsg:
	CJNE    A,#MSG_GRQ,TKC_GRQ?

;       MOV     A,#11
;       CALL    DebugTX

TKC_Irespond:
	mov     dptr,#tkc_eTickets      ; or etickets High+Low
	movx    a,@dptr
	mov     b,a
	inc     dptr
	movx    a,@dptr
	orl     a,b
	jz      TKC_ImayBeOutOfPaper    ; If None check paper
	movx    a,@dptr                 ; If etickets read MS byte again
	mov     dptr,#buffer+4          ; Start painting 5 bytes of message
	movx    @dptr,a                 ; paint 5th byte MSB accumulator
	dec     dpl                     ; point 4th
	mov     a,b                     ; 
	movx    @dptr,a                 ; paint 4th byte LSB accumulator
	dec     dpl                     ; point 3rd
	mov     a,#5                    ;
	movx    @dptr,a                 ; paint 3rd byte Ticket Type 5
	dec     dpl                     ; point 2nd
	mov     a,#99
	movx    @dptr,a                 ; paint 2nd byte arbitrary item #
	dec     dpl                     ; point 1st
	mov     a,#MSG_TSC              ; 
	movx    @dptr,a                 ; paint 1st byte unsolicited TSC
	mov     r7,#5                   ; fire it all
        call    DDSNET_TransmitPacket

E_CLEARCONFIRM EQU 0                    

	IF      E_CLEARCONFIRM          ; don't clear tkc_eTickets
	mov     r2,#255                 ; without HOST confirmation
	mov     r3,#255
TKC_IwantEtotalACK:
	call    NET_ReceivePacket
	jnz     TKC_IgotaPacketforE
	djnz    r3,TKC_IwantEtotalACK
	djnz    r2,TKC_IwantEtotalACK
TKC_IgotNotETACK:
	ret
TKC_IgotaPacketforE:
	cjne    a,MSG_ETACK,TKC_IgotNotETACK
	ENDIF

	mov     dptr,#tkc_eTickets
	clr     a
	movx    @dptr,a
	inc     dptr
	movx    @dptr,a
	ret

MSG_STATE_F EQU 128
MSG_HEAT5_F EQU 32
MSG_HEAT4_F EQU 16
MSG_CUTTR_F EQU 8
MSG_PAPLO_F EQU 4
MSG_PAPNO_F EQU 2

TKC_ImayBeOutOfPaper:

	CLR     A                               ; Status clear

	JNB     prt_paperout,TKT_ImayBeLowOnPaper
	MOV     A,#MSG_PAPNO_F OR MSG_STATE_F

TKT_ImayBeLowOnPaper:

	IF      PAPERDETECT
	push    acc
	mov     dptr,#32                        ; paper low flag?
	movx    a,@dptr                         ; PortReadC would be slower
	mov     b,a                             ; than this
	pop     acc
	jnb     b.0,TKT_ImayHaveCutterProbs
	orl     a,#MSG_PAPLO_F OR MSG_STATE_F

	ENDIF

;       *****************************************************************
;       *       Compose status word for MASTER to relay to HOST in the  *
;       *       array known as HOST_PKT_RS.                             *
;       *                                                               *
;       *       MSG_IDL will only be sent back from SLAVE to MASTER     *
;       *       if no abnormal device states have been OR-flagged.      *
;       *       Values of these state flags are:                        *
;       *       _________________________________________________       *
;       *       |7    |6    |5    |4    |3    |2    |1    |0    |       *
;       *       |_____|_____|_____|_____|_____|_____|_____|_____|       *
;       *       |STATE|spare|HEAT5|HEAT4|CUTTR|PPLOW|PPOUT|Master       *
;       *       |     |     |     |     |     |     |     |Use  |       *
;       *       |_____|_____|_____|_____|_____|_____|_____|_____|       *
;       *  __________|       {_________}   |     |     |     |          *
;       *  STATE=1:               |        |     |     |     |          *
;       *  status bits 6:1 are    |        |     |     |     |          *
;       *  device substates.      |        |     |     |     |          *
;       *  STATE=0: this code     |        |     |     |     |          *
;       *  is a protocol unit     |        |     |     |     |          *
;       *  other than device state|        |     |     |     |          *
;       *  e.g. MSG_IDL = x02     |        |     |     |     |          *
;       *                         |        |     |     |     |          *
;       *  _______________________|        |     |     |     |          *
;       *  Head Temperature Status         |     |     |     |          *
;       *  Flags when STATE = 1            |     |     |     |          *
;       *                                  |     |     |     |          *
;       *  ________________________________|     |     |     |          *
;       *  CUTTER jam when STATE = 1             |     |     |          *
;       *                                        |     |     |          *
;       *  ______________________________________|     |     |          *
;       *  PAPER LOW when STATE = 1                    |     |          *
;       *                                              |     |          *
;       *  ____________________________________________|     |          *
;       *  PAPER OUT when STATE = 1                          |          *
;       *                                                    |          *
;       *  __________________________________________________|          *
;       *  Used by MASTER when relaying SLAVE status to HOST:           *
;       *  Indicates that SLAVE is not in communication with MASTER.    *
;       *****************************************************************

TKT_ImayHaveCutterProbs:
	push    acc
	mov     dptr,#cutter_status     ; set during certain
	movx    a,@dptr                 ; cutter action delays
	mov     b,a
	clr     a                       ; do not leave it asserted
	movx    @dptr,a
	pop     acc
	orl     a,b                     ; if set it contains STATE++CUTTR
TKT_ImayHaveHeatProbs:

HEAT_SENSE EQU  1

	IF      HEAT_SENSE
	push    acc
	call    PRT_ScanHeadTemp
	IF      HEAT_SENSE GT 1
	mov     dptr,#prt_headtemp
	movx    a,@dptr
	clr     b
	jb      acc.7,TKT_IhaveHeatProbs
	jnb     acc.6,TKT_IdontHaveHeatProbs
TKT_IhaveHeatProbs:
	anl     a,#192
	rr      a
	rr      a
	mov     b,a
	setb    b.7
TKT_IdontHaveHeatProbs:
	pop     acc
	orl     a,b
	ELSE
	pop     acc
	ENDIF
	ENDIF

TKT_IsendIDL:
	jb      acc.7,TKT_Isendmessage
	MOV     A,#MSG_IDL                      ; send an IDL

TKT_Isendmessage:
	MOV     DPTR,#buffer                    ;
	MOVX    @DPTR,A                         ;

	IF      IDL_APPEND
	mov     dptr,#IDL_APPEND
	movx    a,@dptr
	mov     dptr,#buffer+1
	movx    @dptr,a
	mov     dptr,#buffer
	mov     r7,#2
	ELSE

	MOV     R7,#1                           ;

	ENDIF

        CALL    DDSNET_TransmitPacket            ;
	RET                                     ;

TKC_Inotgrq:
	CJNE    A,#MSG_TSD,TKC_Inottsd

;       MOV     A,#22
;       CALL    DebugTX

	MOV     DPTR,#buffer+5                  ; got a TSD
	MOV     R7,#1                           ; send a TSD
        CALL    DDSNET_TransmitPacket            ;
	RET                                     ;

TKC_Inottsd:
	CJNE    A,#MSG_TPI,TKC_Inottpi          ; got a TPI

;       MOV     A,#33
;       CALL    DebugTX

	IF USE_ALTONCOMMS
	CALL    TKC_SendTSCFail                 ; Added RWG
	RET                                     ;
	 JNB    alton_sensorwait,TKC_IsendTSCfail

;        MOV    A,#99
;        CALL   DebugTX
	 MOV    DPTR,#buffer                    ; got a GRQ
	 MOV    A,#MSG_IDL                      ; send an IDL
	 MOVX   @DPTR,A                         ;
	 MOV    R7,#1                           ; 
         CALL   DDSNET_TransmitPacket            ;

	 RET

	ENDIF

TKC_IsendTSCfail:
	CALL    TKC_SendTSCFail                 ; send a TSC fail (id=0)

TKC_Inottpi:
	IF      DUAL_POLL_POLICY
	cjne    A,#MSG_IDL,TKC_Inothing
	jmp     TKC_Irespond
	ENDIF
TKC_Inothing:


	RET                                     ; unknown message - ignore

;******************************************************************************
;
; Function:     TKC_InitiateTransaction
; Input:        None
; Output:       A=0=fail and abort transaction
;               A=1=ok, first ticket details cached ready for printing
; Preserved:    ?
; Destroyed:    ?
; Description:
;   Initiate a transaction by waiting to be polled and passing the
;   transaction request to the PC. On failure, report error to user and
;   return error code indicating an aborted transaction. On success, cache
;   the details of the first ticket ready for printing.
;
;******************************************************************************

tkc_msg_whatblock:      DB 24,'Enter Block:     (OK=  )'
tkc_msg_tktctrlfail:    DB 24,'Ticket Controller Failed'
tkc_msg_tktctrlfail2:   DB 24,'  Report To Supervisor  '

TKC_InitiateTransaction:


;       *************************************************
;       *       Tim     12viij99        *****Start*******
;       *************************************************
;       *       Flag Transaction Not Yet Failed         *
;       *************************************************

	IF      STARRED_EMERGENCY
	MOV     DPTR,#ppg_oper_text3  ; Flag FIELD_HEADER
	MOV     A,9                   ; OFF
	MOVX    @DPTR,A               ;
	ENDIF

;       *************************************************
;       *       Tim     12viij99        *****Finish******
;       *************************************************


	IF USE_SEATS

	CALL    TKC_CheckTKCtrl                 ; check if we are running
	JNZ     TKC_ITusectrl                   ; in fail-safe or whether
	CLR     A
	MOV     DPTR,#tkc_seatrow
	MOVX    @DPTR,A
	MOV     DPTR,#tkc_seatcol
	MOVX    @DPTR,A
	MOV     DPTR,#tkc_seatblock
	MOVX    @DPTR,A
	MOV     A,#1                            ; we actually want to use
	RET                                     ; the ticketing controller

TKC_ITusectrl:
	CALL    LCD_Clear2                      ; ask the user for the
	MOV     A,#64                           ; block number
	CALL    LCD_GotoXY                      ;
	MOV     DPTR,#tkc_msg_whatblock         ;
	CALL    LCD_DisplayStringCODE           ;
	MOV     DPSEL,#1
	MOV     DPTR,#buffer
	MOV     DPSEL,#0
	MOV     DPTR,#tkc_blockno
	MOV     R5,#2
	CALL    NUM_NewFormatDecimal16
	MOV     A,#64+21
	CALL    LCD_GotoXY
	MOV     DPTR,#buffer
	MOV     R7,#2
	CALL    LCD_DisplayStringXRAM
	MOV     R7,#3                           ;
	MOV     B,#64+13                        ;
	CALL    NUM_GetNumber                   ;
	JNZ     TKC_ITblockok                   ;
	RET                                     ;

;TKC_ITnoctrl:                  ; COMMENTED OUT BECAUSE IT DOESN'T
;       MOV     A,#1            ; SEEM TO DO ANYTHING!!! LOOK AT
;       RET                     ; CLOSLY IF IT SUBSEQUENTLY STOPS WORKING!

TKC_ITblockok:
	MOV     A,mth_op1ll
	ORL     A,mth_op1lh
	JZ      TKC_ITuselastblock

	MOV     DPTR,#tkc_blockno               ; save block number
	CALL    MTH_StoreWord                   ; for later use
TKC_ITuselastblock:

	ENDIF   ; USE_SEATS

;       MOV     A,#44
;       CALL    DebugTX


	MOV     DPSEL,#0
	MOV     DPTR,#tkt_subtot_current        ; start at first item
	CLR     A                               ; in subtotal table
	MOVX    @DPTR,A                         ;

	MOV     A,#MSG_TSR                      ; setup the MSG_TSR
	MOV     DPTR,#tkc_currenttsr            ;
	MOVX    @DPTR,A                         ;

	MOV     DPTR,#tkt_subtot_entries        ; setup the itemcount
	MOVX    A,@DPTR                         ;
	MOV     DPTR,#tkc_currenttsr+1          ;
	MOVX    @DPTR,A                         ;
	INC     DPTR                            ;

	IF USE_SEATS

	MOV     DPTR,#tkc_fixture               ; setup the fixture number
	CALL    MTH_LoadOp1Word                 ;
	MOV     DPTR,#tkc_currenttsr+2          ;
	CALL    MTH_StoreWord                   ;

	ENDIF

TKC_ITloop:
	MOV     DPSEL,#1
	MOV     DPTR,#tkt_subtot_entries        ; check if more entries
	MOVX    A,@DPTR                         ;
	MOV     B,A                             ;
	MOV     DPTR,#tkt_subtot_current        ;
	MOVX    A,@DPTR                         ;
	CJNE    A,B,TKC_ITmore                  ;
	JMP     TKC_ITflush
TKC_ITmore:
	CALL    TKT_LoadUpTicket
	MOV     DPTR,#tkt_issue_qty
	MOVX    A,@DPTR
	MOV     DPSEL,#0
	MOVX    @DPTR,A                         ; store the qty
	INC     DPTR

	IF USE_SEATS

	MOV     DPSEL,#1
	MOV     DPTR,#tkt_type
	MOVX    A,@DPTR
	MOV     DPSEL,#0
	MOVX    @DPTR,A                         ; store the ticket type
	INC     DPTR
	MOV     DPSEL,#1
	CALL    TKT_TSCtrl
	MOVX    A,@DPTR
	ANL     A,#7
	MOV     DPSEL,#0
	MOVX    @DPTR,A                         ; store the zone
	INC     DPTR
	MOV     DPSEL,#1
	MOV     DPTR,#tkc_blockno
	MOVX    A,@DPTR
	MOV     DPSEL,#0
	MOVX    @DPTR,A                         ; store the block
	INC     DPTR
	MOV     DPSEL,#1
	MOV     DPTR,#tkt_groupqty
	MOVX    A,@DPTR
	MOV     DPSEL,#0
	MOVX    @DPTR,A                         ; store the groupqty
	INC     DPTR

	ENDIF ; USE_SEATS

	MOV     DPSEL,#1
	MOV     DPTR,#tkt_subtot_current
	MOVX    A,@DPTR
	INC     A
	MOVX    @DPTR,A
	JMP     TKC_ITloop

TKC_ITflush:
	CALL    COM_InitRS485
TKC_ITstartwaitpoll:
	IF USE_ALTONCOMMS

;       *****************************************************************
;       *       Tim     3ix99   *****************************************
;       *****************************************************************
;       *       Do not call delay100ms when wanting a master packet. ****
;       *       The master waits a very short time for the reply     ****
;       *       nose DLE_STX to appear. Make the delay consist entirely *
;       *       of polling for an input message up to 65000 approx times*
;       *****************************************************************

;         MOV    R3,#20                 ; _T,3ix99

	 mov    r2,#255                 ; T,3ix99
	 MOV    R3,#255                 ; T,3ix99
	ELSE
	 MOV    R3,#100
	ENDIF
TKC_ITwaitpoll:
;       MOV     A,#133
;       CALL    DebugTX

	CALL    NET_ReceivePacket               ; wait for a general
	JNZ     TKC_ITpolled                    ; request poll
	MOV     R0,#1
;        CALL    delay100ms             ; _T,3ix99
	DJNZ    R3,TKC_ITwaitpoll

	djnz    r2,tkc_itwaitpoll       ; T,3ix99

	IF USE_TIMEOUT = 0
	MOV     R3,#10
TKC_IT_IdleLoop
	 CALL   TKC_Idle                        ;To Avoid TSD Hangup
	 MOV    R0,#1
	 CALL   delay100ms
	 DJNZ   R3,TKC_IT_IdleLoop
	MOV DPTR,#tkc_hangcount
	CALL    MTH_IncWord
;        JMP    TKC_ITstartwaitpoll
	ENDIF

;       MOV     A,#77
;       CALL    DebugTX

	IF USE_ALTONCOMMS
	 CALL   TKC_NetworkFailure

;       *************************************************
;       *       Tim     12viij99        *****Start*******
;       *************************************************
;       *       Flag Transaction Not Responded          *
;       *************************************************

	IF      STARRED_EMERGENCY
	 MOV    DPTR,#ppg_oper_text3  ; Flag FIELD_HEADER
	 MOV    A,#255                ; ON
	 MOVX   @DPTR,A               ; 
	ENDIF

	qinc    tkc_etickets

	IF      EXAR_BARCODE_APPLICATION
	call    CHEETAH_move2StateFinal2
	call    CHEE_Yes
	ENDIF

;       *************************************************
;       *       Tim     12viij99        *****Finish******
;       *************************************************

	 MOV    A,#1
	 RET
	ELSE
	 JMP    TKC_NetworkFailure
	ENDIF

TKC_ITpolled:
	PUSHACC
;       MOV     A,#155
;       CALL    DebugTX
	POP     ACC

;       ***************************************************************
;       *       Tim     30viij99        *************Start*************
;       ***************************************************************
;       *       use a TSD the same as a GRQ                           *
;       *       If you have a TSR pending                             *
;       *       before the master polls all other slaves              *
;       ***************************************************************

	CJNE    a,#MSG_TSD,TKC_ITaintaTSD
	jmp     TKC_SendaTSR
TKC_ITaintaTSD:

;       ***************************************************************
;       *       Tim     30viij99        *************End***************
;       ***************************************************************


	CJNE    A,#MSG_GRQ,TKC_ITreallyshouldbeGRQ    ;
	jmp     TKC_SendaTSR
TKC_ITreallyshouldbeGRQ:
	jmp     TKC_ITshouldbeGRQ
;       ***************************************************************
;       *       Tim     30viij99        *************Start*************
;       ***************************************************************

TKC_SendaTSR:

;       ***************************************************************
;       *       Tim     30viij99        *************End***************
;       ***************************************************************

	MOV     DPTR,#tkc_currenttsr+1          ; send the tsr request
	MOVX    A,@DPTR                         ;
	IF USE_SEATS
	 MOV    B,#5                            ;
	 MUL    AB                              ;
	 INC    A                               ;
	 INC    A                               ;
	ENDIF
	INC     A                               ;
	INC     A                               ;
	
        IF      EXAR_BARCODE_APPLICATION AND BARCODE_FORMAT
	
	mov     b,a                             ; set aside Len=[TSR 01 01]
	mov     dptr,#chee_state                ; pick up the barcode length
	movx    a,@dptr                         ; If BarCode length NonZero
	cjne    a,#CHEETAH_FINAL1,TKC_NoBarCodeToDay 
	inc     dptr
	movx    a,@dptr
	mov     r7,a                            ; Length ASCII bytes 
	call    CHEETAH_Move2StateFinal2        

	IF      BARCODE_FORMAT EQ BINARY72
	
	mov     a,#9                            ; Work all done in CHEETAH.ASM

	ENDIF
	
	
	IF      BARCODE_FORMAT EQ PACKED
	
	mov     prt_field_len,#0                ; Temporary Packed BarCodeLen
	mov     r0,#prt_field_str               ; Borrow Print Buffer
TKC_PackLnibble:        
	inc     dptr                            ; Advance into ASCII Image
	movx    a,@dptr                         ; And Read XRAM
	cjne    a,#ANSII_CR,TKC_PackLLL
	jmp     TKC_LoadBarCodeGo
TKC_PackLLL:        
	anl     a,#15                           ; Isolate Upper Quartet
	swap    a                               ; And Position it
	mov     @r0,a                           ; And Store it in IRAM
	inc     prt_field_len                   ; And Count a Packed Octet
	djnz    r7,TKC_PackRnibble              ; And Advance to Low Quartet
	jmp     TKC_LoadBarCodeGo               ; Or Skip if No More Input
TKC_PackRnibble:        
	inc     dptr                            ; Advance in XRAM Buffer
	movx    a,@dptr                         ; and Read ASCII Digit
	cjne    a,#ANSII_CR,TKC_PackRRR
	jmp     TKC_LoadBarCodeGo
TKC_PackRRR:
	anl     a,#15                           ; Isolate Low Quartet
	orl     a,@r0                           ; And Pair with High Quartet
	mov     @r0,a
	inc     r0                              ; Advance in IRAM Buffer
	djnz    r7,TKC_PackLnibble              ; And Continue if More Input
TKC_LoadBarCodeGo:
	
	mov     r7,prt_field_len                ; Read Count of Packed Octets
	mov     r0,#prt_field_str               ; Address IRAM Buffer
	mov     dptr,#tkc_currenttsr+3          ; Address Packet Buffer
TKC_LoopLoadBarCode:
	mov     a,@r0                           ; Read Packed Octet from IRAM
	movx    @dptr,a                         ; Write to Packet Buffer
	inc     r0                              ; Index Forward Input
	inc     dptr                            ; Index Forward Output
	djnz    r7,TKC_LoopLoadBarCode          ; Until All Copied
	mov     a,prt_field_len                 ; Now Pick Up Length Again
	
	ENDIF
	
	IF      BARCODE_FORMAT EQ ASCII21
	
	mov     a,#21        

	ENDIF

	IF      BARCODE_FORMAT EQ ASCII17

	mov     a,#17

	ENDIF

TKC_NoBarCodeToDay:
	add     a,b                             ; Add Barcode Length If Any
	
        ENDIF

	MOV     R7,A                                                                            ;
TKC_XmitTSR:        
	MOV     DPTR,#tkc_currenttsr            ;
        CALL    DDSNET_TransmitPacket            ;

TSR_RETRY EQU   1
	IF      TSR_RETRY
TKC_ITStartWaitTSI:
	mov     r2,#255
	mov     r3,#255
TKC_ITwaitTSI:
	call    NET_ReceivePacket
	jnz     TKC_ITgotHostResp
	djnz    r3,TKC_ITwaitTSI
	djnz    r2,TKC_ITwaitTSI
	qinc    tkc_etickets
	call    TKC_NetworkFailure
	mov     a,#1
	ret
TKC_ITgotHostResp:
	cjne    a,#MSG_TPI,TKC_ITnotTPI
	mov     dptr,#tkc_recent_tsc
	mov     a,#MSG_TSC
	movx    @dptr,a
	
	mov     r7,#3
        call    DDSNET_TransmitPacket
	jmp     TKC_ITStartWaitTSI
TKC_ITnotTPI:
	cjne    a,#MSG_TSF,TKC_ITnotTSF
	
	IF      EXAR_BARCODE_APPLICATION
	
	mov     a,prt_field_len
	jz      TKC_TSFNotBarCode
	
	IF      ATARI EQ 0
	call    CHEE_No
	ELSE
	call    CHEE_Yes
	

        IF      EXAR_BARCODE_APPLICATION NE 7


        mov     a,#1                    ; Scum Ticket
	mov     dptr,#tkt_type
	movx    @dptr,a
	mov     dptr,#tkt_macrotype
	movx    @dptr,a
	call    TKT_DisplayTicketDesc

	call    KBD_FlushKeyBoard      
	call    PRT_StartPrint         
	call    TKT_PrintTicket
	call    CUT_FireCutter
	call    PRT_EndPrint

	IF      PREPRINT
	call    PRT_StartPrint
	mov     dptr,#tkt_tmpl_text1
	call    PRT_PrintOperatorField
	mov     dptr,#tkt_tmpl_text2
	call    PRT_PrintOperatorField
	call    PRT_EndPrint
	ENDIF
	

        ENDIF


        clr     a
	ret                    
	ENDIF

TKC_TSFNotBarCode:
	
	ENDIF
	
	clr     a
	ret
TKC_SendaTSR2:
	IF      EXAR_BARCODE_APPLICATION
	
	IF      BARCODE_FORMAT EQ BINARY72
	mov     r7,#12
	ENDIF
	IF      BARCODE_FORMAT EQ PACKED
	mov     r7,#10
	ENDIF
	IF      BARCODE_FORMAT EQ ASCII21
	mov     r7,#24
	ENDIF
	IF      BARCODE_FORMAT EQ ASCII17
	mov     r7,#20
	ENDIF

	jmp     TKC_XmitTSR
	ELSE
	jmp     TKC_SendaTSR
	ENDIF
TKC_ITnotTSF:
	cjne    a,#MSG_TSI,TKC_SendaTSR2
	
	
	IF      EXAR_BARCODE_APPLICATION
	
	IF      EXAR_BARCODE_APPLICATION EQ 7
	
	mov     dptr,#buffer+6
	movx    a,@dptr
	mov     dptr,#tkc_itemno
	movx    @dptr,a
	mov     dptr,#tkt_printstatus
	mov     a,#1
	movx    @dptr,a
	jmp     TKC_GNTwaittpi
	
	ENDIF
	
	mov     a,prt_field_len
	jz      TKC_TSINotBarCode
	
	
	call    CHEE_Yes
TKC_TSINotBarCode:
	
	ENDIF
	
	
	jmp     TKC_GNTisTSI
	ELSE
	JMP     TKC_GNTwaittpi                  ;
	ENDIF

TKC_ITshouldbeGRQ:
;       CALL    DebugTX
;       MOV     A,#188
;       CALL    DebugTX

;       ***************************************************************
;       *       Tim     10ix99  ***************************************
;       ***************************************************************
;       *       Host sends IDL instead of ENQ when closed.            *
;       *       This means: "Thou shalt not, before thou dost ask."   *
;       *       However, there is no response to a real TSF, but to   *
;       *       an IDL sent instead of an ENQ, there should be an IDL *
;       *       response.                                             *
;       ***************************************************************

	IF      DUAL_POLL_POLICY
	cjne    A,#MSG_IDL,TKC_ITnotClosed      ;

	MOV     R7,#1                           ; send it back
	MOV     DPTR,#buffer+5                  ;
        CALL    DDSNET_TransmitPacket            ;

	jmp     TKC_GNTisTSF                    ;
TKC_ITnotClosed:
	ENDIF
;       *       Tim     10ix99 End New ********************************

	CJNE    A,#MSG_TSD,TKC_GoBack           ; Test For TSD
						; Got a TSD!
	MOV     R7,#1                           ; send it back
	MOV     DPTR,#buffer+5                  ;
        CALL    DDSNET_TransmitPacket            ;
TKC_GoBack: 
	JMP     TKC_ITwaitpoll

;******************************************************************************
;
; Function:     TKC_GetNextTicket
; Input:        A=1 if last ticket printed ok, else A=0
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

;test: DB 21,'ABCDEFGHIJKLMNOPQRSTU'

TKC_GetNextTicket:

	IF USE_SEATS

	CALL    TKC_CheckTKCtrl                 ; check if we are running
	JNZ     TKC_GNTusectrl                  ; in fail-safe or whether
	MOV     A,#1                            ; we actually want to use
	RET                                     ; the ticketing controller

	ENDIF
	JNZ     TKC_GNT_NoFail                  ;Skip Update of printstatus
TKC_GNTusectrl:
	MOV     DPTR,#tkt_printstatus
	MOVX    @DPTR,A
TKC_GNT_NoFail:
	CALL    COM_InitRS485
TKC_GNTwaittpi:
	IF USE_ALTONCOMMS

;       *****************************************************************
;       *       Tim     3ix99   *****************************************
;       *****************************************************************
;       *       Do not call delay100ms when wanting a master packet. ****
;       *       The master waits a very short time for the reply     ****
;       *       nose DLE_STX to appear. Make the delay consist entirely *
;       *       of polling for an input message up to 65000 approx times*
;       *****************************************************************

	mov     r2,#255             ; T,3ix99
	mov     r3,#255             ; T,3ix99
;         MOV    R3,#20             ; _T,3ix99
	ELSE
	 MOV    R3,#100
	ENDIF
TKC_GNTwaittpiloop:
;       MOV     A,#122
;       CALL    DebugTX

	CALL    NET_ReceivePacket               ; wait to be polled
	JNZ     TKC_GNTgotpkt                   ; with a TPI message
	MOV     R0,#1
;        CALL    delay100ms        ; _T,3ix99
	DJNZ    R3,TKC_GNTwaittpiloop
	djnz    r2,tkc_gntwaittpiloop     ; T,3ix99
	IF USE_TIMEOUT = 0
;        JMP    TKC_GNTwaittpi
	MOV DPTR,#tkc_hangcount
	CALL    MTH_IncWord

	ENDIF

;       MOV     A,#88
;       CALL    DebugTX

	IF USE_ALTONCOMMS
	 CALL   TKC_NetworkFailure
	 CLR    A
	 RET
	ELSE
	 JMP    TKC_NetworkFailure
	ENDIF

TKC_GNTgotpkt:
;       PUSHACC
;       MOV     A,#144
;       CALL    DebugTX
;       POP     ACC

	CJNE    A,#MSG_TPI,TKC_GNTnottpi        ;

;       MOV     A,#199
;       CALL    DebugTX


	MOV     DPTR,#tkc_itemno                ; store the item number
	MOVX    A,@DPTR                         ; from the TSI in the
	MOV     DPTR,#buffer+1                  ; TSC message
	MOVX    @DPTR,A                         ;

	mov     dptr,#tkc_recent_tsc+1          ; T,31i2000
	movx    @dptr,a

	MOV     DPTR,#tkt_printstatus           ; store the print status
	MOVX    A,@DPTR                         ; (A=1=ok, A=0=fail) in
	jz      TKC_GNTwritestatus              ;
	mov     dptr,#tkt_type                  ; 
	movx    a,@dptr
	inc     a
TKC_GNTwritestatus:
	MOV     DPTR,#buffer+2                  ; the TSC message
	MOVX    @DPTR,A                         ;

	mov     dptr,#tkc_recent_tsc+2          ; T,31i2000
	movx    @dptr,a

	MOV     DPTR,#buffer                    ; in buffer and transmit
	MOV     A,#MSG_TSC                      ; the TSC status
	MOVX    @DPTR,A                         ;
	MOV     R7,#3                           ;
        CALL    DDSNET_TransmitPacket            ;
	JNZ     TKC_GNTwaittpi                  ;


;       MOV     A,#177
;       CALL    DebugTX

	RET

TKC_GNTnottpi:
	CJNE    A,#MSG_TSI,TKC_GNTnottsi

;       MOV     A,#211
;       CALL    DebugTX

TKC_GNTisTSI:

	MOV     DPTR,#buffer+6                  ; got a TSI, grab the
	MOVX    A,@DPTR                         ; item number for later use
	MOV     DPTR,#tkc_itemno                ;
	MOVX    @DPTR,A                         ;


	IF USE_SEATS

	MOV     DPTR,#buffer+7                  ; grab the seat row string
	CALL    MEM_SetSource                   ;
	MOVX    A,@DPTR                         ;
	INC     A                               ;
	MOV     R7,A                            ;
	MOV     DPTR,#tkc_seatrow               ;
	CALL    MEM_SetDest                     ;
	CALL    MEM_CopyXRAMtoXRAMsmall         ;

	MOV     DPH,srcDPH                      ; grab the seat col string
	MOV     DPL,srcDPL                      ;
	MOVX    A,@DPTR                         ;
	INC     A                               ;
	MOV     R7,A                            ;
	MOV     DPTR,#tkc_seatcol               ;
	CALL    MEM_SetDest                     ;
	CALL    MEM_CopyXRAMtoXRAMsmall         ;

	MOV     DPH,srcDPH                      ; grab the block name
	MOV     DPL,srcDPL                      ;
	MOVX    A,@DPTR                         ;
	INC     A                               ;
	MOV     R7,A                            ;
	MOV     DPTR,#tkc_seatblock             ;
	CALL    MEM_SetDest                     ;
	CALL    MEM_CopyXRAMtoXRAMsmall         ;

	ELSE
	IF USE_ALTONCOMMS

	; here grab sales data for alton towers style comms

	MOV     DPTR,#buffer+7                  ; grab the date
	MOVX    A,@DPTR
	MOV     DPTR,#datebuffer
	MOVX    @DPTR,A
	MOV     DPTR,#buffer+8
	MOVX    A,@DPTR
	MOV     DPTR,#datebuffer+1
	MOVX    @DPTR,A

	MOV     DPTR,#buffer+9                  ; grab the time
	MOVX    A,@DPTR
	MOV     DPTR,#timebuffer
	MOVX    @DPTR,A
	MOV     DPTR,#buffer+10
	MOVX    A,@DPTR
	MOV     DPTR,#timebuffer+1
	MOVX    @DPTR,A

	MOV     DPTR,#buffer+11                 ; grab the expire hour
	MOVX    A,@DPTR
	PUSHACC
	CALL    TKT_ExpireHour
	POP     ACC
	MOVX    @DPTR,A

	MOV     DPTR,#buffer+12                 ; grab the expire minutes
	MOVX    A,@DPTR
	PUSHACC
	CALL    TKT_ExpireMinute
	POP     ACC
	MOVX    @DPTR,A

;;;;;;;;;;;;;;;;;;;;;;
; SSM additions 7/3/99
;;;;;;;;;;;;;;;;;;;;;;
	MOV     DPTR,#buffer+13                 ; grab "queue until" minutes
	MOVX    A,@DPTR
	MOV     DPTR,#tkt_expireminutes2
	MOVX    @DPTR,A
	MOV     DPTR,#buffer+14                 ; and hours
	MOVX    A,@DPTR
	MOV     DPTR,#tkt_expirehours2
	MOVX    @DPTR,A
;;;;;;;;;;;;;;;;;;;;;;

	ENDIF   ; USE_ALTONCOMMS
	ENDIF   ; USE_SEATS

;       MOV     DPTR,#test
;       CALL    MEM_SetSource
;       MOV     DPTR,#tkc_seatblock
;       CALL    MEM_SetDest
;       MOV     R7,#22
;       CALL    MEM_CopyCODEtoXRAMsmall

	MOV     A,#1                            ; further ticket(s) to print
	RET

TKC_GNTnottsi:
	CJNE    A,#MSG_TSD,TKC_GNTnottsd        ; got a TSD

;       MOV     A,#55
;       CALL    DebugTX

	MOV     R7,#1                           ; send it back
	MOV     DPTR,#buffer+5                  ;
        CALL    DDSNET_TransmitPacket            ;
	CLR     A                               ; ticket printing finished
	RET                                     ;

TKC_GNTnottsd:
	CJNE    A,#MSG_TSF,TKC_GNTnottsf

TKC_GNTisTSF:                                   ; T,10ix99

;       MOV     A,#222
;       CALL    DebugTX

;       CALL    LCD_Clear                       ; got a TSF
;       MOV     DPTR,#buffer+6                  ;
;       MOV     R7,#24                          ;
;       CALL    LCD_DisplayStringXRAM           ;
;       MOV     A,#64                           ;
;       CALL    LCD_GotoXY
;       MOV     DPTR,#buffer+6+24
;       MOV     R7,#24
;       CALL    LCD_DisplayStringXRAM
;       CALL    SND_Warning                     ;
;       CALL    KBD_WaitKey                     ;
	CLR     A                               ; ticket printing finished

;       MOV     A,#66
;       CALL    DebugTX

	RET

TKC_GNTnottsf:
	CJNE    A,MSG_GRQ,TKC_GNTGoBack         ;Test For GRQ
						;Got A GRQ
	MOV     DPTR,#tkc_currenttsr+1          ; send the tsr request
	MOVX    A,@DPTR                         ;
	IF USE_SEATS
	 MOV    B,#5                            ;
	 MUL    AB                              ;
	 INC    A                               ;
	 INC    A                               ;
	ENDIF
	INC     A                               ;
	INC     A                               ;
	MOV     R7,A                                                                            ;
	MOV     DPTR,#tkc_currenttsr            ;
        CALL    DDSNET_TransmitPacket            ;

TKC_GNTGoBack:
	JMP     TKC_GNTwaittpiloop

;******************************************************************************
;
; Function:     TKC_NetworkFailure
; Input:        ?
; Output:       ?
; Preserved:    ?
; Destroyed:    ?
; Description:
;   etc
;
;******************************************************************************

TKC_NetworkFailure:
	IF USE_ALTONCOMMS
	ELSE
	 CALL   SND_Warning
	 CALL   LCD_Clear
	 MOV    DPTR,#tkc_msg_tktctrlfail
	 CALL   LCD_DisplayStringCODE
	 MOV    A,#64
	 CALL   LCD_GotoXY
	 MOV    DPTR,#tkc_msg_tktctrlfail2
	 CALL   LCD_DisplayStringCODE
	 CALL   KBD_WaitKey
	 CLR    A
	ENDIF
	RET

	ENDIF   ; USE_TKTCTRL

	END
;****************************** End Of TKTCTRL.ASM ****************************
;
