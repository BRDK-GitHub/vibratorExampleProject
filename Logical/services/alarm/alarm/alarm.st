
PROGRAM _INIT

	cm.setup.name			:= 'alarm';
	cm.setup.parent.name 	:= 'main';
	gAlarm.status.ready		:= FALSE;
	
	 
END_PROGRAM

PROGRAM _CYCLIC

	IF MpAlarmXCore_0.Error THEN
		cm.state := 9999;
	END_IF
	
	CASE cm.state OF

		0:
			cm.description 	:= 'wait for MpAlarmXCore and MpAlarmXListUI_0 to be active';
			
			IF MpAlarmXCore_0.Active AND gFile.status.ready THEN
				MpAlarmXHistory_0.Enable := TRUE;
				cm.state 	:= 100;
			END_IF

		100:
			cm.description 		:= 'alarm system ready';
			
			gAlarm.status.ready	:= TRUE;
			
			TON_0.IN := TRUE;;
			TON_0.PT := T#30m;
			TON_0();
			
			IF gAlarm.cmd.acknowledge THEN
				AlarmXListUIConnectType.Acknowledge := TRUE;
				gAlarm.cmd.acknowledge := FALSE;
			ELSIF gAlarm.cmd.acknowledgeAll THEN
				AlarmXListUIConnectType.AcknowledgeAll := TRUE;
				gAlarm.cmd.acknowledgeAll := FALSE;
			ELSIF gAlarm.cmd.exportLogToCsv OR TON_0.Q THEN
				TON_0.IN := gAlarm.cmd.exportLogToCsv := FALSE;
				TON_0();
				logAlarmsError := FALSE;
				cm.state := 200;
			END_IF
			
		200:	
			cm.description := '';

			DevLink_0.enable := TRUE;
			DevLink_0.pDevice := ADR('PLC');
			DevLink_0.pParam := ADR('/SIP=192.168.2.11 /PROTOCOL=ftp /USER=admin /PASSWORD=admin');
			DevLink_0();
			
			IF DevLink_0.status = ERR_OK OR DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
				DevLink_0(enable:=FALSE);	
				cm.state := 210;
			ELSIF DevLink_0.status <> ERR_FUB_BUSY THEN
				DevLink_0(enable:=FALSE);	
				logAlarmsError := TRUE;
				cm.state := 100;
			END_IF
			
		210:
			DirDeleteEx_0.enable := TRUE;
			DirDeleteEx_0.pDevice := ADR('PLC');
			DirDeleteEx_0.pName := ADR('F:\alarm');
			DirDeleteEx_0();
			
			IF DirDeleteEx_0.status = ERR_OK OR DirDeleteEx_0.status = fiERR_DIR_NOT_EXIST THEN
				DirDeleteEx_0(enable:=FALSE);
				cm.state := 220;
			ELSIF DirDeleteEx_0.status <> ERR_FUB_BUSY THEN
				DirDeleteEx_0(enable:=FALSE);
				logAlarmsError := TRUE;
				cm.state := 100;
			END_IF
			
		220:
			DirCreate_0.enable := TRUE;
			DirCreate_0.pDevice := ADR('PLC');
			DirCreate_0.pName := ADR('F:\alarm');
			DirCreate_0();
			
			IF DirCreate_0.status = ERR_OK THEN
				DirCreate_0(enable:=FALSE);
				MpAlarmXHistory_0.Export := TRUE;
				cm.state := 230;
			ELSIF DirCreate_0.status <> ERR_FUB_BUSY THEN
				DirCreate_0(enable:=FALSE);
				logAlarmsError := TRUE;
				cm.state := 100;
			END_IF
			
		230:
			IF MpAlarmXHistory_0.CommandDone THEN
				MpAlarmXHistory_0.Export := FALSE;
				cm.state := 100;
			ELSIF MpAlarmXHistory_0.Error THEN
				MpAlarmXHistory_0.Enable := FALSE;
				MpAlarmXHistory_0.Export := FALSE;
				logAlarmsError := TRUE;
				cm.state := 100;
			END_IF
			
		9999:
			cm.description 	:= 'wait for error reset';
			
			MpAlarmXCore_0.ErrorReset := TRUE;
			
			IF NOT MpAlarmXCore_0.Error THEN
				MpAlarmXCore_0.ErrorReset := FALSE;
				cm.state 	:= 0;
			END_IF

		
		
		
	END_CASE

	cm();
	
//	MpAlarmXListUI_0.MpLink := ADR(mpAlarmXCore);
//	MpAlarmXListUI_0.Enable := TRUE;
//	MpAlarmXListUI_0.UIConnect := ADR(AlarmXListUIConnectType);
//	MpAlarmXListUI_0.UISetup := AlarmXListUISetupType;
//	MpAlarmXListUI_0();
	
	MpAlarmXCore_0.Enable := TRUE;
	MpAlarmXCore_0.MpLink := ADR(mpAlarmXCore);
	MpAlarmXCore_0();
	
	MpAlarmXHistory_0.MpLink := ADR(mpAlarmXHistory);
	MpAlarmXHistory_0.DeviceName := ADR('ALARM');
	MpAlarmXHistory_0();
	
				
END_PROGRAM

PROGRAM _EXIT
	MpAlarmXListUI_0(Enable:=FALSE);
	MpAlarmXCore_0(Enable := FALSE);
	MpAlarmXHistory_0(Enable:=FALSE);
END_PROGRAM