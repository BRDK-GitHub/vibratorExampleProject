
ACTION calibratingMode:
	
	CASE em.state OF
		
		STATE_STOPPED:
			
		
			em.cmd.sc := TRUE;
		
		STATE_RESETTING:
			hmi.stopCalibration := FALSE;
			interface.status.percent := 0;
			em.cmd.sc := TRUE;
			
		STATE_IDLE:
			em.cmd.start := TRUE;
			em.cmd.sc := TRUE;
			
		STATE_STARTING:
			
			CASE em.substate OF
				
				0:
					IF interface.status.calibratingMode THEN
						em.substate := 5;
					ELSE
						em.substate := 10;
					END_IF
				
				5:
					axis.command.power := TRUE;
					
					IF axis.status.powerOn THEN
						em.substate := 10;
					END_IF 
				
				10:
					em.cmd.sc := TRUE;
					
				
			END_CASE
			

						
		STATE_EXECUTE:
		
			IF hmi.stopCalibration THEN
				em.substate := 222;
			END_IF
			
			CASE em.substate OF
				
				0:
					IF interface.cmd.calibrationDone THEN
						em.substate := 222;
					ELSIF interface.cmd.testPulses THEN
						this.PulseAmplitude := VIB_CALI_PULSE_AMPLITUDE; // Use 60% for calibration of boost.
						this.TON_PulseTest.PT := T#1500ms;
						em.substate := 10;
					END_IF
					
				10:
					this.TON_PulseTest.IN := TRUE;
					this.TON_PulseTest();
				
					IF this.TON_PulseTest.Q THEN
						this.TON_PulseTest.IN := FALSE;
						this.TON_PulseTest();
		
						IF interface.status.percent = this.PulseAmplitude THEN
							interface.status.percent := 0;
						ELSE
							interface.status.percent := this.PulseAmplitude;
						END_IF
						
					ELSIF NOT interface.cmd.testPulses THEN
						em.substate := 0;	
					END_IF
					
					
				222:
					em.cmd.stop := TRUE;
				
			END_CASE

			em.cmd.sc := TRUE;
			
			STATE_STOPPING, STATE_ABORTING, STATE_HOLDING:
			em.description := 'stopping vibrators';

			interface.status.percent := 0;
			hmi.stopCalibration := FALSE;
			interface.status.calibratingMode := FALSE;
			axis.command.power := FALSE;
			em.cmd.sc := TRUE;
			
		STATE_ABORTED:
			
			IF (i=0 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortCircularFeeder')) OR (i=1 AND NOT MpAlarmXCheckReaction(mpAlarmXCore,'abortLinearFeeder')) THEN
				em.cmd.sc := TRUE;
			END_IF
			
			
		STATE_CLEARING:
			
			em.description := 'clearing';

			axis.command.errorAcknowledge := axis.status.error.fault; // clear axis if we have any error
			
			em.cmd.sc := TRUE;
			
		ELSE
			
			em.description := 'power off - waiting for start';
			axis.command.power := FALSE;
			em.cmd.sc := TRUE;
		
	END_CASE
	
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        