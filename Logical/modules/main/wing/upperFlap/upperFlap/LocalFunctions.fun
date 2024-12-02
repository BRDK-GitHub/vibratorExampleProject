
FUNCTION_BLOCK errBuffer (*LIFO buffer to save the status of last 100 portions and calculate the error rate*)
	VAR_INPUT
		input : BOOL; (*input (OK or not OK)*)
		array : {REDUND_UNREPLICABLE} ARRAY[0..ERR_BUFFER_SIZE] OF BOOL := [100(TRUE)];
		pushToBuffer : BOOL; (*push input to buffer*)
		reset : BOOL := FALSE;
	END_VAR
	VAR_OUTPUT
		errorRate : REAL;
	END_VAR
	VAR
		idx : UINT;
		okItems : REAL;
		itemsInBuffer : UINT;
	END_VAR
END_FUNCTION_BLOCK
