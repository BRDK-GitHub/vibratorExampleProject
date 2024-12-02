
TYPE
	local_typ : 	STRUCT 
		cmd : local_cmd_typ;
		status : local_status_typ;
		opcua : local_opcua_typ;
		hmi : local_hmi_typ;
		internal : local_internal_typ;
		CfgGetIPAddr_0 : CfgGetIPAddr;
	END_STRUCT;
	local_cmd_typ : 	STRUCT 
		updateCurrentPackage : BOOL;
		clearUpdateFolder : BOOL; (*If any update exists delete*)
		writeUpdateInstalledToGateway : BOOL; (*Write bulk to gateway from CM*)
		disconnect : BOOL; (*disconnect client*)
		reset : BOOL; (*Reset client when in error*)
		checkForUpdate : BOOL;
		loadRecipeTemplateFromGateway : BOOL; (*Will load recipe template from gateway.*)
		saveRecipeTemplateFromGateway : BOOL;
		checkForUpdateInstantly : BOOL; (*Will check for update instantly*)
	END_STRUCT;
	local_status_typ : 	STRUCT 
		readyForUpdate : BOOL;
		updateFolderCleared : BOOL; (*Folder is cleared*)
	END_STRUCT;
	local_internal_typ : 	STRUCT 
		DevLink_0 : DevLink;
		DirDeleteEx_0 : DirDeleteEx;
		FileDelete_0 : FileDelete;
		DevUnlink_0 : DevUnlink;
		handleDevLink : UDINT;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		strRecipeTemplate : STRING[30];
		strRecipeTemplateSaveName : STRING[30];
		templateDataProvider : ARRAY[0..MAX_TEMPLATES_IDX]OF STRING[100];
		updateTemplates : BOOL;
		selectedTemplateType : templateType_enum; (*0: 1pcs, 1: 2pcs, 2: 3pcs, 3: 4pcs and 4: Big CM*)
		oldSelectedTemplateType : templateType_enum;
		automatic : local_hmi_automatic_typ;
		strRecipeAutoSaveName : STRING[30];
		strRecipeAutoLoadName : STRING[30];
		updateAllCMs : BOOL;
	END_STRUCT;
	local_hmi_automatic_typ : 	STRUCT 
		save : BOOL;
		load : BOOL;
		overwrite : BOOL;
		alreadyExists : BOOL;
		confirmLoad : BOOL;
		confirmSave : BOOL;
	END_STRUCT;
	local_opcua_typ : 	STRUCT 
		UA_Connect_0 : UA_Connect;
		connectionHdl : DWORD;
		UASessionConnectInfo_0 : UASessionConnectInfo;
		UA_GetNamespaceIndex_0 : UA_GetNamespaceIndex;
		UaClt_WriteBulk_0 : UaClt_WriteBulk;
		UaClt_ReadBulk_0 : UaClt_ReadBulk;
		variablesWrite : ARRAY[0..MAX_UA_VARIABLES]OF STRING[MAX_LENGTH_VARIABLE];
		nodeIDWrite : ARRAY[0..MAX_UA_VARIABLES]OF UANodeID;
		nodeErrorID : ARRAY[0..MAX_UA_VARIABLES]OF DWORD;
		UA_Disconnect_0 : UA_Disconnect;
		actualLocalIpAddress : STRING[15];
		gatewayEndpoint : USINT;
		errorID : DWORD;
		errorRecoverState : UINT;
		namespaceIndex : UINT;
		indexInGatewayIpArray : USINT;
		timerConnectionErrorTimeout : TON;
		UA_ConnectionGetStatus_0 : UA_ConnectionGetStatus;
		connectionStatus : STRING[20];
	END_STRUCT;
	template_recipes_typ : 	STRUCT 
		strArr : ARRAY[0..MAX_TEMPLATES_IDX]OF STRING[30];
	END_STRUCT;
	templateType_enum : 
		(
		ONE_PIECE,
		TWO_PIECE,
		THREE_PIECE,
		FOUR_PIECE,
		BIG_CM
		);
END_TYPE
