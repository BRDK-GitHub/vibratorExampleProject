ACTION producing:
	
	CASE em.state OF

		STATE_STOPPED:
			
			interface.status.active := TRUE; // need to tell wing when we are active. (otherwise wing start too fast and this task is stuck in STATE_ACTIVATING doing boot)
			
			interface.status.ready 	:= FALSE;
			interface.status.request := FALSE; 
		
			em.cmd.sc 				:= TRUE;	

		STATE_RESETTING:
			
			em.cmd.sc := TRUE;

		STATE_STARTING:
			
			interface.status.request := TRUE; // request new brick
			interface.status.ready 	:= TRUE;
			interface.cmd.start		:= FALSE;
			em.cmd.sc 				:= TRUE;

		STATE_EXECUTE:

			
			CASE em.substate OF

				0:	// G010 (Initialisation)
					em.cmd.sc := TRUE;
					interface.status.ready	:= TRUE; // only ready if not about to reject due to aftercount.;
				
					em.description := 'waiting for start command';
					
//					IF this.afterCount THEN
//						
//						IF (interface.status.request AND interface.cmd.start) OR NOT interface.status.request THEN
//							interface.cmd.start 		:= FALSE;
//							//this.afterCount := FALSE;
//							interface.status.request	 := FALSE; 
//							interface.status.ready 		:= FALSE;
//							em.substate := 20;
//						END_IF
//						
					IF interface.cmd.start THEN
						interface.cmd.start 		:= FALSE;
						this.waitingTime.current	:= 0;
						interface.status.request	 := FALSE; 
						interface.status.ready 		:= FALSE;
						
						this.lastUpperFlapCycleTime := this.upperFlapCycleTime;
						
						em.substate := 20;
					ELSIF interface.cmd.manuelMode THEN
						em.substate := 1000;
					END_IF
					

				20: // G020 (Shaft Start)
					em.description := 'waiting for middle flap to be ready';
					this.waitingTime.current := this.waitingTime.current + em.status.cycleTime;
					
					IF gCapconInterface.status.brickPresent AND interface.cmd.brickStatusReady AND gCapconInterface.parameter.capconMode <> 2 THEN // don't look on aftercount from capcon if capconMode=OFF
						this.rejectNext := TRUE;
					END_IF

					IF gMiddleFlapInterface.status.ready THEN
						this.flap.open := TRUE;
						this.cycleTimeTheoretical := 0;
						this.upperFlapCycleTime := 0;
						em.substate := 50;
						em.cmd.sc := FALSE;
					END_IF

				50: // G050 (Open FU)
					em.description 				:= 'waiting for flap to be open';
					
					IF gCapconInterface.status.brickPresent AND interface.cmd.brickStatusReady AND gCapconInterface.parameter.capconMode <> 2 THEN // don't look on aftercount from capcon if capconMode=OFF
						this.rejectNext := TRUE;
					END_IF
					
					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error in execute
					ELSIF this.flap.position = FLAP_OPEN THEN
						this.time.elapsed		:= 0;
						this.time.maximum		:= interface.parameter.openTime;
						em.substate 			:= 55;
					END_IF
					
				55: 
					em.description 		:= 'waiting for open time';	
					
					IF gCapconInterface.status.brickPresent AND interface.cmd.brickStatusReady AND gCapconInterface.parameter.capconMode <> 2 THEN // don't look on aftercount from capcon if capconMode=OFF
						this.rejectNext := TRUE;
					END_IF
					
					this.time.elapsed	:= this.time.elapsed + em.status.cycleTime;
					
					IF this.time.elapsed >= this.time.maximum AND (NOT interface.status.ready OR interface.cmd.brickStatusReady) THEN
						this.flap.close := TRUE;
						interface.status.request := TRUE;	 // if no wait time set true now. Otherwise wait time from config.
						gMiddleFlapInterface.parameter.brickStatus := SEL(this.rejectNext OR this.afterCount , interface.parameter.brickStatus, BRICK_STATUS_NOK);
						this.afterCount := this.rejectNext := FALSE;
						
						interface.cmd.brickStatusReady := FALSE;
						interface.status.openCloseTime := this.cycleTimeTheoretical;
						this.time.elapsed := 0;
						em.substate	:= 60;
					END_IF

				60: // G060 (Close FU)
					em.description := 'waiting for after count time';		
					
					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					
					IF (gCapconInterface.status.brickPresent OR testAfterCount) AND NOT this.afterCount AND gCapconInterface.parameter.capconMode <> 2 THEN // don't look on aftercount from capcon if capconMode=OFF
						testAfterCount := FALSE;
						this.afterCount := TRUE;
					ELSIF (this.time.elapsed/1000) >= (this.flap.closingTimeAfterChangeover-90) OR this.flap.position = FLAP_CLOSED THEN
						IF this.afterCount AND gCapconInterface.parameter.capconMode <> 2 THEN // don't look on aftercount from capcon if capconMode=OFF
							interface.parameter.brickStatus := BRICK_STATUS_NOK;
							gMiddleFlapInterface.parameter.brickStatus := BRICK_STATUS_NOK;
							//gBeltInterface.cmd.afterCount := TRUE;
						END_IF
						interface.status.lastCycleTime := this.upperFlapCycleTime;

						
						
						// Don't calculate reject% if about to do extra motion after afterCount or doing a teach.
						IF NOT this.afterCount AND gCapconInterface.status.teachingDone THEN
							this.errBuffer_0.input := gMiddleFlapInterface.parameter.brickStatus = BRICK_STATUS_OK;
							this.errBuffer_0.pushToBuffer := this.oldTeachingDone;
							this.errBuffer_0();
							this.hmi.errorRate := this.errBuffer_0.errorRate*100;
							interface.status.OKPortions := SEL(gMiddleFlapInterface.parameter.brickStatus = BRICK_STATUS_OK, interface.status.OKPortions, interface.status.OKPortions + 1);
							interface.status.NOKPortions := SEL(gMiddleFlapInterface.parameter.brickStatus = BRICK_STATUS_NOK, interface.status.NOKPortions, interface.status.NOKPortions + 1);
						END_IF
						this.oldTeachingDone := gCapconInterface.status.teachingDone;
						
						interface.status.countAftercount := SEL(this.afterCount,interface.status.countAftercount,interface.status.countAftercount + 1);
						
						// If reject all is enabled it should always be a reject
						interface.parameter.brickStatus := SEL(this.hmi.rejectAll,interface.parameter.brickStatus,BRICK_STATUS_NOK);
						gMiddleFlapInterface.parameter.brickStatus := SEL(this.hmi.rejectAll,gMiddleFlapInterface.parameter.brickStatus,BRICK_STATUS_NOK);
						gMiddleFlapInterface.cmd.start := TRUE;
						
						em.substate := 65;
					END_IF
					
					
				65: // G060 (Close FU)
					em.description 		:= 'waiting for flap to be closed';		

					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700; // Error in execute
					ELSIF this.flap.position = FLAP_CLOSED THEN

								
						IF interface.parameter.brickStatus = BRICK_STATUS_OK THEN
							this.MTFilterMovingAverage_0.Enable := TRUE;
							this.MTFilterMovingAverage_0.In := 60000000.0 / UDINT_TO_REAL(LIMIT(1, this.lastUpperFlapCycleTime, 4000000));
							this.MTFilterMovingAverage_0.WindowLength := 40;
							this.MTFilterMovingAverage_0();
							
							this.MTFilterMovingAverage_10.Enable := TRUE;
							this.MTFilterMovingAverage_10.In := 60000000.0 / UDINT_TO_REAL(LIMIT(1, this.lastUpperFlapCycleTime, 4000000));
							this.MTFilterMovingAverage_10.WindowLength := 10;
							this.MTFilterMovingAverage_10();
							
							this.MTFilterMovingAverage_10_TMU.Enable := TRUE;
							this.MTFilterMovingAverage_10_TMU.In := UDINT_TO_REAL(LIMIT(1, this.lastUpperFlapCycleTime, 4000000))/36000;
							this.MTFilterMovingAverage_10_TMU.WindowLength := 10;
							this.MTFilterMovingAverage_10_TMU();
						ELSE
							this.upperFlapCycleTime := this.upperFlapCycleTime + this.lastUpperFlapCycleTime;
						END_IF

						this.flapTest.openTime := this.flap.openTimeAfterChangeover;
						this.flapTest.closingTime := this.flap.closingTimeAfterChangeover;
						this.flapTest.openTimeOK := this.flapTest.openTime >= 210 AND this.flapTest.openTime <= 230;
						this.flapTest.closingTimeOK := this.flapTest.closingTime >= 210 AND this.flapTest.closingTime <= 230;
						em.substate := 0;
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
						this.alarm.closeTooLong.name := 'upperFlapCloseTooLong';
						this.alarm.openTooLong.name := 'upperFlapOpenTooLong';
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
						
						50: // Error opening
							this.flap.open := TRUE;
							this.cycleTimeTheoretical := 0;
							em.substate := 50;
							
						65: // Error closing
							this.flap.close := TRUE;
							em.substate := 65;
						
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
			
			this.cycleTimeTheoretical := this.cycleTimeTheoretical + em.status.cycleTime;
			IF gMainInterface.status.state = STATE_EXECUTE THEN
				this.upperFlapCycleTime := this.upperFlapCycleTime + em.status.cycleTime;
			END_IF

		STATE_COMPLETING:
			
			CASE em.substate OF
				
				0:
					em.description 				:= 'waiting for flap to be open';
					this.flap.open := TRUE;
					IF this.flap.error THEN
						this.alarm.openTooLong.active := TRUE;
						this.previousState := em.substate;
						em.substate := 700;
					ELSIF this.flap.position = FLAP_OPEN THEN
						this.time.elapsed := 0;
						em.substate := 10;
					END_IF
				10:
					em.description 				:= 'waiting for middle flap to be ready';
					em.cmd.sc := gMiddleFlapInterface.status.ready;
				
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
						this.alarm.closeTooLong.name := 'upperFlapCloseTooLong';
						this.alarm.openTooLong.name := 'upperFlapOpenTooLong';
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
						
						0: // Error opening
							this.flap.open := TRUE;
							em.substate := 0;

					END_CASE	
				
			END_CASE
		
		STATE_COMPLETE:
			
			em.description 				:= 'Emptying machine';
			em.setup.reactTo := BRDK_EM_REACT_TO_ALL;
			interface.status.ready := TRUE;
			interface.status.request := TRUE;
			em.cmd.sc := TRUE;
			
		STATE_ABORTED, STATE_SUSPENDED:
			em.description := 'waiting for wing to start';
			em.cmd.sc := TRUE;
					
		STATE_STOPPING, STATE_ABORTING, STATE_SUSPENDING:			
		
			
			CASE em.substate OF
				
				0:
					em.description 				:= 'Clear status and close flap';
					interface.status.request := FALSE;
					interface.status.ready 	:= FALSE;
					interface.cmd.start 	:= FALSE;
					interface.cmd.brickStatusReady := FALSE;
					this.hw.do_open := FALSE;
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
					em.cmd.sc := TRUE;
				
			END_CASE

			
		STATE_CLEARING, STATE_UNSUSPENDING:
			em.description := 'waiting for flap error reset';
			
			CASE em.substate OF
				
				0:
					IF NOT this.flap.error THEN
						brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
						//Alarm texts
						this.alarm.closeTooLong.name := 'upperFlapCloseTooLong';
						this.alarm.openTooLong.name := 'upperFlapOpenTooLong';
						this.flap.close := TRUE;
						em.substate := 10;
					ELSE
						this.flap.resetError := TRUE;
					END_IF
				
				10:
					em.description := 'Wait for flap to close';
				
					IF this.flap.error THEN
						em.substate := 0;
					ELSIF this.flap.position = FLAP_CLOSED  THEN
						interface.status.request := TRUE;
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