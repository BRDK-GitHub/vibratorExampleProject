 
PROGRAM _INIT

	em.setup.name := 'capcon';
	em.setup.parent.name := 'main';
	em.setup.lastActivated := FALSE;
	
	// gets the task name and setup names for config and receipe types
	ST_name(0,ADR(this.names.configName),0);
	brdkStrCpy(ADR(this.names.recipeName),ADR(this.names.configName));
	brdkStrCpy(ADR(this.names.recipeNameCurrent),ADR(this.names.configName));
	brdkStrCat(ADR(this.names.configName),ADR(':this.hmi.config'));
	brdkStrCat(ADR(this.names.recipeName),ADR(':this.hmi.recipe'));
	brdkStrCat(ADR(this.names.recipeNameCurrent),ADR(':this.hmi.recipeCurrent'));
	
	setupPointers;
	
	//Alarm texts
	this.alarm.teachingError.name := 'capconTeachingError';
	
END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	
	IF gRecipe.status.newRecipeLoaded OR this.hmi.redoTeaching OR interface.cmd.reTeach THEN
		interface.cmd.reTeach := FALSE;
		gRecipe.status.newRecipeLoaded 	:= FALSE;	
		this.hmi.redoTeaching			:= FALSE;
		this.newRecipeLoaded 			:= TRUE;
	END_IF
	
	interface.parameter.simSampleDelay 	:= config.simSampleDelay;
	interface.parameter.controlPercent 	:= recipe.controlPrc;
	interface.parameter.capconMode 		:= recipe.capconMode;
	interface.status.cycleTime 			:= em.status.cycleTime;
	brsmemcpy(ADR(interface.config),ADR(config),SIZEOF(interface.config));
	
	countersData := countersData;
	TMU := TMU;
	
	CASE em.mode OF
		MODE_PRODUCING: producing;
		ELSE em.cmd.sc := TRUE;
	END_CASE
	
	alarm;
	
	em();
	
	interface.status.wingDosing := gRecipe.status.loaded AND (recipe.brickCount = 0 OR gMainInterface.line.bypassCassette);
	interface.status.numBricksInPortion := USINT_TO_UDINT(recipe.brickCount);
	interface.status.factorRmsMax := config.factorRmsMax;
	interface.status.capconMinThreshold := config.capconMinThreshold;
	
	// copy the recipe data
	CASE interface.cmd.copyRecipe OF
	
		COPY_RECIPE_NEXT_TO_WORKING: 
			IF gMainInterface.cmd.loadingTemplateRecipe THEN
				gMainInterface.cmd.loadingTemplateRecipe := FALSE;
				// Template recipe can't load brickCount
				this.brickCount := this.hmi.recipe.brickCount;
				this.hmi.recipe := this.hmi.recipeCurrent;
				this.hmi.recipe.brickCount := this.brickCount;
			ELSE
				this.hmi.recipe := this.hmi.recipeCurrent;
			END_IF
			
			//	this.hmi.recipe.controlPrcIdx := LIMIT(0, REAL_TO_USINT((USINT_TO_REAL(this.hmi.recipe.controlPrc)-35.0) / 10.0), 5);
			
			recipe.controlPrc := 45;
			recipe.controlPrcIdx := 1;
			recipe.controlPrcOld := 45;
			interface.status.numBricksInPortion := USINT_TO_UDINT(recipe.brickCount);
			gBeltInterface.cmd.initRecipe := TRUE; // Belt can only init when we know brickcount.
			gVibratorInterface[0].cmd.initRecipe := gVibratorInterface[1].cmd.initRecipe := TRUE; // Vibrator can only init recipe when we know brickcount
			gRecipe.cmd.save 			:= TRUE;
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
			
		COPY_RECIPE_SANDBOX_TO_NEXT: 
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
	
	END_CASE
	
	// Convert control% dropdown to controlPrc
	CASE this.hmi.recipe.controlPrcIdx OF
		0:
			this.hmi.recipe.controlPrc := 35;
		1:
			this.hmi.recipe.controlPrc := 45;
		2:
			this.hmi.recipe.controlPrc := 55;
		3:
			this.hmi.recipe.controlPrc := 65;
		4:
			this.hmi.recipe.controlPrc := 75;
		5:
			this.hmi.recipe.controlPrc := 85;
		ELSE
			this.hmi.recipe.controlPrc := 0;
	END_CASE
	
	IF gRecipe.status.doCheckForChanges AND NOT this.oldCheckChangesRecipe THEN
		gMainInterface.status.statusIT.PortionItemCount := USINT_TO_INT(recipe.brickCount);
		this.MpRecipeRegPar_Recipe.Enable := TRUE;
		this.MpRecipeRegPar_RecipeCurrent.Enable := TRUE;
	
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
	this.MpRecipeRegPar_Recipe(MpLink := ADR(mpRecipe), PVName := ADR(this.names.recipeName), Category := ADR('recipe'));
	this.MpRecipeRegPar_RecipeCurrent(MpLink := ADR(mpRecipeCurrent), PVName := ADR(this.names.recipeNameCurrent), Category := ADR('recipeCurrent'));
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
	this.MpRecipeRegPar_Config(MpLink := ADR(mpRecipe), PVName := ADR(this.names.configName), Category := ADR('config'));
	this.oldCheckChangesConfig := gConfig.status.doCheckForChanges;
	
	// Calculate count percentages
	this.sumStatistik := UDINT_TO_REAL(this.hmi.count.integral.tooBig + this.hmi.count.integral.tooSmall + this.hmi.count.invalidBuffer.count + gUpperFlapInterface.status.countAftercount);
	
	this.hmi.capconModeOn 		:= this.hmi.recipe.capconMode = 0;
	this.hmi.capconModeMedium 	:= this.hmi.recipe.capconMode = 1;
	this.hmi.capconModeOff 		:= this.hmi.recipe.capconMode = 2;
	this.hmi.teaching			:= this.newRecipeLoaded AND (em.state = STATE_STARTING OR em.state = STATE_EXECUTE);
	
	IF this.sumStatistik = 0 THEN
		this.hmi.count.integral.tooBigPercent	:= 0;
		this.hmi.count.integral.tooSmallPercent	:= 0;
		this.hmi.count.afterCounting.percent	:= 0;
		this.hmi.count.invalidBuffer.percent	:= 0;
		gUpperFlapInterface.status.countAftercount := 0; // only upperFlap knows the amount of aftercounts.
	ELSE
		this.hmi.count.integral.tooBigPercent	:= UDINT_TO_REAL(this.hmi.count.integral.tooBig) / this.sumStatistik * 100;
		this.hmi.count.integral.tooSmallPercent	:= UDINT_TO_REAL(this.hmi.count.integral.tooSmall) / this.sumStatistik * 100;
		this.hmi.count.afterCounting.percent	:= UDINT_TO_REAL(gUpperFlapInterface.status.countAftercount) / this.sumStatistik * 100;
		this.hmi.count.invalidBuffer.percent	:= UDINT_TO_REAL(this.hmi.count.invalidBuffer.count) / this.sumStatistik * 100;
	END_IF;
	
	interface.status.state := em.state;

	IF gConfig.status.factoryReset[3] THEN
		gConfig.status.factoryReset[3] := FALSE;
		// Factory reset all parameters:
		config.noStopDelay := 100;
		config.logToFile := FALSE;
		config.capconNoiseAllowedPeakToPeak := 55;
		config.capconDcOffsetAllowed := 800;
		config.capconNoiseAllowedSpeed := 2000;
		config.simSampleDelay := 150;
		config.portionsAllowTeach := 10;
		
		recipe.controlPrc := 55;
		recipe.controlPrcOld := 55;
		recipe.capconMode := 0;
		recipe.controlPrcIdx := 2;
	END_IF
END_PROGRAM

PROGRAM _EXIT
	setupPointers;
	this.MpRecipeRegPar_Recipe(Enable := FALSE);
	this.MpRecipeRegPar_Config(Enable := FALSE);
	this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
END_PROGRAM