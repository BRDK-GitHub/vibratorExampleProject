
TYPE
	gData_typ : 	STRUCT  (*Global recipe type.*)
		cmd : gData_cmd_typ; (*Command type.*)
		status : gData_status_typ; (*Status type.*)
	END_STRUCT;
	gData_cmd_typ : 	STRUCT  (*Global command type.*)
		numberOfSamples : UDINT := 250;
		triggerRecord : BOOL;
		exportRecord : BOOL;
		humanDecision : BOOL;
		machineDecision : BOOL;
		startRecord : BOOL;
		enable : BOOL;
	END_STRUCT;
	gData_status_typ : 	STRUCT  (*Global status type.*)
		running : BOOL := TRUE;
		active : BOOL;
		enoughFreeMem : BOOL; (*Will be false if we have less than 10 MiB freemem*)
	END_STRUCT;
END_TYPE
