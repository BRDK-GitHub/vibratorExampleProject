
FUNCTION_BLOCK OeeCalc
	VAR_INPUT
		Enable : BOOL;
	END_VAR
	VAR_INPUT RETAIN
		BadPortion : UDINT;
		GoodPortion : UDINT;
	END_VAR
	VAR_INPUT
		Executing : BOOL;
		IdealCycleTime : REAL;
		Reset : BOOL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Availability : REAL;
		Performance : REAL;
		Quality : REAL;
		OEE : REAL;
	END_VAR
	VAR
		state : INT;
		RTInfo_0 : RTInfo;
	END_VAR
	VAR RETAIN
		executeTime : UDINT;
		totalTime : UDINT;
	END_VAR
END_FUNCTION_BLOCK

{REDUND_ERROR} FUNCTION_BLOCK WingSync (*Function block that handles synchronization between two CMs*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Request : BOOL; (*Request synchronization with neighbour machine*)
		di_neighbourPortionReady : BOOL;
		NeighbourActive : BOOL;
		NeighbourIsDosing : BOOL;
		Cancel : BOOL;
	END_VAR
	VAR_OUTPUT
		do_neighbourPortionReady : BOOL;
		Approved : BOOL; (*Syncronization with neighbour completed*)
		CancelApproved : BOOL;
		WaitingForNeighbour : BOOL;
		RunningWithNeighbour : BOOL;
	END_VAR
	VAR
		state : UINT;
		TON_transmissionDelay : TON;
		TON_timeout : TON;
	END_VAR
END_FUNCTION_BLOCK
