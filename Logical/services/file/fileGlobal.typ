
TYPE
	gFile_typ : 	STRUCT  (*Global file type.*)
		cmd : gFile_cmd_typ; (*File command type.*)
		status : gFile_status_typ; (*File status type.*)
	END_STRUCT;
	gFile_status_typ : 	STRUCT  (*File status type.*)
		ready : BOOL; (*File devices are ready to use.*)
	END_STRUCT;
	gFile_cmd_typ : 	STRUCT  (*File command type.*)
		update : BOOL; (*Update file devices command.*)
	END_STRUCT;
END_TYPE
