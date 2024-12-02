
TYPE
	brdk_mc_para_hwinputs_typ : 	STRUCT  (*HW inputs*)
		homeReference : brdk_mc_para_hwinputs_di_typ; (*Home switch*)
		negHwLimit : brdk_mc_para_hwinputs_di_typ; (*Negative hw limit switch*)
		posHwLimit : brdk_mc_para_hwinputs_di_typ; (*Positive hw limit switch*)
		trigger1 : brdk_mc_para_hwinputs_di_typ; (*Trigger switch*)
		trigger2 : brdk_mc_para_hwinputs_di_typ; (*Trigger switch*)
	END_STRUCT;
	brdk_mc_para_hwinputs_di_typ : 	STRUCT  (*HW input commands*)
		input : BOOL; (*Manipulates switch in the drive if useExternalInput is TRUE*)
		useExternalInput : BOOL; (*Get the input from a digital input module or PLC*)
	END_STRUCT;
	brdk_mc_command_typ : 	STRUCT  (*Commands*)
		power : BOOL; (*Power on drive*)
		home : BOOL; (*Home axis*)
		moveAbsolute : BOOL; (*Move to position*)
		moveAdditive : BOOL; (*Move distance*)
		moveVelocity : BOOL; (*Move with speed*)
		halt : BOOL; (*Halt movement*)
		stop : BOOL; (*Stop movement*)
		jogPositive : BOOL; (*Jog in positive direction*)
		jogNegative : BOOL; (*Jog in negative direction*)
		gearIn : BOOL; (*Connect slave axis to master axis*)
		gearOut : BOOL; (*Disconnect master and slave axes*)
		limitLoad : BOOL; (*Limits the motor torque*)
		errorAcknowledge : BOOL; (*Acknowledge error at rising edge*)
		updatePeriod : BOOL; (*Update axis factor and period, done automatically at axis bootup*)
		simulateError : BOOL; (*Trigger a simulated axis error*)
		resetTorqueStatus : BOOL; (*Reset torque statistics*)
		newBatAcknowledge : BOOL; (*Acknowledge battery excange - Only for AcoposMicro with Endat 2.2*)
	END_STRUCT;
	brdk_mc_status_typ : 	STRUCT  (*Status*)
		state : Status_enum; (*Current PLCopen state*)
		actVelocity : REAL; (*Actual velocity [PLCopen units/s]*)
		actPosition : REAL; (*Actual position [PLCopen units]*)
		actLagError : REAL; (*Actual position lag error [PLCopen units] if configuration factor set > 0 else in [units]*)
		actTorque : REAL; (*Actual torque [Nm]*)
		torque : brdk_mc_status_torque_typ; (*Extended torque readout*)
		powerOn : BOOL; (*Axis is powered on*)
		isHomed : BOOL; (*Axis is homed*)
		inMotion : BOOL; (*Axis is in motion or geared in to a master axis*)
		stopped : BOOL; (*Axis is stopped using the command stop and is at standstill*)
		done : BOOL; (*Specified command done*)
		busy : BOOL; (*Specified command is executed and active*)
		updateDone : BOOL; (*UpdatePeriod command done*)
		error : brdk_mc_status_error_typ; (*Error status information*)
		driveStatus : brdk_mc_status_drive_status_typ; (*Drive status information*)
		encoderBatteryStatus : brdk_mc_enc_bat_status_typ; (*Status of encoder battery - Only for AcoposMicro with Endat 2.2*)
		axisDescription : STRING[30]; (*Defined axis desciption*)
	END_STRUCT;
	brdk_mc_status_drive_status_typ : 	STRUCT  (*Drive status*)
		simulation : BOOL; (*If TRUE, simulation mode is active for the drive.*)
		initialized : BOOL; (*If TRUE, the network is initialized.*)
		homeSwitch : BOOL; (*If TRUE, the digital reference switch input is active.*)
		posLimitSwitch : BOOL; (*If TRUE, the positive hardware limit switch is active.*)
		negLimitSwitch : BOOL; (*If TRUE, the negative hardware limit switch is active.*)
		trigger1 : BOOL; (*If TRUE, the first trigger input is active.*)
		trigger2 : BOOL; (*If TRUE, the second trigger input is active.*)
		driveEnable : BOOL; (*If TRUE, the enable input is in use.*)
		controllerReady : BOOL; (*If TRUE, the controller is ready to be turned on.*)
		lagWarning : BOOL; (*If TRUE, the lag error has exceeded the limit value specified for a warning (limit.parameter.ds_warning).*)
	END_STRUCT;
	brdk_mc_status_error_text_typ : 	STRUCT  (*Error text*)
		active : ARRAY[0..4]OF STRING[363]; (*Active fault descriptions*)
		last : ARRAY[0..4]OF STRING[363]; (*Last reset faults descriptions*)
	END_STRUCT;
	brdk_mc_status_error_typ : 	STRUCT  (*Error status*)
		fault : BOOL; (*Fault present on axis*)
		count : UINT; (*Number of faults*)
		text : brdk_mc_status_error_text_typ; (*Error message*)
	END_STRUCT;
	brdk_mc_status_torque_typ : 	STRUCT  (*Torque status*)
		actual : REAL; (*Actual torque 0.5 sec average [Nm]*)
		continous : REAL; (*Continous peak torque 5 sec average [Nm]*)
		peak : REAL; (*Peak torque 0.5 sec average [Nm]*)
	END_STRUCT;
	brdk_mc_internal_typ : 	STRUCT  (*internal*)
		MC_BR_CyclicRead_1 : MC_BR_CyclicRead;
		MC_MoveVelocity_0 : MC_MoveVelocity;
		MC_Reset_0 : MC_Reset;
		MC_Home_0 : MC_Home;
		MC_Halt_0 : MC_Halt;
		MC_Stop_0 : MC_Stop;
		MC_Power_0 : MC_Power;
		MC_BR_Simulation_0 : MC_BR_Simulation;
		MC_ReadActualPosition_0 : MC_ReadActualPosition;
		MC_ReadStatus_0 : MC_ReadStatus;
		MC_ReadActualVelocity_0 : MC_ReadActualVelocity;
		MC_GearIn_0 : MC_GearIn;
		MC_GearOut_0 : MC_GearOut;
		MC_MoveAdditive_0 : MC_MoveAdditive;
		MC_MoveAbsolute_0 : MC_MoveAbsolute;
		MC_ReadActualTorque_0 : MC_ReadActualTorque;
		MC_BR_ReadDriveStatus_0 : MC_BR_ReadDriveStatus;
		MC_BR_ReadAxisError_0 : MC_BR_ReadAxisError;
		MC_BR_AxisErrorCollector_0 : MC_BR_AxisErrorCollector;
		MC_BR_GetHardwareInfo_0 : MC_BR_GetHardwareInfo;
		MC_BR_SetHardwareInputs_0 : MC_BR_SetHardwareInputs;
		MC_BR_InitAxisSubjectPar_0 : MC_BR_InitAxisSubjectPar;
		MC_BR_CyclicRead_0 : MC_BR_CyclicRead;
		MC_BR_ReadParID_3 : MC_BR_ReadParID;
		MC_BR_ReadParID_2 : MC_BR_ReadParID;
		MC_BR_ReadParID_1 : MC_BR_ReadParID;
		MC_BR_ReadParID_0 : MC_BR_ReadParID;
		MC_BR_InitModPos_0 : MC_BR_InitModPos;
		MC_BR_CommandError_0 : MC_BR_CommandError;
		MC_BR_WriteParID_1 : MC_BR_WriteParID;
		MC_BR_WriteParID_0 : MC_BR_WriteParID;
		MC_LimitLoad_0 : MC_LimitLoad;
		encoderReset : UDINT;
		old_hardwareInput : brdk_mc_para_hwinputs_typ;
		encoderStatus : UDINT;
		encoderType : USINT;
		strcat_adr : UDINT;
		string2 : STRING[8];
		tmpErrorString : STRING[324];
		tmpErrorCount : UINT;
		tmpErrorID : STRING[5];
		tmpErrorArray : ARRAY[0..3]OF STRING[80];
		i : USINT;
		oldParID : UINT;
		oldErrorID : UINT;
		substate : USINT;
		tmpNumberOfErrors : UINT;
		filterBase : ARRAY[0..1]OF REAL;
		RTInfo : RTInfo;
		calcActualValueTemp_old : REAL;
		calcActualValueTemp : REAL;
		calcActualValue_old : ARRAY[0..1]OF REAL;
		calcActualValue : ARRAY[0..1]OF REAL;
		filterTime : ARRAY[0..1]OF REAL;
		stateMotor : USINT;
		filterBaseTemp : REAL;
		filterTimeTemp : REAL;
		TON_error_read_delay : TON;
		k : USINT;
		batteryState : bat_state_enum;
		acoposMicroBatMon : BOOL;
		tmpDriveStatus : MC_DRIVESTATUS_TYP;
		initialized : BOOL;
	END_STRUCT;
	brdk_mc_parameter_typ : 	STRUCT  (*Parameters*)
		position : REAL; (*Position for an absolute movement [PLCopen units]*)
		distance : REAL; (*Distance for an additive movement [PLCopen units]*)
		velocity : REAL; (*Movement velocity [PLCopen units/s] *)
		acceleration : REAL; (*Acceleration [PLCopen units/s²]*)
		deceleration : REAL; (*Deceleration [PLCopen units/s²]*)
		decelerationFault : REAL; (*Deceleration at axis fault [PLCopen units/s²]*)
		direction : USINT; (*Movement direction:
mcPOSITITVE_DIR ... 0

mcNEGATIVE_DIR ... 1

mcCURRENT_DIR ... 2

mcSHORTEST_WAY ... 3

mcEXCEED_PERIOD ... 8*)
		loadLimit : REAL; (*Torque load limit [Nm]*)
		homePosition : REAL; (*Home position, position after homing [PLCopen units]*)
		homeMode : USINT; (*Homing mode:
mcHOME_ABS_SWITCH (performs homing with absolute reference switch)

mcHOME_SWITCH_GATE (homing with reference switch gate)

mcHOME_LIMIT_SWITCH (homing with hardware limit switch)

mcHOME_DIRECT (direct homing without reference pulse)

mcHOME_REF_PULSE (direct homing with reference pulse)

mcHOME_ABSOLUTE (homing by setting the homing offset)

mcHOME_ABSOLUTE_CORR (homing by setting the homing offset with counting range correction)

mcHOME_DCM (homing using interval-encoded reference marks)

mcHOME_DCM_CORR (Homing using distance coded reference marks with counting range correction)

mcHOME_RESTORE_POS (restore position from permanent memory)

mcHOME_AXIS_REF (performs homing with the data from the axis structure)

mcHOME_BLOCK_TORQUE (performs homing to mechanical limit, torque as criteria)

mcHOME_BLOCK_DS (performs homing to mechanical limit, lag error value as criteria)*)
		ratioSlave : INT; (*Slave gear ratio*)
		ratioMaster : UINT; (*Master gear ration*)
		gearInMasterParID : UINT; (*This ParID is used instead of the position setpoint;
0 ... Use position setpoint*)
		gearInMasterParIDMaxVelocity : REAL; (*If this parameter is "0.0", the current velocity of the master axis is used. 
If a value is specified for "MasterParID": 
Maximum velocity of the master ParID value 

If a value is not specified for "MasterParID": 
Maximum velocity of the master axis [PLCopen units of master/s]*)
		errorSimulationCommand : USINT; (*0: Warning message reported 

1: Error message reported 

2: Error message reported and active movement aborted 

3: Error message reported, active movement aborted and controller switched off 

4: Error message reported, active movement ended with a speed-controlled ramp and controller switched off*)
		hwInput : brdk_mc_para_hwinputs_typ; (*Hardware input manipulation for home reference, triggers and limit switches*)
	END_STRUCT;
	brdk_mc_configuration_typ : 	STRUCT  (*Axis configuration*)
		masterAxis : UDINT; (*Master axis reference*)
		axis : UDINT; (*Axis reference*)
		errorTextObject : STRING[12]; (*Name of the acp10 error text object
If no name is entered, the default name 'acp10etxen' is assumed (table must be available in the project)*)
		description : STRING[30]; (*Optional: Axis description or name; added to the error texts*)
		factor : UDINT; (*Axis factor*)
		period : UDINT; (*Axis period*)
		ignoreSwLimit : USINT; (*Ignore software end limit positions (0: end limits active 1: ignore sw end limits)*)
		disableVelocityReading : BOOL; (*Disables actual velocity status readout*)
		disablePositionReading : BOOL; (*Disables actual position status readout*)
		disableTorqueReading : BOOL; (*Disables actual torque status readout*)
		disableTemperatureReading : BOOL; (*Disables actual motor temperature readout*)
		disableLagErrorReading : BOOL; (*Disables actual lag error status readout*)
	END_STRUCT;
	brdk_mc_info_typ : 	STRUCT  (*HW info*)
		startupPhase : STRING[100]; (*Drive startup phase information*)
		hw : brdk_mc_info_hw_typ; (*Hardware information*)
	END_STRUCT;
	brdk_mc_info_hw_typ : 	STRUCT  (*Hardware information*)
		drive : brdk_mc_info_hw_drive_typ; (*Motor type*)
		motor : brdk_mc_info_hw_motor_typ; (*Motors maximum torque [Nm]*)
	END_STRUCT;
	brdk_mc_info_hw_drive_typ : 	STRUCT  (*HW drive info*)
		model : STRING[32]; (*Drive model number*)
		serial : STRING[32]; (*Drive serial number*)
		card : ARRAY[0..3]OF brdk_mc_info_hw_card_typ; (*Plugin cards*)
	END_STRUCT;
	brdk_mc_info_hw_card_typ : 	STRUCT  (*HW card info*)
		model : STRING[32]; (*Model number*)
		serial : STRING[32]; (*Serial number*)
	END_STRUCT;
	brdk_mc_info_hw_motor_typ : 	STRUCT  (*Motor info*)
		model : STRING[32]; (*Motor type*)
		temperature : REAL; (*Motor temperature [C]*)
		torqueRated : REAL; (*Motors nominal torque [Nm]*)
		torqueMaximum : REAL; (*Motors maximum torque [Nm]*)
	END_STRUCT;
	brdk_mc_enc_bat_status_typ : 	STRUCT  (*Encoder battry information*)
		batteryOK : BOOL; (*Encoder battery is OK - Voltage OK and position valid*)
		batteryError : BOOL; (*Encoder battery NOT ok - voltage has dropped below threshhold. Posiion valid if PositionLost = false.*)
		batteryWarning : BOOL; (*Error has been acknowledged - battery not exchanged, position still valid*)
		positionLost : BOOL; (*Encoder postion has been lost due to battery failure*)
	END_STRUCT;
	state_enum : 
		(
		ST_INIT := 0,
		ST_WAIT := 1,
		ST_POWER_ON := 2,
		ST_HOME_AT_POWER_OFF := 3,
		ST_EXTERNAL_HW_INPUTS := 5,
		ST_UPDATE_FACTOR_PERIOD := 6,
		ST_READY := 10,
		ST_HOME := 20,
		ST_STOP := 30,
		ST_HALT := 31,
		ST_MOVE_ABSOLUTE := 40,
		ST_MOVE_ADDITIVE := 41,
		ST_MOVE_VELOCITY := 42,
		ST_GEAR_START := 50,
		ST_GEAR_STOP := 51,
		ST_IN_GEAR := 52,
		ST_JOG_POS := 60,
		ST_JOG_NEG := 61,
		ST_HALT_JOG := 62,
		ST_STOP_AFTER_ERROR := 100,
		ST_STOPPING_AFTER_ERROR := 101,
		ST_ERROR := 110,
		ST_CHECK_ERROR := 111,
		ST_ERROR_RESET := 120,
		ST_ENCODER_ERROR_RESET := 130
		);
	bat_state_enum : 
		(
		ST_BAT_OK := 0,
		ST_BAT_ERROR := 1,
		ST_BAT_WARNING := 2,
		ST_BAT_POS_LOST := 3
		);
	Status_enum : 
		(
		DISABLED := 0,
		STANDSTILL := 1,
		HOMING := 2,
		CONTINOUS_MOTION := 3,
		DISCRETE_MOTION := 4,
		SYNCHRONIZED_MOTION := 5,
		STOPPING := 6,
		ERROR_STOP := 10
		);
END_TYPE
