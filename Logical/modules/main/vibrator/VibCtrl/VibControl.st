FUNCTION_BLOCK VibControl

	IF NOT Enable AND Active THEN
		state := 0;
		CalibrateDone := FALSE;
		phi := 0;
		amplitude_out := 0;
		frequency_out := 0;
		Braking := FALSE;
		HoldPhase := FALSE;
		Active := FALSE;
		TestPulses := FALSE;
		LookupTbl_PhaseTarget.Enable := FALSE;
		LookupTbl_PhaseTarget();
		LookupTbl_BoostCurrent.Enable := FALSE;
		LookupTbl_BoostCurrent();
		LookupTbl_FreqFromCurrent.Enable := FALSE;
		LookupTbl_FreqFromCurrent();
		LookupTbl_CurrentFromPercent.Enable := FALSE;
		LookupTbl_CurrentFromPercent();
	END_IF
	
	currentZeroCrossing := (sin_ref >= 0.0 AND old_sin < 0.0) OR (sin_ref <= 0.0 AND old_sin > 0.0);
	
	IF TestPulses THEN
		
		IF measureBoostTime THEN
			measureBoostTime := FALSE;
			
			cali.startPulseTime := TRUE;
			cali.timePulseTest := 0;
			cali.saveMax := TRUE;
			cali.MTDataStatistics_0.Enable := FALSE;
			cali.MTDataStatistics_0();
		END_IF
		
		IF cali.startPulseTime THEN
			cali.timePulseTest := cali.timePulseTest + CYCLE_TIME_s; 
			
			IF Percent >= (SetAmplitudeLatched*0.8) THEN
				cali.startPulseTime := FALSE;
			END_IF
		END_IF
		
		IF cali.saveMax THEN
			cali.MTDataStatistics_0.Enable := TRUE;
			cali.MTDataStatistics_0.In := Percent;
			cali.MTDataStatistics_0();
		END_IF
	
	END_IF
	
	TON_running.IN := TRUE;
	TON_running();
	
	CASE state OF
		0:	
			CalibrateStatus := SEL(TestPulses,'Ready to start calibration','Calibrating boost with pulses');
			
			IF Enable THEN
				Active := TRUE;
				
				cali.sweepAmplitude := SEL(VibratorType=0,0.11,0.9);
				cali.sweepAmplitudeBigCF := SEL(VibratorType=0,0.07,1.6);
				SteadyLowAmplitudeKp := SEL(VibratorType=0,0.0004,0.004);
				SteadyLowAmplitudeKi := SEL(VibratorType=0,0.0000015,0.00015);
				cali.stepSizeAmplitude := SEL(VibratorType=0,0.01,0.1);
				
				VibOptimizerAmplitude_0.paramsCurrentLUT := ADR(config.lookUpCurrentFromPercent);
				VibOptimizerFrequency_0.paramsFrequencyLUT := ADR(config.lookupFrequencyFromPercent);
				
				LookupTbl_PhaseTarget.Enable := TRUE;
				LookupTbl_PhaseTarget.X := ADR(config.lookupPhaseTargetFromPercent.X);
				LookupTbl_PhaseTarget.Y := ADR(config.lookupPhaseTargetFromPercent.Y);
				LookupTbl_PhaseTarget();
				
				config.lookupBoostCurrentFromPercent.Y[0] := SEL(MachineSize=0,1.5,1.7); // reduced boost current at 10% for big CF - it was overshooting a lot before the feedback loops were even rdy.
				LookupTbl_BoostCurrent.Enable := TRUE;
				LookupTbl_BoostCurrent.X := ADR(config.lookupBoostCurrentFromPercent.X);
				LookupTbl_BoostCurrent.Y := ADR(config.lookupBoostCurrentFromPercent.Y);
				LookupTbl_BoostCurrent();
				
				LookupTbl_FreqFromCurrent.Enable := TRUE;
				LookupTbl_FreqFromCurrent.X := ADR(config.lookupFrequencyFromCurrent.X);
				LookupTbl_FreqFromCurrent.Y := ADR(config.lookupFrequencyFromCurrent.Y);
				LookupTbl_FreqFromCurrent();
				
				LookupTbl_CurrentFromPercent.Enable := TRUE;
				LookupTbl_CurrentFromPercent.X := ADR(config.lookUpCurrentFromPercent.X);
				LookupTbl_CurrentFromPercent.Y := ADR(config.lookUpCurrentFromPercent.Y);
				
				frequency := 50;
				lastSetAmplitude := 0;
				config.PhaseTarget := SEL(MachineSize=0,50.0,70.0);
				PhaseTarget := config.PhaseTarget;
				TON_ControllerStuck.PT := T#2s;
				time := 0;
				
				// Setup limiter for RampUp
				MTBasicsLimiter_0.Enable := TRUE;
				MTBasicsLimiter_0.MinOut := 0;
				MTBasicsLimiter_0.MaxOut := 130.0; // LF max is 130%.
				MTBasicsLimiter_0.MaxPosSlewRate := RampUp;
				MTBasicsLimiter_0.MaxNegSlewRate := 0;
				
				// Init PI-controllers
				IF MachineSize=0 THEN
					PIController_Phase.LoopRate := T#30ms;
					PIController_Phase.MinOutput := 45;
					PIController_Phase.MaxOutput := SEL(VibratorType=0,55,52);
					PIController_Ampl.LoopRate := T#30ms;
					PIController_Ampl.MinOutput := 0;
					PIController_Ampl.MaxOutput := SEL(VibratorType=0,0.19,1.9);
					SteadyAmplitudeKp := 0.01;
					SteadyAmplitudeKi := 0.000375;
					SteadyLowAmplitudeKp := 0.004;
					SteadyLowAmplitudeKi := 0.00015;
				ELSE
					PIController_Phase.LoopRate := SEL(VibratorType=0,T#30ms,T#60ms);
					PIController_Phase.MinOutput := SEL(VibratorType=0,45,22.0);
					PIController_Phase.MaxOutput := SEL(VibratorType=0,55,26.0);
					PIController_Ampl.LoopRate := SEL(VibratorType=0,T#30ms,T#60ms);
					PIController_Ampl.MinOutput := 0;
					PIController_Ampl.MaxOutput := SEL(VibratorType=0,0.19,2.8);
					SteadyAmplitudeKp := 0.005;
					SteadyAmplitudeKi := 0.0005;
					SteadyLowAmplitudeKp := 0.005;
					SteadyLowAmplitudeKi := 0.0005;
				END_IF
				PIController_Ampl.Kp := SteadyAmplitudeKp;
				PIController_Ampl.Ki := SteadyAmplitudeKi;
				
				IF VibratorType=0 THEN
					state := 5;
				ELSE
					PIController_Ampl.Hold := TRUE;
					PIController_Phase.Hold := TRUE;
					state := 700;
				END_IF
			END_IF
			
		5:
			
			IF ManualControl AND NOT TestNormal THEN
				PIController_Ampl.FeedForward := 0;
				PIController_Phase.FeedForward := 0;
				
				time := 0;
				state := SEL(config.calibrationDone,100,105); // Can only run closed-loop in manual if vibrator has been calibrated.
			ELSIF Calibrate AND NOT TestPulses THEN
				PIController_Ampl.FeedForward := 0;
				PIController_Phase.FeedForward := 0;
			
				state := 600;
			ELSIF SetAmplitude < lastSetAmplitude AND frequency <> 0.0 THEN
				
				// Only brake if the change in SetAmplitude is more than 3%
				IF (lastSetAmplitude-SetAmplitude) > 3 AND (lastSetAmplitude > 25.0 OR SetAmplitude <> 0) THEN			// if WaitSpeed > 25.0 when stopping to 0.0 use brake if <= 25.0 dont' use brake.
					time := 0;
					// If the Actual amplitude is almost equal to the SetAmplitude we set earlier -> save current/frequency we used.
//					IF ABS(ActAmplitude-lastSetAmplitude) < 1.50 THEN
//						VibOptimizerAmplitude_0.Key := lastSetAmplitude;
//						VibOptimizerAmplitude_0.Value := amplitude_out;
//						VibOptimizerAmplitude_0.Error := ActAmplitude-lastSetAmplitude;
//						VibOptimizerAmplitude_0.Set := TRUE;
//						VibOptimizerAmplitude_0();
//						
//						VibOptimizerFrequency_0.Key := lastSetAmplitude;
//						VibOptimizerFrequency_0.Value := frequency_out;
//						VibOptimizerFrequency_0.Error := ActAmplitude-lastSetAmplitude;
//						VibOptimizerFrequency_0.Set := TRUE;
//						VibOptimizerFrequency_0();
//					END_IF
					VibOptimizerAmplitude_0.Key := lastSetAmplitude;
					VibOptimizerAmplitude_0.Get := TRUE;
					VibOptimizerAmplitude_0();
					brakeAmplitude := amplitude_out;
					brakeTime := GetBrakeTimeFromAmplitude(amplitude_out, lastSetAmplitude-SetAmplitude,MachineSize);
					brakeTime := LIMIT(0,brakeTime,1.0);
					lastSetAmplitude := SetAmplitude;
					
					SetAmplitudeLatched := SetAmplitude;
					state := 20;
				ELSE
					SetAmplitudeLatched := SetAmplitude;
					lastSetAmplitude := SetAmplitude;
				END_IF
			ELSIF SetAmplitude > lastSetAmplitude AND frequency <> 0.0 THEN
				
				// Only boost if the change in SetAmplitude is more than 3%
				IF (SetAmplitude-lastSetAmplitude) > 3 THEN
					time := 0;
					lastSetAmplitudeLatched := lastSetAmplitude;
					lastSetAmplitude := SetAmplitude;
					PIController_Ampl.Hold := TRUE;
					PIController_Phase.Hold := TRUE;
					
					SetAmplitudeLatched := SetAmplitude;
					state := 10;
				ELSE
					SetAmplitudeLatched := SetAmplitude;
					lastSetAmplitude := SetAmplitude;
				END_IF
			ELSIF SetAmplitude > 0 THEN
				
				//	PIController_Ampl.Hold := ActAmplitude < 7;
				IF currentZeroCrossing THEN
					amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
					
					PIController_Phase.Hold := ActAmplitude < 2;
					frequency := RoundToPrecision(PIController_Phase.Output, 2);
				END_IF
				
			ELSIF TON_running.Q THEN
				PIController_Ampl.Hold := TRUE;
				PIController_Phase.Hold := TRUE;
				amplitude_out := 0;
			END_IF
			
		10: // wait for zero crossing
			
			IF currentZeroCrossing THEN
				// Reset timer for minimum time running.
				TON_running.IN := FALSE;
				TON_running.PT := SEL(MachineSize=0,config.minTimeInCountBigCf,config.minTimeInCount);
				TON_running();
				
				// Look-up amplitude at SetAmplitude.
				VibOptimizerAmplitude_0.Key := SetAmplitudeLatched;
				VibOptimizerAmplitude_0.Get := TRUE;
				VibOptimizerAmplitude_0();
				PIController_Ampl.FeedForward := RoundToPrecision(VibOptimizerAmplitude_0.Out*FeedForwardScaling, 3);
				PIController_Ampl.Integral := 0;
				//LookupTbl_BoostCurrent.In := PIController_Ampl.Setpoint;
				LookupTbl_BoostCurrent.In := SetAmplitudeLatched;
				LookupTbl_BoostCurrent();
				
				IF MachineSize=1 THEN
					// Currently boostCurrentScale is a LUT for big CF
					config.boostCurrentScale := LookupTbl_BoostCurrent.Out+config.OffsetBoostAmplitude;
				END_IF
				
				SetAmplitudeChange := LIMIT(1,SetAmplitudeLatched-lastSetAmplitudeLatched,130); // To avoid division with 0.
				TransientAmplitudeKp := (VibOptimizerAmplitude_0.Out*config.boostCurrentScale-PIController_Ampl.FeedForward) / SetAmplitudeChange;
				TransientAmplitudeKp := TransientAmplitudeKp*SetAmplitudeChange/SetAmplitudeLatched;
				TransientAmplitudeKp := LIMIT(0, TransientAmplitudeKp, 0.1);
				PIController_Ampl.Kp := TransientAmplitudeKp;
				PIController_Ampl.Output := PIController_Ampl.FeedForward + SetAmplitudeChange * TransientAmplitudeKp;
				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);

				// Look-up frequency at SetAmplitude.
				VibOptimizerFrequency_0.Key := SetAmplitudeLatched;
				VibOptimizerFrequency_0.Get := TRUE;
				VibOptimizerFrequency_0();
				PIController_Phase.FeedForward := RoundToPrecision(VibOptimizerFrequency_0.Out, 2);
				PIController_Phase.Integral := 0;
				PIController_Phase.Output := PIController_Phase.FeedForward;
				frequency := RoundToPrecision(PIController_Phase.Output, 2);
				
//				IF MachineSize=0 THEN
//					PhaseTarget := config.PhaseTarget;
//				ELSE
//					// Look-up PhaseTarget from frequency
//					LookupTbl_PhaseTarget.In := SetAmplitudeLatched;
//					LookupTbl_PhaseTarget();
//					PhaseTarget := LookupTbl_PhaseTarget.Out;
				//				END_IF
				
				PhaseTarget := config.PhaseTarget;
				zeroCrossingCount := 0;
				measureBoostTime := TRUE;
				
				state := 15;
			END_IF
			
		15: // Boosting
			
			zeroCrossingCount := SEL(currentZeroCrossing, zeroCrossingCount, zeroCrossingCount + 1);
			time := time + CYCLE_TIME_s;
			
			IF currentZeroCrossing THEN
				PIController_Ampl.Hold := NOT ActAmplitudeValid OR ActAmplitude < BoostAmplitudeLimit;
				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
				
				PIController_Phase.Hold := NOT ActPhaseValid;
				frequency := RoundToPrecision(PIController_Phase.Output, 2);
			END_IF
			
			IF zeroCrossingCount >= 3 AND NOT PIController_Ampl.Hold AND NOT PIController_Phase.Hold OR SetAmplitudeLatched <> SetAmplitude THEN
				PIController_Phase.Hold := FALSE;
				PIController_Ampl.Hold := FALSE;
				
				state := 5;
			ELSIF time >= 0.4 THEN
				// Timeout. It has been seen on ICM22 that it could get stuck here because ActAmplitude never got above 2.0.
				PIController_Phase.Hold := FALSE;
				PIController_Ampl.Hold := FALSE;
				ErrorTimeout := TRUE;
				state := 5;
			END_IF
			
		17:
			zeroCrossingCount := SEL(currentZeroCrossing, zeroCrossingCount, zeroCrossingCount + 1);
			
			IF zeroCrossingCount >= 4 THEN
				
				PIController_Ampl.Hold := FALSE;
				PIController_Ampl.Integral := amplitude_out;
				PIController_Ampl.Output := amplitude_out;
				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
				
			
				PIController_Phase.Hold := FALSE;
				PIController_Phase.Integral := frequency;
				PIController_Phase.Output := frequency;
				frequency := RoundToPrecision(PIController_Phase.Output, 2);
				
				state := 5;
			END_IF
			
					
		20: // Wait for zero crossing
			
			IF currentZeroCrossing AND TON_running.Q THEN
				PIController_Ampl.Hold := TRUE;
				PIController_Phase.Hold := TRUE;
				amplitude_out := brakeAmplitude;
				
				Braking := TRUE;
				BrakingToAmplitudePct := SetAmplitudeLatched;
				
				HoldPhase := TRUE;
				zeroCrossingCount := 0;
				time := 0;
				phi := phi - (PI/2.0);
				

				
				
//				IF MachineSize=0 THEN
//					PhaseTarget := config.PhaseTarget;
//				ELSE
//					// Look-up PhaseTarget from frequency
//					LookupTbl_PhaseTarget.In := SetAmplitudeLatched;
//					LookupTbl_PhaseTarget();
//					PhaseTarget := LookupTbl_PhaseTarget.Out;
				//				END_IF
				
				PhaseTarget := config.PhaseTarget;
				state := 25;
			END_IF
			
		25: // Braking
			
			time := time + CYCLE_TIME_s;
			frequency := RoundToPrecision(PIController_Phase.Output, 2);
			
			IF time >= brakeTime OR time >= 1.0 THEN
				state := 30;
			END_IF
			
		30:
			//			frequency := RoundToPrecision(PIController_Phase.Output, 2);
			
			IF SetAmplitude <> SetAmplitudeLatched THEN
				// Continue immediately no reason to lookup "SetAmplitudeLatched" since a new SetAmplitude has been received.
				Braking := FALSE;
				phi := phi + (PI/2.0);
				
				HoldPhase := FALSE;
				PIController_Phase.Hold := FALSE;
				PIController_Ampl.Hold := FALSE;
				state := 5;
			ELSIF currentZeroCrossing THEN
				Braking := FALSE;
				time := 0;
				phi := phi + (PI/2.0);
				
				// Look-up amplitude at SetAmplitude.
				VibOptimizerAmplitude_0.Key := SetAmplitudeLatched;
				VibOptimizerAmplitude_0.Get := TRUE;
				VibOptimizerAmplitude_0();
				PIController_Ampl.FeedForward := RoundToPrecision(VibOptimizerAmplitude_0.Out, 3);
				PIController_Ampl.Integral := 0;
				PIController_Ampl.Output := PIController_Ampl.FeedForward;
				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);

				// Look-up frequency at SetAmplitude.
				VibOptimizerFrequency_0.Key := SetAmplitudeLatched;
				VibOptimizerFrequency_0.Get := TRUE;
				VibOptimizerFrequency_0();
				PIController_Phase.FeedForward := RoundToPrecision(VibOptimizerFrequency_0.Out, 2);
				PIController_Phase.Integral := 0;
				PIController_Phase.Output := PIController_Phase.FeedForward;
				frequency := RoundToPrecision(PIController_Phase.Output, 2);
		
				state := 35;
			END_IF
			
		35:
			time := time + CYCLE_TIME_s;
			
			IF time >= (1/frequency)*WaitPeriodsAfterBrake OR SetAmplitude=0.0 OR SetAmplitude <> SetAmplitudeLatched OR time >= 1.0 THEN
				HoldPhase := FALSE;
				PIController_Phase.Hold := FALSE;
				PIController_Ampl.Hold := FALSE;
				
				IF NOT TestPulses THEN
					state := 5;
				ELSE
					cali.saveMax := FALSE;
					cali.startPulseTime := FALSE;
					// We are testing pulses for calibration:
					
					CASE MachineSize OF
						
						0:
							// Save best result
							IF (ABS(cali.timePulseTest-0.180)) < cali.bestTimePulseTest THEN
								cali.bestTimePulseTest := ABS(cali.timePulseTest-0.180);
								cali.bestBoostCurrent := config.boostCurrentScale;
							END_IF
							
							IF cali.timePulseTest > 0.190 AND config.boostCurrentScale <= 1.6 AND cali.countPulses < MAX_CALI_PULSES THEN
								config.boostCurrentScale := config.boostCurrentScale + 0.05;
								state := 5;
							ELSIF cali.timePulseTest < 0.150 AND config.boostCurrentScale >= 1.1 AND cali.countPulses < MAX_CALI_PULSES OR cali.MTDataStatistics_0.MaxValue > (VIB_CALI_PULSE_AMPLITUDE+2.0) AND cali.countPulses < MAX_CALI_PULSES THEN // Don't allow a overshoot of more than 2.0%.
								config.boostCurrentScale := config.boostCurrentScale - 0.05;
								state := 5;
							ELSE
								// Done
								//	config.boostCurrentScale := config.AddToBoostCurrentAt60pct/config.lookupBoostCurrentFromPercent.Y[5];		// Factor to scale ex. 0.10 which means that all boost currents will be scaled with +10% (could also be negative)
								TestPulses := FALSE;
								config.timeBoostCalibration := cali.timePulseTest;
								config.boostCurrentScale := cali.bestBoostCurrent;
								state := 647;
							END_IF
						
						1:
							// Save best result
							IF (ABS(cali.timePulseTest-0.350)) < cali.bestTimePulseTest THEN
								cali.bestTimePulseTest := ABS(cali.timePulseTest-0.350);
								cali.bestBoostCurrent := config.OffsetBoostAmplitude;
							END_IF
							
							// Big CF uses an offset value because "boostCurrentScale" is from a LUT.
							IF cali.timePulseTest > 0.370 AND config.OffsetBoostAmplitude <= 0.2 AND cali.countPulses < MAX_CALI_PULSES THEN
								config.OffsetBoostAmplitude := config.OffsetBoostAmplitude + 0.02;
								state := 5;
							ELSIF cali.timePulseTest < 0.300 AND config.OffsetBoostAmplitude >= -0.1 AND cali.countPulses < MAX_CALI_PULSES OR cali.MTDataStatistics_0.MaxValue > (VIB_CALI_PULSE_AMPLITUDE+2.0) AND cali.countPulses < MAX_CALI_PULSES THEN // Don't allow a overshoot of more than 2.0%.
								config.OffsetBoostAmplitude := config.OffsetBoostAmplitude - 0.02;
								state := 5;
							ELSE
								// Done
								//	config.boostCurrentScale := config.AddToBoostCurrentAt60pct/config.lookupBoostCurrentFromPercent.Y[5];		// Factor to scale ex. 0.10 which means that all boost currents will be scaled with +10% (could also be negative)
								TestPulses := FALSE;
								config.timeBoostCalibration := cali.timePulseTest;
								config.OffsetBoostAmplitude := cali.bestBoostCurrent;
								state := 647;
							END_IF
						
