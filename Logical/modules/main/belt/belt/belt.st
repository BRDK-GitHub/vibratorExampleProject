
PROGRAM _INIT

	em.setup.name := 'belt';
	em.setup.parent.name := 'main';
	em.setup.lastActivated := FALSE;
	
	// gets the task name and setup names for config and receipe types
	ST_name(0,ADR(this.configName),0);
	brdkStrCpy(ADR(this.recipeName),ADR(this.configName));
	brdkStrCpy(ADR(this.recipeNameCurrent),ADR(this.configName));
	brdkStrCat(ADR(this.configName),ADR(':this.hmi.config'));
	brdkStrCat(ADR(this.recipeName),ADR(':this.hmi.recipe'));
	brdkStrCat(ADR(this.recipeNameCurrent),ADR(':this.hmi.recipeCurrent'));
	
	setupPointers;
	
	//=====================================================================================
	//						Axis adr setup
	//=====================================================================================
	axis.configuration.ignoreSwLimit	:= TRUE;
	axis.configuration.disableTemperatureReading := TRUE;
	axis.configuration.disableTorqueReading := TRUE;
	axis.configuration.disableLagErrorReading := TRUE;
	axis.configuration.period := 0;
	axis.configuration.factor := 100;
	
	//Set alarm texts
	this.alarm.missingElements.name := 'beltMissingElements';
	this.alarm.axisError.name := 'beltAxisError';
	this.alarm.beltBlocked.name := 'beltBlocked';
	
END_PROGRAM

PROGRAM _CYCLIC

	setupPointers;
	
	IF gMainInterface.status.simulation OR gSimulation.status.simulateAllButWing THEN
		this.hw.di_photo := gSimulation.status.photoSensor;
	END_IF
	
	//***********************************
	//          Brick Detector
	//***********************************
	this.BrickDetector_0.Signal 		:= this.hw.di_photo;
	this.BrickDetector_0.BeltPosition 	:= axis.status.actPosition;
	this.BrickDetector_0.ItemGap 		:= recipe.itemGap;
	this.BrickDetector_0.FlickeringFilterGap := config.flickeringFilterGap;
	this.BrickDetector_0.FlickeringFilterGapLong := config.flickeringFilterGapLong;
	this.BrickDetector_0();

	this.brickDetected := this.BrickDetector_0.Out;
	this.hmi.itemGapTeaching := this.BrickDetector_0.Teaching;

	//***********************************
	//          Brick Counter
	//***********************************
	this.BrickCounter_0.Signal 			:= this.BrickDetector_0.Out;
	this.BrickCounter_0();

	//***********************************
	//         Brick Information
	//***********************************
	this.BrickInfo_0.Signal 		:= this.BrickDetector_0.Out;
	this.BrickInfo_0.Speed 			:= interface.status.speed;
	this.BrickInfo_0.BeltPosition 	:= axis.status.actPosition;
	this.BrickInfo_0();
	
	this.hmi.avgDistanceBetweenBricks := this.BrickInfo_0.BrickGap;
	
	//***********************************
	// Ramp Up Time Calc
	//***********************************
