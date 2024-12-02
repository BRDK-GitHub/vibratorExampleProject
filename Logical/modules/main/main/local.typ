
TYPE
	set_mode_typ : 
		(
		STOP := 0,
		PRODUCTION := 1,
		EMPTY_OUT := 2,
		PRE_EMPTY := 3,
		BYPASS_CASSETTE := 4,
		BYPASS_CASSETTE_DISABLE := 5,
		PRE_EMPTY_DISABLE := 6,
		EXTRA := 7
		);
	lamp_color_typ : 
		(
		COLOR_OFF := 0, (*NO COLOR*)
		COLOR_GREEN := 1, (*GREEN*)
		COLOR_RED := 2, (*RED*)
		COLOR_YELLOW := 3, (*YELLOW*)
		COLOR_BLUE := 4, (*BLUE*)
		COLOR_ORANGE := 5, (*ORANGE*)
		COLOR_OWN := 6, (*OWN*)
		COLOR_WHITE := 7 (*WHITE*)
		) := COLOR_OFF;
	lamp_flash_typ : 
		(
		FLASH_PERMANENT := 0,
		FLASH_FLASH := 1, (*Flash every x ms for a timeout duration*)
		FLASH_BLINK := 2 (*Blink every x ms for a count amount*)
		) := FLASH_PERMANENT;
	local_typ : 	STRUCT 
		alarm : local_alarm_typ;
		hw : local_hw_typ;
		TOF_alarmBeaconOn : TOF;
		TON_alarmBeaconOff : TON;
		configName : STRING[80];
		recipeName : STRING[80];
		recipeNameCurrent : STRING[80];
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		hmi : hmi_typ;
		timeElapsed : UDINT;
		recipeOld : recipe_main_typ;
		configOld : config_main_typ;
		newRecipeLoaded : BOOL;
		interface : gMainInterface_typ;
		stopCalibration : BOOL;
		reteach : BOOL;
		oldRemoteCommand : USINT;
		oldItemNumber : STRING[100];
		itemNumber : STRING[100];
		itemTypeId : DINT;
		TON_clearing : TON;
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
		alarmBeaconFlash : BOOL;
		alarmBeaconFlashSlow : BOOL;
		alarmBeaconOn : BOOL;
		TON_0 : TON;
		updateStatus : BOOL;
		oldStopEthIP : BOOL; (*cmd from LineController to CM20*)
		oldStartEthIP : BOOL; (*cmd from LineController to CM20*)
		oldEmptyEthIP : BOOL; (*cmd from LineController to CM20*)
		oldEmptyModeEthIP : BOOL; (*cmd from LineController to CM20*)
		oldBypassCassetteEthIP : BOOL; (*cmd from LineController to CM20*)
		timeElapsedAfterLampCmd : UDINT; (* [us]*)
		countBlinksLamp : UDINT;
		oldSecond : UDINT;
		TON_BalluffLightTowerTest : TON;
		count : USINT;
	END_STRUCT;
	hmi_cmd_typ : 	STRUCT 
		empty : SINT;
		confirm : BOOL;
		stop : BOOL;
		hold : BOOL;
		start : BOOL;
		teach : BOOL;
		rejectAll : USINT;
		redoTeaching : BOOL;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		openConfirmDialog : BOOL;
		recipe : recipe_main_typ;
		cmd : hmi_cmd_typ;
		config : config_main_typ;
		status : USINT;
		state : STRING[80];
		stateTemp : STRING[80];
		recipeCurrent : recipe_main_typ; (*Next recipe data*)
		setMode : USINT;
		mainAborted : BOOL;
		cmType : STRING[10];
		batchId : DINT;
		imageURL : STRING[200];
		itemNumberNext : STRING[100];
		showNextItemNumberLabel : BOOL;
		startLightTowerTest : BOOL;
		alarmBeaconFATTest : BOOL;
	END_STRUCT;
	config_main_typ : 	STRUCT 
		number : DINT;
		version : STRING[80];
		machineType : USINT; (*0 = left, 1 = right*)
		enableExperimental : BOOL;
	END_STRUCT;
	recipe_main_typ : 	STRUCT 
		itemNumber : STRING[100]; (*Item number*)
		width : INT; (*[mm] width setting on circular vibrator*)
		height : INT; (*[mm] height setting on circular vibrator*)
		angle : INT;
		itemName : STRING[100]; (*Item name*)
		itemTypeId : DINT; (*item type/design id of brick. Unique for element design but the same for different colors/decoration*)
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		di_stopButton : BOOL; (*Signal name: DI_CM_STOP
PJ95: NA
Connector: B500
Description: Signal from Stop button*)
		di_startButton : BOOL; (*Signal name: DI_CM_START
PJ95: B501
Connector: NA
Description: Signal from Start button*)
		do_stopButtonIndicator : BOOL; (*Signal name: DO_CM_STOP
PJ95: B502
Connector: NA
Description: Signal to Stop button indicator*)
		do_startButtonIndicator : BOOL; (*Signal name: DO_CM_START
PJ95: B503
Connector: NA
Description: Signal to Start button indicator*)
		do_alarmBeacon : BOOL; (*Signal name: DO_CM_ALARM
PJ95: H100
Connector: DO.04
Description: Signal to alarm beacon*)
		do_wo_ON : BOOL; (*Stepper wu on command*)
		do_clearWU : BOOL;
		di_stepperWUExecute : ARRAY[0..1]OF BOOL;
		output_lightTowerBalluff : USINT;
		input_lightTowerBalluff : USINT;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		KA10 : gAlarm_struct_typ;
		KA11 : gAlarm_struct_typ;
		KA12 : gAlarm_struct_typ;
		KA13 : gAlarm_struct_typ;
		KA14 : gAlarm_struct_typ;
		KA15 : gAlarm_struct_typ;
		KA16 : gAlarm_struct_typ;
		KA17 : gAlarm_struct_typ;
		KA18 : gAlarm_struct_typ;
		KA19 : gAlarm_struct_typ;
		KA20 : gAlarm_struct_typ;
		KA21 : gAlarm_struct_typ;
		KA22 : gAlarm_struct_typ;
		cantEmptyNeedCassette : gAlarm_struct_typ;
		opcuaMethodError : gAlarm_struct_typ;
	END_STRUCT;
	remoteCmd_typ : 	STRUCT 
		bypassCassette : USINT; (*Can be “On” or “Off”.  It is Bypass cassette - CM release cassette without dossing*)
		command : USINT; (*Can be “End”, “Stop”, “Start” or “Empty”.
“End” indicates that counting will cease either when the current counting process has been completed or, if the first element has not yet been counted, immediately.
“Stop” indicates that counting will stop immediately. Any count in progress will be rejected.
“Start” indicates that counting starts if the element quantity is greater than zero.
“Empty” indicates that the counting machine is to be empties for items.*)
	END_STRUCT;
END_TYPE
