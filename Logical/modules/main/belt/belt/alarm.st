ACTION alarm:
	
	// Extra check if belt is stopped and vibrator is running. Happend in production
	IF (gVibratorInterface[0].status.percent > 0 OR gVibratorInterface[1].status.percent > 0) AND axis.status.actVelocity < 10.0 THEN
		this.timeBeltStoppedButVibrRunning := this.timeBeltStoppedButVibrRunning + em.status.cycleTime;
	ELSE
		this.timeBeltStoppedButVibrRunning := 0;
	END_IF
	
	// Missing elements
	this.alarm.missingElements.active := this.TON_missingElements.Q;
	IF this.alarm.missingElements.active AND NOT this.alarm.missingElements.oldActive THEN
		this.alarm.missingElements.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.missingElements.name);
	ELSIF NOT this.alarm.missingElements.active AND this.alarm.missingElements.oldActive THEN
		MpAlarmXAcknowledgeID(mpAlarmXCore, this.alarm.missingElements.instanceID);
	END_IF
	this.alarm.missingElements.oldActive := this.alarm.missingElements.active;
	
	// Axis error alarm
	this.alarm.axisError.active := (axis.status.error.fault AND axis.status.driveStatus.initialized);
	IF this.alarm.axisError.active AND NOT this.alarm.axisError.oldActive THEN
		IF axis.status.error.count < 1 THEN
			this.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.axisError.name);
		ELSE
			FOR j:=0 TO (axis.status.error.count-1) DO
				IF brdkStrSearch(ADR(axis.status.error.text.active[j]),ADR('Lag error')) <> -1 THEN
					this.alarm.beltBlocked.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.beltBlocked.name);
					EXIT;
				ELSIF j=(axis.status.error.count-1) THEN
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
		this.hmi.showHighWaitspeedAlarm := recipe.waitSpeed>140;
		this.hmi.enableStaticMode := NOT this.hmi.enableAutoMode;
		this.hmi.showPermanentAutoModeButton := NOT config.hideExperimentalFeatures;
		
		(****************************** REACTION ******************************)
		
		IF em.state <> STATE_ABORTED AND em.state <> STATE_ABORTING AND em.state <> STATE_CLEARING THEN
			IF MpAlarmXCheckReaction(mpAlarmXCore,'abortBelt') THEN
				em.cmd.abort := TRUE;
			END_IF
		END_IF
		(**********************************************************************)

	END_IF
	
END_ACTION