//	this.RampUpTimeCalc_0.Enable := TRUE;
//	this.RampUpTimeCalc_0.BeltFeederSensor := NOT gFeederInterface.status.beltFeederEmpty;
//	this.RampUpTimeCalc_0.ChangeOverCounter := this.changeOverCounter;
//	this.RampUpTimeCalc_0.OKPortions := gUpperFlapInterface.status.OKPortions;
//	this.RampUpTimeCalc_0.Running := em.state = STATE_STARTING OR em.substate = STATE_EXECUTE;
//	this.RampUpTimeCalc_0.CFSensor := NOT gFeederInterface.status.vibratorBowlEmpty;
//	this.RampUpTimeCalc_0();
//
//	this.hmi.rampUpTime := this.RampUpTimeCalc_0.RampUpTime;
	
	//***********************************
	// Vibrator Controller (Auto Mode)
	//***********************************
	
	
	CASE interface.parameter.brickCountInPortion OF
		
		0,1:
			this.CFController_0.BrickGapTargetMin := 55;
			this.CFController_0.BrickGapTargetMax := config.brickGapCfMax1Portion;
			this.LFController_0.BrickGapTargetMin := config.brickGapLfMin1Portion;
			this.LFController_0.BrickGapTargetMax := 70;
			
		2:
			this.CFController_0.BrickGapTargetMin := 55;
			this.CFController_0.BrickGapTargetMax := config.brickGapCfMax2Portion;
			this.LFController_0.BrickGapTargetMin := config.brickGapLfMin2Portion;
			this.LFController_0.BrickGapTargetMax := 45;
			
		3:
			this.CFController_0.BrickGapTargetMin := 50;
			this.CFController_0.BrickGapTargetMax := config.brickGapCfMax3Portion;
			this.LFController_0.BrickGapTargetMin := config.brickGapLfMin3Portion;
			this.LFController_0.BrickGapTargetMax := config.brickGapLfMin3Portion;
			
		4:
			this.CFController_0.BrickGapTargetMin := config.brickGapCfMax4Portion;
			this.CFController_0.BrickGapTargetMax := config.brickGapCfMax4Portion;
			this.LFController_0.BrickGapTargetMin := config.brickGapLfMin4Portion;
			this.LFController_0.BrickGapTargetMax := config.brickGapLfMin4Portion;
			
		ELSE
			this.CFController_0.BrickGapTargetMin := config.brickGapCfMax4Portion;
			this.CFController_0.BrickGapTargetMax := config.brickGapCfMax4Portion;
			this.LFController_0.BrickGapTargetMin := config.brickGapLfMin4Portion;
			this.LFController_0.BrickGapTargetMax := config.brickGapLfMin4Portion;
		
	END_CASE
	
	// One time set belt speed in AutoMode when 20 bricks has been counted (If brick is very long a 2 portion might need to use same belt speed as a 4 portion small brick).
