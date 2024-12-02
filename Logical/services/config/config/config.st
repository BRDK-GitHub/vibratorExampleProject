
PROGRAM _INIT

	cm.setup.name			:= 'config';
	cm.setup.parent.name 	:= 'main';
	gConfig.status.loaded 	:= FALSE;
	gConfig.status.saved 	:= FALSE;
	gConfig.cmd.load 		:= TRUE;

	ton_chekForChanges.PT 	:= t#3s;
END_PROGRAM

PROGRAM _CYCLIC
	
	ton_chekForChanges(IN:= NOT MpRecipeXml_0.Save);
	gConfig.status.doCheckForChanges := (NOT gConfig.status.loaded OR ton_chekForChanges.Q) AND MpRecipeXml_0.Active;

	IF ton_chekForChanges.Q THEN
		ton_chekForChanges(IN:= FALSE);
	END_IF
	
	
	CASE cm.state OF
		
		0:
			cm.description := 'wait for file devices to be ready';
			
			IF gFile.status.ready THEN
				cm.state := 5;
			END_IF
			
		5:
			cm.description := 'See if we have a config file on FTP';
			
			this.FileInfo_0.enable := TRUE;
			this.FileInfo_0.pDevice := ADR('CONFIG');
			this.FileInfo_0.pName := ADR('config.xml');
			this.FileInfo_0.pInfo := ADR(this.configPLCFileInfo);
			this.FileInfo_0();
			
			IF this.FileInfo_0.status = ERR_OK THEN
				// already have a config file -> go load it using mpRecipe.
				this.FileInfo_0(enable := FALSE);
				cm.state := 10;
			ELSIF this.FileInfo_0.status = fiERR_FILE_NOT_FOUND THEN 
				// No config file -> Go look if FT50 has one.
				this.FileInfo_0(enable := FALSE);
				this.cifsParamFT50 := '/SIP=192.168.2.70 /PROTOCOL=cifs /SHARE=usershare /USER=pft50-user /PASSWORD=1234';
				cm.state := 6;
			ELSIF this.FileInfo_0.status <> ERR_FUB_BUSY THEN
				this.FileInfo_0(enable := FALSE);
				cm.state := 9999;
			END_IF
			
		6:	
			cm.description := 'Create devLink to FT50 shared internal memory';
			
			this.devLinkFT50_0.enable := TRUE;
			this.devLinkFT50_0.pDevice := ADR('FT50');
			this.devLinkFT50_0.pParam := ADR(this.cifsParamFT50);
			this.devLinkFT50_0();
			
			IF this.devLinkFT50_0.status = ERR_OK OR this.devLinkFT50_0.status=fiERR_DEVICE_ALREADY_EXIST THEN
				this.devLinkFT50_0.enable := FALSE;
				cm.state := 7;
			ELSIF this.devLinkFT50_0.status <> ERR_FUB_BUSY THEN
				// Ideally, should never get here. It happens if shared memory is not set on FT50 panel service page.
				this.devLinkFT50_0.enable := FALSE;
				this.noConfigExist := TRUE;
				cm.state := 10;
			END_IF
			
			
		7:
			cm.description := 'See if we have a config file on FT50 panel';
			
			this.FileInfo_0.enable := TRUE;
			this.FileInfo_0.pDevice := ADR('FT50');
			this.FileInfo_0.pName := ADR('config.xml');
			this.FileInfo_0.pInfo := ADR(this.configFT50FileInfo);
			this.FileInfo_0();
			
			IF this.FileInfo_0.status = ERR_OK THEN
				// config exist on FT50 -> Go copy it to PLC
				this.FileInfo_0(enable := FALSE);
				cm.state := 9;
			ELSIF this.FileInfo_0.status = fiERR_FILE_NOT_FOUND THEN 
				// No config file on FT50 either -> Save a brand new one (this should in an ideal world never happen).
				this.FileInfo_0(enable := FALSE);
				this.noConfigExist := TRUE;
				cm.state := 10;
			ELSIF this.FileInfo_0.status <> ERR_FUB_BUSY THEN
				this.FileInfo_0(enable := FALSE);
				cm.state := 9999;
			END_IF
			
		9:
			cm.description := 'File copy config from FT50 to PLC';
			
			this.fileCopy_0.enable := TRUE;
			this.fileCopy_0.pSrcDev := ADR('FT50');
			this.fileCopy_0.pSrc := ADR('config.xml');
			this.fileCopy_0.pDestDev := ADR('CONFIG');
			this.fileCopy_0.pDest := ADR('config.xml');
			this.fileCopy_0();
			
			IF this.fileCopy_0.status = ERR_OK THEN
				this.fileCopy_0(enable := FALSE);
				gConfig.status.loadInitialValue[0] := gConfig.status.loadInitialValue[1] := gConfig.status.loadInitialValue[2] := gConfig.status.loadInitialValue[3] := gConfig.status.loadInitialValue[4] := TRUE; // signal to load initial recipe value.
				cm.state := 10;
			ELSIF this.fileCopy_0.status <> ERR_FUB_BUSY THEN
				cm.state := 9999;
			END_IF
			
		10:	
			cm.description := 'wait for MpRecipeXml to be active';
			
			MpRecipeXml_0.Enable := TRUE;
			IF MpRecipeXml_0.Active THEN
				IF this.noConfigExist THEN
					this.noConfigExist := FALSE;
					gConfig.cmd.load := FALSE;			 // Don't load if a config don't exist.
					gConfig.status.loaded := TRUE;		 // Will allow others tasks to trigger a .save cmd.
				END_IF
				cm.state := 100;
			ELSIF MpRecipeXml_0.Error THEN
				cm.state := 9999;
			END_IF
			
		100:
			cm.description := 'wait for load or save command';
			
			IF (gConfig.cmd.load OR gConfig.cmd.save) AND NOT MpRecipeXml_0.UpdateNotification AND NOT gMachineInterface.cmd.saveConfigToT50 THEN // Added "AND NOT gMachineInterface.cmd.saveConfigToT50" Because we can't save config while we are moving config from ftp server to T50 hmi.
				IF gFile.status.ready THEN
					MpRecipeXml_0.FileName := ADR('config.xml');
					IF gConfig.cmd.load THEN
						// Set the recipe interface
						gConfig.status.loaded 	:= FALSE;
						gConfig.cmd.load		:= FALSE;
						// call the load cmd
						MpRecipeXml_0.Load 		:= TRUE;
						cm.state 				:= 200;
					ELSE
						// Set the recipe interface
						gConfig.status.saved	:= FALSE;
						gConfig.cmd.save		:= FALSE;
						// call the save cmd
						MpRecipeXml_0.Save 		:= TRUE;
						cm.state 				:= 300;
					END_IF
				ELSE
					gConfig.cmd.load 	:= FALSE;
					gConfig.cmd.save 	:= FALSE;
					cm.state 			:= 0;
				END_IF
			ELSE
				MpRecipeXml_0.UpdateNotification := FALSE;
				// Signal from HMI to factory reset all configuration parameters:
				IF this.factoryReset THEN
					this.factoryReset := FALSE;
					// each bool represents [feeder,vibrator,belt,capcon,cassette/wing]
					gConfig.status.factoryReset[0] := gConfig.status.factoryReset[1] := gConfig.status.factoryReset[2] := gConfig.status.factoryReset[3] := gConfig.status.factoryReset[4] := TRUE;
				END_IF
			END_IF
			
		200:
			cm.description := 'wait for loading file';
			
			IF MpRecipeXml_0.CommandDone THEN
				// set the recipe interface
				gConfig.status.loaded := TRUE;
				// reset the load cmd
				MpRecipeXml_0.Load := FALSE;
				cm.state := 220;
			ELSIF MpRecipeXml_0.Error THEN
				MpRecipeXml_0.Load := FALSE;
				CASE MpRecipeXml_0.StatusID OF

					-1064140798,-1064140791: // mpRECIPE_ERR_LOAD_DATA
						MpRecipeXml_0.ErrorReset := TRUE;
						gConfig.status.loaded := TRUE;
						cm.state := 210;
						
					ELSE
						cm.state := 9999;
				END_CASE
			END_IF

		210:
			cm.description := 'wait for NOT MpRecipeXml_0.Error';
			
			IF NOT MpRecipeXml_0.Error THEN
				MpRecipeXml_0.ErrorReset := FALSE;
				MpRecipeXml_0.Save := TRUE;
				cm.state := 300;
			END_IF
		
		220:
			IF MpRecipeXml_0.CommandDone AND MpRecipeXml_0.UpdateNotification THEN
				MpRecipeXml_0.UpdateNotification := FALSE;	   
			ELSIF NOT MpRecipeXml_0.CommandDone THEN
				MpRecipeXml_0.UpdateNotification := TRUE;
				cm.state := 100;
			END_IF
			
		300:
			cm.description := 'wait for saving file';
			
			IF MpRecipeXml_0.CommandDone THEN
				// set the recipe interface
				gConfig.status.saved := TRUE;
				// reset the save cmd
				MpRecipeXml_0.Save := FALSE;
				// If just finished a linearization -> signal that we just saved config and that it can be moved to T50 panel now.
				IF gMachineInterface.cmd.requestSaveToT50 THEN
					gMachineInterface.cmd.requestSaveToT50 := FALSE;
					gMachineInterface.cmd.saveConfigToT50 := TRUE; // this signal will also block config from being saved while moving the file.
				END_IF
				cm.state := 220;
			ELSIF MpRecipeXml_0.Error THEN
				MpRecipeXml_0.Save := FALSE;
				cm.state := 9999;
			END_IF

		9999:
			cm.description := 'wait for error reset';
			
			IF NOT MpRecipeXml_0.Error THEN
				cm.state := 10;
			END_IF

	END_CASE
	
	cm();
	
	
	
	MpRecipeXml_0.MpLink := ADR(mpConfig);
	MpRecipeXml_0.DeviceName := ADR('CONFIG');
	MpRecipeXml_0.Category := ADR('config'); 
	MpRecipeXml_0();
	
	 
END_PROGRAM

PROGRAM _EXIT
	
	MpRecipeXml_0(Enable := FALSE);
	this.FileInfo_0(enable := FALSE);
	this.fileCopy_0(enable := FALSE);
	this.devLinkFT50_0(enable := FALSE);

END_PROGRAM

