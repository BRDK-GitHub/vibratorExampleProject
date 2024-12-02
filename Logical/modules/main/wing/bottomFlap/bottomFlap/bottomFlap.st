PROGRAM _INIT

	em.setup.name 			:= 'bottomFlap';
	em.setup.parent.name 	:= 'wing';
	em.setup.reactTo 		:= BRDK_EM_REACT_TO_ALL;
		
	setupPointers;

	// Alarm texts
	this.alarm.openTooLong.name := 'bottomFlapOpenTooLong';
	this.alarm.closeTooLong.name := 'bottomFlapCloseTooLong';
	this.alarm.openNeighbourTooLong.name := 'neighbourBottomFlapOpenTooLong';
	this.alarm.closeNeighbourTooLong.name := 'neighbourBottomFlapCloseTooLong';
	this.alarm.neighbourNotActive.name := 'neighbourNotActive';
	
	cm20Connected := TRUE;
	
END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	ioMappingInput;
	
	// this.runningAlone := this.hw.di_neigbourIsDosing OR NOT (this.hw.di_neighbourActive);

	// setup flap function block
	this.flap.enable 						 := TRUE;
	this.flap.cycleTime						 := em.status.cycleTime;
	this.flap.flapTime						 := interface.parameter.flapTime;
	this.flap.di_changeover 				 := this.hw.di_changeover;
	this.flap.simulation					 := gWingInterface.parameter.simulation;
	this.neighbourFlap.enable				 := NOT this.WingSync_0.RunningWithNeighbour;
	this.neighbourFlap.cycleTime			 := em.status.cycleTime;	
	this.neighbourFlap.flapTime				 := interface.parameter.flapTime;
	this.neighbourFlap.di_changeover 		 := this.hw.di_neighbourChangeover;
	this.neighbourFlap.simulation			 := gWingInterface.parameter.simulation;
	
	
	this.flap();
	this.neighbourFlap();

	CASE em.mode OF
		MODE_PRODUCING: producing;
		MODE_MANUAL: testing;	// mode for testing flaps manually.
		ELSE em.cmd.sc := TRUE;
	END_CASE
	
	this.hw.do_open				:= this.flap.do_open;
	this.hw.do_neighbourOpen	:= this.neighbourFlap.do_open;
	this.hmi.neighbourActive	:= this.hw.di_neighbourActive;
	
	alarm;

	em();
		
	this.WingSync_0.NeighbourActive 			:= this.hw.di_neighbourActive;
	this.WingSync_0.NeighbourIsDosing 			:= this.hw.di_neigbourIsDosing;
	this.WingSync_0.di_neighbourPortionReady 	:= this.hw.di_neighbourPortionReady;
	this.WingSync_0();
	this.hw.do_neighbourPortionReady 			:= this.WingSync_0.do_neighbourPortionReady;
	
	this.OeeCalc_0.Enable := TRUE;
	this.OeeCalc_0.Executing := gMainInterface.status.state = STATE_EXECUTE;
	this.OeeCalc_0.IdealCycleTime := 1200;
	this.OeeCalc_0.Reset := gMainInterface.status.state = STATE_COMPLETING;
	this.OeeCalc_0();
	
	interface.status.waitingForNeighbour 		:= this.WingSync_0.WaitingForNeighbour;
	interface.status.neighbourWaiting			:= this.hw.di_neighbourPortionReady;
	
	
	// FAT test
	CASE testStateFAT OF
		
		0:
			IF interface.cmd.wingTestManual THEN
				// Only execute if flap is closed
				IF this.hw.do_open=FALSE AND this.hw.do_neighbourOpen=FALSE THEN
					interface.status.testResultFAT := FALSE; // reset result
					testStateFAT := 10;
				END_IF
				
			END_IF
		
		10:
			//wait 1s so flaps are closed before we start test.
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				// Open flap
				this.flap.open := TRUE;
				testStateFAT := 20;
			END_IF
		
		20:
			IF this.flap.error THEN
				// Test fail
				testStateFAT := 120;
			ELSIF this.flap.position = FLAP_OPEN THEN
				testStateFAT 			:= 30;
			END_IF
		
		30:
			//wait 1s before closing
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				// Close flap
				this.flap.close := TRUE;
				testStateFAT := 40;
			END_IF
		
		40:
			IF this.flap.error THEN
				// Test fail
				testStateFAT := 120;
			ELSIF this.flap.position = FLAP_CLOSED THEN
				testStateFAT 			:= 50;
			END_IF
		
		50:
			//wait 1s
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				// start test of neighbourFlap
				this.neighbourFlap.open := TRUE;
				testStateFAT := 60;
			END_IF
			
		60:
			IF this.neighbourFlap.error THEN
				// test Fail
				testStateFAT := 120;
			ELSIF this.neighbourFlap.position = FLAP_OPEN THEN
				testStateFAT := 70;
			END_IF
			
		70:
			//wait 1s
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				// start test of neighbourFlap
				this.neighbourFlap.close := TRUE;
				testStateFAT := 80;
			END_IF
			
		80:
			IF this.neighbourFlap.error THEN
				// test Fail
				testStateFAT := 120;
			ELSIF this.flap.position = FLAP_CLOSED THEN
				testStateFAT := 90;
			END_IF
			
		90:
			//wait 1s
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				interface.status.testResultFAT := TRUE; // Good result
				testStateFAT := 120;
			END_IF
			
		120:
			// Reset error (if any) before finishing test
			this.flap.resetError := this.flap.error;
			this.neighbourFlap.resetError := this.neighbourFlap.error;
			
			IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
				interface.cmd.wingTestManual := FALSE; // signal test done
				
				// Start next test (we are done here)
				gCassetteInterface.cmd.wingTestManual := TRUE;
				testStateFAT := 0;
			END_IF
		
	END_CASE
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

