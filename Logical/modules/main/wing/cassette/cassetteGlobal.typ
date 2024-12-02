
TYPE
	gCassetteInterface_typ : 	STRUCT 
		cmd : gCassetteInterface_cmd_typ;
		parameter : gCassetteInterface_parameter_typ;
		status : gCassetteInterface_status_typ;
	END_STRUCT;
	gCassetteInterface_cmd_typ : 	STRUCT 
		start : UDINT;
		cassetteIsBeingSimulated : BOOL;
		dosing : BOOL;
		wingTestManual : BOOL;
	END_STRUCT;
	gCassetteInterface_status_typ : 	STRUCT 
		ready : BOOL;
		startAck : UDINT;
		dosing : BOOL;
		syncAck : UDINT;
		testResultFAT : BOOL; (*TRUE=good, FALSE=bad*)
	END_STRUCT;
	gCassetteInterface_parameter_typ : 	STRUCT 
		cassetteDetectTime : UDINT; (*Time that the cassette ready signal need to be low*)
		releaseTime : UDINT; (*Cassette release time*)
	END_STRUCT;
END_TYPE
