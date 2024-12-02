
ACTION resultsFATfileHandling: 

	
	CASE stateRecipe OF
		
		0:
		//	cm.description := 'wait for file devices to be ready';
			
			IF gFile.status.ready AND gConfig.status.loaded THEN
				this.MpRecipeRegPar_result.Enable := TRUE;
				stateRecipe := 10;
			END_IF
			
		10:	
	//		cm.description := 'wait for MpRecipeXml to be active';
			
			this.MpRecipeXml_0.Enable := TRUE;
			IF this.MpRecipeXml_0.Active THEN
				stateRecipe := 100;
			ELSIF this.MpRecipeXml_0.Error THEN
				stateRecipe := 9999;
			END_IF
			
		100:
		//	cm.description := 'wait for load or save command';
			
			IF this.MpRecipeXml_0.Load THEN
				stateRecipe := 200;
			ELSIF this.MpRecipeXml_0.Save THEN
				stateRecipe := 300;
			END_IF
			
			
		200:
		//	cm.description := 'wait for loading file';
			
			IF this.MpRecipeXml_0.CommandDone THEN
				// reset the load cmd
				this.MpRecipeXml_0.Load := FALSE;
				resultFATOld := resultFAT; // After load update old (no reason to save immediatly after)
				this.resultsFATLoaded := TRUE;
				stateRecipe := 100;
			ELSIF this.MpRecipeXml_0.Error THEN
				this.MpRecipeXml_0.Load := FALSE;
				CASE this.MpRecipeXml_0.StatusID OF

					-1064140798,-1064140791: // mpRECIPE_ERR_LOAD_DATA
						this.MpRecipeXml_0.ErrorReset := TRUE;
						stateRecipe := 210;
						
					ELSE
						stateRecipe := 9999;
				END_CASE
			END_IF

		210:
		//	cm.description := 'wait for NOT MpRecipeXml_0.Error';
			
			IF NOT this.MpRecipeXml_0.Error THEN
				this.MpRecipeXml_0.ErrorReset := FALSE;
				this.MpRecipeXml_0.Save := TRUE;
				stateRecipe := 300;
			END_IF
			
		300:
		//	cm.description := 'wait for saving file';
			
			IF this.MpRecipeXml_0.CommandDone THEN
				// reset the save cmd
				this.MpRecipeXml_0.Save := FALSE;
				this.resultsFATLoaded := TRUE; // If saved also say that we have loaded (first download when file is not there)
				stateRecipe := 100;
			ELSIF this.MpRecipeXml_0.Error THEN
				this.MpRecipeXml_0.Save := FALSE;
				stateRecipe := 9999;
			END_IF

		9999:
		//	cm.description := 'wait for error reset';
			
			IF NOT this.MpRecipeXml_0.Error THEN
				stateRecipe := 10;
			END_IF

	END_CASE
	
	this.MpRecipeXml_0.MpLink := ADR(mpResult);
	this.MpRecipeXml_0.DeviceName := ADR('RESULT');
	this.MpRecipeXml_0.FileName := ADR('result.xml');
	this.MpRecipeXml_0.Category := ADR('result');
	this.MpRecipeXml_0();

	// Check if resultsFAT has changed with a TON
	this.ton_chekForChanges(IN:=NOT this.MpRecipeXml_0.Save AND NOT this.MpRecipeXml_0.Load);
	
	IF this.ton_chekForChanges.Q THEN
		this.ton_chekForChanges(IN:=FALSE);
	
		IF brsmemcmp(ADR(resultFAT),ADR(resultFATOld),SIZEOF(resultFATOld)) <> 0 THEN
			this.MpRecipeXml_0.Save := TRUE;
		END_IF
		resultFATOld := resultFAT;
		
	END_IF
	this.MpRecipeRegPar_result(MpLink := ADR(mpResult), PVName := ADR(this.resultName), Category := ADR('result'));

	
END_ACTION
