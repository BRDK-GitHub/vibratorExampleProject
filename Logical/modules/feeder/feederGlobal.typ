
TYPE
	gFeederInterface_typ : 	STRUCT 
		cmd : gFeederInterface_cmd_typ;
		status : gFeederInterface_status_typ;
	END_STRUCT;
	gFeederInterface_cmd_typ : 	STRUCT 
		speed : LEGO_SPEED_ENUM;
		stop : BOOL;
		start : BOOL;
		copyRecipe : copy_recipe_command_typ;
		empty : BOOL; (*OpcUA empty cmd in main needs this to empty feeder*)
		setLevelSensor : ARRAY[0..2]OF BOOL; (*0: Low, 1: Medium, 2: High*)
		startFlapTest : BOOL;
		levelSensorTestActive : BOOL;
	END_STRUCT;
	gFeederInterface_status_typ : 	STRUCT 
		running : BOOL; (*The belt is moving*)
		count : UDINT; (*Count of bricks that has passed through the photo sensor*)
		mode : DINT;
		state : brdk_em_states_typ;
		beltFeederEmpty : BOOL;
		vibratorBowlEmpty : BOOL;
		levelSensorReceiverInBowl : BOOL;
		flapTest : testResult_enum;
	END_STRUCT;
END_TYPE
