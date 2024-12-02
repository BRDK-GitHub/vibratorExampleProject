PROGRAM _INIT
	cm.setup.name := 'machine';
	cm.setup.parent.name := 'main';
	
	this.CfgSetIPAddr_0.Option  := cfgOPTION_NON_VOLATILE;
	//this.hmi.setNtpClient := TRUE;
	
	ST_name(0,ADR(this.configName),0);
	brdkStrCat(ADR(this.configName),ADR(':this.hmi.config'));
	
	this.hmi.config.dhcpEnabled := TRUE;
	
	this.TON_updateIp.PT := T#30s;
	
//	this.forceOutputsFB[0].dpName  := '%QX.IF6.ST6.DigitalOutput01'; //main:this.hw.do_stopButtonIndicator
//	this.forceOutputsFB[1].dpName  := '%QX.IF6.ST6.DigitalOutput02'; //main:this.hw.do_startButtonIndicator
	this.forceOutputsFB[2].dpName  := '%QX.IF6.ST2.DigitalOutput02'; //main:this.hw.do_alarmBeacon
	//this.forceOutputsFB[3].dpName  := '%QX.IF6.ST13.DigitalOutput01'; //feeder:this.hw.do_beltForwards
	//this.forceOutputsFB[4].dpName  := '%QX.IF6.ST13.DigitalOutput02'; //feeder:this.hw.do_beltBackwards
	this.forceOutputsFB[5].dpName  := '%QX.IF6.ST2.DigitalOutput01'; //feeder:this.hw.do_levelSensorInBowlLow
	this.forceOutputsFB[6].dpName  := '%QX.IF6.ST2.DigitalOutput03'; //feeder:this.hw.do_levelSensorInBowlMedium
	this.forceOutputsFB[7].dpName  := '%QX.IF6.ST2.DigitalOutput05'; //feeder:this.hw.do_levelSensorInBowlHigh
	
	this.forceOutputsFB[8].dpName  := '%QX.IF6.ST7.DigitalOutput01'; //upperFlap:this.hw.do_open
	this.forceOutputsFB[9].dpName  := '%QX.IF6.ST7.DigitalOutput03'; //middleFlap:this.hw.do_open
	this.forceOutputsFB[10].dpName := '%QX.IF6.ST8.DigitalOutput01'; //bottomFlap:this.hw.do_open
	this.forceOutputsFB[11].dpName := '%QX.IF6.ST8.DigitalOutput03'; //bottomFlap:this.hw.do_neighbourOpen
	this.forceOutputsFB[12].dpName := '%QX.IF6.ST7.DigitalOutput04'; //cassette:this.hw.do_dosing
	this.forceOutputsFB[13].dpName := '%QX.IF6.ST8.DigitalOutput05'; //cassette:this.hw.do_cassetteRelease
	this.forceOutputsFB[14].dpName := '%QX.IF6.ST7.DigitalOutput07'; //cassette:this.hw.do_bricksReadyInCassette
	this.forceOutputsFB[15].dpName := '%QX.IF6.ST7.DigitalOutput10'; //external:this.hw.do_itemsDelivered
	
//	this.forceOutputsFB[16].dpName := '%QX.IF6.ST10.DigitalOutput02'; //feeder:this.hw.do_flapOpen
//	this.forceOutputsFB[17].dpName := '%QX.IF6.ST10.DigitalOutput01'; //feeder:this.hw.do_flapClose
//	this.forceOutputsFB[18].dpName := '%QX.IF6.ST10.DigitalOutput04'; //feeder:this.hw.do_flapClose
//	this.forceOutputsFB[19].dpName := '%QX.IF6.ST10.DigitalOutput03'; //feeder:this.hw.do_flapOpen
	
	this.forceOutputsFB[20].dpName := '%QX.IF6.ST11.ClearError01'; //belt:this.hw.pwm.clearError
	this.forceOutputsFB[21].dpName := '%QW.IF6.ST11.PulseWidthCurrentPWM01'; //belt:this.hw.pwm.pulseWidth
	hgInfo;
	this.DTGetTime_0.enable := TRUE;
	
	FOR i:=0 TO MAX_FORCE_OUTPUTS DO
		this.forceOutputsFB[i].setValue := 1;
	END_FOR
	
	this.hmi.version := hgInfo.version;

	gMainInterface.status.statusIT.Version := CONCAT('CM20 ',this.hmi.version);
	
