
TYPE
	legocm20_flap_internal_typ : 	STRUCT  (*Flap internal variables.*)
		state : DINT; (*State of the function block.*)
		timeElapsed : UDINT; (*Time elapsed.*)
		startMeasTimeOpenClose : BOOL;
		avgOpenTime : MTFilterMovingAverage;
		avgCloseTime : MTFilterMovingAverage;
		openTimeMaxCnt : USINT;
		closeTimeMaxCnt : USINT;
		openCloseTime : UDINT;
	END_STRUCT;
	legocm20_flap_position_typ : 
		( (*Flap positions.*)
		FLAP_OPENING_BEFORE_CHANGEOVER := 1, (*Before changeover.*)
		FLAP_OPENING_AT_CHANGEOVER := 3, (*At changeover.*)
		FLAP_OPEN := 4, (*Open.*)
		FLAP_CLOSEING_BEFORE_CHANGEOVER := 5, (*Before changeover.*)
		FLAP_CLOSEING_AT_CHANGEOVER := 7, (*At changeover.*)
		FLAP_CLOSED := 8 (*Closed.*)
		);
	LEGO_SPEED_ENUM : 
		(
		lego_speed_stop := 0,
		lego_speed_wait := 1,
		lego_speed_counting := 2
		);
END_TYPE
