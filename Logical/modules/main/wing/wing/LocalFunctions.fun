
{REDUND_ERROR} FUNCTION_BLOCK CycleTimeCalc (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Enable : {REDUND_UNREPLICABLE} BOOL;
		UpperFlapReady : BOOL;
		MiddleFlapReady : BOOL;
		Stop : BOOL;
	END_VAR
	VAR_OUTPUT
		Ready : BOOL;
		CycleTime : REAL;
		TMU : REAL;
	END_VAR
	VAR
		startTime1 : TIME;
		startTime2 : TIME;
		elapsed : TIME;
		tmu : REAL;
		cycleTime : REAL;
		cycleTimeArr : ARRAY[0..9] OF REAL;
		cycleTimeArrFull : BOOL;
		cycleTimeArrIdx : USINT;
		state : UDINT;
		i : UDINT;
		_stop : BOOL;
	END_VAR
END_FUNCTION_BLOCK
