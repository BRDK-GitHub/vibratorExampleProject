FUNCTION_BLOCK  brdkMcBasic

	(* Access the axis structure *)
	pAxis ACCESS configuration.axis;

	(*********************** CHECK FOR ERRORS **************************)
	IF (state < ST_STOP_AFTER_ERROR) THEN
		IF (internal.MC_BR_AxisErrorCollector_0.Errorstop) THEN
			state := ST_ERROR;
		ELSIF (internal.MC_BR_AxisErrorCollector_0.FunctionBlockError) OR 
		   	  (internal.MC_BR_AxisErrorCollector_0.AxisError) OR 
			  (internal.MC_BR_AxisErrorCollector_0.AxisWarning) THEN
			status.busy := 0;
			status.done := 0;
			state 		:= ST_STOP_AFTER_ERROR;
		END_IF
	END_IF


	(***************** CHECK IF POWER SHOULD BE OFF *******************)
	IF (command.power = 0 AND state < ST_STOP_AFTER_ERROR AND state <> ST_HOME_AT_POWER_OFF AND state <> ST_INIT AND state <> ST_EXTERNAL_HW_INPUTS AND state <> ST_UPDATE_FACTOR_PERIOD) THEN
		status.busy := 0;
		status.done := 0;
		
		IF ((internal.MC_ReadStatus_0.Errorstop = 1) AND (internal.MC_ReadStatus_0.Valid = TRUE)) THEN
			state := ST_ERROR_RESET;
		ELSE
			state := ST_WAIT;
		END_IF
	END_IF
	

	(* Status Motion States *)
	IF internal.MC_ReadStatus_0.Disabled THEN
		status.state := DISABLED;
	ELSIF internal.MC_ReadStatus_0.StandStill THEN
		status.state := STANDSTILL;
	ELSIF internal.MC_ReadStatus_0.Homing THEN
		status.state := HOMING;
	ELSIF internal.MC_ReadStatus_0.Stopping THEN
		status.state := STOPPING;
	ELSIF internal.MC_ReadStatus_0.Errorstop THEN
		status.state := ERROR_STOP;
	ELSIF internal.MC_ReadStatus_0.DiscreteMotion THEN
		status.state := DISCRETE_MOTION;
	ELSIF internal.MC_ReadStatus_0.ContinuousMotion THEN
		status.state := CONTINOUS_MOTION;
	ELSIF internal.MC_ReadStatus_0.SynchronizedMotion THEN
		status.state := SYNCHRONIZED_MOTION;
	END_IF
	
	(* Limit load torque *)
	internal.MC_LimitLoad_0.Load		:= parameter.loadLimit;
	internal.MC_LimitLoad_0.Direction	:= parameter.direction;
	internal.MC_LimitLoad_0.Enable		:= command.limitLoad;

	
	(***************************************************************)
	(************************* MAIN CONTROL ************************)
	(***************************************************************)

	(* check for stop command *)
	IF command.stop AND state <> ST_INIT AND state <> ST_WAIT AND state <> ST_POWER_ON AND state <> ST_UPDATE_FACTOR_PERIOD AND state <> ST_HOME_AT_POWER_OFF AND state <> ST_EXTERNAL_HW_INPUTS AND state <> ST_STOP AND state < 100 THEN
		internal.MC_Stop_0.Deceleration	:= parameter.deceleration;
		internal.MC_Stop_0.Execute 		:= 1;
		state := ST_STOP;
	END_IF
	
	
	CASE state OF

		(****************** STARTING DRIVE *****************)
		ST_INIT:
			CASE internal.substate OF
				0:				
					IF pAxis.network.phase = 90 THEN
						internal.substate := 10;	
					END_IF
			
				10:	(* initialize factor and period *)
					internal.MC_BR_InitModPos_0.Factor	:= configuration.factor;
					internal.MC_BR_InitModPos_0.Period	:= configuration.period;		
					internal.MC_BR_InitModPos_0.Execute	:= TRUE;
							
					IF internal.MC_BR_InitModPos_0.Done THEN
						internal.MC_BR_InitModPos_0.Execute := FALSE;
						internal.substate					:= 20;
					END_IF
				
				20: (* set end limit ignore *)
					internal.MC_BR_WriteParID_1.ParID		:= ACP10PAR_SGEN_SW_END_IGNORE;
					internal.MC_BR_WriteParID_1.DataType	:= ncPAR_TYP_USINT;
					internal.MC_BR_WriteParID_1.DataAddress	:= ADR(configuration.ignoreSwLimit);
					internal.MC_BR_WriteParID_1.Execute		:= TRUE;
					
					IF internal.MC_BR_WriteParID_1.Done THEN
						internal.MC_BR_WriteParID_1.Execute := FALSE;
						internal.initialized				:= TRUE;
						internal.substate 					:= 0;
						state 								:= ST_WAIT;	
					END_IF
					internal.MC_BR_WriteParID_1(Axis := configuration.axis);
			END_CASE
				
					
		(******************** WAIT *************************)
		ST_WAIT: (* STATE: Wait *)
		
			(* reset status *)
			status.busy   		:= 0;
			status.done 		:= 0;
			status.updateDone 	:= 0;

			(* reset user commands *)
			command.stop 			:= 0;
			command.halt 			:= 0;
			command.moveVelocity	:= 0;
			command.moveAbsolute	:= 0;
			command.moveAdditive	:= 0;
			command.gearIn 			:= 0;
			command.gearOut			:= 0;
			command.jogPositive		:= 0;
			command.jogNegative		:= 0;
			
			(* reset all fb execute inputs we use *)
			internal.MC_Home_0.Execute 					:= 0;
			internal.MC_Stop_0.Execute 					:= 0;
			internal.MC_Halt_0.Execute 					:= 0;
			internal.MC_MoveAbsolute_0.Execute 			:= 0;
			internal.MC_MoveAdditive_0.Execute 			:= 0;
			internal.MC_MoveVelocity_0.Execute 			:= 0;
			internal.MC_GearIn_0.Execute 				:= 0;
			internal.MC_GearOut_0.Execute 				:= 0;
			internal.MC_BR_ReadAxisError_0.Acknowledge	:= 0;
			internal.MC_Reset_0.Execute 				:= 0;
			internal.substate 							:= 0;
			
			IF (command.power) THEN
				state := ST_POWER_ON;
			ELSE
				internal.MC_Power_0.Enable := 0;
			END_IF
			
			(* wait for homing command *)
			IF (command.home) THEN
				internal.MC_Home_0.Position 	:= parameter.homePosition;
				internal.MC_Home_0.HomingMode 	:= parameter.homeMode;
				internal.MC_Home_0.Execute 		:= 1;	
				state 							:= ST_HOME_AT_POWER_OFF;
			END_IF
		
			(* initialize factor and period *)
			IF command.updatePeriod THEN	
				internal.MC_BR_InitModPos_0.Axis 	:= configuration.axis;
				internal.MC_BR_InitModPos_0.Factor	:= configuration.factor;
				internal.MC_BR_InitModPos_0.Period	:= configuration.period;		
				internal.MC_BR_InitModPos_0.Execute	:= TRUE;
				state 								:= ST_UPDATE_FACTOR_PERIOD;
			END_IF			
			
			(* check if external inputs has been changed *)	
			IF parameter.hwInput.homeReference.useExternalInput <> internal.old_hardwareInput.homeReference.useExternalInput OR 
			   parameter.hwInput.negHwLimit.useExternalInput <> internal.old_hardwareInput.negHwLimit.useExternalInput OR
			   parameter.hwInput.posHwLimit.useExternalInput <> internal.old_hardwareInput.posHwLimit.useExternalInput OR
			   parameter.hwInput.trigger1.useExternalInput <> internal.old_hardwareInput.trigger1.useExternalInput OR
			   parameter.hwInput.trigger2.useExternalInput <> internal.old_hardwareInput.trigger2.useExternalInput THEN
				IF parameter.hwInput.homeReference.useExternalInput <> internal.old_hardwareInput.homeReference.useExternalInput THEN
					IF parameter.hwInput.homeReference.useExternalInput THEN
						pAxis.dig_in.level.reference.5 := pAxis.dig_in.level.reference.8 := 1;
					ELSE
						pAxis.dig_in.level.reference.5 := pAxis.dig_in.level.reference.8 := 0;
					END_IF
				END_IF
				IF parameter.hwInput.negHwLimit.useExternalInput <> internal.old_hardwareInput.negHwLimit.useExternalInput THEN
					IF parameter.hwInput.negHwLimit.useExternalInput THEN
						pAxis.dig_in.level.neg_hw_end.5 := pAxis.dig_in.level.neg_hw_end.8 := 1;
					ELSE
						pAxis.dig_in.level.neg_hw_end.5 := pAxis.dig_in.level.neg_hw_end.8 := 0;
					END_IF
				END_IF
				IF parameter.hwInput.posHwLimit.useExternalInput <> internal.old_hardwareInput.posHwLimit.useExternalInput THEN
					IF parameter.hwInput.posHwLimit.useExternalInput THEN
						pAxis.dig_in.level.pos_hw_end.5 := pAxis.dig_in.level.pos_hw_end.8 := 1;
					ELSE
						pAxis.dig_in.level.pos_hw_end.5 := pAxis.dig_in.level.pos_hw_end.8 := 0;
					END_IF
				END_IF
				IF parameter.hwInput.trigger1.useExternalInput <> internal.old_hardwareInput.trigger1.useExternalInput THEN
					IF parameter.hwInput.trigger1.useExternalInput THEN
						pAxis.dig_in.level.trigger1.5 := pAxis.dig_in.level.trigger1.8 := 1;
					ELSE
						pAxis.dig_in.level.trigger1.5 := pAxis.dig_in.level.trigger1.8 := 0;
					END_IF
				END_IF
				IF parameter.hwInput.trigger2.useExternalInput <> internal.old_hardwareInput.trigger2.useExternalInput THEN
					IF parameter.hwInput.trigger2.useExternalInput THEN
						pAxis.dig_in.level.trigger2.5 := pAxis.dig_in.level.trigger2.8 := 1;
					ELSE
						pAxis.dig_in.level.trigger2.5 := pAxis.dig_in.level.trigger2.8 := 0;
					END_IF
				END_IF
				
				internal.old_hardwareInput.homeReference.useExternalInput 	:= parameter.hwInput.homeReference.useExternalInput;
				internal.old_hardwareInput.negHwLimit.useExternalInput 		:= parameter.hwInput.negHwLimit.useExternalInput;
				internal.old_hardwareInput.posHwLimit.useExternalInput 		:= parameter.hwInput.posHwLimit.useExternalInput;
				internal.old_hardwareInput.trigger1.useExternalInput 		:= parameter.hwInput.trigger1.useExternalInput;
				internal.old_hardwareInput.trigger2.useExternalInput 		:= parameter.hwInput.trigger2.useExternalInput;
				state 														:= ST_EXTERNAL_HW_INPUTS;
			END_IF
			
			(* check if drive was initialized *)
			IF NOT internal.initialized	THEN
				internal.substate := 0;
				state 			  := ST_INIT;
			END_IF
				
			
		(******************** POWER ON **********************)
		ST_POWER_ON: (* STATE: Power on *)
			internal.MC_Power_0.Enable := 1;
			IF (internal.MC_Power_0.Status = 1) THEN
				state := ST_READY;
			END_IF
			
			(* check if error occured *)
			IF (internal.MC_Power_0.Error) THEN
				internal.MC_Power_0.Enable := 0;
				state := ST_WAIT;
			END_IF


		(******************** HOME AT POWER OFF *************)
		ST_HOME_AT_POWER_OFF: (* STATE: start homing process *)
			(* check if functionblock is busy *)
			status.busy := internal.MC_Home_0.Busy;
				
			(* if axis homed go to state ready *)	
			status.done := internal.MC_Home_0.Done;
	
			(* return to ready state *)
			IF NOT command.home THEN
				status.busy := 0;
				status.done := 0;
				internal.MC_Home_0.Execute := 0;
				state := ST_WAIT;
			END_IF	
		
			
		(********* setup EXTERNAL HW INPUTS **************)	
		ST_EXTERNAL_HW_INPUTS:	
			(* check if functionblock is busy *)
			status.busy := internal.MC_BR_InitAxisSubjectPar_0.Busy;
				
			(* check if command is done *)	
			status.done := internal.MC_BR_InitAxisSubjectPar_0.Done;
			
			internal.MC_BR_InitAxisSubjectPar_0.Execute := TRUE;
			
			IF internal.MC_BR_InitAxisSubjectPar_0.Done THEN
				internal.MC_BR_InitAxisSubjectPar_0.Execute := FALSE;
				state 										:= ST_WAIT;
			END_IF
		
			
		(********* UPDATE period AND factor **************)		 
		ST_UPDATE_FACTOR_PERIOD:
			status.updateDone := internal.MC_BR_InitModPos_0.Done AND internal.MC_BR_WriteParID_1.Done;	
			
			IF internal.MC_BR_InitModPos_0.Done THEN
				internal.MC_BR_WriteParID_1.ParID		:= ACP10PAR_SGEN_SW_END_IGNORE;
				internal.MC_BR_WriteParID_1.DataType	:= ncPAR_TYP_USINT;
				internal.MC_BR_WriteParID_1.DataAddress	:= ADR(configuration.ignoreSwLimit);
				internal.MC_BR_WriteParID_1.Execute		:= TRUE;
			END_IF
			
			IF NOT command.updatePeriod THEN
				internal.MC_BR_WriteParID_1.Execute	:= FALSE;
				internal.MC_BR_InitModPos_0.Execute := FALSE;
				state 	 							:= ST_WAIT;
			END_IF	
			
										
		(******************** READY **********************)
		ST_READY: (* STATE: Waiting for commands *)
			IF command.home AND NOT internal.MC_Home_0.CommandAborted THEN
				internal.MC_Home_0.Position 	:= parameter.homePosition;
				internal.MC_Home_0.HomingMode 	:= parameter.homeMode;
				state := ST_HOME;

			ELSIF command.halt AND NOT internal.MC_Halt_0.CommandAborted THEN
				internal.MC_Halt_0.Deceleration	:= parameter.deceleration;
				state := ST_HALT;

			ELSIF command.moveAbsolute AND NOT internal.MC_MoveAbsolute_0.CommandAborted THEN
				internal.MC_MoveAbsolute_0.Position		:= parameter.position;
				internal.MC_MoveAbsolute_0.Velocity		:= parameter.velocity;
				internal.MC_MoveAbsolute_0.Acceleration	:= parameter.acceleration;
				internal.MC_MoveAbsolute_0.Deceleration	:= parameter.deceleration;
				internal.MC_MoveAbsolute_0.Direction	:= parameter.direction;
				state := ST_MOVE_ABSOLUTE;

			ELSIF command.moveAdditive AND NOT internal.MC_MoveAdditive_0.CommandAborted THEN
				internal.MC_MoveAdditive_0.Distance		:= parameter.distance;
				internal.MC_MoveAdditive_0.Velocity		:= parameter.velocity;
				internal.MC_MoveAdditive_0.Acceleration	:= parameter.acceleration;
				internal.MC_MoveAdditive_0.Deceleration	:= parameter.deceleration;
				state := ST_MOVE_ADDITIVE;

			ELSIF command.moveVelocity AND NOT internal.MC_MoveVelocity_0.CommandAborted THEN
				internal.MC_MoveVelocity_0.Velocity		:= parameter.velocity;
				internal.MC_MoveVelocity_0.Acceleration	:= parameter.acceleration;
				internal.MC_MoveVelocity_0.Deceleration	:= parameter.deceleration;
				internal.MC_MoveVelocity_0.Direction	:= parameter.direction;
				state := ST_MOVE_VELOCITY;
			
			ELSIF command.jogPositive AND NOT internal.MC_MoveVelocity_0.CommandAborted THEN
				internal.MC_MoveVelocity_0.Velocity		:= parameter.velocity;
				internal.MC_MoveVelocity_0.Acceleration	:= parameter.acceleration;
				internal.MC_MoveVelocity_0.Deceleration	:= parameter.deceleration;
				internal.MC_MoveVelocity_0.Direction	:= mcPOSITIVE_DIR;
				state := ST_JOG_POS;
				
			ELSIF command.jogNegative AND NOT internal.MC_MoveVelocity_0.CommandAborted THEN
				internal.MC_MoveVelocity_0.Velocity		:= parameter.velocity;
				internal.MC_MoveVelocity_0.Acceleration	:= parameter.acceleration;
				internal.MC_MoveVelocity_0.Deceleration	:= parameter.deceleration;
				internal.MC_MoveVelocity_0.Direction	:= mcNEGATIVE_DIR;
				state := ST_JOG_NEG;	
				
			ELSIF command.gearIn AND NOT internal.MC_GearIn_0.CommandAborted THEN
				internal.MC_GearIn_0.RatioNumerator			:= parameter.ratioSlave;
				internal.MC_GearIn_0.RatioDenominator		:= parameter.ratioMaster;
				internal.MC_GearIn_0.Acceleration			:= parameter.acceleration;
				internal.MC_GearIn_0.Deceleration			:= parameter.deceleration;
				internal.MC_GearIn_0.MasterParID 			:= parameter.gearInMasterParID;
				internal.MC_GearIn_0.MasterParIDMaxVelocity := parameter.gearInMasterParIDMaxVelocity;
				state := ST_GEAR_START;
			ELSIF command.gearOut THEN
			 	state := ST_GEAR_STOP;
			END_IF
			
			status.busy	:= 0;
			status.done := 0;
			
			internal.MC_Home_0.Execute			:= command.home;
			internal.MC_Halt_0.Execute			:= command.halt;
			internal.MC_MoveVelocity_0.Execute  := command.moveVelocity OR command.jogPositive OR command.jogNegative;
			internal.MC_MoveAbsolute_0.Execute 	:= command.moveAbsolute;
			internal.MC_MoveAdditive_0.Execute 	:= command.moveAdditive;
			internal.MC_GearIn_0.Execute 		:= command.gearIn;
			internal.MC_GearOut_0.Execute 		:= command.gearOut;
			

		(******************** HOME **********************)
		ST_HOME: (* STATE: start homing process *)
			(* check if functionblock is busy *)
			status.busy := internal.MC_Home_0.Busy;
				
			(* if axis homed go to state ready *)	
			status.done := internal.MC_Home_0.Done;
			
			(* return to ready state *)
			IF NOT command.home THEN
				status.busy := 0;
				status.done := 0;
				internal.MC_Home_0.Execute := 0;
				state := ST_READY;
			END_IF

				
		(*********************** STOP MOVEMENT *************************)
		ST_STOP: (* STATE: Stop movement *)
			(* check if commanded position is reached *)	
			status.done := 0;
			
			(* check if functionblock is busy *)
			status.busy := internal.MC_Stop_0.Busy;
			
			(* return to ready state *)
			IF NOT command.stop THEN
				status.busy 			:= 0;
				status.done 			:= 0;
				internal.MC_Stop_0.Execute := 0;
				state	 					 := ST_READY;
			END_IF


		(********************** HALT MOVEMENT *************************)
		ST_HALT: (* STATE: Halt movement *)
			(* check if halt is done, velocity zero *)	
			status.done := internal.MC_Halt_0.Done;
			
			(* check if functionblock is busy *)
			status.busy := internal.MC_Halt_0.Busy;
			
			(* return to ready state *)
			IF NOT command.halt THEN
				status.busy 				:= 0;
				status.done 				:= 0;
				internal.MC_Halt_0.Execute 	:= 0;
				state	 					:= ST_READY;
			END_IF


		(******************** START ABSOLUTE MOVEMENT **********************)
		ST_MOVE_ABSOLUTE: (* STATE: Start absolute movement *)
			(* check if commanded position is reached *)	
			status.done := internal.MC_MoveAbsolute_0.Done;
			
			(* check if functionblock is busy *)
			status.busy := internal.MC_MoveAbsolute_0.Busy;
			
			(* return to ready state *)
			IF NOT command.moveAbsolute THEN
				status.busy 						:= 0;
				status.done 						:= 0;
				internal.MC_MoveAbsolute_0.Execute  := 0;
				state	 							:= ST_READY;
			END_IF


		(******************** START ADDITIVE MOVEMENT **********************)
		ST_MOVE_ADDITIVE: (* STATE: Start additive movement *)
			(* check if commanded position is reached *)	
			status.done := internal.MC_MoveAdditive_0.Done;

			(* check if functionblock is busy *)
			status.busy := internal.MC_MoveAdditive_0.Busy;
			
			(* return to ready state *)
			IF NOT command.moveAdditive THEN
				status.busy 						:= 0;
				status.done 						:= 0;
				internal.MC_MoveAdditive_0.Execute 	:= 0;
				state	 							:= ST_READY;
			END_IF


		(******************** START VELOCITY MOVEMENT **********************)
		ST_MOVE_VELOCITY: (* STATE: Start velocity movement *)
			(* check if commanded velocity is reached *)	
			status.done := internal.MC_MoveVelocity_0.InVelocity;

			(* check if functionblock is busy *)
			status.busy := internal.MC_MoveVelocity_0.Busy;
			
			(* return to ready state *)
			IF NOT command.moveVelocity THEN
				status.busy 						:= 0;
				status.done 						:= 0;
				internal.MC_MoveVelocity_0.Execute 	:= 0;
				state	 							:= ST_READY;
			END_IF
	
			
		(*********************** JOGGING ******************************)
		ST_JOG_POS: (* STATE: Jogging in positive direction *)	
			(* check if functionblock is busy *)
			status.busy := internal.MC_MoveVelocity_0.Busy;
			
			(* return to ready state *)
			IF NOT command.jogPositive THEN
				status.busy 						:= 0;
				status.done 						:= 0;
				internal.MC_MoveVelocity_0.Execute 	:= 0;
				internal.MC_Halt_0.Deceleration		:= parameter.deceleration;
				internal.MC_Halt_0.Execute 			:= 1;
				state	 							:= ST_HALT_JOG;
			END_IF
			
		(*********************** JOGGING ******************************)
		ST_JOG_NEG: (* STATE: Jogging in positive direction *)	
			(* check if functionblock is busy *)
			status.busy := internal.MC_MoveVelocity_0.Busy;
			
			(* return to ready state *)
			IF NOT command.jogNegative THEN
				status.busy 						:= 0;
				status.done 						:= 0;
				internal.MC_MoveVelocity_0.Execute 	:= 0;
				internal.MC_Halt_0.Deceleration		:= parameter.deceleration;
				internal.MC_Halt_0.Execute 			:= 1;
				state	 							:= ST_HALT_JOG;
			END_IF
			
		(*********************** JOGGING ******************************)
		ST_HALT_JOG: (* STATE: Stopping jog movement *)	
			(* check if functionblock is busy *)
			IF internal.MC_Halt_0.Busy THEN
				internal.MC_Halt_0.Execute := 0;
				state	 				   := ST_READY;
			END_IF


		(******************* START GEAR MOVEMENT **********************)
		ST_GEAR_START: (* STATE: Start electronic gear coupling *)
			(* if axis is in gear go to ready state *)
			status.done := internal.MC_GearIn_0.InGear;
			
			IF NOT command.gearIn THEN
				status.done 					:= 0;
				internal.MC_GearIn_0.Execute 	:= 0;
				state 							:= ST_READY;		
			END_IF

			
		(******************** STOP GEAR MOVEMENT **********************)
		ST_GEAR_STOP: (* STATE: Stop electronic gear coupling *)
			(* check if coupling is stopped *)
			status.done := internal.MC_GearOut_0.Done;

			IF NOT command.gearOut THEN
				status.done 					:= 0;
				internal.MC_GearOut_0.Execute 	:= 0;
				state 							:= ST_READY;
			END_IF
			
			
		(****************** STOP MOVEMENT AFTER ERROR ********************)
		ST_STOP_AFTER_ERROR:
			IF 	(internal.MC_ReadStatus_0.ContinuousMotion) OR 
					(internal.MC_ReadStatus_0.DiscreteMotion) OR 
					(internal.MC_ReadStatus_0.SynchronizedMotion) OR 
					(internal.MC_ReadStatus_0.Homing) THEN
					
					IF parameter.decelerationFault = 0 THEN
						internal.MC_Stop_0.Deceleration	:= parameter.deceleration;
					ELSE
						internal.MC_Stop_0.Deceleration	:= parameter.decelerationFault;
					END_IF
					
					status.error.fault 		   := TRUE;
					internal.MC_Stop_0.Execute := 1;
					state					   := ST_STOPPING_AFTER_ERROR;
			ELSE
				state := ST_ERROR;
			END_IF
 
			
		(****************** STOPPING MOVEMENT AFTER ERROR ********************)
		ST_STOPPING_AFTER_ERROR:			 		
			(* check if stopped *)	
			IF internal.MC_Stop_0.Done THEN
				internal.MC_Stop_0.Execute := 0;
				state	 					 					 := ST_ERROR;
			ELSIF (internal.MC_Stop_0.Error) THEN
				internal.MC_Stop_0.Execute := 0;
				state	 					 					 := ST_ERROR;
			END_IF

			(* check if functionblock is busy *)
			IF internal.MC_Stop_0.Busy THEN
				status.busy := 1;
			END_IF

			
		(*************** CHECK AND ACKNOWLEDGE ERRORS ********************)
		ST_ERROR:
			(* reset all fb execute inputs we use *)
			IF internal.MC_Power_0.Error OR NOT command.power THEN
 				internal.MC_Power_0.Enable := 0;
			END_IF
			
			status.busy := 0;
			status.done := 0;
			
			internal.MC_Home_0.Execute 							:= 0;
			internal.MC_Stop_0.Execute 							:= 0;
			internal.MC_Halt_0.Execute							:= 0;			
			internal.MC_MoveAbsolute_0.Execute 					:= 0;
			internal.MC_MoveAdditive_0.Execute 					:= 0;
			internal.MC_MoveVelocity_0.Execute 					:= 0;
			internal.MC_GearIn_0.Execute 						:= 0;
			internal.MC_GearOut_0.Execute 						:= 0;
			internal.MC_BR_ReadAxisError_0.Acknowledge 			:= 0;
			internal.MC_Reset_0.Execute 						:= 0;
			internal.MC_BR_InitModPos_0.Execute					:= 0;	
			
			(* reset user commands *)
			command.stop 				 		:= 0;
			command.halt 		 				:= 0;
			command.home 		 				:= 0;
			command.moveVelocity				:= 0;
			command.moveAbsolute 				:= 0;
			command.moveAdditive 				:= 0;
			command.gearIn 		 				:= 0;
			command.gearOut						:= 0;		
			internal.TON_error_read_delay.IN	:= TRUE;
				
			(* Check for a valid error *)
			IF internal.MC_BR_ReadAxisError_0.Valid AND (internal.MC_BR_ReadAxisError_0.ErrorRecordAvailable OR internal.MC_BR_AxisErrorCollector_0.Errorstop) AND internal.TON_error_read_delay.Q THEN
				
				(* log error into array *)
				IF internal.tmpErrorCount < SIZEOF(status.error.text.active) / SIZEOF status.error.text.active[0] AND internal.MC_BR_ReadAxisError_0.ErrorRecord.Number <> 0 THEN
					(* add axis description to error text *)
					brsstrcpy(ADR(status.error.text.active[internal.tmpErrorCount]),ADR(configuration.description));			
					brsstrcat(ADR(status.error.text.active[internal.tmpErrorCount]), ADR(' - '));		
					
					(* add error id to error text *)							
					brsitoa(internal.MC_BR_ReadAxisError_0.ErrorRecord.Number,ADR(internal.tmpErrorID));									
					brsstrcat(ADR(status.error.text.active[internal.tmpErrorCount]), ADR(internal.tmpErrorID));	
					brsstrcat(ADR(status.error.text.active[internal.tmpErrorCount]),ADR(': '));
			
					(* add axis error text to error text *)
					internal.tmpErrorString := '';
					FOR internal.i := 0 TO SIZEOF(internal.tmpErrorArray)/SIZEOF(internal.tmpErrorArray[0])-1 DO
						IF brsstrlen(ADR(internal.tmpErrorArray[internal.i])) <> 0 THEN
							brsstrcat(ADR(internal.tmpErrorString),ADR(internal.tmpErrorArray[internal.i]));
							brsstrcat(ADR(internal.tmpErrorString),ADR('. '));
						ELSE
							EXIT;
						END_IF
					END_FOR									
					brsstrcat(ADR(status.error.text.active[internal.tmpErrorCount]),ADR(internal.tmpErrorString));		
				END_IF	
				
				(* acknowledge axis error *)
				IF (internal.MC_BR_ReadAxisError_0.AxisErrorCount + internal.MC_BR_ReadAxisError_0.AxisWarningCount + internal.MC_BR_ReadAxisError_0.FunctionBlockErrorCount > 0) THEN
					internal.MC_BR_ReadAxisError_0.Acknowledge  := TRUE;
				END_IF

				state := ST_CHECK_ERROR;
		
			ELSIF internal.MC_BR_ReadAxisError_0.Error AND internal.MC_BR_ReadAxisError_0.ErrorID = 29294 THEN		// Error that no error text table is available
				(* add axis description to error text *)
				brsstrcpy(ADR(status.error.text.active[internal.tmpErrorCount]),ADR(configuration.description));			
				brsstrcat(ADR(status.error.text.active[internal.tmpErrorCount]), ADR('- Unable to determine error text, axis error text table not found'));		
				state := ST_CHECK_ERROR;				
			END_IF

		
		(***************CHECK AND ACKNOWLEDGE ERRORS********************)
		ST_CHECK_ERROR:
			(* reset all fb execute inputs we use *)
			IF internal.MC_Power_0.Error OR NOT command.power THEN
 				internal.MC_Power_0.Enable := 0;
			END_IF
			
			IF (internal.MC_BR_ReadAxisError_0.Valid) THEN
				IF (internal.MC_BR_ReadAxisError_0.AxisErrorCount + internal.MC_BR_ReadAxisError_0.AxisWarningCount + internal.MC_BR_ReadAxisError_0.FunctionBlockErrorCount = 0) THEN
					status.error.fault 							:= TRUE;
					internal.MC_BR_ReadAxisError_0.Acknowledge  := FALSE;
					internal.tmpErrorCount						:= 0;
					
					(* COUNT ALL ERROR STRINGS IN ERROR ARRAY *)
					status.error.count := 0;	
					FOR internal.i := 0 TO SIZEOF(status.error.text.active)/SIZEOF(status.error.text.active[0])-1 DO 
						IF brsstrlen(ADR(status.error.text.active[internal.i])) <> 0 THEN
							status.error.count := status.error.count + 1;
						ELSE
							EXIT;
						END_IF
					END_FOR
					
					// wait for acknoledge command
					IF command.errorAcknowledge THEN		
						command.errorAcknowledge 	:= FALSE;
						status.error.fault 			:= FALSE;
						status.error.text.last 		:= status.error.text.active;		// copy active to last
						internal.TON_error_read_delay.IN	:= FALSE;
						brsmemset(ADR(status.error.text.active),0,SIZEOF(status.error.text.active)-1);	// clear active list
						status.error.count := 0;
						
						IF internal.batteryState = ST_BAT_ERROR THEN
							internal.batteryState := ST_BAT_WARNING;
						END_IF
						
						IF (internal.MC_ReadStatus_0.Errorstop) AND (internal.MC_ReadStatus_0.Valid) THEN
							state := ST_ERROR_RESET;
						ELSE
							IF pAxis.nc_obj_inf.nc_obj_typ = 4 OR pAxis.nc_obj_inf.net_if_typ = 129 THEN 
								state := ST_WAIT;
							ELSE
								state := ST_ENCODER_ERROR_RESET;
							END_IF
						END_IF
					END_IF
					
				(* check if a new errornumber or parid is present, then last error is acknowledged *)
				ELSIF internal.MC_BR_ReadAxisError_0.AxisErrorCount + internal.MC_BR_ReadAxisError_0.AxisWarningCount + internal.MC_BR_ReadAxisError_0.FunctionBlockErrorCount <> 0 THEN
					internal.MC_BR_ReadAxisError_0.Acknowledge	:= FALSE;
					internal.tmpErrorCount						:= internal.tmpErrorCount + 1;
					state 										:= ST_ERROR;
				END_IF
			END_IF
 
		(*****************RESET AXIS STATE ERRORSTOP********************)
		ST_ERROR_RESET:
			internal.MC_Reset_0.Execute 		:= TRUE;
			
			IF (internal.MC_Reset_0.Done) THEN
				internal.MC_Reset_0.Execute := 0;
				IF pAxis.nc_obj_inf.nc_obj_typ <> 1 OR pAxis.nc_obj_inf.net_if_typ = 129 THEN 	// 1 = Real axis	129 = sdc_type
					state := ST_WAIT;
				ELSE
					state := ST_ENCODER_ERROR_RESET;
				END_IF
			ELSIF (internal.MC_Reset_0.Error) THEN 
				internal.MC_Reset_0.Execute := 0;
				state 						:= ST_ERROR;
			END_IF
		
			
		(***************** RESETS ABSOLUTE ENCODER ERRORS ONLY ON ENDAT 2.2 ********************)
		ST_ENCODER_ERROR_RESET:
			
			CASE internal.substate OF
				0:
					internal.MC_BR_ReadParID_0.Execute 	:= FALSE;
					internal.substate 					:= 1;
					
				1:	// check encoder type 
					
					internal.MC_BR_ReadParID_0(Axis := configuration.axis, Execute := TRUE , ParID := ACP10PAR_ENCOD_TYPE , DataAddress := ADR(internal.encoderType) , DataType := ncPAR_TYP_USINT);
						
					IF internal.MC_BR_ReadParID_0.Done THEN
						internal.MC_BR_ReadParID_0.Execute 	:= FALSE;
						internal.substate 					:= 5;
					END_IF
					
					IF internal.MC_BR_ReadParID_0.Error THEN
						internal.MC_BR_ReadParID_0.Execute 	:= FALSE;
						internal.substate 					:= 0;
						state 			  					:= ST_WAIT;
					END_IF						
					
				5:	// check encoder type
					IF internal.encoderType = ncENDAT THEN
						internal.substate := 10;	
					ELSE
						internal.substate := 0;
						state 			  := ST_WAIT;
					END_IF
										
				10: // check for encoder alarm bit error
					
					internal.MC_BR_ReadParID_0(Axis := configuration.axis, Execute := TRUE , ParID := ACP10PAR_ENCOD_STATUS , DataAddress := ADR(internal.encoderStatus) , DataType := ncPAR_TYP_UDINT);
			
					IF internal.MC_BR_ReadParID_0.Done THEN
						internal.MC_BR_ReadParID_0.Execute 	:= FALSE;
						internal.substate 					:= 20;
					END_IF
					
					IF internal.MC_BR_ReadParID_0.Error THEN
						internal.MC_BR_ReadParID_0.Execute 	:= FALSE;
						internal.substate 					:= 0;
						state 			  					:= ST_WAIT;
					END_IF
				
				20:	// reset encoder alarm bit error if existing	
					internal.encoderReset	:= 1;
					
					(* check for encoder alarm bit set (bit 5)and encoder warning bit set (bit 8) *)
					IF internal.encoderStatus.5 AND NOT internal.MC_BR_WriteParID_0.Error THEN 
						internal.MC_BR_WriteParID_0(Axis := configuration.axis , Execute := TRUE, ParID := ACP10PAR_ENCOD_CMD, DataAddress := ADR(internal.encoderReset) , DataType := ncPAR_TYP_UDINT);
					
						IF internal.MC_BR_WriteParID_0.Done THEN
							internal.MC_BR_WriteParID_0.Execute := FALSE;
							internal.encoderReset				:= 0;
							internal.substate 					:= 0;	
							state								:= ST_WAIT;
						END_IF
						
					ELSE
						internal.MC_BR_WriteParID_0.Execute := FALSE;
						internal.encoderReset				:= 0;
						internal.substate 					:= 0;	
						state 			  					:= ST_WAIT;			
					END_IF
				
			END_CASE
				
		(******************** SEQUENCE END *************************)

	END_CASE


