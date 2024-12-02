
(* Calculates cycle time for CM20 *)
FUNCTION_BLOCK CycleTimeCalc
	
	IF Enable THEN
		Ready := TRUE;
		
		IF Stop AND NOT _stop THEN
			_stop := TRUE;
		END_IF
		
		CASE state OF
			0: // Waiting for Upper or Middle to be ready 
				IF MiddleFlapReady OR UpperFlapReady THEN
					IF startTime1 = T#0ms THEN
						startTime1 := clock_ms();
					END_IF
					elapsed := 0;
					state := 10;
				END_IF
			10:
				IF NOT UpperFlapReady AND NOT MiddleFlapReady THEN
					elapsed := clock_ms()-startTime1;
					state := 20;
				ELSIF NOT UpperFlapReady THEN
					state := 30;
				END_IF
			20:
				IF MiddleFlapReady THEN
					startTime1 := clock_ms();
					state := 30;
				END_IF
			30:
				IF UpperFlapReady THEN
					startTime2 := clock_ms();
					state := 40;
				ELSIF _stop THEN
					_stop := FALSE;
					elapsed := elapsed + (clock_ms()-startTime1);
					cycleTimeArr[cycleTimeArrIdx] := TIME_TO_REAL(elapsed)/1000.0;
					cycleTimeArrFull := SEL(cycleTimeArrIdx = 9, cycleTimeArrFull, TRUE);
					cycleTimeArrIdx := SEL(cycleTimeArrIdx = 9, cycleTimeArrIdx + 1, 0);
					cycleTime := 0;
					IF cycleTimeArrIdx > 0 OR cycleTimeArrFull THEN
						FOR i:=0 TO SEL(cycleTimeArrFull, cycleTimeArrIdx-1, 9) DO
							cycleTime := cycleTime + cycleTimeArr[i]/SEL(cycleTimeArrFull, USINT_TO_REAL(cycleTimeArrIdx), 10.0);
						END_FOR
						CycleTime := 60.0/cycleTime;
						tmu := 0;
						FOR i:=0 TO SEL(cycleTimeArrFull, cycleTimeArrIdx-1, 9) DO
							tmu := tmu + cycleTimeArr[i]/360.0;
						END_FOR
						TMU := tmu;
					END_IF
					state := 0;
				END_IF
			40:
				IF _stop THEN
					_stop := FALSE;
					elapsed := elapsed + (clock_ms()-startTime1);
					cycleTimeArr[cycleTimeArrIdx] := TIME_TO_REAL(elapsed)/1000.0;
					cycleTimeArrFull := SEL(cycleTimeArrIdx = 9, cycleTimeArrFull, TRUE);
					cycleTimeArrIdx := SEL(cycleTimeArrIdx = 9, cycleTimeArrIdx + 1, 0);
					cycleTime := 0;
					IF cycleTimeArrIdx > 0 OR cycleTimeArrFull THEN
						FOR i:=0 TO SEL(cycleTimeArrFull, cycleTimeArrIdx-1, 9) DO
							cycleTime := cycleTime + cycleTimeArr[i]/SEL(cycleTimeArrFull, USINT_TO_REAL(cycleTimeArrIdx), 10.0);
						END_FOR
						CycleTime := 60.0/cycleTime;
						tmu := cycleTime/0.0360;
						TMU := tmu;
					END_IF
					startTime1 := startTime2;
					startTime2 := T#0ms;
					state := 0;
				END_IF
		END_CASE
		
	ELSIF Ready THEN
		Ready := FALSE;
		brsmemset(ADR(cycleTimeArr), 0, SIZEOF(cycleTimeArr));
		cycleTimeArrFull := FALSE;
		cycleTimeArrIdx := 0;
		CycleTime := 0;
		TMU := 0;
		startTime1 := T#0ms;
		startTime2 := T#0ms;
	END_IF
	
END_FUNCTION_BLOCK
