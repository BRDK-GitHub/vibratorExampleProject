
ACTION calibratingMode:
	
	CASE em.state OF
		
		STATE_STOPPED:
			
		
			em.cmd.sc := TRUE;
		
		STATE_STARTING:
			
		
			CASE em.substate OF
				
				0:
					em.description := 'Power on axis.';
				
					this.vibPercentAmplitude := this.vibAmplitude := 0;
					this.hmi.force.enable := FALSE;
					IF this.hmi.calibration.activate THEN
						axis.command.power := TRUE;
						
					
					
						IF axis.status.powerOn THEN
							this.vibAmplitude := 0;
							this.MC_BR_WriteParID_0(Execute := FALSE);
							this.hmi.linearizationGoalValue := configTmp.pointX1;
							gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
							this.hmi.calibration.increaseBoost := FALSE;
							this.hmi.calibration.decreaseBoost := FALSE;
							this.hmi.calibration.increaseBrake := FALSE;
							this.hmi.calibration.decreaseBrake := FALSE;
							em.cmd.sc := TRUE;
							gVibratorInterface[i].cmd.monitorActPeakValue := TRUE;
							this.hmi.calibration.enableBoostBrakeAdjustment := TRUE;
							this.hmi.calibration.enableStopButton := FALSE;
							em.substate := 10;
						END_IF
					ELSE
						em.cmd.sc := TRUE;
					END_IF
				10:
					em.description := 'Wait for SC';
				
				
				
			END_CASE
						
		STATE_EXECUTE:
		
			CASE em.substate OF
				
				0:
					// Jump to different substate depending if CF/LF small/big
					IF this.hmi.calibration.testBoost THEN
						this.hw.do_isBigCF := interface.status.isBigCF := i=0 AND gVibratorInterface[0].status.machineType=1;
						local_no_opcua[0].configTmp := localVariables[0].hmi.config;
						local_no_opcua[1].configTmp := localVariables[1].hmi.config;
						em.substate := 190;	
					ELSIF this.hmi.calibration.runTestPulses THEN
						this.hw.do_isBigCF := interface.status.isBigCF := i=0 AND gVibratorInterface[0].status.machineType=1;
						local_no_opcua[0].configTmp := localVariables[0].hmi.config;
						local_no_opcua[1].configTmp := localVariables[1].hmi.config;
						
						brsmemset(ADR(local.configTmp.caliPulseBufferAcc),0,SIZEOF(local.configTmp.caliPulseBufferAcc));
						brsmemset(ADR(local.configTmp.caliPulseEstimatedPct),0,SIZEOF(local.configTmp.caliPulseEstimatedPct));
						em.substate := 950;
					ELSIF this.hmi.calibration.activate THEN
						this.hw.do_isBigCF := interface.status.isBigCF := i=0 AND gVibratorInterface[0].status.machineType=1;
						this.hmi.calibration.enableStopButton := TRUE;
						this.hmi.calibration.enableBoostBrakeAdjustment := FALSE;
						// reset linearization
						local_no_opcua[0].configTmp := localVariables[0].hmi.config;
						local_no_opcua[1].configTmp := localVariables[1].hmi.config;
						
						brsmemset(ADR(local.configTmp.linearizationPercent),0,SIZEOF(local.configTmp.linearizationPercent));
						brsmemset(ADR(local.configTmp.autoLinearizationAccAtCurrent),0,SIZEOF(local.configTmp.autoLinearizationAccAtCurrent));
						brsmemset(ADR(local.configTmp.linearizationCurrent),0,SIZEOF(local.configTmp.linearizationCurrent));
						brsmemset(ADR(local.configTmp.autoLinearizationCurrent),0,SIZEOF(local.configTmp.autoLinearizationCurrent));
						brsmemset(ADR(local.configTmp.linearizationFrequencies),0,SIZEOF(local.configTmp.linearizationFrequencies));
						brsmemset(ADR(local.configTmp.linearizationAmplitude),0,SIZEOF(local.configTmp.linearizationAmplitude));
						brsmemset(ADR(local.configTmp.caliPulseBufferAcc),0,SIZEOF(local.configTmp.caliPulseBufferAcc));
						brsmemset(ADR(local.configTmp.caliPulseEstimatedPct),0,SIZEOF(local.configTmp.caliPulseEstimatedPct));
						configTmp.amplitudeFineTuning := 0.0;
						
						
						this.calibration.TON_0(IN:=FALSE); // reset
						this.calibration.TON_0.PT := this.calibration.timeToGetVibrWarm;
						this.calibration.analogVib := 0;
						this.hmi.showErrorMsgLinearization := TRUE;
						// Set hardcoded values for linearization points:
						IF local_no_opcua[0].configTmp.type=0 THEN 	// small cf
							local_no_opcua[0].configTmp.pointX1 := 10;
							local_no_opcua[0].configTmp.pointY1 := 53*52;
							local_no_opcua[0].configTmp.pointX2 := 100;
							local_no_opcua[0].configTmp.pointY2 := 335*52;
							// LF
							local_no_opcua[1].configTmp.pointX1 := 10;
							local_no_opcua[1].configTmp.pointY1 := 25*52;
							local_no_opcua[1].configTmp.pointX2 := 100;
							local_no_opcua[1].configTmp.pointY2 := 195*52;
						ELSE 					// large CF
							local_no_opcua[0].configTmp.pointX1 := 10;
							local_no_opcua[0].configTmp.pointY1 := 28*52;
							local_no_opcua[0].configTmp.pointX2 := 100;
							local_no_opcua[0].configTmp.pointY2 := 155*52;
							// LF
							local_no_opcua[1].configTmp.pointX1 := 10;
							local_no_opcua[1].configTmp.pointY1 := 29*52;
							local_no_opcua[1].configTmp.pointX2 := 100;
							local_no_opcua[1].configTmp.pointY2 := 170*52;
						END_IF
						this.hmi.linearizationGoalValue := configTmp.pointX1;
						
						CASE i OF // choose ampl/freq for long test to get warm.
							
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibAmplitude := this.calibration.sweepAmpl3CF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl3CFbig;
								END_IF	
							
							1: //LF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibAmplitude := this.calibration.sweepAmpl3LF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl3LFbig; // not necessary to warm up at 100% - therefore use 0.02A less. 
								END_IF	
							
						END_CASE
						
					
						
						
						// go to fast sweep
						this.vibFrequency := 45;
						em.substate := 20;
					
					ELSE
						em.cmd.sc := TRUE;
						em.substate := 2222; // this vibrator is not calibrating - jump down and wait.. 
					END_IF
	
				
					
				20:
					em.description := 'Setup limiter';
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					IF i=0 AND local_no_opcua[0].configTmp.type = 1 THEN
						// big CF uses different freq range.
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.1;
						this.MTBasicsLimiter_0.MinOut := 22;
						this.MTBasicsLimiter_0.MaxOut := 25.5;
					ELSE
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.25;
						this.MTBasicsLimiter_0.MinOut := 45;
						this.MTBasicsLimiter_0.MaxOut := 55;
					END_IF
					
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.OutPresetValue := this.MTBasicsLimiter_0.MinOut;
					this.MTBasicsLimiter_0.SetOut := TRUE;
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone AND this.MTBasicsLimiter_0.Out=this.MTBasicsLimiter_0.MinOut THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.MTBasicsLimiter_0.SetOut := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := TRUE;
						em.substate := 30;
					END_IF
					this.MTBasicsLimiter_0();
					
				30:
					em.description := 'Fast sweep';
					//
					this.MTBasicsLimiter_0.Enable := TRUE;

					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out; 
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						this.calibration.maxFreqFastSweep := gVibratorInterface[i].status.highestFrequency;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
						
						//set amplitude for warm up:
						IF NOT this.calibration.bypassWarmUp THEN
							this.vibFrequency := this.calibration.maxFreqFastSweep;
							this.calibration.TON_0.IN := FALSE;
							this.calibration.TON_0();
							em.substate := 40;
						ELSE
							this.vibAmplitude := 0;
							em.substate := 100;
						END_IF
							
						
					END_IF
					
				40:
					em.description := 'Running vibrator at high amplitude for some time to make it warm';
					gVibratorInterface[i].cmd.monitorMaxPeakValue := TRUE;
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						// vibrator warm -> go to fast sweep.
						gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
						em.substate := 100;
					END_IF
					
					// -------------------- RESSONANCE SWEEPS --------------------
					// ------------------------- SWEEP 1 -------------------------
				100:
					em.description := 'Set frequency to start freq for first slow sweep';
					
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
				
					IF i=0 AND local_no_opcua[0].configTmp.type = 1 THEN
						this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreqFastSweep-0.6; //
						this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreqFastSweep+0.5; //
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.01;	 // slower if big CF because it uses half frequency.
					ELSE
						this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreqFastSweep-0.5; //
						this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreqFastSweep+0.5; //
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;	 // slow going up.
					END_IF
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.OutPresetValue := this.MTBasicsLimiter_0.MinOut;
					this.MTBasicsLimiter_0.SetOut := TRUE;
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone AND this.MTBasicsLimiter_0.Out=this.MTBasicsLimiter_0.MinOut THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.MTBasicsLimiter_0.SetOut := FALSE;
						
						// set freq/ampl for sweep1
						this.vibFrequency := this.MTBasicsLimiter_0.MinOut;
						
						CASE i OF // choose ampl for sweep1 at high ampl.
							
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibAmplitude := this.calibration.sweepAmpl3CF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl3CFbig;
								END_IF	
							
							1: //LF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 	
									this.vibAmplitude := this.calibration.sweepAmpl3LF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl3LFbig;
								END_IF	
							
						END_CASE
						
						this.calibration.TON_0(IN:=FALSE);
						em.substate := 110;
					END_IF
					this.MTBasicsLimiter_0();
					
					
				110:
					em.description := 'Wait 3s before we start measure of max amplitude.';
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#3s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						// start monitor and sweep freq
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := TRUE;
						
						em.substate := 120;
					END_IF
					
				120:
					em.description := 'Sweep1 at high amplitude';
					
					this.MTBasicsLimiter_0.Enable := TRUE;

					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out; 
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						
						
						configTmp.linearizationFrequencies[2] := SEL(gVibratorInterface[0].status.machineType=0,gVibratorInterface[i].status.highestFrequency+VIBRATOR_FREQ_OFFSET_BIG_CF,gVibratorInterface[i].status.highestFrequency+VIBRATOR_FREQ_OFFSET); 
						configTmp.linearizationAmplitude[2] := this.vibAmplitude;
						
