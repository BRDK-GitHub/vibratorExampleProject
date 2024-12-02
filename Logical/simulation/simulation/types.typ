
TYPE
	local_feeder_typ : 	STRUCT 
		activated : BOOL;
		var : local_feeder_var_typ;
		hw : local_feeder_hw_typ;
	END_STRUCT;
	local_feeder_var_typ : 	STRUCT 
		TOF_levelSensorOn : TOF;
		TON_levelSensorOff : TON;
		TON_0 : TON;
		flapSpeed : REAL;
		stateFlap : USINT;
	END_STRUCT;
	local_feeder_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_FEEDER]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_FEEDER]OF brdkSimOutput;
	END_STRUCT;
	local_vibrator_typ : 	STRUCT 
		activated : BOOL;
		var : local_vibrator_var_typ;
		hw : local_vibrator_hw_typ;
	END_STRUCT;
	local_vibrator_var_typ : 	STRUCT 
		TON_sensor : TON;
		flapSpeed : REAL;
		state : USINT;
	END_STRUCT;
	local_vibrator_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_VIBRATOR]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_VIBRATOR]OF brdkSimOutput;
	END_STRUCT;
	local_belt_typ : 	STRUCT 
		activated : BOOL;
		usePWMforSim : BOOL;
		var : local_belt_var_typ;
		hw : local_belt_hw_typ;
	END_STRUCT;
	local_belt_var_typ : 	STRUCT 
		convPosition : REAL;
		TON_sensor : TON;
		convSpeed : REAL;
		state : UINT;
		brickLength : REAL := 20;
		brickStart : REAL;
		gapLength : REAL := 50;
		brickGap : REAL;
		gapLengthVarMax : UDINT;
		gapLengthVarMin : UDINT;
		gapVariancePrc : REAL := 0.3;
		gapStart : REAL;
		brickEnd : REAL;
		bricksAtEdgeIdx : UINT;
		bricksAtEdge : ARRAY[0..299]OF REAL;
		percentToSpeed : REAL := 1;
	END_STRUCT;
	local_belt_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_BELT]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_BELT]OF brdkSimOutput;
	END_STRUCT;
	local_capcon_typ : 	STRUCT 
		activated : BOOL;
		var : local_capcon_var_typ;
		hw : local_capcon_hw_typ;
	END_STRUCT;
	local_capcon_var_typ : 	STRUCT 
		i : UINT;
		j : UINT;
		oldSensor : UDINT;
		state : USINT;
		line : STRING[1000000];
		data : ARRAY[0..99]OF local_capcon_var_data_typ;
		setInputValue : INT;
		setInputValueR : REAL;
		beltPosition : REAL;
		signalIdx : UINT;
		signals : ARRAY[0..299]OF INT;
		x : REAL;
		currSignal : REAL;
		signalHeight : REAL := 1000;
		errorRate : REAL := 0.0;
		rejects : ARRAY[0..299]OF BOOL;
	END_STRUCT;
	local_capcon_var_data_typ : 	STRUCT 
		brick : ARRAY[0..499]OF INT;
	END_STRUCT;
	local_capcon_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_CAPCON]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_CAPCON]OF brdkSimOutput;
	END_STRUCT;
	local_wing_typ : 	STRUCT 
		activated : BOOL;
		var : local_wing_var_typ;
		hw : local_wing_hw_typ;
	END_STRUCT;
	local_wing_var_typ : 	STRUCT 
		oldVal : ARRAY[0..MAX_WINGS]OF UDINT;
		TON_delay : ARRAY[0..MAX_WINGS]OF TON;
		TOF_changeOver : ARRAY[0..MAX_WINGS]OF TOF;
	END_STRUCT;
	local_wing_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_WING]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_WING]OF brdkSimOutput;
	END_STRUCT;
	local_cassette_typ : 	STRUCT 
		activated : BOOL;
		var : local_cassette_var_typ;
		hw : local_cassette_hw_typ;
	END_STRUCT;
	local_cassette_var_typ : 	STRUCT 
		cassetteInPlace : BOOL;
		tonDelay : TON := (PT:=T#0ms);
		state : USINT;
		toReadyTime : TIME := T#560ms;
		fromReadyTime : TIME := T#67ms;
		fromQueueTime : TIME := T#300ms;
		cassetteQueueTime : TIME := T#1s;
		tofDelay : TOF;
	END_STRUCT;
	local_cassette_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_CASSETTE]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_CASSETTE]OF brdkSimOutput;
	END_STRUCT;
	local_external_typ : 	STRUCT 
		activated : BOOL;
		var : local_external_var_typ;
		hw : local_external_hw_typ;
	END_STRUCT;
	local_external_var_typ : 	STRUCT 
		dummy : USINT;
	END_STRUCT;
	local_external_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_EXTERNAL]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_EXTERNAL]OF brdkSimOutput;
	END_STRUCT;
	local_vision_typ : 	STRUCT 
		activated : BOOL;
		var : local_vision_var_typ;
		hw : local_vision_hw_typ;
	END_STRUCT;
	local_vision_var_typ : 	STRUCT 
		New_Member : USINT;
	END_STRUCT;
	local_vision_hw_typ : 	STRUCT 
		in : ARRAY[0..MAX_INPUT_VISION]OF brdkSimInput;
		out : ARRAY[0..MAX_OUTPUT_VISION]OF brdkSimOutput;
	END_STRUCT;
END_TYPE
