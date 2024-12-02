
PROGRAM _INIT

	// index 0 is the circular vibrator
	// index 1 is the linear vibrator
	
	FOR i := 0 TO NUM_VIBRATOR DO

		setupPointers;
	
		// gets the task name and setup names for config and receipe types
		ST_name(0,ADR(this.configName),0);
		brdkStrCpy(ADR(this.recipeName),ADR(this.configName));
		brdkStrCpy(ADR(this.recipeNameCurrent),ADR(this.configName));
		brdkStrCat(ADR(this.configName),ADR(':localVariables['));
		brdkStrCat(ADR(this.recipeName),ADR(':localVariables['));
		brdkStrCat(ADR(this.recipeNameCurrent),ADR(':localVariables['));
		brdkStrAppendUdintToA(i,ADR(this.configName),0,-1);
		brdkStrCat(ADR(this.configName),ADR('].hmi.config'));
		brdkStrAppendUdintToA(i,ADR(this.recipeName),0,-1);
		brdkStrCat(ADR(this.recipeName),ADR('].hmi.recipe'));
		brdkStrAppendUdintToA(i,ADR(this.recipeNameCurrent),0,-1);
		brdkStrCat(ADR(this.recipeNameCurrent),ADR('].hmi.recipeCurrent'));
		
		// Init recipe
		recipe.countingSpeed := SEL(i=0,50,15);
		recipe.waitSpeed := SEL(i=0,35,10);
		
	END_FOR
	
END_PROGRAM

