
PROGRAM _INIT

	cm.setup.name			:= 'file';
	cm.setup.parent.name 	:= 'main';
	gFile.status.ready 		:= FALSE;
	gFile.cmd.update 		:= FALSE;

	// add file device used for the data logging
	brdkFileDeviceHandler_0.setup.fileDevices[0].name := 'CONFIG';
	brdkFileDeviceHandler_0.setup.fileDevices[0].path := 'config';
	brdkFileDeviceHandler_0.setup.fileDevices[1].name := 'RECIPES';
	brdkFileDeviceHandler_0.setup.fileDevices[1].path := 'recipes';
	brdkFileDeviceHandler_0.setup.fileDevices[2].name := 'DATA';
	brdkFileDeviceHandler_0.setup.fileDevices[2].path := 'data';
	brdkFileDeviceHandler_0.setup.fileDevices[3].name := 'IMAGES';
	brdkFileDeviceHandler_0.setup.fileDevices[3].path := 'images';
	brdkFileDeviceHandler_0.setup.fileDevices[4].name := 'ALARM';
	brdkFileDeviceHandler_0.setup.fileDevices[4].path := 'alarm';
	brdkFileDeviceHandler_0.setup.fileDevices[5].name := 'REPORT';
	brdkFileDeviceHandler_0.setup.fileDevices[5].path := 'report';
	brdkFileDeviceHandler_0.setup.fileDevices[6].name := 'UPDATE';
	brdkFileDeviceHandler_0.setup.fileDevices[6].path := 'update';
	brdkFileDeviceHandler_0.setup.fileDevices[7].name := 'UPDATEEWU';
	brdkFileDeviceHandler_0.setup.fileDevices[7].path := 'updateewu';
	brdkFileDeviceHandler_0.setup.fileDevices[8].name := 'RESULT';
	brdkFileDeviceHandler_0.setup.fileDevices[8].path := 'result';
	
	// file devices are automatically created on a USB drive whenever it is inserted.
	brdkFileDeviceHandler_0.setup.usbOverrule := FALSE;
	
	//brdkFileDeviceHandler_0.simulation.pcUSBDrive		:= E_DRIVE;
	IF gMainInterface.status.simulation THEN
		brdkFileDeviceHandler_0.setup.plcDrive := C_DRIVE; 
	ELSE
		brdkFileDeviceHandler_0.setup.plcDrive := F_DRIVE;
	END_IF
	
END_PROGRAM

PROGRAM _CYCLIC
	
	CASE cm.state OF
		
		0:
			cm.description := 'wait for brdkFileDeviceHandler to be done detecting file devices';
			
			brdkFileDeviceHandler_0.enable 	:= TRUE;
			gFile.status.ready := FALSE;
			IF brdkFileDeviceHandler_0.ready THEN
				cm.state := 100;
			ELSIF brdkFileDeviceHandler_0.status <> 0 THEN
				cm.state := 9999;
			END_IF

		100:
			cm.description := 'wait for commands';
			
			gFile.status.ready := TRUE;
			
			IF gFile.cmd.update THEN
				gFile.status.ready := FALSE;
				gFile.cmd.update := FALSE;
				brdkFileDeviceHandler_0.enable := FALSE;
				cm.state := 110;
			END_IF	
			
		110:
			cm.description := 'wait for brdkFileDeviceHandler to be disabled';
			
			IF NOT brdkFileDeviceHandler_0.ready THEN
				cm.state := 0;
			END_IF
			
		9999:
			cm.description := 'wait for error reset';
			
			IF brdkFileDeviceHandler_0.status = 0 THEN
				cm.state := 0;
			END_IF
			
	END_CASE
	 
	cm();
	brdkFileDeviceHandler_0();
		
END_PROGRAM

PROGRAM _EXIT

	brdkFileDeviceHandler_0(enable := FALSE);
	 
END_PROGRAM

