PROGRAM _INIT

	em.setup.name 			:= 'cassette';
	em.setup.lastActivated	:= TRUE;

	setupPointers;	

	interface.parameter.cassetteDetectTime := 10000;	// 10ms
	
	this.hwWu[0].do_active := TRUE;
	this.hwWu[1].do_active := TRUE;

END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	ioMappingInput;
		
	CASE em.mode OF
		MODE_PRODUCING: producing;
		ELSE em.cmd.sc := TRUE;
	END_CASE
	
	em();
	
	this.CassetteSync_0.NeighbourActive 				:= this.hw.di_neighbourActive;
	this.CassetteSync_0.di_neighbourBricksInCassette 	:= this.hw.di_neighbourBricksInCassette;
	this.CassetteSync_0();
	IF this.hmi.do_bricksReadyInCassetteForce THEN
		this.hw.do_bricksReadyInCassette := TRUE;
	ELSE
		this.hw.do_bricksReadyInCassette 					:= this.CassetteSync_0.do_bricksReadyInCassette;
	END_IF
	
	IF this.hmi.do_dosingForce THEN
		this.hw.do_dosing := TRUE;
	ELSE
		this.hw.do_dosing := interface.cmd.dosing;
	END_IF
	this.CassetteUtilization_0.Enable 				:= gMainInterface.status.state = STATE_EXECUTE;
	this.CassetteUtilization_0.Substate 			:= em.substate;
	this.CassetteUtilization_0.CycleTime			:= em.status.cycleTime;
	this.CassetteUtilization_0.CassetteCounter 		:= this.cassetteCounter;
	this.CassetteUtilization_0.WaitingForNeighbour 	:= gBottomFlapInterface.status.waitingForNeighbour;
	this.CassetteUtilization_0();
	this.hmi.waitForPortion 				:= this.CassetteUtilization_0.WaitForPortion;
	this.hmi.releaseCassette 				:= this.CassetteUtilization_0.ReleaseCassette;
	this.hmi.waitForNeighbour 				:= this.CassetteUtilization_0.WaitForNeighbour;
	this.hmi.waitForQueue 					:= this.CassetteUtilization_0.WaitForQueue;
	this.hmi.waitForCassette 				:= this.CassetteUtilization_0.WaitForCassette;
	
	this.hmi.cycleTimeStopStation			:= this.CassetteUtilization_0.WaitForPortion+this.CassetteUtilization_0.ReleaseCassette+this.CassetteUtilization_0.WaitForNeighbour;
	this.hmi.cycleTime						:= this.CassetteUtilization_0.WaitForPortion+this.CassetteUtilization_0.ReleaseCassette;
	this.hmi.cassettesReleased 				:= this.CassetteUtilization_0.CassettesReleased;
	this.hmi.cassetteQueueSensor			:= NOT this.hw.di_cassetteQueue;
	this.hmi.cassetteReadySensor			:= NOT this.hw.di_cassetteReady;
	
	this.FlowMeasure_0.Enable := TRUE;
	this.FlowMeasure_0.CassetteQueue := this.hw.di_cassetteQueue;
	this.FlowMeasure_0.CassetteReady := this.hw.di_cassetteReady;
	this.FlowMeasure_0();
	
	// TOFF cassette signals (for PP99 linecontroller to avoid that signals gets lost in communication)
	this.TOF_cassetteReady.IN := this.hw.di_cassetteReady;
	this.TOF_cassetteReady.PT := gWingInterface.status.timeTOF_cassetteSignals;
	this.TOF_cassetteReady();
	this.TOF_cassetteQueue.IN := this.hw.di_cassetteQueue;
	this.TOF_cassetteQueue.PT := gWingInterface.status.timeTOF_cassetteSignals;
	this.TOF_cassetteQueue();

	this.hmi.di_cassetteReady_TOF := this.TOF_cassetteReady.Q;
	this.hmi.di_cassetteQueue_TOF := this.TOF_cassetteQueue.Q;
	
	// global interfacing
	gEthernetIPInterface.status.di_cassetteReady := this.hw.di_cassetteReady;
	gEthernetIPInterface.status.di_cassetteQueue := this.hw.di_cassetteQueue;
	gEthernetIPInterface.status.do_cassetteRelease := this.hw.do_cassetteRelease;

	
	// FAT test
	CASE testStateFAT OF
		
		0:
			IF interface.cmd.wingTestManual THEN
				
				IF this.hw.do_cassetteRelease=FALSE THEN
					this.oldCassetteReady := this.hw.di_cassetteReady;
					this.hw.do_cassetteRelease := TRUE;
					testStateFAT := 10;
				END_IF
			END_IF
			
		10:
			this.TON_test.IN := TRUE;
			this.TON_test.PT := T#1s;
			this.TON_test();
		
			IF this.TON_test.Q THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				// Test Fail
				interface.status.testResultFAT := FALSE;
				testStateFAT := 20;
			ELSIF this.oldCassetteReady <> this.hw.di_cassetteReady THEN
				this.TON_test.IN := FALSE;
				this.TON_test();
				// Test OK
				interface.status.testResultFAT := TRUE;
				testStateFAT := 20;
			END_IF
		
		20:
			// Test done go back
			this.hw.do_cassetteRelease := FALSE;
			interface.cmd.wingTestManual := FALSE;
			testStateFAT := 0;
		
	END_CASE
	
END_PROGRAM

PROGRAM _EXIT
	 
END_PROGRAM

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        