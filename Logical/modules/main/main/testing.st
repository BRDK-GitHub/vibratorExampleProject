
ACTION testing: 

	CASE em.state OF
		
		STATE_STOPPED:
			
			IF gWingInterface.cmd.changeMode THEN
				gWingInterface.cmd.changeMode := FALSE;
				em.mode := MODE_PRODUCING;
			END_IF
			em.cmd.sc := TRUE;
	
			
		STATE_IDLE:
			
			em.cmd.start := em.cmd.sc := TRUE;
		
		STATE_EXECUTE:
			
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
			em.cmd.sc := TRUE;
		ELSE
			
			em.cmd.sc := TRUE;
		
	END_CASE
	
END_ACTION
