
ACTION producing:

	CASE em.state OF
		
		
		STATE_STARTING:
			
			em.cmd.sc := em.status.parent.state = STATE_STOPPING;
			
			CASE em.substate OF
				0:
					em.description := '';
				
					IF (NOT this.newRecipeLoaded AND interface.status.teachingDone AND this.brickCountTeached = recipe.brickCount) OR interface.cmd.skipTeach OR this.hmi.capconModeOff THEN
						interface.status.teachingDone := TRUE;
						brdkStrMemSet(ADR(this.pctFromMeanToLimit),0,SIZEOF(this.pctFromMeanToLimit));
						bufferIdxCounter :=0;
						this.MTDataStatistics_Teach(Enable:=FALSE);
						this.MTFilterMovingAverage_0(Enable:=FALSE);
						this.TeachIntegral_0.Enable := FALSE;
						this.TeachIntegral_0();
						em.substate := 100;
					ELSE
						interface.status.wingStartBrickNOK	:= TRUE;
						interface.parameter.teachBrickCount := 0;
						gCapconInterface.status.teachingDone := FALSE;
						gUpperFlapInterface.cmd.resetStatistics := TRUE; //
						gBottomFlapInterface.cmd.resetCassetteWaitTime := TRUE;
						brdkStrMemSet(ADR(this.pctFromMeanToLimit),0,SIZEOF(this.pctFromMeanToLimit));
						bufferIdxCounter :=0;
						this.countGoodPortionForTeach := 0;
						this.MTDataStatistics_1(Enable:=FALSE);
						this.MTDataStatistics_0(Enable:=FALSE);
						this.MTDataStatistics_Teach(Enable:=FALSE);
						this.MTFilterMovingAverage_0(Enable:=FALSE);
						this.TeachIntegral_0.Enable := FALSE;
						this.TeachIntegral_0();
						this.noAdaptiveTeaching := 0;
						interface.status.cycleTimeAutoMode := 0;
						gBeltInterface.cmd.cycleTimeCount := 0;
						this.MTFilterMovingAverage_1.Enable := FALSE;
						this.MTFilterMovingAverage_1();
						//always delete statistics before a new teach.
						resetStatistics;
						em.substate := 10;
					END_IF
				
				10:
					em.description := 'wait for wing to be ready';
					
					IF interface.cmd.wingReady OR interface.cmd.wingRequest THEN
						interface.status.ready := TRUE;
						em.substate := 20;
					END_IF
				
				20:
					em.description := 'wait for belt to feed bricks';
					
					IF gBeltInterface.status.dropBrickDone THEN
						interface.status.ready := FALSE;
						em.substate := 30;
					END_IF
				
				30:
					em.description := 'wait to see if brick is falling';
					
					this.TON_waitTime.IN := TRUE;
					this.TON_waitTime.PT := T#400ms;
					this.TON_waitTime();
					
					interface.status.wingStart := this.TON_waitTime.ET >= T#300ms;

					IF this.TON_waitTime.Q AND NOT interface.status.brickDetected THEN
						this.TON_waitTime.IN := FALSE;
						this.TON_waitTime();
						interface.status.wingStartBrickNOK := TRUE;
						em.substate := 40;
					END_IF
				
				40:
					em.description := 'wait for wing ready';
					
					IF interface.cmd.wingCmdAck OR gMainInterface.status.emptying THEN
						interface.status.wingStart := FALSE;
						interface.status.wingStartBrickNOK := FALSE;
						interface.status.wingStartBrickOK := FALSE;
						
						this.TeachIntegral_0.Enable 			:= TRUE;
						this.TeachIntegral_0.In 				:= interface.status.integralSum / USINT_TO_REAL(recipe.brickCount);
						this.TeachIntegral_0.BrickCount 		:= recipe.brickCount;
						this.TeachIntegral_0.CapconModeOn 		:= this.hmi.capconModeOn;
						this.TeachIntegral_0.NoPeaks 			:= interface.status.noVerifiedPeaks;
						this.TeachIntegral_0.NoPortions			:= config.portionsAllowTeach;
						this.TeachIntegral_0();
						
						interface.status.teachIntegral := this.TeachIntegral_0.Out;
						
						IF this.TeachIntegral_0.Done THEN
							this.TeachIntegral_0.Enable := FALSE;
							this.TeachIntegral_0();
							interface.status.teachingDone := TRUE;
							this.newRecipeLoaded := FALSE;
							em.substate := 100;
						ELSIF this.TeachIntegral_0.Error THEN
							this.TeachIntegral_0.Enable := FALSE;
							this.TeachIntegral_0();
							em.substate := 200;
						ELSE
							em.substate := 10;
						END_IF
					END_IF

				100:
					em.description := 'Wait for bypassCassette OFF';
					
					IF NOT gMainInterface.line.bypassCassette OR gMainInterface.status.emptying THEN
						em.substate := 110;
					END_IF
					
				110:
					em.description := 'teaching done';
					this.brickCountTeached := recipe.brickCount;
					em.cmd.sc := TRUE;
				
				200:
					em.description := 'teaching error';
					this.alarm.teachingError.active := TRUE;
					em.cmd.sc := TRUE;
				
			END_CASE
			
			// redo teaching if an empty is started while the reteach is running.
			IF interface.cmd.emptyWhileTeaching THEN
				this.hmi.redoTeaching := TRUE;
				em.cmd.sc := TRUE;
			END_IF

		STATE_EXECUTE:
			
			this.timeBetweenBricks := this.timeBetweenBricks + em.status.cycleTime;
			
			CASE em.substate OF 
				0:
					em.description := 'wait for wing ready';
					
					interface.status.waiting := NOT interface.cmd.wingRequest;

					IF interface.cmd.wingRequest AND recipe.brickCount > 0 THEN
						IF recipe.brickCount <> this.brickCountTeached THEN
							this.newRecipeLoaded := TRUE;
						END_IF
						interface.status.ready := TRUE;
						em.cmd.sc := FALSE;
						this.startTime := 0;
						em.substate := 10;
					ELSE
						em.cmd.sc := TRUE;
					END_IF

				10:
					em.description := 'wait for belt to feed bricks';
					
					IF interface.cmd.wingReady AND this.startTime = 0 THEN
						this.startTime := TIME_TO_UDINT(clock_ms());
					END_IF

					IF gBeltInterface.status.dropBrickDone THEN
						interface.status.ready := FALSE;
						this.brickPresent := FALSE;
						IF this.startTime = 0 THEN
							this.startTime := TIME_TO_UDINT(clock_ms());
						END_IF
						em.substate := 20;
					END_IF
						
				20:
					em.description := 'wait to see if brick is falling';
					
					this.TON_waitTime.IN := TRUE;
					this.TON_waitTime.PT := T#400ms; // falltime through capcon is 400ms
					this.TON_waitTime();

					interface.status.wingStart := this.TON_waitTime.ET >= T#250ms;

					IF this.TON_waitTime.Q AND NOT interface.status.brickDetected THEN
						this.TON_waitTime.IN := FALSE;
						this.TON_waitTime();
						interface.status.wingStart := TRUE;
						
						em.substate := 30;
					END_IF
				
				30:
					em.description := 'validate brick';
					
					IF this.hmi.capconModeOff THEN
						// If capcon off = always OK capcon is completly OFF
						interface.status.wingStartBrickOK := TRUE;
					
						em.substate := 40;
