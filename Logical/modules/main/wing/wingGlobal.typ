
TYPE
	gWingInterface_typ : 	STRUCT 
		cmd : gWingInterface_cmd_typ;
		parameter : gWingInterface_parameter_typ;
		status : gWingInterface_status_typ;
	END_STRUCT;
	gWingInterface_cmd_typ : 	STRUCT 
		startBrickNOK : BOOL; (*Start wing with NOK brick.*)
		startBrickOK : BOOL; (*Start wing with OK brick.*)
		emptyStart : BOOL;
		emptyStop : BOOL;
		dosing : BOOL;
		shaftModeEmpty : BOOL;
		machineStart : BOOL;
		startManuelMode : BOOL;
		changeMode : BOOL; (*signal from wing -> main to change mode*)
		copyRecipe : copy_recipe_command_typ;
		rejectNextBatch : BOOL; (*Used if we have an aftercount to reject the next batch as well. We both need to reject upper/middle in case of afterCount*)
		disableOptimization : BOOL; (*Used to disable wing flap optimization (FOR TEST)*)
		startBrick : BOOL;
		confirmEmpty : BOOL;
	END_STRUCT;
	gWingInterface_status_typ : 	STRUCT 
		neighbourActive : BOOL;
		ready : BOOL;
		simCassette : BOOL;
		simNeighbour : BOOL;
		request : BOOL;
		commandAck : BOOL;
		startTestSequence : BOOL;
		wingEmpty : BOOL;
		stepperWUConnected : BOOL;
		timeTOF_cassetteSignals : TIME;
	END_STRUCT;
	gWingInterface_parameter_typ : 	STRUCT 
		simulation : BOOL;
	END_STRUCT;
	local_time_typ : 	STRUCT 
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
	gFlap_brick_status_typ : 
		(
		BRICK_STATUS_NOK := 0, (*Reject brick(s)*)
		BRICK_STATUS_OK := 1, (*Good brick(s)*)
		BRICK_STATUS_REJECT_ALL := 2, (*Reject all*)
		BRICK_STATUS_EMPTY := 3, (*Empty mode*)
		BRICK_STATUS_EMPTY_SMALL_ITEMS := 4, (*Empty small items*)
		BRICK_STATUS_EMPTY_END := 5, (*Empty ends*)
		BRICK_STATUS_DOSING := 6, (*Dosing*)
		BRICK_STATUS_DOSING_AND_EMPTY := 7 (*Dosing and empty*)
		);
END_TYPE
