
ACTION motionControl: 

	// Production code to control amplitude/frequency,
	// Change frequency / amplitude depending what vibPercent is
	
	// never ramp on circular feeder
	localVariables[0].hmi.recipe.rampUp := 0;
	
	// vibrators can have ramp up time. 
	this.vibPercentAmplitude := LIMIT(0,this.vibPercentAmplitude,180);
	
	this.MTBasicsLimiter_0.Enable 	:= TRUE;
	this.rampUp 					:= (this.vibPercentAmplitude)/(UDINT_TO_REAL(MAX(1,recipe.rampUp))/1000);
	this.MTBasicsLimiter_0.Update 	:= (NOT this.MTBasicsLimiter_0.UpdateDone AND (this.MTBasicsLimiter_0.MaxPosSlewRate <> this.rampUp));
			
	IF this.MTBasicsLimiter_0.Update THEN
		this.MTBasicsLimiter_0.MaxPosSlewRate := this.rampUp;
	END_IF

	this.MTBasicsLimiter_0.MinOut 	:= 0;
	this.MTBasicsLimiter_0.MaxOut 	:= 130; 
	this.MTBasicsLimiter_0.In 		:= this.vibPercentAmplitude;
	this.MTBasicsLimiter_0();

	this.vibAcceleration			:= getAccelerationFromPercent(this.MTBasicsLimiter_0.Out,i,gVibratorInterface[0].status.machineType);
	this.linearizationTable.InX		:= this.vibAcceleration;
	this.linearizationTable();
	IF recipe.countingSpeed > 0 AND interface.cmd.speed <> lego_speed_stop AND this.vibPercentAmplitude <> 0 THEN
		interface.status.vibAmplitude 			:= this.linearizationTable.Out;
		interface.status.percent				:= this.vibPercentAmplitude;
	ELSE
		interface.status.vibAmplitude := interface.status.percent := 0;
	END_IF
	interface.status.vibAmplitudePercent	:= this.vibPercentAmplitude;
	

	
	
	IF recipe.waitSpeed=0 AND interface.cmd.speed = lego_speed_wait THEN
		interface.cmd.speed := lego_speed_stop;
	ELSE
		// Update frequency depending on vibAmplitude
		this.lookUpFrequency.InX 		:= interface.status.vibAmplitude;
		this.lookUpFrequency();
		this.vibFrequency 				:= this.lookUpFrequency.Out;
		interface.status.vibFrequency 	:= LIMIT(0,this.vibFrequency,54);
	END_IF
					
	
END_ACTION


ACTION caliMotionControl: 

	IF this.vibPercentAmplitude=0 THEN
		this.vibFrequency := this.oldVibPercentAmplitude := this.vibAmplitude := 0;
	ELSIF this.vibPercentAmplitude <> this.oldVibPercentAmplitude THEN
		this.vibPercentAmplitude := LIMIT(0,this.vibPercentAmplitude,180);
		this.oldVibPercentAmplitude := this.vibPercentAmplitude;
						
		// Update amplitude depending on %
		this.vibAcceleration		:= getAccelerationFromPercent(this.vibPercentAmplitude,i,gVibratorInterface[0].status.machineType);
		this.linearizationTable.InX := this.vibAcceleration;
		this.linearizationTable();
		this.vibAmplitude := this.linearizationTable.Out;
		// Update frequency depending on vibAmplitude
		this.lookUpFrequency.InX := this.vibAmplitude;
		this.lookUpFrequency();
		this.vibFrequency := this.lookUpFrequency.Out;
		this.vibFrequency := LIMIT(0,this.vibFrequency,54);
		
//		interface.status.vibAmplitude 			:= this.vibAmplitude;

	END_IF

END_ACTION