//					ELSIF NOT gBeltInterface.status.gapOK AND (gBeltInterface.status.autoMode OR gBeltInterface.status.autoModeSimple) THEN
//						interface.status.wingStartBrickNOK := TRUE;
//						em.substate := 40;
					ELSIF interface.status.noVerifiedPeaks > interface.status.numBricksInPortion THEN
						this.hmi.count.integral.tooBig := this.hmi.count.integral.tooBig + 1;
						this.hmi.totalCount.integral.tooBig := this.hmi.totalCount.integral.tooBig + 1;
						interface.status.wingStartBrickNOK := TRUE;
						gBeltInterface.cmd.afterCount := NOT this.lastAfterCount;
						this.lastAfterCount := TRUE;
						em.substate := 40;
					ELSIF interface.status.noVerifiedPeaks < interface.status.numBricksInPortion AND this.hmi.capconModeOn THEN // only use lowerLimit if capconMode = ON
						this.hmi.count.integral.tooSmall := this.hmi.count.integral.tooSmall + 1;
						this.hmi.totalCount.integral.tooSmall := this.hmi.totalCount.integral.tooSmall + 1;
						interface.status.wingStartBrickNOK := TRUE;
						em.substate := 40;
					ELSE
						interface.status.wingStartBrickOK := TRUE;
						this.lastAfterCount := FALSE;
						em.substate := 40;
					END_IF

					this.totalTime := this.totalTime + (TIME_TO_UDINT(clock_ms())-this.startTime) + (MAX(MAX(gUpperFlapInterface.status.openCloseTime, gMiddleFlapInterface.status.openCloseTime), gBottomFlapInterface.status.openCloseTime)/1000);
					IF interface.status.wingStartBrickOK THEN
						
						this.MTFilterMovingAverage_0.Enable := TRUE;
						this.MTFilterMovingAverage_0.In := UDINT_TO_REAL(this.totalTime);
						this.MTFilterMovingAverage_0.WindowLength := 10;
						this.MTFilterMovingAverage_0();
				
						this.hmi.cycleTime := 60000/this.MTFilterMovingAverage_0.Out;
						this.hmi.cycleTimeTMU := this.MTFilterMovingAverage_0.Out/36;
						
						this.MTFilterMovingAverage_1.Enable := TRUE;
						this.MTFilterMovingAverage_1.In := UDINT_TO_REAL(this.totalTime);
						this.MTFilterMovingAverage_1.WindowLength := 20;
						this.MTFilterMovingAverage_1();
						
						interface.status.cycleTimeAutoMode := 60000/this.MTFilterMovingAverage_1.Out;
						gBeltInterface.cmd.cycleTimeCount := gBeltInterface.cmd.cycleTimeCount + 1;
						
						this.totalTime := 0;
					END_IF
					
					IF this.noAdaptiveTeaching < 8 OR this.newRecipeLoaded THEN
					
						this.TeachIntegral_0.Enable 			:= TRUE;
						this.TeachIntegral_0.In 				:= interface.status.integralSum / USINT_TO_REAL(recipe.brickCount);
						this.TeachIntegral_0.BrickCount 		:= recipe.brickCount;
						this.TeachIntegral_0.CapconModeOn 		:= this.hmi.capconModeOn;
						this.TeachIntegral_0.NoPeaks 			:= interface.status.noAdaptiveVerifiedPeaks;
						this.TeachIntegral_0.NoPortions			:= 3;
						this.TeachIntegral_0();
						
						interface.status.adaptiveTeachIntegral := this.TeachIntegral_0.Out;
						
						IF this.TeachIntegral_0.Done THEN
							this.TeachIntegral_0.Enable := FALSE;
							this.TeachIntegral_0();
							this.MTDataStatistics_0.In := this.TeachIntegral_0.Out;
							this.MTDataStatistics_0.Enable := TRUE;
							this.MTDataStatistics_0.MovingWindowLength := 8;
							this.MTDataStatistics_0();
							this.noAdaptiveTeaching := this.noAdaptiveTeaching + 1;
							IF this.newRecipeLoaded THEN
								this.newRecipeLoaded := FALSE;
								this.brickCountTeached := recipe.brickCount;
								this.countGoodPortionForTeach := 0;
								this.MTDataStatistics_1(Enable:=FALSE);
								interface.status.teachIntegral := this.TeachIntegral_0.Out;
								this.noAdaptiveTeaching := 0;
							ELSE
								interface.status.teachIntegral := this.MTDataStatistics_0.Mean;
							END_IF
						ELSIF this.TeachIntegral_0.Error THEN
							this.TeachIntegral_0.Enable := FALSE;
							this.TeachIntegral_0();
							IF this.newRecipeLoaded THEN
								this.alarm.teachingError.active := TRUE;
							END_IF
						END_IF
						
						IF interface.status.wingStartBrickOK THEN
							this.MTDataStatistics_Teach.In := interface.status.integralSum/USINT_TO_REAL(recipe.brickCount);
							this.MTDataStatistics_Teach.Enable := TRUE;
							this.MTDataStatistics_Teach.MovingWindowLength := 40;
							this.MTDataStatistics_Teach();
						END_IF
						
					ELSIF this.noAdaptiveTeaching >= 8 THEN
						
						IF interface.status.wingStartBrickOK THEN
							this.MTDataStatistics_Teach.In := interface.status.integralSum/USINT_TO_REAL(recipe.brickCount);
							this.MTDataStatistics_Teach.Enable := TRUE;
							this.MTDataStatistics_Teach.MovingWindowLength := 40;
							this.MTDataStatistics_Teach();
							
							this.hmi.capconMean := this.MTDataStatistics_Teach.Mean;
							this.hmi.capconMax := this.MTDataStatistics_Teach.MaxValue;
							this.hmi.capconMin := this.MTDataStatistics_Teach.MinValue;
							this.hmi.capconVariance := this.MTDataStatistics_Teach.Variance;
							this.hmi.integralSum := interface.status.integralSum;
							
							//
							IF this.countGoodPortionForTeach < 100 THEN
								this.MTDataStatistics_1.In := interface.status.integralSum/USINT_TO_REAL(recipe.brickCount);
								this.MTDataStatistics_1.Enable := TRUE;
								this.MTDataStatistics_1.MovingWindowLength := 40;
								this.MTDataStatistics_1();
								
								this.countGoodPortionForTeach := this.countGoodPortionForTeach + 1;
								IF this.countGoodPortionForTeach = 100 THEN
									// If 100 good portions - update teach integral to mean
									interface.status.teachIntegral := this.MTDataStatistics_1.Mean;
								END_IF
							END_IF
						END_IF
							
					END_IF


				40:
					em.description := 'wait for wing ready';
					
					IF interface.cmd.wingCmdAck OR gMainInterface.status.emptying THEN
						IF interface.status.wingStartBrickOK THEN
							this.hmi.count.portions.count := this.hmi.count.portions.count + 1;
							this.hmi.totalCount.portions.count := this.hmi.totalCount.portions.count + 1;
						ELSIF interface.status.wingStartBrickNOK THEN
							this.hmi.count.reject.count := this.hmi.count.reject.count + 1;
							this.hmi.totalCount.reject.count := this.hmi.totalCount.reject.count + 1;
						END_IF
						this.hmi.count.total := this.hmi.count.portions.count + this.hmi.count.reject.count;
						this.hmi.totalCount.total := this.hmi.totalCount.portions.count + this.hmi.totalCount.reject.count;
						IF this.hmi.count.total > 0 THEN
							tmpCal := UDINT_TO_REAL(this.hmi.count.portions.count) / UDINT_TO_REAL(this.hmi.count.total);
							this.hmi.count.portions.percent := tmpCal * 100.0;
							this.hmi.count.reject.percent := 100.0-this.hmi.count.portions.percent;
						END_IF
						this.lastPortionOK := interface.status.wingStartBrickOK;
						interface.status.wingStart 			:= FALSE;
						interface.status.wingStartBrickNOK 	:= FALSE;
						interface.status.wingStartBrickOK 	:= FALSE;
						gBeltInterface.cmd.afterCount := FALSE;
						em.substate := 0;
					END_IF
					
			END_CASE
			
			em.cmd.sc := TRUE;

		STATE_COMPLETING:
			
			interface.status.ready := interface.cmd.wingRequest;
			
			CASE em.substate OF
				0:
					em.description := 'Waiting for wing to be ready';
					IF interface.cmd.wingRequest THEN
						interface.status.wingStartBrickNOK	:= TRUE;
						em.substate := 10;
					END_IF

				10: 
					em.description := 'Waiting wing to ack reject command';
				
					IF interface.cmd.wingCmdAck THEN
						interface.status.wingStartBrickNOK	:= FALSE;
						em.substate := 0;
					END_IF
			END_CASE
							
			em.cmd.sc := interface.cmd.emptyStop;
		
		STATE_SUSPENDED:
			
			em.description := 'wing ready to receive drop';
			interface.status.ready := interface.cmd.wingReady AND NOT interface.cmd.brickIncomming;
			interface.status.waiting := NOT interface.cmd.wingReady;		
			em.cmd.sc := TRUE;
			
		STATE_ABORTED:
		
			IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortCapcon') THEN
				em.cmd.sc := TRUE;
			END_IF
			
		STATE_CLEARING:
			
			brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
			//Alarm texts
			this.alarm.teachingError.name := 'capconTeachingError';
			
			em.cmd.sc := TRUE;
		
		STATE_STOPPED:
			
			em.description := 'Waiting for start command';
			
			IF gConfig.status.loadInitialValue[3] AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
				gConfig.status.loadInitialValue[3] := FALSE;
				recipe.brickCount := 1;
				recipe.controlPrc := 45;
			END_IF
			em.cmd.sc := TRUE;
			
		STATE_STOPPING, STATE_ABORTING:
			interface.status.ready := FALSE;
			this.hmi.cycleTime := 0;
			this.hmi.cycleTimeTMU := 0;
			interface.status.cycleTimeAutoMode := 0;
			gBeltInterface.cmd.cycleTimeCount := 0;
			interface.status.wingStartBrickNOK := FALSE;
			interface.status.wingStartBrickOK := FALSE;
			interface.status.wingStart := FALSE;
			em.cmd.sc := TRUE;
		
		ELSE
			
			em.cmd.sc := TRUE;

	END_CASE
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                