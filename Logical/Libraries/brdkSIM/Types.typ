
TYPE
	brdkSIM_status_typ : 	STRUCT 
		fbStatus : brdkSIM_STATUS_typ;
		error : BOOL;
		errorCode : UINT;
	END_STRUCT;
	brdkSIM_STATUS_typ : 
		(
		brdkSIM_NOT_ENABLED := 0,
		brdkSIM_BUSY := 10,
		brdkSIM_RUNNING := 20,
		brdkSIM_ERROR := 200
		);
	brdkSimInput_internal_typ : 	STRUCT 
		state : USINT;
		AsIOEnableForcing_0 : AsIOEnableForcing;
		AsIOSetForceValue_0 : AsIOSetForceValue;
		AsIODisableForcing_0 : AsIODisableForcing;
	END_STRUCT;
	brdkSimOutput_internal_typ : 	STRUCT 
		state : USINT;
		pvStatus : UINT;
		pvAdr : UDINT;
		pvLen : UDINT;
		pvCheck : UINT;
		pvCmpString : STRING[4];
		boolVar : BOOL;
	END_STRUCT;
END_TYPE
