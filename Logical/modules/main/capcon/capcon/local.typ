
TYPE
	counters_data_typ : 	STRUCT 
		itemAfterCounting : UDINT;
		itemCountToFew : UDINT;
		itemCountToMany : UDINT;
		itemSizeToLarge : UDINT;
		itemSizeToSmall : UDINT;
		okCount : UDINT;
	END_STRUCT;
	local_updateHMIandRecord : 	STRUCT 
		MpDataRegPar : ARRAY[0..19]OF MpDataRegPar;
		state : USINT;
		updateCmd : BOOL;
		length : DINT;
		lengthNew : DINT;
		startIdx : DINT;
		record : local_record_typ;
	END_STRUCT;
	recipe_capcon_typ : 	STRUCT 
		controlPrcOld : USINT := 55; (*%*)
		brickCount : USINT := 1;
		controlPrc : USINT := 55;
		controlPrcIdx : USINT := 2;
		capconMode : USINT := 0; (*0: On, 1: Medium, 2: Off*)
	END_STRUCT;
	local_typ : 	STRUCT 
		hmi : hmi_typ;
		alarm : local_alarm_typ;
		MpRecipeRegPar_Config : MpRecipeRegPar;
		MpRecipeRegPar_Recipe : MpRecipeRegPar;
		MpRecipeRegPar_RecipeCurrent : MpRecipeRegPar;
		time : local_time_typ;
		integral : REAL;
		samples : UDINT;
		topAvgSignal : REAL;
		emptyRejectCount : USINT;
		TON_timeout : TON;
		configOld : config_capcon_typ;
		recipeOld : recipe_capcon_typ;
		useTeachCount : UDINT;
		sumStatistik : REAL;
		timeBetweenBricks : UDINT;
		newRecipeLoaded : BOOL;
		dropTimeIdx : USINT;
		droptimes : ARRAY[0..100]OF REAL;
		wingOldReady : BOOL;
		controlOld : USINT;
		names : local_names_typ;
		inCommingCount : INT;
		peakCount : USINT;
		moreThan2Peaks : BOOL; (*Capcon signal have more than 2 peaks. ONLY topMax strategy is valid if signal have > 1 peak*)
		rejectInPortion : BOOL; (*True if at least 1 reject in the portion. Will be reset after each portion.*)
		brickCount : USINT;
		TON_waitTime : TON;
		brickPresent : BOOL;
		lastPortionOK : BOOL;
		brickCountTeached : USINT; (*Brick count that we teached with.*)
		timeBrickIsFalling : TIME := T#400ms;
		pctFromMeanToLimit : ARRAY[0..MAX_PCT_FROM_MEAN]OF REAL;
		MTDataStatistics_Teach : MTDataStatistics;
		MTDataStatistics_0 : MTDataStatistics;
		MTDataStatistics_1 : MTDataStatistics;
		countGoodPortionForTeach : USINT;
		errorTeachCounter : USINT;
		newTeachMean : REAL;
		TeachIntegral_0 : TeachIntegral;
		startTime : UDINT;
		totalTime : UDINT;
		MTFilterMovingAverage_0 : MTFilterMovingAverage;
		noAdaptiveTeaching : UDINT;
		lastAfterCount : BOOL;
		oldCheckChangesConfig : BOOL;
		oldCheckChangesRecipe : BOOL;
		oldLoaded : BOOL;
		oldLoadedRecipe : BOOL;
		MTFilterMovingAverage_1 : MTFilterMovingAverage;
	END_STRUCT;
	hmi_typ : 	STRUCT 
		config : config_capcon_typ;
		recipe : recipe_capcon_typ;
		actualBrickInPortion : UDINT;
		count : local_hmi_count_typ;
		totalCount : local_hmi_count_typ;
		previusError : STRING[80];
		lastError : STRING[80];
		pcsPerMin : REAL;
		tmu : REAL;
		ultilityPercent : REAL;
		integral : REAL;
		samples : UDINT;
		topAvgSignal : REAL;
		redoTeaching : BOOL;
		maxSpeedNoise : REAL;
		recipeCurrent : recipe_capcon_typ;
		capconModeMedium : BOOL;
		capconModeOff : BOOL;
		capconModeOn : BOOL;
		cycleTimeTMU : REAL;
		cycleTime : REAL;
		teaching : BOOL;
		capconMax : REAL;
		capconMin : REAL;
		capconMean : REAL;
		capconVariance : REAL;
		integralSum : REAL;
	END_STRUCT;
	local_time_typ : 	STRUCT 
		elapsed : UDINT;
		maximum : UDINT;
	END_STRUCT;
	local_names_typ : 	STRUCT 
		configName : STRING[80];
		recipeName : STRING[80];
		recipeNameCurrent : STRING[80];
	END_STRUCT;
	local_record_typ : 	STRUCT 
		avgSignalData : ARRAY[0..CAPCON_LOG_SAMPLE_SIZE]OF REAL;
		avgSpeedData : ARRAY[0..CAPCON_LOG_SAMPLE_SIZE]OF REAL;
		rawData : ARRAY[0..CAPCON_LOG_SAMPLE_SIZE]OF INT;
		avgSignalPoints : ARRAY[0..2]OF REAL;
		avgSpeedPoints : ARRAY[0..2]OF REAL;
		idxPoints : ARRAY[0..2]OF DINT;
		integral : REAL;
		samples : UDINT;
		topAvgSignal : REAL;
		validation : local_element_validation_typ;
		count : UDINT;
	END_STRUCT;
	local_peak_typ : 	STRUCT 
		currentNettime : DINT;
		start : local_peak_point_typ;
		top : local_peak_point_typ;
		end : local_peak_point_typ;
		count : REAL;
		buffers : local_peak_buffer_typ;
		internalCount : USINT;
		internalRejectCount : USINT;
	END_STRUCT;
	local_peak_point_typ : 	STRUCT 
		nettime : DINT;
		value : REAL;
	END_STRUCT;
	local_peak_buffer_typ : 	STRUCT 
		live : ARRAY[0..99]OF REAL; (*tmp live data buffer to be copied to peak buffer*)
		peak : ARRAY[0..99]OF REAL; (*buffer containing the last detected peak, time starts from 0 and ends with peakTimespan [ms]*)
		peakCountdownCpy : DINT; (*samples to wait before copying live to get a top more er less in the middle*)
		peakTimespan : UDINT; (*Timespan of the peak buffer in ms*)
		peakCursor2 : UDINT; (*Time of cursor 2 (peak end point) in ms from peak buffer start*)
		peakCursor1 : UDINT; (*Time of cursor 1 (peak end point) in ms from peak buffer start*)
	END_STRUCT;
	local_element_validation_typ : 
		(
		CAPCON_VALIDATION_NONE := 0,
		CAPCON_VALIDATION_ACCEPT := 1,
		CAPCON_VAL_REJECT_SAMP_TOO_SMALL := 2,
		CAPCON_VAL_REJECT_SAMP_TOO_BIG := 3,
		CAPCON_VAL_REJECT_PEAK_TOO_SMALL := 4,
		CAPCON_VAL_REJECT_PEAK_TOO_BIG := 5,
		CAPCON_VAL_REJECT_INT_TOO_SMALL := 6,
		CAPCON_VAL_REJECT_INT_TOO_BIG := 7,
		CAPCON_VAL_REJECT_INVALID := 8,
		CAPCON_VAL_REJECT_AFTER_COUNT := 9,
		CAPCON_VAL_REJECT_TIMEOUT := 10,
		CAPCON_VAL_REJECT_TOO_MANY := 11
		) := CAPCON_VALIDATION_NONE;
	local_hmi_count_item_typ : 	STRUCT 
		percent : REAL;
		count : UDINT;
	END_STRUCT;
	local_hmi_count_min_max_item_typ : 	STRUCT 
		tooSmallPercent : REAL;
		tooBigPercent : REAL;
		tooSmall : UDINT;
		tooBig : UDINT;
	END_STRUCT;
	local_hmi_count_typ : 	STRUCT 
		reject : local_hmi_count_item_typ;
		portions : local_hmi_count_item_typ;
		integral : local_hmi_count_min_max_item_typ;
		afterCounting : local_hmi_count_item_typ;
		invalidBuffer : local_hmi_count_item_typ;
		total : UDINT;
	END_STRUCT;
	config_capcon_typ : 	STRUCT 
		noStopDelay : UDINT := 100; (*[ms] delay between two bricks that there is time to turn the reject system*)
		simSampleDelay : UDINT := 150; (*[ms] delay to when the sampleing is starting*)
		capconNoiseAllowedPeakToPeak : REAL := 55; (*[mV] noise we allow on passive capcon signal before throwing alarm.*)
		capconDcOffsetAllowed : REAL := 800; (*[mV] tolerance for DC-offset on signal before making an alarm*)
		logToFile : BOOL := FALSE;
		capconNoiseAllowedSpeed : REAL := 2000;
		factorRmsMax : REAL := 0.001;
		capconMinThreshold : REAL := 100.0;
		portionsAllowTeach : USINT := 10;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		teachingError : gAlarm_struct_typ;
	END_STRUCT;
	BUFFER_BRICK_STATE : 
		(
		BUFFER_BRICK_END,
		BUFFER_BRICK_MIDDLE,
		BUFFER_BRICK_START
		);
END_TYPE
