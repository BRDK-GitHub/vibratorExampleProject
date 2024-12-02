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
	
	// Open Neighbour Time Too Long

	IF this.alarm.openNeighbourTooLong.active AND NOT this.alarm.openNeighbourTooLong.oldActive THEN
		this.alarm.openNeighbourTooLong.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.openNeighbourTooLong.name);
	END_IF
	this.alarm.openNeighbourTooLong.oldActive := this.alarm.openNeighbourTooLong.active;
	
	// Close Neighbour Time Too Long
	
	IF this.alarm.closeNeighbourTooLong.active AND NOT this.alarm.closeNeighbourTooLong.oldActive THEN
		this.alarm.closeNeighbourTooLong.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.closeNeighbourTooLong.name);
	END_IF
	this.alarm.closeNeighbourTooLong.oldActive := this.alarm.closeNeighbourTooLong.active;
	
	// Neighbour machine not active

	this.alarm.neighbourNotActive.active := NOT this.hw.di_neighbourActive AND this.old_neighbourActive AND gMainInterface.status.machineStart;
	this.old_neighbourActive := this.hw.di_neighbourActive;
	
	IF this.alarm.neighbourNotActive.active AND NOT this.alarm.neighbourNotActive.oldActive THEN
		this.alarm.neighbourNotActive.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.neighbourNotActive.name);
		interface.status.neighbourDisappeared := TRUE;
	END_IF
	this.alarm.neighbourNotActive.oldActive := this.alarm.neighbourNotActive.active;
		


END_ACTION
