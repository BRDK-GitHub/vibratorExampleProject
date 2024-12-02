
TYPE
	gSimCapcon_typ : 	STRUCT 
		cmd : gSimCapcon_cmd_typ; (*Command type.*)
		status : gSimCapcon_status_typ; (*Status type.*)
		parameter : gSimCapcon_parameter_typ;
	END_STRUCT;
	gSimCapcon_cmd_typ : 	STRUCT  (*Global command type.*)
		readFile : BOOL;
	END_STRUCT;
	gSimCapcon_status_typ : 	STRUCT  (*Global status type.*)
		data : gSimCapcon_data_typ;
		simSignal : INT;
	END_STRUCT;
	gSimCapcon_parameter_typ : 	STRUCT 
		fileName : STRING[200];
	END_STRUCT;
	gSimCapcon_data_typ : 	STRUCT 
		record : ARRAY[0..CAPCON_LOG_RECORD_SIZE]OF gSimCapcon_data_record_typ;
	END_STRUCT;
	gSimCapcon_data_record_typ : 	STRUCT 
		value : ARRAY[0..CAPCON_LOG_SAMPLE_SIZE]OF INT;
	END_STRUCT;
END_TYPE
