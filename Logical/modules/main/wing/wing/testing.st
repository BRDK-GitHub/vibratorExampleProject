
ACTION testing: 

	CASE this.test.state OF
		
		0:
			IF this.test.startTestSequence THEN
				interface.status.startTestSequence := TRUE;
				gUpperFlapInterface.cmd.runFlapContinuously := this.test.runUpperFlapContinuously := FALSE;
				gMiddleFlapInterface.cmd.runFlapContinuously := this.test.runMiddleFlapContinuously := FALSE;
				gBottomFlapInterface.cmd.runFlapContinuously := this.test.runBottomFlapContinuously := FALSE;
				gUpperFlapInterface.cmd.manuelMode := gMiddleFlapInterface.cmd.manuelMode := gBottomFlapInterface.cmd.manuelMode := TRUE;
				this.test.state := 20;
			ELSIF this.test.runUpperFlapContinuously OR this.test.runMiddleFlapContinuously OR this.test.runBottomFlapContinuously THEN
				this.test.state := 10;
			ELSE
				gUpperFlapInterface.cmd.manuelMode := gMiddleFlapInterface.cmd.manuelMode := gBottomFlapInterface.cmd.manuelMode := interface.status.startTestSequence := FALSE;
			END_IF
		
		(**** Actuate flaps continously if prompted from hmi. ****)
			
		10:
			gUpperFlapInterface.cmd.runFlapContinuously := gUpperFlapInterface.cmd.manuelMode := this.test.runUpperFlapContinuously;
			gMiddleFlapInterface.cmd.runFlapContinuously := gMiddleFlapInterface.cmd.manuelMode := this.test.runMiddleFlapContinuously;
			gBottomFlapInterface.cmd.runFlapContinuously := gBottomFlapInterface.cmd.manuelMode := this.test.runBottomFlapContinuously;
			
			IF (NOT this.test.runUpperFlapContinuously AND NOT this.test.runMiddleFlapContinuously AND NOT this.test.runBottomFlapContinuously) OR this.test.startTestSequence THEN
				gUpperFlapInterface.cmd.runFlapContinuously := this.test.runUpperFlapContinuously := FALSE;
				gMiddleFlapInterface.cmd.runFlapContinuously := this.test.runMiddleFlapContinuously := FALSE;
				gBottomFlapInterface.cmd.runFlapContinuously := this.test.runBottomFlapContinuously := FALSE;
				this.test.state := 0;
			END_IF
		
		(**** Start flap sequence ****)
			
		20:
			
			IF NOT this.test.startTestSequence THEN	// test stopped
				gUpperFlapInterface.cmd.runFlapContinuously := gUpperFlapInterface.cmd.open := FALSE;
				gMiddleFlapInterface.cmd.runFlapContinuously := gMiddleFlapInterface.cmd.open := FALSE;
				gBottomFlapInterface.cmd.runFlapContinuously := gBottomFlapInterface.cmd.open := FALSE;
				interface.status.startTestSequence := FALSE;
				this.test.state := 0;
			ELSE
				// Signal flaps to open in a sequence.
				gUpperFlapInterface.cmd.open := TRUE;
				this.test.state := 30;
			END_IF
				
		30:
			em.description := 'Wait for upper flap to open/close';
					
			IF NOT this.test.startTestSequence THEN
				gUpperFlapInterface.cmd.open := FALSE;
				interface.status.startTestSequence := FALSE;
				this.test.state := 0;
			ELSIF NOT gUpperFlapInterface.cmd.open THEN // means that it has been open and closed.
				gMiddleFlapInterface.cmd.open := TRUE;
				this.test.state := 40;
			END_IF
				
		40:
			em.description := 'Wait for middle flap to open/close';
					
			IF NOT this.test.startTestSequence THEN
				gMiddleFlapInterface.cmd.open := FALSE;
				interface.status.startTestSequence := FALSE;
				this.test.state := 0;
			ELSIF NOT gMiddleFlapInterface.cmd.open THEN
				gBottomFlapInterface.cmd.open := TRUE;
				this.test.state := 50;
			END_IF
				
		50:
			em.description := 'Wait for bottom flap to open/close';
				 
			IF NOT this.test.startTestSequence THEN
				gBottomFlapInterface.cmd.open := FALSE;
				interface.status.startTestSequence := FALSE;
				this.test.state := 0;
			ELSIF NOT gBottomFlapInterface.cmd.open THEN
				this.test.state := 20;
			END_IF
			
	END_CASE
	
	
END_ACTION
