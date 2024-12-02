
ACTION producing:
	
	CASE em.state OF
	
		STATE_ACTIVATING:
			
			CASE em.substate OF
				
				0:
					IF (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
						em.substate := 10;
					END_IF
					
				
				10:
					// Wait 20ms to make sure recipe is in the global variable. (belt in faster cyclic than vibrator)
					
					this.timeMinInCount := this.timeMinInCount + em.status.cycleTime;
					IF this.timeMinInCount > 20000 THEN
						this.timeMinInCount := 0;
						// Load CF/LF countspeed from recipe
						CFCountSpeed := gVibratorInterface[0].status.countingSpeed;
						LFCountSpeed := gVibratorInterface[1].status.countingSpeed;
						interface.status.recipeLoaded := TRUE;
						em.substate := 20;
					END_IF
				
				20:
					em.cmd.sc := TRUE;

				
			END_CASE

		
		STATE_STOPPED:
			em.description 	:= 'Waiting for start command';
			
			IF gConfig.status.loadInitialValue[2] AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
				gConfig.status.loadInitialValue[2] := FALSE;
				recipe.countingSpeed := 300;
				recipe.useWaitSpeed := TRUE;
				recipe.waitSpeed := 110;
				recipe.rampUp := 50;
				recipe.rampDown := 30;
				recipe.itemGap := FALSE;
			END_IF
			
			// This case ONLY used for FAT
			CASE em.substate OF
				
				0:
					em.description := 'Wait for command';
					
					
					
					IF interface.cmd.doPhotoSensorTest THEN
						interface.status.photoSensorTestResult := TEST_NOT_DONE;
						this.hmi.statusFAT.torqueTestMaxProgress := 12000;
						this.hmi.statusFAT.torqueTestProgress := 0;
						this.hmi.statusFAT.photoSensorTestProgress := 0;
						this.hmi.statusFAT.photoSensorTestActive := TRUE;
						
						em.substate := 10;
					ELSIF interface.cmd.doPhotoSensorTestNoBelt THEN
						interface.cmd.doPhotoSensorTestNoBelt := FALSE;
						interface.status.photoSensorTestNoBeltResult := TEST_NOT_DONE;
						this.hmi.statusFAT.photoSensorTestNoBeltRunning := TRUE;
						this.timeElapsed := 0;
						em.substate := 50;
					END_IF
					
				10:
					em.description := 'Start servo and wait until it is running';
				
					interface.cmd.runManualTest := TRUE;
					interface.parameter.speedManualTest := 400;
					
//					IF this.hmi.cmd.stopPhotoSensorTest THEN	// stop cmd from user.
//						this.hmi.cmd.stopPhotoSensorTest := FALSE;
//						interface.status.photoSensorTestResult := TEST_STOPPED;
//						interface.cmd.startBelt := FALSE;
//						interface.par.beltSpeed := 0;
//						interface.cmd.doPhotoSensorTest := FALSE;
//						this.photoSensorTestProgress := 0;
//						this.hmi.status.photoSensorTestActive := FALSE;
//						em.substate := 0;
					IF axis.status.inMotion AND ABS(axis.status.actVelocity) > (interface.parameter.speedManualTest-50) THEN	// axis is running
						this.hmi.statusFAT.photoSensorTestProgress := 0;
						this.TON_photoSensorTest.PT := T#12000ms;
						this.TON_photoSensorTest.IN := FALSE;
						this.TON_photoSensorTest();
						// read parid for motor torque
						this.MC_BR_ReadParID_277.Axis := ADR(gAxisBelt);
						this.MC_BR_ReadParID_277.ParID := 277;
						this.MC_BR_ReadParID_277.DataType := ncPAR_TYP_REAL;
						this.MC_BR_ReadParID_277.DataAddress := ADR(this.motorTorque);
						this.MTDataMean_torque.Enable := TRUE;
						this.MTDataMean_torque.Reset := FALSE;
						this.MTDataMean_torque();
						
						em.substate := 11;
					END_IF
				
				11:
					em.description := 'Running photoSensor test';
					this.TON_photoSensorTest.IN := TRUE;
					// progress
					this.hmi.statusFAT.photoSensorTestProgress := TIME_TO_REAL(this.TON_photoSensorTest.ET);
					
					// read motor torque while running test.
					this.MC_BR_ReadParID_277.Execute := TRUE;	
					this.MC_BR_ReadParID_277.Axis := ADR(gAxisBelt);
					this.MC_BR_ReadParID_277.DataAddress := ADR(this.motorTorque);
			
					IF this.MC_BR_ReadParID_277.Done THEN
						this.MC_BR_ReadParID_277.Execute := FALSE;
					END_IF
					this.MC_BR_ReadParID_277();
					IF this.hmi.statusFAT.photoSensorTestProgress >= 2500 THEN
						this.MTDataMean_torque.Reset := TRUE;
						this.MTDataMean_torque.In := ABS(this.motorTorque);
					END_IF
					this.MTDataMean_torque();
					
//					IF this.hmi.cmd.stopPhotoSensorTest THEN	// stop cmd from user.
//						this.hmi.cmd.stopPhotoSensorTest := FALSE;
//						this.TON_photoSensorTest.IN := FALSE;
//						interface.status.photoSensorTestResult := TEST_STOPPED;
//						interface.cmd.startBelt := FALSE;
//						interface.par.beltSpeed := 0;
//						interface.cmd.doPhotoSensorTest := FALSE;
//						this.photoSensorTestProgress := 0;
//						this.hmi.status.photoSensorTestActive := FALSE;
//						this.MTDataMean_torque(Enable:=FALSE,Reset:=FALSE);
//						em.substate := 15;
					IF this.hw.di_photo THEN
						interface.status.photoSensorTestResult := TEST_NOT_OK;
						this.TON_photoSensorTest.IN := FALSE;
						interface.cmd.runManualTest := FALSE;
						interface.parameter.speedManualTest := 0;
						this.hmi.avgMotorTorque := this.MTDataMean_torque.Out;
						interface.cmd.doPhotoSensorTest := FALSE;
						this.hmi.statusFAT.photoSensorTestProgress := 0;
						this.hmi.statusFAT.photoSensorTestActive := FALSE;
						this.MTDataMean_torque(Enable:=FALSE,Reset:=FALSE);
						em.substate := 15;
					ELSIF this.TON_photoSensorTest.Q THEN		// TODO: distanceConveyorShouldRun=6000 is random. How long should it run??
						IF this.MTDataMean_torque.Out < 0.25 THEN
							interface.status.photoSensorTestResult := TEST_OK;
							this.TON_photoSensorTest.IN := FALSE;
							interface.cmd.runManualTest := FALSE;
							interface.parameter.speedManualTest := 0;
							this.hmi.avgMotorTorque := this.MTDataMean_torque.Out;
							this.MTDataMean_torque(Enable:=FALSE,Reset:=FALSE);
							interface.cmd.doPhotoSensorTest := FALSE;
							this.hmi.statusFAT.photoSensorTestActive := FALSE;
							em.substate := 15;
						ELSE
							interface.status.photoSensorTestResult := TEST_NOT_OK;
							this.TON_photoSensorTest.IN := FALSE;
							interface.cmd.runManualTest := FALSE;
							this.hmi.avgMotorTorque := this.MTDataMean_torque.Out;
							interface.parameter.speedManualTest := 0;
							interface.cmd.doPhotoSensorTest := FALSE;
							this.hmi.statusFAT.photoSensorTestProgress := 0;
							this.hmi.statusFAT.photoSensorTestActive := FALSE;
							this.MTDataMean_torque(Enable:=FALSE,Reset:=FALSE);
							em.substate := 15;
						END_IF
					END_IF
					this.TON_photoSensorTest();
					
				15:
					em.description := 'Wait for readParId to be done (not busy)';
					
					this.MC_BR_ReadParID_277.Execute := FALSE;	
					this.MC_BR_ReadParID_277.Axis := ADR(gAxisBelt);
					this.MC_BR_ReadParID_277.DataAddress := ADR(this.motorTorque);
					this.MC_BR_ReadParID_277();
					
					IF NOT this.MC_BR_ReadParID_277.Busy THEN
						em.substate := 0;
					END_IF
					
				50:
					em.description := 'Photo sensor test with no belt';
							
					this.timeElapsed := this.timeElapsed + em.status.cycleTime;
						
					IF this.timeElapsed > 20000000 THEN // 20s
						interface.status.photoSensorTestNoBeltResult := TEST_NOT_OK;
						interface.cmd.doPhotoSensorTestNoBelt := FALSE;
						this.hmi.statusFAT.photoSensorTestNoBeltRunning := FALSE;
						em.substate := 0;
					ELSIF this.hw.di_photo THEN
						interface.status.photoSensorTestNoBeltResult := TEST_OK;
						this.hmi.statusFAT.photoSensorTestNoBeltRunning := FALSE;
						interface.cmd.doPhotoSensorTestNoBelt := FALSE;
						em.substate := 0;
					END_IF
				
				
			END_CASE
			
			
	
			IF EDGENEG(interface.cmd.runManualTest)  THEN
				this.hmi.force.enable := FALSE;
			ELSIF interface.cmd.runManualTest THEN
				this.hmi.force.enable := TRUE;
				this.hmi.force.speed := interface.parameter.speedManualTest;
			END_IF
			
			this.hmi.status := 0;
			em.cmd.sc 		:= TRUE;
		
		STATE_RESETTING:
			
			this.TON_missingElements(IN := FALSE);
			this.hmi.force.enable := FALSE;
			this.teach.beltSpeed := 35;
			this.teach.attemptCount := 0;
			this.teach.TON_timeout(IN := FALSE);
			this.timeElapsed := 0;
			
			//set ramps for axis
	
			interface.status.speed	:= lego_speed_stop;
		

			CASE em.substate OF			
				0:
					em.description := 'power on axis';
			
					IF axis.status.powerOn THEN
						axis.parameter.homePosition := 0;
						axis.parameter.homeMode := mcHOME_DIRECT;
						axis.command.home := TRUE;
						em.substate := 10;
					ELSE
						axis.command.power := TRUE;
					END_IF
			
				10:
					em.description := 'home axis axis';

					IF axis.status.isHomed AND axis.status.actPosition = 0 THEN
						axis.command.home := FALSE;
						em.cmd.sc := TRUE;
					END_IF		
			END_CASE
		
	
			
		STATE_STARTING:
			
			interface.status.speed := lego_speed_stop;
			this.setSpeed := 0;
			brsmemset(ADR(this.distBetweenBricksFIFO),0,SIZEOF(this.distBetweenBricksFIFO)); // reset FIFO when starting. 
			this.fifoIdx := 0;
			this.forceBeltToRun := FALSE;
			gVibratorInterface[0].cmd.useWaitSpeed := gVibratorInterface[1].cmd.useWaitSpeed := FALSE; 
			IF this.hmi.brickLength<1 AND recipe.itemGap THEN // if no user input for brick length just set 20mm (some number).
				// Generate error?
				this.hmi.brickLength := 20;
			END_IF
			em.cmd.sc := TRUE;

		
		STATE_EXECUTE:
						
			CASE em.substate OF
				
				0:
					em.description := 'Waiting for command to run';
					
					IF interface.cmd.dropBrick THEN
						interface.status.speed := lego_speed_counting;
						this.timeMinInCount := 0;
						em.substate := 10;
					ELSIF interface.cmd.afterCount THEN
						interface.cmd.afterCount := FALSE;
						this.BrickCounter_0.Reset := TRUE;
						em.substate := 30;
					ELSIF this.BrickDetector_0.Out THEN
						interface.status.speed := lego_speed_stop;
					END_IF
					
				10:
					em.description := 'Counting portion';

					this.TON_missingElements.IN := TRUE;
					this.TON_missingElements.PT := T#10s;
					this.TON_missingElements();
					
					this.timeMinInCount := this.timeMinInCount + em.status.cycleTime; // Timer to latch lego_speed_count for min 1 cycle in 4.8ms (where vibrator is running) (we use UDINT because TON is not precise under 10ms)
					
					IF this.BrickCounter_0.Count >= interface.parameter.brickCountInPortion AND this.timeMinInCount >= 4800 THEN
						this.TON_missingElements.IN := FALSE;
						this.TON_missingElements();
						this.BrickCounter_0.Reset := TRUE;
						
						interface.status.speed := SEL(recipe.useWaitSpeed, lego_speed_stop, lego_speed_wait);
						em.substate := 20;
					END_IF
						
				20:
					em.description := 'Counting done';

					interface.status.dropBrickDone := TRUE;
					IF NOT interface.cmd.dropBrick THEN
						interface.status.dropBrickDone := FALSE;
						this.BrickCounter_0.Reset := FALSE;
						em.substate := 0;
					ELSIF this.BrickDetector_0.Out THEN
						interface.status.speed := lego_speed_stop;
					END_IF
				
				30:
					em.description := 'Handle aftercount';

					this.BrickCounter_0.Reset := FALSE;
					em.substate := 0;

			END_CASE
			
			// check what speeed to run		
			CASE interface.status.speed OF
				lego_speed_stop:
					this.hmi.status := 1;
					this.setSpeed 	:= 0;	
					
				lego_speed_counting:
					this.setSpeed := recipe.countingSpeed;
					this.hmi.status := 2;
 						
				lego_speed_wait:
					this.hmi.status := 3;
					this.setSpeed := recipe.waitSpeed;
				
			END_CASE
			
			
			em.cmd.sc := TRUE;

		STATE_COMPLETING:
			
			CASE em.substate OF
				
				0:
					this.setSpeed := 0;
					interface.status.speed := lego_speed_stop;
					this.hmi.enableAutoMode := FALSE; // Disable automode if empty of machine is triggered.
					
					IF this.updateSpeedState=0 THEN
						this.SpeedRippleCalc_0.Enable := FALSE;
						this.SpeedRippleCalc_0();
						this.TON_speedRipple.IN := FALSE;
						this.TON_speedRipple();
						this.speedRippleChanged := FALSE;
						em.substate := 2;
					END_IF
				
				2:
					
					em.description := 'Emptying at max speed';
				
					IF interface.cmd.stopDoingEmpty THEN
						em.substate := 5;
					ELSE
						
						IF this.updateSpeedState=0 THEN	// only set speed when motionControl is rdy. Otherwise it might not be set.
							this.setSpeed := 500; // Max speed
						END_IF
						interface.status.speed := lego_speed_counting;
						
					END_IF
					
					
					IF interface.cmd.calibrate THEN		
						em.substate := 10;
					END_IF
		
				5:
					em.description := 'Emptying - Waiting for wing to request brick';
					
					IF NOT interface.cmd.stopDoingEmpty THEN
						em.substate := 0;
					ELSE
						this.setSpeed := 0;
						interface.status.speed := lego_speed_stop;
					END_IF
		
					IF interface.cmd.calibrate THEN		
						em.substate := 10;
					END_IF
		
					
				10:
					commonStoppingHoldingCompletingAbortingSuspending; // only run this action and em.cmd.sc = TRUE
				
			END_CASE
			
			// Meassure speed ripple doing emptiing
			this.TON_speedRipple.IN := axis.parameter.velocity=this.setSpeed AND NOT this.speedRippleChanged;
			this.TON_speedRipple.PT := T#10s;
			this.TON_speedRipple();
			
			this.SpeedRippleCalc_0.Enable := TRUE;
			this.SpeedRippleCalc_0.Axis := ADR(gAxisBelt);
			this.SpeedRippleCalc_0();
			
			IF this.TON_speedRipple.Q THEN
				this.TON_speedRipple.IN := FALSE;
				this.TON_speedRipple();
				
				config.speedRipple := this.SpeedRippleCalc_0.Out;
				this.speedRippleChanged := TRUE;
				this.SpeedRippleCalc_0.Enable := FALSE;
				this.SpeedRippleCalc_0();
			END_IF
				
			
			
		
		STATE_SUSPENDED:
			
			em.description := 'wing ready to receive drop';
			
			em.cmd.sc := TRUE;
			
		STATE_STOPPING, STATE_ABORTING, STATE_HOLDING,STATE_SUSPENDING:
			
			commonStoppingHoldingCompletingAbortingSuspending;

			
		STATE_ABORTED:
			
			this.hmi.status := 4;
			
			IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortBelt') THEN
				em.cmd.sc := TRUE;
			END_IF
			
		STATE_CLEARING:
			
			commonClearing;
			
		ELSE
			
			em.cmd.sc := TRUE;
		
	END_CASE
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        