(***************************************************************
		FUNCTION Block Calls
***************************************************************)

	(************************** MC_POWER ****************************)
	internal.MC_Power_0.Axis := configuration.axis; (* pointer to axis *)
	internal.MC_Power_0();

	(************************** MC_HOME *****************************)
	internal.MC_Home_0.Axis := configuration.axis;
	internal.MC_Home_0();

	(********************** MC_MOVEABSOLUTE *************************)
	internal.MC_MoveAbsolute_0.Axis := configuration.axis;
	internal.MC_MoveAbsolute_0();

	(********************** MC_MOVEADDITIVE *************************)
	internal.MC_MoveAdditive_0.Axis := configuration.axis;
	internal.MC_MoveAdditive_0();

	(********************** MC_MOVEVELOCITY *************************)
	internal.MC_MoveVelocity_0.Axis := configuration.axis;
	internal.MC_MoveVelocity_0();

	(********************** MC_GEARIN *************************)
	internal.MC_GearIn_0.Master := configuration.masterAxis;
	internal.MC_GearIn_0.Slave  := configuration.axis;
//	internal.MC_GearIn_0();

	(********************** MC_GEAROUT *************************)
	internal.MC_GearOut_0.Slave := configuration.axis;
//	internal.MC_GearOut_0();

	(************************** MC_STOP *****************************)
	internal.MC_Stop_0.Axis := configuration.axis;
	internal.MC_Stop_0();

	(************************* MC_BR_INITMODPOS *********************)
	internal.MC_BR_InitModPos_0.Axis := configuration.axis;
	internal.MC_BR_InitModPos_0();

	(************************** MC_HALT *****************************)
	internal.MC_Halt_0.Axis := configuration.axis;
	internal.MC_Halt_0();

	(************************** OTHER *****************************)
	internal.MC_BR_ReadParID_0();
	internal.MC_BR_WriteParID_0();
	
	(************************* MC_BR_READAXISERROR ***********************)
	internal.MC_BR_ReadAxisError_0.Axis	  := configuration.axis;
	internal.MC_BR_ReadAxisError_0.Mode   := mcTEXT;
	internal.MC_BR_ReadAxisError_0.Enable := 1;
		
	internal.MC_BR_ReadAxisError_0.Configuration.Format				:= mcNULL;
	internal.MC_BR_ReadAxisError_0.Configuration.DataAddress		:= ADR(internal.tmpErrorArray[0]);
	internal.MC_BR_ReadAxisError_0.Configuration.DataLength			:= SIZEOF(internal.tmpErrorArray);
	internal.MC_BR_ReadAxisError_0.Configuration.LineLength			:= SIZEOF(internal.tmpErrorArray[0]);
	
	// default error text object name acp10etxen
	IF brsstrlen(ADR(configuration.errorTextObject)) = 0 THEN
		configuration.errorTextObject	:= 'acp10etxen';
	END_IF
		
	internal.MC_BR_ReadAxisError_0.Configuration.DataObjectName		:= configuration.errorTextObject;
	internal.MC_BR_ReadAxisError_0();

	IF internal.MC_BR_ReadAxisError_0.ErrorRecord.Number = 39014 AND internal.batteryState = ST_BAT_OK THEN //Low battery warning
		internal.batteryState := ST_BAT_ERROR;
	ELSIF internal.MC_BR_ReadAxisError_0.ErrorRecord.Number = 39024  THEN //Encoder positions lost	
		internal.batteryState := ST_BAT_POS_LOST;
	END_IF
	(************************** MC_RESET ****************************)
	internal.MC_Reset_0.Axis := configuration.axis;
	internal.MC_Reset_0();

	
	(************************ MC_BR_CommandError *********************)
	internal.MC_BR_CommandError_0.Axis 		:= configuration.axis;
	internal.MC_BR_CommandError_0.Command	:= parameter.errorSimulationCommand;
	internal.MC_BR_CommandError_0.Execute	:= command.simulateError;
	internal.MC_BR_CommandError_0();
	
	IF internal.MC_BR_CommandError_0.Done THEN
		internal.MC_BR_CommandError_0.Execute := command.simulateError := FALSE;
	END_IF	
	
	(****************** MC_BR_AXISERRORCOLLECTOR *********************)
	internal.MC_BR_AxisErrorCollector_0.Axis 	:= configuration.axis;
	internal.MC_BR_AxisErrorCollector_0.Enable	:= 1;
	internal.MC_BR_AxisErrorCollector_0();

	
	(************************ MC_READSTATUS *************************)
	internal.MC_ReadStatus_0.Enable  := 1;
	internal.MC_ReadStatus_0.Axis 	:= configuration.axis;
	internal.MC_ReadStatus_0();

	
	(******************** MC_READACTUALPOSITION *********************)
	IF  (pAxis.nc_obj_inf.hardware.acp_typ = 0 OR pAxis.nc_obj_inf.hardware.acp_typ = 2) AND pAxis.nc_obj_inf.nc_obj_typ <> 4 THEN		// Check if it is an ACOPOSmulti power supply. if virtual axis its ok
		internal.MC_ReadActualPosition_0.Enable	:= 0;
	ELSIF NOT internal.MC_ReadActualPosition_0.Error AND state < ST_ERROR THEN 
		internal.MC_ReadActualPosition_0.Enable	:= 1;
	ELSE
		internal.MC_ReadActualPosition_0.Enable := status.driveStatus.initialized;
	END_IF
	
	IF NOT configuration.disablePositionReading THEN
		internal.MC_ReadActualPosition_0.Axis	:= configuration.axis;
		internal.MC_ReadActualPosition_0();
		IF (internal.MC_ReadActualPosition_0.Valid) THEN
			status.actPosition := internal.MC_ReadActualPosition_0.Position;
		ELSIF (internal.MC_ReadActualPosition_0.ErrorID <> 0 AND state < ST_ERROR) THEN
			status.actPosition := 0.0;
			state       	   := ST_ERROR;
		END_IF
	ELSE
		status.actPosition := 0.0;
	END_IF
	
	(******************* MC_BR_WriteParID  *******************)
	internal.MC_BR_WriteParID_1(Axis := configuration.axis);		// write sw end limit ignore

	
	(******************* MC_BR_INITAXISSUBJECTPAR *******************)
	internal.MC_BR_InitAxisSubjectPar_0.Axis 	:= configuration.axis;
	internal.MC_BR_InitAxisSubjectPar_0.Subject := ncDIG_IN;
	internal.MC_BR_InitAxisSubjectPar_0();
	
	
	(******************** MC_BR_SetHardwareInput *******************)
	internal.MC_BR_SetHardwareInputs_0.Enable		:= pAxis.dig_in.level.neg_hw_end >= ncFORCE OR pAxis.dig_in.level.pos_hw_end >= ncFORCE OR 
												 	   pAxis.dig_in.level.reference >= ncFORCE OR pAxis.dig_in.level.trigger1 >= ncFORCE OR pAxis.dig_in.level.trigger2 >= ncFORCE;
	internal.MC_BR_SetHardwareInputs_0.HomeSwitch	:= parameter.hwInput.homeReference.input;
	internal.MC_BR_SetHardwareInputs_0.NegHWSwitch	:= parameter.hwInput.negHwLimit.input;
	internal.MC_BR_SetHardwareInputs_0.PosHWSwitch	:= parameter.hwInput.posHwLimit.input;
	internal.MC_BR_SetHardwareInputs_0.Trigger1		:= parameter.hwInput.trigger1.input;
	internal.MC_BR_SetHardwareInputs_0.Trigger2		:= parameter.hwInput.trigger2.input;
