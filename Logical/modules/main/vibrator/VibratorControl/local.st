
PROGRAM _INIT

	FOR i:=0 TO NUM_VIBRATOR DO
		this ACCESS ADR(localVariables[i]);
		config ACCESS ADR(localVariables[i].config);
		
		// gets the task name and setup names for config and receipe types
		ST_name(0,ADR(this.configName),0);
		brdkStrCat(ADR(this.configName),ADR(':localVariables['));
		brdkStrAppendUdintToA(i,ADR(this.configName),0,-1);
		brdkStrCat(ADR(this.configName),ADR('].config'));
		
		this.VibFeedback_0.VibratorType := i;
		this.VibControl_0.VibratorType := i; // i=0=CF , i=1=LF
		this.Accelerometer_0.VibratorType := i; // i=0=CF , i=1=LF
		this.MpRecipeRegPar_Config.Enable := TRUE;
		config.emptyPercent := SEL(i=0,110,50);
		gVibratorInterface[i].cmd.emptyPercent := config.emptyPercent;
	END_FOR
	
END_PROGRAM

PROGRAM _CYCLIC
	
	FOR i:=0 TO NUM_VIBRATOR DO
		this ACCESS ADR(localVariables[i]);
		config ACCESS ADR(localVariables[i].config);
		hmi ACCESS ADR(localHmi[i]);
		
		modules;
	END_FOR
	
	// Watch Idx
	i := LIMIT(0, watchIdx, NUM_VIBRATOR);
	this ACCESS ADR(localVariables[i]);
	hmi ACCESS ADR(localHmi[i]);
	config ACCESS ADR(localVariables[i].config);
	
	
END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