//						IF i=1 THEN	// if LF use a=-10
//							configTmp.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequency+0.1; 
//							configTmp.linearizationAmplitude[1] := this.vibAmplitude-0.01;
//							configTmp.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequency+0.2; 
//							configTmp.linearizationAmplitude[0] := this.vibAmplitude-0.02;
//						ELSIF i=0 AND local_no_opcua[0].configTmp.type = 1 THEN // big cF
//							configTmp.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequency+0.07; 
//							configTmp.linearizationAmplitude[1] := this.vibAmplitude-0.1;
//							configTmp.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequency+0.14; 
//							configTmp.linearizationAmplitude[0] := this.vibAmplitude-0.2;
//						ELSIF i=0 AND local_no_opcua[0].configTmp.type = 0 THEN // small CF
//							configTmp.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequency+0.14; 
//							configTmp.linearizationAmplitude[1] := this.vibAmplitude-0.1;
//							configTmp.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequency+0.28; 
//							configTmp.linearizationAmplitude[0] := this.vibAmplitude-0.2;
//						END_IF
						gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
						this.vibAmplitude := 0;
						configTmp.vibFrequency := gVibratorInterface[i].status.highestFrequency;
						em.substate := 130;
					END_IF
					
					// -------------------- RESSONANCE SWEEPS --------------------
					// ------------------------- SWEEP 2 -------------------------
					
				130:
					em.description := 'Set frequency to start freq for second slow sweep';
					
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := configTmp.linearizationFrequencies[2]; //
					this.MTBasicsLimiter_0.MaxOut := configTmp.linearizationFrequencies[2]+1.0; //
					IF i=0 AND local_no_opcua[0].configTmp.type = 1 THEN
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.01;	 // slower if big CF because it uses half frequency.
					ELSE
						this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;	 // slow going up.
					END_IF
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.OutPresetValue := this.MTBasicsLimiter_0.MinOut;
					this.MTBasicsLimiter_0.SetOut := TRUE;
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone AND this.MTBasicsLimiter_0.Out=this.MTBasicsLimiter_0.MinOut THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.MTBasicsLimiter_0.SetOut := FALSE;
						
						// set freq/ampl for sweep1
						this.vibFrequency := this.MTBasicsLimiter_0.MinOut;
						
						CASE i OF // choose ampl for sweep1 at medium ampl.
							
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibAmplitude := this.calibration.sweepAmpl2CF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl2CFbig;
								END_IF	
							
							1: //LF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 	
									this.vibAmplitude := this.calibration.sweepAmpl2LF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl2LFbig;
								END_IF	
							
						END_CASE
						
						this.calibration.TON_0(IN:=FALSE);
						em.substate := 140;
					END_IF
					this.MTBasicsLimiter_0();
					
					
				140:
					em.description := 'Wait 3s before we start measure of max amplitude.';
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#3s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						// start monitor and sweep freq
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := TRUE; 
						
						em.substate := 150;
					END_IF
					
				150:
					em.description := 'Sweep2 at high amplitude';
					
					this.MTBasicsLimiter_0.Enable := TRUE;

					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out; 
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						configTmp.linearizationFrequencies[0] := SEL(gVibratorInterface[0].status.machineType=0,gVibratorInterface[i].status.highestFrequency+VIBRATOR_FREQ_OFFSET_BIG_CF,gVibratorInterface[i].status.highestFrequency+VIBRATOR_FREQ_OFFSET); 
						configTmp.linearizationAmplitude[0] := this.vibAmplitude;

						configTmp.linearizationFrequencies[1] := configTmp.linearizationFrequencies[0] + ((configTmp.linearizationFrequencies[2]-configTmp.linearizationFrequencies[0])/2); // CHANGE TO FILTERED VERSION.
						configTmp.linearizationAmplitude[1] := configTmp.linearizationAmplitude[0] + ((configTmp.linearizationAmplitude[2]-configTmp.linearizationAmplitude[0])/2);
						gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
						this.vibAmplitude := 0;
						//
						
						em.substate := 190;
					END_IF
					
					// -------------------- RESSONANCE SWEEPS --------------------
					// ------------------------- SWEEP 3 -------------------------
					
				160:
					em.description := 'Set frequency to start freq for second slow sweep';
					
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := configTmp.linearizationFrequencies[1]; //
					this.MTBasicsLimiter_0.MaxOut := configTmp.linearizationFrequencies[1]+0.75; //
					this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;	 // slow going up.
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.OutPresetValue := this.MTBasicsLimiter_0.MinOut;
					this.MTBasicsLimiter_0.SetOut := TRUE;
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone AND this.MTBasicsLimiter_0.Out=this.MTBasicsLimiter_0.MinOut THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.MTBasicsLimiter_0.SetOut := FALSE;
						
						// set freq/ampl for sweep1
						this.vibFrequency := this.MTBasicsLimiter_0.MinOut;
						
						CASE i OF // choose ampl for sweep1 at medium ampl.
							
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibAmplitude := this.calibration.sweepAmpl1CF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl1CFbig;
								END_IF	
							
							1: //LF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 	
									this.vibAmplitude := this.calibration.sweepAmpl1LF;
								ELSE // big machine
									this.vibAmplitude := this.calibration.sweepAmpl1LFbig;
								END_IF	
							
						END_CASE
						
						this.calibration.TON_0(IN:=FALSE);
						em.substate := 170;
					END_IF
					this.MTBasicsLimiter_0();
					
					
				170:
					em.description := 'Wait 3s before we start measure of max amplitude.';
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#3s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						// start monitor and sweep freq
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := TRUE; 
						
						em.substate := 180;
					END_IF
					
				180:
					em.description := 'Sweep3 at high amplitude';
					
					this.MTBasicsLimiter_0.Enable := TRUE;

					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out; 
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						configTmp.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequency; 
						configTmp.linearizationAmplitude[0] := this.vibAmplitude;
						gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
						this.vibAmplitude := 0;
						//
						
						em.substate := 185;
					END_IF
					
				185:
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						em.substate := 190;
					END_IF
					
				190:
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF configTmp.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.lookUpFrequency.NodeVectorX[j] := configTmp.linearizationAmplitude[j];
						this.lookUpFrequency.FcnValues[j] := configTmp.linearizationFrequencies[j];
					END_FOR
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.NumberOfNodes := this.pointsInLinearization;
					this.lookUpFrequency.Update := TRUE;
					this.lookUpFrequency();
					
					IF this.lookUpFrequency.UpdateDone THEN
						this.lookUpFrequency.Update := FALSE;
						this.lookUpFrequency();
						// Set max amplitude / frequency depending on vibrator
						CASE i OF
							
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									local.calibration.maxAmplitude := 1.7;
									local.calibration.maxVibration := 17420;
									local.calibration.stepSizeAmplitude := 0.15;
									this.vibAmplitude := 0.3;
								ELSE // big machine
									local.calibration.maxAmplitude := 2.7;
									local.calibration.maxVibration := 8060;
									local.calibration.stepSizeAmplitude := 0.15;
									this.vibAmplitude := 0.9;
								END_IF	
							
							1: //LF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 	
									local.calibration.maxAmplitude := 0.18;
									local.calibration.maxVibration := 10140;
									local.calibration.stepSizeAmplitude := 0.015;
									this.vibAmplitude := 0.02;
								ELSE // big machine
									local.calibration.maxAmplitude := 0.18;
									local.calibration.maxVibration := 8840;
									local.calibration.stepSizeAmplitude := 0.015;
									this.vibAmplitude := 0.04;
								END_IF	
							
						END_CASE
					
						this.TON_delay(IN:=FALSE);
						j:=0;
						
						em.substate := 203;
					END_IF	
				
				203: // wait small time before making first step to make sure vibrator is stoppped.
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay(IN:=FALSE);
						em.substate := 200;
					END_IF	
					
				200: // Auto stepping current to match which % matches which current [A]
					
					// change frequency using newly created LUT
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.InX := this.vibAmplitude;
					this.lookUpFrequency();
					this.vibFrequency := this.lookUpFrequency.Out;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#4s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay(IN:=FALSE);
						
						configTmp.autoLinearizationCurrent[j] := this.vibAmplitude;
						configTmp.autoLinearizationAccAtCurrent[j] := interface.status.currAccelerometerValue;
						j := j + 1;
						
						IF interface.status.currAccelerometerValue >= local.calibration.maxVibration OR this.vibAmplitude >= local.calibration.maxAmplitude OR j > MAX_IDX_AUTO_LINEARIZATION THEN
							this.vibAmplitude := 0;
							em.substate := 300;
						ELSE
							local.calibration.tmpAmplitude := this.vibAmplitude;
							this.vibAmplitude := 0;
							em.substate := 205;
						END_IF
						
					END_IF
					
				205:
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#4s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay(IN:=FALSE);
							
						this.vibAmplitude := local.calibration.tmpAmplitude + local.calibration.stepSizeAmplitude;
						em.substate := 200;
					END_IF		
				
				300:
					em.description := 'Determine how many linearization points that has been used';
					
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_IDX_AUTO_LINEARIZATION DO
						IF configTmp.autoLinearizationCurrent[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					em.substate := 303;
					
				303:
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.linearizationTable.NodeVectorX[j] := configTmp.autoLinearizationAccAtCurrent[j];
						this.linearizationTable.FcnValues[j] := configTmp.autoLinearizationCurrent[j];
					END_FOR
					this.linearizationTable.Enable := TRUE;
					this.linearizationTable.NumberOfNodes   := this.pointsInLinearization;
					this.linearizationTable.Mode 			:= mtLOOKUP_LINEAR_EXTRAPOLATION;
					this.linearizationTable.Update			:= TRUE;
					this.linearizationTable();
					IF this.linearizationTable.UpdateDone THEN 
						this.linearizationTable.Update		:= FALSE;
						this.linearizationTable();
						// Go find brake parameters 
						CASE i OF // choose ampl for sweep1 at medium ampl.
						
							0: //CF
								IF local_no_opcua[0].configTmp.type = 0 THEN // Small machine 
									this.vibPercentAmplitude := 140.0; // 140% corresponds to 1.5A on machines that we tested with in Odense
								ELSE // big machine
									this.vibPercentAmplitude := 100.0; // 112% corresponds to 2.5A on machines that we tested with in Odense
								END_IF	
						
							1: //LF
								this.vibPercentAmplitude := 24.0; // 24% corresponds to 0.06A on machines that we tested with in Odense
							
						
						END_CASE
						caliMotionControl;
						configTmp.brakeFrequency := this.vibFrequency-0.5;
						this.calibration.startBrakeFrequency := this.vibFrequency;
						configTmp.brakeAmplitude := this.vibAmplitude;
					
						this.calibration.minAcceleration := 99999999;
						
						this.vibPercentAmplitude := 0;
						caliMotionControl;
						
						em.substate := 305;
					END_IF
					
				305:
					this.vibPercentAmplitude := 0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						em.substate := 310;
					END_IF
					
				310:
					em.description := 'find brake parameters';
					
					this.vibPercentAmplitude := 70.0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						em.substate := 320;
					END_IF
					
				320:
					em.description := 'find brake parameters';

					interface.status.calibrateBrake := TRUE;
					interface.status.calibrateBraketime := 0.5;
					interface.status.calibrateBrakeAmplitudeEnd := 0.0;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#300ms;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						
						interface.status.calibrateBrake := FALSE;
						
						IF interface.status.minAcceleration < this.calibration.minAcceleration THEN
							this.calibration.minAcceleration := interface.status.minAcceleration;
							this.calibration.minAccelerationTime := interface.status.minAccelerationTime;
							this.calibration.minAccelerationStart := interface.status.minAccelerationStart;
							this.calibration.minFrequency := configTmp.brakeFrequency;
						END_IF
						
						this.TON_delay.IN := FALSE;
						this.TON_delay();

						em.substate := 330;
					END_IF	
					
				330:
					
					IF configTmp.brakeFrequency >= this.calibration.startBrakeFrequency + 0.5 THEN
						configTmp.brakeFrequency := this.calibration.minFrequency;
						configTmp.boostFrequency := configTmp.brakeFrequency;			 // Brake frequency = boost frequency because they use same amplitude!
						configTmp.brakeVelocity := SEL(this.calibration.minAccelerationTime <> 0,0,(this.calibration.minAccelerationStart-this.calibration.minAcceleration)/this.calibration.minAccelerationTime);
						configTmp.brakeVelocity := configTmp.brakeVelocity/1.10;
						em.substate := 340;
					ELSE
						configTmp.brakeFrequency := configTmp.brakeFrequency + 0.1;
						em.substate := 305;
					END_IF
					
				340:
					// BOOST
					em.description := 'find boost parameters';

					this.vibPercentAmplitude := 0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#4s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						CASE i OF 
							
							0: //CF uses 140% for small cf and 110% for big cf
								this.vibPercentAmplitude := 140.0; 
								caliMotionControl;
								IF interface.status.machineType = 0 THEN
									configTmp.boostAmplitude := LIMIT(0,this.vibAmplitude,2.0); 
								ELSE
									configTmp.boostAmplitude := LIMIT(0,this.vibAmplitude,3.0); 
								END_IF
							
							1: //LF uses 100% for boost
								this.vibPercentAmplitude := 120;
								caliMotionControl;
								configTmp.boostAmplitude := LIMIT(0,this.vibAmplitude,0.2); 
							
						END_CASE
						
						configTmp.boostVelocityLow := 0;
						configTmp.boostVelocityHigh := 0;
					
						em.substate := 350;
					END_IF
					
				350:
					em.description := 'find boost parameters';
					
					interface.status.calibrateBoost := TRUE;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#2s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.vibPercentAmplitude := 0;
						caliMotionControl;
						
						configTmp.boostVelocityLow := interface.status.caliBoostVelocityLow/1.1;
						configTmp.boostVelocityHigh := interface.status.caliBoostVelocityHigh/1.1;	// divide to make sure that we overshoot for next test.
						
						interface.status.calibrateBoost := FALSE;
						
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						interface.status.caliProdTest := TRUE;
						 
						local.calibration.countPulsesToFinetune := 0;
						em.substate := 400;
					END_IF
					
					
				400:
					this.vibPercentAmplitude := 0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						em.substate := 410;
					END_IF
					
				410:
					this.vibPercentAmplitude := 70;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						IF (interface.status.maxBoostPercent > interface.status.filteredAccelerometerPercent+4.0 AND NOT local.calibration.boostCaliDone) AND configTmp.boostVelocityLow < 300000 THEN
							configTmp.boostVelocityLow := configTmp.boostVelocityLow*1.05;
							configTmp.boostVelocityHigh := configTmp.boostVelocityHigh*1.05;
						ELSE
							local.calibration.boostCaliDone := TRUE;
						END_IF
						
						em.substate := 420;
					END_IF
					
				420:
					this.vibPercentAmplitude := 20;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						IF (interface.status.minBreakPercent < interface.status.filteredAccelerometerPercent-4.0 AND NOT local.calibration.breakCaliDone) AND configTmp.brakeVelocity < 300000 THEN
							configTmp.brakeVelocity := configTmp.brakeVelocity*1.05;
						ELSE
							local.calibration.breakCaliDone := TRUE;
						END_IF
						
						IF local.calibration.boostCaliDone AND local.calibration.breakCaliDone OR local.calibration.countPulsesToFinetune > 14 THEN // max 15 times.
							em.substate := 970;
						ELSE
							local.calibration.countPulsesToFinetune := local.calibration.countPulsesToFinetune+1;
							em.substate := 400;
						END_IF
					END_IF
					
				(*	
				440:
					em.description := 'find brake start acceleration value';
					
					this.vibPercentAmplitude := 70.0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						this.calibration.accelerationStart := interface.status.currAccelerometerValue;
						this.vibPercentAmplitude := 20.0; //this.vibPercentAmplitude/2.0;
						caliMotionControl;
						
						em.substate := 450;
					END_IF
					
				450:
					em.description := 'find brake end acceleration value';
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						this.calibration.accelerationEnd := interface.status.currAccelerometerValue;
						
						em.substate := 460;
					END_IF
					
				460:
					em.description := 'find brake parameters';
					
					this.vibPercentAmplitude := 70.0;
					caliMotionControl;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#3s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						this.vibPercentAmplitude := 20.0; //this.vibPercentAmplitude/2;
						caliMotionControl;
						
						interface.status.calibrateBraketime := (this.calibration.accelerationStart-this.calibration.accelerationEnd)/configTmp.brakeVelocity;
						interface.status.calibrateBrakeAmplitudeEnd := this.vibAmplitude;
						interface.status.calibrateBrakeFrequencyEnd := this.vibFrequency;
						
						em.substate := 470;
					END_IF
					
				470:
					
					interface.status.calibrateBrake := TRUE;
					
					this.TON_delay.IN := TRUE;
					this.TON_delay.PT := T#2s;
					this.TON_delay();
					
					IF this.TON_delay.Q THEN
						this.TON_delay.IN := FALSE;
						this.TON_delay();
						
						interface.status.calibrateBrake := FALSE;
						
						IF interface.status.minAcceleration <= interface.status.currAccelerometerValue AND configTmp.brakeVelocity < 300000 THEN
							configTmp.brakeVelocity := configTmp.brakeVelocity + 5000;
							em.substate := 460;
						ELSE
							this.vibAmplitude := 0;
							em.substate := 970;
						END_IF
						
					END_IF
					*)
				950:
					// Setup freq LUT
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF configTmp.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.lookUpFrequency.NodeVectorX[j] := configTmp.linearizationAmplitude[j];
						this.lookUpFrequency.FcnValues[j] := configTmp.linearizationFrequencies[j];
					END_FOR
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.NumberOfNodes := this.pointsInLinearization;
					this.lookUpFrequency.Update := TRUE;
					this.lookUpFrequency();
					
					IF this.lookUpFrequency.UpdateDone THEN
						this.lookUpFrequency.Update := FALSE;
						this.lookUpFrequency();
						this.TON_delay(IN:=FALSE);
						j:=0;
						
						em.substate := 960;
					END_IF	
					
					
				960:
					// Setup ampl LUT
					em.description := 'Determine how many linearization points that has been used';
					
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_IDX_AUTO_LINEARIZATION DO
						IF configTmp.autoLinearizationCurrent[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					em.substate := 965;
					
				965:
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.linearizationTable.NodeVectorX[j] := configTmp.autoLinearizationAccAtCurrent[j];
						this.linearizationTable.FcnValues[j] := configTmp.autoLinearizationCurrent[j];
					END_FOR
					this.linearizationTable.Enable := TRUE;
					this.linearizationTable.NumberOfNodes   := this.pointsInLinearization;
					this.linearizationTable.Mode 			:= mtLOOKUP_LINEAR_EXTRAPOLATION;
					this.linearizationTable.Update			:= TRUE;
					this.linearizationTable();
					IF this.linearizationTable.UpdateDone THEN 
						this.linearizationTable.Update		:= FALSE;
						this.linearizationTable();
						
						em.substate := 970;
					END_IF
					
				970:
					// Wait a little bit before taking vibrator to 0%
					this.vibPercentAmplitude := 0;
					caliMotionControl;
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#3s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						this.verifyIdx := 0;
						this.simuTimeInCountSpeed := 800000; // 800ms
						this.simuTimeInWaitSpeed := 500000; // 500ms
						this.simuTimeInStopped := 600000; // 600ms  
						this.stateSimuPulse := 0;
						local.calibration.countTestPulse := 0;
						local.calibration.counter := 0;
						local.calibration.bufferIdx := 15; // starting from this idx for cosmetic reasons in line chart widget.
						interface.status.caliProdTest := TRUE;
						this.time.elapsed := 0;
						
						this.vibPercentAmplitude := 70;
						
						em.substate := 980;
					END_IF
					
					
				980:
					// 2 Pulses that will be saved in config. Pulse 1 will use countSpeed=70% and waitSpeed=30%. Pulse 2 will use countSpeed=30% and waitSpeed=10%
					
					CASE this.stateSimuPulse OF
					
						0:	// CountSpeed
							
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInCountSpeed THEN
								this.time.elapsed := 0;
								IF local.calibration.countTestPulse = 0 THEN
									// first pulse
									this.vibPercentAmplitude := 40;
								ELSIF local.calibration.countTestPulse = 1 THEN
									// second pulse
									this.vibPercentAmplitude := 10;
								END_IF
								this.stateSimuPulse := 10;
							END_IF
						
						10:
				
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInWaitSpeed THEN
								this.time.elapsed := 0;
								this.stateSimuPulse := 20;
							END_IF
						
						20:
							this.vibPercentAmplitude := 0;
							
							this.time.elapsed := this.time.elapsed + em.status.cycleTime;
							IF this.time.elapsed >= this.simuTimeInStopped THEN
								this.time.elapsed := 0;
								IF local.calibration.countTestPulse = 0 THEN
									// first pulse change counting speed for 2nd pulse
									this.vibPercentAmplitude := 30;
								ELSE
									// second pulse we are done!
									em.substate := 990;
								END_IF
								local.calibration.countTestPulse := local.calibration.countTestPulse + 1;
								this.stateSimuPulse := 0;
							END_IF
						
					END_CASE
					caliMotionControl;
					
				
					// Save data in config:
					local.calibration.counter := local.calibration.counter + 1;
					IF local.calibration.counter >= 2 THEN
						// Save value every 2nd scan which is 9.6ms ˜ 10ms
						local.calibration.counter := 0;
						IF local.calibration.bufferIdx <= MAX_BUFFER_CALI_IDX THEN
							configTmp.caliPulseBufferAcc[local.calibration.bufferIdx] := REAL_TO_USINT(interface.status.filteredAccelerometerPercent);
							configTmp.caliPulseEstimatedPct[local.calibration.bufferIdx] :=  REAL_TO_USINT(interface.status.currEstimatedPercent);
							local.calibration.bufferIdx := local.calibration.bufferIdx + 1;
						END_IF
					END_IF
					
				990:
					this.hmi.config := local.configTmp; // Success calibration. Put configTmp into config
					
					IF NOT this.hmi.calibration.runTestPulses THEN
						// Done!
						
						this.hmi.config.calibrationDateTime := this.DTGetTime_0.DT1;
						
						interface.status.caliProdTest := FALSE;
						gMachineInterface.cmd.requestSaveToT50 := TRUE;
						em.substate := 2221;
					ELSE
						// doing pulses. Wait a short time and do another
						this.calibration.TON_0.IN := TRUE;
						this.calibration.TON_0.PT := T#2s;
						this.calibration.TON_0();
					
						IF this.calibration.TON_0.Q THEN
							this.calibration.TON_0(IN:=FALSE);
							this.verifyIdx := 0;
							this.simuTimeInCountSpeed := 800000; // 800ms
							this.simuTimeInWaitSpeed := 500000; // 500ms
							this.simuTimeInStopped := 600000; // 600ms  
							this.stateSimuPulse := 0;
							local.calibration.countTestPulse := 0;
							local.calibration.counter := 0;
							local.calibration.bufferIdx := 15; // starting from this idx for cosmetic reasons in line chart widget.
							interface.status.caliProdTest := TRUE;
							this.time.elapsed := 0;
						
							this.vibPercentAmplitude := 70;
						
							em.substate := 980;
						END_IF
					END_IF
					
				(*
				975:
					em.description := 'Determine how many linearization points that has been used';
					
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_IDX_AUTO_LINEARIZATION DO
						IF configTmp.autoLinearizationCurrent[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					em.substate := 980;
					
				980:
					FOR j:=0 TO (this.pointsInLinearization-1) DO
						this.linearizationTable.NodeVectorX[j] := configTmp.autoLinearizationAccAtCurrent[j];
						this.linearizationTable.FcnValues[j] := configTmp.autoLinearizationCurrent[j];
					END_FOR
					this.linearizationTable.Enable := TRUE;
					this.linearizationTable.NumberOfNodes   := this.pointsInLinearization;
					this.linearizationTable.Mode 			:= mtLOOKUP_LINEAR_EXTRAPOLATION;
					this.linearizationTable.Update			:= TRUE;
					this.linearizationTable();
					IF this.linearizationTable.UpdateDone THEN 
						this.linearizationTable.Update		:= FALSE;
						em.substate := 1000;
					END_IF
				
					// ----------- confirm linearization -----------
				1000: 
					this.vibPercentAmplitude := 10+(this.verifyIdx*10);
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#5s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0.IN := FALSE;
						this.calibration.TON_0();
						this.verifyLinearization[this.verifyIdx] := interface.status.maxPeakValue;
						configTmp.verifyLinearization[this.verifyIdx] := interface.status.maxPeakValue;
						IF this.verifyIdx < 9 THEN
							this.verifyIdx := this.verifyIdx + 1;
						ELSE
							configTmp.fitPercentage :=  RSquared(this.verifyLinearization, local.configTmp.pointY1, local.configTmp.pointY2)*100.0;
							gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
							
							this.hmi.config := local.configTmp; // Success calibration. Put configTmp into config

							this.hmi.config.calibrationDateTime := this.DTGetTime_0.DT1;
							
							gMachineInterface.cmd.requestSaveToT50 := TRUE;
							em.substate := 2221;
						END_IF
					END_IF
					caliMotionControl;
*)
					
				2221:
					em.description := 'Wait 3s to make sure file is saved';
					
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#3s;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0.IN := FALSE;
						this.calibration.TON_0();
						
						em.substate := 2222;
					END_IF
					
				2222: 
					// not this vibr calibrating. Wait here until other vibrator is done.
				
					this.hmi.calibration.activate := FALSE;
					em.cmd.sc := TRUE;
				
				
			END_CASE
			// Scale maxPeakVal to be shown in percent.
			this.hmi.linearizationActValue := LIMIT(0,interface.status.filteredAccelerometerPercent,200);//maxPeakToPercent(interface.status.maxPeakValue,configTmp.pointY1,configTmp.pointY2);
			
			IF this.hmi.stopLinearization THEN
				this.hmi.stopLinearization := FALSE;
				this.hmi.calibration.activate := FALSE;
				em.cmd.sc := TRUE;
				em.substate := 2222;
			END_IF
			
			IF this.hmi.calibration.decreaseBoost THEN
				this.hmi.calibration.decreaseBoost := FALSE;
				configTmp.boostVelocityLow := configTmp.boostVelocityLow*1.020; //2%
				configTmp.boostVelocityHigh := configTmp.boostVelocityHigh*1.020;
			END_IF
			IF this.hmi.calibration.increaseBoost THEN
				this.hmi.calibration.increaseBoost := FALSE;
				configTmp.boostVelocityLow := configTmp.boostVelocityLow*0.980; //2%
				configTmp.boostVelocityHigh := configTmp.boostVelocityHigh*0.980;
			END_IF
			IF this.hmi.calibration.increaseBrake THEN
				this.hmi.calibration.increaseBrake := FALSE;
				configTmp.brakeVelocity := configTmp.brakeVelocity*1.020;
			END_IF
			IF this.hmi.calibration.decreaseBrake THEN
				this.hmi.calibration.decreaseBrake := FALSE;
				configTmp.brakeVelocity := configTmp.brakeVelocity*0.980;
			END_IF
			
		STATE_STOPPING, STATE_ABORTING, STATE_HOLDING:
			em.description := 'stopping vibrators';
			this.vibAmplitude := this.vibPercentAmplitude := 0;
			this.linearizationTable(Enable:=FALSE);
			this.lookUpFrequency(Enable:=FALSE);
			this.hmi.calibration.increaseBoost := FALSE;
			this.hmi.calibration.decreaseBoost := FALSE;
			this.hmi.calibration.increaseBrake := FALSE;
			this.hmi.calibration.decreaseBrake := FALSE;
			this.hmi.calibration.enableStopButton := FALSE;
			this.hmi.calibration.runTestPulses := FALSE;
			gVibratorInterface[i].cmd.monitorMaxPeakValue := FALSE;
			gVibratorInterface[i].status.maxPeakValue := 0;
			gVibratorInterface[i].cmd.monitorActPeakValue := FALSE;
			interface.status.caliProdTest := FALSE;
			gVibratorInterface[i].status.calibrateBrake := FALSE;
			this.hmi.calibration.enableBoostBrakeAdjustment := TRUE;
			this.vibPercentAmplitude := 0;
			caliMotionControl;
			em.cmd.sc := TRUE;
			
			this.hmi.force.enable := FALSE;
			
			this.hmi.calibratingProcessing := this.hmi.cancelTuning := this.hmi.showErrorMsgLinearization := this.hmi.enableOperatorInput := FALSE;
	
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
			
			em.description := 'power off - waiting for start';
			axis.command.power := FALSE;
			em.cmd.sc := TRUE;
		
	END_CASE
 
	interface.status.vibAmplitude := this.vibAmplitude;
	interface.status.vibFrequency := this.vibFrequency;
	interface.status.percent	  := this.vibPercentAmplitude;
	
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        