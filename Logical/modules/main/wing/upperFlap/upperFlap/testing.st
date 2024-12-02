
ACTION testing: 

	this.flapTest.openTime := this.flap.openTimeAfterChangeover;
	this.flapTest.closingTime := this.flap.closingTimeAfterChangeover;
	this.flapTest.openTimeOK := this.flapTest.openTime >= 210 AND this.flapTest.openTime <= 230;
	this.flapTest.closingTimeOK := this.flapTest.closingTime >= 210 AND this.flapTest.closingTime <= 230;
	
	CASE this.test.state OF
		
		0:
			IF NOT interface.cmd.manuelMode THEN
				interface.cmd.runFlapContinuously := FALSE;
				em.substate := 0; // go back to 0 (no more manuel mode)
			ELSIF gWingInterface.status.startTestSequence THEN
				interface.cmd.runFlapContinuously := FALSE; // can't run while doing test sequence.
				this.test.state := 10;
			ELSIF interface.cmd.runFlapContinuously THEN
				this.test.state := 60;
			END_IF
		
			(**** Run sequence ****)
			
		10:
			IF NOT gWingInterface.status.startTestSequence THEN
				this.test.state := 0;
			ELSIF interface.cmd.open THEN
				this.flap.open := TRUE;
				this.test.state := 20;
			END_IF
		
		20: 
			
			IF this.flap.error THEN
				this.alarm.openTooLong.active := TRUE;
			ELSIF this.flap.position = FLAP_OPEN THEN
				this.time.elapsed := 0;
				this.test.state := 30;
			END_IF
		
		30:
			this.time.elapsed := this.time.elapsed + em.status.cycleTime;
			IF this.time.elapsed >= this.flapTest.waitTime THEN
				this.flap.close := TRUE;		// close cmd
				this.test.state := 40;
			END_IF
		
		40:
			IF this.flap.error THEN
				this.alarm.closeTooLong.active := TRUE;
			ELSIF this.flap.position = FLAP_CLOSED THEN
				this.time.elapsed := 0;
				this.test.state := 50;
			END_IF 
		
		50:
			em.description := 'Wait delay before opening next flap';
				
			this.time.elapsed := this.time.elapsed + em.status.cycleTime;
			IF this.time.elapsed >= this.flapTest.waitTime THEN
				interface.cmd.open := FALSE;	// Will signal to wing that flap is done with open/close.
				this.test.state := 10;
			END_IF
			
		
			(**** Run continously ****)
		
		60:
			IF NOT interface.cmd.runFlapContinuously THEN
				this.test.state := 0;
			ELSE
				this.flap.open := TRUE;
				this.test.state := 70;
			END_IF
		
		70:
			IF this.flap.error THEN
				this.alarm.openTooLong.active := TRUE;
			ELSIF this.flap.position = FLAP_OPEN THEN
				this.time.elapsed := 0;
				this.test.state := 80;
			END_IF
		
		80:
			this.time.elapsed := this.time.elapsed + em.status.cycleTime;
			IF this.time.elapsed >= this.flapTest.waitTime THEN
				this.flap.close := TRUE;		// close cmd
				this.test.state := 90;
			END_IF
		
		90:
			IF this.flap.error THEN
				this.alarm.closeTooLong.active := TRUE;
			ELSIF this.flap.position = FLAP_CLOSED THEN
				this.time.elapsed := 0;
				this.test.state := 100;
			END_IF 
			
		100:
			this.time.elapsed := this.time.elapsed + em.status.cycleTime;
			IF this.time.elapsed >= this.flapTest.waitTime THEN
				this.test.state := 60;
			END_IF
		
	END_CASE
	
END_ACTION
