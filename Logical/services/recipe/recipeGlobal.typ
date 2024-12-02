
TYPE
	gRecipe_typ : 	STRUCT  (*Global recipe type.*)
		cmd : gRecipe_cmd_typ; (*Command type.*)
		status : gRecipe_status_typ; (*Status type.*)
	END_STRUCT;
	gRecipe_cmd_typ : 	STRUCT  (*Global command type.*)
		load : BOOL; (*Load command.*)
		saveCurrent : BOOL; (*Save current recipe to file of RECIPES partition*)
		save : BOOL; (*Save command.*)
		loadCurrent : BOOL; (*Load current recipe to file of RECIPES partition*)
		brickID : STRING[80]; (*BrickID for the recipe to load.*)
	END_STRUCT;
	gRecipe_status_typ : 	STRUCT  (*Global status type.*)
		saved : BOOL; (*Recipe saved.*)
		loaded : BOOL; (*Recipe loaded.*)
		doCheckForChanges : BOOL;
		newRecipeLoaded : BOOL;
	END_STRUCT;
END_TYPE
