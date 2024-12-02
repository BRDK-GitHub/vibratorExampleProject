ACTION alarm:

	// Axis error alarm
	this.alarm.axisError.active := (axis.status.error.fault AND axis.status.driveStatus.initialized);
	IF this.alarm.axisError.active AND NOT this.alarm.axisError.oldActive THEN
		IF axis.status.error.count < 1 THEN
			this.axisAlarmText := SEL(i=0,'Linear Feeder axis error','Circular Feeder axis error'); // no specified text - just write default text.
			this.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.axisError.name);
		ELSE
			FOR k:=0 TO (axis.status.error.count-1) DO
				IF axis.status.error.text.active[k] <> '' THEN
					this.axisAlarmText := axis.status.error.text.active[k]; // Use specified alarm text from brdkMC axis FB.
					this.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.axisError.name);
				ELSE
					this.axisAlarmText := SEL(i=0,'Linear Feeder axis error','Circular Feeder axis error'); // no specified text - just write default text.
					this.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.axisError.name);
				END_IF
			END_FOR
		END_IF
	END_IF
	this.alarm.axisError.oldActive := this.alarm.axisError.active;
	
	this.TON_alarmReaction.IN := TRUE;
	this.TON_alarmReaction.PT := T#200ms;
	this.TON_alarmReaction();
	
	IF this.TON_alarmReaction.Q THEN
		this.TON_alarmReaction.IN := FALSE;
		this.TON_alarmReaction();
		
		(****************************** REACTION ******************************)
		IF em.state <> STATE_ABORTED AND em.state <> STATE_ABORTING AND em.state <> STATE_CLEARING THEN
			IF (i=0 AND MpAlarmXCheckReaction(mpAlarmXCore,'abortCircularFeeder')) OR 
				(i=1 AND MpAlarmXCheckReaction(mpAlarmXCore,'abortLinearFeeder')) THEN
				em.cmd.abort := TRUE;
			END_IF
		END_IF
		(**********************************************************************)
		
	END_IF
	
END_ACTION
