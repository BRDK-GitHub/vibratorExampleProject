ACTION alarm:
	
	
	// Low level
	this.TON_lowLevel(IN := NOT this.hw.di_levelSensorBelt AND em.state <> STATE_STOPPED, PT := T#2s);
	this.alarm.lowLevel.active := this.TON_lowLevel.Q;

	IF this.alarm.lowLevel.active AND NOT this.alarm.lowLevel.oldActive THEN
		this.alarm.lowLevel.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.lowLevel.name);
	ELSIF this.alarm.lowLevel.oldActive AND NOT this.alarm.lowLevel.active THEN
		MpAlarmXAcknowledgeID(mpAlarmXCore, this.alarm.lowLevel.instanceID);
	END_IF
	this.alarm.lowLevel.oldActive := this.alarm.lowLevel.active;
	
//	IF this.hw.di_levelSensorBelt THEN
//		this.alarm.lowLevel.active := FALSE;
//		this.lowLevelTime := 0;
//	ELSIF this.belt.state = FEEDER_BELT_FORWARDS THEN
//		this.lowLevelTime := this.lowLevelTime + em.status.cycleTime;
//		
//		IF this.lowLevelTime >= config.alarmLowLevelTime THEN
//			this.alarm.lowLevel.active := TRUE;
//		END_IF
//	END_IF
	
	// Box Missing
	
	IF this.alarm.boxMissing.active AND NOT this.alarm.boxMissing.oldActive THEN
		this.alarm.boxMissing.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.boxMissing.name);
	ELSIF this.alarm.boxMissing.oldActive AND NOT this.alarm.boxMissing.active THEN
		MpAlarmXAcknowledgeID(mpAlarmXCore, this.alarm.boxMissing.instanceID);
	END_IF
	this.alarm.boxMissing.oldActive := this.alarm.boxMissing.active;
	
	// Cannot Close Flap
	IF gAlarm.status.ready THEN
		IF this.alarm.cannotCloseFlap.active AND NOT this.alarm.cannotCloseFlap.oldActive THEN
			this.alarm.cannotCloseFlap.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.cannotCloseFlap.name);
		END_IF
		this.alarm.cannotCloseFlap.oldActive := this.alarm.cannotCloseFlap.active;
	END_IF
	
	// Cannot Open Flap
	IF gAlarm.status.ready THEN
		IF this.alarm.cannotOpenFlap.active AND NOT this.alarm.cannotOpenFlap.oldActive THEN
			this.alarm.cannotOpenFlap.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.cannotOpenFlap.name);
		END_IF
		this.alarm.cannotOpenFlap.oldActive := this.alarm.cannotOpenFlap.active AND gAlarm.status.ready;
	END_IF
	
	// Belt feeder empty
	
	IF this.alarm.beltFeederEmpty.active AND NOT this.alarm.beltFeederEmpty.oldActive THEN
		this.alarm.beltFeederEmpty.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.cannotOpenFlap.name);
	END_IF
	this.alarm.beltFeederEmpty.oldActive := this.alarm.beltFeederEmpty.active;
	
	(****************************** REACTION ******************************)
	IF em.state <> STATE_ABORTED AND em.state <> STATE_ABORTING AND em.state <> STATE_CLEARING THEN
		IF MpAlarmXCheckReaction(mpAlarmXCore,'abortFeeder') THEN
			em.cmd.abort := TRUE;
		END_IF
	END_IF
	(**********************************************************************)
	
END_ACTION