//	IF this.hmi.enableAutoMode AND this.BrickInfo_0.BrickCount=20 THEN
//		this.portionLength := (this.BrickInfo_0.BrickLength+this.LFController_0.BrickGapTargetMax)*UDINT_TO_REAL(interface.parameter.brickCountInPortion);
//		
//		IF this.portionLength < 120 THEN
//			recipe.countingSpeed := 380;
//		ELSIF this.portionLength < 170 THEN
//			recipe.countingSpeed := 400;
//		ELSE
//			recipe.countingSpeed := 420;
//		END_IF
//	END_IF
	
	this.CFController_0.Enable := this.hmi.enableAutoMode;
	this.CFController_0.BrickGap := this.BrickInfo_0.BrickGap75;
	this.CFController_0.MaxOutput := SEL(this.BrickInfo_0.BrickLength=0, MIN(this.BrickInfo_0.BrickLength*2.5, 80), 80);
	this.CFController_0.PortionCount := interface.parameter.brickCountInPortion;
	this.CFController_0.Running := gVibratorInterface[0].status.percent > 0 AND (em.state = STATE_EXECUTE OR em.state = STATE_STARTING);
	this.CFController_0.NoElements := gFeederInterface.status.vibratorBowlEmpty;
	this.CFController_0.BeltMissingElements := this.BrickInfo_0.MissingElements AND em.state <> STATE_STOPPED;
	this.CFController_0.StaticOut := CFCountSpeed;
	this.CFController_0();
	
	this.LFController_0.Enable := this.hmi.enableAutoMode;
	this.LFController_0.BrickGap := this.BrickInfo_0.MinBrickGap;
	this.LFController_0.Running := gVibratorInterface[1].status.percent > 0 AND (em.state = STATE_EXECUTE OR em.state = STATE_STARTING);
	this.LFController_0.BeltMissingElements := this.BrickInfo_0.MissingElements AND em.state <> STATE_STOPPED;
	this.LFController_0.StaticOut := LFCountSpeed;
	this.LFController_0();
	
	this.CFController_0.LFOut := this.LFController_0.Out;
	
	IF this.LFController_0.Active THEN
		interface.status.LFCountSpeed := LIMIT(5,this.LFController_0.Out,130);
		interface.status.CFCountSpeed := LIMIT(10,this.CFController_0.Out,100);
		
		CFCountSpeed := interface.status.CFCountSpeed;
		LFCountSpeed := interface.status.LFCountSpeed;
	ELSE
		interface.status.CFCountSpeed := CFCountSpeed;
		interface.status.LFCountSpeed := LFCountSpeed;
	END_IF
	
	
	// Auto disable AutoMode if output is good!
	IF this.hmi.enableAutoMode THEN
		
		// Minimum wait 20 portions in EXECUTE before auto disabling
		IF interface.cmd.cycleTimeCount > 19 THEN 
			
			CASE interface.parameter.brickCountInPortion OF
			
			0,1:
				IF gCapconInterface.status.cycleTimeAutoMode > config.cycleTimeToStopAutoMode1 THEN
					this.hmi.enableAutoMode := FALSE;	
				END_IF
				
			2:
				IF gCapconInterface.status.cycleTimeAutoMode > config.cycleTimeToStopAutoMode2 THEN
					this.hmi.enableAutoMode := FALSE;	
				END_IF
				
			3:
				IF gCapconInterface.status.cycleTimeAutoMode > config.cycleTimeToStopAutoMode3 THEN
					this.hmi.enableAutoMode := FALSE;	
				END_IF
	
				
			4:
				IF gCapconInterface.status.cycleTimeAutoMode > config.cycleTimeToStopAutoMode4 THEN
					this.hmi.enableAutoMode := FALSE;	
				END_IF	
		
				
			ELSE
				IF gCapconInterface.status.cycleTimeAutoMode > config.cycleTimeToStopAutoMode4 THEN
					this.hmi.enableAutoMode := FALSE;	
				END_IF	
		
			
			END_CASE
			
		END_IF
		
	ELSIF NOT this.changeOverTriggered THEN
		interface.cmd.cycleTimeCount := 0;
	END_IF
	
	IF config.enablePermanentAutoMode THEN
		this.hmi.enableAutoMode := TRUE;
	END_IF
	
	IF this.changeOverTriggered THEN
		
		// After changeover wait 10 portions -> if output is low enable AutoMode
		IF interface.cmd.cycleTimeCount > 9 THEN 
			this.changeOverTriggered := FALSE;
			
			CASE interface.parameter.brickCountInPortion OF
			
				0,1:
					IF gCapconInterface.status.cycleTimeAutoMode < config.cycleTimeToStopAutoMode1 THEN
						this.hmi.enableAutoMode := TRUE;	
					END_IF
				
				2:
					IF gCapconInterface.status.cycleTimeAutoMode < config.cycleTimeToStopAutoMode2 THEN
						this.hmi.enableAutoMode := TRUE;	
					END_IF
				
				3:
					IF gCapconInterface.status.cycleTimeAutoMode < config.cycleTimeToStopAutoMode3 THEN
						this.hmi.enableAutoMode := TRUE;	
					END_IF
	
				
				4:
					IF gCapconInterface.status.cycleTimeAutoMode < config.cycleTimeToStopAutoMode4 THEN
						this.hmi.enableAutoMode := TRUE;	
					END_IF	
		
				
				ELSE
					IF gCapconInterface.status.cycleTimeAutoMode < config.cycleTimeToStopAutoMode4 THEN
						this.hmi.enableAutoMode := TRUE;	
					END_IF	
		
			
			END_CASE
			
		END_IF
		
		// If operator changes CountSpeeds don't auto trigger enableAutoMode. We believe that operator will tune the machine and don't want to trigger AutoMode in the middle of his work.
		IF CFCountSpeed <> gVibratorInterface[0].status.countingSpeed OR LFCountSpeed <> gVibratorInterface[1].status.countingSpeed THEN
			this.changeOverTriggered := FALSE;
		END_IF
		
	END_IF
	
	// TEMP FIX BECAUSE BIG BOWL HASNT BEEN IMPLEMENTED YET
	IF gVibratorInterface[0].parameter.machineSize = 1 THEN
		this.hmi.enableAutoMode := FALSE;
	END_IF
	
	CASE em.mode OF
		MODE_PRODUCING: producing;
		MODE_CALIBRATING: calibrating;
		ELSE em.cmd.sc := TRUE;
	END_CASE
		
	alarm;
	
	em();
	

	motionControl;
	this.MC_LimitLoad_0();
	axis();

	interface.status.calibratingMode := this.hmi.calibrating.activate;
	interface.status.actualPosition := ABS(axis.status.actPosition);
	interface.status.autoMode := this.hmi.enableAutoMode;
	
	// copy the recipe data
	CASE interface.cmd.copyRecipe OF
	
		COPY_RECIPE_NEXT_TO_WORKING: 
			this.hmi.recipe 			:= this.hmi.recipeCurrent;
			gRecipe.cmd.save 			:= TRUE;
			this.changeOverCounter 		:= this.changeOverCounter + 1;
