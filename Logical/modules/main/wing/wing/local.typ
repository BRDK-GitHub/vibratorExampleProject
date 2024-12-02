
TYPE
	hmi_typ : 	STRUCT 
		upperAccept : BOOL;
		upperReject : BOOL;
		upperClosed : BOOL;
		upperChangeOverToClosed : BOOL;
		upperChangeOverToOpened : BOOL;
		middleAccept : BOOL;
		middleReject : BOOL;
		middleClosed : BOOL;
		middleChangeOverToClosed : BOOL;
		middleChangeOverToOpened : BOOL;
		bottomAccept : BOOL;
		bottomReject : BOOL;
		bottomOpened : BOOL;
		bottomClosed : BOOL;
		bottomChangeOverToClosed : BOOL;
		bottomChangeOverToOpened : BOOL;
		middleNeighbourAccept : BOOL;
		bottomNeighbourAccept : BOOL;
		bottomNeighbourOpened : BOOL;
		bottomNeighbourClosed : BOOL;
		bottomNeighbourChangeOverToClose : BOOL;
		bottomNeighbourChangeOverToOpen : BOOL;
		cmd : hmi_cmd_typ;
		config : config_wing_typ;
		recipe : recipe_wing_typ;
		cycleTime : REAL;
		cycleTimeTmu : REAL;
		waitTimeUtilisation : REAL;
		recipeCurrent : recipe_wing_typ;
		addFallTimeMs : UDINT;
	END_STRUCT;
	hmi_cmd_typ : 	STRUCT 
		rejectAll : SINT;
	END_STRUCT;
	local_typ : 	STRUCT 
		hw : local_hw_typ;
		alarm : local_alarm_typ;
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		brdkPVLocalVariable_0 : brdkPVLocalVariable;
		time : local_time_typ;
		hmi : hmi_typ;
		configName : STRING[80];
		recipeName : STRING[80];
		recipeNameCurrent : STRING[80];
		configOld : config_wing_typ;
		recipeOld : recipe_wing_typ;
		middelBrickStatusTmp : gFlap_brick_status_typ;
		start : BOOL;
		upperReadyOld : BOOL;
		middleFlapStartOld : BOOL;
		cycleTime : UDINT;
		cycleTimeIdx : USINT;
		cycleTimes : ARRAY[0..9]OF REAL;
		cycleTimesTmu : ARRAY[0..9]OF REAL;
		waitingTimeUtilisation : UDINT;
		waitingTimeIdx : USINT;
		waitingTimeBuffer : ARRAY[0..59]OF REAL;
		waitTime : UDINT;
		waitTimeState : USINT;
		machineStartOld : BOOL;
		utilityBufferActive : BOOL; (*true when utility buffer is active.*)
		blockCycleTime : BOOL; (*if true we don't meassure cycle time*)
		oldEmptyMode : BOOL;
		stateStatisctics : USINT;
		CycleTimeCalc_0 : CycleTimeCalc;
		test : local_test_typ;
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
	END_STRUCT;
	local_test_typ : 	STRUCT 
		startTestSequence : BOOL;
		runUpperFlapContinuously : BOOL;
		runMiddleFlapContinuously : BOOL;
		runBottomFlapContinuously : BOOL;
		state : USINT;
	END_STRUCT;
	flap_ctrl_typ : 	STRUCT 
		state : USINT;
		description : STRING[65];
		ready : BOOL;
		accept : BOOL;
		reject : BOOL;
		fall : BOOL;
		fallTimeLeft : REAL;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		do_active : BOOL; (*Signal name: DO_WU_NCON
PJ95: WU_S
Connector: DO.18
Description: Signal to neighbour CM. �1� means CM is connected and active.*)
		wu_error : ARRAY[0..1]OF BOOL; (*WU_error*)
	END_STRUCT;
	config_wing_typ : 	STRUCT 
		readyDelay : UDINT := 0; (*Delay before the ready seignal is activated.*)
		flapMoveTime : UDINT := 800000; (*Time that the flap is to move.*)
		flapBottomMoveTime : UDINT := 800000; (*Time that the bottom flap is to move.*)
		cassetteDetectTime : UDINT := 20000; (*Time that the cassette ready signal need to be low*)
		cassetteReleaseTime : UDINT := 20000; (*Cassette release time*)
		simCassette : BOOL := FALSE; (*Simulate the cassette*)
		simNeighbour : BOOL := FALSE; (*Simulate the neigbour*)
		emptySmallItemsTime : UDINT := 2000000; (*Time middle flap is closed before letting out  smll itmes for empty.*)
		transmissionDelay : UDINT := 10000;
		startBeltWaitTime : UDINT := 0; (*Normally belt will run when upperFlap close command = TRUE. If this is greater than 0 we will wait that time before telling belt to run.*)
		simWing : BOOL := FALSE;
		timeTOF_cassetteSignals : TIME := T#250ms;
		mediumFlaps : BOOL; (*Required for special element like rubber tires. They need to run a bit slower flaps but "long" flaps reduce cycle time too much*)
		addFallTimeBottom : UDINT := 70000;
	END_STRUCT;
	recipe_wing_typ : 	STRUCT 
		flapOpenTimeMiddle : recipe_flap_open_time_typ; (*Time that the flaps stays open for normal bricks.*)
		flapOpenTimeUpper : recipe_flap_open_time_typ; (*Time that the flaps stays open for normal bricks.*)
		flapOpenTimeBottom : recipe_flap_open_time_typ;
		fallTimeUM : UDINT := 100000;
		fallTimeBottom : UDINT := 100000; (*Time to fall from middle to bottom flap*)
		longBrick : BOOL;
		fallTimeBottomLong : UDINT := 460000;
		fallTimeBottomNormal : UDINT := 260000;
	END_STRUCT;
	neighbourState_typ : 
		(
		NEIGHBOUR_NOT_ACTIVE := 0,
		NEIGHBOUR_ACTIVE := 1
		);
	local_alarm_typ : 	STRUCT 
		dummy : USINT;
	END_STRUCT;
	local_time_typ : 	STRUCT 
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
	recipe_flap_open_time_typ : 	STRUCT 
		normal : UDINT := 110000;
		Long : UDINT := 360000;
	END_STRUCT;
END_TYPE
