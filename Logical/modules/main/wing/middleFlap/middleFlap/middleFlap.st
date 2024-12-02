PROGRAM _INIT

	em.setup.name 			:= 'middleFlap';
	em.setup.parent.name 	:= 'wing';
	em.setup.reactTo 		:= BRDK_EM_REACT_TO_ALL;
	
	setupPointers;

	this.alarm.closeTooLong.name := 'middleFlapCloseTooLong';
	this.alarm.openTooLong.name := 'middleFlapOpenTooLong';
	
END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	ioMappingInput;
	
	// setup flap function block
	this.flap.enable				:= TRUE;
	this.flap.cycleTime				:= em.status.cycleTime;
	this.flap.flapTime				:= interface.parameter.flapTime;
	this.flap.di_changeover 		:= this.hw.di_changeover;
	this.flap.simulation := gWingInterface.parameter.simulation;
	
	CASE em.mode OF
		MODE_PRODUCING,MODE_EMPTY: producing;
		MODE_MANUAL: testing;	// mode for testing flaps manually.
		ELSE em.cmd.sc := TRUE;
	END_CASE
	
	this.hw.do_open := this.flap.do_open;

	alarm;

	em();
	this.flap();
	
	// FAT test
	CASE testStateFAT OF
		
		0:
			IF interface.cmd.wingTestManual THEN
				// Only execute if flap is closed
				IF this.hw.do_open=FALSE THEN
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
				testStateFAT := 60;
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
				testStateFAT := 60;
			ELSIF this.flap.position = FLAP_CLOSED THEN
				testStateFAT 			:= 50;
			END_IF
		
		50:
			//wait 1s before closing
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#500ms;
			this.TON_test();
			
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				
				interface.status.testResultFAT := TRUE; // Good result
				testStateFAT := 60;
			END_IF
		
		60:
			// Reset error (if any) before finishing test
			this.flap.resetError := this.flap.error;
		
			IF NOT this.flap.error THEN
				interface.cmd.wingTestManual := FALSE; // signal test done
				
				// Start next test (we are done here)
				gBottomFlapInterface.cmd.wingTestManual := TRUE;
				testStateFAT := 0;
			END_IF
		
	END_CASE
 
END_PROGRAM

PROGRAM _EXIT

END_PROGRAM

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        