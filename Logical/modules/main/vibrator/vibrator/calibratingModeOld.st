
ACTION calibratingModeOld:
	
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
						axis.internal.MC_Power_0.Enable := TRUE;
						
					
					
						IF axis.status.powerOn THEN
							this.vibAmplitude := 0;
							this.MC_BR_WriteParID_0(Execute := FALSE);
							this.hmi.linearizationGoalValue := config.pointX1;
							em.cmd.sc := TRUE;
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
					IF this.hmi.calibration.activate THEN
						// reset linearization
						brsmemset(ADR(this.hmi.config.linearizationPercent),0,SIZEOF(this.hmi.config.linearizationPercent));
						brsmemset(ADR(this.hmi.config.linearizationCurrent),0,SIZEOF(this.hmi.config.linearizationCurrent));
						brsmemset(ADR(this.hmi.config.linearizationFrequencies),0,SIZEOF(this.hmi.config.linearizationFrequencies));
						brsmemset(ADR(this.hmi.config.linearizationAmplitude),0,SIZEOF(this.hmi.config.linearizationAmplitude));
						CASE i OF
							
							0:
								IF localVariables[0].hmi.config.type = 0 THEN // Small machine 
									this.vibFrequency := 46.5;
									em.substate := 100;
								ELSE // big machine
									this.vibFrequency := 23.0;
									em.substate := 300;
								END_IF	
							
							1:
								IF localVariables[0].hmi.config.type = 0 THEN // Small machine 
									this.vibFrequency := 47;
									em.substate := 200;
								ELSE // big machine
									this.vibFrequency := 47;
									em.substate := 400;
								END_IF	
							
						END_CASE
						this.calibration.TON_0(IN:=FALSE); // reset
						this.calibration.analogVib := 0;
						this.hmi.showErrorMsgLinearization := TRUE;
						// Set hardcoded values for linearization points:
						IF localVariables[0].hmi.config.type=0 THEN 	// small cf
							localVariables[0].hmi.config.pointX1 := 10;
							localVariables[0].hmi.config.pointY1 := 29;
							localVariables[0].hmi.config.pointX2 := 100;
							localVariables[0].hmi.config.pointY2 := 168;
							// LF
							localVariables[1].hmi.config.pointX1 := 10;
							localVariables[1].hmi.config.pointY1 := 13.2;
							localVariables[1].hmi.config.pointX2 := 100;
							localVariables[1].hmi.config.pointY2 := 104;
						ELSE 					// large CF
							localVariables[0].hmi.config.pointX1 := 10;
							localVariables[0].hmi.config.pointY1 := 31.8;
							localVariables[0].hmi.config.pointX2 := 100;
							localVariables[0].hmi.config.pointY2 := 174.8;
							// LF
							localVariables[1].hmi.config.pointX1 := 10;
							localVariables[1].hmi.config.pointY1 := 15.8;
							localVariables[1].hmi.config.pointX2 := 100;
							localVariables[1].hmi.config.pointY2 := 93;
						END_IF
					ELSE
						em.cmd.sc := TRUE;
						em.substate := 2222;
					END_IF
	
				// -------------------- CF small --------------------
				100:
					// Search for approximate ressonance in steps of 0.5hz while warming up springs with a proper amplitude.
					// 46.5Hz -> 50.5 Hz
					this.vibAmplitude := 0.8;
					
					this.calibration.TON_0.PT := T#4s; // mby reduce to 3
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						IF localVariables[0].hw.actVib > this.calibration.analogVib THEN
							this.calibration.maxFreq := this.vibFrequency;
							this.calibration.analogVib := localVariables[0].hw.actVib;
						END_IF
						this.vibFrequency := this.vibFrequency + 0.5;
					END_IF
					
					IF this.vibFrequency >= 51 THEN
						// Found approximate ressonance. Now ready to sweep slowly.
						this.vibAmplitude := 0;
						this.MTBasicsLimiter_0(Enable:=FALSE);
						em.substate := 110;
					END_IF
					
				110:
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreq-0.75;
					this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreq+0.75;
					this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 120;
					END_IF
					this.MTBasicsLimiter_0();
					
				120:
					// Sweep1
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl1CF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[0] := this.calibration.sweepAmpl1CF;
						config.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 121;
					END_IF
					
				121:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 130;
					END_IF
					
				130:
					// Sweep2
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl2CF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[0]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[1] := this.calibration.sweepAmpl2CF;
						config.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 131;
					END_IF
					
				131:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 140;
					END_IF
					
				140:
					// Sweep3
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl3CF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[1]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[2] := this.calibration.sweepAmpl3CF;
						config.linearizationFrequencies[2] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 141;
					END_IF
					
				141:
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF config.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
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
						// Guess 10pct
						this.vibAmplitude := 0.38;
						em.substate := 950;
					END_IF			
				
					
					// -------------------- LF small --------------------
				200:
					// Search for approximate ressonance in steps of 0.5hz while warming up springs with a proper amplitude.
					// 49Hz -> 53 Hz
					this.vibAmplitude := 0.08;
					
					this.calibration.TON_0.PT := T#4s; // mby reduce to 3
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						IF localVariables[0].hw.actVib > this.calibration.analogVib THEN
							this.calibration.maxFreq := this.vibFrequency;
							this.calibration.analogVib := localVariables[0].hw.actVib;
						END_IF
						this.vibFrequency := this.vibFrequency + 0.5;
					END_IF
					
					IF this.vibFrequency >= 53 THEN
						// Found approximate ressonance. Now ready to sweep slowly.
						this.vibAmplitude := 0;
						this.MTBasicsLimiter_0(Enable:=FALSE);
						em.substate := 210;
					END_IF
					
				210:
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreq-1.0;
					this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreq+1.0;
					this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 220;
					END_IF
					this.MTBasicsLimiter_0();
					
				220:
					// Sweep1
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl1LF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[0] := this.calibration.sweepAmpl1LF;
						config.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 221;
					END_IF
					
				221:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 230;
					END_IF
					
				230:
					// Sweep2
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl2LF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[0]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[1] := this.calibration.sweepAmpl2LF;
						config.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 231;
					END_IF
					
				231:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 240;
					END_IF
					
				240:
					// Sweep3
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl3LF;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[1]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[2] := this.calibration.sweepAmpl3LF;
						config.linearizationFrequencies[2] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 241;
					END_IF
					
				241:
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF config.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
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
						// Guess 10pct
						this.vibAmplitude := 0.03;
						em.substate := 950;
					END_IF			
					
					// -------------------- CF big --------------------
				300:
					// Search for approximate ressonance in steps of 0.5hz while warming up springs with a proper amplitude.
					// 46.5Hz -> 50.5 Hz
					this.vibAmplitude := 1.7;
					
					this.calibration.TON_0.PT := T#4s; // mby reduce to 3
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						IF localVariables[0].hw.actVib > this.calibration.analogVib THEN
							this.calibration.maxFreq := this.vibFrequency;
							this.calibration.analogVib := localVariables[0].hw.actVib;
						END_IF
						this.vibFrequency := this.vibFrequency + 0.25;
					END_IF
					
					IF this.vibFrequency >= 25.25 THEN
						// Found approximate ressonance. Now ready to sweep slowly.
						this.vibAmplitude := 0;
						this.MTBasicsLimiter_0(Enable:=FALSE);
						em.substate := 310;
					END_IF
					
				310:
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreq-0.75;
					this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreq+0.75;
					this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 320;
					END_IF
					this.MTBasicsLimiter_0();
					
				320:
					// Sweep1
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl1CFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[0] := this.calibration.sweepAmpl1CFbig;
						config.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 321;
					END_IF
					
				321:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 330;
					END_IF
					
				330:
					// Sweep2
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl2CFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[0]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[1] := this.calibration.sweepAmpl2CFbig;
						config.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 331;
					END_IF
					
				331:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 340;
					END_IF
					
				340:
					// Sweep3
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl3CFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[1]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[2] := this.calibration.sweepAmpl3CFbig;
						config.linearizationFrequencies[2] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 341;
					END_IF
					
				341:
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF config.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
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
						// Guess 10pct
						this.vibAmplitude := 0.9;
						em.substate := 950;
					END_IF
					
					// -------------------- LF big --------------------
				400:
					// Search for approximate ressonance in steps of 0.5hz while warming up springs with a proper amplitude.
					// 49Hz -> 53 Hz
					this.vibAmplitude := 0.11;
					
					this.calibration.TON_0.PT := T#4s; // mby reduce to 3
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						IF localVariables[0].hw.actVib > this.calibration.analogVib THEN
							this.calibration.maxFreq := this.vibFrequency;
							this.calibration.analogVib := localVariables[0].hw.actVib;
						END_IF
						this.vibFrequency := this.vibFrequency + 0.5;
					END_IF
					
					IF this.vibFrequency >= 53 THEN
						// Found approximate ressonance. Now ready to sweep slowly.
						this.vibAmplitude := 0;
						this.MTBasicsLimiter_0(Enable:=FALSE);
						em.substate := 410;
					END_IF
					
				410:
					// setup limiter
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.MTBasicsLimiter_0.MinOut := this.calibration.maxFreq-1.0;
					this.MTBasicsLimiter_0.MaxOut := this.calibration.maxFreq+1.0;
					this.MTBasicsLimiter_0.MaxPosSlewRate := 0.02;
					this.MTBasicsLimiter_0.MaxNegSlewRate := 200000; // instant to go down.
					this.MTBasicsLimiter_0.Update := TRUE;
					
				
					IF this.MTBasicsLimiter_0.UpdateDone THEN
						this.MTBasicsLimiter_0.Update := FALSE;
						this.sweep.maxVibration := -1;
						this.sweep.maxVibrationISO := -1;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 420;
					END_IF
					this.MTBasicsLimiter_0();
					
				420:
					// Sweep1
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl1LFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
				
					IF this.vibFrequency >= this.MTBasicsLimiter_0.MaxOut THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[0] := this.calibration.sweepAmpl1LFbig;
						config.linearizationFrequencies[0] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 421;
					END_IF
					
				421:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 430;
					END_IF
					
				430:
					// Sweep2
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl2LFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[0]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[1] := this.calibration.sweepAmpl2LFbig;
						config.linearizationFrequencies[1] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 431;
					END_IF
					
				431:
					// wait delay and put freq to start freq again.
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut; 
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#800ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						gVibratorInterface[i].cmd.monitorHighestAmplitude := TRUE;
						gVibratorInterface[i].status.highestAmplitudeAnalog := 0;
						gVibratorInterface[i].status.highestAmplitudeISO := 0;
						gVibratorInterface[i].status.highestFrequencyAnalog := 0;
						gVibratorInterface[i].status.highestFrequencyISO := 0;
						em.substate := 440;
					END_IF
					
				440:
					// Sweep3
					
					this.MTBasicsLimiter_0.Enable := TRUE;
					this.vibAmplitude := this.calibration.sweepAmpl3LFbig;
					this.MTBasicsLimiter_0.In := this.MTBasicsLimiter_0.MaxOut;
					this.MTBasicsLimiter_0();
					this.vibFrequency := this.MTBasicsLimiter_0.Out+this.MTBasicsLimiter_0.MinOut; // add with .MinOut because it is incrementing from 0.
						
					IF this.vibFrequency >= (config.linearizationFrequencies[1]+0.1) THEN
						// done
						this.MTBasicsLimiter_0(Enable:=FALSE);
						config.linearizationAmplitude[2] := this.calibration.sweepAmpl3LFbig;
						config.linearizationFrequencies[2] := gVibratorInterface[i].status.highestFrequencyAnalog;
						gVibratorInterface[i].cmd.monitorHighestAmplitude := FALSE;
						this.vibAmplitude := 0;
						em.substate := 441;
					END_IF
					
				441:
					// Update frequency LUT and go to 150
					this.pointsInLinearization := 0;
					FOR j:=0 TO MAX_LOOKUP_POINTS DO
						IF config.linearizationAmplitude[j]=0.0 THEN
							EXIT;
						ELSE
							this.pointsInLinearization := this.pointsInLinearization + 1;
						END_IF
					END_FOR
					
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
						// Guess 10pct
						this.vibAmplitude := 0.05;
						em.substate := 950;
					END_IF			
					
				// --------------------- COMMON LINEARIZATION OF 10% and 100% ---------------------
					// find 10% and 100%. Common states for all vibrators.
					
				950:
					//10% calibration
					this.hmi.showErrorMsgLinearization := FALSE;
					this.hmi.enableOperatorInput := TRUE;
					this.hmi.linearizationGoalValue := config.pointX1;
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.InX := this.vibAmplitude;
					this.lookUpFrequency();
					this.vibFrequency := this.lookUpFrequency.Out;
					
					// HMI input to increase/decrease vibAmplitude
					IF this.hmi.increaseVibAmplitude THEN
						this.hmi.increaseVibAmplitude := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude + 0.001;
						ELSE
							this.vibAmplitude := this.vibAmplitude + 0.0001;
						END_IF
					ELSIF this.hmi.decreaseVibAmplitude THEN
						this.hmi.decreaseVibAmplitude := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude - 0.001;
						ELSE
							this.vibAmplitude := this.vibAmplitude - 0.0001;
						END_IF
					END_IF
					IF this.hmi.increaseVibAmplitudeFast THEN
						this.hmi.increaseVibAmplitudeFast := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude + 0.01;
						ELSE
							this.vibAmplitude := this.vibAmplitude + 0.001;
						END_IF
					ELSIF this.hmi.decreaseVibAmplitudeFast THEN
						this.hmi.decreaseVibAmplitudeFast := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude - 0.01;
						ELSE
							this.vibAmplitude := this.vibAmplitude - 0.001;
						END_IF
					END_IF
					
					IF this.hmi.confirmPct THEN
						this.hmi.confirmPct := FALSE;
						config.linearizationPercent[0] := 10;
						config.linearizationCurrent[0] := this.vibAmplitude;
						// Guess 100pct
						CASE i OF	
							
							0:
								IF config.type=0 THEN
									this.vibAmplitude := 1.1;
								ELSE // BIG CF:
									this.vibAmplitude := 2.0;
								END_IF
							
							1:
								IF config.type=0 THEN
									this.vibAmplitude := 0.09;
								ELSE // BIG LF:
									this.vibAmplitude := 0.1;
								END_IF
						
						END_CASE
						this.hmi.linearizationGoalValue := config.pointX2;
						em.substate := 960;
					END_IF
					
				960:
					//100% calibration
					
					this.lookUpFrequency.Enable := TRUE;
					this.lookUpFrequency.InX := this.vibAmplitude;
					this.lookUpFrequency();
					this.vibFrequency := this.lookUpFrequency.Out;
		
					// HMI input to increase/decrease vibAmplitude
					IF this.hmi.increaseVibAmplitude THEN
						this.hmi.increaseVibAmplitude := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude + 0.001;
						ELSE
							this.vibAmplitude := this.vibAmplitude + 0.0001;
						END_IF
					ELSIF this.hmi.decreaseVibAmplitude THEN
						this.hmi.decreaseVibAmplitude := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude - 0.001;
						ELSE
							this.vibAmplitude := this.vibAmplitude - 0.0001;
						END_IF
					END_IF
					IF this.hmi.increaseVibAmplitudeFast THEN
						this.hmi.increaseVibAmplitudeFast := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude + 0.01;
						ELSE
							this.vibAmplitude := this.vibAmplitude + 0.001;
						END_IF
					ELSIF this.hmi.decreaseVibAmplitudeFast THEN
						this.hmi.decreaseVibAmplitudeFast := FALSE;
						IF i=0 THEN
							this.vibAmplitude := this.vibAmplitude - 0.01;
						ELSE
							this.vibAmplitude := this.vibAmplitude - 0.001;
						END_IF
					END_IF
					
					IF this.hmi.confirmPct THEN
						this.hmi.confirmPct := FALSE;
						config.linearizationPercent[1] := 100;
						config.linearizationCurrent[1] := this.vibAmplitude;
						this.vibAmplitude := this.vibAmplitude*0.5; // take half of amplitude.
						this.hmi.linearizationGoalValue := config.pointX1;
						this.hmi.enableOperatorInput := FALSE;
						em.substate := 970;
					END_IF
					
				970:
					// Wait a little bit before taking vibrator to 0%
					this.calibration.TON_0.IN := TRUE;
					this.calibration.TON_0.PT := T#1500ms;
					this.calibration.TON_0();
					
					IF this.calibration.TON_0.Q THEN
						this.calibration.TON_0(IN:=FALSE);
						this.hmi.calibration.activate := FALSE;
						em.cmd.sc := TRUE;
						em.substate := 2222;
					END_IF
				
				
				
					
					
				2222: 
					// not this vibr calibrating. Wait here until other vibrator is done.
				
				
				
				
			END_CASE
			
			IF this.hmi.stopLinearization THEN
				this.hmi.stopLinearization := FALSE;
				this.hmi.calibration.activate := FALSE;
				em.cmd.sc := TRUE;
				em.substate := 2222;
			END_IF
			
		STATE_STOPPING, STATE_ABORTING, STATE_HOLDING:
			em.description := 'stopping vibrators';
			this.vibAmplitude := this.vibPercentAmplitude := 0;
			this.linearizationTable(Enable:=FALSE);
			this.lookUpFrequency(Enable:=FALSE);
			em.cmd.sc := TRUE;
			
			this.sweep.MC_BR_ReadParID_214.Execute := FALSE;
			this.hmi.force.enable := FALSE;
			
			this.hmi.ackTuning := this.hmi.calibratingProcessing := this.hmi.cancelTuning := FALSE;
	
			em.cmd.sc := TRUE;
			
		STATE_ABORTED:
			
			IF (i=0 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortCircularFeeder')) OR (i=1 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortLinearFeeder')) THEN
				em.cmd.sc := TRUE;
			END_IF
			
			
		STATE_CLEARING:
			
			em.description := 'clearing';
			
			brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
			// Alarm texts
			this.alarm.axisFault.name := SEL(i=0, 'linearFeederAxisFault', 'circularFeederAxisFault');
			em.cmd.sc := TRUE;
			
		ELSE
			
			em.description := 'power off - waiting for start';
			axis.command.power := FALSE;
			em.cmd.sc := TRUE;
		
	END_CASE
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        