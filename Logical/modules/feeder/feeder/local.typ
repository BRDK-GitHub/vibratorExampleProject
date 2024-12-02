
TYPE
	config_feeder_typ : 	STRUCT 
		alarmLowLevelTime : UDINT := 15000000;
		overCurrentProtectTime : TIME := T#400ms;
		maxOpenCloseTime : TIME := T#8s;
		experimentalRefilling : BOOL;
	END_STRUCT;
	flap_typ : 	STRUCT 
		state : flap_state_typ;
		internal : flap_internal_typ;
		cmd : flap_cmd_typ;
	END_STRUCT;
	flap_cmd_typ : 	STRUCT 
		open : BOOL;
		close : BOOL;
	END_STRUCT;
	flap_internal_typ : 	STRUCT 
		TON_maxCloseTime : TON;
		TON_maxOpenTime : TON;
		TON_delaySwitch : TON;
		TON_overCurrentProtect : TON;
		oldState : flap_state_typ;
	END_STRUCT;
	flap_state_typ : 
		(
		FEEDER_FLAP_IDLE := 0,
		FEEDER_FLAP_OPENING := 1,
		FEEDER_FLAP_OPENED := 2,
		FEEDER_FLAP_CLOSING := 3,
		FEEDER_FLAP_CLOSED := 4
		);
	belt_typ : 	STRUCT 
		state : belt_state_typ;
		internal : belt_internal_typ;
		cmd : belt_cmd_typ;
	END_STRUCT;
	belt_cmd_typ : 	STRUCT 
		forwards : BOOL;
		backwards : BOOL;
	END_STRUCT;
	belt_state_typ : 
		(
		FEEDER_BELT_IDLE := 0,
		FEEDER_BELT_FORWARDS := 1,
		FEEDER_BELT_BACKWARDS := 2
		);
	belt_internal_typ : 	STRUCT 
		TON_delaySwitch : TON;
		oldState : flap_state_typ;
	END_STRUCT;
	hmi_cmd_typ : 	STRUCT 
		stop : BOOL;
		empty : BOOL;
		confirmEmpty : BOOL; (*If user press confirm button before BF has been emptied, BF should exit "STATE_COMPLETING" and be ready for production. Otherwise BF will be stuck*)
		enable : BOOL := TRUE; (*Enable/disable BF*)
		forceForwards : BOOL;
		forceBackwards : BOOL;
		expFillingVisible : BOOL;
		stopFlapTest : BOOL;
	END_STRUCT;
	hmi_status_typ : 	STRUCT 
		running : BOOL;
		flapOpen : BOOL;
		flapClose : BOOL;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		status : hmi_status_typ;
		cmd : hmi_cmd_typ;
		config : config_feeder_typ;
		recipe : recipe_feeder_typ;
		recipeCurrent : recipe_feeder_typ;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		lowLevel : gAlarm_struct_typ;
		boxMissing : gAlarm_struct_typ;
		cannotCloseFlap : gAlarm_struct_typ;
		cannotOpenFlap : gAlarm_struct_typ;
		beltFeederEmpty : gAlarm_struct_typ;
		TON_timeout : TON := (PT:=T#20s);
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		di_levelSensorBelt : BOOL; (*Signal name: DI_BF_LEV
PJ95: BF_S
Connector: DI.20
Description: Signal from belt feeder BF91. ”1” indicates level transmitter is activated*)
		di_boxIsReadyAtFlap : BOOL; (*Signal name: DI_BF_BOX
PJ95: BF_S
Connector: DI.21
Description: Signal form belt feeder BF91. ”1” indicates a box is ready at the belt feeder empty flap*)
		di_flapIsClosed : BOOL; (*Signal name: DI_BF_FC
PJ95: BF_S
Connector: DI.22
Description: Signal from belt feeder BF91. ”1” indicates empty flap is closed*)
		di_flapIsOpen : BOOL; (*Signal name: DI_BF_FO
PJ95: BF_S
Connector: DI.23
Description: Signal from belt feeder BF91. ”0” indicates empty flap is open*)
		do_beltForwards : BOOL; (*Signal name: DO_BF_FW
PJ95: BF_P
Connector: DO.20
Description: Signal to belt feeder: “1” means belt is driven forward if a BF91 is connected (DI_BF_91 is activated). “1” means power supply activated if a BF87 is connected (DI_BF_91 is not activated)*)
		do_beltBackwards : BOOL; (*Signal name: DO_BF_BW
PJ95: BF_P
Connector: DO.21
Description: Signal to belt feeder: “1” means belt is driven backwards if a BF91 is connected (DI_BF_91 is activated). “1” means belt is activated if a BF87 is connected (DI_BF_91 is not activated)*)
		di_levelSensorInBowl : BOOL; (*Signal name: DI_CF_LEV
PJ95: B100
Connector: DI.04
Description: Signal from CF. “0” indicates level receiver in CF is low*)
		do_levelSensorInBowlLow : BOOL; (*Signal name: DO_CF_LL
PJ95: B101
Connector: DO.01
Description: Signal to CF. “1” means low level transmitter is activated*)
		do_levelSensorInBowlMedium : BOOL; (*Signal name: DO_CF_LM
PJ95: B102
Connector: DO.02
Description: Signal to CF. “1” means medium level transmitter is activated*)
		do_levelSensorInBowlHigh : BOOL; (*Signal name: DO_CF_LH
PJ95: B103
Connector: DO.03
Description: Signal to CF. “1” means high level transmitter is activated*)
		do_flapOpen : BOOL;
		do_flapClose : BOOL;
	END_STRUCT;
	local_typ : 	STRUCT 
		belt : belt_typ;
		flap : flap_typ;
		alarm : local_alarm_typ;
		hw : local_hw_typ;
		configName : STRING[80];
		recipeName : STRING[80];
		recipeNameCurrent : STRING[80];
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		hmi : hmi_typ;
		configOld : config_feeder_typ;
		recipeOld : recipe_feeder_typ;
		TON_lowLevel : TON;
		TON_timeout : TON := (PT:=T#10s);
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
		lowLevelTime : UDINT;
		TON_VibratorBowlEmpty : TON;
		RTInfo_0 : RTInfo;
		startCounter : UDINT;
		onCounter : UDINT;
		offCounter : UDINT;
		stopCounter : UDINT;
		TON_startDelay : TON;
		state : USINT;
		testTimeout : TON;
	END_STRUCT;
	recipe_feeder_typ : 	STRUCT 
		levelSensor : INT; (*10=low, 11=middle, 12=high*)
		startDelay : INT := 500; (*ms*)
		stopDelay : INT := 10; (*ms*)
		onTime : INT := 1000; (*ms*)
		offTime : INT := 300; (*ms*)
	END_STRUCT;
END_TYPE
