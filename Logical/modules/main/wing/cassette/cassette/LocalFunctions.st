
(* Function block that handles synchronization between two CMs *)
FUNCTION_BLOCK CassetteSync
	
	CASE state OF 
		0:
			IF Request THEN
				do_bricksReadyInCassette := TRUE;
				state := 10;
			ELSIF Cancel THEN
				state := 220;
			END_IF
		
		10:
			IF di_neighbourBricksInCassette THEN
				state := 15;
			ELSIF Cancel THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 200;
			END_IF
			
		15:
			TON_transmissionDelay.IN := TRUE;
			TON_transmissionDelay.PT:= T#10ms;
			TON_transmissionDelay();
			
			IF TON_transmissionDelay.Q THEN
				TON_transmissionDelay.IN := FALSE;
				TON_transmissionDelay();
				do_bricksReadyInCassette := FALSE;
				state := 20;
			END_IF
		
		20:
			IF NOT di_neighbourBricksInCassette THEN
				Approved := TRUE;
				state := 30;
			END_IF
		
		30:
			IF NOT Request THEN
				Approved := FALSE;
				state := 0;
			END_IF
		
		100:
			Approved := Request;
			
			IF NeighbourActive THEN
				Approved := FALSE;
				state := 0;
			END_IF
		
		200:
			do_bricksReadyInCassette := FALSE;
			
			TON_timeout.IN := TRUE;
			TON_timeout.PT := T#100ms;
			TON_timeout();
		
			IF di_neighbourBricksInCassette THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 210;
			ELSIF TON_timeout.Q THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 220;
			END_IF
		
		210:
			TON_timeout.IN := TRUE;
			TON_timeout.PT := T#100ms;
			TON_timeout();
			
			IF NOT di_neighbourBricksInCassette THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				Approved := TRUE;
				state := 30;
			ELSIF TON_timeout.Q THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 220;
			END_IF
		
		220:
			CancelApproved := TRUE;
			
			IF NOT Cancel THEN
				CancelApproved := FALSE;
				state := 0;
			END_IF
	
	END_CASE
	
	IF NOT NeighbourActive THEN
		do_bricksReadyInCassette := FALSE;
		state := 100;
	END_IF
	
END_FUNCTION_BLOCK



FUNCTION_BLOCK FallingEdgeTrigger
	
	IF start THEN
		TON_timeout.IN := NOT output; // IF not output for 2s - timeout and make out=TRUE.
		TON_timeout.PT := T#2s;
		TON_timeout();
		
		IF (NOT input AND oldInput) OR TON_timeout.Q THEN
			TON_timeout(IN:=FALSE);
			output := TRUE;
		END_IF
		oldInput := input;
		
	ELSE
		TON_timeout(IN:=FALSE);
		output := oldInput := FALSE;
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK CassetteUtilization

	CASE state OF
		0:
			IF Enable THEN
				state := 10;
			END_IF
		
		10:
			CASE Substate OF
				0,10:
					_waitForCassette := _waitForCassette + CycleTime;
					
				20,30:
					IF WaitingForNeighbour THEN
						_waitForNeighbour := _waitForNeighbour + CycleTime;
					ELSE
						_waitForPortion := _waitForPortion + CycleTime;
					END_IF
					
				40:
					_waitForQueue := _waitForQueue + CycleTime;
					
				50:
					_waitForNeighbour := _waitForNeighbour + CycleTime;
				
				70,80:
					_releaseCassette := _releaseCassette + CycleTime;
			END_CASE
		
	END_CASE
	
	IF CassetteCounter <> oldCassetteCounter THEN
		oldCassetteCounter := CassetteCounter;
		
		WaitForCassette := UDINT_TO_REAL(_waitForCassette)/1000;
		WaitForNeighbour :=  UDINT_TO_REAL(_waitForNeighbour)/1000;
		WaitForPortion :=  UDINT_TO_REAL(_waitForPortion)/1000;
		WaitForQueue :=  UDINT_TO_REAL(_waitForQueue)/1000;
		ReleaseCassette :=  UDINT_TO_REAL(_releaseCassette)/1000;
				
		CassettesReleased := CassetteCounter;
		
		_waitForCassette := 0;
		_waitForNeighbour := 0;
		_waitForPortion := 0;
		_waitForQueue := 0;
		_releaseCassette := 0;
	END_IF
	
	IF state <> 0 AND NOT Enable THEN
		state := 0;
	END_IF

END_FUNCTION_BLOCK

FUNCTION_BLOCK FlowMeasure
	
	CASE state OF
		0:
			IF Enable THEN
				state := 10;
			END_IF
		
		10:
			// Cassette wait
			IF CassetteReady AND cassetteReadyTime = 0 THEN
				cassetteReadyTime := TIME_TO_DINT(clock_ms());
			END_IF
		
			IF NOT CassetteReady AND cassetteReadyTime <> 0 THEN
				FlowWaitTime := TIME_TO_DINT(clock_ms()) - cassetteReadyTime;
				cassetteReadyTime := 0;
			END_IF
		
			IF cassetteReadyTime <> 0 AND FlowWaitTime + 2000 < TIME_TO_DINT(clock_ms()) - cassetteReadyTime THEN
				FlowWaitTime := TIME_TO_DINT(clock_ms()) - cassetteReadyTime;
			END_IF
			
			// Cassette queue
			IF NOT CassetteQueue AND cassetteQueueTime = 0 THEN
				cassetteQueueTime := TIME_TO_DINT(clock_ms());
			END_IF
		
			IF CassetteQueue AND cassetteQueueTime <> 0 THEN
				FlowQueueTime := TIME_TO_DINT(clock_ms()) - cassetteQueueTime;
				cassetteQueueTime := 0;
			END_IF
		
			IF cassetteQueueTime <> 0 AND FlowQueueTime + 2000 < TIME_TO_DINT(clock_ms()) - cassetteQueueTime THEN
				FlowQueueTime := TIME_TO_DINT(clock_ms()) - cassetteQueueTime;
			END_IF
	END_CASE
	
END_FUNCTION_BLOCK

