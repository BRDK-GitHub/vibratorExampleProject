
TYPE
	gUpperFlapInterface_status_typ : 	STRUCT 
		ready : BOOL;
		request : BOOL;
		openCloseTime : UDINT;
		active : BOOL;
		countAftercount : UDINT;
		OKPortions : UDINT;
		NOKPortions : UDINT;
		lastCycleTime : UDINT;
		testResultFAT : BOOL; (*TRUE=good, FALSE=bad*)
	END_STRUCT;
	gUpperFlapInterface_para_typ : 	STRUCT 
		brickStatus : gFlap_brick_status_typ;
		openTime : UDINT; (*Time the flap stays open*)
		flapTime : UDINT; (*Time that the flap is to open or close*)
		startBeltWaitTime : UDINT;
	END_STRUCT;
	gUpperFlapInterface_cmd_typ : 	STRUCT 
		start : BOOL;
		runFlapContinuously : BOOL;
		open : BOOL; (*wing -> flap to open doing sequence test*)
		brickStatusReady : BOOL;
		manuelMode : BOOL;
		resetStatistics : BOOL;
		wingTestManual : BOOL;
	END_STRUCT;
	gUpperFlapInterface_typ : 	STRUCT 
		cmd : gUpperFlapInterface_cmd_typ;
		parameter : gUpperFlapInterface_para_typ;
		status : gUpperFlapInterface_status_typ;
	END_STRUCT;
END_TYPE
