PROGRAM _INIT

	em.setup.name := 'feeder';
	em.setup.lastActivated := FALSE;
	
	// gets the task name and setup names for config and receipe types
	ST_name(0,ADR(this.configName),0);
	brdkStrCpy(ADR(this.recipeName),ADR(this.configName));
	brdkStrCpy(ADR(this.recipeNameCurrent),ADR(this.configName));
	brdkStrCat(ADR(this.configName),ADR(':this.hmi.config'));
	brdkStrCat(ADR(this.recipeName),ADR(':this.hmi.recipe'));
	brdkStrCat(ADR(this.recipeNameCurrent),ADR(':this.hmi.recipeCurrent'));

	setupPointers;	
	
	this.hmi.cmd.enable := TRUE;			// always enable BF on a boot.

	// Set alarm texts
	this.alarm.lowLevel.name := 'feederLowLevel';
	this.alarm.boxMissing.name := 'feederBoxMissing';
	this.alarm.cannotCloseFlap.name := 'feederCannotCloseFlap';
	this.alarm.cannotOpenFlap.name := 'feederCannotOpenFlap';
	this.alarm.beltFeederEmpty.name := 'beltFeederEmpty';
	
	this.alarm.cannotCloseFlap.active := flapClosing;
	this.alarm.cannotOpenFlap.active := flapOpening;
	
END_PROGRAM

PROGRAM _CYCLIC
	
	setupPointers;
	
	this.hw.do_levelSensorInBowlLow 	:= recipe.levelSensor = LEVEL_SENSOR_LOW;
	this.hw.do_levelSensorInBowlMedium 	:= recipe.levelSensor = LEVEL_SENSOR_MEDIUM;
	this.hw.do_levelSensorInBowlHigh 	:= recipe.levelSensor = LEVEL_SENSOR_HIGH;
	
	IF interface.cmd.empty THEN // Signal from OPCUA to empty feeder
		interface.cmd.empty := FALSE;
		this.hmi.cmd.empty := TRUE;
	END_IF
	
	// Signal indicator for when vibrator is empty
	this.TON_VibratorBowlEmpty.IN := NOT this.hw.di_levelSensorInBowl AND cmIsRunning(interface.cmd.speed);
	this.TON_VibratorBowlEmpty.PT := T#3s;
	this.TON_VibratorBowlEmpty();
	interface.status.vibratorBowlEmpty := this.TON_VibratorBowlEmpty.Q;
	
	CASE em.mode OF
		MODE_PRODUCING: producing;
		ELSE em.cmd.sc := TRUE;
	END_CASE
		
	alarm;
	
	em();
	
	flapControl;
	beltControl;
	
	this.RTInfo_0.enable := TRUE;
	this.RTInfo_0();
	
	interface.status.state := em.state;
	interface.status.mode := em.mode;
	interface.status.beltFeederEmpty := this.hw.di_levelSensorBelt;

	
	recipe.onTime := MAX(10,recipe.onTime);
	recipe.offTime := MAX(10,recipe.offTime);

	// copy the recipe data
	CASE interface.cmd.copyRecipe OF
	
		COPY_RECIPE_NEXT_TO_WORKING: 
			this.hmi.recipe 			:= this.hmi.recipeCurrent;
			gRecipe.cmd.save 			:= TRUE;
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
			
			// Hardcode low filling for some elements. Ex. stalk, glass window and visor:
			IF elementNeedsLowFilling(gMainInterface.status.itemTypeId) THEN
				// Set low filling parameters
				recipe.startDelay := 3000;
				recipe.stopDelay := 10;
				recipe.onTime := 200;
				recipe.offTime := 2000;
				recipe.levelSensor := LEVEL_SENSOR_LOW;
			ELSE
				// Set default filling parameters
				recipe.startDelay := 500;
				recipe.stopDelay := 10;
				recipe.onTime := 1000;
				recipe.offTime := 300;
			END_IF
			
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
	
	IF gConfig.status.factoryReset[0] THEN
		gConfig.status.factoryReset[0] := FALSE;
		// Factory reset all parameters:
		recipe.offTime := 300;
		recipe.onTime := 1000;
		recipe.startDelay := 500;
		recipe.stopDelay := 10;
	END_IF
	
	
	
	// FAT Level sensor test
	IF interface.cmd.levelSensorTestActive THEN
		this.hw.do_levelSensorInBowlLow 	:= interface.cmd.setLevelSensor[0];
		this.hw.do_levelSensorInBowlMedium 	:= interface.cmd.setLevelSensor[1]; 
		this.hw.do_levelSensorInBowlHigh 	:= interface.cmd.setLevelSensor[2]; 
		interface.status.levelSensorReceiverInBowl := this.hw.di_levelSensorInBowl;
	END_IF
	
	
	// FAT FLAP TEST:
	IF gFeederInterface.cmd.startFlapTest THEN
		CASE this.state OF
			
			0:
				IF gFeederInterface.cmd.startFlapTest THEN
					gFeederInterface.status.flapTest := TEST_NOT_DONE;
					this.state := 10;
				END_IF
			
			10:
				//	em.description := 'Flap opening';
				
				this.flap.cmd.open := TRUE;
						
				IF this.flap.state = FEEDER_FLAP_OPENED THEN
					this.flap.cmd.open := FALSE;
					this.state := 20;
				END_IF
				
			20:
				//em.description := 'flap closing and run belt forward';
				
				this.flap.cmd.close := TRUE;
						
				IF this.flap.state = FEEDER_FLAP_CLOSED THEN
					this.flap.cmd.close :=  FALSE;
					gFeederInterface.cmd.startFlapTest := FALSE;
					this.testTimeout(IN:=FALSE);
					gFeederInterface.status.flapTest := TEST_OK;
					this.state := 0;
				END_IF
			
		END_CASE
		this.testTimeout.IN := TRUE;
		this.testTimeout.PT := T#20s;
		this.testTimeout();
		IF this.testTimeout.Q THEN
			this.flap.cmd.open := FALSE;
			this.flap.cmd.close := TRUE;
			IF this.flap.state = FEEDER_FLAP_CLOSED THEN
				this.flap.cmd.close :=  FALSE;
				this.state := 0;
				this.testTimeout(IN:=FALSE);
				gFeederInterface.cmd.startFlapTest := FALSE;
				gFeederInterface.status.flapTest := TEST_NOT_OK;
			END_IF
			
		END_IF
		IF this.hmi.cmd.stopFlapTest THEN
			this.flap.cmd.open := FALSE;
			this.testTimeout(IN:=FALSE);
			this.flap.cmd.close := TRUE;
			IF this.flap.state = FEEDER_FLAP_CLOSED THEN
				this.flap.cmd.close :=  FALSE;
				this.state := 0;
				this.hmi.cmd.stopFlapTest := FALSE;
				gFeederInterface.cmd.startFlapTest := FALSE;
				gFeederInterface.status.flapTest := TEST_NOT_OK;
			END_IF
			
		END_IF
		
	END_IF
	
END_PROGRAM

PROGRAM _EXIT

	this.MpRecipeRegPar_Recipe(Enable := FALSE);
	this.MpRecipeRegPar_Config(Enable := FALSE);
	this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
	 
END_PROGRAM