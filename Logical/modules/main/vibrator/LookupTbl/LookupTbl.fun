
FUNCTION_BLOCK LookupTbl
	VAR_INPUT
		Enable : BOOL;
		X : REFERENCE TO ARRAY[0..MAX_LOOKUP_IDX] OF REAL;
		Y : REFERENCE TO ARRAY[0..MAX_LOOKUP_IDX] OF REAL;
		In : REAL;
		Descending : BOOL; (*if x[] is descending this should be set to TRUE*)
	END_VAR
	VAR_OUTPUT
		Out : REAL;
	END_VAR
	VAR
		i : USINT;
		numOfValues : USINT;
		maxValueIdx : USINT;
		oldEnable : BOOL;
		denominator : REAL;
	END_VAR
END_FUNCTION_BLOCK
