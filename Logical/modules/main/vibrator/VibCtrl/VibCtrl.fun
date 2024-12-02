
FUNCTION GetBrakeTimeFromAmplitude : REAL
	VAR_INPUT
		CurrentAmplitude : REAL;
		PercentChange : REAL;
		MachineSize : USINT;
	END_VAR
	VAR
		b : REAL := 40;
	END_VAR
END_FUNCTION

FUNCTION HammingWindow : REAL
	VAR_INPUT
		n : UINT;
		N : UINT;
	END_VAR
END_FUNCTION

FUNCTION GetPhaseTargetFromFrequency : REAL
	VAR_INPUT
		Frequency : REAL;
	END_VAR
END_FUNCTION

FUNCTION GetCurrentFromAmplitude : REAL
	VAR_INPUT
		Amplitude : REAL;
	END_VAR
END_FUNCTION

FUNCTION GetFrequencyFromAmplitude : REAL
	VAR_INPUT
		Amplitude : REAL;
	END_VAR
END_FUNCTION

FUNCTION GetPercentFromAmplitude : REAL
	VAR_INPUT
		Amplitude : REAL;
	END_VAR
END_FUNCTION

FUNCTION GetKpFromPercent : REAL
	VAR_INPUT
		Amplitude : REAL;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK KalmanFilter1D
	VAR_INPUT
		Enable : BOOL;
		Measurement : REAL;
		KalmanGain : REAL;
		ProcessVariance : REAL;
		MeasureVariance : REAL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Prediction : REAL;
		Estimation : REAL;
		ErrorEstimate : REAL;
	END_VAR
	VAR
		state : INT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK PIController
	VAR_INPUT
		Enable : BOOL;
		Hold : BOOL;
		LoopRate : TIME;
		Setpoint : REAL;
		ProcessValue : REAL;
		Kp : REAL;
		Ki : REAL;
		MinOutput : REAL;
		MaxOutput : REAL;
		Integral : REAL;
		Output : REAL;
		FeedForward : REAL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Error : REAL;
	END_VAR
	VAR
		state : INT;
		TON_LoopRate : TON;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK VibFeedbackOld
	VAR_INPUT
		Enable : BOOL;
		Axis : UDINT;
		RunCalculation : BOOL;
		Frequency : REAL;
		Simulation : BOOL;
		SimCurrent : REAL;
		AirgapScale : REAL := 1;
		PhaseOffset : REAL;
		HoldPhase : BOOL;
		current : ARRAY[0..2] OF REAL;
		voltage : ARRAY[0..2] OF REAL;
	END_VAR
	VAR_OUTPUT
		Amplitude : REAL;
		AmplitudeFast : REAL;
		Phase : REAL;
		PhaseFast : REAL;
		PhaseHMI : REAL;
	END_VAR
	VAR
		dt : REAL := 0.0004; (*400�s*)
		state : INT;
		currentLPF : ARRAY[0..2] OF REAL;
		voltageLPF : ARRAY[0..2] OF REAL;
		MC_BR_CyclicRead_0 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_1 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_2 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_3 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_4 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_5 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_6 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_7 : MC_BR_CyclicRead;
		i : INT;
		MTFilterLowPass_2 : MTFilterLowPass;
		MTFilterLowPass_1 : MTFilterLowPass;
		MTFilterLowPass_0 : MTFilterLowPass;
		tmpTime : REAL := 0;
		lastTmpTime : REAL;
		zeroVolt : REAL := 0;
		intVolt : ARRAY[0..2] OF REAL := [3(0)];
		j : USINT;
		phaseFound : BOOL;
		intVoltBuffer : ARRAY[0..255] OF REAL;
		intCurrBuffer : ARRAY[0..255] OF REAL;
		currentLPFBuffer : ARRAY[0..255] OF REAL;
		intEMF : ARRAY[0..255] OF REAL; (*Integral of EMF*)
		intCurr : ARRAY[0..2] OF REAL := [3(0)];
		a : REAL := 0; (*voltage slope*)
		Offshift : USINT := 1; (*Offset for the airgap calculation*)
		lastidx : USINT := 0; (*index to count samples to loop for airgap calculation*)
		peakVib : REAL := 0; (*Peak vibration*)
		res : REAL := 4.2; (*Resistance*)
		lastTmpTimeMinusDt : REAL;
		tmpTimeAirgap : REAL;
		lastsumAirgap : REAL := 0;
		airgap : ARRAY[0..255] OF REAL := [256(0)];
		counter : UINT;
		MTFilterLowPass_Phase : MTFilterLowPass;
		MTFilterLowPass_Ampl : MTFilterLowPass;
		MC_BR_CyclicReadDataInfo_0 : MC_BR_CyclicReadDataInfo;
		airgap1 : REAL;
		airgap2 : REAL;
		tmpAirgapTrace : USINT;
		intCurr1 : REAL;
		intCurr2 : REAL;
		intVolt1 : REAL;
		intVolt2 : REAL;
		voltZeroOffset : REAL;
		currZeroOffset : REAL;
		phaseCalc : REAL;
		setPhase : REAL := 95;
		indexJ : USINT;
		CutOffFrequency : REAL := 150;
		windLenAmp : UINT := 2;
		windLenPhase : UINT := 2;
		MTFilterLowPass_Current : MTFilterLowPass;
		MTFilterLowPass_Frequency : MTFilterLowPass;
		xi : REAL;
		omega : REAL;
		alpha : REAL;
		simCurr10Prc : REAL := 0.4;
		simCurr100Prc : REAL := 1.1;
		simResonance : REAL := 49;
		simPrc : REAL;
		phaseRes : REAL;
		tmpAirgap : REAL;
		MTFilterBandPass_Airgap : MTFilterBandPass;
		MTFilterBandPass_Voltage3rd : MTFilterBandPass;
		windLenAirgap : UINT := 50;
		TimeDelay_0 : TimeDelay;
		TimeDelayVoltage : REAL;
		TON_RunDelay : TON;
		CalcDelay : TIME := T#0ms;
		RunDelay : TIME := T#50ms;
		TON_CalcDelay : TON;
		RawAirgap : BOOL := TRUE;
		meanAirgap : REAL := 3.2;
		KalmanFilter1D_Ampl : KalmanFilter1D;
		MTBasicsDT1_ActAmpl : MTBasicsDT1;
		MTFilterBandPass_AirgapFast : MTFilterBandPass;
		voltage3rdHarmonic : ARRAY[0..255] OF REAL;
		idx : USINT;
		peak3rdHarmonic : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK VibFeedback
	VAR_INPUT
		Enable : BOOL;
		Axis : UDINT;
		VibratorType : USINT;
		Frequency : REAL;
		Amplitude_out : REAL := 0.0;
		HoldPhase : BOOL;
		Braking : BOOL := FALSE;
		BrakingToAmplitudePct : REAL; (*Amplitude that we are currently braking to "open loop".*)
		RawVib : REAL;
		PhaseOffset : REAL := -80;
		Calibrating : BOOL;
		config : REFERENCE TO VibControl_config_typ;
		SinePhase : REAL;
		SineOut : REAL;
		UpdateFilter : BOOL;
		MachineSize : USINT; (*0=Small CM, 1=Big CM*)
	END_VAR
	VAR_OUTPUT
		Amplitude : REAL;
		AmplitudeRaw : REAL;
		AmplitudeGoertzel : REAL;
		AmplitudeFast : REAL;
		Phase : REAL;
		PhaseAcc : REAL;
		PhaseGoertzel : REAL;
		current : ARRAY[0..2] OF REAL;
		voltage : ARRAY[0..2] OF REAL;
		AmplitudeValid : BOOL;
		PhaseValid : BOOL;
		UpdateFilterDone : BOOL;
		ActAmplitudeGoertzel : REAL;
	END_VAR
	VAR
		state : USINT;
		MTFilterBandPass_3rdHarmonic : MTFilterBandPass;
		LookupTbl_Percent : LookupTbl;
		MC_BR_CyclicRead_0 : MC_BR_CyclicRead := (ParID:=14433,DataType:=ncPAR_TYP_REAL);
		MC_BR_CyclicRead_1 : MC_BR_CyclicRead := (ParID:=14425,DataType:=ncPAR_TYP_REAL);
		MC_BR_CyclicRead_2 : MC_BR_CyclicRead := (ParID:=14435,DataType:=ncPAR_TYP_REAL);
		MC_BR_CyclicRead_3 : MC_BR_CyclicRead := (ParID:=14427,DataType:=ncPAR_TYP_REAL);
		i : USINT;
		time : REAL;
		peakVib : REAL;
		peakCurr : REAL;
		cnt : USINT;
		cntAcc : USINT;
		lastBPF : REAL;
		tmpTime : REAL;
		dt : REAL := 0.0004;
		tmpTimeAirgap : REAL;
		lastRawVib : REAL;
		CalcPhasePosAcc : BOOL;
		CalcPhaseNegAcc : BOOL;
		CalcPhasePos : BOOL;
		CalcPhaseNeg : BOOL;
		voltageZeroCrossing : BOOL;
		AmplitudeCurrent : REAL;
		Feedback : REAL;
		tmpTimeAcc : REAL;
		lastTmpTimeAcc : REAL;
		lastCurrAcc : REAL;
		hammingIdx : UINT;
		hammingLength : UINT := 50;
		tmpPhase : REAL;
		feedbackInterpolation : REAL;
		lastSinePhase : REAL;
		MTFilterLowPass_Phase : MTFilterLowPass;
		MTFilterLowPass_Amplitude : MTFilterLowPass;
		oldUpdateFilter : BOOL;
		testPhaseUsingAcc : BOOL;
		hammingWindow : ARRAY[0..MAX_SAMPLES_GOERTZEL] OF REAL;
		j : INT;
		goertzelCount : INT;
		samples : ARRAY[0..MAX_SAMPLES_GOERTZEL] OF REAL;
		samplesCurr : ARRAY[0..MAX_SAMPLES_GOERTZEL] OF REAL;
		goertzelMagPhase_0 : goertzelMagPhase;
		goertzelMagPhase_1 : goertzelMagPhase;
		goertzelMagPhase_2 : goertzelMagPhase;
		goertzelMagPhase_3 : goertzelMagPhase;
		phase : ARRAY[0..3] OF REAL;
		oldGoertzelPhaseStart : REAL;
		goertzelRef : REAL;
		goertzelSignal : REAL;
		goertzelPhase : REAL;
		goertzelScaling : REAL := 1;
		goertzelPhaseStart : REAL;
		goertzelPhaseComp : REAL;
		TON_PhaseValid : TON;
		timeHalfPeriod : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK VibControl
	VAR_INPUT
		Enable : BOOL;
		Calibrate : BOOL;
		Percent : REAL;
		Axis : UDINT;
		ActPhase : REAL;
		ActPhaseAcc : REAL;
		SetAmplitude : REAL;
		ActAmplitude : REAL;
		ActAmplitudeValid : BOOL;
		ManualControl : BOOL;
		ManualCurrent : REAL;
		ManualPercent : REAL;
		ManualFrequency : REAL := 50.0;
		ClosedLoopAmplitude : BOOL;
		ClosedLoopPhase : BOOL;
		VibratorType : USINT;
		MaxCurr : REAL := 1.9;
		AccPercent : REAL;
		config : REFERENCE TO VibControl_config_typ;
		ActPhaseValid : BOOL;
		SaveConfigDone : BOOL;
		UpdateFilterDone : BOOL;
		MachineSize : USINT; (*0=Small CM, 1=Big CM*)
		MinTimeInCount : TIME := T#300ms;
		MinTimeInCountBigCf : TIME;
		RampUp : REAL; (*ms it takes to go from 0% to 100% -> 100ms ex. 100/0.1 = 1000%/s*)
		SendCaliResultToFAT : BOOL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		amplitude_out : REAL;
		frequency_out : REAL;
		Braking : BOOL;
		BrakingToAmplitudePct : REAL; (*Amplitude that we are currently braking to "open loop".*)
		HoldPhase : BOOL;
		CalibrateStatus : STRING[60];
		CalibrateDone : BOOL;
		SinePhase : REAL;
		SineOut : REAL;
		SaveConfig : BOOL;
		UpdateFilter : BOOL;
		TestPulses : BOOL;
	END_VAR
	VAR
		VibOptimizerAmplitude_0 : VibOptimizerAmplitude;
		VibOptimizerFrequency_0 : VibOptimizerFrequency;
		LookupTbl_PhaseTarget : LookupTbl;
		LookupTbl_BoostCurrent : LookupTbl;
		LookupTbl_FreqFromCurrent : LookupTbl;
		LookupTbl_CurrentFromPercent : LookupTbl;
		paramsBoostCurrentLUT : LUT_typ := (X:=[10,20,30,40,50,60,70,80,90,100,10(0.0)],Y:=[0.45,0.6,0.7425,0.8885,1.0345,1.1805,1.3265,1.4725,1.6185,1.7645,10(0.0)]);
		cali : VibControlCalibration_typ;
		state : UINT;
		frequency : REAL;
		SetAmplitudeLatched : REAL;
		time : REAL;
		sin_ref : REAL;
		old_sin : REAL;
		brakeAmplitude : REAL := 0.9;
		phi : REAL;
		sin_out : REAL;
		phaseShift : REAL;
		sin_abs : REAL;
		phaseShiftLocal : REAL;
		MC_BR_CyclicWrite_0 : MC_BR_CyclicWrite;
		FreqLoopRate : TIME := T#50ms;
		PhaseTarget : REAL := 70;
		lastSetAmplitude : REAL;
		lastSetAmplitudeLatched : REAL;
		brakeTime : REAL := 0.2;
		TestNormal : BOOL;
		PIController_Ampl : PIController;
		PIController_Phase : PIController;
		currentZeroCrossing : BOOL;
		zeroCrossingCount : USINT;
		TestProduction : BOOL;
		TransientAmplitudeKp : REAL := 0.02;
		TransientAmplitudeKi : REAL := 0;
		SteadyAmplitudeKp : REAL := 0.01;
		SteadyAmplitudeKi : REAL := 0.000375;
		SteadyLowAmplitudeKp : REAL := 0.004;
		SteadyLowAmplitudeKi : REAL := 0.00015;
		ErrorLimitTansient : REAL;
		ErrorLimitScaling : REAL := 0.9;
		gainState : INT;
		TON_Transient : TON;
		transientSetAmplitude : REAL;
		count : USINT;
		FeedForwardScaling : REAL := 0.98;
		WaitPeriodsAfterBrake : REAL := 4.0;
		LimitValueToUseNormalKpKi : REAL := 15.0;
		BoostAmplitudeLimit : REAL := 2.0;
		AddToBoostCurrent : REAL;
		measureBoostTime : BOOL;
		ErrorTimeout : BOOL;
		MachineType : USINT;
		TON_ControllerStuck : TON;
		i : USINT;
		DevForce : BOOL;
		TON_running : TON;
		MTBasicsLimiter_0 : MTBasicsLimiter;
		SetAmplitudeChange : REAL;
		oldManualPercent : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION SkewedGaussianPDF : REAL
	VAR_INPUT
		x : REAL;
		xi : REAL;
		omega : REAL;
		alpha : REAL;
	END_VAR
	VAR
		tempNormPDF : REAL;
		tempNormCDF : REAL;
		a : REAL;
		sign : INT;
		temp : REAL;
		xPDF : REAL;
		xCDF : REAL;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK TimeDelay
	VAR_INPUT
		Enable : BOOL; (*Enables the function block*)
		In : REAL; (*Input signal*)
		Dt : REAL; (*Sampling period [s]*)
		Delay : REAL; (*Delay [s]*)
	END_VAR
	VAR_OUTPUT
		Out : REAL; (*Delayed signal*)
	END_VAR
	VAR
		lastIn : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION RoundToPrecision : REAL
	VAR_INPUT
		value : REAL;
		precision : INT;
	END_VAR
	VAR
		multiplier : REAL;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK VibOptimizerAmplitude
	VAR_INPUT
		Set : BOOL;
		Get : BOOL;
		Key : REAL; (*Amplitude*)
		Value : REAL; (*Current*)
		VibratorType : USINT;
		paramsCurrentLUT : REFERENCE TO LUT_typ; (*GetCurrentFromAmplitude*)
		Error : REAL;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
	END_VAR
	VAR
		found : BOOL;
		lookup : ARRAY[0..MAX_ELEMENTS] OF lookup_typ;
		i : USINT;
		lastIdx : USINT;
		LookupTbl_Amplitude : LookupTbl;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION GetPhaseDelay : REAL
	VAR_INPUT
		Frequency : REAL;
	END_VAR
	VAR
		w : REAL;
		wc : REAL := 2 * 3.14159 * 150;
		wb : REAL := 2 * 3.14159 * 10;
		A : REAL;
		B : REAL;
		real2 : REAL;
		imag2 : REAL;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK VibOptimizerFrequency
	VAR_INPUT
		Set : BOOL;
		Get : BOOL;
		Reset : BOOL; (*Will reset any saved values.*)
		Key : REAL; (*Amplitude*)
		Value : REAL; (*Current*)
		paramsFrequencyLUT : REFERENCE TO LUT_typ; (*GetFrequencyFromAmplitude*)
		Error : REAL;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
	END_VAR
	VAR
		found : BOOL;
		lookup : ARRAY[0..MAX_ELEMENTS] OF lookup_typ;
		i : USINT;
		lastIdx : USINT;
		LookupTbl_Frequency : LookupTbl;
	END_VAR
END_FUNCTION_BLOCK