//							TestPulses := FALSE;
//							config.timeBoostCalibration := cali.timePulseTest;
//							state := 647;
						
					END_CASE
					cali.countPulses := cali.countPulses + 1;
				

					
				END_IF
				
			END_IF
		
		80:
			amplitude_out := 0;
			time := time + CYCLE_TIME_s;
			
			IF time >= 2.0 THEN
				time := 0;
				
				lastSetAmplitude := 0;
				state := 5;
			END_IF
			
		100:
			// Force without closed-loop (if vibrator is NOT calibrated)
			
			PIController_Ampl.Hold := TRUE;
			PIController_Phase.Hold := TRUE;
			
			VibOptimizerAmplitude_0.Get := TRUE;
			VibOptimizerAmplitude_0.Key := ManualPercent;
			VibOptimizerAmplitude_0();
			amplitude_out := VibOptimizerAmplitude_0.Out;
			
			
			IF config.maxFrequencySweep > 15.0 THEN
				VibOptimizerFrequency_0.Get := TRUE;
				VibOptimizerFrequency_0.Key := ManualPercent;
				VibOptimizerFrequency_0();
				frequency := VibOptimizerFrequency_0.Out;
			ELSE
				// Use 50hz - a calibration has not been running.
				amplitude_out := ManualPercent/100*MaxCurr;
				frequency := ManualFrequency;
				
			END_IF
			
			// Manual mode disabled
			IF NOT ManualControl OR TestNormal THEN
				amplitude_out := 0;
				state := 5;
			ELSIF DevForce THEN
				state := 110;
			END_IF
			
		105:
			// Run open loop for 1s before switching to closed loop.
			
			PIController_Ampl.Hold := TRUE;
			PIController_Phase.Hold := TRUE;
			
			VibOptimizerAmplitude_0.Get := TRUE;
			VibOptimizerAmplitude_0.Key := ManualPercent;
			VibOptimizerAmplitude_0();
			amplitude_out := VibOptimizerAmplitude_0.Out;
			
			VibOptimizerFrequency_0.Get := TRUE;
			VibOptimizerFrequency_0.Key := ManualPercent;
			VibOptimizerFrequency_0();
			frequency := VibOptimizerFrequency_0.Out;
			
			time := time + CYCLE_TIME_s;
				
			IF NOT ManualControl OR TestNormal THEN
				// Manual mode disabled
				amplitude_out := 0;
				state := 5;
			ELSIF time >= 1.0 AND ManualPercent >= 20.0 THEN
				time := 0;
				oldManualPercent := ManualPercent;
				PhaseTarget := config.PhaseTarget;
				SetAmplitudeLatched := ManualPercent;
				state := 107;
			ELSIF DevForce THEN
				state := 110;
			END_IF
			
		107:
			// Run closed loop.
			
			IF PIController_Ampl.Hold THEN
				PIController_Ampl.Hold := FALSE;
				PIController_Ampl.Integral := amplitude_out;
				PIController_Ampl.Output := amplitude_out;
			END_IF
			amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
			
			IF PIController_Phase.Hold THEN
				PIController_Phase.Hold := FALSE;
				PIController_Phase.Integral := frequency_out;
				PIController_Phase.Output := frequency_out;
			END_IF
			frequency := RoundToPrecision(PIController_Phase.Output, 2);
			
			IF NOT ManualControl OR TestNormal THEN
				// Manual mode disabled
				amplitude_out := 0;
				PIController_Phase.Hold := TRUE;
				PIController_Ampl.Hold := TRUE;
				state := 5;
			ELSIF ManualPercent <> oldManualPercent THEN
				state := 105;
			ELSIF DevForce THEN
				state := 110;
			END_IF
			
		// Dev force:
		110:
			IF ClosedLoopAmplitude THEN
				SetAmplitudeLatched := SetAmplitude;
				IF PIController_Ampl.Hold THEN
					PIController_Ampl.Hold := FALSE;
					PIController_Ampl.Integral := amplitude_out;
					PIController_Ampl.Output := amplitude_out;
				END_IF
				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
			ELSE
				PIController_Ampl.Hold := TRUE;
				amplitude_out := ManualCurrent;
			END_IF
				
			IF ClosedLoopPhase THEN
				IF PIController_Phase.Hold THEN
					PIController_Phase.Hold := FALSE;
					PIController_Phase.Integral := frequency;
					PIController_Phase.Output := frequency;
				END_IF
				frequency := RoundToPrecision(PIController_Phase.Output, 2);
			ELSE
				PIController_Phase.Hold := TRUE;
				frequency := ManualFrequency;
			END_IF
			
			IF NOT ManualControl OR NOT DevForce THEN
				amplitude_out := 0;
				state := 5;
			END_IF
			
			//------------------------------------------
			//				CALIBRATION CF
			//------------------------------------------
			
		600:
			CalibrateStatus := 'Find ressonance frequency';
			
			amplitude_out := SEL(MachineSize=0,cali.sweepAmplitudeBigCF,cali.sweepAmplitude);
			frequency := SEL(MachineSize=0,26.0,53.0);
			
			time := time + CYCLE_TIME_s;
			
			IF time >= cali.sweepTimeSteps THEN
				// Reset all vars before starting
				config.vibratorIsCalibrated := FALSE;
				time := 0;
				cali.sweepMaxAmplitude := 0;
				brsmemset(ADR(config.lookUpCurrentFromPercent),0,SIZEOF(config.lookUpCurrentFromPercent));
				brsmemset(ADR(config.lookupFrequencyFromPercent),0,SIZEOF(config.lookupFrequencyFromPercent));
				brsmemset(ADR(config.lookUpPercentFromAmplitude),0,SIZEOF(config.lookUpPercentFromAmplitude));
				brsmemset(ADR(config.lookupPhaseTargetFromPercent),0,SIZEOF(config.lookupPhaseTargetFromPercent));
				brsmemset(ADR(config.lookupFrequencyFromCurrent),0,SIZEOF(config.lookupFrequencyFromCurrent));
				brsmemset(ADR(config.lookupBoostCurrentFromPercent),0,SIZEOF(config.lookupBoostCurrentFromPercent));
				config.maxCurrentUsed := 0.0;
				config.maxFrequencySweep := 0.0;
				config.maxPhaseSweep := 0.0;
				config.ressonanceFrequencyAt45Pct := 0.0;
				config.LUTsDescending := FALSE;
				config.lookupBoostCurrentFromPercent.X[0] := 10.0;
				config.lookupBoostCurrentFromPercent.X[1] := 20.0;
				config.lookupBoostCurrentFromPercent.X[2] := 40.0;
				config.lookupBoostCurrentFromPercent.X[3] := 60.0;
				config.lookupBoostCurrentFromPercent.X[4] := 80.0;
				config.lookupBoostCurrentFromPercent.X[5] := 100.0;
				
				config.lookupBoostCurrentFromPercent.Y[0] := SEL(MachineSize=0,1.5,1.7); // reduced boost current at 10% for big CF - it was overshooting a lot before the feedback loops were even rdy.
				config.lookupBoostCurrentFromPercent.Y[1] := 1.5;
				config.lookupBoostCurrentFromPercent.Y[2] := 1.3;
				config.lookupBoostCurrentFromPercent.Y[3] := 1.2;
				config.lookupBoostCurrentFromPercent.Y[4] := 1.1;
				config.lookupBoostCurrentFromPercent.Y[5] := 1.1;
	
				config.AddToBoostCurrentAt60pct := 0.0;
				config.OffsetBoostAmplitude := 0.0;
				config.boostCurrentScale := 1.4;
				
				// Step size is half with big CF.
				cali.freqStepSize := SEL(MachineSize=0,0.05,0.1);
				cali.freqStepSizeSmall := SEL(MachineSize=0,0.01,0.02);
				cali.sweepEndFrequency := SEL(MachineSize=0,22.0,46.0);
				config.centerFrequencyBPF := SEL(MachineSize=0,36.3,73.5);		// Corresponds to 49Hz and 24.2Hz
				config.timeInCalibrationSeconds := 0.0; // Reset time in calibration.
				config.calibrationDone := FALSE;
				
				UpdateFilter := TRUE;
				state := 605;
			END_IF
			
		605:
			CalibrateStatus := 'Init filters';
			
			IF UpdateFilterDone THEN
				UpdateFilter := FALSE;
				state := 610;
			END_IF
		
		
		610:
			CalibrateStatus := 'Find ressonance frequency';
			
			time := time + CYCLE_TIME_s;
			
			IF time >= cali.sweepTimeSteps THEN
				time := 0;
				
				IF ActAmplitude > cali.sweepMaxAmplitude THEN
					cali.sweepMaxAmplitude := ActAmplitude;
					cali.sweepMaxFrequency := frequency;
					cali.sweepMaxPhase := SEL(MachineSize=0,ActPhaseAcc,ActPhase);
				END_IF
			
				
				IF frequency <= cali.sweepEndFrequency THEN
					config.maxFrequencySweep := cali.sweepMaxFrequency;
					config.maxPhaseSweep := cali.sweepMaxPhase;
					config.centerFrequencyBPF := (cali.sweepMaxFrequency/2.0)*3;
					
					amplitude_out := 0;
					UpdateFilter := TRUE;
					state := 615;
				ELSE
					// Take smaller steps if percent is more than 20.0.	
					IF Percent > 20.0 AND Percent > (cali.sweepMaxAmplitude-15) THEN
						frequency := frequency - cali.freqStepSizeSmall;
					ELSE
						frequency := frequency - cali.freqStepSize;
					END_IF
				END_IF
			END_IF
		
		615:
			CalibrateStatus := 'Wait for filters to update';
					
			IF UpdateFilterDone THEN
				UpdateFilter := FALSE;
				
				// Prime frequency to start searching for freq that match the phaseshift
				amplitude_out := SEL(MachineSize=0,cali.sweepAmplitudeBigCF,cali.sweepAmplitude);
				frequency := config.maxFrequencySweep;
				PhaseTarget := config.PhaseTarget;
		
					
				PIController_Ampl.FeedForward := 0;
				PIController_Phase.FeedForward := 0;
				cali.setAmplitude := 9.0;  // go to 10% (using 8.0 to get to 10 faster - we just want to get there approx and save values when we are there.)
				
				state := 620;
			END_IF
			
		620:
			CalibrateStatus := 'Wait for controller to find 10%';
			
			time := time + CYCLE_TIME_s;
			
			IF time > 2.0 THEN
				time := 0.0;
				
