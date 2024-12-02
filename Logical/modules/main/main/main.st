
PROGRAM _INIT

	gMachineType := 'CM20'; // String identifier logger system.
	
	em.setup.name 			:= 'main';
	em.setup.lastActivated	:= FALSE;
	
	// gets the task name and setup names for config and receipe types
	ST_name(0,ADR(this.configName),0);
	brdkStrCpy(ADR(this.recipeName),ADR(this.configName));
	brdkStrCpy(ADR(this.recipeNameCurrent),ADR(this.configName));
	brdkStrCat(ADR(this.configName),ADR(':this.hmi.config'));
	brdkStrCat(ADR(this.recipeName),ADR(':this.hmi.recipe'));
	brdkStrCat(ADR(this.recipeNameCurrent),ADR(':this.hmi.recipeCurrent'));
	
	setupPointers;

	interface.status.simulation := DiagCpuIsSimulated();
	interface.status.statusIT.Connected := TRUE;
	
	brdkOPCUAMethodOperate_SetMode.enable 	:= TRUE;
	brdkOPCUAMethodOperate_SetMode.name 	:= 'SetMode';
	brdkOPCUAMethodOperate_LampMode.enable := TRUE;
	brdkOPCUAMethodOperate_LampMode.name := 'LampMode';
	hmiEmptyMode;
	interface.status.statusIT.Command := 1; // STOPPED
	
	// Alarm texts
	this.alarm.cantEmptyNeedCassette.name := 'cantEmptyNeedCassette';
	this.alarm.opcuaMethodError.name := 'opcuaMethodError';
	this.alarm.KA10.name := 'KA10ModuleError';
	this.alarm.KA11.name := 'KA11ModuleError';
	this.alarm.KA12.name := 'KA12ModuleError';
	this.alarm.KA13.name := 'KA13ModuleError';
	this.alarm.KA14.name := 'KA14ModuleError';
	this.alarm.KA15.name := 'KA15ModuleError';
	this.alarm.KA16.name := 'KA16ModuleError';
	this.alarm.KA17.name := 'KA17ModuleError';
	this.alarm.KA18.name := 'KA18ModuleError';
	this.alarm.KA19.name := 'KA19ModuleError';
	
	this.hmi.cmType := 'CM20';
	
