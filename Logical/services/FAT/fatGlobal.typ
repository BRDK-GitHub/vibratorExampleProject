
TYPE
	gFAT_typ : 	STRUCT  (*Global file type.*)
		cmd : gFAT_cmd_typ; (*File command type.*)
		status : gFAT_status_typ; (*File status type.*)
	END_STRUCT;
	gFAT_status_typ : 	STRUCT  (*File status type.*)
		dummy : BOOL; (*File devices are ready to use.*)
	END_STRUCT;
	gFAT_cmd_typ : 	STRUCT  (*File command type.*)
		dummy : BOOL; (*Update file devices command.*)
	END_STRUCT;
END_TYPE
