ACTION alarm:
		
	this.TON_0.IN := TRUE;
	this.TON_0.PT := T#200ms; // only check all these alarms every 200ms.
	this.TON_0();
	
	IF this.TON_0.Q THEN
		this.TON_0.IN := FALSE;
		this.TON_0();
		this.updateStatus := TRUE; // signal to update status.
		
		interface.status.machineType := config.machineType;
		IF gBeltInterface.cmd.setDirection THEN
			gBeltInterface.cmd.setDirection := FALSE;
			config.machineType := gBeltInterface.parameter.direction;
		END_IF
		// Can't empty machine because we need a cassette
		
		IF this.alarm.cantEmptyNeedCassette.active AND NOT this.alarm.cantEmptyNeedCassette.oldActive THEN
			this.alarm.cantEmptyNeedCassette.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.cantEmptyNeedCassette.name);
		END_IF
		
		
		// reaction. Acknowledge automatically if falling edge on alarm
		IF NOT this.alarm.cantEmptyNeedCassette.active AND this.alarm.cantEmptyNeedCassette.oldActive THEN
			MpAlarmXAcknowledgeID(mpAlarmXCore, this.alarm.cantEmptyNeedCassette.instanceID);
		END_IF
		this.alarm.cantEmptyNeedCassette.oldActive := this.alarm.cantEmptyNeedCassette.active;
		
		// If brdkOPCUAMethodOperate is in error (then the machine can't recieve commands from gateway)
		
		this.alarm.opcuaMethodError.active := brdkOPCUAMethodOperate_SetMode.state = BRDK_OPCUA_METHOD_ERROR;
		IF this.alarm.opcuaMethodError.active AND NOT this.alarm.opcuaMethodError.oldActive THEN
			this.alarm.opcuaMethodError.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.opcuaMethodError.name);
		END_IF
		// Reaction. Acknoledge if falling edge on alarm
		IF NOT this.alarm.opcuaMethodError.active AND this.alarm.opcuaMethodError.oldActive THEN
			MpAlarmXAcknowledgeID(mpAlarmXCore, this.alarm.opcuaMethodError.instanceID);
		END_IF
		this.alarm.opcuaMethodError.oldActive := this.alarm.opcuaMethodError.active;
		
		// IO Link module alarm ( Brick sensor belt and leve bowl)
		
		IF NOT this.alarm.KA10.active AND this.alarm.KA10.oldActive THEN
			this.alarm.KA10.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA10.name);
		END_IF
		this.alarm.KA10.oldActive := this.alarm.KA10.active;
	
			
		// Digital Outputs 1 module alarm (bowl level and becon)
		
		IF NOT this.alarm.KA11.active AND this.alarm.KA11.oldActive THEN
			this.alarm.KA11.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA11.name);
		END_IF
		this.alarm.KA11.oldActive := this.alarm.KA11.active;
	
		// Analog Inputs module alarm (Capcon)
		
		IF NOT this.alarm.KA12.active AND this.alarm.KA12.oldActive THEN
			this.alarm.KA12.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA12.name);
		END_IF
		this.alarm.KA12.oldActive := this.alarm.KA12.active;
		
		// Potential Distributor module alarm (GND)
		
		IF NOT this.alarm.KA13.active AND this.alarm.KA13.oldActive THEN
			this.alarm.KA13.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA13.name);
		END_IF
		this.alarm.KA13.oldActive := this.alarm.KA13.active;
		
		// Digital Inputs 1 module alarm (Wing flaps change)
		
		IF NOT this.alarm.KA14.active AND this.alarm.KA14.oldActive THEN
			this.alarm.KA14.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA14.name);
		END_IF
		this.alarm.KA14.oldActive := this.alarm.KA14.active;
		
		// Digital Inputs 2 module alarm (Wing and Cassette)
		
		IF NOT this.alarm.KA15.active AND this.alarm.KA15.oldActive THEN
			this.alarm.KA15.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA15.name);
		END_IF
		this.alarm.KA15.oldActive := this.alarm.KA15.active;	
		
		
		// Digital Outputs 2 module alarm (Wing and Cassette)
		
		IF NOT this.alarm.KA16.active AND this.alarm.KA16.oldActive THEN
			this.alarm.KA16.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA16.name);
		END_IF
		this.alarm.KA16.oldActive := this.alarm.KA16.active;
		
		// Digital Outputs 3 module alarm (Feeder and bottom flap)
		
		IF NOT this.alarm.KA17.active AND this.alarm.KA17.oldActive THEN
			this.alarm.KA17.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA17.name);
		END_IF
		this.alarm.KA17.oldActive := this.alarm.KA17.active;
		
		
		
		// Digital input 3 module alarm (Feeder)
		
		IF NOT this.alarm.KA18.active AND this.alarm.KA18.oldActive THEN
			this.alarm.KA18.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA18.name);
		END_IF
		this.alarm.KA18.oldActive := this.alarm.KA18.active;
		
		
		
		// Digital Outputs 4 module alarm (Flaps)
		
		IF NOT this.alarm.KA19.active AND this.alarm.KA19.oldActive THEN
			this.alarm.KA19.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA19.name);
		END_IF
		this.alarm.KA19.oldActive := this.alarm.KA19.active;
		
		(*	Comment out and create alarms in alarmX mp file when all machines are equal!
		// Module ok KA20
		this.alarm.KA18.name := 'KA20ModuleError';
		IF NOT this.alarm.KA20 AND this.alarm.KA20.oldActive THEN
			this.alarm.KA18.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA20.name);
		END_IF
		this.alarm.KA20.oldActive := this.alarm.KA20.active;
		
		// Module ok KA21
		this.alarm.KA21.name := 'KA21ModuleError';
		IF NOT this.alarm.KA21 AND this.alarm.KA21.oldActive THEN
			this.alarm.KA21.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA21.name);
		END_IF
		this.alarm.KA21.oldActive := this.alarm.KA21.active;
		
		// Module ok KA22
		this.alarm.KA22.name := 'KA22ModuleError';
		IF NOT this.alarm.KA22 AND this.alarm.KA22.oldActive THEN
			this.alarm.KA22.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA22.name);
		END_IF
		this.alarm.KA22.oldActive := this.alarm.KA22.active;
	*)
		
		
		(*	now using PWM anymore
		// Digital output PWM module alarm
		this.alarm.KA20.name := 'KA20ModuleError';
		IF NOT this.alarm.KA20.active AND this.alarm.KA20.oldActive THEN
			this.alarm.KA20.instanceID := MpAlarmXSet(mpAlarmXCore, this.alarm.KA20.name);
		END_IF
		this.alarm.KA20.oldActive := this.alarm.KA20.active;
		*)
		
		
	
		
		(****************************** REACTION ******************************)
		IF em.state <> STATE_ABORTED AND em.state <> STATE_ABORTING AND em.state <> STATE_CLEARING THEN
			IF MpAlarmXCheckReaction(mpAlarmXCore,'abortMain') THEN
				em.cmd.abort := TRUE;
			END_IF
		END_IF
		
	
		
		IF MpAlarmXCheckReaction(mpAlarmXCore,'alarmBeaconFlash') THEN
			this.alarmBeaconFlash := TRUE;
		ELSIF MpAlarmXCheckReaction(mpAlarmXCore,'alarmBeaconFlashSlow') THEN
			this.alarmBeaconFlashSlow := TRUE;
		ELSIF MpAlarmXCheckReaction(mpAlarmXCore,'alarmBeaconOn') THEN
			this.alarmBeaconOn := TRUE;
		ELSE
			this.alarmBeaconFlash := this.alarmBeaconFlashSlow := this.alarmBeaconOn := FALSE;
		END_IF
		(**********************************************************************)
		
	END_IF	
	

	// Set alarm beacon depending on multiple situations
	IF this.hmi.alarmBeaconFATTest THEN
		// FAT overwrites everyone.
		this.hw.do_alarmBeacon := TRUE;
	ELSIF this.alarmBeaconFlash THEN
		this.TOF_alarmBeaconOn(IN := this.TON_alarmBeaconOff.Q, PT := T#100ms);
		this.TON_alarmBeaconOff(IN := NOT this.TOF_alarmBeaconOn.Q, PT := T#100ms);
		this.hw.do_alarmBeacon := this.TOF_alarmBeaconOn.Q;
	ELSIF this.alarmBeaconFlashSlow THEN
		this.TOF_alarmBeaconOn(IN := this.TON_alarmBeaconOff.Q, PT := T#250ms);
		this.TON_alarmBeaconOff(IN := NOT this.TOF_alarmBeaconOn.Q, PT := T#250ms);
		this.hw.do_alarmBeacon := this.TOF_alarmBeaconOn.Q;
	ELSIF this.alarmBeaconOn THEN
		this.hw.do_alarmBeacon := TRUE;
	ELSE
		this.hw.do_alarmBeacon := FALSE;
	END_IF

	
END_ACTION
