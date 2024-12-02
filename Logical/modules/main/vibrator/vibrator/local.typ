
TYPE
	local_no_opcua_typ : 	STRUCT 
		configOld : config_vibrator_typ;
		recipeOld : recipe_vibrator_typ;
		configTmp : config_vibrator_typ;
		axisAlarmText : STRING[363];
		alarm : local_alarm_typ;
		TON_alarmReaction : TON;
		calibration : local_no_opcua_calibration_typ;
	END_STRUCT;
	local_no_opcua_calibration_typ : 	STRUCT 
		maxAmplitude : REAL;
		maxVibration : REAL;
		stepSizeAmplitude : REAL;
		tmpAmplitude : REAL;
		counter : USINT;
		bufferIdx : UINT;
		countTestPulse : USINT;
		boostCaliDone : BOOL;
		breakCaliDone : BOOL;
		countPulsesToFinetune : USINT;
	END_STRUCT;
	local_typ : 	STRUCT 
		recipeName : STRING[80];
		configName : STRING[80];
		recipeNameCurrent : STRING[80];
		calibration : calibration_typ;
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		time : local_time_typ;
		MTBasicsLimiter_0 : MTBasicsLimiter;
		MC_BR_WriteParID_0 : MC_BR_WriteParID;
		vibAmplitude : REAL;
		highSpeed : BOOL;
		vibPercentAmplitude : REAL; (*amplitude for P3*)
		oldVibPercentAmplitude : REAL;
		vibAcceleration : REAL;
		sweep : local_sweep_typ;
		hmi : hmi_typ;
		vibFrequency : REAL := 50; (*[Hz] Frequency of virator*)
		calibrateState : UDINT;
		rampUp : REAL;
		linearizationSweep : linearizationSweep_typ;
		hw : local_hw_typ;
		linearizationTable : MTLookUpTable;
		lookUpFrequency : MTLookUpTable;
		pointsInLinearization : USINT;
		testAmplitude : BOOL;
		testDefault : BOOL;
		verifyLinearization : ARRAY[0..9]OF REAL;
		verifyIdx : USINT;
		testPercent : BOOL;
		oldSpeed : LEGO_SPEED_ENUM;
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
		minimumTimeInCount : UDINT := 60000;
		DTGetTime_0 : DTGetTime;
		stateSimuPulse : USINT;
		simuTimeInCountSpeed : UDINT := 1000000;
		simuTimeInWaitSpeed : UDINT := 500000;
		simuTimeInStopped : UDINT := 600000;
		testProdFlow : BOOL;
		TON_delay : TON;
		currentAcceleration : REAL;
	END_STRUCT;
	calibration_typ : 	STRUCT 
		TON_0 : TON;
		maxFreq : REAL;
		analogVib : REAL;
		sweepAmpl1CF : REAL := 0.5;
		sweepAmpl2CF : REAL := 0.6;
		sweepAmpl3CF : REAL := 1.0;
		sweepAmpl1LF : REAL := 0.09;
		sweepAmpl2LF : REAL := 0.08;
		sweepAmpl3LF : REAL := 0.11;
		sweepAmpl1LFbig : REAL := 0.1;
		sweepAmpl2LFbig : REAL := 0.08;
		sweepAmpl3LFbig : REAL := 0.11;
		sweepAmpl1CFbig : REAL := 1.7;
		sweepAmpl2CFbig : REAL := 1.4;
		sweepAmpl3CFbig : REAL := 1.8;
		timeToGetVibrWarm : TIME := T#11s;
		maxFreqFastSweep : REAL;
		bypassWarmUp : BOOL;
		slope : REAL;
		minAcceleration : REAL;
		minAccelerationTime : REAL;
		minAccelerationPhaseVelocity : REAL;
		accelerationStart : REAL;
		minAccelerationStart : REAL;
		freqBrakeCaliOffset : REAL;
		minFrequency : REAL;
		accelerationEnd : REAL;
		startBrakeFrequency : REAL;
	END_STRUCT;
	hmi_calibrate_typ : 	STRUCT 
		activate : BOOL;
		calibrationToolPlugged : BOOL;
		progress : USINT;
		percentValue : REAL;
		testBoost : BOOL;
		enableStopButton : BOOL;
		runTestPulses : BOOL;
		increaseBoost : BOOL;
		increaseBrake : BOOL;
		decreaseBoost : BOOL;
		decreaseBrake : BOOL;
		enableBoostBrakeAdjustment : BOOL;
	END_STRUCT;
	linearizationSweep_typ : 	STRUCT 
		actVibOld : REAL;
		sweepIdx : USINT;
		stableTime_TON : TON;
		a : REAL; (*Slope of linear function*)
		b : REAL; (*Intersection with y-axis in linear function*)
		MTBasicsPID_0 : MTBasicsPID;
		countStableSamples : USINT; (*If signal is less than allowed control error count one up.*)
		actIsOverSetValue : BOOL; (*True if act value is over set value.*)
		dcBusVoltage : REAL;
		supplyType : USINT; (*0=230V, 0=110V (Mexico)*)
	END_STRUCT;
	force_hw_typ : 	STRUCT 
		enable : BOOL;
		current : REAL;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		config : config_vibrator_typ;
		calibratingProcessing : BOOL;
		cancelTuning : BOOL;
		recipe : recipe_vibrator_typ;
		calibration : hmi_calibrate_typ;
		force : force_hw_typ;
		needLinearization : BOOL;
		linearizationProcessing : BOOL;
		stopSweep : BOOL;
		oldCfType : SINT;
		actVoltage : REAL;
		targetAcceleration : REAL;
		voltage10Percent : REAL;
		voltage100Percent : REAL;
		recipeCurrent : recipe_vibrator_typ;
		waitSpeedLastBrick : USINT := 5;
		confirmPct : BOOL;
		increaseVibAmplitude : BOOL;
		decreaseVibAmplitude : BOOL;
		increaseVibAmplitudeFast : BOOL;
		decreaseVibAmplitudeFast : BOOL;
		linearizationGoalValue : REAL;
		enableOperatorInput : BOOL;
		showErrorMsgLinearization : BOOL;
		stopLinearization : BOOL;
		fitPercentTooLow : BOOL;
		linearizationActValue : REAL;
		daysSinceCalibration : REAL;
	END_STRUCT;
	local_time_typ : 	STRUCT 
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
	config_vibrator_typ : 	STRUCT 
		tuneOnStartup : BOOL;
		vibFrequency : REAL := 50000;
		maxCurrent : REAL := 2.4;
		maxVoltage : REAL := 200;
		type : SINT; (*0=small CF, 1=big CF*)
		linearizationNodeVectorX : ARRAY[0..49]OF REAL;
		linearizationFcnValues : ARRAY[0..49]OF REAL;
		linearizationAccValues : ARRAY[0..49]OF REAL;
		linearizationFrequency1 : REAL; (*First frequency used for linear function for "voltage,frequency"*)
		linearizationFrequency2 : REAL; (*Second frequency used for linear function for "voltage,frequency"*)
		linearizationVoltage1 : REAL; (*First voltage used for linear function*)
		linearizationVoltage2 : REAL; (*Second voltage used for linear function*)
		pointY1 : REAL := 14;
		pointX1 : REAL := 10;
		pointY2 : REAL := 105;
		pointX2 : REAL := 100;
		Gain : REAL := 0.2;
		IntegrationTime : REAL := 1.5;
		minOut : REAL := 20;
		maxOut : REAL := 200;
		stableWindowPercent : REAL := 0.015;
		linearizeUsing3Points : BOOL := TRUE; (*True = only use 10%,55%,100% for linearization. *)
		frequencyVaryMode : BOOL := TRUE; (*This mode will vary the frequency depending on amplitude used on vibrator*)
		linearizationPercent : ARRAY[0..MAX_LOOKUP_POINTS]OF REAL;
		linearizationCurrent : ARRAY[0..MAX_LOOKUP_POINTS]OF REAL; (*Current at different percentages*)
		linearizationFrequencies : ARRAY[0..MAX_LOOKUP_POINTS]OF REAL; (*Frequency at different amplitudes*)
		linearizationAmplitude : ARRAY[0..MAX_LOOKUP_POINTS]OF REAL; (*Amplitude [A]*)
		fitPercentage : REAL; (*R^2 coefficient*)
		verifyLinearization : ARRAY[0..9]OF REAL;
		linearizationAccValue10pct : REAL;
		linearizationAccValue55pct : REAL;
		linearizationAccValue100pct : REAL;
		amplitudeFineTuning : REAL; (*This value will be add/subtract to the amplitude linearization result in case the calibration is a little off.*)
		emptyPercent : REAL;
		minimumTimeInCount : UDINT := 60000;
		calibrationDateTime : DATE_AND_TIME;
		boostVelocityLow : REAL;
		boostVelocityHigh : REAL;
		brakePhaseShiftVelocity : REAL;
		boostPhaseShiftVelocity : REAL;
		brakeVelocity : REAL;
		boostFrequency : REAL;
		brakeFrequency : REAL;
		boostAmplitude : REAL;
		brakeAmplitude : REAL;
		autoLinearizationAccAtCurrent : ARRAY[0..MAX_IDX_AUTO_LINEARIZATION]OF REAL;
		autoLinearizationCurrent : ARRAY[0..MAX_IDX_AUTO_LINEARIZATION]OF REAL;
		caliPulseBufferAcc : ARRAY[0..MAX_BUFFER_CALI_IDX]OF USINT;
		caliPulseEstimatedPct : ARRAY[0..MAX_BUFFER_CALI_IDX]OF USINT;
		disableLFBoost : BOOL;
	END_STRUCT;
	recipe_vibrator_typ : 	STRUCT 
		waitSpeed : USINT := 10; (*%*)
		countingSpeed : USINT := 30; (*%*)
		rampUp : INT := 0; (*Time for 0 to 100 percent in msec*)
		useWaitSpeedCountingLastElement : BOOL := FALSE; (*If portion >2 and this is TRUE the vibrators will use waitSpeed when counting the last element, but belt will still keep counting speed.*)
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		axisError : gAlarm_struct_typ;
	END_STRUCT;
	local_sweep_typ : 	STRUCT 
		start : BOOL;
		amplitudeCFsmall : REAL := 0.8;
		amplitudeCFlarge : REAL := 1.2;
		amplitudeLF : REAL := 0.1;
		MTDataMinMax_0 : MTDataMinMax;
		frequencyStart : REAL := 48.5;
		frequencyStop : REAL := 50.4;
		maxVibrationISO : REAL;
		maxVibration : REAL;
		freqChangeRate : REAL := 0.02;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		actVib : REAL;
		toggleBit : BOOL; (*Toggle bit will be true when we have new data ready*)
		ISO : REAL;
		analogInput : REAL;
		do_isBigCF : BOOL;
	END_STRUCT;
	axis_typ : 	STRUCT 
		cmd : axis_cmd_typ;
		status : axis_status_typ;
		internal : axis_internal_typ;
	END_STRUCT;
	axis_cmd_typ : 	STRUCT 
		power : BOOL;
	END_STRUCT;
	axis_status_typ : 	STRUCT 
		powerOn : BOOL;
	END_STRUCT;
	axis_internal_typ : 	STRUCT 
		MC_Power_0 : MC_Power;
	END_STRUCT;
	hmi_em_status_typ : 	STRUCT 
		state : brdk_em_states_typ;
		substate : STRING[BRDK_MU_MAX_DESCRIPTION_STRING];
	END_STRUCT;
END_TYPE
