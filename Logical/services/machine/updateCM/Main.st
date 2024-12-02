
PROGRAM _INIT
	cm.setup.name := 'updateCM';
	cm.setup.parent.name := 'main';
	//this.hmi.updateTemplates := TRUE; // always update available templates on a boot.
	isBoot := TRUE;
	templateDropdownSelectedIdx;
END_PROGRAM

PROGRAM _CYCLIC
	
	CASE cm.state OF
		
		0:
			IF gFile.status.ready THEN
				brdkUpdateManager_0.enable 		:= TRUE;
				cm.state := 5;
			END_IF
			
		5:
			// Create devLink to FT50
			
			this.internal.DevLink_0.enable := TRUE;
			this.internal.DevLink_0.pDevice := ADR('PLC');
			this.internal.DevLink_0.pParam := ADR('/SIP=192.168.2.11 /PROTOCOL=ftp /USER=admin /PASSWORD=admin');
			this.internal.DevLink_0();
			
			IF this.internal.DevLink_0.status = ERR_OK OR this.internal.DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
				this.internal.handleDevLink := this.internal.DevLink_0.handle;
				this.internal.DevLink_0(enable:=FALSE);
				cm.state := 7;
			ELSIF this.internal.DevLink_0.status <> ERR_FUB_BUSY THEN
				cm.state := 9999;
			END_IF
		
		7:
			cm.description := 'Delete update folder if it exists';
			
			this.internal.DirDeleteEx_0.enable := TRUE;
			this.internal.DirDeleteEx_0.pDevice := ADR('PLC');
			this.internal.DirDeleteEx_0.pName := ADR('F:\Default_X20CP04xx');
			this.internal.DirDeleteEx_0();
			
			IF this.internal.DirDeleteEx_0.status = ERR_OK OR this.internal.DirDeleteEx_0.status = fiERR_DIR_NOT_EXIST THEN
				this.internal.DirDeleteEx_0(enable:=FALSE);
				cm.state := 8;
			ELSIF this.internal.DirDeleteEx_0.status <> ERR_FUB_BUSY THEN
				this.internal.DirDeleteEx_0(enable:=FALSE);
				cm.state := 9999;
			END_IF
			
		8:
			cm.description := 'Delete update .xml file if it exists';
			
			this.internal.FileDelete_0.enable := TRUE;
			this.internal.FileDelete_0.pDevice := ADR('PLC');
			this.internal.FileDelete_0.pName := ADR('F:\arnbcfg.xml');
			this.internal.FileDelete_0();
			
			IF this.internal.FileDelete_0.status = ERR_OK OR this.internal.FileDelete_0.status = fiERR_FILE_NOT_FOUND THEN
				this.internal.FileDelete_0(enable:=FALSE);
				cm.state := 9;
			ELSIF this.internal.FileDelete_0.status <> ERR_FUB_BUSY THEN
				this.internal.FileDelete_0(enable:=FALSE);
				cm.state := 9999;
			END_IF
			
		9: 
			cm.description := 'Disconnect PLC devlink';
			
			this.internal.DevUnlink_0.enable := TRUE;
			this.internal.DevUnlink_0.handle := this.internal.handleDevLink;
			this.internal.DevUnlink_0();
			
			IF this.internal.DevUnlink_0.status = ERR_OK THEN
				this.internal.DevUnlink_0(enable:=FALSE);
				cm.state := 10;
			ELSIF this.internal.DevUnlink_0.status <> ERR_FUB_BUSY THEN
				this.internal.DevUnlink_0(enable:=FALSE);
				cm.state := 9999;
			END_IF
			
		10:
			IF brdkUpdateManager_0.running.version <> '' THEN
				// go check if any update package on update partition
				brdkUpdateManager_0.cmd.checkForUpdate := TRUE;
				cm.state := 20;	// wait state for command.
			END_IF
			
		20:
			
			IF brdkUpdateManager_0.status = ERR_OK THEN
				this.status.readyForUpdate := TRUE;
				IF (brdkStrCmp(ADR(brdkUpdateManager_0.update.version),ADR(brdkUpdateManager_0.running.version)) = 0) THEN		// if update version is equal to the running version -> delete package.
					brdkUpdateManager_0.cmd.deleteUpdate := TRUE;
					cm.state := 30; 
				ELSE
					// Update package is not equal -> just continue
					cm.state := 100;
				END_IF
			ELSIF brdkUpdateManager_0.status = fiERR_FILE_NOT_FOUND THEN // no file.
				// no file. Error reset and continue to wait state 100.
				brdkUpdateManager_0.cmd.errorReset := TRUE;
				cm.state := 40;
			END_IF
			
		30:
			IF brdkUpdateManager_0.status = ERR_OK THEN
				// Update package deleted
				this.cmd.writeUpdateInstalledToGateway := TRUE;
				cm.state := 900; // Write to gateway that software just got updated using opcua.
			END_IF
		
		40:
			
			IF brdkUpdateManager_0.status = ERR_OK THEN
				// ready
				cm.state := 100;
			END_IF
		
		100: // Wait state. React on commands
		
			IF this.cmd.updateCurrentPackage THEN // cmd from gateway to update from software package.
				this.cmd.updateCurrentPackage := FALSE;
				// reset timer
				TON_0.IN := FALSE;
				TON_0.PT := T#4s;
				TON_0();
				cm.state := 110;
			ELSIF this.cmd.checkForUpdate AND gMachineInterface.parameter.actualServerIP <> '' THEN
				TON_0.IN := FALSE;
				TON_0.PT := T#6s;
				TON_0();
				cm.state := 118; // will check for a new update AND . 
			ELSIF this.cmd.checkForUpdateInstantly THEN
				this.cmd.checkForUpdateInstantly := FALSE;
				brdkUpdateManager_0.cmd.checkForUpdate := TRUE;
				cm.state := 130;
			ELSIF this.hmi.updateTemplates AND gMachineInterface.parameter.actualServerIP <> '' THEN
				IF isBoot THEN
					isBoot := FALSE;
					cm.state := 900;
				ELSE
					cm.state := 1000;
				END_IF
			ELSIF this.cmd.loadRecipeTemplateFromGateway AND gMachineInterface.parameter.actualServerIP <> '' THEN
				
				templateDropdownSelectedIdx;
				IF templateDropdownSelectedIdx <= MAX_TEMPLATES_IDX THEN
					startSearchStr := 'text';
					endSearchStr := '"';
					// Take out the fileName from the dataProvider using substring search.
					brdkStrSubStrSearch(ADR(this.hmi.strRecipeTemplate),
					ADR(this.hmi.templateDataProvider[templateDropdownSelectedIdx]),
					ADR(startSearchStr),ADR(endSearchStr),3,TRUE);
					cm.state := 1000;
				ELSE
					// Error will result in out of bounds.
					this.cmd.loadRecipeTemplateFromGateway := FALSE;
				END_IF
				
			ELSIF this.cmd.saveRecipeTemplateFromGateway AND gMachineInterface.parameter.actualServerIP <> '' THEN
				IF this.hmi.strRecipeTemplateSaveName <> '' THEN
					cm.state := 1000;
				ELSE
					this.cmd.saveRecipeTemplateFromGateway := FALSE;
				END_IF
			ELSIF this.hmi.automatic.save THEN
				
				IF gMachineInterface.parameter.actualServerIP <> '' THEN
					this.hmi.strRecipeAutoSaveName := UDINT_TO_STRING(gCapconInterface.status.numBricksInPortion);
					IF gVibratorInterface[0].status.machineType = 0 THEN
						tmpString := 'S';
					ELSE // bif cf
						tmpString := 'L';
					END_IF
					brdkStrCat(ADR(this.hmi.strRecipeAutoSaveName),ADR(tmpString));
					tmpString := DINT_TO_STRING(gMainInterface.status.itemTypeId);
					brdkStrCat(ADR(this.hmi.strRecipeAutoSaveName),ADR(tmpString));
					IF gMainInterface.status.itemTypeId <> 0 AND gCapconInterface.status.numBricksInPortion <> 0 THEN
						cm.state := 1000;
					ELSE
						this.hmi.automatic.save := FALSE;
					END_IF
				ELSE
					this.hmi.automatic.save := FALSE;
				END_IF
			ELSIF this.hmi.automatic.overwrite THEN
				this.hmi.automatic.save := TRUE; // Save like normal. We will tell that it is overwrite further down in the opcua client code.
			ELSIF this.hmi.automatic.load THEN
				IF gMachineInterface.parameter.actualServerIP <> '' THEN
					this.hmi.strRecipeAutoLoadName := UDINT_TO_STRING(gCapconInterface.status.numBricksInPortion);
					IF gVibratorInterface[0].status.machineType = 0 THEN
						tmpString := 'S';
					ELSE // bif cf
						tmpString := 'L';
					END_IF
					brdkStrCat(ADR(this.hmi.strRecipeAutoLoadName),ADR(tmpString));
					tmpString := DINT_TO_STRING(gMainInterface.status.itemTypeId);
					brdkStrCat(ADR(this.hmi.strRecipeAutoLoadName),ADR(tmpString));
					IF gCapconInterface.status.numBricksInPortion <> 0 THEN
						cm.state := 1000;
					ELSE
						this.hmi.automatic.load := FALSE;
					END_IF
				ELSE
					this.hmi.automatic.load := FALSE;
				END_IF
			ELSIF this.hmi.updateAllCMs THEN
				IF gMachineInterface.parameter.actualServerIP <> '' THEN
					cm.state := 1000;
				ELSE
					this.hmi.updateAllCMs := FALSE;
				END_IF
			END_IF
		
		110:
			// Wait 4sec to be 100% sure that gateway has disconnectet OPCUA CLIENT before rebooting the machine.
			
			TON_0.IN := TRUE;
			TON_0();
			IF TON_0.Q THEN
				TON_0(IN:=FALSE);
				brdkUpdateManager_0.cmd.updateReboot := TRUE; // update from software package on FTP server.
				cm.state := 112;
			END_IF	
			
		112:
			
			IF brdkUpdateManager_0.status = ERR_OK THEN
				cm.state := 100;
			ELSIF brdkUpdateManager_0.status <> ERR_FUB_BUSY THEN
				// error reset 
				brdkUpdateManager_0.cmd.errorReset := TRUE;
				cm.state := 113;
			END_IF
			
		113:
			// Wait for reset of error
			IF brdkUpdateManager_0.status = ERR_OK THEN
				cm.state := 100;
			END_IF
			
		(* ------------------------------------------------------------ *)	
		(* 				OPCUA. WRITE UPDATE FILESIZE to GATEWAY         *)
		(* ------------------------------------------------------------ *)
		
		118:
			// wait 6s to make sure FTP is done.
			TON_0.IN := TRUE;
			TON_0();
			IF TON_0.Q THEN
				TON_0(IN:=FALSE);
				brdkUpdateManager_0.cmd.checkForUpdate := TRUE;
				cm.state := 120;
			END_IF
			
		120:
			IF brdkUpdateManager_0.status = ERR_OK THEN
				IF brdkUpdateManager_0.update.artransferFileSize > 0 THEN
					// Write file size to gateway
					cm.state := 1000;
				ELSE
					// return? No file size (should never happen)
					this.cmd.checkForUpdate := FALSE;
					cm.state := 100;
				END_IF
			ELSIF brdkUpdateManager_0.status = fiERR_FILE_NOT_FOUND THEN // no file.
				// no file. Error reset and continue to wait state 100.
				brdkUpdateManager_0.cmd.errorReset := TRUE;
				cm.state := 121;
			END_IF	
			
		121: // no update file just return
			
			IF brdkUpdateManager_0.status = ERR_OK THEN
				this.cmd.checkForUpdate := FALSE;
				cm.state := 100;
			END_IF
			
		130:
			IF brdkUpdateManager_0.status = ERR_OK THEN
				cm.state := 100;
			ELSIF brdkUpdateManager_0.status = fiERR_FILE_NOT_FOUND THEN // no file.
				// no file. Error reset and continue to wait state 100.
				brdkUpdateManager_0.cmd.errorReset := TRUE;
				cm.state := 131;
			END_IF	
			
		131:
			IF brdkUpdateManager_0.status = ERR_OK THEN
				this.cmd.checkForUpdateInstantly := FALSE;
				cm.state := 100;
			END_IF
			
			
		(* ------------------------------------------------------------ *)	
		(* OPCUA. WRITE TO GATEWAY THAT NEW SOFTWARE HAS BEEN INSTALLED *)
		(* ------------------------------------------------------------ *)	
			
		900:
			// Wait 7s to be sure that machine got IP from DHCP . (if not it's OK, we will call IP FB untill we get one)
			TON_0.IN := cm.state=900;
			TON_0.PT := T#7s;
			
			IF TON_0.Q AND gMachineInterface.parameter.actualServerIP <> '' THEN
				TON_0.IN := FALSE;
				cm.state := 1000;
			END_IF
			TON_0();
			
		1000: (* UA_Connect - establish connection to OPC UA Server *)
			
			this.opcua.UASessionConnectInfo_0.SecurityMsgMode 								:= UASecurityMsgMode_None;
			this.opcua.UASessionConnectInfo_0.SecurityPolicy 								:= UASecurityPolicy_None;
			this.opcua.UASessionConnectInfo_0.TransportProfile 								:= UATP_UATcp;
			this.opcua.UASessionConnectInfo_0.SessionTimeout 								:= T#1m;
			this.opcua.UASessionConnectInfo_0.MonitorConnection 							:= T#10s;
			this.opcua.UASessionConnectInfo_0.UserIdentityToken.UserIdentityTokenType 		:= UAUITT_Anonymous;
				
			this.opcua.UA_Connect_0.Execute 			:= TRUE;
			tmpString := gMachineInterface.parameter.actualServerIP;
			brdkStrSlice(ADR(tmpString),0,2);
			IF tmpString = '10' THEN 
				// test endpoint in odense
				this.opcua.UA_Connect_0.ServerEndpointUrl 	:= 'opc.tcp://10.45.10.199:4840';
			ELSE
				// production endpoint
				this.opcua.UA_Connect_0.ServerEndpointUrl 	:= 'opc.tcp://192.168.1.199:4840';
			END_IF
			this.opcua.UA_Connect_0.SessionConnectInfo 	:= this.opcua.UASessionConnectInfo_0;
			this.opcua.UA_Connect_0.Timeout 				:= T#30s;
				
			IF this.opcua.UA_Connect_0.Done THEN
				this.opcua.connectionHdl 		:= this.opcua.UA_Connect_0.ConnectionHdl;
				this.opcua.UA_Connect_0.Execute 	:= FALSE;
				cm.state 				:= 1020;
			ELSIF this.opcua.UA_Connect_0.Error THEN
				this.opcua.errorID 				:= this.opcua.UA_Connect_0.ErrorID;
				this.opcua.UA_Connect_0.Execute 	:= FALSE;
				this.opcua.errorRecoverState := cm.state;
				// return to 100 adn reset all cmds - no gateway
				this.cmd.checkForUpdate := FALSE;
				this.cmd.updateCurrentPackage := FALSE;
				this.hmi.updateTemplates := FALSE;
				this.cmd.loadRecipeTemplateFromGateway := FALSE;
				cm.state 				:= 100;
			END_IF
			
		1020: (* UA_GetNamespaceIndex - read index of required namespace for PVs *)
            
			this.opcua.UA_GetNamespaceIndex_0.Execute 		:= TRUE;
			this.opcua.UA_GetNamespaceIndex_0.ConnectionHdl	:= this.opcua.connectionHdl;
			this.opcua.UA_GetNamespaceIndex_0.NamespaceUri 	:= 'http://br-automation.com/OpcUa/PLC/PV/';
			this.opcua.UA_GetNamespaceIndex_0.Timeout 		:= this.opcua.UA_Connect_0.Timeout; // same timeout
				
			IF this.opcua.UA_GetNamespaceIndex_0.Done THEN
				this.opcua.namespaceIndex 					:= this.opcua.UA_GetNamespaceIndex_0.NamespaceIndex;
				this.opcua.UA_GetNamespaceIndex_0.Execute 	:= FALSE;
				cm.state 							:= 1040;
			ELSIF this.opcua.UA_GetNamespaceIndex_0.Error THEN
				this.opcua.errorID								:= this.opcua.UA_GetNamespaceIndex_0.ErrorID;
				this.opcua.UA_GetNamespaceIndex_0.Execute 	:= FALSE;
				this.opcua.errorRecoverState := cm.state;
				cm.state 							:= 3000;
			END_IF
		
		1040: // wait state
			
			IF this.cmd.writeUpdateInstalledToGateway THEN
				
				this.CfgGetIPAddr_0.pDevice := ADR('SS1.IF1.ETH'); //IF2 is local / SS1.IF1.ETH is server commu card.
				this.CfgGetIPAddr_0.pIPAddr := ADR(this.opcua.actualLocalIpAddress);
				this.CfgGetIPAddr_0.Len 	:= SIZEOF(this.opcua.actualLocalIpAddress);
						
				this.CfgGetIPAddr_0(enable := TRUE);
						
				IF this.CfgGetIPAddr_0.status = ERR_OK THEN
					this.CfgGetIPAddr_0(enable := FALSE);
					IF this.opcua.actualLocalIpAddress <> '' THEN // String can't be empty
						this.cmd.writeUpdateInstalledToGateway := FALSE;
						cm.state := 1059;
					END_IF
				ELSIF this.CfgGetIPAddr_0.status <> ERR_FUB_BUSY THEN
					this.CfgGetIPAddr_0(enable:=FALSE); // try again -> dhcp get IP from DHCP yet.
				END_IF	
			ELSIF this.cmd.checkForUpdate THEN
				cm.state := 1059;
			ELSIF this.cmd.loadRecipeTemplateFromGateway OR this.hmi.automatic.load THEN
				this.CfgGetIPAddr_0.pDevice := ADR('SS1.IF1.ETH'); //IF2 is local / SS1.IF1.ETH is server commu card.
				this.CfgGetIPAddr_0.pIPAddr := ADR(this.opcua.actualLocalIpAddress);
				this.CfgGetIPAddr_0.Len 	:= SIZEOF(this.opcua.actualLocalIpAddress);
						
				this.CfgGetIPAddr_0(enable := TRUE);
						
				IF this.CfgGetIPAddr_0.status = ERR_OK THEN
					this.CfgGetIPAddr_0(enable := FALSE);
					IF this.opcua.actualLocalIpAddress <> '' THEN // String can't be empty
						this.cmd.writeUpdateInstalledToGateway := FALSE;
						cm.state := 1057;
					END_IF
				ELSIF this.CfgGetIPAddr_0.status <> ERR_FUB_BUSY THEN
					this.CfgGetIPAddr_0(enable:=FALSE); // try again -> dhcp get IP from DHCP yet.
				END_IF	
			ELSIF this.hmi.updateTemplates THEN
				
				
				cm.state := 1056;
				
			ELSIF this.cmd.saveRecipeTemplateFromGateway OR this.hmi.automatic.save THEN
				this.cmd.saveRecipeTemplateFromGateway := FALSE;
				cm.state := 1058;
			ELSIF this.hmi.updateAllCMs THEN
				cm.state := 1061;
			ELSIF this.cmd.disconnect THEN
				this.cmd.disconnect := FALSE;
				cm.state := 1100;
			END_IF
		
		1056:
			// prepare bulk before write.
			FOR i:=0 TO MAX_UA_VARIABLES DO
				this.opcua.nodeIDWrite[i].NamespaceIndex := this.opcua.namespaceIndex;
				this.opcua.nodeIDWrite[i].IdentifierType := UAIdentifierType_String;
			END_FOR
			
			// Node1: "write to gateway that we want to update"
			this.opcua.nodeIDWrite[0].Identifier := '::CM20:templateNames';
			this.opcua.variablesWrite[0] := '::updateCM:templateNames';
			
			this.opcua.UaClt_ReadBulk_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UaClt_ReadBulk_0.NodeIDCount := 1;
			this.opcua.UaClt_ReadBulk_0.NodeAddInfo := 0;
			this.opcua.UaClt_ReadBulk_0.TimeStamps := 0;
			this.opcua.UaClt_ReadBulk_0.Timeout := this.opcua.UA_Connect_0.Timeout;
			this.opcua.UaClt_ReadBulk_0.Execute := FALSE;
				
			cm.state := 1070; // go read bulk
			
		1057:
			// prepare bulk before write.
			FOR i:=0 TO MAX_UA_VARIABLES DO
				this.opcua.nodeIDWrite[i].NamespaceIndex := this.opcua.namespaceIndex;
				this.opcua.nodeIDWrite[i].IdentifierType := UAIdentifierType_String;
			END_FOR
			writeBool := TRUE;
			findIndexInGatewayArray;
			IF this.hmi.automatic.load THEN
				
				writeUSINT := 5;
				// Node2: String to specify fileName of the recipe template.
				this.hmi.strRecipeAutoLoadName;
				this.opcua.nodeIDWrite[1].Identifier := '::CM20:recipeTemplateNameStr[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[1] := '::updateCM:this.hmi.strRecipeAutoLoadName';
			ELSE
				writeUSINT := UDINT_TO_USINT(this.hmi.selectedTemplateType);
				// Node2: String to specify fileName of the recipe template.
				this.hmi.strRecipeTemplate;
				this.opcua.nodeIDWrite[1].Identifier := '::CM20:recipeTemplateNameStr[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[1] := '::updateCM:this.hmi.strRecipeTemplate';
			END_IF
			
			
			// Node1: cmd to load the recipe
			this.opcua.nodeIDWrite[0].Identifier := '::CM20:writeRecipeTemplate[';
			tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
			brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
			tmpString := ']';
			brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
			this.opcua.variablesWrite[0] := '::updateCM:writeBool';
			
			
			
			// Node3: usint to specify which type of recipe we are using (1pcs,2pcs,3pcs,4pcs, BIG CM or automatic)
			this.opcua.nodeIDWrite[2].Identifier := '::recipeLoad:dirRecipeTemplateType';
			this.opcua.variablesWrite[2] := '::updateCM:writeUSINT';
			
			this.opcua.UaClt_WriteBulk_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UaClt_WriteBulk_0.NodeIDCount := 3; // write 2 var
			this.opcua.UaClt_WriteBulk_0.NodeAddInfo := 0;
			this.opcua.UaClt_WriteBulk_0.Timeout := this.opcua.UA_Connect_0.Timeout;
			this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
				
			cm.state := 1060;
			
		1058:
			
			// prepare bulk before write.
			FOR i:=0 TO MAX_UA_VARIABLES DO
				this.opcua.nodeIDWrite[i].NamespaceIndex := this.opcua.namespaceIndex;
				this.opcua.nodeIDWrite[i].IdentifierType := UAIdentifierType_String;
			END_FOR
			
			writeBool := TRUE;
			findIndexInGatewayArray;
			IF this.hmi.automatic.save THEN
				this.hmi.automatic.save := FALSE;
				writeUSINT := 5; // 5 means we should save to automatic folder.
				// Node2: String to specify fileName of the recipe template.
				this.opcua.nodeIDWrite[1].Identifier := '::CM20:recipeTemplateNameStr[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[1] := '::updateCM:this.hmi.strRecipeAutoSaveName';
			ELSE
				writeUSINT := UDINT_TO_USINT(this.hmi.selectedTemplateType);
				// Node2: String to specify fileName of the recipe template.
				this.opcua.nodeIDWrite[1].Identifier := '::CM20:recipeTemplateNameStr[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[1].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[1] := '::updateCM:this.hmi.strRecipeTemplateSaveName';
			END_IF
			
			
			// Node1: cmd to save the recipe
			this.opcua.nodeIDWrite[0].Identifier := '::CM20:saveRecipeTemplate[';
			tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
			brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
			tmpString := ']';
			brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
			this.opcua.variablesWrite[0] := '::updateCM:writeBool';
			
			IF NOT this.hmi.automatic.overwrite THEN
				// Node3: usint to specify which type of recipe we are using (1pcs,2pcs,3pcs,4pcs or BIG CM)
				this.opcua.nodeIDWrite[2].Identifier := '::recipeLoad:dirRecipeTemplateType';
				this.opcua.variablesWrite[2] := '::updateCM:writeUSINT';
			ELSE
				// Node3: Tell that it is overwrite (we already know recipeTemplateType - no reason to write again.
				this.hmi.automatic.overwrite := FALSE;
				this.opcua.nodeIDWrite[2].Identifier := '::CM20:overwriteRecipe[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[2].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[2].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[2] := '::updateCM:writeBool';
			END_IF
			
			this.opcua.UaClt_WriteBulk_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UaClt_WriteBulk_0.NodeIDCount := 3; // write 3 var
			this.opcua.UaClt_WriteBulk_0.NodeAddInfo := 0;
			this.opcua.UaClt_WriteBulk_0.Timeout := this.opcua.UA_Connect_0.Timeout;
			this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
			
			cm.state := 1060; // go write.
			
		1059:
			writeBool := TRUE;	// Always true.
			// prepare bulk
			this.opcua.nodeIDWrite[0].NamespaceIndex := this.opcua.namespaceIndex;
			this.opcua.nodeIDWrite[0].IdentifierType := UAIdentifierType_String;
			// ::cm20Recipe:newSoftwareInstalled[0]
			IF NOT this.cmd.checkForUpdate THEN
				 // Write that we are updated
				findIndexInGatewayArray;
				this.opcua.nodeIDWrite[0].Identifier := '::CM20:newSoftwareInstalled[';
				tmpString := USINT_TO_STRING(this.opcua.indexInGatewayIpArray);
				brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
				tmpString := ']';
				brdkStrCat(ADR(this.opcua.nodeIDWrite[0].Identifier),ADR(tmpString));
				this.opcua.variablesWrite[0] := '::updateCM:writeBool';
			ELSE 	// Write update file size to gateway
				this.opcua.nodeIDWrite[0].Identifier := '::AsGlobalPV:gUpdateFileSize';
				this.opcua.variablesWrite[0] := '::updateCM:brdkUpdateManager_0.update.artransferFileSize';
			END_IF
				
			this.opcua.UaClt_WriteBulk_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UaClt_WriteBulk_0.NodeIDCount := 1; // write 1 var
			this.opcua.UaClt_WriteBulk_0.NodeAddInfo := 0;
			this.opcua.UaClt_WriteBulk_0.Timeout := this.opcua.UA_Connect_0.Timeout;
			this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
				
			cm.state := 1060;
			
		1061:
			writeBool := TRUE;	// Always true.
			// prepare bulk
			this.opcua.nodeIDWrite[0].NamespaceIndex := this.opcua.namespaceIndex;
			this.opcua.nodeIDWrite[0].IdentifierType := UAIdentifierType_String;
		
			// Write to gateway that it should update all online machines.
			findIndexInGatewayArray;
			this.opcua.nodeIDWrite[0].Identifier := '::updateSoft:updateAllOnlineCMs';
			this.opcua.variablesWrite[0] := '::updateCM:writeBool';
		
				
			this.opcua.UaClt_WriteBulk_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UaClt_WriteBulk_0.NodeIDCount := 1; // write 1 var
			this.opcua.UaClt_WriteBulk_0.NodeAddInfo := 0;
			this.opcua.UaClt_WriteBulk_0.Timeout := this.opcua.UA_Connect_0.Timeout;
			this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
				
			cm.state := 1060;
			
		1060:	
			
			this.opcua.UaClt_WriteBulk_0.Execute 			:= TRUE;
			this.opcua.UaClt_WriteBulk_0.Variables 			:= ADR(this.opcua.variablesWrite);
			this.opcua.UaClt_WriteBulk_0.NodeErrorIDs 		:= ADR(this.opcua.nodeErrorID);
			this.opcua.UaClt_WriteBulk_0.NodeIDs 			:= ADR(this.opcua.nodeIDWrite);
			IF NOT this.opcua.UaClt_WriteBulk_0.Error THEN
				IF this.opcua.UaClt_WriteBulk_0.Done THEN
					this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
					this.cmd.checkForUpdate 				:= FALSE; 	// reset
					this.hmi.updateAllCMs := FALSE;
					IF this.cmd.loadRecipeTemplateFromGateway OR this.hmi.automatic.load THEN
						this.hmi.automatic.load := FALSE;
						this.cmd.loadRecipeTemplateFromGateway 	:= FALSE;	// reset
						gMainInterface.cmd.loadingTemplateRecipe := TRUE;
					END_IF
					this.cmd.disconnect 					:= TRUE;	// Disconnect client. We are done writing.
					cm.state								:= 1040;
				END_IF
			ELSE // error
				this.opcua.errorID := this.opcua.UaClt_WriteBulk_0.ErrorID;
				this.cmd.checkForUpdate 	 	  	 := FALSE; 	// reset
				this.cmd.loadRecipeTemplateFromGateway 	:= FALSE;	// reset
				this.opcua.UaClt_WriteBulk_0.Execute := FALSE;
				this.opcua.errorRecoverState := cm.state;
				cm.state					 := 3000;
			END_IF
			
		1070: (* Read bulk *)
			this.opcua.UaClt_ReadBulk_0.Execute := TRUE;
			this.opcua.UaClt_ReadBulk_0.NodeIDs := ADR(this.opcua.nodeIDWrite);
			this.opcua.UaClt_ReadBulk_0.Variables := ADR(this.opcua.variablesWrite);
			this.opcua.UaClt_ReadBulk_0.NodeErrorIDs := ADR(this.opcua.nodeErrorID);
	
			IF NOT this.opcua.UaClt_ReadBulk_0.Error THEN
				IF this.opcua.UaClt_ReadBulk_0.Done THEN
					this.hmi.updateTemplates := FALSE;
					this.opcua.UaClt_ReadBulk_0.Execute := FALSE;
					this.cmd.disconnect := TRUE;
					
					IF templateNames[this.hmi.selectedTemplateType].strArr[0] <> '' THEN
						// if a template exist.
						count := 0;
						brdkStrMemSet(ADR(this.hmi.templateDataProvider),0,SIZEOF(this.hmi.templateDataProvider));
						FOR k:=0 TO MAX_TEMPLATES_IDX DO
							IF templateNames[this.hmi.selectedTemplateType].strArr[k] <> '' THEN
								
								this.hmi.templateDataProvider[count] := '{"value":"';
								tmpString := USINT_TO_STRING(count);
								brdkStrCat(ADR(this.hmi.templateDataProvider[count]),ADR(tmpString));
								tmpString := '", "text":"';
								brdkStrCat(ADR(this.hmi.templateDataProvider[count]),ADR(tmpString));
								tmpString := templateNames[this.hmi.selectedTemplateType].strArr[k];
								brdkStrCat(ADR(this.hmi.templateDataProvider[count]),ADR(tmpString));
								tmpString := '"}';
								brdkStrCat(ADR(this.hmi.templateDataProvider[count]),ADR(tmpString));
								
								count := count + 1;
							
							ELSE
								EXIT; // exit no more templates on gateway
							END_IF
						END_FOR
					END_IF
					
					cm.state := 1040;
				END_IF
			ELSE // error
				this.opcua.errorID := this.opcua.UaClt_ReadBulk_0.ErrorID;
				this.hmi.updateTemplates := FALSE;
				this.opcua.UaClt_ReadBulk_0.Execute := FALSE;
				this.opcua.errorRecoverState := cm.state;
				cm.state					 := 3000;
			END_IF
		
		1100: (* Disconnect opcua client *)
			this.opcua.UA_Disconnect_0.Execute := TRUE;
			this.opcua.UA_Disconnect_0.ConnectionHdl := this.opcua.connectionHdl;
			this.opcua.UA_Disconnect_0.Timeout := this.opcua.UA_Connect_0.Timeout;
				
			IF this.opcua.UA_Disconnect_0.Done THEN
				this.opcua.connectionHdl := 0;
				this.opcua.UA_Disconnect_0(Execute := FALSE); // This 1 time call it because we will stop calling FBs when state is changed to 100.
				this.cmd.disconnect := FALSE;
				TON_0(IN:=FALSE);
				cm.state := 100; // Go back to 100 and be ready for an update.
			ELSIF this.opcua.UA_Disconnect_0.Error THEN
				this.opcua.errorID := this.opcua.UA_Disconnect_0.ErrorID;
				this.opcua.UA_Disconnect_0.Execute := FALSE;
				this.opcua.errorRecoverState := cm.state;
				cm.state := 3000;
			END_IF
			
		2000:	// save recipe on gateway
		
		
		
		3000: (* Error *)
				
			this.opcua.timerConnectionErrorTimeout.IN := FALSE;
			this.opcua.timerConnectionErrorTimeout.PT := T#3s;
			this.opcua.timerConnectionErrorTimeout(); // make sure timer is reset.
			cm.state := 4000;
				
			
		4000: (* UA_ConnectionGetStatus - get server status *)
				
			this.opcua.timerConnectionErrorTimeout.IN := TRUE;
				
			// Call UA_connectionGetStatus FB every 3sec
			this.opcua.UA_ConnectionGetStatus_0.Execute 			:= this.opcua.timerConnectionErrorTimeout.Q; // If 3s passed start to call FB.
			this.opcua.UA_ConnectionGetStatus_0.ConnectionHdl 		:= this.opcua.connectionHdl;
			this.opcua.UA_ConnectionGetStatus_0.Timeout 			:= this.opcua.UA_Connect_0.Timeout;
				
				
			IF this.opcua.UA_ConnectionGetStatus_0.Done THEN
					
				IF this.opcua.UA_ConnectionGetStatus_0.ConnectionStatus=UACS_Connected AND this.opcua.UA_ConnectionGetStatus_0.ServerState = UASS_Running THEN
					// Return the state it was coming from
					this.opcua.timerConnectionErrorTimeout.IN := FALSE;
					cm.state := this.opcua.errorRecoverState; // return to the state - server is up again.
				END_IF
					
				// reset FB and timer
				this.opcua.UA_ConnectionGetStatus_0.Execute := FALSE;
				this.opcua.timerConnectionErrorTimeout.IN := FALSE;
					
			ELSIF this.opcua.UA_ConnectionGetStatus_0.Error THEN
				// 16#A0080000 "PlcOpen_BadConnectionInvalidHdl" -> Happens if losing connection while calling UA_Disconnect. I've chosen to not react on this
				this.opcua.timerConnectionErrorTimeout.IN := FALSE;
				this.opcua.UA_ConnectionGetStatus_0.Execute := FALSE;
			END_IF
			this.opcua.timerConnectionErrorTimeout();
			
		
	END_CASE

	IF cm.state > 999 THEN
		this.opcua.UA_Connect_0();
		this.opcua.UA_GetNamespaceIndex_0();
		this.opcua.UaClt_WriteBulk_0();
		this.opcua.UaClt_ReadBulk_0();
		this.opcua.UA_ConnectionGetStatus_0();
		this.opcua.UA_Disconnect_0();
		
		// Timeout in case we can't write to gateway.
		TON_1.IN := TRUE;
		TON_1.PT := T#2m;
		IF TON_1.Q THEN
			TON_1.IN := FALSE;
			
			this.opcua.UA_Connect_0(Execute:=FALSE);
			this.opcua.UA_GetNamespaceIndex_0(Execute:=FALSE);
			this.opcua.UaClt_WriteBulk_0(Execute:=FALSE);
			this.opcua.UaClt_ReadBulk_0(Execute:=FALSE);
			this.opcua.UA_ConnectionGetStatus_0(Execute:=FALSE);
			this.opcua.UA_Disconnect_0(Execute:=FALSE);
			this.cmd.writeUpdateInstalledToGateway := FALSE;
			
			IF this.opcua.connectionHdl <> 0 THEN
				cm.state := 1100;
			ELSE
				// no connectionHdl just return to 0.
				cm.state := 100;
			END_IF
		END_IF
		
		TON_1();
	ELSE
		TON_1(IN:=FALSE);
	END_IF
	
	cm();
	IF gFile.status.ready THEN
		brdkUpdateManager_0.pFileDevice := ADR('UPDATE');
		brdkUpdateManager_0();
	END_IF
	
	
	
	
END_PROGRAM

PROGRAM _EXIT
	brdkUpdateManager_0(enable:=FALSE);
	this.CfgGetIPAddr_0(enable:=FALSE);
END_PROGRAM

