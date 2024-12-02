
TYPE
	local_typ : 	STRUCT 
		time : local_time_typ;
		waitingTime : waiting_time_typ;
		flap : legoCM20Flap;
		alarm : local_alarm_typ;
		hwAir : local_hw_typ;
		hw : local_hw_typ;
		hwWu : ARRAY[0..1]OF wu20_typ; (*Communication with wing unit*)
		flapTest : flapTest_typ;
		hmi : local_hmi_typ;
		afterCount : BOOL;
		rejectNext : BOOL;
		cycleTimeTheoretical : UDINT;
		test : local_test_typ;
		errBuffer_0 : errBuffer;
		previousState : UINT;
		oldTeachingDone : BOOL;
		upperFlapCycleTime : UDINT;
		MTFilterMovingAverage_0 : MTFilterMovingAverage;
		MTFilterMovingAverage_10 : MTFilterMovingAverage;
		MTFilterMovingAverage_10_TMU : MTFilterMovingAverage;
		lastUpperFlapCycleTime : UDINT;
		TON_test : TON;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		errorRate : REAL;
		cycleTime : REAL; (*moving avg of 40*)
		cycleTimeHMI : REAL; (*moving avg of 10*)
		cycleTimeTMU : REAL;
		cycleTimeRaw : REAL;
		rejectAll : BOOL;
	END_STRUCT;
	wu20_typ : 	STRUCT 
		flapPosition : DINT; (*4 = open, 8 = closed*)
		di_wingUnitActive : BOOL;
	END_STRUCT;
	waiting_time_typ : 	STRUCT 
		current : UDINT; (*[us]*)
		average : UDINT; (*[us]*)
		count : USINT;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		di_changeover : BOOL;
		do_open : BOOL;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		openTooLong : gAlarm_struct_typ;
		closeTooLong : gAlarm_struct_typ;
	END_STRUCT;
	flapTest_typ : 	STRUCT 
		flapSequenceTest : BOOL; (*Flaps will run in a sequence (usually over night)*)
		openTime : UDINT;
		closingTime : UDINT;
		waitTime : UDINT := 200000;
		alarmOpenTooLong : BOOL;
		alarmCloseTooLong : BOOL;
		openTimeOK : BOOL;
		closingTimeOK : BOOL;
	END_STRUCT;
	local_test_typ : 	STRUCT 
		state : USINT;
	END_STRUCT;
END_TYPE
