
TYPE
	item_data_typ : 	STRUCT 
		main : item_data_main_typ;
	END_STRUCT;
	item_data_main_typ : 	STRUCT 
		itemNumber : STRING[100]; (*Item number*)
		width : INT; (*[mm] width setting on circular vibrator*)
		height : INT; (*[mm] height setting on circular vibrator*)
		angle : INT;
		useWaitSpeed : BOOL := TRUE; (*0 = suspend machine when capcon is not ready, 1 = use wait speed *)
		itemName : STRING[100]; (*Item name*)
	END_STRUCT;
	item_data_feeder_typ : 	STRUCT 
		levelSensor : INT; (*10=low, 11=middle, 12=high*)
		startDelay : INT; (*ms*)
		stopDelay : INT; (*ms*)
		onTime : INT; (*ms*)
		offTime : INT; (*ms*)
	END_STRUCT;
	method_typ : 	STRUCT 
		copyRecipe : method_copy_recipe_typ;
	END_STRUCT;
	method_copy_recipe_typ : 	STRUCT 
		direction : USINT;
	END_STRUCT;
END_TYPE
