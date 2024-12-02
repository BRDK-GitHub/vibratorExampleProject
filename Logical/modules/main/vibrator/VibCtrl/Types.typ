
TYPE
	lookup_typ : 	STRUCT 
		key : REAL;
		value : REAL;
		error : REAL;
	END_STRUCT;
	VibControlCalibration_typ : 	STRUCT 
		sweepAmplitude : REAL;
		sweepAmplitudeBigCF : REAL;
		MTDataStatistics_0 : MTDataStatistics;
		sweepTimeSteps : REAL := 0.3;
		sweepMaxAmplitude : REAL;
		sweepMaxFrequency : REAL;
		sweepMaxPhase : REAL;
		freqStepSize : REAL := 0.1;
		freqStepSizeSmall : REAL := 0.02;
		phaseStepSize : REAL := 2.50;
		stepTimeAmplitude : REAL := 4.0;
		startAmplitude : REAL := 0.3;
		stopAmplitude : REAL;
		stepSizeAmplitude : REAL := 0.1;
		setAmplitude : REAL;
		timePulseTest : REAL;
		bestTimePulseTest : REAL := 9999;
		startPulseTime : BOOL;
		saveMax : BOOL;
		sweepEndFrequency : REAL;
		countPulses : USINT;
		bestBoostCurrent : REAL;
	END_STRUCT;
	VibControl_config_typ : 	STRUCT 
		MachineSize : USINT; (*0=Small CM, 1=Big CM*)
		lookUpPercentFromAmplitude : LUT_typ;
		lookUpCurrentFromPercent : LUT_typ;
		lookupFrequencyFromPercent : LUT_typ;
		lookupPhaseTargetFromPercent : LUT_typ;
		lookupFrequencyFromCurrent : LUT_typ;
		lookupBoostCurrentFromPercent : LUT_typ := (X:=[10,20,40,60,80,100,14(0.0)],Y:=[1.7,1.5,1.3,1.2,2(1.1),14(0.0)]);
		maxFrequencySweep : REAL;
		maxFrequencySweep2 : REAL;
		maxPhaseSweep : REAL;
		maxCurrentUsed : REAL;
		centerFrequencyBPF : REAL := 75.0;
		machineType : USINT; (*0=small bowl , 1=big bowl*)
		AddToBoostCurrentAt60pct : REAL; (*Current that was added to boost current at 60% (because we use 60% in calibration)*)
		boostCurrentScale : REAL := 1.4; (*Factor to scale ex. 0.10 which means that all boost currents will be scaled with +10% (could also be negative)*)
		OffsetBoostAmplitude : REAL;
		PhaseTarget : REAL := 70.0;
		emptyPercent : REAL;
		timeBoostCalibration : REAL;
		LUTsDescending : BOOL; (*TRUE if 1 or more LUTs are descending which is wrong!*)
		minTimeInCount : TIME := T#250ms;
		minTimeInCountBigCf : TIME := T#400ms;
		vibratorIsCalibrated : BOOL;
		ressonanceFrequencyAt45Pct : REAL; (*mechanical frequency = 2 * output frequnecy*)
		timeInCalibrationSeconds : REAL;
		calibrationDone : BOOL;
	END_STRUCT;
END_TYPE
