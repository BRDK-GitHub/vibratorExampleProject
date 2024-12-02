
ACTION producing:

	CASE em.state OF
			
		STATE_STOPPED:
			em.description 			:= 'start wing unit right away';
			
			IF gUpperFlapInterface.status.active AND gMiddleFlapInterface.status.active AND gBottomFlapInterface.status.active THEN
				// start wing as soon as all childs are active (they are active when they enter STATE_STOPPED).
				this.time.elapsed := this.time.elapsed + em.status.cycleTime;
				IF this.time.elapsed >= 2000000 THEN
					// Wait 2s before we start.
					em.cmd.sc 				:= TRUE;
					em.cmd.reset			:= TRUE;
				END_IF
			ELSE
				this.time.elapsed := 0;
			END_IF
			
			
		STATE_IDLE:
			em.description 	:= 'wing unit must always be started';
			em.cmd.sc := em.cmd.start 		:= TRUE;
		
		STATE_STARTING:
			em.description := 'waiting for ready command from upper flap';
//	
				interface.status.ready 	:= TRUE;
				interface.cmd.startManuelMode := FALSE;
				
				this.cycleTime		:= 0;
				this.cycleTimeIdx	:= 0;
				this.waitingTimeIdx	:= 0;
				this.hmi.cycleTime := 0;
				this.hmi.cycleTimeTmu := 0;
				this.hmi.waitTimeUtilisation := 0;
				brdkStrMemSet(ADR(this.cycleTimes),0,SIZEOF(this.cycleTimes));
				brdkStrMemSet(ADR(this.cycleTimesTmu),0,SIZEOF(this.cycleTimesTmu));
				brdkStrMemSet(ADR(this.waitingTimeBuffer),0,SIZEOF(this.waitingTimeBuffer));
			
				interface.status.request := TRUE;
				this.utilityBufferActive := FALSE;
				
				IF gCapconInterface.status.teachingDone THEN
					this.blockCycleTime := TRUE;
				ELSE
					this.blockCycleTime := FALSE;
				END_IF
				
				this.oldEmptyMode := interface.cmd.shaftModeEmpty; // To avoid delay on first start. Only relevant when changing mode doing STATE_EXECUTE.
				em.cmd.sc 	:= TRUE;

		STATE_EXECUTE:
			
			interface.status.ready := gUpperFlapInterface.status.ready;
			
			em.description 									:= 'waiting for commands';
			
			IF interface.cmd.startBrick AND NOT interface.status.commandAck THEN
				gUpperFlapInterface.cmd.start 				:= TRUE;
				interface.status.ready 						:= FALSE;
				interface.status.request					:= FALSE;
				interface.status.commandAck					:= TRUE;
			END_IF
			
			IF (interface.cmd.startBrickOK OR interface.cmd.startBrickNOK) AND NOT gUpperFlapInterface.cmd.brickStatusReady THEN
				gUpperFlapInterface.parameter.brickStatus 	:= SEL(interface.cmd.startBrickNOK, BRICK_STATUS_OK, BRICK_STATUS_NOK);
				gUpperFlapInterface.cmd.brickStatusReady 	:= TRUE;
	
				IF NOT interface.cmd.startBrick AND NOT interface.status.commandAck THEN
					gUpperFlapInterface.cmd.start 				:= TRUE;
					interface.status.ready 						:= FALSE;
					interface.status.request					:= FALSE;
					interface.status.commandAck					:= TRUE;
				END_IF
			END_IF
			
			IF interface.status.commandAck AND (NOT interface.cmd.startBrickOK AND NOT interface.cmd.startBrickNOK AND NOT interface.cmd.startBrick) THEN
				interface.status.commandAck := FALSE;
			END_IF
			
			
			CASE em.substate OF
				0:
					
					IF NOT interface.status.request AND NOT gCapconInterface.status.wingDosing  THEN
						em.substate := 10;
					END_IF					

				10:
					
					em.description := 'waiting for upper flap to be request';		
					
					IF gUpperFlapInterface.status.request  THEN
						interface.status.request 	:= TRUE;
						em.substate 			:= 20;
					END_IF
				
				20:
					em.description := 'Wait for upperFlap request false';
					
					IF NOT gUpperFlapInterface.status.request THEN
						em.substate := 0;
					END_IF

			END_CASE
			
			(**** Manuel mode ****)
			testing;

			
			this.CycleTimeCalc_0.Enable := em.status.parent.state = STATE_EXECUTE;
			this.CycleTimeCalc_0.MiddleFlapReady := gMiddleFlapInterface.status.ready;
			this.CycleTimeCalc_0.UpperFlapReady := gUpperFlapInterface.status.ready;
			this.CycleTimeCalc_0.Stop := gMiddleFlapInterface.cmd.updateStatistics AND gMiddleFlapInterface.parameter.brickStatus = BRICK_STATUS_OK;
			this.CycleTimeCalc_0();

			this.hmi.cycleTime := this.CycleTimeCalc_0.CycleTime;
			this.hmi.cycleTimeTmu := this.CycleTimeCalc_0.TMU;
		
			gMiddleFlapInterface.cmd.updateStatistics := FALSE;
			
			CASE this.waitTimeState OF
				0:
					IF interface.cmd.startBrickOK OR interface.cmd.startBrickNOK THEN		
						this.utilityBufferActive := TRUE;	// only start buffer after first element fall through capcon.
						this.waitTimeState := 10;
					END_IF
				10:
					this.waitTime :=this. waitTime + em.status.cycleTime;
					IF gMiddleFlapInterface.status.ready  THEN
						this.waitTimeState := 0;
					END_IF
			END_CASE
					
			this.waitingTimeUtilisation := this.waitingTimeUtilisation + em.status.cycleTime;
			IF 1000000 < this.waitingTimeUtilisation AND this.utilityBufferActive THEN // wait 1 sec and wait for first element to fall through capcon.
				IF this.waitingTimeBuffer[0] = 0 THEN
					FOR j := 0 TO 59 DO
						this.waitingTimeBuffer[j] := UDINT_TO_REAL(this.waitTime);	// if buffer is new fill the whole buffer with the first result
					END_FOR
				ELSE
					this.waitingTimeBuffer[this.waitingTimeIdx] := UDINT_TO_REAL(this.waitTime);
				END_IF
				this.waitingTimeIdx := (this.waitingTimeIdx+1) MOD 60; // 60 samples in ring buffer
				this.waitTime := 0;
				this.waitingTimeUtilisation := 0;
				this.hmi.waitTimeUtilisation	:= 0;
				FOR j := 0 TO 59 DO
					this.hmi.waitTimeUtilisation := this.hmi.waitTimeUtilisation + this.waitingTimeBuffer[j];	
				END_FOR
				this.hmi.waitTimeUtilisation := 100-(this.hmi.waitTimeUtilisation/60000000)*100;	
			END_IF
			
			// Command from main that we should empty now.
			IF gWingInterface.cmd.emptyStart THEN
				gWingInterface.cmd.emptyStart := FALSE;
				em.cmd.complete := TRUE;
			END_IF
			
			
			gBottomFlapInterface.parameter.shaftMode 	:= SEL(interface.cmd.shaftModeEmpty, SHAFT_MODE_NORMAL, SHAFT_MODE_EMPTY);	// set shaft mode for bottom flap
			IF interface.cmd.shaftModeEmpty AND NOT this.oldEmptyMode THEN
				// Rising edge on empty mode.
				gBottomFlapInterface.cmd.waitModeChange := TRUE;
			END_IF
			this.oldEmptyMode := interface.cmd.shaftModeEmpty;
			
			em.cmd.sc									:= TRUE;
			
		STATE_COMPLETE:
			em.description 				:= 'Emptying machine';
			
			interface.status.request					:= TRUE;
			IF interface.cmd.confirmEmpty OR gMainInterface.status.state <> STATE_COMPLETING THEN
				interface.cmd.confirmEmpty := FALSE;
				interface.status.commandAck := FALSE;
				em.cmd.stop := TRUE;
			END_IF
			em.cmd.sc := TRUE;
			
		STATE_STOPPING,STATE_ABORTING,STATE_SUSPENDING:
			em.description 				:= 'clear wing ready signal';
			interface.status.ready 		:= FALSE;
			interface.status.startTestSequence := FALSE;
			interface.status.commandAck := FALSE;
			this.test.startTestSequence := this.test.runUpperFlapContinuously := this.test.runMiddleFlapContinuously := this.test.runBottomFlapContinuously := FALSE;
			em.cmd.sc					:= TRUE;
			
		STATE_ABORTED:
			em.description := 'waiting for achknowledge comand';
			IF  NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortWing') THEN
				em.cmd.sc 		:= TRUE;
			END_IF
			
		STATE_CLEARING:
			em.description := 'reset and clear alarms';
			brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
			em.cmd.sc := TRUE;
		
		STATE_SUSPENDED:
			
			IF  NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortWing') THEN
				em.cmd.start := TRUE;
				em.cmd.sc := TRUE;
			END_IF
		
		ELSE
			em.cmd.sc := TRUE;

	END_CASE
	
END_ACTION