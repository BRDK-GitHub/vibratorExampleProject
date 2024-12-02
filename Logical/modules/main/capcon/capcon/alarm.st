ACTION alarm:
	
	// Teaching Error
	
	IF this.alarm.teachingError.active AND NOT this.alarm.teachingError.oldActive THEN
		this.alarm.teachingError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.teachingError.name);
	END_IF
	this.alarm.teachingError.oldActive := this.alarm.teachingError.active;
	

	// Alarms are also set in sampling task

	(****************************** REACTION ******************************)
	IF em.state <> STATE_ABORTED AND em.state <> STATE_ABORTING AND em.state <> STATE_CLEARING THEN
		IF MpAlarmXCheckReaction(mpAlarmXCore,'abortCapcon') THEN
			em.cmd.abort := TRUE;
		END_IF
	END_IF
	(**********************************************************************)
	
END_ACTION
