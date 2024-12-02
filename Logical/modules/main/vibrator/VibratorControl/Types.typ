
TYPE
	hmi_typ : 	STRUCT 
		NeedCalibration : BOOL;
		CalibrationStatus : calibrationResult_enum;
		daysSinceCalibration : REAL := 99999;
		calibrationNotActive : BOOL;
		resonanceFrequencyOK : BOOL;
		currentOK : BOOL;
		minCurrent : REAL;
		maxCurrent : REAL;
		minResonanceFrequency : REAL;
		maxResonanceFrequency : REAL;
		frequencyTimes2 : REAL;
	END_STRUCT;
	local_typ : 	STRUCT 
		VibFeedback_0 : VibFeedback;
		VibControl_0 : VibControl;
		Accelerometer_0 : Accelerometer;
		useAccPhase : BOOL;
		MpRecipeRegPar_Config : MpRecipeRegPar;
		VibFeedback_old : VibFeedbackOld;
		configName : STRING[80];
		config : VibControl_config_typ;
		configOld : VibControl_config_typ;
		oldCheckChangesConfig : BOOL;
		timeConfig : UDINT;
		oldLoaded : BOOL;
		stateSave : USINT;
		testAccFeedback : BOOL;
		SaveConfig : BOOL;
	END_STRUCT;
	calibrationResult_enum : 
		(
		CALIBRATION_NOT_DONE := 0,
		SMALL_CF_CALIBRATION_OK := 1,
		SMALL_CF_CALIBRATION_NOK := 2,
		BIG_CF_CALIBRATION_OK := 3,
		BIG_CF_CALIBRATION_NOK := 4,
		LF_CALIBRATION_OK := 5,
		LF_CALIBRATION_NOK := 6
		);
END_TYPE
