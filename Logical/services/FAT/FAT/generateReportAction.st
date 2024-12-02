
ACTION generateReportAction: 

	CASE reportState OF
		
		0:
		//	'Wait for user to input cmd';
			this.MpReportCore_0.Enable := FALSE;
			
			IF this.hmi.cmd.createReports THEN
				this.hmi.cmd.createReports := FALSE;
				this.hmi.status.reportCreationOK := FALSE;
				resultFAT.FATdone := FALSE;
				
				gMachineInterface.cmd.saveConfigToT50 := TRUE;
				//Generate data from user input:
				this.hmi.dateString := ''; 
				brdkStrCat(ADR(this.hmi.dateString),ADR('D#'));
				this.hmi.yearIdx := 2020+this.hmi.yearIdx;	// 0 means 2020
				this.tmpString := UINT_TO_STRING(this.hmi.yearIdx);
				brdkStrCat(ADR(this.hmi.dateString),ADR(this.tmpString));
				brdkStrCat(ADR(this.hmi.dateString),ADR('-'));
				
				this.hmi.monthIdx := 1+this.hmi.monthIdx;	//0 means 1 (january)
				IF this.hmi.monthIdx < 10 THEN
					this.tmpString := '0';
					brdkStrCat(ADR(this.hmi.dateString),ADR(this.tmpString));
				END_IF
				this.tmpString := UINT_TO_STRING(this.hmi.monthIdx);
				brdkStrCat(ADR(this.hmi.dateString),ADR(this.tmpString));
				brdkStrCat(ADR(this.hmi.dateString),ADR('-'));
				
				this.hmi.dayIdx := 1+this.hmi.dayIdx; 		// 0 means day 1
				IF this.hmi.dayIdx < 10 THEN
					this.tmpString := '0';
					brdkStrCat(ADR(this.hmi.dateString),ADR(this.tmpString));
				END_IF
				this.tmpString := UINT_TO_STRING(this.hmi.dayIdx);
				brdkStrCat(ADR(this.hmi.dateString),ADR(this.tmpString));
				this.hmi.date := STRING_TO_DATE(this.hmi.dateString);
				
				// gReport cmd will we reset in hwReadout task
				this.MpReportCore_0.Enable := TRUE;
				
				this.ftpParamPLC := '/SIP=192.168.2.11 /PROTOCOL=ftp /USER=superuser /PASSWORD=superuser';
				reportState := 10;
			END_IF
		
		10:
			// 'Create devlink to PLC';
			
			this.devLinkPLC_0.enable := TRUE;
			this.devLinkPLC_0.pDevice := ADR('PLC');
			this.devLinkPLC_0.pParam := ADR(this.ftpParamPLC);
			this.devLinkPLC_0();
			
			IF this.devLinkPLC_0.status=0 OR this.devLinkPLC_0.status=fiERR_DEVICE_ALREADY_EXIST THEN	// devLink created successfully or it's already created.
				this.devLinkPLC_0.enable := FALSE;
				this.devLinkPLC_0();
				// Go to state where we move images from PLC to IMAGES file device. 
				this.fileNameSrc := 'C:\ADDONS\DATA\IAT_Data\wwwRoot\BRVisu\Media\Images\leftMachine.jpg';
				this.fileNameDest := 'leftMachine.jpg';
				reportState := 20;
			END_IF
		
		20:
			this.fileCopy_0.enable := TRUE;
			this.fileCopy_0.pSrcDev := ADR('PLC');
			this.fileCopy_0.pSrc := ADR(this.fileNameSrc);
			this.fileCopy_0.pDestDev := ADR('IMAGES');
			this.fileCopy_0.pDest := ADR(this.fileNameDest);
			this.fileCopy_0.option := fiOVERWRITE;
			this.fileCopy_0();
			
			IF this.fileCopy_0.status = ERR_OK THEN
				this.fileCopy_0(enable := FALSE);
				this.fileNameSrc := 'C:\ADDONS\DATA\IAT_Data\wwwRoot\BRVisu\Media\Images\rightMachine.jpg';
				this.fileNameDest := 'rightMachine.jpg';
				reportState := 30;
			END_IF
		
		30:
			this.fileCopy_0.enable := TRUE;
			this.fileCopy_0.pSrcDev := ADR('PLC');
			this.fileCopy_0.pSrc := ADR(this.fileNameSrc);
			this.fileCopy_0.pDestDev := ADR('IMAGES');
			this.fileCopy_0.pDest := ADR(this.fileNameDest);
			this.fileCopy_0.option := fiOVERWRITE;
			this.fileCopy_0();
			
			IF this.fileCopy_0.status = ERR_OK THEN
				this.fileCopy_0(enable := FALSE);
				reportState := 40; // Done moving pics
			END_IF	
		
		40:
			IF this.MpReportCore_0.Active THEN
				reportState := 50;
			END_IF	
		
		50:
			this.MpReportCore_0.Name := ADR('CM20Protocol');
			this.MpReportCore_0.Generate := TRUE;
			
			IF this.MpReportCore_0.CommandDone THEN
				this.MpReportCore_0.Generate := FALSE;
				reportState := 60;
			ELSIF this.MpReportCore_0.Error THEN
				this.MpReportCore_0.Generate := FALSE;
				reportState := 9999;
			END_IF
			
		60:
			// 'Generate checklist';
			
			this.MpReportCore_0.Name := ADR('CM20Checklist');
			this.MpReportCore_0.Generate := TRUE;
			
			IF this.MpReportCore_0.CommandDone THEN
				this.MpReportCore_0.Generate := FALSE;
				this.hmi.status.reportCreationOK := TRUE;
				// Reports generated. Trigger a factory reset to be sure parameters are optimal.
				gConfig.status.factoryReset[0] := gConfig.status.factoryReset[1] := gConfig.status.factoryReset[2] := gConfig.status.factoryReset[3] := gConfig.status.factoryReset[4] := TRUE;
				reportState := 0;
			ELSIF this.MpReportCore_0.Error THEN
				this.MpReportCore_0.Generate := FALSE;
				reportState := 9999;
			END_IF
		
		9999:
			// 'Error';
			this.hmi.status.reportCreationOK := FALSE;
			
			IF NOT this.MpReportCore_0.Error THEN
				reportState := 0;
			END_IF
		
		
		
		
	END_CASE
	
	this.MpReportCore_0.MpLink := ADR(mpReport);
	this.MpReportCore_0.Language := ADR('en');
	this.MpReportCore_0.DeviceName := ADR('REPORT');
	this.MpReportCore_0();
	
END_ACTION
