
TYPE
	gConfig_typ : 	STRUCT  (*Global config type.*)
		cmd : gConfig_cmd_typ; (*Command type.*)
		status : gConfig_status_typ; (*Status type.*)
	END_STRUCT;
	gConfig_cmd_typ : 	STRUCT  (*Global command type.*)
		load : BOOL; (*Load command.*)
		save : BOOL; (*Save command.*)
	END_STRUCT;
	gConfig_status_typ : 	STRUCT  (*Global status type.*)
		saved : BOOL; (*config saved.*)
		loaded : BOOL; (*config loaded.*)
		doCheckForChanges : BOOL;
		loadInitialValue : ARRAY[0..4]OF BOOL; (*each bool represents [feeder,vibrator,belt,capcon,machine]*)
		factoryReset : ARRAY[0..4]OF BOOL; (*each bool represents [feeder,vibrator,belt,capcon,wing/cassette]*)
	END_STRUCT;
END_TYPE