//			this.BrickInfo_0.Reset := TRUE;
//			this.BrickInfo_0();
//			this.LFController_0.Enable := FALSE;
//			this.LFController_0();
//			CFCountSpeed := 20;
//			LFCountSpeed := 40;
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
			
		COPY_RECIPE_SANDBOX_TO_NEXT: 
			interface.cmd.copyRecipe 	:= COPY_RECIPE_NONE;
	
	END_CASE
	
	// ----------------------- TODO TEST THIS !!!! ------------------------------------
	// vibrator -> belt. We have changeover and recipe values has been updated. Init with recipe parameters and reset VibratorController.
	IF interface.cmd.changeover THEN
		interface.cmd.changeover := FALSE;
		
		CFCountSpeed := gVibratorInterface[0].status.countingSpeed;
		LFCountSpeed := gVibratorInterface[1].status.countingSpeed;
		this.BrickInfo_0.Reset := TRUE;
		this.BrickInfo_0();
		this.CFController_0.Enable := FALSE;
		this.CFController_0();
		this.LFController_0.Enable := FALSE;
		this.LFController_0();
		IF gVibratorInterface[0].parameter.machineSize <> 1 AND config.enableAutoModeFeature THEN // Not Big Machine and auto mode enabled
			gCapconInterface.status.cycleTimeAutoMode := 0;
			interface.cmd.cycleTimeCount := 0; // to make sure we don't disable autoMode right aways
			this.CFController_0.LFOffset := LIMIT(0,LFCountSpeed-CFCountSpeed,10); // use the offset from recipe but limit it.
			this.changeOverTriggered := TRUE;
		END_IF
	END_IF
	
	IF interface.cmd.initRecipe THEN
		interface.cmd.initRecipe := FALSE;
		
		recipe.countingSpeed := LIMIT(350,recipe.countingSpeed,450);
		recipe.waitSpeed := LIMIT(100,recipe.waitSpeed,150);
		recipe.rampUp := 100;
		recipe.rampDown := 30;
	ELSIF interface.cmd.putRecipeForStalkElement THEN
		interface.cmd.putRecipeForStalkElement := FALSE;
		
		recipe.rampUp := 100;
		recipe.rampDown := 0;
		recipe.countingSpeed := 440;
		recipe.waitSpeed := 120;
		recipe.useWaitSpeed := TRUE;
	END_IF
	
	IF gRecipe.status.doCheckForChanges AND NOT this.oldCheckChangesRecipe THEN
		// chek if it has been loade then update old
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
	
	IF axis.status.error.fault THEN
		this.alarm.axisError.active	:= TRUE;
	ELSE
		this.alarm.axisError.active	:= FALSE;
	END_IF
	
	IF gConfig.status.factoryReset[2] THEN
		gConfig.status.factoryReset[2] := FALSE;
		// Factory reset all parameters:
		config.maxTorqueAllowed := 0.7; //0.7nm
	END_IF
	
	this.hmi.waitSpeedDisabled := NOT recipe.useWaitSpeed;
	
END_PROGRAM

PROGRAM _EXIT

	this.MpRecipeRegPar_Recipe(Enable := FALSE);
	this.MpRecipeRegPar_Config(Enable := FALSE);
	this.MpRecipeRegPar_RecipeCurrent(Enable := FALSE);
	
	this.MTDataMean_torque(Enable := FALSE);
	this.MC_LimitLoad_0(Enable := FALSE);
	this.MTBasicsLimiter_0(Enable := FALSE);
	 
END_PROGRAM