ACTION alarm:
	
	// Open Time Too Long
	
	IF this.alarm.openTooLong.active AND NOT this.alarm.openTooLong.oldActive THEN
		this.alarm.openTooLong.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.openTooLong.name);
	END_IF
	this.alarm.openTooLong.oldActive := this.alarm.openTooLong.active;
	
	// Close Time Too Long
	
	IF this.alarm.closeTooLong.active AND NOT this.alarm.closeTooLong.oldActive THEN
		this.alarm.closeTooLong.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.closeTooLong.name);
	END_IF
	this.alarm.closeTooLong.oldActive := this.alarm.closeTooLong.active;
		

END_ACTION