//				IF PIController_Ampl.Hold THEN
//					PIController_Ampl.Hold := FALSE;
//					PIController_Ampl.Integral := amplitude_out;
//					PIController_Ampl.Output := amplitude_out;
//				END_IF
//				amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);
//			
//				IF PIController_Phase.Hold THEN
//					PIController_Phase.Hold := FALSE;
//					PIController_Phase.Integral := frequency;
//					PIController_Phase.Output := frequency;
//				END_IF
				//				frequency := RoundToPrecision(PIController_Phase.Output, 2);
				
				PIController_Ampl.FeedForward := amplitude_out;
				PIController_Ampl.Integral := 0;
				PIController_Ampl.Output := PIController_Ampl.FeedForward;
				PIController_Ampl.Hold := FALSE;
			
				PIController_Phase.FeedForward := frequency_out;
				PIController_Phase.Integral := 0;
				PIController_Phase.Output := PIController_Phase.FeedForward;
				PIController_Phase.Hold := FALSE;
			
				
				cali.MTDataStatistics_0.Enable := FALSE;
				cali.MTDataStatistics_0();
				
				state := 630;
			END_IF
			
		630:
			
			frequency := RoundToPrecision(PIController_Phase.Output, 2);
			amplitude_out := RoundToPrecision(PIController_Ampl.Output, 3);

			cali.MTDataStatistics_0.Enable := TRUE;
			cali.MTDataStatistics_0.In := Percent;
			cali.MTDataStatistics_0.MovingWindowLength := 30*25; // 30 periods: approx 25 samples per period (1/50hz)/0.0008=25.0
			cali.MTDataStatistics_0();
			
			IF cali.MTDataStatistics_0.Mean > (cali.setAmplitude-0.5) AND cali.MTDataStatistics_0.Mean < (cali.setAmplitude+1.5) THEN // mean between 8.5% - 10.5%
				cali.MTDataStatistics_0.Enable := FALSE;
				cali.MTDataStatistics_0();
				
				PIController_Ampl.Hold := TRUE;
				
				cali.stepSizeAmplitude := SEL(MachineSize=0,0.25,0.1);	// Bigger stepsize for big CF
				time := 0.0;
				count := 0;
				state := 640;
			END_IF
			
		640:
			CalibrateStatus := 'Step up current and save parameters';
		
			cali.MTDataStatistics_0.Enable := TRUE;
			cali.MTDataStatistics_0.In := Percent;
			cali.MTDataStatistics_0.MovingWindowLength := 30*25; // 30 periods: approx 25 samples per period (1/50hz)/0.0008=25.0
			cali.MTDataStatistics_0();
			
			frequency := RoundToPrecision(PIController_Phase.Output, 2);

			time := time + CYCLE_TIME_s;
			
			IF time >= cali.stepTimeAmplitude THEN
				time := 0;
				
				count := LIMIT(0,count,MAX_LOOKUP_IDX);
				IF Percent >= 5.0 THEN
					config.lookUpPercentFromAmplitude.X[count] := ActAmplitude;
					config.lookUpPercentFromAmplitude.Y[count] := cali.MTDataStatistics_0.Mean;	// Mean percent
					
					config.lookUpCurrentFromPercent.X[count] := cali.MTDataStatistics_0.Mean;	// Mean percent
					config.lookUpCurrentFromPercent.Y[count] := amplitude_out;
					
					config.lookupFrequencyFromPercent.X[count] := cali.MTDataStatistics_0.Mean;	// Mean percent
					config.lookupFrequencyFromPercent.Y[count] := frequency;
	
					config.lookupPhaseTargetFromPercent.X[count] := cali.MTDataStatistics_0.Mean; // Mean Percent
					config.lookupPhaseTargetFromPercent.Y[count] := ActPhase;
					
					config.lookupFrequencyFromCurrent.X[count] := amplitude_out;
					config.lookupFrequencyFromCurrent.Y[count] := frequency;
					
					count := count + 1;
				END_IF
					
				// Stop when above 75%. The trend is linear so we can extrapolate.
				IF cali.MTDataStatistics_0.Mean > 75.0 OR amplitude_out >= MaxCurr THEN
					LookupTbl_CurrentFromPercent.Enable := FALSE;
					LookupTbl_CurrentFromPercent();
					LookupTbl_CurrentFromPercent.Enable := TRUE;
					LookupTbl_CurrentFromPercent.X := ADR(config.lookUpCurrentFromPercent.X);
					LookupTbl_CurrentFromPercent.Y := ADR(config.lookUpCurrentFromPercent.Y);
					LookupTbl_CurrentFromPercent.In := 100.0;
					LookupTbl_CurrentFromPercent();
					config.maxCurrentUsed := LookupTbl_CurrentFromPercent.Out;
					
					amplitude_out := amplitude_out/2.0;
					state := 645;
				ELSE
					amplitude_out := amplitude_out + cali.stepSizeAmplitude;
				END_IF
				
				cali.MTDataStatistics_0.Enable := FALSE;
				cali.MTDataStatistics_0();
			END_IF
			
		645:
			time := time + CYCLE_TIME_s;
		
			IF time >= 1.0 THEN
				amplitude_out := 0.0;
				
				IF time >= 2.0 THEN
					// Restet everything like the FB was disabled (Power=false)
					time := 0;
					phi := 0;
					amplitude_out := 0;
					frequency_out := 0;
					Braking := FALSE;
					HoldPhase := FALSE;
					Active := FALSE;
					LookupTbl_PhaseTarget.Enable := FALSE;
					LookupTbl_PhaseTarget();
					LookupTbl_BoostCurrent.Enable := FALSE;
					LookupTbl_BoostCurrent();
					LookupTbl_FreqFromCurrent.Enable := FALSE;
					LookupTbl_FreqFromCurrent();
					LookupTbl_CurrentFromPercent.Enable := FALSE;
					LookupTbl_CurrentFromPercent();
					
					// Jump to 0 and run production code for the test pulses.
					// Save best result
					cali.timePulseTest := 0.0;
					cali.bestTimePulseTest := 9999;
					cali.bestBoostCurrent := 0;
					cali.countPulses := 0;
					measureBoostTime := FALSE;
					TestPulses := TRUE;
					state := 0;
					//state := 647;
				END_IF
			END_IF
			
		647:
			amplitude_out := 0;
			config.vibratorIsCalibrated := TRUE;
			
			time := time + CYCLE_TIME_s;

			IF time >= 1.0 THEN
				time := 0;
				
				// Check if any LUTs are descending
				config.LUTsDescending := FALSE;
				FOR i:=1 TO MAX_LOOKUP_IDX DO
					
					IF config.lookUpPercentFromAmplitude.X[i] < config.lookUpPercentFromAmplitude.X[i-1] AND config.lookUpPercentFromAmplitude.X[i] <> 0.0  THEN
						config.LUTsDescending := TRUE;
					ELSIF config.lookUpCurrentFromPercent.X[i] < config.lookUpCurrentFromPercent.X[i-1] AND config.lookUpCurrentFromPercent.X[i] <> 0.0 THEN
						config.LUTsDescending := TRUE;
					ELSIF config.lookupFrequencyFromPercent.X[i] < config.lookupFrequencyFromPercent.X[i-1] AND config.lookupFrequencyFromPercent.X[i] <> 0.0 THEN
						config.LUTsDescending := TRUE;
					ELSIF config.lookupPhaseTargetFromPercent.X[i] < config.lookupPhaseTargetFromPercent.X[i-1] AND config.lookupPhaseTargetFromPercent.X[i] <> 0.0 THEN
						config.LUTsDescending := TRUE;
					ELSIF config.lookupFrequencyFromCurrent.X[i] < config.lookupFrequencyFromCurrent.X[i-1] AND config.lookupFrequencyFromCurrent.X[i] <> 0.0 THEN
						config.LUTsDescending := TRUE;
					END_IF
					
				END_FOR 
				
				// Save 45% frequency. This is the one maintenance use to adjust vibrator mechanics (found at PJM workshop using ESR2500)
				VibOptimizerFrequency_0.Reset := TRUE;
				VibOptimizerFrequency_0.paramsFrequencyLUT := ADR(config.lookupFrequencyFromPercent);
				VibOptimizerFrequency_0.Key := 45.0;
				VibOptimizerFrequency_0.Get := TRUE;
				VibOptimizerFrequency_0();
				config.maxFrequencySweep := VibOptimizerFrequency_0.Out;
				config.calibrationDone := TRUE;
				SendCaliResultToFAT := TRUE;
				
				state := 650;
			END_IF
						
						
		650:
			SaveConfig := TRUE;
			
			IF SaveConfigDone THEN
				SaveConfig := FALSE;
				
				state:= 660;
			END_IF
			
		660:
			CalibrateStatus := 'Calibration done';
			
			CalibrateDone := TRUE;
			
			IF NOT Calibrate THEN
				CalibrateDone := FALSE;
				state := 0;
			END_IF
		
			
			// State 700 = LF
		700:
			IF ManualControl THEN
				
				IF config.maxCurrentUsed > 0.0 THEN
					VibOptimizerAmplitude_0.Get := TRUE;
					VibOptimizerAmplitude_0.VibratorType := VibratorType;
					VibOptimizerAmplitude_0.Key := ManualPercent;
					VibOptimizerAmplitude_0();
					
					amplitude_out := VibOptimizerAmplitude_0.Out;
					LookupTbl_FreqFromCurrent.In := amplitude_out;
					LookupTbl_FreqFromCurrent();
					frequency := LookupTbl_FreqFromCurrent.Out;
				ELSE
					// no calibration
					amplitude_out := ManualPercent/100*MaxCurr;
					frequency := ManualFrequency;
				END_IF
				
			ELSIF Calibrate THEN
				state := 800;
			ELSE
				
				// --------------------- PROD CODE NO RAMP UP: ---------------------------------------------
				
				// Running production - put amplitude/frequency to match SetAmplitude
