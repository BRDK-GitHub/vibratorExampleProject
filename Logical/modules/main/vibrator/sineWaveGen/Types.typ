
TYPE
	acc_typ : 	STRUCT 
		samples : UINT;
		enable : BOOL; (*enable reading of acc. values*)
		actVib : REAL;
		analogVib : REAL;
		toggleBit : BOOL;
		RmsAccRaw : REAL;
		RmsVelRaw : REAL;
		PeakRaw : REAL;
		RmsRaw : REAL;
		ISO : REAL;
		rawVib : REAL;
	END_STRUCT;
	local_typ : 	STRUCT 
		percentFromAccelerometer : REAL;
		MC_BR_CyclicRead_Max : MC_BR_CyclicRead;
		maxVoltage : REAL;
		MC_BR_CyclicRead_0 : MC_BR_CyclicRead;
		MC_BR_CyclicRead_1 : MC_BR_CyclicRead;
		time : REAL;
		maxPeakCurrent : REAL;
		actCurrent : REAL;
		actVoltage : REAL;
		readPercentFromAccelerometer : BOOL := FALSE;
	END_STRUCT;
END_TYPE
