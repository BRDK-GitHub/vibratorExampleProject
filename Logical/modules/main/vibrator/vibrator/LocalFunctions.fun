
{REDUND_ERROR} FUNCTION RSquared : REAL (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		data : ARRAY[0..9] OF REAL;
		prc10 : REAL;
		prc100 : REAL;
	END_VAR
	VAR
		i : USINT;
		ssTot : REAL;
		ssRes : REAL;
		mean : REAL;
	END_VAR
END_FUNCTION

FUNCTION maxPeakToPercent : REAL
	VAR_INPUT
		maxPeakVal : REAL;
		Y1 : REAL;
		Y2 : REAL;
	END_VAR
	VAR
		slope : REAL;
	END_VAR
END_FUNCTION

FUNCTION getAccelerationFromPercent : REAL
	VAR_INPUT
		percent : REAL;
		vibratorType : UINT; (*0=CF, 1=LF*)
		machineType : SINT; (*0=small, 1=big*)
	END_VAR
END_FUNCTION
