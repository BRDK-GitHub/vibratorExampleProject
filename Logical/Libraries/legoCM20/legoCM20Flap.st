FUNCTION_BLOCK legoCM20Flap

	// open								close
	//  ____________________________________
	// |____________________________________|   
	//              /changeover\
	internal.avgOpenTime.Enable := TRUE;
	internal.avgCloseTime.Enable := TRUE;
	
	IF avgSamples <> internal.avgOpenTime.WindowLength THEN
		internal.avgOpenTime.Update := TRUE;
		internal.avgOpenTime.WindowLength  := avgSamples;
		
	END_IF
	
	IF avgSamples <> internal.avgCloseTime.WindowLength THEN
		internal.avgCloseTime.Update := TRUE;
		internal.avgCloseTime.WindowLength  := avgSamples;
		
	END_IF
	
	IF internal.avgOpenTime.UpdateDone THEN
		internal.avgOpenTime.Update := FALSE;
	END_IF
	
	IF internal.avgCloseTime.UpdateDone THEN
		internal.avgCloseTime.Update := FALSE;
	END_IF
	
	CASE internal.state OF
	
		0:	// waiting for a start command
			IF NOT enable THEN
				do_open := FALSE;
				internal.state := 100;
			ELSIF WUstepperConnected THEN
				internal.state := 200;
			ELSIF open THEN
				open 					:= FALSE;
				IF simulation THEN
					TON_0(IN:=FALSE);
					open := TRUE;
					internal.state := 110;
				ELSIF position <> FLAP_OPEN THEN
					error					:= FALSE;
					do_open				:= TRUE;					// start opening the flap
					internal.timeElapsed 	:= 0;						// reset elapsed time
					internal.openCloseTime	:= 0;
					internal.startMeasTimeOpenClose := TRUE;
					position				:= FLAP_OPENING_BEFORE_CHANGEOVER;
					internal.state 			:= 10;
				END_IF
			ELSIF close THEN
				close 					:= FALSE;
				IF simulation THEN
					TON_0(IN:=FALSE);
					internal.state := 110;
				ELSIF position <> FLAP_CLOSED THEN
					error					:= FALSE;
					do_open				:= FALSE;					// start closeing the flap
					internal.timeElapsed 	:= 0;						// reset elapsed time
					position				:= FLAP_CLOSEING_BEFORE_CHANGEOVER;
					internal.state 			:= 10;
				END_IF
			ELSIF error THEN
				do_open					:= FALSE;
				IF resetError THEN
					internal.timeElapsed 	:= 0;
					internal.state 			:= 40;
				END_IF
			END_IF
			
	
		10:	// waiting for changeover sensor
			internal.timeElapsed := internal.timeElapsed + cycleTime;
			IF internal.timeElapsed >= flapTime THEN
				internal.state 	:= 0;
				error			:= TRUE;
			ELSIF NOT di_changeover THEN	 // high signal (active low)
				IF do_open THEN
					IF internal.timeElapsed > REAL_TO_UDINT(internal.avgOpenTime.Out) THEN
						internal.openTimeMaxCnt := internal.openTimeMaxCnt+1;
					ELSE
						internal.openTimeMaxCnt := 0;
					END_IF
					
					internal.avgOpenTime(In := UDINT_TO_REAL(internal.timeElapsed));
					openTime := internal.timeElapsed;
					position		:= FLAP_OPENING_AT_CHANGEOVER;
				ELSE
					IF internal.timeElapsed > REAL_TO_UDINT(internal.avgCloseTime.Out) THEN
						internal.closeTimeMaxCnt := internal.closeTimeMaxCnt+1;
					ELSE
						internal.closeTimeMaxCnt := 0;
					END_IF
					
					internal.avgCloseTime(In := UDINT_TO_REAL(internal.timeElapsed));
					internal.startMeasTimeOpenClose := FALSE;
					openCloseTime := internal.openCloseTime;
					closingTime := internal.timeElapsed;
					position		:= FLAP_CLOSEING_AT_CHANGEOVER;
				END_IF
				
				IF internal.openTimeMaxCnt > 25THEN
					internal.openTimeMaxCnt := 0;
					internal.state 	:= 0;
					error			:= TRUE;
				END_IF
				
				IF internal.closeTimeMaxCnt > 25THEN
					internal.closeTimeMaxCnt := 0;
					internal.state 	:= 0;
					error			:= TRUE;
				END_IF
				
			
				internal.state 	:= 20;
			END_IF

		20:	// waiting for no changeover sensor
			internal.timeElapsed := internal.timeElapsed + cycleTime;
			IF internal.timeElapsed >= flapTime THEN
				internal.state 	:= 0;
				error			:= TRUE;
			ELSIF di_changeover THEN
				position		:= SEL(NOT do_open,FLAP_OPEN,FLAP_CLOSED);
				IF do_open THEN
					openTimeAfterChangeover := (internal.timeElapsed-cycleTime)/1000; // subtract 1 scan because we PVmap from sampling task (takes 1 extra scan).
				ELSE //closing
					closingTimeAfterChangeover := (internal.timeElapsed-cycleTime)/1000;
				END_IF
				internal.state 	:= 0;
			END_IF
		
		40:
			internal.timeElapsed := internal.timeElapsed + cycleTime;
			IF internal.timeElapsed >= 2*flapTime THEN
				resetError 	:= FALSE;
				position	:= FLAP_CLOSED;
				do_open 	:= FALSE;
				error		:= FALSE;
				internal.state 	:= SEL(WUstepperConnected,0,200);
			END_IF
				
		100:
			IF enable THEN
				internal.state := SEL(WUstepperConnected,0,200);
			ELSE
				IF open THEN
					open := FALSE;
					position := FLAP_OPEN;
				ELSIF close THEN
					close := FALSE;
					position := FLAP_CLOSED;
				END_IF
			END_IF
		
		110:
			TON_0.IN := TRUE;
			TON_0.PT := simulatedTimeToOpenCloseFlap;
			TON_0();
		
			IF TON_0.Q THEN
				TON_0(IN:=FALSE);
				position := SEL(open,FLAP_CLOSED,FLAP_OPEN);
				open := FALSE;
				internal.state := 0;
			END_IF
	
		(**** STEPPER WU20 ****)
			
		200:
			IF NOT enable THEN
				do_open := FALSE;
				internal.state := 100;
			ELSIF open THEN
				open 					:= FALSE;
				IF positionFromWUstepper <> FLAP_OPEN THEN
					error					:= FALSE;
					do_open				:= TRUE;						// start opening the flap
					internal.timeElapsed 	:= 0;						// reset elapsed time
					position := FLAP_OPENING_AT_CHANGEOVER;
					internal.state 			:= 210;
				ELSE
					position := FLAP_OPEN;
				END_IF
			ELSIF close THEN
				close 					:= FALSE;
				IF positionFromWUstepper <> FLAP_CLOSED THEN
					error					:= FALSE;
					do_open				:= FALSE;					// start closeing the flap
					internal.timeElapsed 	:= 0;						// reset elapsed time
					position := FLAP_CLOSEING_AT_CHANGEOVER;
					internal.state 			:= 210;
				ELSE
					position := FLAP_CLOSED;
				END_IF
			ELSIF error THEN
				do_open					:= FALSE;
				IF resetError THEN
					internal.timeElapsed 	:= 0;
					internal.state 			:= 40;
				END_IF
			END_IF
		
		210:
			internal.timeElapsed := internal.timeElapsed + cycleTime;
			
			IF internal.timeElapsed >= flapTime THEN
				internal.state 	:= 200;
				error			:= TRUE;
			ELSIF (do_open AND positionFromWUstepper=FLAP_OPEN) OR (NOT do_open AND positionFromWUstepper=FLAP_CLOSED) THEN
				position := positionFromWUstepper;
				// Only for timings to show on HMI:
				IF do_open THEN
					openTimeAfterChangeover := (internal.timeElapsed-cycleTime)/1000; // subtract 1 scan because we PVmap from sampling task (takes 1 extra scan).
				ELSE //closing
					closingTimeAfterChangeover := (internal.timeElapsed-cycleTime)/1000;
				END_IF
				internal.state 	:= 200;
			END_IF
		
		
	END_CASE

	IF internal.startMeasTimeOpenClose THEN
		internal.openCloseTime := internal.openCloseTime + cycleTime;
	END_IF
	
END_FUNCTION_BLOCK
