
{REDUND_ERROR} FUNCTION_BLOCK RemoteUpdate (* *) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Enable : BOOL;
		IpEndpoint : STRING[32];
		CheckVersion : BOOL; (*Only check version locally and on eWU*)
		PrepareUpdate : {REDUND_UNREPLICABLE} BOOL; (*Check version locally and on eWU and send it afterward with FTP (if different version)*)
		UpdateEWU : BOOL; (*Will tell the eWU to update.*)
	END_VAR
	VAR_OUTPUT
		VersionEWU : STRING[32];
		VersionLocal : STRING[32];
	END_VAR
	VAR_OUTPUT RETAIN
		UpdateReadyOnEWU : BOOL;
	END_VAR
	VAR
		state : USINT;
		EasyUaRead_0 : EasyUaRead;
		EasyUaWrite_0 : EasyUaWrite;
		brdkUpdateCheck_0 : brdkUpdateCheck;
		brdkUpdateDistributeFTP_0 : brdkUpdateDistributeFTP;
		boolTRUE : BOOL := TRUE; (*Used to write a true bool over OPCUA.*)
		TON_0 : TON;
	END_VAR
END_FUNCTION_BLOCK