PROGRAM _CYCLIC
	
	//-------------------------------------------------------------------------------------------------------------------------------------------------
	// Recipe handling for CF (gateway still sends recipe to vibrator task so we have to map it to the new advanced vibrations "EM_vibrat" task.) 
	//-------------------------------------------------------------------------------------------------------------------------------------------------
	FOR i:=0 TO NUM_VIBRATOR DO
		setupPointers;
		
		// copy the recipe data
		CASE interface.cmd.copyRecipe OF
		
			COPY_RECIPE_NEXT_TO_WORKING: 
				this.hmi.recipe 			:= this.hmi.recipeCurrent;
				this.hmi.recipe.countingSpeed := LIMIT(5,this.hmi.recipe.countingSpeed,100);
				
				// Init on changeover for autoMode
				IF gVibratorInterface[0].parameter.machineSize <> 1 THEN
					recipe.rampUp := 100; // 100 is default ramp up.
				END_IF
				interface.status.countingSpeed := recipe.countingSpeed;
				
				IF i=1 THEN
					// Send to belt that we have a changeover and it can take CF/LF countspeed
					gBeltInterface.cmd.changeover := TRUE;
				END_IF
				
				gRecipe.cmd.save 			:= TRUE;
				interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
				
			COPY_RECIPE_SANDBOX_TO_NEXT: 
				interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
		
		END_CASE
		
		IF interface.cmd.putRecipeForStalkElement THEN
			interface.cmd.putRecipeForStalkElement := FALSE;
			
			recipe.countingSpeed := SEL(i=0,45,25);
			recipe.waitSpeed := SEL(i=0,10,10);
			recipe.rampUp := 0;
		ELSIF interface.cmd.initRecipe THEN
			interface.cmd.initRecipe := FALSE;
			
			IF gCapconInterface.status.numBricksInPortion > 2 THEN
				IF i=0 THEN
					recipe.waitSpeed := LIMIT(0,recipe.waitSpeed,15);
				ELSE
					recipe.waitSpeed := LIMIT(0,recipe.waitSpeed,20);
				END_IF
			END_IF
		END_IF
		
		IF gRecipe.status.doCheckForChanges AND NOT this.oldCheckChangesRecipe THEN
			gMainInterface.status.statusIT.Type := SINT_TO_INT(localVariables[0].hmi.config.type);
			this.MpRecipeRegPar_Recipe.Enable := TRUE;
			this.MpRecipeRegPar_RecipeCurrent.Enable := TRUE;
	
			// If not in AutoMode set count speeds from belt into the recipe. We don't want it doing AutoMode because it will trigger a save to file all the time
			IF NOT gBeltInterface.status.autoMode AND gBeltInterface.status.recipeLoaded THEN
				recipe.countingSpeed := SEL(i=0,REAL_TO_USINT(gBeltInterface.status.LFCountSpeed),REAL_TO_USINT(gBeltInterface.status.CFCountSpeed));
			END_IF
			
			IF gRecipe.status.loaded AND NOT this.oldLoadedRecipe THEN
				// Initial program load. Set old=new to avoid saving just after a load (makes no sense)
				local.recipeOld := this.hmi.recipe;
			END_IF
			this.oldLoadedRecipe := gRecipe.status.loaded;
			
			IF NOT gRecipe.cmd.save AND gRecipe.status.loaded AND (brsmemcmp(ADR(this.hmi.recipe),ADR(local.recipeOld),SIZEOF(local.recipeOld)) <> 0) THEN
				gRecipe.cmd.save := TRUE;
				local.recipeOld := this.hmi.recipe;
			END_IF
		
		END_IF
		this.MpRecipeRegPar_Recipe(MpLink := ADR(mpRecipe), PVName := ADR(this.recipeName), Category := ADR('recipe'));
		this.MpRecipeRegPar_RecipeCurrent(MpLink := ADR(mpRecipeCurrent), PVName := ADR(this.recipeNameCurrent), Category := ADR('recipeCurrent'));
		this.oldCheckChangesRecipe := gRecipe.status.doCheckForChanges;
		
		// Mapping of vibrator recipe to -> EM_vibrat 
		interface.status.countingSpeed := recipe.countingSpeed;
		interface.status.waitSpeed := recipe.waitSpeed;
		interface.status.rampUp := recipe.rampUp;
		
		(* beeing able to watch the referenced variable *)
		watchIdx := LIMIT(0, watchIdx, NUM_VIBRATOR);
		this ACCESS ADR(localVariables[watchIdx]);
		em ACCESS ADR(localModule[watchIdx]);
		interface ACCESS ADR(gVibratorInterface[watchIdx]);
		config ACCESS ADR(localVariables[watchIdx].hmi.config);
		configTmp ACCESS ADR(local_no_opcua[watchIdx].configTmp);
		recipe ACCESS ADR(localVariables[watchIdx].hmi.recipe);
		axis ACCESS ADR(localAxis[watchIdx]);
		local ACCESS ADR(local_no_opcua[watchIdx]);
	END_FOR
	
	// Factory reset:
	IF gConfig.status.loadInitialValue[1] AND (gRecipe.status.saved OR gRecipe.status.loaded) AND (gConfig.status.saved OR gConfig.status.loaded) THEN
		gConfig.status.loadInitialValue[1] := FALSE;
		localVariables[0].hmi.recipe.countingSpeed := 15;
		localVariables[0].hmi.recipe.waitSpeed := 10;
		localVariables[1].hmi.recipe.countingSpeed := 50;
		localVariables[1].hmi.recipe.waitSpeed := 35;
		localVariables[1].hmi.recipe.rampUp := 0;
	END_IF
	
	
	
END_PROGRAM

PROGRAM _EXIT
	FOR i:=0 TO NUM_VIBRATOR DO
		setupPointers;
		this.MpRecipeRegPar_Recipe(Enable := FALSE);
		this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
		this.MpRecipeRegPar_Config(Enable := FALSE);
		this.MTBasicsLimiter_0(Enable := FALSE);
		this.sweep.MTDataMinMax_0(Enable := FALSE);
		this.lookUpFrequency(Enable := FALSE);
		this.linearizationTable(Enable := FALSE);
		this.linearizationSweep.MTBasicsPID_0(Enable := FALSE);
	END_FOR

END_PROGRAM