//				IF SetAmplitude=0 THEN
//					//lastSetAmplitude := SetAmplitude;
//					amplitude_out := 0;
//					frequency := 0;
//				ELSE
//					//lastSetAmplitude := SetAmplitude;
//					
//					VibOptimizerAmplitude_0.Get := TRUE;
//					VibOptimizerAmplitude_0.VibratorType := VibratorType;
//					VibOptimizerAmplitude_0.Key := SetAmplitude;
//					VibOptimizerAmplitude_0();
//					amplitude_out := VibOptimizerAmplitude_0.Out;
//					
//					LookupTbl_FreqFromCurrent.In := amplitude_out;
//					LookupTbl_FreqFromCurrent();
//					frequency := LookupTbl_FreqFromCurrent.Out;
//					
//				END_IF
				
				// --------------------- RAMP UP PROD CODE: ---------------------------------------------
				
				MTBasicsLimiter_0.In := SetAmplitude;
				MTBasicsLimiter_0.MaxPosSlewRate := RampUp;
				MTBasicsLimiter_0();
				
				// Running production - put amplitude/frequency to match SetAmplitude
				IF SetAmplitude=0 THEN
					//lastSetAmplitude := SetAmplitude;
					amplitude_out := 0;
					frequency := 0;
					MTBasicsLimiter_0.Update := FALSE;
				ELSE
					//lastSetAmplitude := SetAmplitude;
					
					VibOptimizerAmplitude_0.Get := TRUE;
					VibOptimizerAmplitude_0.VibratorType := VibratorType;
					VibOptimizerAmplitude_0.Key := MTBasicsLimiter_0.Out;
					VibOptimizerAmplitude_0();
					amplitude_out := VibOptimizerAmplitude_0.Out;
					
					LookupTbl_FreqFromCurrent.In := amplitude_out;
					LookupTbl_FreqFromCurrent();
					frequency := LookupTbl_FreqFromCurrent.Out;
					
					MTBasicsLimiter_0.Update := TRUE;
				END_IF
				
			END_IF
			
	
			
			//------------------------------------------
			//				CALIBRATION LF
			//------------------------------------------
			
		800:
			CalibrateStatus := 'Find ressonance frequency';
			
			amplitude_out := 0.10;
			frequency := 55.0;
			
			time := time + CYCLE_TIME_s;
			
			IF time >= cali.sweepTimeSteps THEN
				// Reset all vars before starting
				time := 0;
				config.vibratorIsCalibrated := FALSE;
				cali.sweepMaxAmplitude := 0;
				brsmemset(ADR(config.lookUpCurrentFromPercent),0,SIZEOF(config.lookUpCurrentFromPercent));
				brsmemset(ADR(config.lookupFrequencyFromPercent),0,SIZEOF(config.lookupFrequencyFromPercent));
				brsmemset(ADR(config.lookUpPercentFromAmplitude),0,SIZEOF(config.lookUpPercentFromAmplitude));
				brsmemset(ADR(config.lookupPhaseTargetFromPercent),0,SIZEOF(config.lookupPhaseTargetFromPercent));
				brsmemset(ADR(config.lookupFrequencyFromCurrent),0,SIZEOF(config.lookupFrequencyFromCurrent));
				config.maxCurrentUsed := 0.0;
				config.maxFrequencySweep := 0.0;
				config.maxPhaseSweep := 0.0;
				config.timeInCalibrationSeconds := 0.0; // Reset time in calibration
				config.calibrationDone := FALSE;
				config.LUTsDescending := FALSE;
				
				state := 810;
			END_IF
		
		
		810:
			CalibrateStatus := 'Find ressonance frequency';
			
			time := time + CYCLE_TIME_s;
			
			IF time >= cali.sweepTimeSteps THEN
				time := 0;
				IF Percent > cali.sweepMaxAmplitude THEN
					cali.sweepMaxAmplitude := Percent;
					cali.sweepMaxFrequency := frequency;
				END_IF
				
				IF frequency <= 46.0 THEN
					config.maxFrequencySweep := cali.sweepMaxFrequency;
					config.lookupFrequencyFromCurrent.X[0] := amplitude_out;
					config.lookupFrequencyFromCurrent.Y[0] := config.maxFrequencySweep;
					
					amplitude_out := 0;
					state := 815;
				ELSE
					// Determine if we should take small or big frequency steps (depending how close we are to resonance)
					IF Percent > 15.0 AND Percent > (cali.sweepMaxAmplitude-10) THEN
						frequency := frequency - cali.freqStepSizeSmall;
					ELSE
						frequency := frequency - cali.freqStepSize;
					END_IF
				END_IF
			END_IF
		
		815:
			CalibrateStatus := 'Wait for vibrator to be stopped';
			time := time + CYCLE_TIME_s;
			
			IF time >= 1.0 THEN
				time := 0.0;
				state := 820;
			END_IF
			
		820:
			CalibrateStatus := 'Find ressonance frequency at amplitude 2';
			
			amplitude_out := 0.07;
			frequency := config.maxFrequencySweep+1.5;
			
			time := time + CYCLE_TIME_s;
			
			IF time >= 2.0 THEN
				time := 0;
				cali.sweepMaxAmplitude := 0;
				
				state := 830;
			END_IF
			
		830:
			CalibrateStatus := 'Find ressonance frequency at amplitude 2';
			
			time := time + CYCLE_TIME_s;
			
			IF time >= cali.sweepTimeSteps THEN
				time := 0;
				IF Percent > cali.sweepMaxAmplitude THEN
					cali.sweepMaxAmplitude := Percent;
					cali.sweepMaxFrequency := frequency;
				END_IF
				
				IF frequency <= config.maxFrequencySweep THEN
					config.maxFrequencySweep2 := cali.sweepMaxFrequency;
					
					config.lookupFrequencyFromCurrent.X[1] := amplitude_out;
					config.lookupFrequencyFromCurrent.Y[1] := config.maxFrequencySweep2;
					amplitude_out := 0;
					state := 845;
				ELSE
					// always use smaller steps. We know from the previous sweep where to look so it will not be that long (1.50hz)
					frequency := frequency - cali.freqStepSizeSmall;
				END_IF
			END_IF
			
			
			
		845:
			time := time + CYCLE_TIME_s;
		
			IF time >= 1.0 THEN
				time := 0;
				// Update LUT
				LookupTbl_FreqFromCurrent.Enable := FALSE;
				LookupTbl_FreqFromCurrent();
				LookupTbl_FreqFromCurrent.Enable := TRUE;
				LookupTbl_FreqFromCurrent.X := ADR(config.lookupFrequencyFromCurrent.X);
				LookupTbl_FreqFromCurrent.Y := ADR(config.lookupFrequencyFromCurrent.Y);
				
				
				amplitude_out := 0.03; // Start amplitude
				LookupTbl_FreqFromCurrent.In := amplitude_out;
				LookupTbl_FreqFromCurrent();
				frequency := LookupTbl_FreqFromCurrent.Out;
				cali.MTDataStatistics_0.Enable := FALSE;
				cali.MTDataStatistics_0();
				count := 0;
				
				state := 850;
			END_IF
		
		850:
			CalibrateStatus := 'Step up current and save parameters';
		
			cali.MTDataStatistics_0.Enable := TRUE;
			cali.MTDataStatistics_0.In := Percent;
			cali.MTDataStatistics_0.MovingWindowLength := 30*25; // 30 periods: approx 25 samples per period (1/50hz)/0.0008=25.0
			cali.MTDataStatistics_0();

			time := time + CYCLE_TIME_s;
			
			IF time >= cali.stepTimeAmplitude THEN
				time := 0;
				
				count := LIMIT(0,count,MAX_LOOKUP_IDX);
				IF Percent >= 5.0 THEN
					config.lookUpCurrentFromPercent.X[count] := cali.MTDataStatistics_0.Mean;	// Mean percent
					config.lookUpCurrentFromPercent.Y[count] := amplitude_out;
					count := count + 1;
				END_IF
					
				// Stop when above 85%. The trend is linear so we can extrapolate.
				IF cali.MTDataStatistics_0.Mean > 85.0 OR amplitude_out >= MaxCurr THEN
					LookupTbl_CurrentFromPercent.Enable := FALSE;
					LookupTbl_CurrentFromPercent();
					LookupTbl_CurrentFromPercent.Enable := TRUE;
					LookupTbl_CurrentFromPercent.X := ADR(config.lookUpCurrentFromPercent.X);
					LookupTbl_CurrentFromPercent.Y := ADR(config.lookUpCurrentFromPercent.Y);
					LookupTbl_CurrentFromPercent.In := 100.0;
					LookupTbl_CurrentFromPercent();
					config.maxCurrentUsed := LookupTbl_CurrentFromPercent.Out;
					
					amplitude_out := amplitude_out/2.0;
					config.vibratorIsCalibrated := TRUE;
					state := 860;
				ELSE
					amplitude_out := amplitude_out + cali.stepSizeAmplitude;
					LookupTbl_FreqFromCurrent.In := amplitude_out;
					LookupTbl_FreqFromCurrent();
					frequency := LookupTbl_FreqFromCurrent.Out;
				END_IF
				
				cali.MTDataStatistics_0.Enable := FALSE;
				cali.MTDataStatistics_0();
			END_IF
			
		860:
			
			time := time + CYCLE_TIME_s;
			
			IF time >= 1.0 THEN
				amplitude_out := 0.0;
				// Setup
				
				// Check if any LUTs are descending
				config.LUTsDescending := FALSE;
				FOR i:=1 TO MAX_LOOKUP_IDX DO
					
					IF config.lookUpCurrentFromPercent.X[i] < config.lookUpCurrentFromPercent.X[i-1] AND config.lookUpCurrentFromPercent.X[i] <> 0.0 THEN
						config.LUTsDescending := TRUE;
					END_IF
					
				END_FOR 
				
				config.calibrationDone := TRUE;
				SendCaliResultToFAT := TRUE;
				
				state := 870;
			END_IF
			
		870:
			SaveConfig := TRUE;
			
			IF SaveConfigDone THEN
				SaveConfig := FALSE;
				
				state:= 880;
			END_IF
			
		880:
			CalibrateStatus := 'Calibration done';
			
			CalibrateDone := TRUE;
			
			IF NOT Calibrate THEN
				CalibrateDone := FALSE;
				SendCaliResultToFAT := TRUE;
				state := 0;
			END_IF
		
	END_CASE
	
	old_sin := sin_ref;
	frequency_out := LIMIT(20,frequency,60);	

	// create sinewave amplitude with defined frequency
	amplitude_out := LIMIT(-MaxCurr,amplitude_out,MaxCurr);
	sin_out := amplitude_out*SIN(phi+phaseShift);
	sin_abs := ABS(sin_out);
	phi := fmod(phi + frequency*2*PI*CYCLE_TIME_s, 2*PI);
	sin_ref := SIN(phi+phaseShift);
	phaseShift := fmod(phaseShift, 2*PI);
	phaseShiftLocal := fmod(phaseShiftLocal, 2*PI);
	SinePhase := phi;
	SineOut := sin_out;
	
	// Write sine wave to vibrator parID
	MC_BR_CyclicWrite_0.Enable := Enable;
	MC_BR_CyclicWrite_0.Axis := Axis;
	MC_BR_CyclicWrite_0.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicWrite_0.DataAddress := ADR(sin_out);
	MC_BR_CyclicWrite_0.ParID := ACP10PAR_USER_R4_VAR1;
	MC_BR_CyclicWrite_0();
	
	// Gain scheduling
	CASE gainState OF
		0:
			IF SetAmplitudeLatched <> transientSetAmplitude THEN
				// Linear function to determine the transient Kp
				// TransientAmplitudeKp := GetKpFromPercent(ABS(SetAmplitude-transientSetAmplitude));
				//PIController_Ampl.Kp := TransientAmplitudeKp;
				PIController_Ampl.Ki := TransientAmplitudeKi;
				transientSetAmplitude := SetAmplitudeLatched;
				
				ErrorLimitTansient := SetAmplitudeLatched-(SetAmplitudeLatched*ErrorLimitScaling);
				
				TON_Transient.IN := FALSE;
				TON_Transient();
				TON_Transient.IN := TRUE;
				TON_Transient.PT := T#400ms;
			END_IF
			
			TON_Transient();
		
			IF ABS(SetAmplitudeLatched-PIController_Ampl.ProcessValue) < ErrorLimitTansient AND TON_Transient.IN THEN
				IF SetAmplitudeLatched >= LimitValueToUseNormalKpKi THEN
					PIController_Ampl.Kp := SteadyAmplitudeKp;
					PIController_Ampl.Ki := SteadyAmplitudeKi;
				ELSE
					PIController_Ampl.Kp := SteadyLowAmplitudeKp;
					PIController_Ampl.Ki := SteadyLowAmplitudeKi;
				END_IF
			END_IF
		
			IF TON_Transient.Q THEN
				TON_Transient.IN := FALSE;
				TON_Transient();
				
				IF SetAmplitudeLatched >= LimitValueToUseNormalKpKi THEN
					PIController_Ampl.Kp := SteadyAmplitudeKp;
					PIController_Ampl.Ki := SteadyAmplitudeKi;
				ELSE
					PIController_Ampl.Kp := SteadyLowAmplitudeKp;
					PIController_Ampl.Ki := SteadyLowAmplitudeKi;
				END_IF
			END_IF
			
			IF (Calibrate OR ManualControl) AND NOT TestPulses THEN
				gainState := 10;
			END_IF
		
		10:
			// Calbrating just use steadystate parameters
		
			PIController_Ampl.Kp := SteadyLowAmplitudeKp;
			PIController_Ampl.Ki := SteadyLowAmplitudeKi;
			
			IF NOT Calibrate AND NOT ManualControl THEN
				gainState := 0;
			ELSIF TestPulses THEN
				gainState := 0;
			END_IF
			
	END_CASE
	
	IF NOT PIController_Ampl.Enable THEN
		PIController_Ampl.Hold := TRUE;
		PIController_Ampl.Enable := TRUE;
	END_IF
	
	IF TON_Transient.IN THEN
		PIController_Ampl.MinOutput := PIController_Ampl.FeedForward;
	ELSE
		PIController_Ampl.MinOutput := 0.2;
	END_IF
	
	IF NOT Calibrate AND VibratorType=0 OR TestPulses THEN 
		PIController_Ampl.ProcessValue := ActAmplitude;
		PIController_Ampl.Setpoint := SetAmplitudeLatched;
	ELSE
		PIController_Ampl.ProcessValue := SEL(Calibrate,ActAmplitude,Percent);
		PIController_Ampl.Setpoint := SEL(Calibrate,SetAmplitude,cali.setAmplitude);
	END_IF
	PIController_Ampl();
	
	IF NOT PIController_Phase.Enable THEN
		PIController_Phase.Kp := 0.01;
		PIController_Phase.Ki := 0.001;
		PIController_Phase.Hold := TRUE;
		PIController_Phase.Enable := TRUE;
	END_IF
	
	IF SetAmplitudeLatched > 29.0 THEN
		// Phase has ripple on smaller amplitudes so we tune down parameters
		PIController_Phase.Kp := 0.01;
		PIController_Phase.Ki := 0.001;
	ELSE
		PIController_Phase.Kp := 0.004;
		PIController_Phase.Ki := 0.0004;
	END_IF


	PIController_Phase.ProcessValue := ActPhase;
	PIController_Phase.Setpoint := PhaseTarget;
	PIController_Phase();
	
