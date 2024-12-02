
TYPE
	gVibratorInterface_typ : 	STRUCT 
		cmd : gVibratorInterface_cmd_typ;
		parameter : gVibratorInterface_parameter_typ;
		status : gVibratorInterface_status_typ;
	END_STRUCT;
	gVibratorInterface_cmd_typ : 	STRUCT 
		speed : LEGO_SPEED_ENUM;
		calibrate : BOOL;
		copyRecipe : copy_recipe_command_typ;
		useWaitSpeed : BOOL; (*belt -> vibrator . Use waitSpeed even though belt is using countSpeed.*)
		monitorHighestAmplitude : BOOL; (*Will monitor highest analog acc value on accelerometer.*)
		readCurrentAndVoltage : BOOL;
		monitorActPeakValue : BOOL;
		monitorMaxPeakValue : BOOL;
		calibrationDone : BOOL;
		testPulses : BOOL;
		emptyPercent : REAL;
		reduceCountspeedWith5 : BOOL;
		runManualTest : BOOL;
		putRecipeForStalkElement : BOOL;
		initRecipe : BOOL;
		setCfType : BOOL;
	END_STRUCT;
	gVibratorInterface_parameter_typ : 	STRUCT 
		speedPctManualTest : REAL;
		machineSize : USINT; (*0=Small CM, 1=Big CM*)
		CFType : USINT;
	END_STRUCT;
	gVibratorInterface_status_typ : 	STRUCT 
		start : BOOL;
		calibrationDone : BOOL;
		calibratingMode : BOOL;
		machineType : SINT; (*0=small CM20, 1=big CM20*)
		highestAmplitudeAnalog : REAL;
		highestAmplitudeISO : REAL;
		highestAmplitudePeak : REAL;
		highestFrequencyAnalog : REAL;
		highestFrequencyISO : REAL;
		highestFrequencyPeak : REAL;
		highestAmplitude : REAL;
		highestFrequency : REAL;
		New_Member : USINT;
		actCurr : REAL;
		maxPeakValue : REAL;
		waitSpeed : USINT;
		countingSpeed : USINT;
		vibFrequency : REAL;
		vibAmplitude : REAL;
		vibAmplitudePercent : REAL;
		forcing : BOOL;
		percent : REAL;
		linearizationAmplitude : ARRAY[0..4]OF REAL;
		linearizationFrequencies : ARRAY[0..4]OF REAL;
		powered : BOOL;
		currAccelerometerPercent : REAL;
		currAccelerometerValue : REAL;
		calibrateBoost : BOOL;
		calibrateBrake : BOOL;
		brakePhaseShiftVelocity : REAL;
		boostPhaseShiftVelocity : REAL;
		minAccelerationStart : REAL;
		minAcceleration : REAL;
		minAccelerationTime : REAL;
		boostFrequency : REAL;
		brakeFrequency : REAL;
		brakeVelocity : REAL;
		boostVelocityLow : REAL;
		boostVelocityHigh : REAL;
		caliBoostVelocityLow : REAL;
		caliBoostVelocityHigh : REAL;
		calibrateBraketime : REAL;
		calibrateBrakeAmplitudeEnd : REAL;
		calibrateBrakeFrequencyEnd : REAL;
		boostAmpltiude : REAL;
		brakeAmplitude : REAL;
		caliProdTest : BOOL;
		currEstimatedPercent : REAL;
		isBigCF : BOOL;
		maxBoostPercent : REAL;
		minBreakPercent : REAL;
		filteredAccelerometerPercent : REAL;
		disableLFBoost : BOOL;
		rampUp : INT;
		calibrationResultFrequency : REAL;
		calibrationResultCurrent : REAL;
		calibrationResultCurrentOK : BOOL;
		calibrationResultFrequencyOK : BOOL;
		calibrationResultsReady : BOOL;
	END_STRUCT;
END_TYPE