END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	
	
	
	IF gRecipe.status.newRecipeLoaded THEN
		this.newRecipeLoaded := TRUE;
	END_IF
	
	// OPCUA cmds
	brdkOPCUAMethodOperate_SetMode();
	CASE brdkOPCUAMethodOperate_SetMode.state OF
		// TODO: Generate alarm if BRDK_OPCUA_ERROR occurs
		BRDK_OPCUA_METHOD_IS_CALLED:
			CASE setMode OF
			
				STOP:
					this.hmi.cmd.stop := TRUE;
			
					
				PRODUCTION:
					this.hmi.cmd.start := TRUE;
				
				PRE_EMPTY:
					interface.line.emptyMode := hmiEmptyMode := TRUE;
					
				PRE_EMPTY_DISABLE:
					interface.line.emptyMode := hmiEmptyMode := FALSE;
					
				EMPTY_OUT:
					gFeederInterface.cmd.empty := TRUE;	// cmd to feeder (feeder is not parent of main)
					this.hmi.cmd.empty := TRUE;
				
			END_CASE
	
			brdkOPCUAMethodOperate_SetMode.finish := TRUE;

	END_CASE
	
	// Ethernet IP cmds
	IF interface.cmd.stopEthIP AND NOT this.oldStopEthIP THEN
		// Rising edge trigger
		this.hmi.cmd.stop := TRUE;
	END_IF
	this.oldStopEthIP := interface.cmd.stopEthIP;
	
	IF interface.cmd.startEthIP AND NOT this.oldStartEthIP THEN
		// Rising edge trigger
		this.hmi.cmd.start := TRUE;
	END_IF
	this.oldStartEthIP := interface.cmd.startEthIP;
	
	IF interface.cmd.emptyEthIP AND NOT this.oldEmptyEthIP THEN
		// Rising edge trigger
		gFeederInterface.cmd.empty := TRUE;	// cmd to feeder (feeder is not parent of main)
		this.hmi.cmd.empty := TRUE;
	END_IF
	this.oldEmptyEthIP := interface.cmd.emptyEthIP;
	
	IF interface.cmd.emptyModeEthIP AND NOT this.oldEmptyModeEthIP THEN
		// Rising AND falling edge trigger
		interface.line.emptyMode := hmiEmptyMode := TRUE;
	END_IF
	this.oldEmptyModeEthIP := interface.cmd.emptyModeEthIP;
	
	interface.line.bypassCassette := interface.cmd.bypassCassetteEthIP; // bypass always dictated by line controller over ethernet ip.

	//-------------------------------- //
	
	// Ethernet IP status
	gEthernetIPInterface.status.stop := em.state = STATE_STOPPED;
	gEthernetIPInterface.status.start := em.state <> STATE_STOPPED; 
	gEthernetIPInterface.status.empty := interface.status.emptying;
	gEthernetIPInterface.status.emptyMode := interface.line.emptyMode;
	gEthernetIPInterface.status.bypassCassette := interface.line.bypassCassette;
	
	em.cmd.stop := this.hmi.cmd.stop OR gRecipe.cmd.load;
	this.stopCalibration :=  em.mode = MODE_CALIBRATING AND em.state <> STATE_STOPPED;
	
	// Some status update for IT
	IF this.updateStatus THEN
		this.updateStatus := FALSE;
		// CM_BOOL_STATUS for gateway. 0: stopped, 1: running, 2: emptying, 3: preempty, 4: dosing
		interface.status.statusIT.BypassCassette := interface.line.bypassCassette;
		CM_BOOL_STATUS.1 := em.state=STATE_EXECUTE OR em.state=STATE_STARTING;
		CM_BOOL_STATUS.2 := em.state=STATE_COMPLETE OR em.state=STATE_COMPLETING;
		CM_BOOL_STATUS.0 := NOT CM_BOOL_STATUS.1 AND NOT CM_BOOL_STATUS.2; // If not running or emptying, then it's stopped.
		CM_BOOL_STATUS.3 := interface.line.emptyMode;
		CM_BOOL_STATUS.4 := interface.line.bypassCassette OR gCapconInterface.status.wingDosing;	// When recipe.brickCount=0 OR line command
		
		
		IF interface.line.bypassCassette THEN
			// dosing
			interface.status.statusIT.Command := 4;
		ELSIF em.state=STATE_COMPLETE OR em.state=STATE_COMPLETING THEN
			// emptying
			interface.status.statusIT.Command := 2;
		ELSIF interface.line.emptyMode THEN
			// preempty
			interface.status.statusIT.Command := 5;
		ELSE
			// Production if em is in execute/starting else stopped
			interface.status.statusIT.Command := SEL(em.state=STATE_EXECUTE OR em.state=STATE_STARTING,1,3);
		END_IF
		
	END_IF
	
	
	FOR i := 0 TO 20 BY 1 DO
		IF gMainInterface.cmd.activateCalibrateMode[i] THEN
			IF em.mode = MODE_PRODUCING AND em.state <> STATE_STOPPED THEN
				em.cmd.stop := TRUE;
			END_IF
			this.stopCalibration := FALSE; // do not stop calibration as one module still has calibration active
		END_IF
	END_FOR
			
	IF this.stopCalibration THEN
		em.cmd.stop := TRUE;
	END_IF
	
	interface.line.emptyMode := hmiEmptyMode; // emptyMode from hmi.

	
	IF this.hmi.cmd.redoTeaching AND (em.state = STATE_STARTING) THEN
		this.reteach := TRUE;
		em.cmd.stop := TRUE;
	END_IF
	
	
	CASE em.mode OF
		MODE_PRODUCING: producing;
		MODE_CALIBRATING: calibrating;
		MODE_MANUAL: testing;
			
		ELSE em.cmd.sc := TRUE;
	END_CASE
	
	
	interface.status.emMode := em.mode;
	interface.status.itemNumber := SEL(this.hmi.itemNumberNext <> '', recipe.itemNumber, this.hmi.itemNumberNext);
	interface.status.itemTypeId := recipe.itemTypeId;
	interface.status.machineDirection := config.machineType;
	this.hmi.showNextItemNumberLabel := this.hmi.itemNumberNext <> '';
	
	brdkStrMemSet(ADR(this.hmi.cmd),0,SIZEOF(this.hmi.cmd));
			
		
	alarm;
	lampCtrl;
	em();
	
	
	//Give status to wing that machine start and reset statistic
	IF em.state = STATE_EXECUTE AND em.mode = MODE_PRODUCING THEN
		interface.status.machineStart	:= TRUE;
	ELSE
		interface.status.machineStart	:= FALSE;
	END_IF
	
	//this.hmi.mainAborted := em.state = STATE_ABORTED;
	
	// copy the recipe data
	CASE interface.cmd.copyRecipe OF
	
		COPY_RECIPE_NEXT_TO_WORKING: 
			IF interface.cmd.loadingTemplateRecipe THEN
				// Template recipe can't load itemNumber/itemTypeId
				this.itemNumber := this.hmi.recipe.itemNumber;
				this.itemTypeId := this.hmi.recipe.itemTypeId;
				this.hmi.recipe := this.hmi.recipeCurrent;
				this.hmi.recipe.itemNumber := this.itemNumber;
				this.hmi.recipe.itemTypeId := this.itemTypeId;
			ELSE
				this.hmi.recipe := this.hmi.recipeCurrent;
			END_IF
			interface.status.statusIT.ItemType := DINT_TO_UDINT(recipe.itemTypeId);
			interface.status.itemTypeId := recipe.itemTypeId;
			this.hmi.itemNumberNext := '';
			
			IF recipe.itemTypeId = 24855 OR recipe.itemTypeId = 3741 THEN
				// Stalk element. Put som hardcoded values for this because it is a very tricky element and we have seen some very bad values in lego DB.
				gVibratorInterface[0].cmd.putRecipeForStalkElement := gVibratorInterface[1].cmd.putRecipeForStalkElement := gBeltInterface.cmd.putRecipeForStalkElement := TRUE;
			END_IF
			
			gRecipe.cmd.save 			:= TRUE;
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
			
		COPY_RECIPE_SANDBOX_TO_NEXT: 
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
	
	END_CASE
	
	IF gRecipe.status.doCheckForChanges AND NOT this.oldCheckChangesRecipe THEN
		this.MpRecipeRegPar_Recipe.Enable := TRUE;
		this.MpRecipeRegPar_RecipeCurrent.Enable := TRUE;
		// Update statusIT.
		interface.status.statusIT.ItemNumber := STRING_TO_UDINT(recipe.itemNumber);
		interface.status.statusIT.ItemType := DINT_TO_UDINT(recipe.itemTypeId);
	
		IF gRecipe.status.loaded AND NOT this.oldLoadedRecipe THEN
			// Initial program load. Set old=new to avoid saving just after a load (makes no sense)
			this.recipeOld := this.hmi.recipe;
		END_IF
		this.oldLoadedRecipe := gRecipe.status.loaded;
		
		IF NOT gRecipe.cmd.save AND gRecipe.status.loaded AND (brsmemcmp(ADR(this.hmi.recipe),ADR(this.recipeOld),SIZEOF(this.recipeOld)) <> 0) THEN
			gRecipe.cmd.save := TRUE;
			this.recipeOld := this.hmi.recipe;
		END_IF
		
	END_IF
	this.MpRecipeRegPar_Recipe(MpLink := ADR(mpRecipe), PVName := ADR(this.recipeName), Category := ADR('recipe'));
	this.MpRecipeRegPar_RecipeCurrent(MpLink := ADR(mpRecipeCurrent), PVName := ADR(this.recipeNameCurrent), Category := ADR('recipeCurrent'));
	this.oldCheckChangesRecipe := gRecipe.status.doCheckForChanges;
	
	IF gConfig.status.doCheckForChanges AND NOT this.oldCheckChangesConfig THEN
		this.MpRecipeRegPar_Config.Enable := TRUE;
	
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
	
	interface.status.state := em.state;
	

	
END_PROGRAM

PROGRAM _EXIT
	
	this.MpRecipeRegPar_Recipe(Enable := FALSE);
	this.MpRecipeRegPar_Config(Enable := FALSE);
	this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
	brdkOPCUAMethodOperate_SetMode(enable:=FALSE);
	brdkOPCUAMethodOperate_LampMode(enable:=FALSE);
END_PROGRAM

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                