//  TON to detect if controllers are stuck on limit.
	TON_ControllerStuck.IN := (PIController_Ampl.Output =  PIController_Ampl.MaxOutput OR PIController_Phase.Output = PIController_Phase.MaxOutput OR PIController_Phase.Output = PIController_Phase.MinOutput) AND state = 5;
	TON_ControllerStuck();
	
	IF TON_ControllerStuck.Q THEN
		TON_ControllerStuck.IN := FALSE;
		TON_ControllerStuck();
		ErrorTimeout := TRUE;
		time := 0;
		
		state := 80;
	END_IF
END_FUNCTION_BLOCK

FUNCTION_BLOCK PIController
	
	IF NOT Enable AND Active THEN
		state := 0;
		TON_LoopRate.IN := FALSE;
		TON_LoopRate();
		Error := 0;
		Integral := 0;
		Output := 0;
		Active := FALSE;
	END_IF

	CASE state OF
		0:
			IF Enable THEN
				Active := TRUE;
				
				state := 10;
			END_IF
		
		10:
			TON_LoopRate.IN := NOT Hold;
			TON_LoopRate.PT := LoopRate;
			TON_LoopRate();
			
			IF TON_LoopRate.Q THEN
				TON_LoopRate.IN := FALSE;
				TON_LoopRate();
				
				// Calculate the error
				Error := Setpoint - ProcessValue;                 
	    		
				// Anti windup if output is saturated
				IF Output > MinOutput AND Output < MaxOutput THEN
					// Integral accumulation
					Integral := Integral + (Ki * Error);
				END_IF
	    
				// PI controller formula with limits on output
				Output := LIMIT(MinOutput, Kp * Error + Integral + FeedForward, MaxOutput);             
			END_IF
	END_CASE
	
