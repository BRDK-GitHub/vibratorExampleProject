
TYPE
	local_typ : 	STRUCT 
		FileInfo_0 : FileInfo;
		configPLCFileInfo : fiFILE_INFO;
		configFT50FileInfo : fiFILE_INFO;
		devLinkFT50_0 : DevLink;
		cifsParamFT50 : STRING[100];
		noConfigExist : BOOL; (*True on boot if PLC has no config to load on FTP and FT50 panel*)
		fileCopy_0 : FileCopy;
		factoryReset : BOOL; (*factory reset all config parameters*)
	END_STRUCT;
END_TYPE
