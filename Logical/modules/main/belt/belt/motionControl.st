ACTION motionControl:
	// Update speed on drive
	
	this.rampDown := 500/(UDINT_TO_REAL(MAX(1,recipe.rampDown+20))/1000);
	this.rampUp := 500/(UDINT_TO_REAL(MAX(1,recipe.rampUp+20))/1000);
	
	axis.parameter.acceleration	:= this.rampUp;
	axis.parameter.deceleration	:= this.rampDown;
	
	IF this.hmi.force.enable THEN
		axis.command.power := TRUE;
		IF(axis.status.powerOn) THEN
			IF axis.status.isHomed THEN
				axis.command.home := FALSE;
				axis.parameter.velocity		:= this.hmi.force.speed;
				IF NOT axis.status.inMotion OR this.hmi.force.speed <> this.oldForceSpeed THEN
					axis.command.moveVelocity	:= TRUE;
				ELSE
					axis.command.moveVelocity	:= FALSE;
				END_IF;
				this.oldForceSpeed := this.hmi.force.speed;
			ELSE
				axis.command.home := TRUE;
			END_IF
				
		ELSE
			axis.command.power := TRUE;
		END_IF
	ELSIF NOT this.hmi.force.enable AND this.hmi.force.enable <> this.oldForceActive THEN
		axis.command.power 			:= FALSE;
		axis.command.moveVelocity	:= FALSE;
	ELSIF em.mode = MODE_CALIBRATING THEN
		
		CASE this.updateSpeedState OF
			
			0:
				IF this.setSpeed <> this.speedOldManual THEN
					this.updateSpeedState := 10;
				END_IF
				this.speedOldManual := this.setSpeed;
				
			10:
				axis.parameter.velocity		:= this.setSpeed;
				axis.command.moveVelocity	:= TRUE;
				IF axis.status.done THEN	// When in motion .moveVelocity succeeded. 
					this.updateSpeedState		:= 0;
					axis.command.moveVelocity	:= FALSE;
				END_IF
				
				
			20:
				axis.command.stop := TRUE;
				IF axis.status.stopped THEN
					axis.command.stop := FALSE;
					this.updateSpeedState := 0;
				END_IF
					
				
		END_CASE
					
	ELSE
		
		CASE this.updateSpeedState OF
		
			0:
				IF interface.status.speed <> this.speedOld THEN 
					axis.parameter.velocity		:= this.setSpeed;
					axis.command.moveVelocity	:= TRUE;
					this.speedOld	:= interface.status.speed;
					this.oldPosition := axis.status.actPosition;
					this.updateSpeedState	:= 10;
				ELSIF em.state <> STATE_STARTING AND em.state <> STATE_EXECUTE AND interface.status.speed = 0 AND axis.status.inMotion THEN
					this.updateSpeedState := 20;
				END_IF
				
			10:
			//	IF axis.status.done OR interface.status.speed = lego_speed_stop OR (interface.status.speed = lego_speed_wait AND ) THEN	// When in motion .moveVelocity succeeded. 
			//	IF axis.status.done OR interface.status.speed <> this.speedOld THEN	// When in motion .moveVelocity succeeded. 
				IF axis.status.done OR interface.status.speed = lego_speed_stop OR (interface.status.speed = lego_speed_wait AND ABS(axis.status.actPosition-this.oldPosition) >= this.minMillimeterInCount) THEN
					this.updateSpeedState		:= 0;
					axis.command.moveVelocity	:= FALSE;
				END_IF
			
			20:
				axis.command.stop := TRUE;
				IF axis.status.stopped THEN
					axis.command.stop := FALSE;	
					this.updateSpeedState := 0;
				END_IF
			
		END_CASE
	END_IF
	
	this.oldForceActive := this.hmi.force.enable;
	
	// torque limit control
	//this.MC_LimitLoad_0.Enable := axis.parameter.direction = this.MC_LimitLoad_0.Direction; // will call false for 1 scan if direction changes.
	//this.MC_LimitLoad_0.Axis := ADR(gAxisBelt);
	//this.MC_LimitLoad_0.Direction := axis.parameter.direction;
	//this.MC_LimitLoad_0.Load := config.maxTorqueAllowed;
	
	// Axis direction and torque limit
	CASE this.stateAxisDirection OF	
				
		0:
		//	'Wait for config';
						
			IF gConfig.status.loaded THEN
				this.MC_BR_WriteParID_0(Execute := FALSE);
				this.oldMachineType := 99;
				this.stateAxisDirection := 10;
			END_IF
			
		10:
			this.TON_testDelay.IN := TRUE;
			this.TON_testDelay.PT := T#300ms;
			this.TON_testDelay();
				
			IF this.TON_testDelay.Q THEN
				this.TON_testDelay.IN := FALSE;
				this.TON_testDelay();
				
				this.stateAxisDirection := 15;
			END_IF
			
		15:
			// Wait to see if machineType changes.
			
			IF gMainInterface.status.machineType <> this.oldMachineType THEN
				this.oldMachineType := gMainInterface.status.machineType;
				
				this.stateAxisDirection := 20;
			END_IF
				
		20:
		//	'Set count_dir to inverse';
						
			this.MC_BR_WriteParID_0.Execute 		:= TRUE;
			this.MC_BR_WriteParID_0.Axis 			:= ADR(gAxisBelt);
			this.MC_BR_WriteParID_0.ParID 			:= 96; 					// Encoder1: Load scaling: Count direction
			this.MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_USINT;
			this.MC_BR_WriteParID_0.DataAddress 	:= SEL(this.oldMachineType=0,ADR(ncSTANDARD),ADR(ncINVERSE));
			this.MC_BR_WriteParID_0();
						
			IF this.MC_BR_WriteParID_0.Done THEN
				this.MC_BR_WriteParID_0(Execute := FALSE);
				this.MC_LimitLoad_0(Enable := FALSE);
				this.stateAxisDirection := 100;
			END_IF
					
		100:
			this.MC_LimitLoad_0.Axis := ADR(gAxisBelt);
			this.MC_LimitLoad_0.Direction := SEL(this.oldMachineType=0,0,1);
			this.MC_LimitLoad_0.Load := config.maxTorqueAllowed;
			this.MC_LimitLoad_0.Enable := TRUE;
					
			IF this.MC_LimitLoad_0.Ready THEN
				this.stateAxisDirection := 15;
			END_IF
				
	END_CASE
	
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     