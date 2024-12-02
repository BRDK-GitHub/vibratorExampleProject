
TYPE
	gMachineInterface_typ : 	STRUCT 
		cmd : gMachineInterface_cmd_typ;
		parameter : gMachineInterface_parameter_typ;
		status : gMachineInterface_status_typ;
	END_STRUCT;
	gMachineInterface_cmd_typ : 	STRUCT 
		saveConfigToT50 : BOOL;
		requestSaveToT50 : BOOL; (*request will wait untill config is saved and then trigger the "final cmd to saveConfig"*)
		digitalSiloCmdActive : BOOL; (*main -> udpClient (receive heatbeat so we can blink at the same time)*)
		serialNoDINT : DINT; (*FAT settings serial number*)
	END_STRUCT;
	gMachineInterface_status_typ : 	STRUCT 
		configSavedToT50 : BOOL;
		imageServerURL : STRING[150];
		heartBeatFromGateway : UDINT;
		machineNotInProduction : BOOL;
	END_STRUCT;
	gMachineInterface_parameter_typ : 	STRUCT 
		actualServerIP : STRING[20];
	END_STRUCT;
END_TYPE
