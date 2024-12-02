
PROGRAM _INIT

	cm.setup.name			:= 'recipe';
	cm.setup.parent.name 	:= 'main';
	gRecipe.status.loaded 	:= FALSE;
	gRecipe.status.saved 	:= FALSE;
	
	gRecipe.cmd.load		:= TRUE;

	ton_chekForChanges.PT 	:= t#3s;
END_PROGRAM

PROGRAM _CYCLIC
	
	ton_chekForChanges(IN:= NOT MpRecipeXml_0.Save);
	gRecipe.status.doCheckForChanges := NOT gRecipe.status.loaded OR ton_chekForChanges.Q;

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
			cm.description := 'Dont try to load on boot if no recipe file exists';
			
			FileInfo_0.enable := TRUE;
			FileInfo_0.pDevice := ADR('RECIPES');
			FileInfo_0.pName := ADR('working.xml');
			FileInfo_0.pInfo := ADR(recipePLCFileInfo);
			FileInfo_0();
			
			IF FileInfo_0.status = ERR_OK THEN
				// already have a recipe file -> go load it using mpRecipe.
				FileInfo_0(enable := FALSE);
				cm.state := 10;
			ELSIF FileInfo_0.status <> ERR_FUB_BUSY THEN
				FileInfo_0(enable := FALSE);
				// No recipe file exist. Don't trigger a load cmd, but save instead.
				gRecipe.cmd.load := FALSE;
				gRecipe.cmd.save := TRUE;
				gConfig.status.loadInitialValue[0] := gConfig.status.loadInitialValue[1] := gConfig.status.loadInitialValue[2] := gConfig.status.loadInitialValue[3] := gConfig.status.loadInitialValue[4] := TRUE; // signal to load initial recipe value.
				
				cm.state := 10;
			END_IF
			
		10:	
			cm.description := 'wait for MpRecipeXml to be active';
			
			MpRecipeXml_0.Enable := TRUE;
			IF MpRecipeXml_0.Active THEN
				cm.state := 100;
			ELSIF MpRecipeXml_0.Error THEN
				cm.state := 9999;
			END_IF
			
		100:
			cm.description := 'wait for load or save command';
			IF (gRecipe.cmd.load OR gRecipe.cmd.save) AND NOT MpRecipeXml_0.UpdateNotification THEN
				IF gFile.status.ready THEN
					gRecipe.status.newRecipeLoaded := gRecipe.cmd.load;
					MpRecipeXml_0.FileName := ADR('working.xml');
					IF gRecipe.cmd.load THEN
						// Set the recipe interface
						gRecipe.status.loaded 	:= FALSE;
						gRecipe.cmd.load		:= FALSE;
						// call the load cmd
						MpRecipeXml_0.Load 		:= TRUE;
						cm.state 				:= 200;
					ELSE
						// Set the recipe interface
						gRecipe.status.saved	:= FALSE;
						gRecipe.cmd.save		:= FALSE;
						// call the save cmd
						MpRecipeXml_0.Save 		:= TRUE;
						cm.state 				:= 300;
					END_IF
				ELSE
					gRecipe.cmd.load 	:= FALSE;
					gRecipe.cmd.save 	:= FALSE;
					cm.state 			:= 0;
				END_IF
			ELSE
				MpRecipeXml_0.UpdateNotification := FALSE;
			END_IF
			
		200:
			cm.description := 'wait for loading file';
			
			IF MpRecipeXml_0.CommandDone THEN
				// set the recipe interface
				gRecipe.status.loaded := TRUE;
				// reset the load cmd
				MpRecipeXml_0.Load := FALSE;
				// Signal to all tasks that we just loaded and that the task don't have to save this change!
				cm.state := 220;
			ELSIF MpRecipeXml_0.Error THEN
				MpRecipeXml_0.Load := FALSE;
				CASE MpRecipeXml_0.StatusID OF
					-1064140798,-1064140791: // mpRECIPE_ERR_LOAD_DATA
						MpRecipeXml_0.ErrorReset := TRUE;
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
			cm.description 			:= 'wait for saving file';
			
			IF MpRecipeXml_0.CommandDone THEN
				// set the recipe interface
				gRecipe.status.saved 	:= TRUE;
				gRecipe.status.loaded := TRUE;	// If we save a brand new one it's ofc. also loaded
				// reset the save cmd
				MpRecipeXml_0.Save 		:= FALSE;
				cm.state 				:= 220;
			ELSIF MpRecipeXml_0.Error THEN
				MpRecipeXml_0.Save 		:= FALSE;
				cm.state 				:= 9999;
			END_IF

		9999:
			cm.description := 'wait for error reset';
			
			IF NOT MpRecipeXml_0.Error THEN
				cm.state := 10;
			END_IF

	END_CASE
	
	cm();
	
	MpRecipeXml_0.MpLink := ADR(mpRecipe);
	MpRecipeXml_0.DeviceName := ADR('RECIPES');
	MpRecipeXml_0.Category := ADR('recipe'); 
	MpRecipeXml_0();
	
END_PROGRAM

PROGRAM _EXIT
	
	FileInfo_0(enable := FALSE);
	MpRecipeXml_0(Enable := FALSE);

END_PROGRAM

