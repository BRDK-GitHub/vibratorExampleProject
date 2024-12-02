
ACTION calibrating:
	
	CASE em.state OF
		
		STATE_STOPPED:
			
			IF this.abortedDoingTorqueTest THEN
				this.abortedDoingTorqueTest := FALSE;
				this.hmi.calibrating.activate := FALSE; //Should change to MODE_Production
			END_IF;
			em.cmd.sc := TRUE;
			
		STATE_RESETTING:
			
			IF this.hmi.calibrating.activate THEN
				interface.status.speed := lego_speed_stop;
				CASE em.substate OF			
					0:
						em.description := 'power on axis';
					
						IF axis.status.powerOn THEN
							em.substate := 10;
						ELSE
							axis.command.power := TRUE;
						END_IF
					
					10:
						em.description := 'home axis axis';
					
						IF axis.status.isHomed THEN
							axis.command.home := FALSE;
							em.cmd.sc := TRUE;
						ELSE
							axis.command.home := TRUE;
						END_IF		
				END_CASE
			ELSE
				em.cmd.sc := TRUE;
			END_IF
			
		STATE_STARTING:
			this.setSpeed := 0;
			this.abortedDoingTorqueTest := FALSE;
			interface.status.speed := lego_speed_stop;
			
			IF this.hmi.calibrating.activate THEN
				// motor torque
				this.MC_BR_ReadParID_277.Axis := ADR(gAxisBelt);
				this.MC_BR_ReadParID_277.ParID := 277;
				this.MC_BR_ReadParID_277.DataType := ncPAR_TYP_REAL;
				this.MC_BR_ReadParID_277.DataAddress := ADR(this.motorTorque);
			END_IF
			em.cmd.sc := TRUE;
			
		STATE_EXECUTE:
			IF this.hmi.calibrating.activate THEN
				// motor torque
				this.MC_BR_ReadParID_277.Execute := TRUE;	
				this.MC_BR_ReadParID_277.Axis := ADR(gAxisBelt);
				this.MC_BR_ReadParID_277.DataAddress := ADR(this.motorTorque);
				
				IF this.MC_BR_ReadParID_277.Done THEN
					this.MC_BR_ReadParID_277.Execute := FALSE;
				END_IF
						
				this.MC_BR_ReadParID_277();
			END_IF
			
			CASE em.substate OF
				
				0:
					em.description := 'Only calibrate if it is for belt';
					
					em.cmd.sc := NOT this.hmi.calibrating.activate;
				
					
				
			END_CASE		
			
			em.cmd.sc := TRUE;
			
		STATE_STOPPING, STATE_ABORTING, STATE_HOLDING:
			this.MTDataMean_torque(Enable := FALSE);
			this.MC_BR_ReadParID_277.Execute := FALSE;
			this.MC_BR_ReadParID_277();
			IF NOT this.MC_BR_ReadParID_277.Busy THEN
				commonStoppingHoldingCompletingAbortingSuspending;
			END_IF
			
		STATE_ABORTED:
			
			IF NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortBelt') THEN
				em.cmd.sc := TRUE;
			END_IF
			
		STATE_CLEARING:
			this.hmi.avgMotorTorque := 0;
			this.abortedDoingTorqueTest := TRUE;
			commonClearing;

		ELSE
			
			em.cmd.sc := TRUE;
		
	END_CASE
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        