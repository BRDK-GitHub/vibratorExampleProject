
FUNCTION_BLOCK brdkPVLocalVariable (*Creates the PV names for the variables which can be used for e.g. mappRecipe or mappData.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pPV : ARRAY[0..BRDK_PV_MAX_PV_NAMES] OF UDINT := [10(0)]; (*String pointer for each variable.*)
		lPV : ARRAY[0..BRDK_PV_MAX_PV_NAMES] OF STRING[BRDK_PV_MAX_NAME_LENGTH] := [10('')]; (*String list of local variables.*)
	END_VAR
	VAR_OUTPUT
		status : UINT := 0; (*Status of the function block.*)
	END_VAR
END_FUNCTION_BLOCK
