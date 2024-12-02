
FUNCTION_BLOCK brdkUpdateCheck (*Reads the information from an update package.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pFileDevice : UDINT := 0; (*String pointer for file device. Can be created with brdkFilelibrary.*)
	END_VAR
	VAR_OUTPUT
		updateFolderPath : STRING[255] := ''; (*Path of the update folder.*)
		pipFilePath : STRING[255] := ''; (*Path of the pipconfig.xml file.*)
		artransferFilePath : STRING[255] := ''; (*Filepath to "artransfer.br" file*)
		version : STRING[32] := ''; (*Update version number.*)
		id : STRING[255] := ''; (*Update configuration ID.*)
		artransferFileSize : UDINT := 0; (*Update file "artransfer.br" size in bytes.*)
		status : DINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
	END_VAR
	VAR
		internal : brdk_update_check_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION brdkUpdateCmpVersion : DINT (*Can compare two version strings. The version string must comply with Semantic Versioning x.x.x. $RETURN=result/error;1 : new > old- 0 : new = old : -1 new < old.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pNewVersion : UDINT := 0; (*String pointer to new version.*)
		pOldVersion : UDINT := 0; (*String pointer to old version.*)
	END_VAR
END_FUNCTION

FUNCTION_BLOCK brdkUpdateDelete (*Deletes an update.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pFileDevice : UDINT := 0; (*String pointer for file device. Can be created with brdkFilelibrary.*)
	END_VAR
	VAR_OUTPUT
		status : DINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
	END_VAR
	VAR
		internal : brdk_update_delete_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkUpdateDistributeFTP (*Distributes an update package to a list of PLC's.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pFileDevice : UDINT := 0; (*String pointer for file device. Can be created with brdkFilelibrary.*)
		client : ARRAY[0..BRDK_UPDATE_MAX_FTP_CLIENTS] OF brdk_update_dist_ftp_client_typ; (*List of FTP clients that will receive the update.*)
		cmd : brdk_update_dist_ftp_cmd_typ; (*Commands.*)
	END_VAR
	VAR_OUTPUT
		status : DINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
		ready : BOOL := FALSE; (*Function block ready.*)
		version : STRING[32] := ''; (*Update version number.*)
		id : STRING[255] := ''; (*Update configuration ID.*)
		artransferFileSize : UDINT := 0; (*Update file "artransfer.br" size in bytes.*)
		updatePackagesSent : USINT := 0; (*Amount of update packages sent*)
	END_VAR
	VAR
		internal : brdk_update_dist_ftp_int_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkUpdateManager (*Manages updates.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pFileDevice : UDINT := 0; (*String pointer for file device. Can be created with brdkFilelibrary.*)
		cmd : brdk_update_manager_cmd_typ; (*Commands.*)
	END_VAR
	VAR_OUTPUT
		running : brdk_update_manager_run_info_typ; (*Running information.*)
		update : brdk_update_manager_upd_info_typ; (*Update information.*)
		ready : BOOL := FALSE; (*Function block ready.*)
		status : DINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
	END_VAR
	VAR
		internal : brdk_update_manager_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK
