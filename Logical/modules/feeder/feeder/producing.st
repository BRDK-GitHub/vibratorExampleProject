ACTION producing:
	
	CASE em.state OF
		
		STATE_STOPPED:
		
			em.description := 'Waiting for start command';
			em.cmd.reset 	:= interface.cmd.start OR this.hmi.cmd.empty;
			IF gConfig.status.loadInitialValue[0] AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
				gConfig.status.loadInitialValue[0] := FALSE;
				recipe.offTime := 1000;
				recipe.onTime := 1000;
				recipe.startDelay := 30;
				recipe.stopDelay := 30;
			END_IF
			IF this.hmi.cmd.forceForwards AND this.hmi.cmd.forceBackwards THEN
				this.hmi.cmd.forceForwards := FALSE;
				this.hmi.cmd.forceBackwards := FALSE;
			END_IF
			this.belt.cmd.forwards := this.hmi.cmd.forceForwards;
			this.belt.cmd.backwards := this.hmi.cmd.forceBackwards;
				
			
			em.cmd.sc 		:= TRUE;
			
		STATE_IDLE:
		
			em.cmd.start := em.cmd.sc := TRUE;
			
		STATE_STARTING:
			
			em.description := 'wait for feeder flap to close';
			IF this.flap.state = FEEDER_FLAP_CLOSED THEN
				this.flap.cmd.close := FALSE;
				this.stopCounter := 0;
				this.startCounter := 0;
				this.onCounter := 0;
				this.offCounter := 0;
				em.cmd.sc := TRUE;
			ELSE
				this.flap.cmd.close := TRUE;
			END_IF
					
		STATE_EXECUTE:
		
			this.hmi.status.running := interface.status.running := this.hmi.cmd.enable;		// running if enabled from HMI
			
			IF this.flap.state <> FEEDER_FLAP_CLOSED OR gFeederInterface.cmd.stop OR this.hmi.cmd.stop THEN
				this.hmi.cmd.stop := FALSE;
				em.cmd.stop := TRUE;
			END_IF
			
			CASE em.substate OF
				0:
					em.description := 'wait for CF running and low level';
				
					IF cmIsRunning(interface.cmd.speed) AND NOT this.hw.di_levelSensorInBowl THEN
						em.substate := 10;
					END_IF
				
				10:
					em.description := 'wait start delay';
				
					this.startCounter := this.startCounter + 1;
					
					IF this.hw.di_levelSensorInBowl THEN
						this.startCounter := 0;
						em.substate := 0;
					ELSIF NOT cmIsRunning(interface.cmd.speed) THEN
						em.substate := 0;
					ELSIF UDINT_TO_REAL(this.startCounter*this.RTInfo_0.cycle_time)/1000.0 > recipe.startDelay THEN
						this.belt.cmd.forwards := TRUE;
						this.startCounter := 0;
						em.substate := 20;
					END_IF
				
				20: 
					em.description := 'belt running for on time';
				
					this.onCounter := this.onCounter + 1;
				
					IF this.hw.di_levelSensorInBowl THEN
						this.belt.cmd.forwards := FALSE;
						em.substate := 40;
					ELSIF NOT cmIsRunning(interface.cmd.speed) THEN
						this.onCounter := 0;
						this.belt.cmd.forwards := FALSE;
						em.substate := 0;
					ELSIF UDINT_TO_REAL(this.onCounter*this.RTInfo_0.cycle_time)/1000.0 > recipe.onTime THEN
						this.onCounter := 0;
						this.belt.cmd.forwards := FALSE;
						em.substate := 30;
					END_IF
				
				30:
					em.description := 'belt stopped for off time';
				
					this.offCounter := this.offCounter + 1;
				
					IF NOT cmIsRunning(interface.cmd.speed) THEN
						this.offCounter := 0;
						em.substate := 0;
					ELSIF UDINT_TO_REAL(this.offCounter*this.RTInfo_0.cycle_time)/1000.0 > recipe.offTime THEN
						this.offCounter := 0;
						
						this.belt.cmd.forwards := TRUE;
						em.substate := 20;
					END_IF
						
				40:
					em.description := 'wait for stop delay';
				
					this.stopCounter := this.stopCounter + 1;
				
					IF UDINT_TO_REAL(this.stopCounter*this.RTInfo_0.cycle_time)/1000.0 > recipe.stopDelay OR NOT cmIsRunning(interface.cmd.speed) THEN
						this.stopCounter := 0;
						em.substate := 0;
					ELSIF NOT this.hw.di_levelSensorInBowl THEN
						this.stopCounter := 0;
						this.belt.cmd.forwards := TRUE;
						em.substate := 20;
					END_IF
				
			END_CASE
			
			em.cmd.complete := this.hmi.cmd.empty;
			em.cmd.sc := TRUE;
			
		STATE_SUSPENDED:
		
			em.cmd.sc := TRUE;
			
		STATE_COMPLETING:
			
			this.hmi.cmd.empty := FALSE;
		
			CASE em.substate OF

				0:
					em.description := 'waiting for an empty box at the flap';
					
					this.belt.cmd.backwards := this.belt.cmd.forwards := this.flap.cmd.open := this.flap.cmd.close := FALSE;
					
					IF this.hw.di_boxIsReadyAtFlap THEN
						this.alarm.boxMissing.active := FALSE;
						em.substate := 10;
					ELSE
						IF NOT this.hmi.cmd.confirmEmpty THEN
							this.alarm.boxMissing.active := TRUE;
						ELSE	// If user confirm -> exit COMPLETING and be ready for production.
							this.alarm.boxMissing.active := FALSE;
							em.cmd.sc := TRUE;
						END_IF
					END_IF
				
				10:
					em.description := 'flap opening';
					
					this.flap.cmd.open := TRUE;
					
					IF this.flap.state = FEEDER_FLAP_OPENED THEN
						this.flap.cmd.open := FALSE;
						this.TON_startDelay(IN :=FALSE);
						this.TON_startDelay.PT := T#2s;
						em.substate := 20;
					END_IF
				
				20:
					em.description := 'run belt backwards until box is removed';
					
					// Run the belt backwards 10s then stop 2s etc. etc. This is done not to burn card.
					this.TON_startDelay.IN := TRUE;
					this.TON_startDelay();
					IF this.TON_startDelay.Q THEN
						this.TON_startDelay(IN:=FALSE);
						IF this.belt.cmd.backwards THEN
							// if it has just been running wait 2s
							this.TON_startDelay.PT := T#2s;
						ELSE
							// If it has not been running - run it for 10s
							this.TON_startDelay.PT := T#10s;
						END_IF
						this.belt.cmd.backwards := NOT this.belt.cmd.backwards;
					END_IF
					
					IF NOT this.hw.di_boxIsReadyAtFlap THEN
						this.belt.cmd.backwards := FALSE;
						this.TON_startDelay(IN :=FALSE);
						em.substate := 25;
					END_IF
					
				25:
					em.description := 'Wait 3s before moving from backward to forward to avoid huge current peak';
					this.TON_startDelay.IN := TRUE;
					this.TON_startDelay.PT := T#3s;
					this.TON_startDelay();
					
					IF this.TON_startDelay.Q THEN
						this.TON_startDelay(IN:=FALSE);
						em.substate := 30;
					END_IF
					
				30:
					em.description := 'flap closing and run belt forward';
					
					this.belt.cmd.forwards := this.flap.cmd.close := TRUE;
					
					IF this.flap.state = FEEDER_FLAP_CLOSED THEN
						this.flap.cmd.close := this.belt.cmd.forwards :=  FALSE;
						em.cmd.sc := TRUE;
					END_IF

			END_CASE			
			
		STATE_COMPLETE:
			
			this.belt.cmd.backwards := this.belt.cmd.forwards := this.flap.cmd.open := this.flap.cmd.close := this.hmi.cmd.confirmEmpty := FALSE;
			em.cmd.stop := em.cmd.sc := TRUE;
			
		STATE_STOPPING, STATE_HOLDING, STATE_ABORTING, STATE_RESETTING, STATE_SUSPENDING:
			
			em.description := 'close flap with max speed and check belt type';
			
			this.belt.cmd.backwards := this.belt.cmd.forwards := this.flap.cmd.open := this.flap.cmd.close := this.hmi.cmd.confirmEmpty := this.hmi.cmd.forceForwards := this.hmi.cmd.forceBackwards := FALSE;
			
			interface.status.count := 0;
			this.hmi.status.running	:= interface.status.running := FALSE;
			this.TON_timeout(IN := FALSE);
			this.TON_startDelay(IN := FALSE);
			this.flap.cmd.open := FALSE;
			em.cmd.sc := TRUE;
		
		STATE_ABORTED:
		
			IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortFeeder') THEN
				em.cmd.clear := em.cmd.sc := TRUE;
			END_IF
		
		STATE_CLEARING:
			

			CASE em.substate OF
				
				0: 
					brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
					// Set alarm texts
					this.alarm.lowLevel.name := 'feederLowLevel';
					this.alarm.boxMissing.name := 'feederBoxMissing';
					this.alarm.cannotCloseFlap.name := 'feederCannotCloseFlap';
					this.alarm.cannotOpenFlap.name := 'feederCannotOpenFlap';
					this.alarm.beltFeederEmpty.name := 'beltFeederEmpty';
					em.substate := 10;
				
				10:
					this.TON_timeout(IN := TRUE);
					IF this.flap.state = FEEDER_FLAP_CLOSED OR  this.TON_timeout.Q THEN
						this.TON_timeout(IN := FALSE);
						this.flap.cmd.close := FALSE;
			
						em.cmd.sc := TRUE;
					ELSE
						this.flap.cmd.close := TRUE;
					END_IF
					
				
			END_CASE


		ELSE
				
			em.cmd.sc := TRUE;
			
	END_CASE
 
	END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        