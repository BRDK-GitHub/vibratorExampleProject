
{REDUND_ERROR} FUNCTION_BLOCK CassetteSync (*Function block that handles synchronization between two CMs*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Request : BOOL; (*Request synchronization with neighbour machine*)
		di_neighbourBricksInCassette : BOOL;
		NeighbourActive : BOOL;
		Cancel : BOOL;
	END_VAR
	VAR_OUTPUT
		do_bricksReadyInCassette : BOOL;
		Approved : BOOL; (*Syncronization with neighbour completed*)
		CancelApproved : BOOL;
	END_VAR
	VAR
		state : UINT;
		TON_timeout : TON;
		TON_transmissionDelay : TON;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK CassetteUtilization
	VAR_INPUT
		Enable : BOOL;
		Substate : UINT;
		CycleTime : UDINT;
		WaitingForNeighbour : BOOL;
		CassetteCounter : UDINT;
	END_VAR
	VAR_OUTPUT
		CassettesReleased : UDINT;
		WaitForCassette : REAL;
		WaitForQueue : REAL;
		WaitForPortion : REAL;
		WaitForNeighbour : REAL;
		ReleaseCassette : REAL;
	END_VAR
	VAR
		state : UINT;
		_waitForCassette : UDINT;
		_waitForNeighbour : UDINT;
		_waitForPortion : UDINT;
		_waitForQueue : UDINT;
		_releaseCassette : UDINT;
		oldCassetteCounter : UDINT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK FallingEdgeTrigger
	VAR_INPUT
		start : BOOL;
		input : BOOL := FALSE;
	END_VAR
	VAR_OUTPUT
		output : BOOL;
	END_VAR
	VAR
		oldInput : BOOL;
		TON_timeout : TON;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK FlowMeasure
	VAR_INPUT
		Enable : BOOL;
		CassetteReady : BOOL;
		CassetteQueue : BOOL;
	END_VAR
	VAR_OUTPUT
		FlowWaitTime : DINT;
		FlowQueueTime : DINT;
	END_VAR
	VAR
		state : INT;
		cassetteReadyTime : DINT;
		cassetteQueueTime : DINT;
	END_VAR
END_FUNCTION_BLOCK
