
TYPE
	gCapconInterface_typ : 	STRUCT 
		cmd : gCapconInterface_cmd_typ;
		status : gCapconInterface_status_typ;
		parameter : gCapconInterface_par_typ;
		config : gCapconInterface_config_typ;
	END_STRUCT;
	gCapconInterface_config_typ : 	STRUCT 
		speedMinLimit : REAL; (*indicates the speed min limit for when you are sure that a brick has passed through*)
		speedMaxLimit : REAL; (*indicates the speed max limit for when you are sure that a brick has passed through*)
		noStopDelay : UDINT; (*[ms] delay between two bricks that there is time to turn the reject system*)
		simSampleDelay : UDINT := 150; (*[ms] delay to when the sampleing is starting*)
		brickIncomingTimeout : UDINT := 1000; (*[ms] timeout signal from when a brick was incomming*)
		capconNoiseAllowedPeakToPeak : REAL := 55; (*[mV] noise we allow on passive capcon signal before throwing alarm.*)
		capconDcOffsetAllowed : REAL := 800; (*[mV] tolerance for DC-offset on signal before making an alarm*)
		logToFile : BOOL;
		capconNoiseAllowedSpeed : REAL;
	END_STRUCT;
	gCapconInterface_cmd_typ : 	STRUCT 
		resetCounters : BOOL;
		startLogging : BOOL;
		portionIncomming : BOOL;
		brickIncomming : BOOL;
		calculateStatistics : BOOL;
		skipTeach : BOOL;
		emptyStop : BOOL;
		wingReady : BOOL;
		wingRequest : BOOL;
		wingCmdAck : BOOL;
		startTeaching : BOOL;
		emptyWhileTeaching : BOOL;
		copyRecipe : copy_recipe_command_typ;
		reTeach : BOOL;
		startSpeedSignalTest : BOOL;
	END_STRUCT;
	teach_status_typ : 	STRUCT 
		maxSpeed : ARRAY[0..CAPCON_TEACH_BRICK_COUNT]OF REAL;
		integral : ARRAY[0..CAPCON_TEACH_BRICK_COUNT]OF REAL;
		topAvgSignal : ARRAY[0..CAPCON_TEACH_BRICK_COUNT]OF REAL;
		samples : ARRAY[0..CAPCON_TEACH_BRICK_COUNT]OF UDINT;
		brickDetected : BOOL;
	END_STRUCT;
	gCapconInterface_par_limit_typ : 	STRUCT 
		maxSamples : UDINT;
		minSamples : UDINT;
		maxTop : REAL;
		minTop : REAL;
		maxIntegral : REAL;
		minIntegral : REAL;
	END_STRUCT;
	gCapconInterface_par_typ : 	STRUCT 
		limits : gCapconInterface_par_limit_typ;
		teachBrickCount : UDINT := 0;
		count : UDINT;
		controlPercent : USINT;
		simSampleDelay : UDINT;
		brickCount : USINT;
		capconMode : USINT;
	END_STRUCT;
	gCapconInterface_status_typ : 	STRUCT 
		ready : BOOL;
		teach : teach_status_typ;
		teachingDone : BOOL;
		waiting : BOOL;
		cycleTime : UDINT;
		reset : BOOL;
		wingStartBrickNOK : BOOL;
		wingStartBrickOK : BOOL;
		state : brdk_em_states_typ;
		wingDosing : BOOL;
		numBricksInPortion : UDINT;
		maxNoiseSpeed : REAL;
		integralSum : REAL;
		brickDetected : BOOL;
		brickPresent : BOOL;
		noPeaks : USINT;
		noVerifiedPeaks : USINT;
		teachIntegral : REAL;
		adaptiveTeachIntegral : REAL;
		noAdaptiveVerifiedPeaks : USINT;
		wingStart : BOOL;
		verifiedPeakCount : ARRAY[0..MAX_PEAKS]OF USINT;
		peakIntegral : ARRAY[0..MAX_PEAKS]OF REAL;
		factorRmsMax : REAL;
		capconMinThreshold : REAL;
		cycleTimeAutoMode : REAL;
		maxRawSignal : REAL;
	END_STRUCT;
	gCapconBufferResult_typ : 	STRUCT 
		samples : UDINT;
		integral : REAL;
		topAvgSignal : REAL;
		done : BOOL;
		peakValue : ARRAY[0..CAPCON_MAX_PEAK_COUNT]OF REAL;
		maxSpeed : REAL;
		peakCount : USINT;
	END_STRUCT;
	gCapcon_buffer_typ : 	STRUCT 
		sample : ARRAY[0..CAPCON_MAX_BUFFER_SIZE]OF gCapcon_buffer_sample_typ;
		idx : DINT;
		topIdx : ARRAY[0..CAPCON_MAX_PEAK_COUNT]OF DINT;
		startIdx : DINT;
		endIdx : DINT;
		active : BOOL;
		invalid : BOOL;
		startTopSampleRange : DINT;
		endTopSampleRange : DINT;
		new : BOOL;
		notAbrick : BOOL;
		nextBrick : BOOL;
		result : gCapconBufferResult_typ;
		nextBrickStart : INT;
	END_STRUCT;
	gCapcon_buffer_sample_typ : 	STRUCT 
		avgSpeed : REAL;
		avgSignal : REAL;
		raw : INT;
	END_STRUCT;
END_TYPE
