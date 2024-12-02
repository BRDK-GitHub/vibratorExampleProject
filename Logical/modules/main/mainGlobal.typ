
TYPE
	gMainInterface_line_typ : 	STRUCT 
		start : BOOL;
		empty : BOOL;
		emptyMode : BOOL;
		bypassCassette : BOOL;
	END_STRUCT;
	gMainInterface_typ : 	STRUCT 
		cmd : gMainInterface_cmd_typ;
		status : gMainInterface_status_typ;
		line : gMainInterface_line_typ;
	END_STRUCT;
	gMainInterface_cmd_typ : 	STRUCT 
		brickAtSensor : BOOL;
		capconReady : BOOL;
		state : BOOL;
		count : UDINT;
		validationTotalCount : UDINT;
		validationGoodBrick : BOOL;
		validationBadBrick : BOOL;
		capconWaiting : BOOL;
		activateCalibrateMode : ARRAY[0..20]OF BOOL;
		copyRecipe : copy_recipe_command_typ;
		wingReadyToEmpty : BOOL;
		loadingTemplateRecipe : BOOL;
		stopEthIP : BOOL; (*cmd from LineController to CM20*)
		startEthIP : BOOL; (*cmd from LineController to CM20*)
		emptyEthIP : BOOL; (*cmd from LineController to CM20*)
		emptyModeEthIP : BOOL; (*cmd from LineController to CM20*)
		bypassCassetteEthIP : BOOL; (*cmd from LineController to CM20*)
	END_STRUCT;
	gMainInterface_status_typ : 	STRUCT 
		start : BOOL;
		simulation : BOOL;
		emMode : DINT;
		count : USINT;
		totalCount : UDINT;
		dpMin : REAL;
		doLinearization : BOOL;
		doCalibrate : BOOL;
		feederStop : BOOL;
		feederStart : BOOL;
		emptying : BOOL;
		machineStart : BOOL;
		machineFirstStart : BOOL; (*will be true first time main goes into STATE_STARTING*)
		itemNumber : STRING[20];
		itemTypeId : DINT; (*item type/design id of brick. Unique for element design but the same for different colors/decoration*)
		statusIT : gMainInterface_statusIT_typ;
		state : brdk_em_states_typ;
		machineDirection : USINT; (*0=left , 1=right*)
		machineType : USINT;
	END_STRUCT;
	gMainInterface_statusIT_typ : 	STRUCT 
		Connected : BOOL;
		ItemNumber : UDINT;
		ItemType : UDINT;
		PortionItemCount : INT;
		SerialNo : UDINT;
		Type : INT;
		Version : STRING[20];
		BypassCassette : BOOL;
		Command : INT; (*// 0: DEACTIVATED, 1: STOPPED, 2: EMPTYING, 3: PRODUCTION, 4: DOSING *)
	END_STRUCT;
END_TYPE
