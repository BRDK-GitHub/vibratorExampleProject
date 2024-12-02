
PROGRAM _INIT
	
	// index 0 is the circular vibrator
	// index 1 is the linear vibrator
	
	FOR i := 0 TO NUM_VIBRATOR DO

		setupPointers;
		
		em.setup.lastActivated := TRUE;
		em.setup.parent.name := 'main';
		
		CASE i OF
			
			0:
				em.setup.name := 'CircularFeeder';
				axis.configuration.axis := ADR(gAxisVibC);
				axis.configuration.description := em.setup.name;
			
			1:
				em.setup.name := 'LinearFeeder';
				axis.configuration.axis := ADR(gAxisVibL);
				axis.configuration.description := em.setup.name;

		END_CASE

		axis.configuration.ignoreSwLimit := TRUE;
		axis.configuration.disableTorqueReading := TRUE;
		axis.configuration.disableLagErrorReading := TRUE;
		axis.configuration.disableTemperatureReading := TRUE;
		axis.configuration.disableVelocityReading := TRUE;
		
		axis.parameter.acceleration := axis.parameter.deceleration := 5000000;
		
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
		
		em();
		axis();
		this.alarm.axisError.name := SEL(i=0, 'linearFeederAxisFault', 'circularFeederAxisFault'); // create alarm names
	
	END_FOR
	this.hw;
	
END_PROGRAM

PROGRAM _CYCLIC

	FOR i := 0 TO NUM_VIBRATOR DO
		
		setupPointers;
				
		CASE em.mode OF
			MODE_PRODUCING:	producing; // state code for mode producing
			MODE_CALIBRATING: calibratingMode;
			ELSE em.cmd.sc := TRUE;
		END_CASE
		
		alarm;
		
		em(); // call the mocule
		axis();
	
		// Mapping to sineWaveGen task
		interface.status.powered := axis.status.powerOn;
		
		IF gConfig.status.doCheckForChanges AND NOT this.oldCheckChangesConfig THEN
			// chek if it has been loade then update old
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
		
		
		(* beeing able to watch the referenced variable *)
		watchIdx := LIMIT(0, watchIdx, NUM_VIBRATOR);
		this ACCESS ADR(localVariables[watchIdx]);
		em ACCESS ADR(localModule[watchIdx]);
		interface ACCESS ADR(gVibratorInterface[watchIdx]);
		config ACCESS ADR(localVariables[watchIdx].hmi.config);
		configTmp ACCESS ADR(localVariables[watchIdx].configTmp);
		axis ACCESS ADR(localAxis[watchIdx]);
		hmi ACCESS ADR(localHmi[watchIdx]);
	END_FOR
	 
	em_status[0].state		:= localModule[0].state;
	em_status[0].substate	:= localModule[0].status.substate;
	em_status[1].state		:= localModule[1].state;
	em_status[1].substate	:= localModule[1].status.substate;
	
END_PROGRAM

PROGRAM _EXIT
	
	FOR i:=0 TO NUM_VIBRATOR DO
		setupPointers;
		this.MpRecipeRegPar_Config(Enable := FALSE);
	END_FOR
	 
END_PROGRAM

