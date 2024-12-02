
FUNCTION_BLOCK brdkSimInput (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL;
		dpName : STRING[100];
		setValue : UDINT;
	END_VAR
	VAR_OUTPUT
		status : brdkSIM_status_typ;
	END_VAR
	VAR
		internal : brdkSimInput_internal_typ;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkSimOutput (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL;
		pvName : STRING[100];
	END_VAR
	VAR_OUTPUT
		actValue : UDINT;
		status : brdkSIM_status_typ;
	END_VAR
	VAR
		internal : brdkSimOutput_internal_typ;
	END_VAR
END_FUNCTION_BLOCK
