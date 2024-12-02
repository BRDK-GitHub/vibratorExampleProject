
ACTION commonStoppingHoldingCompletingAbortingSuspending: 
	
	
	this.setSpeed := 0.0;
	interface.status.speed := lego_speed_stop;
	this.hmi.force.enable := FALSE;
		
	CASE em.substate OF
		0:
			em.description := 'If disabled it is stopped -> continue';
			
			IF axis.status.state <> DISABLED THEN
				em.substate := 5;		// go wait for axis to be stopped before taking power.
			ELSE
				em.cmd.sc := TRUE;
			END_IF
			
			
		5:
			em.description := 'waiting for belt to be stopped';
			
			IF NOT axis.status.inMotion THEN
				em.substate := 10;	
			END_IF
		10:
			em.description := 'waiting for power of of servo axis';
			axis.command.power := FALSE;
			IF NOT axis.status.powerOn THEN
				em.cmd.sc := TRUE;
			END_IF
	END_CASE
		

				

END_ACTION

ACTION commonClearing: 

	em.description := 'clear servo axis error(s)';
	
	IF axis.status.error.fault THEN
		axis.command.errorAcknowledge	:= TRUE;
	ELSE
		axis.command.errorAcknowledge	:= FALSE;
		brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
		//Set alarm texts
		this.alarm.missingElements.name := 'beltMissingElements';
		this.alarm.axisError.name := 'beltAxisError';
		this.alarm.beltBlocked.name := 'beltBlocked';
		em.cmd.sc := TRUE;
	END_IF

	

END_ACTION