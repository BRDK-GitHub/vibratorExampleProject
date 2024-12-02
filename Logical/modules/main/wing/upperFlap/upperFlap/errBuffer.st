
(* TODO: Add your comment here *)
FUNCTION_BLOCK errBuffer
	IF pushToBuffer THEN
		
		// Move full array 1 idx down (stack push implementation).
		memmove(ADR(array[1]), ADR(array[0]), SIZEOF(array[0])*ERR_BUFFER_SIZE);
		array[0] := input;
		
		// Limit items by the size of the buffer
		itemsInBuffer := itemsInBuffer + 1; 
		IF itemsInBuffer > ERR_BUFFER_SIZE+1 THEN
			itemsInBuffer := ERR_BUFFER_SIZE+1;
		END_IF
		
		// Calculate error rate
		okItems := 0;
		FOR idx := 0 TO (itemsInBuffer-1) DO
			IF array[idx] = TRUE THEN
				okItems := okItems + 1;
			END_IF;
		END_FOR;
		errorRate := 1.0 - (okItems / UINT_TO_REAL(itemsInBuffer));
		pushToBuffer := FALSE;
		
	END_IF
	
	IF reset THEN
		reset := FALSE;
		
		errorRate := 0;
		memset(ADR(array),1,SIZEOF(array));
		idx := 0;
		okItems := 0;
		itemsInBuffer := ERR_BUFFER_SIZE+1;
		
	END_IF
	
END_FUNCTION_BLOCK