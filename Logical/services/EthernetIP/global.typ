
TYPE
	gEthernetIPInterface_typ : 	STRUCT 
		status : gEthernetIPInterface_status_typ;
	END_STRUCT;
	gEthernetIPInterface_status_typ : 	STRUCT 
		stop : BOOL; (*CM20 to LineController status*)
		start : BOOL; (*CM20 to LineController status*)
		empty : BOOL; (*CM20 to LineController status*)
		emptyMode : BOOL; (*CM20 to LineController status*)
		bypassCassette : BOOL; (*CM20 to LineController status*)
		di_cassetteReady : BOOL;
		di_cassetteQueue : BOOL;
		do_cassetteRelease : BOOL;
	END_STRUCT;
END_TYPE
