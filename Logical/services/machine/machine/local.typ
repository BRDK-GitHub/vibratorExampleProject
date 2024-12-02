
TYPE
	config_machine_typ : 	STRUCT 
		setLocalIpAddress : STRING[15];
		setGatewayAddress : STRING[15];
		setServerIpAddress : STRING[15];
		ntpServerIpAddress : STRING[40] := 'time.corp.lego.com';
		softwareVersion : STRING[15];
		dhcpEnabled : BOOL;
		serialNumber : DINT;
		selectedLanguage : STRING[40] := 'en'; (*Language selected on the hmi*)
		imageServerURL : STRING[150] := 'https://ip.cz.pac.corp.lego.com/image-service/api/itemimage/getitemimagedata/';
		machineNotInProduction : BOOL;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		setLocalIp : BOOL;
		setServerIp : BOOL;
		setGateway : BOOL;
		setNtpClient : BOOL;
		reboot : BOOL;
		reset : BOOL;
		actualLocalIpAddress : STRING[15];
		actualServerIpAddress : STRING[15];
		actualGatewayAddress : STRING[15];
		openRebootDialog : BOOL;
		confirmReboot : BOOL;
		config : config_machine_typ;
		lineID : STRING[80];
		stringNo : USINT;
		showIpSettings : BOOL;
		version : STRING[50];
		loginTriggered : BOOL;
	END_STRUCT;
	local_typ : 	STRUCT 
		forceOutputsFB : ARRAY[0..MAX_FORCE_OUTPUTS]OF brdkSimInput;
		CfgGetIPAddr_0 : CfgGetIPAddr;
		CfgSetIPAddr_0 : CfgSetIPAddr;
		CfgSetDefaultGateway_0 : CfgSetDefaultGateway;
		CfgSetNtpClient_0 : CfgSetNtpClient;
		CfgSetSubnetMask_0 : CfgSetSubnetMask;
		hmi : hmi_typ;
		CfgGetDefaultGateway_0 : CfgGetDefaultGateway;
		configOld : config_machine_typ;
		MpRecipeRegPar_Config : MpRecipeRegPar;
		configName : STRING[80];
		setFromConfig : BOOL;
		CfgGetEthConfigMode_0 : CfgGetEthConfigMode;
		CfgSetEthConfigMode_0 : CfgSetEthConfigMode;
		errorActive : BOOL;
		TON_updateIp : TON; (*In DHCP mode we need to read the IP with a certain interval*)
		tmpString : STRING[15];
		dhcpOnBootAndConfigIsStatic : BOOL; (*Special case to handle if dhcp on boot but config is manually set.*)
		DTGetTime_0 : DTGetTime;
		warmRestartWU : BOOL;
		oldCheckChangesConfig : BOOL;
		oldLoaded : BOOL;
		DTSetTime_0 : DTSetTime;
	END_STRUCT;
END_TYPE
