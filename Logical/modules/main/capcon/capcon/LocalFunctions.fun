
{REDUND_ERROR} FUNCTION_BLOCK TeachIntegral (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Enable : {REDUND_UNREPLICABLE} BOOL;
		BrickCount : USINT;
		NoPeaks : USINT;
		CapconModeOn : BOOL;
		NoPortions : USINT; (*The amount of good portions that have to be seen before accepting teach*)
		In : REAL;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
		Done : BOOL;
		Error : BOOL;
	END_VAR
	VAR
		teachCandidate : {REDUND_UNREPLICABLE} BOOL;
		teachCandidateIntegral : ARRAY[0..MAX_TEACH_CANDIDATES] OF REAL;
		teachIntegral : REAL;
		teachCandidateCounter : USINT;
		teachCounter : USINT;
		state : UINT;
		i : UINT;
	END_VAR
END_FUNCTION_BLOCK
