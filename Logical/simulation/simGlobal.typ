
TYPE
	gSimulation_status_typ : 	STRUCT 
		photoSensor : BOOL;
		simulateAllButWing : BOOL;
	END_STRUCT;
	gSimulation_typ : 	STRUCT 
		status : gSimulation_status_typ;
	END_STRUCT;
END_TYPE
