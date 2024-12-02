
TYPE
	local_alarm_typ : 	STRUCT 
		noisePeakPeak : BOOL;
		noiseOffset : BOOL;
		noiseSpeed : BOOL;
	END_STRUCT;
	local_TOF_typ : 	STRUCT 
		PT : UDINT := 10000; (*10ms*)
		ET : UDINT;
		OUT : BOOL;
	END_STRUCT;
	local_brickDetect_typ : 	STRUCT 
		state : USINT;
		stateDescription : STRING[200];
	END_STRUCT;
	local_typ : 	STRUCT 
		hw : local_hw_typ;
		sim : local_sim_typ;
		WingHwTOFs : ARRAY[0..3]OF local_TOF_typ;
		TON_timeout : TON;
		alarm : local_alarm_typ;
		BrickDetector_0 : BrickDetector;
		BrickIntegral_0 : BrickIntegral;
		integralSum : REAL;
		peakIntegral : ARRAY[0..MAX_PEAKS]OF REAL;
		noPeaks : USINT;
		noVerifiedPeaks : USINT;
		brickError : BOOL := FALSE;
		tmpBrickCount : USINT;
		MTBasicsTimeDelay_capcon : MTBasicsTimeDelay;
		MTFilterMovingAverage_capcon : MTFilterMovingAverage;
		upperIntegralLimit : REAL;
		lowerIntegralLimit : REAL;
		VerifyPeaks_1 : VerifyPeaks;
		VerifyPeaks_0 : VerifyPeaks;
		TON_capconNoise : TON;
		MTDataMinMax_0 : MTDataMinMax;
		CapconNoiseMeassure_0 : CapconNoiseMeassure;
		lastAiSignal : INT;
		TON_0 : TON;
		maxSignal : REAL;
		minSignal : REAL;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		ai_signal : ARRAY[0..1]OF INT; (*Signal name: AI_CCH
PJ95: B400
Connector: AI.01
Description: Analogue signal from Capcon head.*)
		di_middleFlap_change : BOOL;
		di_neigbourFlap_change : BOOL;
		di_bottomFlap_change : BOOL;
		di_upperFlap_change : BOOL;
	END_STRUCT;
	local_sim_typ : 	STRUCT 
		state : UDINT;
		sampleCount : DINT;
		recordCount : DINT;
		sampleDelay : local_time_typ;
	END_STRUCT;
	local_taskTime_typ : 	STRUCT 
		time : UDINT;
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
END_TYPE
