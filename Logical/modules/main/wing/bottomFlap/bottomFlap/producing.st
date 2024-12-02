ACTION producing:
	
	CASE em.state OF

		STATE_STOPPED:
			
			interface.status.ready1 	:= FALSE;
			interface.status.ready2 	:= FALSE;
			interface.status.active := TRUE; // need to tell wing when we are active. (otherwise wing start too fast and this task is stuck in STATE_ACTIVATING doing boot)
			
			em.cmd.sc 					:= TRUE;

		STATE_RESETTING:
			
			em.cmd.sc := TRUE;
			
			
		STATE_IDLE:
			
			interface.status.ready1 := TRUE;
			em.cmd.sc 					:= TRUE;


		STATE_STARTING:
			
			interface.status.ready1 := TRUE;
			interface.cmd.start1	:= FALSE;
			interface.status.ready2 := FALSE;
			interface.cmd.start2	:= FALSE;
			em.cmd.sc 				:= TRUE;	

		STATE_EXECUTE:
	
//			// Send to main -> ready to empty
//			IF gMainInterface.status.emptying THEN
//				// Only allow to empty if no brick in bottomFlap.
//				interface.status.emptyReady := em.substate < 110  OR em.substate >= 500 AND em.substate < 700;
//				em.cmd.sc := interface.status.emptyReady;
//			END_IF
			
			CASE em.substate OF

				0:	// I010 (Initialisation) + I020 (Bottom flap)
					em.description := 'waiting for start1 command';
					em.cmd.sc := TRUE;
					
					interface.status.ready1 := TRUE;
					
					interface.status.emptyReady := gMainInterface.status.emptying;
					
					IF interface.cmd.start1 AND NOT gMainInterface.status.emptying  THEN // added NOT emptying because otherwise wing could signal ".empty ready" and by the time main is going into completing em.substate is >=150 which till set em.cmd.sc=false. This will make bottom unable to follow main and freeze the machine
					
						em.cmd.sc 	:= FALSE;
						interface.cmd.start1	:= FALSE;
						interface.status.ready1 := FALSE;
						this.bottomFlapTime := 0;
						interface.status.emptyReady := FALSE;
						CASE interface.parameter.brickStatus OF

							BRICK_STATUS_OK: 
								
								this.localShaftMode := interface.parameter.shaftMode;
								em.substate := 100;
		
							BRICK_STATUS_NOK:
							
								this.flap.open := TRUE;
								em.substate 			:= 400;				// Go to I400 (NOK)
							
	
						END_CASE
						
					END_IF

				100:
					em.description := 'waiting for neighbour to have a portion ready';
					
					
					
					IF gMainInterface.status.emptying THEN
						this.WingSync_0.Cancel := TRUE;
						this.WingSync_0.Request := FALSE;
					ELSIF this.localShaftMode = SHAFT_MODE_NORMAL AND NOT this.WingSync_0.Request THEN
						this.WingSync_0.Request := gCassetteInterface.status.syncAck = gCassetteInterface.cmd.start;
					ELSIF this.localShaftMode = SHAFT_MODE_EMPTY AND NOT this.WingSync_0.Request THEN
						this.WingSync_0.Request := gCassetteInterface.status.ready AND (gCassetteInterface.status.startAck = gCassetteInterface.cmd.start);
					END_IF
					
					IF this.WingSync_0.Approved THEN
						this.WingSync_0.Request := FALSE;
						this.WingSync_0.Cancel := FALSE;
						interface.status.ready2 := TRUE;
						this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
						interface.status.approvedPortion := TRUE;
				//		this.runningAlone := this.hw.di_neigbourIsDosing OR NOT (this.hw.di_neighbourActive);
						em.substate := 110;
					ELSIF this.WingSync_0.CancelApproved THEN
						this.WingSync_0.Request := FALSE;
						this.WingSync_0.Cancel := FALSE;
						em.substate := 0;
					END_IF
					
				110:
					em.description := 'waiting for start2 command';
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
					IF interface.cmd.start2 THEN
						interface.cmd.start2 := FALSE;
						interface.status.ready2 := FALSE;
						
						this.time.maximum := interface.parameter.fallTime;
						this.time.elapsed := 0;
						
						em.substate := 112;
					END_IF
					
				112:
					em.description := 'waiting for fall time';
					
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
					
					this.time.elapsed	:= this.time.elapsed + em.status.cycleTime;
					IF this.time.elapsed >= this.time.maximum THEN
						em.substate := 120;
					END_IF

				120:
					em.description := 'waiting for cassette to be ready';
					
					IF gCassetteInterface.status.ready AND (gCassetteInterface.status.startAck = gCassetteInterface.cmd.start) THEN
						this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
						this.flap.open := TRUE;
						this.neighbourFlap.open := TRUE;
						this.time.elapsed := 0;
						this.time.maximum := interface.parameter.cassetteStartDelay;
						this.cycleTimeTheoretical := 0;
						em.substate 		:= 310;
					ELSE
						this.timeWaitForCasstte := (this.timeWaitForCasstte + em.status.cycleTime)/1000;
					END_IF

				310: // I310 (Flap actions)
					em.description := 'waiting for own and neighbour flap to open and cassette delay to run out';
					
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime; // Neighbour flap is set open instantly when dual mahcines are connected
					IF this.flap.error OR this.neighbourFlap.error THEN
						this.alarm.openTooLong.active := this.flap.error;
						this.alarm.openNeighbourTooLong.active := this.neighbourFlap.error;
						this.previousState := em.substate;
						em.substate := 700; // Error in EXECUTE
					ELSIF this.flap.position = FLAP_OPEN AND this.neighbourFlap.position = FLAP_OPEN THEN
						em.substate := 315;
					END_IF
					
				315:
					em.description := 'Wait cassetteStartDelay';
					
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum THEN
						gCassetteInterface.cmd.start 	:= gCassetteInterface.cmd.start + 1;
						interface.status.approvedPortion := FALSE;
						this.OeeCalc_0.GoodPortion := this.OeeCalc_0.GoodPortion + 1;
						this.time.maximum				:= interface.parameter.openTime;
						em.substate 					:= 320;
					END_IF

				320:  // I320 (Cassette start)
					em.description := 'waiting for opening time';

					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime;
					
					// if time elapsed close flap
					IF this.time.elapsed >= this.time.maximum THEN
						this.flap.close := TRUE;
						this.neighbourFlap.close := TRUE;
						em.substate := 330;
					END_IF

				330: // I330 (Flap actions)
					em.description := 'waiting for own and neighbour flaps to be closed';
					
					this.bottomFlapTime := this.bottomFlapTime + em.status.cycleTime; // Neighbour flap is set close instantly when dual mahcines are connected
				
					IF this.flap.error OR this.neighbourFlap.error THEN
						this.alarm.closeTooLong.active := this.flap.error;
						this.alarm.closeNeighbourTooLong.active := this.neighbourFlap.error;
						this.previousState := em.substate;
						em.substate := 700; // Error in EXECUTE
					ELSIF (this.flap.position = FLAP_CLOSED) AND (this.neighbourFlap.position = FLAP_CLOSED) THEN
						interface.status.ready1 := TRUE;
						interface.status.openCloseTime := this.cycleTimeTheoretical;
						// Save open/close time in service menu (better than writing it cyclically).
						this.flapTest.openTime := (this.flap.openTimeAfterChangeover);
						this.flapTest.closingTime := (this.flap.closingTimeAfterChangeover);
						this.flapTest.openTimeOK := this.flapTest.openTime >= 150 AND this.flapTest.openTime <= 170;
						this.flapTest.closingTimeOK := this.flapTest.closingTime >= 220 AND this.flapTest.closingTime <= 250;
						
						this.flapTest.neighbourClosingTime := (this.neighbourFlap.closingTimeAfterChangeover);
						this.flapTest.neighbourOpenTime := (this.neighbourFlap.openTimeAfterChangeover);
						this.flapTest.neighbourOpenTimeOK := this.flapTest.neighbourOpenTime >= 150 AND this.flapTest.neighbourOpenTime <= 170;
						this.flapTest.neighbourClosingTimeOK := this.flapTest.neighbourClosingTime >= 220 AND this.flapTest.neighbourClosingTime <= 250;
						
						this.hmi.portionCycleTime := UDINT_TO_REAL(this.bottomFlapTime) / 1000;
						
						em.substate := 0;
					END_IF

					(*** REJECT / NOK ***)	
					
				400: // I400 (NOK)
					em.description := 'waiting for flap to be open and start 2 command';
					
					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error in EXECUTE
					ELSIF this.flap.position = FLAP_OPEN THEN
						interface.status.ready2 := TRUE;
						em.substate 			:= 410;
					END_IF
					
				410: // I400 (NOK)
					em.description := 'waiting for start2 command';

					IF interface.cmd.start2 THEN
						interface.cmd.start2 	:= FALSE;
						interface.status.ready2 := FALSE;
						this.OeeCalc_0.BadPortion := this.OeeCalc_0.BadPortion + 1;
						this.time.elapsed := 0;
						this.time.maximum := interface.parameter.fallTime;
						em.substate				:= 415;
					END_IF
					
				415: // Wait fall time - 150ms
					em.description := 'wait fall time';
					
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum THEN
						this.flap.close := TRUE;
						em.substate := 420;
					END_IF
					
				420: // I420 
					em.description := 'waiting for flap to be closed';

					IF this.flap.error THEN
						this.alarm.closeTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error in EXECUTE
					ELSIF this.flap.position = FLAP_CLOSED THEN
						interface.status.ready1	:= TRUE;
						
						// Save open/close time in service menu (better than writing it cyclically).
						this.flapTest.openTime := (this.flap.openTimeAfterChangeover);
						this.flapTest.closingTime := (this.flap.closingTimeAfterChangeover);
						this.flapTest.openTimeOK := this.flapTest.openTime >= 150 AND this.flapTest.openTime <= 170;
						this.flapTest.closingTimeOK := this.flapTest.closingTime >= 220 AND this.flapTest.closingTime <= 250;
						em.substate 			:= 0;
					END_IF
				
					(**** ERROR handling in EXECUTE ****)
					
				700:
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
					
					IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
						this.flap.close := TRUE;
						this.neighbourFlap.close := TRUE;
						em.substate := 710;
					ELSE
						this.flap.resetError := this.flap.error;
						this.neighbourFlap.resetError := this.neighbourFlap.error;
					END_IF
					
				710:
					em.description := 'Wait for flap to close - if not still continue. We cant be stuck in "SUSPENDING"';
				
					IF this.flap.error OR this.neighbourFlap.error THEN
						this.time.elapsed := 0;
						em.substate := 720;
					ELSIF this.flap.position = FLAP_CLOSED AND this.neighbourFlap.position = FLAP_CLOSED THEN
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
					IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						this.alarm.openTooLong.name := 'bottomFlapOpenTooLong';
						this.alarm.closeTooLong.name := 'bottomFlapCloseTooLong';
						this.alarm.openNeighbourTooLong.name := 'neighbourBottomFlapOpenTooLong';
						this.alarm.closeNeighbourTooLong.name := 'neighbourBottomFlapCloseTooLong';
						this.alarm.neighbourNotActive.name := 'neighbourNotActive';
						this.flap.close := TRUE;
						this.neighbourFlap.close := TRUE;
						em.substate := 740;
					ELSE
						this.flap.resetError := this.flap.error;
						this.neighbourFlap.resetError := this.neighbourFlap.error;
					END_IF
				
				740:
					em.description := 'Wait for flap to close -> if not go back and try again ';
				
					IF this.flap.error OR this.neighbourFlap.error THEN
						em.substate := 730; // Try again (we MUST close flap before we return)
					ELSIF this.flap.position = FLAP_CLOSED AND this.neighbourFlap.position = FLAP_CLOSED THEN
						em.substate := 750;
					END_IF
					
				750:
					em.description := 'Recover to "previousState"';
					
					CASE this.previousState OF
						
						0:
							em.substate := 0;
						
						310: // error opening flap
							this.flap.open := TRUE;
							this.neighbourFlap.open := TRUE;
							this.time.elapsed := 0;
							this.time.maximum := interface.parameter.cassetteStartDelay;
							this.cycleTimeTheoretical := 0;
							em.substate 		:= 310;
						
						330: // error closing flap
							this.flap.close := TRUE;
							this.neighbourFlap.close := TRUE;
							em.substate := 330;
						
						400: // error opening flap doing reject
							this.flap.open := TRUE;
							em.substate := 400;				// Go to I400 (NOK)
						
						420: // error closing flap doing reject
							this.flap.close := TRUE;
							em.substate := 420;
						
						
					END_CASE	
						

			END_CASE
			
			
			
			(**** Manuel mode ****)
			
			// Had to move manuel mode to its own state diagram.
			CASE this.manuelState OF
				
				0:
					IF interface.cmd.manuelMode THEN
						this.test.state := 0;
						this.manuelState := 10;
					END_IF
					
					
				10:
					testing;
					IF this.flap.error THEN
						// Stop testing and go in execute error state.
						this.previousState := em.substate;
						this.test.state := 0;
						this.manuelState := 222;
						em.substate := 700;
					END_IF
					
					
				222:
					IF em.substate < 700 THEN
						// error has been acknowledged
						this.manuelState := 0;
					END_IF
					
			END_CASE
			
			this.cycleTimeTheoretical := this.cycleTimeTheoretical + em.status.cycleTime;

		STATE_STOPPING:
			CASE em.substate OF
				0:
					em.description 				:= 'Clear status and close flaps';

					this.flap.close := TRUE;
					this.neighbourFlap.close := TRUE;
					
					em.substate := 10;
						
				10: 
					em.description 				:= 'waiting for own and neighbour flaps to be closed';
						
					IF this.flap.error OR this.neighbourFlap.error THEN
						interface.status.ready1 			:= FALSE;
						interface.cmd.start1				:= FALSE;
						interface.status.ready2 			:= FALSE;
						interface.cmd.start2				:= FALSE;
						interface.cmd.brickStatusReady		:= FALSE;
						this.WingSync_0.Request 			:= FALSE;
						em.substate := 100;
					ELSIF this.flap.position = FLAP_CLOSED AND this.neighbourFlap.position = FLAP_CLOSED THEN
						interface.status.ready1 			:= FALSE;
						interface.cmd.start1				:= FALSE;
						interface.status.ready2 			:= FALSE;
						interface.cmd.start2				:= FALSE;
						interface.cmd.brickStatusReady		:= FALSE;
						this.WingSync_0.Request 			:= FALSE;
						
						em.cmd.sc := TRUE;	
					END_IF
				
					(* Error in STOPPING (just reset error - this will auto close) *)
				
				100:
					IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
						em.cmd.sc := TRUE;
					ELSE
						this.flap.resetError := this.flap.error;
						this.neighbourFlap.resetError := this.neighbourFlap.error;
					END_IF
				
			END_CASE
			
			
		STATE_ABORTED, STATE_SUSPENDED:
			em.description := 'waiting for wing to start';
			em.cmd.sc := TRUE;
			
		STATE_ABORTING, STATE_SUSPENDING:
			
			
			CASE em.substate OF
				
				0:
					em.description 				:= 'Clear status and close flap';
					interface.status.ready1 			:= FALSE;
					interface.cmd.start1				:= FALSE;
					interface.status.ready2 			:= FALSE;
					interface.cmd.start2				:= FALSE;
					this.hw.do_neighbourPortionReady 	:= FALSE;
					interface.cmd.brickStatusReady		:= FALSE;
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
				
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
					em.description := 'sc=true';
					em.cmd.sc := TRUE;
				
				
			END_CASE
			
			
			
		STATE_COMPLETING:
			
			this.WingSync_0.Request := FALSE;
			
			CASE em.substate OF
				0:
					em.description 				:= 'Open flap';
					this.timeWaitForCasstte := 0;
					this.flap.open := TRUE;
			
					em.substate := 10;
				10:	
					em.description 				:= 'waiting for own flaps to be open';
					
					IF this.flap.error OR this.neighbourFlap.error THEN
						this.alarm.openTooLong.active := this.flap.error;
						this.previousState := em.substate;
						em.substate := 700;
					ELSIF this.flap.position = FLAP_OPEN THEN
						interface.status.ready2 := TRUE;
						em.cmd.sc := TRUE;
					END_IF
				
					(**** ERROR handling in COMPLETE ****)
					
				700:
					interface.cmd.runFlapContinuously	:= FALSE;
					interface.cmd.open					:= FALSE;
					interface.cmd.manuelMode			:= FALSE;
					
					IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
						this.flap.close := TRUE;
						this.neighbourFlap.close := TRUE;
						em.substate := 710;
					ELSE
						this.flap.resetError := this.flap.error;
						this.neighbourFlap.resetError := this.neighbourFlap.error;
					END_IF
					
				710:
					em.description := 'Wait for flap to close - if not still continue. We cant be stuck in "SUSPENDING"';
				
					IF this.flap.error OR this.neighbourFlap.error THEN
						this.time.elapsed := 0;
						em.substate := 720;
					ELSIF this.flap.position = FLAP_CLOSED AND this.neighbourFlap.position = FLAP_CLOSED THEN
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
					IF NOT this.flap.error AND NOT this.neighbourFlap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						this.alarm.openTooLong.name := 'bottomFlapOpenTooLong';
						this.alarm.closeTooLong.name := 'bottomFlapCloseTooLong';
						this.alarm.openNeighbourTooLong.name := 'neighbourBottomFlapOpenTooLong';
						this.alarm.closeNeighbourTooLong.name := 'neighbourBottomFlapCloseTooLong';
						this.alarm.neighbourNotActive.name := 'neighbourNotActive';
						this.flap.close := TRUE;
						this.neighbourFlap.close := TRUE;
						em.substate := 740;
					ELSE
						this.flap.resetError := this.flap.error;
						this.neighbourFlap.resetError := this.neighbourFlap.error;
					END_IF
				
				740:
					em.description := 'Wait for flap to close -> if not go back and try again ';
				
					IF this.flap.error OR this.neighbourFlap.error THEN
						em.substate := 730; // Try again (we MUST close flap before we return)
					ELSIF this.flap.position = FLAP_CLOSED AND this.neighbourFlap.position = FLAP_CLOSED THEN
						em.substate := 750;
					END_IF
					
				750:
					em.description := 'Recover to "previousState"';
					
					CASE this.previousState OF
						
						10: // Error opening
							this.flap.open := TRUE;
							em.substate := 0;

					END_CASE
					
			END_CASE;
				
		STATE_COMPLETE:
			em.description 				:= 'Emptying machine';
			em.setup.reactTo := BRDK_EM_REACT_TO_ALL;
			em.cmd.start := TRUE;
			
		
			IF interface.cmd.start1 THEN
				this.time.elapsed :=  this.time.elapsed + em.status.cycleTime;
			ELSE
				this.time.maximum := 1000000; // 1 sec
				this.time.elapsed := 0;
			END_IF
			
			em.cmd.sc :=  this.time.elapsed > this.time.maximum AND this.flap.position = FLAP_OPEN; // Flap must be open since we go to STATE_STOPPING and closes both flaps.
		
		STATE_CLEARING, STATE_UNSUSPENDING:
			
			
			CASE em.substate OF
				0:	
					em.description 				:= 'Clear own status';
					interface.status.ready1 			:= FALSE;
					interface.cmd.start1				:= FALSE;
					interface.status.ready2 			:= FALSE;
					interface.cmd.start2				:= FALSE;
					this.hw.do_neighbourPortionReady 	:= FALSE;
					em.substate := 5;
				
				5:
					em.description 				:= 'Clear own flap error';
					IF NOT this.flap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						// Alarm texts
						this.alarm.openTooLong.name := 'bottomFlapOpenTooLong';
						this.alarm.closeTooLong.name := 'bottomFlapCloseTooLong';
						this.alarm.openNeighbourTooLong.name := 'neighbourBottomFlapOpenTooLong';
						this.alarm.closeNeighbourTooLong.name := 'neighbourBottomFlapCloseTooLong';
						this.alarm.neighbourNotActive.name := 'neighbourNotActive';
						this.flap.close := TRUE;
						em.substate := 10;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
	
				10:
					em.description := 'Wait for flap to close';
				
					IF this.flap.error THEN
						em.substate := 5;
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