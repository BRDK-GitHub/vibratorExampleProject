
TYPE
	gMiddleFlapInterface_status_typ : 	STRUCT 
		ready : BOOL;
		readyForStatusChange : BOOL;
		busy : BOOL;
		waitingForBottomOrCassette : BOOL;
		openCloseTime : UDINT;
		active : BOOL;
		lastCycleTime : REAL;
		testResultFAT : BOOL; (*TRUE=good, FALSE=bad*)
	END_STRUCT;
	gMiddleFlapInterface_para_typ : 	STRUCT 
		brickStatus : gFlap_brick_status_typ;
		openTime : UDINT; (*Time the flap stays open*)
		flapTime : UDINT; (*Time that the flap is to open or close*)
		fallTime : UDINT; (*Time that a brick is to fall and be steady*)
		emptySmallItemsTime : UDINT; (*Time for flipping the flap when emptying small items*)
	END_STRUCT;
	gMiddleFlapInterface_cmd_typ : 	STRUCT 
		start : BOOL;
		smallBrick : BOOL;
		updateStatistics : BOOL;
		runFlapContinuously : BOOL;
		open : BOOL; (*wing -> flap to open doing sequence test*)
		manuelMode : BOOL;
		wingTestManual : BOOL;
	END_STRUCT;
	gMiddleFlapInterface_typ : 	STRUCT 
		cmd : gMiddleFlapInterface_cmd_typ;
		parameter : gMiddleFlapInterface_para_typ;
		status : gMiddleFlapInterface_status_typ;
	END_STRUCT;
END_TYPE
