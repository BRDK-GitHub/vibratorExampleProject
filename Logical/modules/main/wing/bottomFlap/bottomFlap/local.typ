
TYPE
	local_typ : 	STRUCT 
		alarm : local_alarm_typ;
		hw : local_hw_typ;
		hwAir : local_hw_typ;
		hwWu : ARRAY[0..1]OF wu20_typ;
		time : local_time_typ;
		neighbourFlap : legoCM20Flap;
		flap : legoCM20Flap;
		hmi : local_hmi_typ;
		flapTest : flapTest_typ;
		localShaftMode : gBottomShaftMode_typ;
		timeWaitForCasstte : UDINT; (*Only for statistics to see how long we wait for cassettes*)
		WingSync_0 : WingSync;
		old_neighbourActive : BOOL;
		cycleTimeTheoretical : UDINT;
		runningAlone : BOOL;
		test : local_test_typ;
		previousState : UINT;
		bottomFlapTime : UDINT;
		manuelState : USINT;
		OeeCalc_0 : OeeCalc;
		TON_test : TON;
	END_STRUCT;
	local_test_typ : 	STRUCT 
		state : USINT;
	END_STRUCT;
	wu20_typ : 	STRUCT 
		flapPosition : DINT; (*4 = open, 8 = closed*)
		neighbourFlapPosition : DINT; (*4 = open, 8 = closed*)
		neighbourActive : BOOL;
		neigbourIsDosing : BOOL;
		neighbourPortionReady : BOOL;
		di_wingUnitActive : BOOL;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		neighbourActive : BOOL;
		forceEmpty : BOOL; (*If operator force an empty even though we have a brick in bottom flap.*)
		portionCycleTime : REAL;
	END_STRUCT;
	local_hw_typ : 	STRUCT 
		di_neighbourChangeover : BOOL;
		do_neighbourOpen : BOOL;
		di_changeover : BOOL;
		do_open : BOOL;
		di_neighbourPortionReady : BOOL; (*Signal name: DI_WU_NFMRDY
PJ95: WU_S
Connector: DI.16
Description: Signal from neighbour CM. �1� indicates elements are ready on neighbour middle flap. Utilized for synchronization shaft with neighbour CM. Only relevant if DI_WU_NCON is active.*)
		do_neighbourPortionReady : BOOL; (*Signal name: DO_WU_NFMRDY
PJ95: WU_S
Connector: DO.16
Description: Signal to neighbour CM. �1� means elements are ready on middle flap. Utilized for synchronization shaft with neighbour CM.*)
		di_neighbourActive : BOOL; (*Signal name: DI_WU_NCON
PJ95: WU_S
Connector: DI.18
Description: Signal from neighbour CM. �1� indicates a neighbour CM is connected and active.*)
		di_neigbourIsDosing : BOOL;
	END_STRUCT;
	local_alarm_typ : 	STRUCT 
		openTooLong : gAlarm_struct_typ;
		closeTooLong : gAlarm_struct_typ;
		openNeighbourTooLong : gAlarm_struct_typ;
		closeNeighbourTooLong : gAlarm_struct_typ;
		neighbourNotActive : gAlarm_struct_typ;
	END_STRUCT;
	flapTest_typ : 	STRUCT 
		flapSequenceTest : BOOL; (*Flaps will run in a sequence (usually over night)*)
		openTime : UDINT;
		closingTime : UDINT;
		neighbourOpenTime : UDINT;
		neighbourClosingTime : UDINT;
		waitTime : UDINT := 200000;
		alarmOpenTooLong : BOOL;
		alarmCloseTooLong : BOOL;
		openTimeOK : BOOL;
		closingTimeOK : BOOL;
		neighbourOpenTimeOK : BOOL;
		neighbourClosingTimeOK : BOOL;
	END_STRUCT;
END_TYPE
