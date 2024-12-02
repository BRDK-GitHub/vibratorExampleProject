
ACTION producing:
	
	CASE em.state OF
		
		STATE_RESETTING:
			this.hw.do_wo_ON	:= TRUE;
			this.reteach := FALSE;
			em.cmd.sc := TRUE;
		
		STATE_IDLE:
	
			em.description := 'Waiting for operator confirm of mechanical settings';
			
			IF this.newRecipeLoaded AND NOT interface.status.emptying THEN
			//	this.hmi.openConfirmDialog := TRUE;
			//	IF this.hmi.cmd.confirm THEN
			//		this.hmi.openConfirmDialog := FALSE;
			em.cmd.start := em.cmd.sc := TRUE;
			this.newRecipeLoaded := FALSE;
			//	END_IF
			ELSE
				em.cmd.start := TRUE;
			END_IF
			
			em.cmd.sc := TRUE;
			
		STATE_STARTING:
			
			em.description := 'Waiting for sub modules to finish starting';
			
			interface.status.machineFirstStart := TRUE;
			interface.status.feederStart := TRUE;
			gRecipe.status.newRecipeLoaded := brdkStrCmp(ADR(recipe.itemNumber),ADR(this.oldItemNumber)) <> 0; 
			this.oldItemNumber := recipe.itemNumber;
			// If user will empty machine while capcon is teaching
			IF this.hmi.cmd.empty = 1 OR gMainInterface.line.empty THEN
				gCapconInterface.cmd.emptyWhileTeaching := TRUE;
				this.hmi.cmd.redoTeaching := TRUE;
			END_IF
			
			em.cmd.sc := TRUE;
				
		STATE_EXECUTE:
			interface.status.feederStart := (this.hmi.cmd.start OR interface.line.start);
		
			IF (this.hmi.cmd.empty = 1 OR gMainInterface.line.empty OR interface.status.emptying OR gCapconInterface.cmd.emptyWhileTeaching) THEN
				interface.status.emptying := TRUE;
				IF interface.cmd.wingReadyToEmpty THEN
					this.alarm.cantEmptyNeedCassette.active := FALSE;
					gCapconInterface.cmd.emptyWhileTeaching := FALSE;
					em.cmd.complete := TRUE;
				ELSE
					this.alarm.cantEmptyNeedCassette.active := TRUE;
				END_IF
			END_IF
			

			
			em.cmd.sc := TRUE;
			
		STATE_SUSPENDED:
			
			em.description := 'Wing ready to receive drop';
			
			em.cmd.start := NOT interface.cmd.capconWaiting OR USINT_TO_BOOL(this.hmi.cmd.empty) OR gMainInterface.line.empty;
			em.cmd.sc := TRUE;
		
		STATE_COMPLETING:
		
			CASE em.substate OF
				
				0:
					gWingInterface.cmd.emptyStart := TRUE;
					
					em.substate := 10;
				
				10:
					interface.status.emptying := TRUE;
					interface.status.feederStop := FALSE;
					interface.status.feederStart := FALSE;
		
					em.description := 'wait for machine to be empty confirm';
					
					IF this.hmi.cmd.confirm OR this.hmi.cmd.stop THEN // In some very odd situation it happened that the dialog with "confirm empty" didnt show and operator couldn't stop machine. Not the stop button will also stop the empty routine.
						this.hmi.cmd.confirm := FALSE;
						interface.line.emptyMode := FALSE;
						interface.line.empty := FALSE;
						hmiEmptyMode := FALSE;
						interface.status.emptying := FALSE;
						gWingInterface.cmd.confirmEmpty := TRUE;
						em.substate := 20;
					END_IF
				
				20:
					em.description := 'waiting for empty to finish';
					
					interface.status.doCalibrate := TRUE;
					
					em.cmd.sc := TRUE;

			END_CASE
			
		STATE_COMPLETE:
			
			gCapconInterface.cmd.reTeach := TRUE;
			interface.status.doCalibrate := FALSE;
			
			em.cmd.stop := em.cmd.sc := TRUE;
			
		STATE_STOPPING,STATE_ABORTING:
			
			interface.status.feederStart := FALSE;
			interface.status.feederStop := TRUE;
			this.hmi.cmd.confirm := FALSE;
			em.cmd.sc := TRUE;
			
		STATE_STOPPED:
			
			em.description	:= 'waiting for cmd';
			
			IF gWingInterface.status.stepperWUConnected THEN
				em.cmd.reset := (this.hw.di_stepperWUExecute[0] OR this.hw.di_stepperWUExecute[1]) AND (this.reteach OR this.hmi.cmd.start OR interface.line.start OR USINT_TO_BOOL(this.hmi.cmd.empty));
			ELSE
				em.cmd.reset := this.reteach OR this.hmi.cmd.start OR USINT_TO_BOOL(this.hmi.cmd.empty) OR interface.line.start;
			END_IF

			interface.status.emptying := USINT_TO_BOOL(this.hmi.cmd.empty);
			
			interface.status.feederStop := this.hmi.cmd.stop;
			interface.status.feederStart := FALSE;
			
			IF gWingInterface.cmd.changeMode THEN
				gWingInterface.cmd.changeMode := FALSE;
				em.mode := MODE_MANUAL;
			END_IF
			
		//	this.hmi.openConfirmDialog := FALSE;
		
		
			this.hmi.cmd.stop := FALSE;
			
			FOR i := 0 TO 20 BY 1 DO
				IF gMainInterface.cmd.activateCalibrateMode[i] THEN
					em.mode := MODE_CALIBRATING;
				END_IF
				
			END_FOR
			
			em.cmd.sc := TRUE;
			
		STATE_ABORTED:
			
			IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortMain') THEN
				em.cmd.clear := em.cmd.sc := TRUE;
			END_IF
			
		STATE_CLEARING:
			
			brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
			// Alarm texts
			this.alarm.cantEmptyNeedCassette.name := 'cantEmptyNeedCassette';
			this.alarm.opcuaMethodError.name := 'opcuaMethodError';
			this.alarm.KA10.name := 'KA10ModuleError';
			this.alarm.KA11.name := 'KA11ModuleError';
			this.alarm.KA12.name := 'KA12ModuleError';
			this.alarm.KA13.name := 'KA13ModuleError';
			this.alarm.KA14.name := 'KA14ModuleError';
			this.alarm.KA15.name := 'KA15ModuleError';
			this.alarm.KA16.name := 'KA16ModuleError';
			this.alarm.KA17.name := 'KA17ModuleError';
			this.alarm.KA18.name := 'KA18ModuleError';
			this.alarm.KA19.name := 'KA19ModuleError';
			
			this.TON_clearing(IN := TRUE, PT := T#1s);
			gBottomFlapInterface.status.neighbourDisappeared := FALSE;
			this.hw.do_clearWU	:= TRUE;
			IF this.TON_clearing.Q THEN
				this.hw.do_clearWU	:= FALSE;
				this.TON_clearing(IN := FALSE);
				em.cmd.sc := TRUE;
			END_IF
	
		ELSE
			
			em.cmd.sc := TRUE;

	END_CASE
	
	
	this.hw.do_wo_ON := em.state <> STATE_STOPPED AND em.state <> STATE_COMPLETE AND em.state <> STATE_ABORTED AND NOT gWingInterface.status.wingEmpty;
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                