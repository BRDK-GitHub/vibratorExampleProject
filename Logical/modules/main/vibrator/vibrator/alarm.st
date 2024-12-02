ACTION alarm:
	(*
	// Axis fault
	local.alarm.axisFault.active := (axis.status.error.fault AND axis.status.driveStatus.initialized);
	local.alarm.axisFault.name := SEL(i=0, 'linearFeederAxisFault', 'circularFeederAxisFault');
	IF local.alarm.axisFault.active AND NOT local.alarm.axisFault.oldActive THEN
		local.alarm.axisFault.instanceID := MpAlarmXSet(mpAlarmXCore, local.alarm.axisFault.name);
	END_IF
	local.alarm.axisFault.oldActive := local.alarm.axisFault.active;

	
	
	IF local.alarm.axisFault.active AND NOT local.alarm.axisFault.oldActive THEN
		local.alarm.axisFault.instanceID := MpAlarmXSet(mpAlarmXCore, local.alarm.axisFault.name);
	END_IF
	local.alarm.axisFault.oldActive := local.alarm.axisFault.active;
	
	*)
	
	// Axis error alarm
	local.alarm.axisError.active := (axis.status.error.fault AND axis.status.driveStatus.initialized);
	IF local.alarm.axisError.active AND NOT local.alarm.axisError.oldActive THEN
		IF axis.status.error.count < 1 THEN
			local.axisAlarmText := SEL(i=0,'Linear Feeder axis error','Circular Feeder axis error'); // no specified text - just write default text.
			local.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, local.alarm.axisError.name);
		ELSE
			FOR k:=0 TO (axis.status.error.count-1) DO
				IF axis.status.error.text.active[k] <> '' THEN
					local.axisAlarmText := axis.status.error.text.active[k]; // Use specified alarm text from brdkMC axis FB.
					local.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, local.alarm.axisError.name);
				ELSE
					local.axisAlarmText := SEL(i=0,'Linear Feeder axis error','Circular Feeder axis error'); // no specified text - just write default text.
					local.alarm.axisError.instanceID := MpAlarmXSet(mpAlarmXCore, local.alarm.axisError.name);
				END_IF
			END_FOR
		END_IF
	END_IF
	local.alarm.axisError.oldActive := local.alarm.axisError.active;
	
	local.TON_alarmReaction.IN := TRUE;
	local.TON_alarmReaction.PT := T#200ms;
	local.TON_alarmReaction();
	
	IF local.TON_alarmReaction.Q THEN
		local.TON_alarmReaction.IN := FALSE;
		local.TON_alarmReaction();
		
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
