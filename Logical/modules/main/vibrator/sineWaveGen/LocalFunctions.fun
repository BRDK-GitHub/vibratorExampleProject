
{REDUND_ERROR} FUNCTION_BLOCK vibratorControl (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL;
		amplitude : REAL;
		percent : REAL;
		vibratorType : USINT;
		machineType : USINT;
		manualFrequency : REAL;
		manualControl : BOOL;
		linearizationAmplitude : ARRAY[0..4] OF REAL;
		linearizationFrequencies : ARRAY[0..4] OF REAL;
		pAxis : UDINT;
		manualBrake : BOOL;
		boostVelocityLow : REAL := 180;
		boostVelocityHigh : REAL;
		brakeVelocity : REAL;
		boostFrequency : REAL;
		brakeFrequency : REAL;
		boostAmplitude : REAL;
		brakeAmplitude : REAL;
		manualBoost : BOOL;
		currAccelerometerValue : REAL;
		currAccelerometerPercent : REAL;
		manualBrakeTime : REAL;
		manualBrakeAmplitudeEnd : REAL;
		manualBrakeFrequencyEnd : REAL;
		activateMinMax : BOOL;
		disableBoost : BOOL;
	END_VAR
	VAR_OUTPUT
		frequency_out : REAL;
		amplitude_out : REAL;
		phaseShift : REAL := 0;
		sin_out : REAL;
		accelerationStart : REAL;
		minAcceleration : REAL;
		minAccelerationTime : REAL;
		caliBoostVelocityLow : REAL;
		caliBoostVelocityHigh : REAL;
		estimatedPercent : REAL;
		minBreakPercent : REAL;
		maxBoostPercent : REAL;
		filteredAccelerometerPercent : REAL;
	END_VAR
	VAR
		state : UINT;
		oldPercent : REAL;
		phi : REAL;
		sine : REAL;
		time : REAL;
		oldMachineType : USINT := 222; (*222 to make sure gets initialized*)
		addBrakeAmplitude : REAL;
		enableBrake : BOOL := TRUE;
		phaseShiftLocal : REAL;
		minBrakeTime : REAL := 0;
		j : UINT;
		MTLookUpTable_0 : MTLookUpTable;
		frequency : REAL;
		MC_BR_CyclicWrite_0 : MC_BR_CyclicWrite;
		old_sin : REAL;
		sin_ref : REAL;
		startPercentBoost : REAL;
		sin_abs : REAL;
		oldVibratorType : USINT;
		brakeStartDelay : REAL;
		brakePercent : REAL;
		timeStart : REAL;
		accelerationStart20pct : REAL;
		MTDataMinMax_0 : MTDataMinMax;
		MTFilterMovingAverage_0 : MTFilterMovingAverage;
		oldCurrAccelerometerValue : REAL;
		boostHighLowSeperatorPercent : REAL := 50.0;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION getPercentFromAcceleration : REAL
	VAR_INPUT
		acc : REAL;
		vibratorType : USINT; (*0=CF, 1=LF*)
		machineType : USINT; (*0=small, 1=big*)
	END_VAR
END_FUNCTION

FUNCTION getAccelerationFromPercent : REAL
	VAR_INPUT
		percent : REAL;
		vibratorType : USINT; (*0=CF, 1=LF*)
		machineType : USINT; (*0=small, 1=big*)
	END_VAR
END_FUNCTION

FUNCTION applyBrake : REAL
	VAR_INPUT
		percent : REAL;
		brakeVelocity : REAL; (*accValue/s*)
		vibratorType : USINT; (*0=CF, 1=LF*)
		machineType : USINT; (*0=small, 1=big*)
	END_VAR
	VAR
		acc : REAL;
		bigBowlChange : REAL := 48000;
	END_VAR
END_FUNCTION

FUNCTION applyBoost : REAL
	VAR_INPUT
		percent : REAL;
		boostVelocity : REAL; (*accValue/s*)
		vibratorType : USINT; (*0=CF, 1=LF*)
		machineType : USINT; (*0=small, 1=big*)
	END_VAR
	VAR
		acc : REAL;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK GetPhaseDifference
	VAR_INPUT
		Enable : BOOL;
		ReferenceSignal : REAL;
		Signal : REAL;
	END_VAR
	VAR_OUTPUT
		Phase : REAL;
		PhaseInv : REAL;
	END_VAR
	VAR
		x : ARRAY[0..MAX_SIGNAL_LENGTH] OF REAL;
		y : ARRAY[0..MAX_SIGNAL_LENGTH] OF REAL;
		r : ARRAY[0..MAX_OUTPUT_LENGTH] OF REAL;
	END_VAR
	VAR CONSTANT
		MAX_SIGNAL_LENGTH : UINT := 19;
		MAX_OUTPUT_LENGTH : UINT := (MAX_SIGNAL_LENGTH*2)+1;
	END_VAR
	VAR
		i : {REDUND_UNREPLICABLE} UINT;
		sum : {REDUND_UNREPLICABLE} REAL;
		offset : {REDUND_UNREPLICABLE} INT;
		j : {REDUND_UNREPLICABLE} UINT;
		maxVal : {REDUND_UNREPLICABLE} REAL;
		maxIdx : {REDUND_UNREPLICABLE} UINT;
		state : UINT;
		idx : UINT;
		minVal : REAL;
		minIdx : UINT;
	END_VAR
END_FUNCTION_BLOCK
