
TYPE
	local_typ : 	STRUCT 
		MpRecipeRegPar_Config : MpRecipeRegPar;
		recipeName : STRING[80];
		configName : STRING[80];
		recipeNameCurrent : STRING[80];
		alarm : local_alarm_typ;
		TON_alarmReaction : TON;
		hmi : hmi_typ; (*DONT USE FOR HMI - This is only kept to allow compatibility with old config files present on machines in production.*)
		configOld : config_vibrator_typ;
		configTmp : config_vibrator_typ;
		oldCheckChangesConfig : BOOL;
		oldLoaded : BOOL;
		axisAlarmText : STRING[363];
		time : local_time_typ;
		MC_BR_WriteParID_0 : MC_BR_WriteParID;
		IsBigCF : BOOL;
		testPulses : BOOL;
		RandomPulses : BOOL;
		PulseWaitAmplitude : REAL := 10;
		PulseAmplitude : REAL := 40;
		TON_PulseTest : TON;
		hw : hw_typ;
		oldRunManualTest : BOOL;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		axisError : gAlarm_struct_typ;
	END_STRUCT;
	local_time_typ : 	STRUCT 
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		config : config_vibrator_typ;
		force : force_hw_typ;
		needLinearization : BOOL;
	END_STRUCT;
	force_hw_typ : 	STRUCT 
		enable : BOOL;
		current : REAL;
	END_STRUCT;
	config_vibrator_typ : 	STRUCT 
		vibFrequency : REAL := 50000;
		type : SINT; (*0=small CF, 1=big CF*)
	END_STRUCT;
	recipe_vibrator_typ : 	STRUCT 
		waitSpeed : USINT := 30; (*%*)
		countingSpeed : USINT := 30; (*%*)
		rampUp : INT := 50; (*Time for 0 to 100 percent in msec*)
		useWaitSpeedCountingLastElement : BOOL := FALSE; (*If portion >2 and this is TRUE the vibrators will use waitSpeed when counting the last element, but belt will still keep counting speed.*)
	END_STRUCT;
	hmi_opcua_typ : 	STRUCT 
		type : SINT; (*0=small CF, 1=big CF*)
		stopCalibration : BOOL;
	END_STRUCT;
	hmi_em_status_typ : 	STRUCT 
		state : brdk_em_states_typ;
		substate : STRING[BRDK_MU_MAX_DESCRIPTION_STRING];
	END_STRUCT;
	hw_typ : 	STRUCT 
		ModuleOkCalibrationTool : BOOL;
		ModuleOkCalibrationToolBusCtrl : BOOL;
	END_STRUCT;
END_TYPE