//	internal.MC_BR_SetHardwareInputs_0(Axis := configuration.axis);
	

	(******************** MC_LIMITLOAD *******************)
//	internal.MC_LimitLoad_0(Axis := configuration.axis);
		
	
	(******************** MC_READACTUALVELOCITY *********************)
	IF (pAxis.nc_obj_inf.hardware.acp_typ = 0 OR pAxis.nc_obj_inf.hardware.acp_typ = 2) AND pAxis.nc_obj_inf.nc_obj_typ <> 4 THEN		// Check if it is an ACOPOSmulti power supply. if virtual axis its ok
		internal.MC_ReadActualVelocity_0.Enable	:= 0;
	ELSIF NOT internal.MC_ReadActualVelocity_0.Error AND state < ST_ERROR THEN
		internal.MC_ReadActualVelocity_0.Enable	:= 1;
	ELSE
		internal.MC_ReadActualVelocity_0.Enable	:= status.driveStatus.initialized;
	END_IF
	
	IF NOT configuration.disableVelocityReading THEN
		internal.MC_ReadActualVelocity_0.Axis := configuration.axis;
		internal.MC_ReadActualVelocity_0();
		IF internal.MC_ReadActualVelocity_0.Valid THEN
			status.actVelocity := internal.MC_ReadActualVelocity_0.Velocity;
		ELSIF (internal.MC_ReadActualVelocity_0.ErrorID <> 0 AND state < ST_ERROR) THEN
			status.actVelocity := 0.0;
			state     		   := ST_ERROR;
		END_IF
	ELSE
		status.actVelocity := 0.0;
	END_IF

	
	(******************** MC_BR_CYCLICREAD LAGERROR *********************)
	IF (pAxis.nc_obj_inf.hardware.acp_typ = 0 OR pAxis.nc_obj_inf.hardware.acp_typ = 2) AND pAxis.nc_obj_inf.nc_obj_typ <> 4 THEN		// Check if it is an ACOPOSmulti power supply. if virtual axis its ok
		internal.MC_BR_CyclicRead_1.Enable	:= 0;
	ELSIF NOT internal.MC_ReadActualVelocity_0.Error AND state < ST_ERROR THEN
		internal.MC_BR_CyclicRead_1.Enable	:= 1;
	ELSE
		internal.MC_BR_CyclicRead_1.Enable	:= status.driveStatus.initialized;
	END_IF
	
	IF NOT configuration.disableLagErrorReading THEN
		internal.MC_BR_CyclicRead_1.Mode 		:= mcONE_RECORD;
		internal.MC_BR_CyclicRead_1.ParID		:= ACP10PAR_PCTRL_LAG_ERROR;
		internal.MC_BR_CyclicRead_1.DataAddress	:= ADR(status.actLagError);
		internal.MC_BR_CyclicRead_1.DataType	:= ncPAR_TYP_REAL;
		internal.MC_BR_CyclicRead_1.Axis 		:= configuration.axis;
		internal.MC_BR_CyclicRead_1();
		
		(* scale lag error to PLCopen units *)
		IF configuration.factor <> 0 THEN
			status.actLagError := status.actLagError / UDINT_TO_REAL(configuration.factor);
		END_IF

		IF (internal.MC_BR_CyclicRead_1.ErrorID <> 0 AND state < ST_ERROR) THEN
			status.actLagError := 0.0;
			state     		   := ST_ERROR;
		END_IF
	ELSE
		status.actLagError := 0.0;
	END_IF	

	
	(******************** MC_READACTUALTORQUE *********************)
	// Check if axis is an inverter and a real axis, then enable read torque function
	IF pAxis.nc_obj_inf.hardware.acp_typ = ncACP_TYP_INV AND pAxis.nc_obj_inf.nc_obj_typ = 1 AND NOT internal.MC_ReadActualTorque_0.Error AND state < ST_ERROR THEN
		internal.MC_ReadActualTorque_0.Enable := status.driveStatus.initialized;
	ELSE
		internal.MC_ReadActualTorque_0.Enable := 0;
	END_IF

	IF NOT configuration.disableTorqueReading THEN
		internal.MC_ReadActualTorque_0.Axis	 := configuration.axis;
		internal.MC_ReadActualTorque_0();
		IF internal.MC_ReadActualTorque_0.Valid THEN
			status.actTorque := internal.MC_ReadActualTorque_0.Torque;
		ELSIF (internal.MC_ReadActualTorque_0.ErrorID <> 0 AND state < ST_ERROR) THEN
			status.actTorque := 0.0;
			state   		 := ST_ERROR;
		END_IF
	ELSE
		status.actTorque := 0.0;
	END_IF
		
	(* get taskclass cycletime info *)
