
ACTION producing: 

	CASE em.state OF
		
		STATE_ACTIVATING:
		
			// setup vibrator for closed loop current control
			CASE em.substate OF 
				
				0:
					em.description := 'Wait for config';
					
					IF gConfig.status.loaded THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						
						IF NOT gMainInterface.status.simulation THEN
							em.substate := 50;
						ELSE
							em.substate := 70;
						END_IF
					END_IF
				
				50:
					em.description := 'Set current controller mode';
					
					this.MC_BR_WriteParID_0.Execute 		:= TRUE;
					this.MC_BR_WriteParID_0.Axis 			:= SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
					this.MC_BR_WriteParID_0.ParID 			:= 328;
					this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_USINT;
					this.MC_BR_WriteParID_0.DataAddress 	:= ADR(CONTROLLER_MODE_CURR_CTRL);
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
					this.MC_BR_WriteParID_0.DataAddress 	:= ADR(PARID_IPL1_OUT);
					this.MC_BR_WriteParID_0();
					
					IF this.MC_BR_WriteParID_0.Done THEN
						this.MC_BR_WriteParID_0(Execute := FALSE);
						em.substate := 70;
					END_IF
					
				70:
					em.cmd.sc := TRUE;

			END_CASE
			
		
		STATE_RESETTING:
			
			CASE em.substate OF
				
				0:
					interface.status.percent := 0;
					axis.command.power := TRUE;
				
					IF gMainInterface.status.simulation THEN
						axis.command.power := FALSE;
						em.substate := 10;
					ELSIF axis.status.powerOn THEN
						em.substate := 10;
					END_IF 
				
				10:
					em.cmd.sc := TRUE;
					
				
			END_CASE
		
		STATE_IDLE:
			em.cmd.sc := TRUE;
			
		STATE_STARTING:
			em.cmd.sc := TRUE; // will move to Execute right away
			
		STATE_EXECUTE:
			
	
			// Test software
			IF NOT this.testPulses THEN
				
				CASE gBeltInterface.status.speed OF
					
					lego_speed_stop:
						em.description := 'Stopped, not using wait speed';
						interface.status.percent := 0;
						interface.cmd.speed := lego_speed_stop;
				
					lego_speed_wait:
						em.description := 'running at waiti ng speed';
						
						// If waitspeed is greater than countspeed just use countspeed instead of waitspeed.
						CASE i OF
							
							0:
								IF interface.status.waitSpeed < gBeltInterface.status.CFCountSpeed THEN
									interface.status.percent := interface.status.waitSpeed; 
								ELSE
									interface.status.percent := gBeltInterface.status.CFCountSpeed;
								END_IF
							
							1:
								IF interface.status.waitSpeed < gBeltInterface.status.LFCountSpeed THEN
									interface.status.percent := interface.status.waitSpeed; 
								ELSE
									interface.status.percent := gBeltInterface.status.LFCountSpeed;
								END_IF
							
							
						END_CASE
						
					
						interface.cmd.speed := lego_speed_wait;
				
					lego_speed_counting:
						em.description := 'running at counting speed';
						//interface.status.percent := interface.status.countingSpeed; // Comes from recipe in vibrator task
						interface.status.percent := SEL(i=0,gBeltInterface.status.LFCountSpeed,gBeltInterface.status.CFCountSpeed);
						interface.cmd.speed := lego_speed_counting;
				
				END_CASE
				
		
				
			ELSE	
				this.TON_PulseTest.IN := TRUE;
				this.TON_PulseTest();
				
				IF this.TON_PulseTest.Q THEN
					this.TON_PulseTest.IN := FALSE;
					this.TON_PulseTest();
					IF this.RandomPulses THEN
						this.TON_PulseTest.PT := UDINT_TO_TIME(rand_interval(150, 1500));	
					END_IF
		
					IF this.PulseWaitAmplitude > 0.0 THEN
						IF interface.status.percent = this.PulseAmplitude THEN
							interface.status.percent := this.PulseWaitAmplitude;
						ELSIF interface.status.percent = this.PulseWaitAmplitude THEN
							interface.status.percent := 0;
						ELSE
							interface.status.percent := this.PulseAmplitude;
						END_IF
					ELSE
						IF interface.status.percent = this.PulseAmplitude THEN
							interface.status.percent := 0;
						ELSE
							interface.status.percent := this.PulseAmplitude;
						END_IF
					END_IF
				END_IF
			
			END_IF
			
			em.cmd.sc := TRUE;
			
		STATE_COMPLETING:
			
			CASE em.substate OF
				
				0:
					interface.status.percent := 0;
					IF gBeltInterface.status.speed <> lego_speed_stop THEN
						this.time.elapsed := 0;
						interface.status.percent := interface.cmd.emptyPercent*0.5;
						em.substate := 3;
					END_IF
				
					IF interface.cmd.calibrate THEN
						em.substate := 10;
					END_IF
				
				3:
					// use half amplitude for 700ms to protect vibrator mechanics.
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 700000 THEN
						em.substate := 5;
					END_IF
					
				5:
					em.description := 'Emptying';
					
					interface.status.percent := interface.cmd.emptyPercent;
					interface.cmd.speed := lego_speed_counting;
					
					IF gBeltInterface.status.speed = lego_speed_stop THEN
						interface.cmd.speed := lego_speed_stop;
						em.substate := 0;
					END_IF
			
					IF interface.cmd.calibrate 	THEN
						this.time.elapsed := 0;
						interface.status.percent := interface.cmd.emptyPercent*0.5;
						em.substate := 8;
					END_IF
					
				8:
					// use half amplitude for 700ms to protect vibrator mechanics.
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 700000 THEN
						em.substate := 10;
					END_IF
					
				10:
					em.cmd.sc := TRUE;
					
				
			END_CASE
			
		STATE_STOPPING, STATE_HOLDING, STATE_SUSPENDING:
	
			em.description := 'stopping vibrators';
			interface.status.percent := 0;
			interface.status.forcing := FALSE;
			interface.cmd.speed := lego_speed_stop;
		
			em.cmd.sc := TRUE;
			this.hmi.force.enable := FALSE;
	
			em.cmd.sc := TRUE;
			
		STATE_ABORTING:
			em.description := 'stopping vibrators';
			axis.command.power := FALSE;
			interface.status.percent := 0;
			interface.status.forcing := FALSE;
			interface.cmd.speed := lego_speed_stop;
		
			em.cmd.sc := TRUE;
			this.hmi.force.enable := FALSE;
	
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

			// Manual run cmd from FAT test
			IF NOT interface.cmd.runManualTest AND this.oldRunManualTest THEN
				this.hmi.force.enable := FALSE;
			ELSIF interface.cmd.runManualTest THEN
				this.hmi.force.enable := TRUE;
			END_IF
			this.oldRunManualTest := interface.cmd.runManualTest;
			
			CASE em.substate OF
				
				0:
					IF this.hmi.force.enable THEN
						em.cmd.sc := FALSE;
						em.substate := 10;
					ELSE
						axis.command.power := FALSE;
						gVibratorInterface[i].status.forcing := FALSE;
						em.cmd.sc := TRUE;	
					END_IF
				
				10:
					axis.command.power := TRUE;
				
					IF axis.status.powerOn THEN
						gVibratorInterface[i].status.forcing := TRUE;
						em.substate := 20;
					END_IF
				
				20:
					IF NOT this.hmi.force.enable THEN
						axis.command.power := FALSE;
						em.substate := 0;
					END_IF
				
			END_CASE
		
	END_CASE
	
END_ACTION
