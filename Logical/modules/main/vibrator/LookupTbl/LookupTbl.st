FUNCTION_BLOCK LookupTbl

	// On edgepos of enable calculate how many points we have in LUT
	IF Enable AND NOT oldEnable THEN
		numOfValues := 0;
		maxValueIdx := 0;
		
		FOR i:=0 TO MAX_LOOKUP_IDX DO
			IF X[i] <> 0.0 AND Y[i] <> 0.0 THEN
				numOfValues := numOfValues + 1;
			ELSE
				EXIT;
			END_IF
		END_FOR
				
		IF numOfValues > 1 THEN
			maxValueIdx := numOfValues-1;
		ELSE
			Enable := FALSE;
		END_IF
		
	END_IF
	oldEnable := Enable;
	
	// Do lookup if Enable=TRUE
	IF Enable THEN
		
		// Descending or Ascending
		IF Descending THEN
			FOR i:=0 TO maxValueIdx DO
				IF X[i] <= In THEN
					EXIT;
				END_IF
			END_FOR
		ELSE
			FOR i:=0 TO maxValueIdx DO
				IF X[i] >= In THEN
					EXIT;
				END_IF
			END_FOR
		END_IF
		
		i := LIMIT(0,i,maxValueIdx);
		
		IF i = 0 THEN
			denominator := X[1] - X[0];
			denominator := SEL(denominator=0.0,denominator,0.001); // avoid division by zero
			Out := Y[0] + (In - X[0]) * (Y[1] - Y[0]) / (denominator); // Linear extrapolation for In < X[0]
		ELSIF i = maxValueIdx THEN
			denominator := X[maxValueIdx] - X[maxValueIdx - 1];
			denominator := SEL(denominator=0.0,denominator,0.001); // avoid division by zero
			Out := Y[maxValueIdx] + (In - X[maxValueIdx]) * (Y[maxValueIdx] - Y[maxValueIdx - 1]) / (denominator); // Linear extrapolation for In > X[maxValueIdx]
		ELSE
			denominator := X[i] - X[i - 1];
			denominator := SEL(denominator=0.0,denominator,0.001); // avoid division by zero
			Out := Y[i - 1] + (In - X[i - 1]) * (Y[i] - Y[i - 1]) / (denominator);	// We are inside range - do interpolation between the 2 nearest values.
		END_IF;

	END_IF
	
	
END_FUNCTION_BLOCK