
TYPE
	gBottomFlapInterface_status_typ : 	STRUCT 
		ready2 : BOOL;
		ready1 : BOOL;
		openCloseTime : UDINT;
		active : BOOL;
		waitingForNeighbour : BOOL;
		emptyReady : BOOL;
		approvedPortion : BOOL;
		neighbourWaiting : BOOL;
		neighbourDisappeared : BOOL;
		testResultFAT : BOOL; (*TRUE=good, FALSE=bad*)
	END_STRUCT;
	gBottomFlapInterface_para_typ : 	STRUCT 
		brickStatus : gFlap_brick_status_typ;
		openTime : UDINT; (*Time the flap stays open*)
		flapTime : UDINT; (*Time that the flap is to open or close*)
		fallTime : UDINT; (*Time that a brick is to fall and be steady*)
		cassetteStartDelay : UDINT; (*Delay time of start cassette*)
		transmissionDelay : UDINT; (*Delay time of transmission to neighbour machine*)
		shaftMode : gBottomShaftMode_typ; (*Shaft mode can either be normal of empty*)
	END_STRUCT;
	gBottomFlapInterface_cmd_typ : 	STRUCT 
		start1 : BOOL;
		start2 : BOOL;
		empty : BOOL;
		updateStatistics : BOOL;
		runFlapContinuously : BOOL;
		open : BOOL; (*Manuel mode to open flap from wing task.*)
		waitModeChange : BOOL; (*When changing to empty mode bottomFlap must wait a delay to make sure the 2 machines both have same mode.*)
		resetCassetteWaitTime : BOOL; (*Capcon -> bottomFlap. We teach a new brick please reset the wait time for cassette.*)
		brickStatusReady : BOOL;
		manuelMode : BOOL;
		wingTestManual : BOOL;
	END_STRUCT;
	gBottomFlapInterface_typ : 	STRUCT 
		cmd : gBottomFlapInterface_cmd_typ;
		parameter : gBottomFlapInterface_para_typ;
		status : gBottomFlapInterface_status_typ;
	END_STRUCT;
	gBottomShaftMode_typ : 
		(
		SHAFT_MODE_NORMAL, (*If shaft mode is normal then stage change to I070 where portion of items is transferred to bottom flap before waiting for cassette is ready *)
		SHAFT_MODE_EMPTY (*If shaft mode is empty then stage change to I100 where bottom flap is waiting for cassette is ready before portion of items is transferred to bottom flap *)
		);
END_TYPE
