
TYPE
	brdk_update_manager_internal_typ : 	STRUCT  (*Manager internal variables.*)
		state : DINT := 0; (*Internal state.*)
		ArProjectGetInfo_0 : ArProjectGetInfo; (*ArProjectGetInfo.*)
		ArProjectInstallPackage_0 : ArProjectInstallPackage; (*ArProjectInstallPackage.*)
		versionCmp : DINT := 0; (*Version compare.*)
		brdkUpdateCheck_0 : brdkUpdateCheck; (*brdkUpdateCheck.*)
		brdkUpdateDelete_0 : brdkUpdateDelete; (*brdkUpdateDelete.*)
	END_STRUCT;
	brdk_update_manager_run_info_typ : 	STRUCT  (*Information.*)
		id : STRING[255] := ''; (*Unique machine ID.*)
		version : STRING[32] := ''; (*Machine version.*)
	END_STRUCT;
	brdk_update_manager_upd_info_typ : 	STRUCT  (*Information.*)
		status : brdk_update_manager_upd_stat_typ := BRDK_UPDATE_NOT_FOUND; (*Indicates if an update is found on the flash.*)
		id : STRING[255] := ''; (*Unique machine ID.*)
		version : STRING[32] := ''; (*Machine version.*)
		artransferFileSize : UDINT := 0; (*File size of "artransfer.br" in bytes.*)
	END_STRUCT;
	brdk_update_manager_upd_stat_typ : 
		( (*Status of the update package.*)
		BRDK_UPDATE_NOT_FOUND := 0, (*Update package not found.*)
		BRDK_UPDATE_NO_ID_MATCH := 1, (*Configuration ID of the update and machine does not match.*)
		BRDK_UPDATE_VERSION_ERROR_FORMAT := 2, (*Format of the version does not comply with x.x.x.*)
		BRDK_UPDATE_VERSIONS_EQUAL := 3, (*Same version on the update package and the machine.*)
		BRDK_UPDATE_VERSION_NEW_SMALLER := 4, (*Update version smaller than machine version.*)
		BRDK_UPDATE_VERSION_NEW_GREATER := 5 (*Update version greater than machine version.*)
		);
	brdk_update_manager_upd_loc_typ : 
		( (*Location of the update package.*)
		BRDK_UPDATE_LOCATION_USER := 0, (*Update package can both be located on USER partition only.*)
		BRDK_UPDATE_LOCATION_USB := 1 (*Update package can both be located on USB only.*)
		) := BRDK_UPDATE_LOCATION_USER;
	brdk_update_manager_cmd_typ : 	STRUCT  (*Commands.*)
		checkForUpdate : BOOL := FALSE; (*Checks for an update.*)
		update : BOOL := FALSE; (*Update PLC.*)
		updateReboot : BOOL := FALSE; (*Update PLC and rebootPLC afterwards.*)
		deleteUpdate : BOOL := FALSE; (*Deletes an update.*)
		errorReset : BOOL := FALSE; (*Resets errors.*)
	END_STRUCT;
	brdk_update_dist_ftp_int_typ : 	STRUCT  (*Distribute internal variables.*)
		state : DINT := 0; (*Internal state.*)
		DevLink_0 : DevLink; (*DevLink.*)
		DevUnlink_0 : DevUnlink; (*DevUnlink.*)
		FileCopy_0 : FileCopy; (*FileCopy.*)
		DirCopy_0 : DirCopy; (*DirCopy.*)
		cIdx : USINT := 0; (*Client idx.*)
		paramStr : STRING[200] := ''; (*Parameter string.*)
		brdkUpdateCheck_0 : brdkUpdateCheck; (*brdkUpdateCheck.*)
		brdkUpdateDelete_0 : brdkUpdateDelete; (*brdkUpdateDelete.*)
	END_STRUCT;
	brdk_update_dist_ftp_client_typ : 	STRUCT  (*PLC client structure.*)
		pIPAddress : UDINT := 0; (*String pointer to IP address of the PLC client.*)
		pUser : UDINT := 0; (*String pointer to FTP user name.*)
		pPassword : UDINT := 0; (*String pointer to FTP password.*)
	END_STRUCT;
	brdk_update_dist_ftp_cmd_typ : 	STRUCT  (*Command structure.*)
		distributeUpdate : BOOL := FALSE; (*Distributes the update to the clients in the client list.*)
		checkUpdate : BOOL := FALSE; (*Reads the data from the update.*)
		deleteUpdate : BOOL := FALSE; (*Deletes an update.*)
		errorReset : BOOL := FALSE; (*Resets errors.*)
	END_STRUCT;
	brdk_update_check_internal_typ : 	STRUCT  (*Read internal variables.*)
		state : DINT := 0; (*Internal state.*)
		brdkFileRead_0 : brdkFileRead; (*brdkFileRead.*)
		buffer : ARRAY[0..1999]OF USINT; (*Read buffer.*)
		simulation : BOOL := FALSE; (*Simulation active.*)
		ArProjectGetPackageInfo_0 : ArProjectGetPackageInfo; (*ArProjectGetPackageInfo.*)
		position : DINT; (*Find position.*)
		FileInfo_0 : FileInfo; (*Read update file info*)
		updateFileInfo : fiFILE_INFO; (*File info structure*)
	END_STRUCT;
	brdk_update_delete_internal_typ : 	STRUCT  (*Delete internal variables.*)
		state : DINT := 0; (*Internal state.*)
		brdkUpdateCheck_0 : brdkUpdateCheck; (*brdkUpdateCheck.*)
		FileDelete_0 : FileDelete; (*FileDelete.*)
		DirDeleteEx_0 : DirDeleteEx; (*DirDeleteEx.*)
	END_STRUCT;
END_TYPE
