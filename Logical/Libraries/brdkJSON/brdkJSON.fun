
FUNCTION brdkJSONfindNext : DINT (*Find a JSON element. $RETURN=position;Position after the found element.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		find : brdk_json_find_typ := BRDK_JSON_OBJECT_START; (*JSON element to find.*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the element. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONnextElement : brdk_json_find_typ (*Return the next found JSON element. $RETURN=type;JSON element type.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		pPposition : UDINT := 0; (*Pointer to the position in the source string where to starte the search for the element. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONparse : DINT (*Finds a name and value pair in a JSON object. $RETURN=position;Position after the found object. Can be used as position input to search for more values in a source string. See error codes below.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		pName : UDINT := 0; (*String pointer to the name.*)
		pValue : UDINT := 0; (*String pointer to the value destination.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_DINT_TO_DINT; (*Convert datatype.*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the value. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONparseArray : DINT (*Finds a name and value pair in a JSON object. $RETURN=position;Position after the found object. Can be used as position input to search for more values in a source string. See error codes below.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		pName : UDINT := 0; (*String pointer to the name.*)
		pValue : UDINT := 0; (*String pointer to the value destination.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_DINT_TO_DINT; (*Convert datatype.*)
		arraySize : UDINT := 0; (*Maximum size of array (number of elements).*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the value. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONparseToString : DINT (*Finds a name and value pair in a JSON object. $RETURN=position;Position after the found object. Can be used as position input to search for more values in a source string. See error codes below.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		pName : UDINT := 0; (*String pointer to the name.*)
		pValue : UDINT := 0; (*String pointer to the value destination.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_STRING_TO_STRING; (*Convert datatype.*)
		size : UDINT := 0; (*Maximum size of the value. Only used when value is a STRING type.*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the value. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONparseToStringArray : DINT (*Finds a name and value pair in a JSON object. $RETURN=position;Position after the found object. Can be used as position input to search for more values in a source string. See error codes below.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pSource : UDINT := 0; (*String pointer to the source string.*)
		pName : UDINT := 0; (*String pointer to the name.*)
		pValue : UDINT := 0; (*String pointer to the value destination.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_STRING_TO_STRING; (*Convert datatype.*)
		size : UDINT := 0; (*Maximum size of the value. Only used when value is a STRING type.*)
		arraySize : UDINT := 0; (*Maximum size of array (number of elements).*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the value. 0 will start from the beginning.*)
	END_VAR
END_FUNCTION

FUNCTION brdkJSONstringify : UDINT (*Add name and value pair to a JSON object. $RETURN=position;Position after the added object. Can be used as position input to search for more values in a source string. See error codes below.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		pDestination : UDINT := 0; (*String pointer to the destination string.*)
		pName : UDINT := 0; (*String pointer to the name.*)
		pValue : UDINT := 0; (*String pointer to value.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_STRING_TO_STRING; (*Convert datatype.*)
		size : UDINT := 0; (*Maximum size of the destination STRING.*)
		position : UDINT := 0; (*Position in the source string where to starte the search for the value. 0 will start from the beginning or it will search for a }.*)
	END_VAR
END_FUNCTION
