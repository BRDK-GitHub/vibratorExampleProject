ACTION producing:
	
	CASE em.state OF
		
		STATE_ACTIVATING:
		
			// setup vibrator for closed loop current control
			CASE em.substate OF 
				
				0:
					em.description := 'Wait for config';
					
					IF gConfig.status.loaded THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 30;
					END_IF
				
				30:
					em.description := 'Set motor stator resistance';
					
					this.MC_BR_WriteParID_0.Execute 		:= TRUE;
					this.MC_BR_WriteParID_0.Axis 			:= SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
					this.MC_BR_WriteParID_0.ParID 			:= 60;
					this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_REAL;
					CASE i OF
						
						0:
							IF config.type=0 THEN
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_RESISTANCE_SMALL_CF);
							ELSE //big cf
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_RESISTANCE_BIG_CF);
							END_IF
						
						1:
							IF config.type=0 THEN
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_RESISTANCE_SMALL_LF);
							ELSE // big LF
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_RESISTANCE_BIG_LF);
							END_IF
						
					END_CASE
					this.MC_BR_WriteParID_0();
					
					IF this.MC_BR_WriteParID_0.Done THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 40;
					END_IF
					
				40:
					em.description := 'Set motor stator inductance';
					
					this.MC_BR_WriteParID_0.Execute 		:= TRUE;
					this.MC_BR_WriteParID_0.Axis 			:= SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
					this.MC_BR_WriteParID_0.ParID 			:= 61;
					this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_REAL;
					CASE i OF
						
						0:
							IF config.type=0 THEN
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_INDUCTANCE_SMALL_CF);
							ELSE //big cf
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_INDUCTANCE_BIG_CF);
							END_IF
						
						1:
							IF config.type=0 THEN
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_INDUCTANCE_SMALL_LF);
							ELSE // big LF
								this.MC_BR_WriteParID_0.DataAddress 	:= ADR(STATOR_INDUCTANCE_BIG_LF);
							END_IF
						
					END_CASE
					this.MC_BR_WriteParID_0();
					
					IF this.MC_BR_WriteParID_0.Done THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 50;
					END_IF
					
				50:
					em.description := 'Set current controller mode';
					
					this.MC_BR_WriteParID_0.Execute 		:= TRUE;
					this.MC_BR_WriteParID_0.Axis 			:= SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
					this.MC_BR_WriteParID_0.ParID 			:= 328;
					this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_USINT;
					this.MC_BR_WriteParID_0.DataAddress 	:= ADR(CONTROLLER_MODE);
					this.MC_BR_WriteParID_0();
					
					IF this.MC_BR_WriteParID_0.Done THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 60;
					END_IF
				
				60:
					em.description := 'Set the pointer of the reference current to the output of the internal frequency generator';
					
					this.MC_BR_WriteParID_0.Execute 		:= TRUE;
					this.MC_BR_WriteParID_0.Axis 			:= SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
					this.MC_BR_WriteParID_0.ParID 			:= 713;						// 713: CTRL Current controller: Set value parameter ID of stator current quadrature component 
					this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_UINT;
					this.MC_BR_WriteParID_0.DataAddress 	:= ADR(SINE_WAVE_GENERATOR);
					this.MC_BR_WriteParID_0();
					
					IF this.MC_BR_WriteParID_0.Done THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 70;
					END_IF
					
				70:
					em.cmd.sc := TRUE;

			END_CASE
			

		STATE_UNHOLDING, STATE_RESETTING:
			
			CASE em.substate OF
				
				0:
					em.description := 'Power on axis.';
				
					this.vibPercentAmplitude := this.vibAmplitude := 0;
					this.hmi.force.enable := FALSE;
					gVibratorInterface[i].status.forcing := FALSE;
					axis.command.power := TRUE;
					
					IF gMainInterface.status.simulation THEN
						axis.command.power := FALSE;
						em.substate := 10;
					ELSIF axis.status.powerOn THEN
						this.vibAmplitude := 0;
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 10;
					END_IF
				
				10:
					em.description := 'Determine how many linearization points that has been used';
					
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_IDX_AUTO_LINEARIZATION DO
						IF config.autoLinearizationCurrent[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
					this.linearizationTable.Enable := FALSE;
					this.linearizationTable();
					em.substate := 20;
					
				20:
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.linearizationTable.NodeVectorX[j] := config.autoLinearizationAccAtCurrent[j];
						this.linearizationTable.FcnValues[j] := config.autoLinearizationCurrent[j];
					END_FOR
					this.linearizationTable.Enable := TRUE;
					this.linearizationTable.NumberOfNodes   := this.pointsInLinearization;
					this.linearizationTable.Mode 			:= mtLOOKUP_LINEAR_EXTRAPOLATION;
					this.linearizationTable.Update			:= TRUE;
					this.linearizationTable();
					IF this.linearizationTable.UpdateDone THEN // TODO: Dont let machine be stuck in none linearization.
						this.linearizationTable.Update		:= FALSE;
						this.linearizationTable();
						
						em.substate := 30;
					END_IF
				
				30:
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF config.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					em.substate := 40;
					
				40:

					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.lookUpFrequency.NodeVectorX[j] := config.linearizationAmplitude[j];
						this.lookUpFrequency.FcnValues[j] := config.linearizationFrequencies[j];
					END_FOR
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.NumberOfNodes := this.pointsInLinearization;
					this.lookUpFrequency.Update := TRUE;
					this.lookUpFrequency();
					IF this.lookUpFrequency.UpdateDone THEN
						this.lookUpFrequency.Update := FALSE;
						this.lookUpFrequency();
						IF i=1 THEN
							em.substate := 50;
						ELSE
							em.substate := 60;
						END_IF
					END_IF
				
				50:
					em.description := 'Update limiter FB for LF ramps';
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.rampUp 	:= (this.vibPercentAmplitude)/(UDINT_TO_REAL(MAX(1,recipe.rampUp))/1000);
					this.MTBasicsLimiter_0.MaxPosSlewRate := this.rampUp;
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // Instant. We don't want to ramp down when stopping.
					this.MTBasicsLimiter_0.MinOut := 0;
					this.MTBasicsLimiter_0.MaxOut := 100; 
					this.MTBasicsLimiter_0.Update := TRUE;
					
					
					IF this.MTBasicsLimiter_0.UpdateDone THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.oldVibPercentAmplitude := -1; // to make sure we detect a change when starting vibrator.
						em.substate := 60;
					END_IF
					this.MTBasicsLimiter_0();
				60:
					em.description := 'Wait for state change';
					em.cmd.sc := TRUE;
				
			END_CASE
			
		STATE_IDLE:
			em.cmd.sc := TRUE;
			
		STATE_STARTING:
			em.cmd.sc := TRUE; // will move to Execute right away
		
		STATE_EXECUTE:
			
			CASE em.substate OF
				
				0:
					IF this.sweep.start THEN
						this.sweep.start := FALSE;
						em.substate := 200;
					ELSIF this.testAmplitude THEN
						// We know frequency but will manually test what 10% and 100% is
						this.vibAmplitude := 0;
						em.substate := 50;
					ELSIF this.testDefault THEN
						// Will do nothing so everything can be changed from monitor mode.
						em.substate := 1000;
					ELSIF this.testPercent THEN
					
						em.substate := 60;
					ELSIF this.testProdFlow THEN
						this.time.elapsed := 0;
						this.stateSimuPulse := 0;
						em.substate := 70;
					ELSIF gSimulation.status.simulateAllButWing THEN
						em.substate := 300;
					ELSE
						// PRODUCTION
						em.substate := 10;
					END_IF
				
				10:	// Production state
				
					CASE gBeltInterface.status.speed OF
						lego_speed_stop:
							em.description := 'Stopped, not using wait speed';
							this.vibPercentAmplitude := 0;
							interface.cmd.speed := lego_speed_stop;
				
						lego_speed_wait:
							em.description := 'running at waiting speed';
							IF this.oldSpeed = lego_speed_stop THEN
								IF gBeltInterface.status.autoMode THEN
									this.vibPercentAmplitude := SEL(i=0, gBeltInterface.status.LFCountSpeed, gBeltInterface.status.CFCountSpeed);
								ELSE
									this.vibPercentAmplitude := recipe.countingSpeed + gBeltInterface.status.adjustPercent;
								END_IF
								interface.cmd.speed := lego_speed_counting;
								this.time.elapsed := 0;
								em.substate := 20;
							ELSE
								IF gBeltInterface.status.autoMode THEN
									this.vibPercentAmplitude := SEL(i=0, gBeltInterface.status.LFWaitSpeed, gBeltInterface.status.CFWaitSpeed);
								ELSE
									this.vibPercentAmplitude := recipe.waitSpeed + gBeltInterface.status.adjustPercent;
								END_IF
								interface.cmd.speed := lego_speed_wait;
							END_IF
			
						lego_speed_counting:
							em.description := 'running at counting speed';
							IF gBeltInterface.status.autoMode THEN
								this.vibPercentAmplitude := SEL(i=0, gBeltInterface.status.LFCountSpeed, gBeltInterface.status.CFCountSpeed);
							ELSE
								this.vibPercentAmplitude := recipe.countingSpeed  + gBeltInterface.status.adjustPercent;
							END_IF
							interface.cmd.speed := lego_speed_counting;
							IF this.oldSpeed <> lego_speed_counting THEN
								this.time.elapsed := 0;
								em.substate := 20;
							END_IF
						
					END_CASE
					motionControl;
					this.oldSpeed := gBeltInterface.status.speed;
				
				20:
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					IF this.time.elapsed > this.minimumTimeInCount THEN
						em.substate := 10;
					END_IF
					motionControl;
					
				50:
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.InX := this.vibAmplitude;
					this.lookUpFrequency();
					this.vibFrequency := this.lookUpFrequency.Out;
				
					IF NOT this.testAmplitude THEN
						em.cmd.stop := TRUE;
					END_IF
					
					
				60:
					em.description := 'Test percent';
					
					motionControl;
					
					IF NOT this.testPercent THEN
						em.cmd.stop := TRUE;
					END_IF
						
					// Frequency sweep
				200:
					
					this.vibFrequency := this.sweep.frequencyStart;
					IF i=0 THEN
						IF config.type = 0 THEN
							this.vibAmplitude := this.sweep.amplitudeCFsmall;
						ELSE // big CF
							this.vibAmplitude := this.sweep.amplitudeCFlarge;
						END_IF
					ELSE //LF
						this.vibAmplitude := this.sweep.amplitudeLF;
					END_IF
		
					em.substate := 210;
					
				70: // simulate production flow.
					
					CASE this.stateSimuPulse OF
					
						0:	// CountSpeed
							this.vibPercentAmplitude := recipe.countingSpeed;
							interface.cmd.speed := lego_speed_counting;
							
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInCountSpeed THEN
								this.time.elapsed := 0;
								IF this.simuTimeInWaitSpeed > 0 THEN
									this.stateSimuPulse := 10;
								ELSE
									this.stateSimuPulse := 20;
								END_IF
							END_IF
						
						10:
							this.vibPercentAmplitude := recipe.waitSpeed;
							interface.cmd.speed := lego_speed_wait;
							
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInWaitSpeed THEN
								this.time.elapsed := 0;
								IF this.simuTimeInStopped > 0 THEN
									this.stateSimuPulse := 20;
								ELSE
									this.stateSimuPulse := 0;
								END_IF
							END_IF
						
						20:
							this.vibPercentAmplitude := 0;
							interface.cmd.speed := lego_speed_stop;
							
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInStopped THEN
								this.time.elapsed := 0;
								this.stateSimuPulse := 0;
							END_IF
						
					END_CASE
					motionControl;
					
					IF NOT this.testProdFlow THEN
						interface.cmd.speed := lego_speed_stop;
						em.substate := 0;
					END_IF
					
				210:
					em.description := 'Setup limiter block for controling frequency';
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := this.sweep.frequencyStart;
					this.MTBasicsLimiter_0.MaxOut := this.sweep.frequencyStop;
					this.MTBasicsLimiter_0.MaxPosSlewRate := this.sweep.freqChangeRate;
					this.MTBasicsLimiter_0.MaxNegSlewRate := this.sweep.freqChangeRate;
					this.MTBasicsLimiter_0.OutPresetValue := this.MTBasicsLimiter_0.MinOut;
					this.MTBasicsLimiter_0.SetOut := TRUE;
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone AND this.MTBasicsLimiter_0.Out=this.MTBasicsLimiter_0.MinOut THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.MTBasicsLimiter_0.SetOut := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						gVibratorInterface[i].status.maxPeakValue := 0;
						gVibratorInterface[i].status.highestAmplitudePeak := 0;
						gVibratorInterface[i].status.highestFrequencyPeak := 0;
						em.substate := 220;
					END_IF
					this.MTBasicsLimiter_0();
					
				220:
					em.description := 'Sweep from 46Hz to 54Hz';
			
					this.MTBasicsLimiter_0.In := this.sweep.frequencyStop;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out; // add with .MinOut because it is incrementing from 0.
						
	
						
					IF this.vibFrequency >= this.sweep.frequencyStop THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						this.MTBasicsLimiter_0.In := 0;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						em.cmd.stop := TRUE;
						em.substate := 0;
					END_IF
				
				300:
					em.description := 'Simulation - amplitude=0';
					
					interface.status.vibAmplitude := 0;
					interface.status.vibFrequency := 0;
					
					IF NOT gSimulation.status.simulateAllButWing THEN
						em.substate := 0;
					END_IF
					
				1000:
				
					IF NOT this.testDefault THEN
						this.vibAmplitude := 0;
						em.substate := 0;
					END_IF
						
				
			END_CASE
			
			
			em.cmd.sc := TRUE;
		STATE_SUSPENDED, STATE_UNSUSPENDING:
			
			
			em.cmd.sc := TRUE;
	
		STATE_COMPLETING: 
			
			CASE em.substate OF
				
				0: // Empty out (using recipe 1 with max speeds)
					em.description := 'Emptying - waiting for request';
					this.vibPercentAmplitude := 0;
					IF gBeltInterface.status.speed <> lego_speed_stop THEN
						IF gSimulation.status.simulateAllButWing THEN
							config.emptyPercent := 0;
						ELSIF config.emptyPercent = 0.0 THEN
							config.emptyPercent := SEL(i=0,95,60);
						END_IF
						
						this.time.elapsed := 0;
						this.vibPercentAmplitude := config.emptyPercent*0.5;
						em.substate := 3;
					END_IF
					
					
					IF interface.cmd.calibrate 	THEN
						this.calibrateState := 0;
						em.substate := 10;
					END_IF
					
				3:
					// use half amplitude for 700ms to protect vibrator mechanics.
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 700000 THEN
						em.substate := 5;
					END_IF
					
				5:
					em.description := 'Emptying - max  speed';
					this.vibPercentAmplitude := config.emptyPercent; //SEL(i=0,95,50);
					interface.cmd.speed := lego_speed_counting;
					
					IF gBeltInterface.status.speed = lego_speed_stop THEN
						interface.cmd.speed := lego_speed_stop;
						em.substate := 0;
					END_IF
			
					IF interface.cmd.calibrate 	THEN
						this.calibrateState := 0;
						this.time.elapsed := 0;
						this.vibPercentAmplitude := config.emptyPercent*0.5;
						em.substate := 8;
					END_IF
				
				8:
					// use half amplitude for 700ms to protect vibrator mechanics.
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 700000 THEN
						em.substate := 10;
					END_IF
					
				10:
					//	calibrating; // calling calibration action, this will set this.calibrateState to 80 when done
					
					em.cmd.sc := TRUE; //this.calibrateState = 110;		
				
				
				
			END_CASE
			
			motionControl;
			
		STATE_STOPPING, STATE_HOLDING, STATE_SUSPENDING:
	
			em.description := 'stopping vibrators';
			
			this.vibAmplitude := this.vibPercentAmplitude := interface.status.vibAmplitude := interface.status.percent := 0;
			interface.status.forcing := FALSE;
			interface.cmd.speed := lego_speed_stop;
			this.linearizationTable(Enable:=FALSE);
			this.lookUpFrequency(Enable:=FALSE);
			em.cmd.sc := TRUE;
			
			this.hmi.force.enable := FALSE;
			
			this.hmi.calibratingProcessing := this.hmi.cancelTuning := FALSE;
	
			em.cmd.sc := TRUE;
			
		STATE_ABORTING:
			em.description := 'stopping vibrators';
			axis.command.power := FALSE;
			this.vibAmplitude := this.vibPercentAmplitude := interface.status.vibAmplitude := interface.status.percent := 0;
			interface.status.forcing := FALSE;
			interface.cmd.speed := lego_speed_stop;
			this.linearizationTable(Enable:=FALSE);
			this.lookUpFrequency(Enable:=FALSE);
			em.cmd.sc := TRUE;
			
			this.hmi.force.enable := FALSE;
			
			this.hmi.calibratingProcessing := this.hmi.cancelTuning := FALSE;
	
			em.cmd.sc := TRUE;
			
		STATE_ABORTED:
			
			IF (i=0 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortCircularFeeder')) OR (i=1 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortLinearFeeder')) THEN
				em.cmd.sc := TRUE;
			END_IF
			
		STATE_CLEARING:
			
			em.description := 'clearing';
		
			axis.command.errorAcknowledge := axis.status.error.fault; // clear axis if we have any error
			
			em.cmd.sc := TRUE;
			
		ELSE
	
			em.description := 'power off - waiting for start - or force of axis';
			
			
			CASE em.substate OF
			
				0:
					IF this.hmi.force.enable THEN
						em.cmd.sc := FALSE;
						this.vibAmplitude := 0;
						gVibratorInterface[i].cmd.monitorActPeakValue := TRUE;
						gVibratorInterface[i].status.forcing := TRUE;
						em.substate := 10;
					ELSIF this.hmi.calibration.runTestPulses THEN
						IF config.autoLinearizationAccAtCurrent[0] <> 0.0 AND config.linearizationAmplitude[0] <> 0.0 AND localVariables[0].hmi.calibration.calibrationToolPlugged THEN
							em.cmd.sc := TRUE;
							this.hmi.calibration.activate := TRUE;
						ELSE
							// Not calibrated or calibration tool not connected -> we cant do test pulses.
							this.hmi.calibration.runTestPulses := FALSE;
						END_IF
					ELSE
						axis.command.power := FALSE; // enable power if forced on HMI.
						gVibratorInterface[i].status.forcing := FALSE;
						em.cmd.sc := TRUE;	
					END_IF
				
				10:
					axis.command.power := TRUE;
	
					
					IF axis.status.powerOn THEN
						// powered
						gVibratorInterface[i].cmd.readCurrentAndVoltage := TRUE;
						IF i=0 AND localVariables[0].hmi.config.type=1 THEN	 
							// if big cf it is ok to have freq around 25
							IF config.vibFrequency > 26 OR config.vibFrequency < 22 THEN
								config.vibFrequency := 24; // freq is crazy just set 24hz.
							END_IF
						ELSIF config.vibFrequency > 60 OR config.vibFrequency < 40 THEN
							// frequency is crazy. just put some approx guess
							config.vibFrequency := SEL(i=0,51,49);
						END_IF
						em.substate := 15;
					END_IF
					
				15:
					IF config.autoLinearizationCurrent[0] = 0.0 THEN
						em.substate := 25;
					ELSE
						this.pointsInLinearization := 0;
						FOR j:=0 TO MAX_LOOKUP_POINTS DO
							IF config.linearizationAmplitude[j]=0.0 THEN
								EXIT;
							ELSE
								this.pointsInLinearization := this.pointsInLinearization + 1;
							END_IF
						END_FOR
						em.substate := 18;
					END_IF
					
				18:

					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.lookUpFrequency.NodeVectorX[j] := config.linearizationAmplitude[j];
						this.lookUpFrequency.FcnValues[j] := config.linearizationFrequencies[j];
					END_FOR
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.NumberOfNodes := this.pointsInLinearization;
					this.lookUpFrequency.Update := TRUE;
					this.lookUpFrequency();
					IF this.lookUpFrequency.UpdateDone THEN
						this.lookUpFrequency.Update := FALSE;
						this.lookUpFrequency();
						em.substate := 20;
					END_IF
				
				20: //force whatever user is putting on HMI with variable freq.
					IF this.hmi.force.enable THEN
						this.vibAmplitude := this.hmi.force.current;
						// Update frequency depending on vibAmplitude
						this.lookUpFrequency.Enable := TRUE;
						this.lookUpFrequency.InX := this.vibAmplitude;
						this.lookUpFrequency();
						this.vibFrequency := this.lookUpFrequency.Out;
					
						this.vibFrequency := LIMIT(0,this.vibFrequency,54);
					ELSE
						// done forcing.
						this.time.elapsed := 0;
						this.lookUpFrequency.Enable := FALSE;
						this.lookUpFrequency();
						this.vibAmplitude := this.vibAmplitude*0.5;
						em.substate := 30;
					END_IF
					interface.status.vibAmplitude := this.vibAmplitude;
					interface.status.vibFrequency := this.vibFrequency;
					
				25: //force whatever user is putting on HMI without variable freq.
					IF this.hmi.force.enable THEN
						this.vibAmplitude := this.hmi.force.current;
						// use static frequency because machine has no calibration:
						this.vibFrequency := config.vibFrequency;
						this.vibFrequency := LIMIT(0,this.vibFrequency,54);
					ELSE
						// done forcing.
						this.time.elapsed := 0;
						this.lookUpFrequency.Enable := FALSE;
						this.lookUpFrequency();
						this.vibAmplitude := this.vibAmplitude*0.5;
						em.substate := 30;
					END_IF
					interface.status.vibAmplitude := this.vibAmplitude;
					interface.status.vibFrequency := this.vibFrequency;
					
					
				30: // ramp down  
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 1000000 THEN //1s
						gVibratorInterface[i].cmd.readCurrentAndVoltage := FALSE;
						this.vibAmplitude := 0;
						gVibratorInterface[i].cmd.monitorActPeakValue := FALSE;
						gVibratorInterface[i].status.forcing := FALSE;
						em.substate := 0;
					END_IF
					interface.status.vibAmplitude := this.vibAmplitude;
					interface.status.vibFrequency := this.vibFrequency;
				
			END_CASE
			
			IF gConfig.status.loadInitialValue[1] AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
				gConfig.status.loadInitialValue[1] := FALSE;
				localVariables[0].hmi.recipe.countingSpeed := 30;
				localVariables[0].hmi.recipe.waitSpeed := 30;
				localVariables[1].hmi.recipe.countingSpeed := 30;
				localVariables[1].hmi.recipe.rampUp := 0;
				localVariables[1].hmi.recipe.waitSpeed := 30;
			END_IF
			

	END_CASE
 
END_ACTION