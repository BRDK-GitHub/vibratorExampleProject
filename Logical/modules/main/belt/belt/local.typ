
TYPE
	local_teach_typ : 	STRUCT 
		beltBackwardSpeed : INT := -40;
		beltSpeed : INT;
		beltBackwardTimeout : UDINT := 3000;
		capconTimeout : UDINT := 1500;
		attemptCount : USINT;
		TON_timeout : TON;
	END_STRUCT;
	hmi_calibrating_typ : 	STRUCT 
		savePwmValueFor0mmPerSec : BOOL;
		savePwmValueFor100mmPerSec : BOOL;
		savePwmValueFor300mmPerSec : BOOL;
		savePwmValueFor500mmPerSec : BOOL;
		activate : BOOL;
		pwmValue : REAL;
		setSpeed : REAL := 200;
	END_STRUCT;
	hmi_force_hw_typ : 	STRUCT 
		PWM : REAL;
		speed : REAL;
		enable : BOOL;
	END_STRUCT;
	local_typ : 	STRUCT 
		TON_missingElements : TON;
		setSpeed : REAL; (*speed in mm/s*)
		oldSpeed : REAL; (*speed in mm/s*)
		actualSpeed : REAL; (*speed in mm/s*)
		pwmSpeed : REAL; (*converted speed from mm/s to pwm value %*)
		alarm : local_alarm_typ;
		hw : local_hw_typ;
		limiterState : USINT;
		configName : STRING[80];
		recipeName : STRING[80];
		recipeNameCurrent : STRING[80];
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		MTBasicsLimiter_0 : MTBasicsLimiter;
		highSpeed : BOOL;
		teach : local_teach_typ;
		configOld : config_belt_typ;
		recipeOld : recipe_belt_typ;
		hmi : hmi_typ;
		TON_stopDelay : TON;
		TON_startDelay : TON;
		rampDown : REAL;
		rampUp : REAL;
		currentCount : UDINT;
		updateSpeedState : USINT;
		speedOld : LEGO_SPEED_ENUM;
		speedOldManual : REAL;
		oldForceSpeed : REAL;
		oldForceActive : BOOL;
		capconNoStopDelay : UDINT; (*Time for no stop delay in capcon config*)
		MC_BR_ReadParID_277 : MC_BR_ReadParID; (*Motor torque*)
		motorTorque : REAL;
		MTDataMean_torque : MTDataMean;
		timeElapsed : UDINT;
		MC_LimitLoad_0 : MC_LimitLoad;
		abortedDoingTorqueTest : BOOL;
		distBetweenBricksFIFO : ARRAY[0..9]OF REAL; (*10 values in FIFO.*)
		previousEncPos : REAL;
		fifoIdx : USINT;
		distanceMovedSinceHighSignal : REAL;
		actPosAfterLastBrickInPortion : REAL; (*Position of axis after the last brick in portion (used to make sure that axis move a certain distance before stopping).*)
		forceBeltToRun : BOOL; (*Will force belt to run*)
		TON_alarmReaction : TON;
		brickDetected : BOOL;
		BrickDetector_0 : BrickDetector;
		BrickInfo_0 : BrickInfo;
		BrickCounter_0 : BrickCounter;
		oldDropBrick : BOOL;
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
		axisAlarmText : STRING[363];
		RampUpTimeCalc_0 : RampUpTimeCalc;
		changeOverCounter : UDINT;
		timeBeltStoppedButVibrRunning : UDINT;
		oldPosition : LREAL;
		minMillimeterInCount : LREAL := 8.0;
		timeMinInCount : UDINT;
		SpeedRippleCalc_0 : SpeedRippleCalc;
		speedRippleChanged : BOOL;
		TON_speedRipple : TON;
		CFController_0 : CFController;
		LFController_0 : LFController;
		MC_BR_WriteParID_0 : MC_BR_WriteParID;
		TON_testDelay : TON;
		stateAxisDirection : USINT;
		oldMachineType : USINT;
		GetBrickGapTargetMinMax_0 : GetBrickGapTargetMinMax;
		portionLength : REAL;
		changeOverTriggered : BOOL;
		TON_photoSensorTest : TON;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		calibrating : hmi_calibrating_typ;
		config : config_belt_typ;
		recipe : recipe_belt_typ;
		mode : LEGO_SPEED_ENUM;
		status : USINT;
		statusFAT : hmi_status_FAT_typ;
		force : hmi_force_hw_typ;
		recipeCurrent : recipe_belt_typ;
		avgMotorTorque : REAL;
		waitSpeedDisabled : BOOL; (*Used for a warning if wait speed is disabled*)
		avgDistanceBetweenBricks : REAL;
		brickLength : REAL;
		enableAutoMode : BOOL;
		targetBrickGap : REAL;
		showHighWaitspeedAlarm : BOOL;
		rampUpTime : REAL;
		itemGapTeaching : BOOL;
		enableStaticMode : BOOL;
		showPermanentAutoModeButton : BOOL;
	END_STRUCT;
	hmi_status_FAT_typ : 	STRUCT 
		photoSensorTestActive : BOOL; (*Used to open/close dialog in HMI*)
		torqueTestMaxProgress : UDINT;
		torqueTestProgress : UDINT;
		photoSensorTestNoBeltRunning : BOOL;
		photoSensorTestProgress : REAL;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		pwm : {REDUND_UNREPLICABLE} local_hw_pwm_typ; (*Signal name: PWM_BELT
PJ95: M300
Connector: PWM.1
Description: Signal to belt. Motor driver for belt motor*)
		di_photo : BOOL; (*Signal name: DI_CH
PJ95: B300
Connector: DI.01
Description: Signal from Counting head. “1” indicates an element on the belt is passing the counting head*)
	END_STRUCT;
	config_belt_typ : 	STRUCT 
		maxTorqueAllowed : REAL := 0.7;
		flickeringFilterGap : REAL := 2.0; (*used when itemGap is disabled*)
		flickeringFilterGapLong : REAL := 4.0; (*used when itemGap is enabled*)
		speedRipple : REAL;
		offsetFromLfCountSpeed : REAL := -20.0;
		hideExperimentalFeatures : BOOL := TRUE;
		brickGapLfMin1Portion : REAL := 35;
		brickGapLfMin2Portion : REAL := 35;
		brickGapLfMin3Portion : REAL := 30;
		brickGapLfMin4Portion : REAL := 30;
		cycleTimeToStopAutoMode1 : REAL := 55;
		cycleTimeToStopAutoMode2 : REAL := 48;
		cycleTimeToStopAutoMode3 : REAL := 43;
		cycleTimeToStopAutoMode4 : REAL := 39;
		brickGapCfMax1Portion : REAL := 130;
		brickGapCfMax2Portion : REAL := 100;
		brickGapCfMax3Portion : REAL := 60;
		brickGapCfMax4Portion : REAL := 52;
		enablePermanentAutoMode : BOOL;
		enableAutoModeFeature : BOOL;
	END_STRUCT;
	recipe_belt_typ : 	STRUCT 
		countingSpeed : INT := 300; (*mm/s*)
		waitSpeed : INT := 110; (*mm/s*)
		itemGap : BOOL := FALSE;
		useWaitSpeed : BOOL := TRUE;
		rampUp : INT := 50; (*ms*)
		rampDown : INT := 30; (*ms*)
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		beltBlocked : gAlarm_struct_typ;
		pwmOverVoltage : gAlarm_struct_typ;
		pwmOverTemperature : gAlarm_struct_typ;
		pwmOperatingError : gAlarm_struct_typ;
		pwmCurrentError : gAlarm_struct_typ;
		pwmOverCurrent : gAlarm_struct_typ;
		axisError : gAlarm_struct_typ;
		missingElements : gAlarm_struct_typ;
		pwmModule : gAlarm_struct_typ;
	END_STRUCT;
	local_hw_pwm_typ : 	STRUCT 
		periodDuration : UINT;
		pulseWidth : INT;
		clearError : BOOL;
		moduleOk : BOOL;
	END_STRUCT;
END_TYPE
