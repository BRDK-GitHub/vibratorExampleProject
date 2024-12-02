
TYPE
	gAlarm_status_typ : 	STRUCT  (*Status of the alarm module.*)
		ready : BOOL := FALSE; (*Alarm module is ready to use.*)
	END_STRUCT;
	gAlarm_typ : 	STRUCT  (*Global alarm interface.*)
		status : gAlarm_status_typ; (*Status of the alarm module.*)
		cmd : gAlarm_cmd_typ;
	END_STRUCT;
	gAlarm_struct_typ : 	STRUCT 
		name : STRING[255];
		active : BOOL;
		oldActive : BOOL;
		instanceID : UDINT;
	END_STRUCT;
	gAlarm_cmd_typ : 	STRUCT  (*Commands for alarm module*)
		acknowledgeAll : BOOL; (*Acknowledge all alarms*)
		acknowledge : BOOL; (*Acknowledge selected alarm on HMI*)
		exportLogToCsv : BOOL;
	END_STRUCT;
END_TYPE
