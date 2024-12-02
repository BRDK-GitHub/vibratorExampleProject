PROGRAM _INIT

	em.setup.name 			:= 'wing';
	em.setup.reactTo 		:= BRDK_EM_REACT_TO_ALL;

	em.setup.lastActivated	:= TRUE;
			
	// gets the task name and setup names for config and receipe types
	ST_name(0,ADR(this.configName),0);
	brdkStrCpy(ADR(this.recipeName),ADR(this.configName));
	brdkStrCpy(ADR(this.recipeNameCurrent),ADR(this.configName));
	brdkStrCat(ADR(this.configName),ADR(':this.hmi.config'));
	brdkStrCat(ADR(this.recipeName),ADR(':this.hmi.recipe'));
	brdkStrCat(ADR(this.recipeNameCurrent),ADR(':this.hmi.recipeCurrent'));
	
	
	
	setupPointers;
	// Init recipe/config
	config.cassetteDetectTime := 25000;
	config.cassetteReleaseTime := 25000;
	config.readyDelay := 230000;
	config.emptySmallItemsTime := 2000000;
	config.transmissionDelay := 10000;
	config.simCassette := FALSE;
	config.simNeighbour := FALSE;
	config.addFallTimeBottom := 70000;
	// recipe wing timings:
	recipe.flapOpenTimeMiddle.normal := 210000;
	recipe.flapOpenTimeMiddle.Long := 560000;
	recipe.flapOpenTimeUpper.normal := 130000;
	recipe.flapOpenTimeUpper.Long := 360000;
	recipe.flapOpenTimeBottom.normal := 60000;
	recipe.flapOpenTimeBottom.Long := 360000;
	recipe.fallTimeUM := 110000;
	recipe.fallTimeBottom := 260000;
	recipe.longBrick := FALSE;
	recipe.fallTimeBottomLong := 460000;
	recipe.fallTimeBottomNormal := 260000;

END_PROGRAM

PROGRAM _CYCLIC
	
	setupPointers;
	
	gWingInterface.parameter.simulation := config.simWing;
	
	gWingInterface.status.wingEmpty		:= gUpperFlapInterface.status.ready AND gMiddleFlapInterface.status.ready AND gBottomFlapInterface.status.ready1;
	
	
	// select if the time is for a short or long brick
	IF recipe.longBrick THEN
		gUpperFlapInterface.parameter.openTime 	:= recipe.flapOpenTimeUpper.Long;
		gMiddleFlapInterface.parameter.openTime := recipe.flapOpenTimeMiddle.Long;
		gBottomFlapInterface.parameter.openTime := recipe.flapOpenTimeBottom.Long;
		gBottomFlapInterface.parameter.fallTime	:= recipe.fallTimeBottomLong;
		config.mediumFlaps := FALSE; // medium not allowed while having long.
	ELSIF config.mediumFlaps THEN
		gUpperFlapInterface.parameter.openTime 	:= recipe.flapOpenTimeUpper.normal;
		gMiddleFlapInterface.parameter.openTime := recipe.flapOpenTimeMiddle.normal;
		gBottomFlapInterface.parameter.openTime := recipe.flapOpenTimeBottom.normal;
		gBottomFlapInterface.parameter.fallTime	:= recipe.fallTimeBottomNormal+config.addFallTimeBottom;
	ELSE
		gUpperFlapInterface.parameter.openTime 	:= recipe.flapOpenTimeUpper.normal;
		gMiddleFlapInterface.parameter.openTime := recipe.flapOpenTimeMiddle.normal;
		gBottomFlapInterface.parameter.openTime := recipe.flapOpenTimeBottom.normal;
		gBottomFlapInterface.parameter.fallTime	:= recipe.fallTimeBottomNormal;
	END_IF
	
			
	// set flap times
	gUpperFlapInterface.parameter.flapTime 	:= config.flapMoveTime;
	gMiddleFlapInterface.parameter.flapTime := config.flapMoveTime;
	gBottomFlapInterface.parameter.flapTime := config.flapBottomMoveTime;

	gMiddleFlapInterface.parameter.emptySmallItemsTime 	:= config.emptySmallItemsTime;
	gMiddleFlapInterface.cmd.smallBrick					:= gVibratorInterface[0].status.machineType=0; // Only empty small bricks if it's a small CM20.
	gMiddleFlapInterface.parameter.fallTime				:= recipe.fallTimeUM;
	
	// Transmission delay.
	gBottomFlapInterface.parameter.transmissionDelay := config.transmissionDelay;
	gBottomFlapInterface.parameter.cassetteStartDelay := config.readyDelay;
	
	// set pther timers
	gCassetteInterface.parameter.cassetteDetectTime := config.cassetteDetectTime;
	gCassetteInterface.parameter.releaseTime 		:= config.cassetteReleaseTime;
	gWingInterface.status.simCassette := this.hmi.config.simCassette OR gMainInterface.status.simulation;
	gWingInterface.status.simNeighbour := this.hmi.config.simNeighbour;
	
	interface.status.timeTOF_cassetteSignals := config.timeTOF_cassetteSignals;
	
	//Normally belt will run when upperFlap close command = TRUE. If this is greater than 0 we will wait that time before telling belt to run.
	gUpperFlapInterface.parameter.startBeltWaitTime := config.startBeltWaitTime;
	
	CASE em.mode OF
		MODE_PRODUCING,MODE_EMPTY: producing;
		MODE_MANUAL: testing;	// mode for testing flaps manually.
		ELSE em.cmd.sc := TRUE;
	END_CASE

	em();
	
	alarm;

	this.hw.do_active := TRUE;
	
	// copy the recipe data
	CASE interface.cmd.copyRecipe OF
	
		COPY_RECIPE_NEXT_TO_WORKING: 
			this.hmi.recipe 			:= this.hmi.recipeCurrent;
			gRecipe.cmd.save 			:= TRUE;
			config.mediumFlaps 			:= FALSE;
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
			
		COPY_RECIPE_SANDBOX_TO_NEXT: 
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
	
	END_CASE
	
	IF gRecipe.status.doCheckForChanges AND NOT this.oldCheckChangesRecipe THEN
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
	
	IF gConfig.status.factoryReset[4] THEN // Both cassette/wing
		gConfig.status.factoryReset[4] := FALSE;
		// Factory reset all parameters:
		config.cassetteDetectTime := 25000;
		config.cassetteReleaseTime := 25000;
		config.readyDelay := 230000;
		config.emptySmallItemsTime := 2000000;
		config.transmissionDelay := 10000;
		config.simCassette := FALSE;
		config.simNeighbour := FALSE;
		config.addFallTimeBottom := 70000;
		// recipe wing timings:
		recipe.flapOpenTimeMiddle.normal := 210000;
		recipe.flapOpenTimeMiddle.Long := 560000;
		recipe.flapOpenTimeUpper.normal := 130000;
		recipe.flapOpenTimeUpper.Long := 360000;
		recipe.flapOpenTimeBottom.normal := 60000;
		recipe.flapOpenTimeBottom.Long := 360000;
		recipe.fallTimeUM := 110000;
		recipe.fallTimeBottom := 260000;
		recipe.longBrick := FALSE;
		recipe.fallTimeBottomLong := 460000;
		recipe.fallTimeBottomNormal := 260000;
	
	END_IF
	
END_PROGRAM

PROGRAM _EXIT

	this.MpRecipeRegPar_Recipe(Enable := FALSE);
	this.MpRecipeRegPar_Config(Enable := FALSE);
	this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
	 
END_PROGRAM

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        