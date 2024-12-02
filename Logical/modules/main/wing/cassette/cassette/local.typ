
TYPE
	local_alarm_typ : 	STRUCT 
		dummy : gAlarm_struct_typ;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		bottomNeighbourAccept : BOOL;
		status : USINT;
		waitForPortion : REAL;
		releaseCassette : REAL;
		waitForNeighbour : REAL;
		waitForQueue : REAL;
		waitForCassette : REAL;
		cycleTime : REAL;
		cycleTimeStopStation : REAL;
		cassettesReleased : UDINT;
		cassetteReadySensor : BOOL;
		cassetteQueueSensor : BOOL;
		di_cassetteReady_TOF : BOOL;
		di_cassetteQueue_TOF : BOOL;
		do_dosingForce : BOOL;
		do_bricksReadyInCassetteForce : BOOL;
	END_STRUCT;
	local_stat_typ : 	STRUCT 
		realeaseCassette : UDINT;
		waitForCassette : UDINT;
		cassetteQueue : UDINT;
		waitForPortion : UDINT;
		waitForNeighbour : UDINT;
	END_STRUCT;
	local_typ : 	STRUCT 
		hw : local_hw_typ;
		hwAir : local_hw_typ;
		hwWu : ARRAY[0..1]OF wu20_typ;
		hmi : hmi_typ;
		time : local_time_typ;
		alarm : local_alarm_typ;
		testSimCassetteReady : BOOL;
		TON_0 : TON;
		statistics : local_stat_typ;
		CassetteSync_0 : CassetteSync;
		CassetteUtilization_0 : CassetteUtilization;
		cassetteCounter : USINT;
		TOF_cassetteReady : TOF;
		TOF_cassetteQueue : TOF;
		FlowMeasure_0 : FlowMeasure;
		oldCassetteReady : BOOL;
		TON_test : TON;
	END_STRUCT;
	wu20_typ : 	STRUCT 
		di_cassetteQueue : BOOL;
		di_neighbourActive : BOOL;
		di_cassetteReady : BOOL;
		di_neighbourIsDosing : BOOL;
		di_neighbourBricksInCassette : BOOL;
		do_active : BOOL; (*Alway true*)
		di_wingUnitActive : BOOL;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		di_cassetteReady : BOOL; (*Signal name: DI_WU_CRDY
PJ95: WU_S
Connector: DI.15
Description: Signal from Shaft. Indicating a cassette is ready at the shaft. “0” indicates a cassette is ready*)
		di_cassetteQueue : BOOL; (*Signal name: DI_WU_CQUE
PJ95: WU_S
Connector: DI.14
Description: Signal from Shaft. Indicating a cassette queue on the transfer system after the CM. “0” indicates cassette queuing up.*)
		di_neighbourBricksInCassette : BOOL; (*Signal name: DI_WU_NCRDY
PJ95: WU_S
Connector: DI.17
Description: Signal from neighbour CM. “0” indicates elements from neighbour shaft are ready in cassette. Utilized for synchronization cassette stop with neighbour CM. Only relevant if DI_WU_NCON is active.*)
		do_cassetteRelease : BOOL; (*Signal name: DO_WU_CREL
PJ95: WU_S
Connector: DO.19
Description: Signal to shaft cassette stop. “1” means cassette is released*)
		do_bricksReadyInCassette : BOOL; (*Signal name: DO_WU_NCRDY
PJ95: WU_S
Connector: DO.17
Description: Signal to neighbour CM. “1” means elements from shaft are ready in cassette. Utilized for synchronization cassette stop with neighbour CM.*)
		di_neighbourActive : BOOL; (*Signal name: DI_WU_NCON
PJ95: WU_S
Connector: DI.18
Description: Signal from neighbour CM. “1” indicates a neighbour CM is connected and active.*)
		di_neighbourIsDosing : BOOL; (*Signal name: DI_WU_NDO
PJ95: WU_S
Connector: DI.08
Description: Signal from neighbour CM. “1” indicates a neighbour CM is dosing meaning empty cassettes are released. Only relevant if DI_WU_NCON is active*)
		do_dosing : BOOL; (*Signal name: DO_WU_NDO
PJ95: WU_S
Connector: DO.22
Description: Signal to neighbour CM. “1” indicates CM is dosing meaning empty cassettes are released*)
		do_testCassetteReady : BOOL;
	END_STRUCT;
END_TYPE