END_FUNCTION_BLOCK

FUNCTION GetCurrentFromAmplitude
	
	//GetCurrentFromAmplitude := 1.1909*Amplitude+0.0396;
	//GetCurrentFromAmplitude := 0.039*Amplitude-0.0485;
	//GetCurrentFromAmplitude := 0.0369*Amplitude-0.0283;
	GetCurrentFromAmplitude := 0.011*Amplitude+0.1434;
	
END_FUNCTION

FUNCTION GetFrequencyFromAmplitude
	
	//GetFrequencyFromAmplitude := -1.0388*Amplitude+50.362;
	//GetFrequencyFromAmplitude := -0.0256*Amplitude+50.267;
	//GetFrequencyFromAmplitude := -0.0275*Amplitude+50.352;
	GetFrequencyFromAmplitude := -0.0114*Amplitude+50.294;
	
END_FUNCTION

FUNCTION GetPhaseTargetFromFrequency

	GetPhaseTargetFromFrequency := 20.69*Frequency - 930.34;
	
END_FUNCTION

FUNCTION GetKpFromPercent
	
	GetKpFromPercent := -0.00007*Amplitude+0.0116;
	
END_FUNCTION

FUNCTION GetBrakeTimeFromAmplitude
	
	IF MachineSize=0 THEN
		b := 40.0;
		GetBrakeTimeFromAmplitude := PercentChange/(803.5*CurrentAmplitude-b);
	ELSE
		b := 242.88;
		GetBrakeTimeFromAmplitude := PercentChange/(384.06*CurrentAmplitude-b);
	END_IF
	
