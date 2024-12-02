ACTION producing:
	
	CASE em.state OF

		STATE_STOPPED:
			
			interface.status.ready 	:= FALSE;
			interface.status.active := TRUE; // need to tell wing when we are active. (otherwise wing start too fast and this task is stuck in STATE_ACTIVATING doing boot)
			
			em.cmd.sc 				:= TRUE;	

			
		STATE_RESETTING:
			
			em.cmd.sc := TRUE;
			
		STATE_IDLE:
			interface.status.ready := TRUE;
			em.cmd.sc := TRUE;
		
			
		STATE_STARTING:
			
			interface.status.ready 									:= TRUE;
			interface.cmd.start										:= FALSE;
			interface.status.readyForStatusChange 					:= TRUE;	
			this.cycleTime 											:= 0;
			em.cmd.sc 												:= TRUE;

			
		STATE_EXECUTE:
			

			CASE em.substate OF
				0: // H010 (Initialisation) + H020 (FM Start)
					em.cmd.sc := TRUE;
					interface.status.ready	:= TRUE;
				
					em.description := 'waiting for start command';
					IF interface.cmd.start THEN
						this.calculateCycletime := TRUE;
						IF interface.parameter.brickStatus = BRICK_STATUS_OK THEN
							this.MTDataStatistics_Real.Enable				:= TRUE;
							this.MTDataStatistics_Real.MovingWindowLength 	:= 10;
							this.MTDataStatistics_Real.In 					:= this.cycleTimeReal / 1000; 
							this.MTDataStatistics_Real();
							this.cycleTimeReal := 0;
							IF this.MTDataStatistics_Real.Mean <> 0 THEN
								this.hmi.realMeanOutput := 60000 / this.MTDataStatistics_Real.Mean;
							END_IF
						END_IF
						
						// calculate cycletime here
						interface.cmd.start 						:= FALSE;
						interface.status.ready 						:= FALSE;
						this.time.elapsed							:= 0;
						this.time.maximum							:= interface.parameter.fallTime;
						gBottomFlapInterface.parameter.brickStatus 	:= interface.parameter.brickStatus;
						gBottomFlapInterface.cmd.brickStatusReady	:= TRUE;
						this.middleFlapTime 						:= 0;
						em.substate 								:= 40;
					ELSIF interface.cmd.manuelMode THEN
						em.substate := 1000;
					END_IF
	
				40: // H040 (FB Ready)
					em.description := 'waiting for bottom flap ready1 or ready2';
	
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF gBottomFlapInterface.status.ready1 THEN
						interface.status.readyForStatusChange 		:= FALSE;
						gBottomFlapInterface.cmd.brickStatusReady	:= FALSE;
						gBottomFlapInterface.cmd.start1	:= TRUE;
						//em.cmd.sc := FALSE;
					END_IF				
					
					// Wait FallTime before giving start2 (ok to give start1 before)
					IF gBottomFlapInterface.status.ready2 THEN
						em.cmd.sc := FALSE;	
						this.flap.open := TRUE;
						this.cycleTimeTheoretical := 0;
						this.middleFlapTime := this.middleFlapTime + em.status.cycleTime;
						em.substate 			:= 70;
					END_IF
				
				70: // H070 (Open FM)
					em.description 				:= 'waiting for flap to be open';
					
					this.middleFlapTime := this.middleFlapTime + em.status.cycleTime;
					
					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error state in execute
					ELSIF this.flap.position = FLAP_OPEN THEN
						this.time.elapsed				:= 0;
						this.time.maximum				:= interface.parameter.openTime;
						gBottomFlapInterface.cmd.start2 := TRUE;
						interface.status.lastCycleTime 	:= UDINT_TO_REAL(this.middleFlapTime);
						interface.status.openCloseTime := this.cycleTimeTheoretical;
						em.substate 					:= 75;
					END_IF

				75: // H075	
					em.description := 'waiting for opening time';
					
					this.middleFlapTime := this.middleFlapTime + em.status.cycleTime;
					this.time.elapsed	:= this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum THEN
						this.flap.close := TRUE;
						em.substate := 80;
					END_IF	

				80: // H080 (Close FM)
					em.description 				:= 'waiting for flap to be closed';
					
					this.middleFlapTime := this.middleFlapTime + em.status.cycleTime;
					
					IF this.flap.error THEN
						this.alarm.closeTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error state in execute
					ELSIF this.flap.position = FLAP_CLOSED THEN
						interface.status.ready	:= TRUE;
						// Save open/close time in service menu (better than writing it cyclically).
						this.flapTest.openTime := this.flap.openTimeAfterChangeover;
						this.flapTest.closingTime := this.flap.closingTimeAfterChangeover;
						this.flapTest.openTimeOK := this.flapTest.openTime >= 210 AND this.flapTest.openTime <= 230;
						this.flapTest.closingTimeOK := this.flapTest.closingTime >= 210 AND this.flapTest.closingTime <= 230;
						this.cycleTime 			:= 0;
						this.hmi.portionCycleTime := UDINT_TO_REAL(this.middleFlapTime+gUpperFlapInterface.status.lastCycleTime)/1000;
						em.substate 			:= 0;
					END_IF

					
					(**** ERROR handling in EXECUTE ****)
					
				700:
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
					
					IF NOT this.flap.error THEN
						this.flap.close := TRUE;
						em.substate := 710;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
					
				710:
					em.description := 'Wait for flap to close - if not still continue. We cant be stuck in "SUSPENDING"';
				
					IF this.flap.error THEN
						this.time.elapsed := 0;
						em.substate := 720;
					ELSIF this.flap.position = FLAP_CLOSED THEN
						this.time.elapsed := 0;
						em.substate := 720;
					END_IF
				
				720:
					em.description := 'Wait for alarm acknowledge';
					
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 500000 THEN //500ms
						this.time.elapsed := 0;
						IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortMain') THEN
							em.substate := 730; // "UNSUSPENDING"
						END_IF
					END_IF
					
				730:
					IF NOT this.flap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						this.alarm.closeTooLong.name := 'middleFlapCloseTooLong';
						this.alarm.openTooLong.name := 'middleFlapOpenTooLong';
						this.flap.close := TRUE;
						em.substate := 740;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
				
				740:
					em.description := 'Wait for flap to close -> if not go back and try again ';
				
					IF this.flap.error THEN
						em.substate := 730; // Try again (we MUST close flap before we return)
					ELSIF this.flap.position = FLAP_CLOSED THEN
						em.substate := 750;
					END_IF
					
				750:
					em.description := 'Recover to "previousState"';
					
					CASE this.previousState OF
						
						70: // Error opening
							em.cmd.sc := FALSE;	
							this.flap.open := TRUE;
							this.cycleTimeTheoretical := 0;
							em.substate 			:= 70;
							
							
						80: // Error closing
							this.flap.close := TRUE;
							em.substate := 80;
						
						1000:
							em.substate := 0;
						
					END_CASE	
					
					
					
					(**** Manuel mode ****)
					
				1000:
					testing;
					IF this.flap.error THEN
						// Stop testing and go in execute error state.
						this.previousState := em.substate;
						this.test.state := 0;
					
						em.substate := 700;
					END_IF
				
			END_CASE
			
			IF gMainInterface.status.state = STATE_EXECUTE THEN
				// calculate throughput cycletime
				this.cycleTime := this.cycleTime + UDINT_TO_REAL(em.status.cycleTime);
				this.cycleTimeReal := this.cycleTimeReal + UDINT_TO_REAL(em.status.cycleTime); 	
			ELSE
				this.MTDataStatistics_Real.Enable := FALSE;
				this.MTDataStatistics_Real();
				this.calculateCycletime := FALSE;
				this.cycleTime := 0;
				this.cycleTimeReal := 0;
				this.hmi.realMeanOutput := 0;
			END_IF
			
			this.cycleTimeTheoretical := this.cycleTimeTheoretical + em.status.cycleTime;
			
		STATE_COMPLETING:
		
			em.description := 'waiting for bottom flap ready2 to be ready';
			
			CASE em.substate OF
				
				0:
					// Determine if big or small brick from capcon teach integral
					IF gCapconInterface.status.teachIntegral > ELEMENT_SIZE_LIMIT AND gCapconInterface.status.teachingDone THEN
						this.ItemSize := Large;
					ELSE
						this.ItemSize := Small;
					END_IF
				
					em.substate := 10;
				
				10:
					IF gBottomFlapInterface.status.ready2 THEN
						gBeltInterface.cmd.stopDoingEmpty := FALSE;
						em.cmd.sc := TRUE;
					END_IF
			
				
			END_CASE
			
			em.setup.reactTo := BRDK_EM_REACT_TO_ALL;
			
	
					
		STATE_COMPLETE:
				
			
			CASE em.substate OF
				
				0:
					em.description 		:= 'empty or small items empty';
					
					IF this.ItemSize=Small THEN
						this.time.maximum := TIME_EMPTY_SMALL_ITEM;
						em.cmd.sc := FALSE;
						em.substate := 5;
					ELSE
						this.flap.open := TRUE;
						em.substate := 10;
						em.cmd.sc := TRUE;
					END_IF
					
				
				5:
					interface.status.ready := TRUE;
					em.description 		:= 'waiting for empty small items time or empty finished';
					this.time.elapsed	:= this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum OR gMainInterface.status.state <> STATE_COMPLETING THEN
						interface.status.busy 	:= TRUE;
						this.time.elapsed 	:= 0;
						this.flap.open := TRUE;
						em.cmd.sc := FALSE;
						gBeltInterface.cmd.stopDoingEmpty := TRUE;
						em.substate 			:= 10;
					END_IF
					
					IF this.time.elapsed >= (this.time.maximum-400000) THEN
						// Signal belt and vibrator to stop 0.4s before opening flap.
						gBeltInterface.cmd.stopDoingEmpty := TRUE;
					END_IF
					
					
				10: // H820 (FM open)
					em.description 			:= 'waiting for flap to be open';
					
					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error state in execute
					ELSIF this.flap.position = FLAP_OPEN THEN
						this.time.elapsed				:= 0;
						this.time.maximum				:= 1000000; // 1s. be open for a longer time because a lot of bricks is falling and we dont want to pierce them.
						em.cmd.sc := TRUE;
						
						IF this.ItemSize=Small THEN
							em.substate 					:= 20;
						ELSE
							em.substate 					:= 40;
						END_IF
							
					END_IF
						
				20: // 
					em.description 		:= 'waiting for opening time';
					this.time.elapsed	:= this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum THEN
						this.flap.close := TRUE;
						em.cmd.sc := FALSE;
						interface.status.busy 			:= FALSE;
						em.substate 					:= 30;
					END_IF	
				
				30: // H830 (FM close)
					em.description 		:= 'waiting for flap to be closed';
					
					IF this.flap.error THEN
						this.alarm.closeTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error state in execute
					ELSIF this.flap.position = FLAP_CLOSED THEN
						interface.status.ready	:= TRUE;
						gBeltInterface.cmd.stopDoingEmpty := FALSE;
						this.flapTest.openTime := this.flap.openTimeAfterChangeover;
						this.flapTest.closingTime := this.flap.closingTimeAfterChangeover;
						this.flapTest.openTimeOK := this.flapTest.openTime >= 210 AND this.flapTest.openTime <= 230;
						this.flapTest.closingTimeOK := this.flapTest.closingTime >= 210 AND this.flapTest.closingTime <= 230;
						em.substate 			:= 0;
					END_IF
						
				40:
					em.description 		:= 'Emptying machine';
					interface.status.ready := TRUE;	
					
						
						(**** ERROR handling in COMPLETE ****)
						
				700:
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
					
					IF NOT this.flap.error THEN
						this.flap.close := TRUE;
						em.substate := 710;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
					
				710:
					em.description := 'Wait for flap to close - if not still continue. We cant be stuck in "SUSPENDING"';
				
					IF this.flap.error THEN
						this.time.elapsed := 0;
						em.substate := 720;
					ELSIF this.flap.position = FLAP_CLOSED THEN
						this.time.elapsed := 0;
						em.substate := 720;
					END_IF
				
				720:
					em.description := 'Wait for alarm acknowledge';
					
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= 500000 THEN //500ms
						this.time.elapsed := 0;
						IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortMain') THEN
							em.substate := 730; // "UNSUSPENDING"
						END_IF
					END_IF
					
				730:
					IF NOT this.flap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						this.alarm.closeTooLong.name := 'middleFlapCloseTooLong';
						this.alarm.openTooLong.name := 'middleFlapOpenTooLong';
						this.flap.close := TRUE;
						em.substate := 740;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
				
				740:
					em.description := 'Wait for flap to close -> if not go back and try again ';
				
					IF this.flap.error THEN
						em.substate := 730; // Try again (we MUST close flap before we return)
					ELSIF this.flap.position = FLAP_CLOSED THEN
						em.substate := 750;
					END_IF
					
				750:
					em.description := 'Recover to "previousState"';
					
					CASE this.previousState OF
						
						10: // Error opening
							em.substate 			:= 0;
							
							
						30: // Error closing
							this.time.elapsed := 0;
							this.time.maximum := interface.parameter.openTime;
							em.substate := 20;
						
					END_CASE
				
		END_CASE
			
			gBottomFlapInterface.cmd.start1 := em.cmd.sc;
				
	STATE_ABORTED, STATE_SUSPENDED:
			em.description := 'waiting for wing to start';
			em.cmd.sc := TRUE;

	STATE_STOPPING, STATE_ABORTING, STATE_SUSPENDING:
		
			CASE em.substate OF
				
				0:
					em.description 				:= 'Clear status and close flap';
					interface.status.ready 					:= FALSE;
					interface.status.readyForStatusChange 	:= FALSE;
					interface.cmd.start 					:= FALSE;
					this.hw.do_open 		:= FALSE;
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
					gBeltInterface.cmd.stopDoingEmpty := FALSE;
				
					IF NOT this.flap.error THEN
						this.flap.close := TRUE;
						em.substate := 10;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
				
				10:
					em.description := 'Wait for flap to close';
				
					IF this.flap.error THEN
						em.substate := 20;
					ELSIF this.flap.position = FLAP_CLOSED THEN
						em.substate := 20;
					END_IF
				
				20:
					em.cmd.sc := TRUE;
				
			END_CASE
			
			
			
	STATE_CLEARING, STATE_UNSUSPENDING:
		em.description := 'waiting for flap error reset';
			
		
			CASE em.substate OF
				
				0:
					IF NOT this.flap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						this.alarm.closeTooLong.name := 'middleFlapCloseTooLong';
						this.alarm.openTooLong.name := 'middleFlapOpenTooLong';
						this.flap.close := TRUE;
						em.substate := 10;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
				
				10:
					em.description := 'Wait for flap to close';
				
					IF this.flap.error THEN
						em.substate := 0;
					ELSIF this.flap.position = FLAP_CLOSED THEN
						em.substate := 20;
					END_IF
					
				20:
					em.description 				:= 'Wait for close of own and neigbourflap';
					em.cmd.sc := TRUE;
				
			END_CASE
	
				
	ELSE
	em.cmd.sc := TRUE;

	END_CASE
	
END_ACTION