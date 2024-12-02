
PROGRAM _INIT
	cm.setup.name := 'transferConfigToT50';
	cm.setup.parent.name := 'main';
	cm.setup.lastActivated := FALSE;
END_PROGRAM

PROGRAM _CYCLIC
	
	CASE cm.state OF
		
		0:
	
			IF gFile.status.ready AND (gConfig.status.saved OR gConfig.status.loaded) THEN
				cm.state := 100;
			END_IF
		
		100:
			// Wait for cmd
			
			IF gMachineInterface.cmd.saveConfigToT50 THEN
				// will reset when succeded (otherwise use can enable while again while saving).
				this.internal.cifsParamFT50 := '/SIP=192.168.2.70 /PROTOCOL=cifs /SHARE=usershare /USER=pft50-user /PASSWORD=1234';
				gMachineInterface.status.configSavedToT50 := FALSE;
				this.hmi.status := 0; // not done
				this.hmi.cantConnectToFT50 := FALSE;
				cm.state := 110;
			END_IF
					
		110:
			// Create devLink to FT50
			
			this.internal.DevLink_0.enable := TRUE;
			this.internal.DevLink_0.pDevice := ADR('FT50');
			this.internal.DevLink_0.pParam := ADR(this.internal.cifsParamFT50);
			this.internal.DevLink_0();
			
			IF this.internal.DevLink_0.status = ERR_OK OR this.internal.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
				this.internal.handleDevlinkFT50 := this.internal.DevLink_0.handle;
				IF this.internal.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
					this.internal.devLinkFT50exists := TRUE;
				ELSE
					this.internal.devLinkFT50exists := FALSE;
				END_IF
				this.internal.DevLink_0(enable:=FALSE);
				
				this.internal.ftpParamPLC := '/SIP=192.168.2.11 /PROTOCOL=ftp /USER=superuser /PASSWORD=superuser';
				cm.state := 120;
			ELSIF this.internal.DevLink_0.status <> ERR_FUB_BUSY THEN
				cm.state := 9999;
			END_IF
			
		120:
			// Create DevLink to PLC
			
			this.internal.DevLink_0.enable := TRUE;
			this.internal.DevLink_0.pDevice := ADR('PLC');
			this.internal.DevLink_0.pParam := ADR(this.internal.ftpParamPLC);
			this.internal.DevLink_0();
			
			IF this.internal.DevLink_0.status = ERR_OK OR this.internal.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
				this.internal.handleDevlinkPLC := this.internal.DevLink_0.handle;
				IF this.internal.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
					this.internal.devLinkPLCexists := TRUE;
				ELSE
					this.internal.devLinkPLCexists := FALSE;
				END_IF
				this.internal.DevLink_0(enable:=FALSE);
				
				this.internal.fileNameSrc := 'F:\config\config.xml';
				this.internal.fileNameDest := 'config.xml';
				cm.state := 130;
			ELSIF this.internal.DevLink_0.status <> ERR_FUB_BUSY THEN
				cm.state := 9999;
			END_IF
			
		130:
			// FileCopy config from PLC to FT50 panel
			
			this.internal.FileCopy_0.enable := TRUE;
			this.internal.FileCopy_0.pSrcDev := ADR('PLC');
			this.internal.FileCopy_0.pSrc := ADR(this.internal.fileNameSrc);
			this.internal.FileCopy_0.pDestDev := ADR('FT50');
			this.internal.FileCopy_0.pDest := ADR(this.internal.fileNameDest);
			this.internal.FileCopy_0.option := fiOVERWRITE;
			this.internal.FileCopy_0();
			
			IF this.internal.FileCopy_0.status = ERR_OK THEN
				this.internal.FileCopy_0(enable:=FALSE);
				cm.state := 140;
			ELSIF this.internal.FileCopy_0.status <> ERR_FUB_BUSY THEN
				cm.state := 9999;
			END_IF
			
		140:
			// DevUnlink PLC only unlink if the link was created in this task.
			IF NOT this.internal.devLinkPLCexists THEN
				this.internal.DevUnlink_0.enable := TRUE;
				this.internal.DevUnlink_0.handle := this.internal.handleDevlinkPLC;
				this.internal.DevUnlink_0();
				
				IF this.internal.DevUnlink_0.status = ERR_OK THEN
					this.internal.handleDevlinkPLC := 0;
					this.internal.DevUnlink_0(enable:=FALSE);
					
					cm.state := 150;
				ELSIF this.internal.DevUnlink_0.status <> ERR_FUB_BUSY THEN
					cm.state := 9999;
				END_IF
			ELSE
				cm.state := 150;
			END_IF
		150:
			// DevUnlink FT50
			IF NOT this.internal.devLinkFT50exists THEN
				this.internal.DevUnlink_0.enable := TRUE;
				this.internal.DevUnlink_0.handle := this.internal.handleDevlinkFT50;
				this.internal.DevUnlink_0();
				
				IF this.internal.DevUnlink_0.status = ERR_OK THEN
					this.internal.handleDevlinkFT50 := 0;
					this.internal.DevUnlink_0(enable:=FALSE);
					
					gMachineInterface.cmd.saveConfigToT50 := FALSE;	 // reset cmd before returning to wait state 100
					gMachineInterface.status.configSavedToT50 := TRUE;
					this.hmi.status := 1; // success
					cm.state := 100;
				ELSIF this.internal.DevUnlink_0.status <> ERR_FUB_BUSY THEN
					cm.state := 9999;
				END_IF
			ELSE
				gMachineInterface.cmd.saveConfigToT50 := FALSE;	 // reset cmd before returning to wait state 100
				gMachineInterface.status.configSavedToT50 := TRUE;
				this.hmi.status := 1; // success
				cm.state := 100;
			END_IF
			
		9999:
			// ERROR
			this.hmi.status := 2;	// error
			this.hmi.cantConnectToFT50 := TRUE;
			
			gMachineInterface.cmd.saveConfigToT50 := FALSE;
			
			// Reset everything and go back to state 100
			this.internal.DevLink_0(enable:=FALSE);
			this.internal.DevUnlink_0(enable:=FALSE);
			this.internal.FileCopy_0(enable:=FALSE);
			cm.state := 0;
	
		
		
	END_CASE
	
	cm();
	 
END_PROGRAM

PROGRAM _EXIT
	this.internal.DevLink_0(enable:=FALSE);
	this.internal.DevUnlink_0(enable:=FALSE);
	this.internal.FileCopy_0(enable:=FALSE);
END_PROGRAM

