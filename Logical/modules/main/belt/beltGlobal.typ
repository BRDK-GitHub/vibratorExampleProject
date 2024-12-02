
TYPE
	gBeltInterface_typ : 	STRUCT 
		cmd : gBeltInterface_cmd_typ;
		status : gBeltInterface_status_typ;
		parameter : gBeltInterface_par_typ;
	END_STRUCT;
	gBeltInterface_cmd_typ : 	STRUCT 
		count : BOOL;
		calibrate : BOOL;
		dropBrick : BOOL;
		emptyStop : BOOL;
		capconTimeOut : BOOL; (*capcon -> belt. Belt signaled that capcon should get a brick but it never arrived, signal back to belt that the brick never arrived.*)
		copyRecipe : copy_recipe_command_typ;
		afterCount : BOOL; (*capcon -> belt. We just had an aftercount*)
		runManualTest : BOOL;
		putRecipeForStalkElement : BOOL;
		initRecipe : BOOL;
		changeover : BOOL; (*vibrator -> belt. We have changeover and recipe values has been updated.*)
		cycleTimeCount : UDINT;
		stopDoingEmpty : BOOL;
		setDirection : BOOL;
		doPhotoSensorTest : BOOL;
		doPhotoSensorTestNoBelt : BOOL;
		doTorqueTest : BOOL;
	END_STRUCT;
	gBeltInterface_par_typ : 	STRUCT 
		brickCountInPortion : UDINT;
		speedManualTest : REAL;
		direction : USINT;
	END_STRUCT;
	gBeltInterface_status_typ : 	STRUCT 
		running : BOOL; (*The belt is moving*)
		countingDone : BOOL;
		teachingDone : BOOL;
		speed : LEGO_SPEED_ENUM;
		calibratingMode : BOOL;
		bricksInPortion : INT;
		useVibratorWaitSpeed : BOOL;
		dropBrickDone : BOOL;
		adjustPercent : SINT;
		autoMode : BOOL;
		CFCountSpeed : REAL;
		CFWaitSpeed : REAL;
		LFCountSpeed : REAL;
		LFWaitSpeed : REAL;
		gapOK : BOOL;
		autoModeSimple : BOOL;
		actualPosition : REAL;
		recipeLoaded : BOOL;
		photoSensorTestResult : testResult_enum;
		torqueTestTestResult : testResult_enum;
		photoSensorTestNoBeltResult : testResult_enum;
	END_STRUCT;
	testResult_enum : 
		( (*Enum to get feedback if test is OK or NOK*)
		TEST_NOT_DONE := 0,
		TEST_OK := 1,
		TEST_NOT_OK := 2,
		TEST_STOPPED := 3
		);
END_TYPE
