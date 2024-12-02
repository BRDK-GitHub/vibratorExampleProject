
(*  *)
FUNCTION_BLOCK RemoteUpdate
	
	CASE state OF
		
		0:
			IF Enable AND IpEndpoint <> '' THEN
				state := 5;
			END_IF
		
		5:
			IF CheckVersion OR TON_0.Q THEN
				CheckVersion := FALSE;
				TON_0.IN := FALSE;
				VersionEWU := '';
				VersionLocal := '';
				state := 10;
			ELSIF PrepareUpdate THEN
				VersionEWU := '';
				VersionLocal := '';
				state := 10;
			ELSIF UpdateEWU THEN
				UpdateEWU := FALSE;
				UpdateReadyOnEWU := FALSE;
				state := 100;
			END_IF
			
			// Only using TON after an EWU update.
			TON_0();
		
		10:
			// Read EWU version using OPCUA
			EasyUaRead_0.Execute := TRUE;
			EasyUaRead_0.ServerEndpointUrl := 'opc.tcp://';
			EasyUaRead_0.ServerEndpointUrl := CONCAT(EasyUaRead_0.ServerEndpointUrl,IpEndpoint);
			EasyUaRead_0.ServerEndpointUrl := CONCAT(EasyUaRead_0.ServerEndpointUrl,':4840');
			EasyUaRead_0.NodeID.NamespaceIndex := 6;
			//EasyUaRead_0.NodeID.Identifier := '::flaps:hmi.version';
			EasyUaRead_0.NodeID.Identifier := '::updateEWU:brdkUpdateManager_0.running.version';
			EasyUaRead_0.NodeID.IdentifierType := UAIdentifierType_String;
			EasyUaRead_0.Variable := '::updateEWU:RemoteUpdate_0.VersionEWU';
			EasyUaRead_0();
		
			IF EasyUaRead_0.Done THEN
				EasyUaRead_0.Execute := FALSE;
				EasyUaRead_0();
				state := 20;
			ELSIF EasyUaRead_0.Error THEN
				EasyUaRead_0.Execute := FALSE;
				EasyUaRead_0();
				state := 20;
			END_IF
			
		20:
			brdkUpdateCheck_0.enable := TRUE;
			brdkUpdateCheck_0.pFileDevice := ADR('UPDATEEWU');
			brdkUpdateCheck_0();
			
			IF brdkUpdateCheck_0.status = ERR_OK THEN
				brdkUpdateCheck_0.enable := FALSE;
				brdkUpdateCheck_0();
				VersionLocal := brdkUpdateCheck_0.version;
				state := SEL(PrepareUpdate,30,40); // if PrepareUpdate go send - otherwise go back.
			ELSIF brdkUpdateCheck_0.status <> ERR_FUB_BUSY THEN
				brdkUpdateCheck_0.enable := FALSE;
				brdkUpdateCheck_0();
				state := SEL(PrepareUpdate,30,40); // if PrepareUpdate go send - otherwise go back.
			END_IF
			
			// On exit of state
			IF state <> 20 THEN
				PrepareUpdate := FALSE;
			END_IF
			
		
		30:
			IF NOT CheckVersion THEN
				state := 5;
			END_IF
		
		40:
			// Check if versions are different and no version empty.
			IF VersionLocal <> VersionEWU AND VersionLocal <> '' AND VersionEWU <> '' THEN
				UpdateReadyOnEWU := FALSE;
				state := 45;
			ELSE
				state := 5;
			END_IF
			
		45:
			// Wait for busy before waiting for ERR_OK (because of stupid design where ERR_OK=0 which it is from the start...)
			brdkUpdateDistributeFTP_0.enable := TRUE;
			brdkUpdateDistributeFTP_0.pFileDevice := ADR('UPDATEEWU');
			brdkUpdateDistributeFTP_0.client[0].pIPAddress := ADR(IpEndpoint);
			brdkUpdateDistributeFTP_0.client[0].pUser := ADR('update');
			brdkUpdateDistributeFTP_0.client[0].pPassword := ADR('update');
			brdkUpdateDistributeFTP_0.cmd.distributeUpdate := TRUE;
			brdkUpdateDistributeFTP_0();
			
			IF brdkUpdateDistributeFTP_0.status = ERR_FUB_BUSY THEN
				state := 50;
			END_IF
			
		50:
			brdkUpdateDistributeFTP_0.enable := TRUE;
			brdkUpdateDistributeFTP_0.pFileDevice := ADR('UPDATEEWU');
			brdkUpdateDistributeFTP_0.client[0].pIPAddress := ADR(IpEndpoint);
			brdkUpdateDistributeFTP_0.client[0].pUser := ADR('update');
			brdkUpdateDistributeFTP_0.client[0].pPassword := ADR('update');
			brdkUpdateDistributeFTP_0.cmd.distributeUpdate := TRUE;
			brdkUpdateDistributeFTP_0();
		
			IF brdkUpdateDistributeFTP_0.status = ERR_OK THEN
				brdkUpdateDistributeFTP_0.enable := FALSE;
				brdkUpdateDistributeFTP_0.cmd.distributeUpdate := FALSE;
				brdkUpdateDistributeFTP_0();
				UpdateReadyOnEWU := TRUE;
				state := 60;
			ELSIF brdkUpdateDistributeFTP_0.status <> ERR_FUB_BUSY THEN
				brdkUpdateDistributeFTP_0.enable := FALSE;
				brdkUpdateDistributeFTP_0.cmd.distributeUpdate := FALSE;
				brdkUpdateDistributeFTP_0();
				state := 60;
			END_IF
		
		60:
			state := 5;
		
		100:
			// Write to EWU that it should update.
			EasyUaWrite_0.Execute := TRUE;
			EasyUaWrite_0.ServerEndpointUrl := 'opc.tcp://';
			EasyUaWrite_0.ServerEndpointUrl := CONCAT(EasyUaWrite_0.ServerEndpointUrl,IpEndpoint);
			EasyUaWrite_0.ServerEndpointUrl := CONCAT(EasyUaWrite_0.ServerEndpointUrl,':4840');
			EasyUaWrite_0.NodeID.NamespaceIndex := 6;
			EasyUaWrite_0.NodeID.Identifier := '::updateEWU:hmi.update';
			EasyUaWrite_0.NodeID.IdentifierType := UAIdentifierType_String;
			EasyUaWrite_0.Variable := '::updateEWU:RemoteUpdate_0.boolTRUE';
			EasyUaWrite_0();
		
			IF EasyUaWrite_0.Done THEN
				EasyUaWrite_0.Execute := FALSE;
				EasyUaWrite_0();
				// Check version after 5min to see if it updated.
				TON_0.IN := TRUE;
				TON_0.PT := T#5m;
				state := 5;
			ELSIF EasyUaWrite_0.Error THEN
				EasyUaWrite_0.Execute := FALSE;
				EasyUaWrite_0();
				state := 5;
			END_IF
		
		
		
			
		
	END_CASE
	
END_FUNCTION_BLOCK