END_FUNCTION


FUNCTION_BLOCK VibOptimizerAmplitude
	
	IF VibratorType=1 THEN
		// LF just lookup - dont set or get anything because we currently have no feedback!
		LookupTbl_Amplitude.Enable := FALSE;
		LookupTbl_Amplitude();
		LookupTbl_Amplitude.Enable := TRUE;
		LookupTbl_Amplitude.X := ADR(paramsCurrentLUT.X);
		LookupTbl_Amplitude.Y := ADR(paramsCurrentLUT.Y);
		LookupTbl_Amplitude.In := Key;
		LookupTbl_Amplitude();
		Out := LookupTbl_Amplitude.Out;
	ELSIF Set THEN
		Set := FALSE;
		
		found := FALSE;
		FOR i:=0 TO MAX_ELEMENTS DO
			IF lookup[i].key = Key THEN
				found := TRUE;
				IF ABS(Error) < lookup[i].error THEN
					lookup[i].value := Value;
					lookup[i].error := ABS(Error);
				END_IF
				EXIT;
			END_IF
		END_FOR

		IF NOT found THEN
			lookup[lastIdx].value := Value;
			lookup[lastIdx].key := Key;
			lookup[lastIdx].error := ABS(Error);
			lastIdx := (lastIdx + 1) MOD MAX_ELEMENTS;
		END_IF

	ELSIF Get THEN
		Get := FALSE;
		
		found := FALSE;
		FOR i:=0 TO MAX_ELEMENTS DO
			IF lookup[i].key = Key THEN
				found := TRUE;
				Out := lookup[i].value;
				EXIT;
			END_IF
		END_FOR

		IF NOT found THEN
			LookupTbl_Amplitude.Enable := FALSE;
			LookupTbl_Amplitude();
			LookupTbl_Amplitude.Enable := TRUE;
			LookupTbl_Amplitude.X := ADR(paramsCurrentLUT.X);
			LookupTbl_Amplitude.Y := ADR(paramsCurrentLUT.Y);
			LookupTbl_Amplitude.In := Key;
			LookupTbl_Amplitude();
			Out := LookupTbl_Amplitude.Out;
			
			lookup[lastIdx].value := Out;
			lookup[lastIdx].key := Key;
			lookup[lastIdx].error := 100;
			lastIdx := (lastIdx + 1) MOD MAX_ELEMENTS;
		
		END_IF

	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK VibOptimizerFrequency
	
	IF Reset THEN
		Reset := FALSE;
		brsmemset(ADR(lookup),0,SIZEOF(lookup));
	END_IF
	
	IF Set THEN
		Set := FALSE;
		
		found := FALSE;
		FOR i:=0 TO MAX_ELEMENTS DO
			IF lookup[i].key = Key THEN
				found := TRUE;
				IF ABS(Error) < lookup[i].error THEN
					lookup[i].value := Value;
					lookup[i].error := ABS(Error);
				END_IF
				EXIT;
			END_IF
		END_FOR

		IF NOT found THEN
			lookup[lastIdx].value := Value;
			lookup[lastIdx].key := Key;
			lookup[lastIdx].error := ABS(Error);
			lastIdx := (lastIdx + 1) MOD MAX_ELEMENTS;
		END_IF

	ELSIF Get THEN
		Get := FALSE;
		
		found := FALSE;
		FOR i:=0 TO MAX_ELEMENTS DO
			IF lookup[i].key = Key THEN
				found := TRUE;
				Out := lookup[i].value;
				EXIT;
			END_IF
		END_FOR

		IF NOT found OR Key = 0.0 THEN
			LookupTbl_Frequency.Enable := FALSE;
			LookupTbl_Frequency();
			LookupTbl_Frequency.Enable := TRUE;
			LookupTbl_Frequency.X := ADR(paramsFrequencyLUT.X);
			LookupTbl_Frequency.Y := ADR(paramsFrequencyLUT.Y);
			LookupTbl_Frequency.In := Key;
			LookupTbl_Frequency();
			Out := LookupTbl_Frequency.Out;
			
			lookup[lastIdx].value := Out;
			lookup[lastIdx].key := Key;
			lookup[lastIdx].error := 100;
			lastIdx := (lastIdx + 1) MOD MAX_ELEMENTS;
		END_IF

	END_IF
	
END_FUNCTION_BLOCK