//	IF internal.RTInfo.cycle_time = 0 THEN
//		internal.RTInfo(enable := TRUE);
//	END_IF
//	
	internal.TON_error_read_delay(PT := T#1s);
//	
//	(* read and save average motor torque *)
//	IF internal.MC_ReadActualTorque_0.Valid AND status.powerOn THEN	
//		(* moving average calculation *)
//		internal.filterTime[0] := 500; 				// [ms]
//		internal.filterTime[1] := 5000; 			// [ms]
//			
//		FOR internal.i := 0 TO 1 DO
//			internal.filterBase[internal.i] := internal.filterTime[internal.i] / (UDINT_TO_REAL(internal.RTInfo.cycle_time) / 1000);
//				
//			IF internal.filterBase[internal.i] < 1 THEN
//				 internal.filterBase[internal.i] := 1;
//			END_IF
//				
//			(* calculate filtered position: filterBase = 1 disables the filter *)
//			internal.calcActualValue[internal.i]	 := internal.calcActualValue_old[internal.i] - (internal.calcActualValue_old[internal.i] / internal.filterBase[internal.i]) + (internal.MC_ReadActualTorque_0.Torque / internal.filterBase[internal.i]); 
//			internal.calcActualValue_old[internal.i] := internal.calcActualValue[internal.i];	
//		END_FOR
//		
//		status.torque.actual := brmceil(internal.calcActualValue[0]*100.0)/100.0;
//		
//		IF ABS(internal.calcActualValue[0]) > ABS(status.torque.peak) THEN
//			status.torque.peak := brmceil(internal.calcActualValue[0]*100.0)/100.0;
//		END_IF
//		
//		IF ABS(internal.calcActualValue[1]) > ABS(status.torque.continous) THEN
//			status.torque.continous := brmceil(internal.calcActualValue[1]*100.0)/100.0;
//		END_IF
//	ELSE
//		status.torque.actual := 0;
//	END_IF
//	
//	(* reset continous and peak torque *)
//	IF command.resetTorqueStatus THEN
//		command.resetTorqueStatus := FALSE;
//		status.torque.continous	  := 0.0;
//		status.torque.peak		  := 0.0;
//	END_IF
		
		
//	(* read physical motor info *)
//	internal.MC_BR_ReadParID_1.Execute := pAxis.network.phase = 90;		// ACOPOS bootup done, drive ready
//	IF internal.MC_BR_ReadParID_1.Execute AND NOT internal.MC_BR_ReadParID_1.Done AND pAxis.nc_obj_inf.nc_obj_typ <> 4 AND pAxis.nc_obj_inf.net_if_typ = 1 THEN
//		internal.MC_BR_ReadParID_1(Axis := configuration.axis, ParID := ACP10PAR_MOTOR_TORQ_RATED , DataAddress := ADR(info.hw.motor.torqueRated) , DataType := ncPAR_TYP_REAL);
//		info.hw.motor.torqueRated := brmceil(info.hw.motor.torqueRated*100.0)/100.0;
//	ELSIF NOT internal.MC_BR_ReadParID_1.Execute THEN
//		internal.MC_BR_ReadParID_1(Axis := configuration.axis);	
//	END_IF
//	
//	internal.MC_BR_ReadParID_2.Execute := pAxis.network.phase = 90;		// ACOPOS bootup done, drive ready
//	IF internal.MC_BR_ReadParID_2.Execute AND NOT internal.MC_BR_ReadParID_2.Done AND pAxis.nc_obj_inf.nc_obj_typ <> 4 AND pAxis.nc_obj_inf.net_if_typ = 1 THEN
//		internal.MC_BR_ReadParID_2(Axis := configuration.axis, ParID := ACP10PAR_MOTOR_TORQ_MAX , DataAddress := ADR(info.hw.motor.torqueMaximum) , DataType := ncPAR_TYP_REAL);
//		info.hw.motor.torqueMaximum := brmceil(info.hw.motor.torqueMaximum*100.0)/100.0;
//	ELSIF NOT internal.MC_BR_ReadParID_2.Execute THEN
//		internal.MC_BR_ReadParID_2(Axis := configuration.axis);	
//	END_IF
//	
//	internal.MC_BR_ReadParID_3.Execute := pAxis.network.phase = 90;		// ACOPOS bootup done, drive ready
//	IF internal.MC_BR_ReadParID_3.Execute AND NOT internal.MC_BR_ReadParID_3.Done AND pAxis.nc_obj_inf.nc_obj_typ <> 4 AND pAxis.nc_obj_inf.net_if_typ = 1 THEN
//		internal.MC_BR_ReadParID_3(Axis := configuration.axis, ParID := ACP10PAR_MOTOR_ORDERTEXT , DataAddress := ADR(info.hw.motor.model) , DataType := ncPAR_TYP_STR32);
//	ELSIF NOT internal.MC_BR_ReadParID_3.Execute THEN
//		internal.MC_BR_ReadParID_3(Axis := configuration.axis);	
//	END_IF
	
//	(* read drive information *)
//	internal.MC_BR_GetHardwareInfo_0.Axis 		:= configuration.axis;
//	internal.MC_BR_GetHardwareInfo_0.Execute 	:= pAxis.network.phase = 90;	// ACOPOS bootup done, drive ready
//	IF internal.MC_BR_GetHardwareInfo_0.Execute AND NOT internal.MC_BR_GetHardwareInfo_0.Done THEN
//		internal.MC_BR_GetHardwareInfo_0();
//	ELSIF NOT internal.MC_BR_GetHardwareInfo_0.Execute THEN
//		internal.MC_BR_GetHardwareInfo_0();	
//	END_IF
//	
//	info.hw.drive.model 	:= internal.MC_BR_GetHardwareInfo_0.HardwareInfo.Drive.ModelNumber;
//	info.hw.drive.serial 	:= internal.MC_BR_GetHardwareInfo_0.HardwareInfo.Drive.SerialNumber;
//	
//	FOR internal.k := 0 TO SIZEOF(info.hw.drive.card)/SIZEOF(info.hw.drive.card[0])-1 DO 
//		info.hw.drive.card[internal.k].model 	:= internal.MC_BR_GetHardwareInfo_0.HardwareInfo.Card[internal.k].ModelNumber;
//		info.hw.drive.card[internal.k].serial 	:= internal.MC_BR_GetHardwareInfo_0.HardwareInfo.Card[internal.k].SerialNumber;
//	END_FOR
//	
//	(* Read and calculate temperature *)
//	IF pAxis.nc_obj_inf.nc_obj_typ <> 4 AND pAxis.nc_obj_inf.net_if_typ = 1 AND NOT configuration.disableTemperatureReading THEN
//		internal.MC_BR_CyclicRead_0(Axis := configuration.axis, Enable := status.driveStatus.initialized, Mode := mcONE_RECORD, ParID := ACP10PAR_TEMP_MOTOR, DataAddress := ADR(info.hw.motor.temperature) , DataType := ncPAR_TYP_REAL);
//
//		(* moving average temperature calculation *)
//		internal.filterTimeTemp := 3000; // [ms]
//		internal.filterBaseTemp := internal.filterTimeTemp / (UDINT_TO_REAL(internal.RTInfo.cycle_time) / 1000);
//		
//		IF internal.filterBaseTemp < 1 THEN
//			 internal.filterBaseTemp := 1;
//		END_IF
//			
//		(* calculate filtered position: filterBase = 1 disables the filter *)
//		internal.calcActualValueTemp	 	:= internal.calcActualValueTemp_old - (internal.calcActualValueTemp_old / internal.filterBaseTemp) + (info.hw.motor.temperature / internal.filterBaseTemp); 
//		internal.calcActualValueTemp_old 	:= internal.calcActualValueTemp;	
//		info.hw.motor.temperature			:= brmceil(ABS(internal.calcActualValueTemp)*10.0)/10.0;
//	ELSE 
//		internal.calcActualValueTemp		:= 0.0;
//		internal.calcActualValueTemp_old	:= 0.0;
//		info.hw.motor.temperature 			:= 0.0;
//	END_IF
	
	
	(******************** MC_BR_READDRIVEstatus *********************)
	internal.MC_BR_ReadDriveStatus_0.Enable			:= 1;
	internal.MC_BR_ReadDriveStatus_0.Axis	 		:= configuration.axis;
	internal.MC_BR_ReadDriveStatus_0.AdrDriveStatus	:= ADR(internal.tmpDriveStatus);
	internal.MC_BR_ReadDriveStatus_0();
	
	IF (internal.MC_BR_ReadDriveStatus_0.ErrorID <> 0 AND state < ST_ERROR) THEN
		state := ST_ERROR;
	END_IF
 
	(* Handling the Description output *)
	IF configuration.description = '' THEN
		IF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOS_1 THEN
			status.axisDescription := 'ACOPOS';
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOS_2 THEN
			status.axisDescription := 'ACOPOS';		
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOSmulti THEN
			status.axisDescription := 'ACOPOSmulti';			
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOSmulti_PPS THEN
			status.axisDescription := 'ACOPOSmulti PPS';			
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOSmicro THEN
			status.axisDescription := 'ACOPOSmicro';			
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOSmulti65 THEN
			status.axisDescription := 'ACOPOSmulti65';			 
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOS_SDC THEN
			status.axisDescription := 'ACOPOS SDC';	 
		ELSIF pAxis.nc_obj_inf.hardware.acp_id = ncACOPOS_SIM THEN
			status.axisDescription := 'ACOPOS Simulation';	
		END_IF
	
		// Add description if the axis is a virtual axis
		IF pAxis.nc_obj_inf.nc_obj_typ = 4 THEN
			internal.string2 := ' virtual';
			brsstrcat(ADR(status.axisDescription), ADR(internal.string2));(*put second string to end of first one*)
		END_IF
	
	ELSE
		status.axisDescription := configuration.description;
	END_IF	


	(* show the startup phase status *)
	IF pAxis.network.phase = 0 THEN
		info.startupPhase := '0: Communication to ACOPOS is not active';
	ELSIF pAxis.network.phase = 1 THEN
		info.startupPhase := '1: Network initialization was started for unit ACOPOS';
	ELSIF pAxis.network.phase = 5 THEN
		info.startupPhase := '5: Wait for completion of network initialization of NC software with higher startup priority';
	ELSIF pAxis.network.phase = 9 THEN
		info.startupPhase := '9: Wait for communication with ACOPOS BsLoader';
	ELSIF pAxis.network.phase = 10 THEN
		info.startupPhase := '10: Communication with ACOPOS BsLoader has been set up';
	ELSIF pAxis.network.phase = 20 THEN
		info.startupPhase := '20: ACOPOS executes start of BsLoader after SW Reset';
	ELSIF pAxis.network.phase = 30 THEN
		info.startupPhase := '30: Download of BsLoader to unit ACOPOS is executed';
	ELSIF pAxis.network.phase = 31 THEN
		info.startupPhase := '31: Download of BsLoader to other ACOPOS modules is executed';
	ELSIF pAxis.network.phase = 40 THEN
		info.startupPhase := '40: Download of operating system to unit ACOPOS is executed';
	ELSIF pAxis.network.phase = 41 THEN
		info.startupPhase := '41: Download of operating system to other ACOPOS modules is executed';
	ELSIF pAxis.network.phase = 50 THEN
		info.startupPhase := '50: ACOPOS executes start of operating system';
	ELSIF pAxis.network.phase = 55 THEN
		info.startupPhase := '55: Wait for completion of network initialization of NC software with lower startup priority';
	ELSIF pAxis.network.phase = 60 THEN
		info.startupPhase := '60: Default parameters are transferred to the ACOPOS';
	ELSIF pAxis.network.phase = 70 THEN
		info.startupPhase := '70: INIT-ACOPOS parameters are transferred to the ACOPOS';
	ELSIF pAxis.network.phase = 90 THEN
		info.startupPhase := '90: Network initialization complete, drive ready';
	END_IF	
(***************** BATTERY STATE MONITOR FOR ACOPOSMICRO WITH ENDAT 2.2 ******************************************)		
	IF info.hw.drive.model = '80VD100PD.C000-01' OR
   		info.hw.drive.model = '80VD100PD.C000-14' OR
   		info.hw.drive.model = '80VD100PS.C00X-01' THEN	
   		internal.acoposMicroBatMon := TRUE;
	
		CASE internal.batteryState OF
		
			ST_BAT_OK:
			
				status.encoderBatteryStatus.batteryError 	:= FALSE;
				status.encoderBatteryStatus.batteryOK		:= TRUE;
				status.encoderBatteryStatus.batteryWarning	:= FALSE;
				status.encoderBatteryStatus.positionLost  	:= FALSE;	
			
			ST_BAT_ERROR:
			
				status.encoderBatteryStatus.batteryError 	:= TRUE;
				status.encoderBatteryStatus.batteryOK		:= FALSE;
				status.encoderBatteryStatus.batteryWarning	:= FALSE;
				status.encoderBatteryStatus.positionLost  	:= FALSE;
				
			ST_BAT_WARNING:
			
				status.encoderBatteryStatus.batteryError 	:= FALSE;
				status.encoderBatteryStatus.batteryOK		:= FALSE;
				status.encoderBatteryStatus.batteryWarning	:= TRUE;
				status.encoderBatteryStatus.positionLost  	:= FALSE;
				
				IF command.newBatAcknowledge AND NOT status.powerOn THEN //Reset encoder warning bit - only possible when power is off
					internal.encoderReset := 1;
					internal.MC_BR_WriteParID_0(Axis := configuration.axis , Execute := TRUE, ParID := ACP10PAR_ENCOD_CMD, DataAddress := ADR(internal.encoderReset) , DataType := ncPAR_TYP_UDINT);
						
					IF internal.MC_BR_WriteParID_0.Done THEN
						internal.MC_BR_WriteParID_0.Execute := FALSE;
						internal.encoderReset				:= 0;
						internal.batteryState				:= ST_BAT_OK;
					END_IF		
				END_IF 
			
			ST_BAT_POS_LOST:
			
				status.encoderBatteryStatus.batteryError 	:= TRUE;
				status.encoderBatteryStatus.batteryOK		:= FALSE;
				status.encoderBatteryStatus.batteryWarning	:= FALSE;
				status.encoderBatteryStatus.positionLost  	:= TRUE;
				IF command.newBatAcknowledge AND NOT status.powerOn THEN //Reset encoder warning bit - only possible when power is off
					internal.encoderReset := 1;
					internal.MC_BR_WriteParID_0(Axis := configuration.axis , Execute := TRUE, ParID := ACP10PAR_ENCOD_CMD, DataAddress := ADR(internal.encoderReset) , DataType := ncPAR_TYP_UDINT);
						
					IF internal.MC_BR_WriteParID_0.Done THEN
						internal.MC_BR_WriteParID_0.Execute := FALSE;
						internal.encoderReset				:= 0;
						internal.batteryState				:= ST_BAT_OK;
					END_IF		
				END_IF 
				
		END_CASE
	ELSE
		internal.batteryState						:= ST_BAT_OK;
		status.encoderBatteryStatus.batteryError 	:= FALSE;
		status.encoderBatteryStatus.batteryOK		:= TRUE;
		status.encoderBatteryStatus.batteryWarning	:= FALSE;
		status.encoderBatteryStatus.positionLost  	:= FALSE;	
			
	END_IF	

	(* status *)
	status.stopped 	:= internal.MC_Stop_0.Done;
	status.isHomed 	:= internal.tmpDriveStatus.HomingOk;
	status.powerOn 	:= internal.tmpDriveStatus.ControllerStatus;
	status.inMotion := pAxis.move.mode <> ncOFF AND NOT internal.MC_ReadStatus_0.Disabled AND NOT internal.MC_ReadStatus_0.StandStill;
	
	(* status drive status *)
	status.driveStatus.controllerReady 		:= internal.tmpDriveStatus.ControllerReady;
	status.driveStatus.driveEnable			:= internal.tmpDriveStatus.DriveEnable;
	status.driveStatus.homeSwitch			:= internal.tmpDriveStatus.HomeSwitch;
	status.driveStatus.negLimitSwitch		:= internal.tmpDriveStatus.NegHWSwitch;
	status.driveStatus.posLimitSwitch		:= internal.tmpDriveStatus.PosHWSwitch;
	status.driveStatus.trigger1				:= internal.tmpDriveStatus.Trigger1;
	status.driveStatus.trigger2				:= internal.tmpDriveStatus.Trigger2;
	status.driveStatus.lagWarning			:= internal.tmpDriveStatus.LagWarning;
	status.driveStatus.initialized			:= internal.tmpDriveStatus.NetworkInit;
	status.driveStatus.simulation			:= internal.tmpDriveStatus.Simulation;

END_FUNCTION_BLOCK

