
(* Function block that handles synchronization between two CMs *)
FUNCTION_BLOCK WingSync
	
	CASE state OF 
		0:
			IF Request THEN
				IF NeighbourIsDosing THEN
					Approved := TRUE;
					RunningWithNeighbour := FALSE;
					state := 30;
				ELSE
					do_neighbourPortionReady := TRUE;
					state := 10;
				END_IF
			ELSIF Cancel THEN
				state := 220;
			END_IF
		
		10:
			IF di_neighbourPortionReady THEN
				state := 15;
			ELSIF NeighbourIsDosing THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 300;	
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
				do_neighbourPortionReady := FALSE;
				state := 20;
			END_IF
		
		20:
			IF NOT di_neighbourPortionReady THEN
				Approved := TRUE;
				RunningWithNeighbour := TRUE;
				state := 30;
			END_IF
		
		30:
			IF NOT Request THEN
				Approved := FALSE;
				state := 0;
			END_IF
		
		100:
			Approved := Request;
			CancelApproved := Cancel;
			RunningWithNeighbour := FALSE;
			
			IF NeighbourActive THEN
				Approved := FALSE;
				CancelApproved := FALSE;
				state := 0;
			END_IF
		
		200:
			do_neighbourPortionReady := FALSE;
			
			TON_timeout.IN := TRUE;
			TON_timeout.PT := T#100ms;
			TON_timeout();
		
			IF di_neighbourPortionReady THEN
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
			
			IF NOT di_neighbourPortionReady THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				Approved := TRUE;
				RunningWithNeighbour := TRUE;
				state := 30;
			ELSIF TON_timeout.Q THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 220;
			END_IF
		
		220:
			CancelApproved := TRUE;
			RunningWithNeighbour := FALSE;
			
			IF NOT Cancel THEN
				CancelApproved := FALSE;
				state := 0;
			END_IF
		
		300:
			do_neighbourPortionReady := FALSE;
			
			TON_timeout.IN := TRUE;
			TON_timeout.PT := T#100ms;
			TON_timeout();
		
			IF di_neighbourPortionReady THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				state := 310;
			ELSIF TON_timeout.Q THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				Approved := TRUE;
				RunningWithNeighbour := FALSE;
				state := 30;
			END_IF
		
		310:
			TON_timeout.IN := TRUE;
			TON_timeout.PT := T#100ms;
			TON_timeout();
			
			IF NOT di_neighbourPortionReady THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				Approved := TRUE;
				RunningWithNeighbour := TRUE;
				state := 30;
			ELSIF TON_timeout.Q THEN
				TON_timeout.IN := FALSE;
				TON_timeout();
				Approved := TRUE;
				RunningWithNeighbour := FALSE;
				state := 30;
			END_IF
				
	END_CASE
	
	WaitingForNeighbour := do_neighbourPortionReady AND NOT di_neighbourPortionReady;
	
	IF NOT NeighbourActive THEN
		do_neighbourPortionReady := FALSE;
		state := 100;
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK OeeCalc
	
	IF NOT Enable AND Active THEN
		state := 0;
		Active := FALSE;
	END_IF
	
	CASE state OF 
		0:
			IF Enable THEN
				Active := TRUE;
				state := 10;
			END_IF
			
		10:
			RTInfo_0.enable := TRUE;
			RTInfo_0();
			
			IF RTInfo_0.status = ERR_OK THEN
				state := 20;
			END_IF
				
		20:
			IF Executing THEN
				executeTime := executeTime + RTInfo_0.cycle_time / 1000;
			END_IF
			totalTime := totalTime + RTInfo_0.cycle_time / 1000;
			
			IF totalTime > 0 THEN
				Availability := UDINT_TO_REAL(executeTime) / UDINT_TO_REAL(totalTime) * 100;
			END_IF
			
			IF executeTime > 0 THEN
				Performance := LIMIT(0, IdealCycleTime * UDINT_TO_REAL(BadPortion + GoodPortion) / UDINT_TO_REAL(executeTime) * 100, 100);
			END_IF
			
			IF GoodPortion + BadPortion > 0 THEN
				Quality := UDINT_TO_REAL(GoodPortion) / UDINT_TO_REAL(GoodPortion + BadPortion) * 100;
			END_IF
			
			OEE := (Availability/100.0) * (Performance/100.0) * (Quality/100.0) * 100;
		
			IF Reset THEN
				executeTime := 0;
				totalTime := 0;
				GoodPortion := 0;
				BadPortion := 0;
			END_IF
	END_CASE

END_FUNCTION_BLOCK

