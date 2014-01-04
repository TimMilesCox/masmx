;*******************************************************************************
;
; File     : CUSTOPTS.INC
;
; Author   : Stephen Macdonald
;
; Project  : Desktop range of ticket printers
;
; Contents : This file contains the default compile options for customers
;
; System   : 80C537
;
; History  :
;   Date     Who Ver  Comments
;
; Notes    :
;
; 1) PRT_CLAA must be used throughout. PRT_CLBM is the STORM 12v mech and the
;    code has not been maintained since day 1 since we now look unlikely to
;    use this printer on DT.
; 2) Only DT10 and DT10W can have BARCODES, RS485, TKTCTRL or SLAVE enabled.
; 3) If DT10W enabled, set NARROWBAND accordingly
; 4) If a VT1, set DT10 and VT1
;******************************************************************************

	IF USE_DDS_DT10
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT10_NETWORK
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT5
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 1 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 0 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT5_NETWORK
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 1 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 0 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT10W
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 1 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT10W_NETWORK
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 1 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 0 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT10W_NARROW
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 1 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 1 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_DDS_DT10W_NETWORK_NARROW
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 0 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 1 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_NARROWBAND  EQU 1 ; define if DT10W is a narrow bander (else wide bander)
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_PAIGNTON
USE_DDS         EQU 0
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_METROLAND
USE_DDS         EQU 0
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 1 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_POWERSCOURT
USE_DDS         EQU 0
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_BEDFORD
USE_DDS         EQU 0
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 1 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 1 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_ALTON
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 0 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 1 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; alton towers fast comms (doesn't work)
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_SEAT_DEMO
USE_DDS         EQU 1
PRT_CLAA        EQU 1 ; --\ define either CLAA or CLBM printer mech
PRT_CLBM        EQU 0 ; --/ (CLBM has not been maintained...needs mods)
DT10            EQU 1 ; --\ define either DT10 or DT5 or DT10W
DT5             EQU 0 ; --| depending on the
DT10W           EQU 0 ; --/ type of machine
VT1             EQU 0 ; define if machine is a vending machine (DT10 only)
DT_TEST         EQU 0 ; define only for TEST PROM
USE_BARCODES    EQU 1 ; define if machine is capable of printing barcodes
USE_UPLOAD      EQU 0 ; define if this DT is connected to an RS485 network
USE_SLAVE       EQU 0 ; define if this DT is controlling another machine
USE_SEATS       EQU 1 ; define if seat allocation is required
USE_ALTONCOMMS  EQU 0 ; define if alton towers style time delay comms req'd
USE_ALTON_FAST  EQU 0 ; define if alton towers style time delay comms req'd
;;;SLAVE_NODE_SHIFT EQU 29 ; gap between DT10's and slave DT10W's node numbers
	ENDIF

	IF USE_SEATS++USE_ALTONCOMMS
USE_TKTCTRL     EQU 1
	ELSE
USE_TKTCTRL     EQU 0
	ENDIF

	IF USE_UPLOAD++USE_TKTCTRL++USE_ALTON_FAST
USE_RS485       EQU 1
	ELSE
USE_RS485       EQU 0
	ENDIF

;****************************** End Of CUSTOPTS.INC ****************************
