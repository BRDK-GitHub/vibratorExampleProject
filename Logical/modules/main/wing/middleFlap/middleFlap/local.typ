
TYPE
	local_typ : 	STRUCT 
		hw : local_hw_typ;
		hwAir : local_hw_typ;
		hwWu : ARRAY[0..1]OF wu20_typ; (*Communication with wing unit*)
		alarm : local_alarm_typ;
		time : local_time_typ;
		flap : legoCM20Flap;
		flapTest : flapTest_typ;
		MTDataStatistics_Real : MTDataStatistics;
		cycleTime : REAL;
		calculateCycletime : BOOL;
		hmi : local_hmi_typ;
		cycleTimeReal : REAL;
		cycleTimeTheoretical : UDINT;
		test : local_test_typ;
		previousState : UINT;
		middleFlapTime : UDINT;
		ItemSize : ITEM_SIZE_enum;
		TON_test : TON;
	END_STRUCT;
	ITEM_SIZE_enum : 
		( (*Default large*)
		Large := 0,
		Small := 1
		);
	wu20_typ : 	STRUCT 
		flapPosition : DINT; (*4 = open, 8 = closed*)
		di_wingUnitActive : BOOL;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		realMeanOutput : REAL;
		cycleTimeRaw : REAL;
		portionCycleTime : REAL;
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
