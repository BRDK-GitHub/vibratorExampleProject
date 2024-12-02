
TYPE
	local_typ : 	STRUCT 
		internal : local_internal_typ;
		hmi : local_hmi_typ;
	END_STRUCT;
	local_internal_typ : 	STRUCT 
		DevLink_0 : DevLink;
		FileCopy_0 : FileCopy;
		DevUnlink_0 : DevUnlink;
		reset : BOOL;
		cifsParamFT50 : STRING[120];
		handleDevlinkFT50 : UDINT;
		handleDevlinkPLC : UDINT;
		fileNameSrc : STRING[40];
		fileNameDest : STRING[40];
		ftpParamPLC : STRING[120];
		devLinkFT50exists : BOOL;
		devLinkPLCexists : BOOL;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		status : USINT; (*0: not done, 1: success, 2: error*)
		cantConnectToFT50 : BOOL;
	END_STRUCT;
END_TYPE