END_PROGRAM

PROGRAM _CYCLIC
	IF cm.status.parent.state = STATE_STOPPED THEN
		IF this.forceOutputsFB[16].enable AND this.forceOutputsFB[17].enable THEN	// We can't open all 4 transistors in H-bridge. This will cause a short circuit.
			// if user try to force both - disable both.
			this.forceOutputsFB[16].enable := FALSE;	//feeder flap open
			this.forceOutputsFB[17].enable := FALSE;	//feeder flap close
		END_IF
		this.forceOutputsFB[19].enable := this.forceOutputsFB[16].enable;
		this.forceOutputsFB[18].enable := this.forceOutputsFB[17].enable;
		
		FOR i:=0 TO MAX_FORCE_OUTPUTS DO
			this.forceOutputsFB[i]();
		END_FOR	
	ELSE // Machine not stopped
		FOR i:=0 TO MAX_FORCE_OUTPUTS DO
			this.forceOutputsFB[i].enable := FALSE;
			this.forceOutputsFB[i]();
		END_FOR	
	END_IF
	
	CASE cm.state OF
		
		0:

			IF NOT gMainInterface.status.simulation  THEN
				IF gFile.status.ready AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded)  THEN
					gConfig.status.loadInitialValue[4] := FALSE;
					this.hmi.config.dhcpEnabled := TRUE; // Machines always have DHCP on servercommunication card. 
					cm.state := 10;
				END_IF
			ELSE
				this.hmi.actualLocalIpAddress := this.hmi.config.setLocalIpAddress := '127.0.0.1';
				this.hmi.actualServerIpAddress := this.hmi.config.setServerIpAddress := '127.0.0.2';
			END_IF 	
			
		10:
			cm.description := 'get local IP address';
			
			this.CfgGetIPAddr_0.pDevice := ADR('IF2');
			this.CfgGetIPAddr_0.pIPAddr := ADR(this.hmi.actualLocalIpAddress);
			this.CfgGetIPAddr_0.Len 	:= SIZEOF(this.hmi.actualLocalIpAddress);
			
			this.CfgGetIPAddr_0(enable := TRUE);
			
			IF this.CfgGetIPAddr_0.status = ERR_OK THEN
				this.CfgGetIPAddr_0(enable := FALSE);
				this.hmi.actualLocalIpAddress;
				IF brdkStrLen(ADR(this.hmi.config.setLocalIpAddress)) < 7 THEN
					brsstrcpy(ADR(this.hmi.config.setLocalIpAddress),ADR(this.hmi.actualLocalIpAddress));
				END_IF
				cm.state :=  20;
			ELSIF this.CfgGetIPAddr_0.status <> ERR_FUB_BUSY THEN
				recoverState := cm.state;
				cm.state := 9999;
			END_IF

		20:			
			cm.description := 'get server IP address';
			
			this.CfgGetIPAddr_0.pDevice := ADR('SS1.IF1.ETH');
			this.CfgGetIPAddr_0.pIPAddr := ADR(this.hmi.actualServerIpAddress);
			this.CfgGetIPAddr_0.Len 	:= SIZEOF(this.hmi.actualServerIpAddress);
			
			this.CfgGetIPAddr_0(enable := TRUE);
			
			IF this.CfgGetIPAddr_0.status = ERR_OK THEN
				this.CfgGetIPAddr_0(enable := FALSE);
				this.hmi.actualServerIpAddress;
				gMachineInterface.parameter.actualServerIP := this.hmi.actualServerIpAddress;
				IF brdkStrLen(ADR(this.hmi.config.setServerIpAddress)) < 7 THEN
					brsstrcpy(ADR(this.hmi.config.setServerIpAddress),ADR(this.hmi.actualServerIpAddress));
				END_IF
				cm.state := 30;
			ELSIF this.CfgGetIPAddr_0.status <> ERR_FUB_BUSY THEN
				recoverState := cm.state;
				cm.state := 9999;
			END_IF
		
		30:
			cm.description := 'get gateway';
			
			this.CfgGetDefaultGateway_0.pDevice := ADR('IF2');
			this.CfgGetDefaultGateway_0.pGateway := ADR(this.hmi.actualGatewayAddress);
			this.CfgGetDefaultGateway_0.Len 	:= SIZEOF(this.hmi.actualGatewayAddress);
			
			this.CfgGetDefaultGateway_0(enable := TRUE);
			
			IF this.CfgGetDefaultGateway_0.status = ERR_OK THEN
				this.CfgGetDefaultGateway_0(enable := FALSE);
				this.hmi.actualGatewayAddress;
				IF brdkStrLen(ADR(this.hmi.config.setGatewayAddress)) < 7 THEN
					brsstrcpy(ADR(this.hmi.config.setGatewayAddress),ADR(this.hmi.actualGatewayAddress));
				END_IF
				
				cm.state := 100; // DONT DO NTP RIGHT NOW IN PROD
			ELSIF this.CfgGetDefaultGateway_0.status <> ERR_FUB_BUSY THEN
				recoverState := cm.state;
				cm.state := 9999;
			END_IF
			
		40:
			cm.description := 'Set time to something wrong to ensure that NTP Client sync with the server';
			
			this.DTSetTime_0.enable := TRUE;
			this.DTSetTime_0.DT1 := DT#1996-06-23-03:15:00;
			this.DTSetTime_0();
			
			IF this.DTSetTime_0.status = ERR_OK THEN
				this.DTSetTime_0.enable := FALSE;
				this.DTSetTime_0();
				
				cm.state := 50;
			ELSIF this.DTSetTime_0.status <> ERR_FUB_BUSY THEN
				recoverState := cm.state;
				cm.state := 9999;
			END_IF
			
			
		50:
			cm.description := 'Set ntp server client';
			
			this.CfgSetNtpClient_0.enable := TRUE;
			this.CfgSetNtpClient_0.start := TRUE;
			this.CfgSetNtpClient_0.pServerAddress1 := ADR(ntpServerIpAddress);
			this.CfgSetNtpClient_0.option := cfgOPTION_VOLATILE;
			this.CfgSetNtpClient_0();
			
			IF this.CfgSetNtpClient_0.status = ERR_OK THEN
				this.CfgSetNtpClient_0(enable := FALSE);
				cm.state := 100;
			ELSIF this.CfgSetNtpClient_0.status <> ERR_FUB_BUSY THEN
				//error
				recoverState := cm.state;
				cm.state := 9999;
			END_IF
			

		100:
			cm.description := 'Read IP if it didnt suceed to read doing boot';
			
			this.TON_updateIp.IN := this.hmi.actualServerIpAddress = '';
	
			IF this.TON_updateIp.Q THEN			// IF ip or gateway is not set go read untill DHCP has set it.
				this.TON_updateIp.IN := FALSE;
				cm.state := 110; // Go read server IP.
			END_IF
			this.TON_updateIp();
			
		110:
			cm.description := 'Get ip received from DHCP network and set it on HMI';
			
			this.CfgGetIPAddr_0.pDevice := ADR('SS1.IF1.ETH');
			this.CfgGetIPAddr_0.pIPAddr := ADR(this.hmi.actualServerIpAddress);
			this.CfgGetIPAddr_0.Len 	:= SIZEOF(this.hmi.actualServerIpAddress);
			
			this.CfgGetIPAddr_0(enable := TRUE);
			
			IF this.CfgGetIPAddr_0.status = ERR_OK THEN
				this.CfgGetIPAddr_0(enable := FALSE);
				this.hmi.actualServerIpAddress;
				cm.state := 100;
			ELSIF this.CfgGetIPAddr_0.status <> ERR_FUB_BUSY THEN
				recoverState := cm.state;
				cm.state := 9999;
			END_IF
			
			
			// ERROR
		
		9999:
			cm.description := 'Wait 5min and go to the state where an error happend';
			
			this.TON_updateIp.IN := TRUE;
			this.TON_updateIp.PT := T#5m;
			this.TON_updateIp();
			
			IF this.TON_updateIp.Q THEN
				this.TON_updateIp.IN := FALSE;
				this.TON_updateIp();
				
				this.errorActive := FALSE;
				this.CfgGetIPAddr_0(enable := FALSE);
				this.CfgSetIPAddr_0(enable := FALSE);
				this.CfgSetDefaultGateway_0(enable := FALSE);
				this.CfgSetEthConfigMode_0(enable := FALSE);
				this.CfgSetSubnetMask_0(enable := FALSE);
				this.CfgSetNtpClient_0(enable := FALSE);
				this.CfgGetEthConfigMode_0(enable := FALSE);
				this.DTGetTime_0(enable := FALSE);
				this.DTSetTime_0(enable := FALSE);
				cm.state := recoverState;
			END_IF

	END_CASE
	
	gMachineInterface.status.imageServerURL := this.hmi.config.imageServerURL;
	legoSTRItemString_Password();
	
	cm();
	
	// IF user suceed to login the password wil be saved for 5min and then cleared
	IF EDGEPOS(this.hmi.loginTriggered) THEN
		TON_login.IN := FALSE;
		TON_login();
		TON_login.IN := TRUE;
		TON_login.PT := T#5m;
		this.hmi.loginTriggered := FALSE;
	END_IF
	
	TON_login();
	IF TON_login.Q THEN
		TON_login.IN := FALSE;
		TON_login();
			
		legoSTRItemString_Password.value := 30; // 30 means "clear"
		legoSTRItemString_Password.trigger := TRUE;
	END_IF
	
	IF this.hmi.confirmReboot THEN
		//this.hmi.confirmReboot := FALSE;
		this.warmRestartWU	:= TRUE;
		TON_0.IN := TRUE;
		TON_0.PT := T#1s;
		TON_0();
		
		// set warmrestart cmd to WU20
		
		IF TON_0.Q THEN
			TON_0(IN:=FALSE);
			SYSreset(TRUE,1); // 1, warm restart
		END_IF
	END_IF
	
	IF gConfig.status.doCheckForChanges AND NOT this.oldCheckChangesConfig THEN
		this.MpRecipeRegPar_Config.Enable := TRUE;
		// chek if it has been loade then update old
		IF gMachineInterface.cmd.serialNoDINT > 0 THEN
			this.hmi.config.serialNumber := gMachineInterface.cmd.serialNoDINT;
		END_IF
		gMainInterface.status.statusIT.SerialNo := DINT_TO_UDINT(this.hmi.config.serialNumber); // serialNo status to IT.
	
		IF gConfig.status.loaded AND NOT this.oldLoaded THEN
			// Initial program load. Set old=new to avoid saving just after a load (makes no sense)
			this.configOld := this.hmi.config;
		END_IF
		this.oldLoaded := gConfig.status.loaded;
		
		IF NOT gConfig.cmd.save AND gConfig.status.loaded AND (brsmemcmp(ADR(this.hmi.config),ADR(this.configOld),SIZEOF(this.configOld)) <> 0) THEN
			gConfig.cmd.save := TRUE;
			this.configOld := this.hmi.config;
		END_IF
		
	END_IF
	this.MpRecipeRegPar_Config(MpLink := ADR(mpRecipe), PVName := ADR(this.configName), Category := ADR('config'));
	this.oldCheckChangesConfig := gConfig.status.doCheckForChanges;
	
	// Get PLC time.
	this.DTGetTime_0();
	
	// Some services dont work if we are not in prod. This bool can be used for some of these services to "hardcode" their functionality (example LEGO image server -> we will hardcode som image)
	gMachineInterface.status.machineNotInProduction := this.hmi.config.machineNotInProduction;
	
END_PROGRAM

PROGRAM _EXIT
	this.CfgGetIPAddr_0(enable := FALSE);
	this.CfgSetIPAddr_0(enable := FALSE);
	this.CfgSetDefaultGateway_0(enable := FALSE);
	this.CfgSetEthConfigMode_0(enable := FALSE);
	this.CfgSetSubnetMask_0(enable := FALSE);
	this.CfgSetNtpClient_0(enable := FALSE);
	this.CfgGetEthConfigMode_0(enable := FALSE);
	this.DTGetTime_0(enable := FALSE);
	this.MpRecipeRegPar_Config(Enable:=FALSE);
	this.DTGetTime_0(enable := FALSE);
	this.DTSetTime_0(enable := FALSE);
	
	FOR i:=0 TO MAX_FORCE_OUTPUTS DO
		this.forceOutputsFB[i](enable := FALSE);
	END_FOR
END_PROGRAM

