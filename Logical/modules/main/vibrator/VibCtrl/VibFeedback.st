FUNCTION_BLOCK VibFeedback
	
	MC_BR_CyclicRead_0.Enable := Enable;
	MC_BR_CyclicRead_0.Axis := Axis;
	//MC_BR_CyclicRead_0.ParID := 14433;
	//MC_BR_CyclicRead_0.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicRead_0.DataAddress := ADR(voltage[1]); // voltage[2] = voltage[i-1]
	MC_BR_CyclicRead_0();
		
	MC_BR_CyclicRead_1.Enable := Enable;
	MC_BR_CyclicRead_1.Axis := Axis;
	//MC_BR_CyclicRead_1.ParID := 14425;
	//MC_BR_CyclicRead_1.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicRead_1.DataAddress := ADR(voltage[2]); // voltage[3] = voltage[i]
	MC_BR_CyclicRead_1();
						
	MC_BR_CyclicRead_2.Enable := Enable;
	MC_BR_CyclicRead_2.Axis := Axis;
	//MC_BR_CyclicRead_2.ParID := 14435;
	//MC_BR_CyclicRead_2.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicRead_2.DataAddress := ADR(current[1]); // current[2] = current[i-1]
	MC_BR_CyclicRead_2();
				
	MC_BR_CyclicRead_3.Enable := Enable;
	MC_BR_CyclicRead_3.Axis := Axis;
	//MC_BR_CyclicRead_3.ParID := 14427;
	//MC_BR_CyclicRead_3.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicRead_3.DataAddress := ADR(current[2]); // current[3] = current[i]
	MC_BR_CyclicRead_3();

	// Go to 0 and update filters if we get Update command
	IF UpdateFilter AND NOT oldUpdateFilter THEN
		state := 0;
	END_IF
	oldUpdateFilter := UpdateFilter;
	
	TON_PhaseValid.IN := Amplitude_out > 0.0;
	TON_PhaseValid();
	
	FOR i:=1 TO 2 DO
		
		CASE state OF
			0:
				
				IF Enable THEN
					// Setup FBs.
					MTFilterBandPass_3rdHarmonic.Enable := TRUE;
					MTFilterBandPass_3rdHarmonic.CenterFrequency := config.centerFrequencyBPF;
					MTFilterBandPass_3rdHarmonic.Bandwidth := SEL(MachineSize=0,2.5,10.0);
					MTFilterBandPass_3rdHarmonic.Order := 2;
					MTFilterBandPass_3rdHarmonic.Type := mtFILTER_BUTTERWORTH;
					
					MTFilterLowPass_Amplitude.Enable := TRUE;
					MTFilterLowPass_Amplitude.Order := 2;
					MTFilterLowPass_Amplitude.CutOffFrequency := 300;
		
					MTFilterLowPass_Phase.Enable := TRUE;
					MTFilterLowPass_Phase.Order := 2;
					MTFilterLowPass_Phase.CutOffFrequency := 300;
			
					TON_PhaseValid.PT := SEL(MachineSize=0,T#150ms,T#100ms);
					hammingLength := SEL(MachineSize=0,100,50); // 50 for small CF, 100 for big CF
					
					// Create hamming window
					FOR j:=0 TO MAX_SAMPLES_GOERTZEL DO
						hammingWindow[j] := getHammingWindow(MAX_SAMPLES_GOERTZEL,j);
					END_FOR
					
					IF UpdateFilter THEN
						state := 5;
					ELSE
						state := 10;
					END_IF
				END_IF
				
			5:
				MTFilterBandPass_3rdHarmonic.Update := TRUE;
				MTFilterBandPass_3rdHarmonic();
				
				UpdateFilterDone := MTFilterBandPass_3rdHarmonic.UpdateDone;
				
				IF NOT UpdateFilter THEN
					UpdateFilterDone := FALSE;
					MTFilterBandPass_3rdHarmonic.Update := FALSE;
					MTFilterBandPass_3rdHarmonic();
					state := 10;
				END_IF
				
			10:
				
				IF Amplitude_out > 0.0 THEN
					time := time + dt; // Because it is a for-loop it will run in 400us
					timeHalfPeriod := (1/Frequency)*0.5;
					voltageZeroCrossing := (voltage[i-1] <= 0 AND voltage[i] > 0) OR (voltage[i-1] >= 0 AND voltage[i] < 0);
				END_IF
				
				
				IF time >= timeHalfPeriod AND voltageZeroCrossing THEN
					time := 0;
					IF Amplitude_out > 0.0 THEN
						hammingIdx := 0;
						AmplitudeCurrent := SEL(Amplitude_out > 0.0,0.01,Amplitude_out); // SEL to avoid division by 0
						
						LookupTbl_Percent.Enable := TRUE;
						LookupTbl_Percent.X := ADR(config.lookUpPercentFromAmplitude.X);
						LookupTbl_Percent.Y := ADR(config.lookUpPercentFromAmplitude.Y);
						LookupTbl_Percent();
						
						goertzelCount := 0;
						
						state := 20;
					END_IF
				ELSE
					MTFilterBandPass_3rdHarmonic.In := 0;
					MTFilterBandPass_3rdHarmonic();
					MTFilterLowPass_Amplitude.In := 0;
					MTFilterLowPass_Amplitude();
					MTFilterLowPass_Phase.In := 90;
					MTFilterLowPass_Phase();
				END_IF
				
//			15:
//				
//				MTFilterBandPass_3rdHarmonic.In := (voltage[i]);
//				IF hammingIdx < hammingLength/2 THEN
//					MTFilterBandPass_3rdHarmonic.In := MTFilterBandPass_3rdHarmonic.In * HammingWindow(hammingIdx, hammingLength);
//					hammingIdx := hammingIdx + 1;
//				END_IF
//				MTFilterBandPass_3rdHarmonic();
//				Feedback := MTFilterBandPass_3rdHarmonic.Out/AmplitudeCurrent;
//				
//				IF (current[i-1] >= 0 AND current[i] < 0) OR (current[i-1] <= 0 AND current[i] > 0) THEN
//					state := 20;
//				END_IF
				
			20:
				IF Braking THEN
					time := 0;
					Amplitude := BrakingToAmplitudePct;
					MTFilterBandPass_3rdHarmonic.In := 0.0; // Prime with 0 because we start again after brake at zero-crossing
					MTFilterBandPass_3rdHarmonic();
					MTFilterLowPass_Amplitude.In := BrakingToAmplitudePct; // Prime with the amplitude (in percent) we are braking to open-loop.
					MTFilterLowPass_Amplitude();
					
					state := 30;
				ELSIF Amplitude_out > 0.0 THEN
					
				
					MTFilterBandPass_3rdHarmonic.In := voltage[i];
					IF hammingIdx < hammingLength/2 THEN
						MTFilterBandPass_3rdHarmonic.In := MTFilterBandPass_3rdHarmonic.In * HammingWindow(hammingIdx, hammingLength);
						hammingIdx := hammingIdx + 1;
					END_IF
					MTFilterBandPass_3rdHarmonic();
					Feedback := MTFilterBandPass_3rdHarmonic.Out/AmplitudeCurrent;
			
					
					IF ABS(Feedback) > peakVib THEN
						peakVib := ABS(Feedback);
					END_IF
					
					IF ABS(current[i]) > peakCurr THEN
						peakCurr := ABS(current[i]);
					END_IF
					
					// Detect zero-crossings on current.
					IF (current[i-1] >= 0 AND current[i] < 0) THEN
						LookupTbl_Percent.In := peakVib;
						LookupTbl_Percent();
						
						MTFilterLowPass_Amplitude.In := SEL(Calibrating,LookupTbl_Percent.Out,peakVib);  // If calibrating use peakVib directly (the LUT is being updated by VibControl)
						MTFilterLowPass_Amplitude();
						Amplitude := MTFilterLowPass_Amplitude.Out;
						AmplitudeRaw := peakVib;
						AmplitudeCurrent := SEL(peakCurr > 0.0,0.01,peakCurr); // SEL to avoid division by 0
						AmplitudeValid := TRUE;
						
						peakVib := 0;
						peakCurr := 0;
					END_IF
					
		
		
//					IF (lastBPF >= 0 AND Feedback < 0) AND lastSinePhase < SinePhase AND NOT HoldPhase THEN
//						feedbackInterpolation := (((-lastBPF)/(Feedback-lastBPF))+(i-1))/2.0;
//						IF SinePhase < 2.0*PI/3.0 THEN
//							MTFilterLowPass_Phase.In := lastSinePhase + (SinePhase-lastSinePhase)*feedbackInterpolation;
//							MTFilterLowPass_Phase.In := ((MTFilterLowPass_Phase.In / 2.0*PI/3.0) * 180) - SEL(Braking, 0, 90);
//							MTFilterLowPass_Phase();
//							Phase := MTFilterLowPass_Phase.Out;
//							PhaseValid := TRUE;
//						END_IF
//					END_IF
				

	
					IF goertzelCount <= MAX_SAMPLES_GOERTZEL THEN
						samples[goertzelCount] := voltage[i];
						samplesCurr[goertzelCount] := current[i];
						goertzelCount := goertzelCount+1;
					ELSIF current[i-1] <= 0.0 AND current[i] > 0.0 THEN
						goertzelMagPhase_0.samples := ADR(samples);
						goertzelMagPhase_0.window := ADR(hammingWindow);
						goertzelMagPhase_0.frequency := (Frequency)*3;
						goertzelMagPhase_0.sampleRate := 2500;
						goertzelMagPhase_0();
						phase[0] := goertzelMagPhase_0.phase;
						goertzelMagPhase_1.samples := ADR(samples);
						goertzelMagPhase_1.window := ADR(hammingWindow);
						goertzelMagPhase_1.frequency := Frequency;
						goertzelMagPhase_1.sampleRate := 2500;
						goertzelMagPhase_1();
						phase[1] := goertzelMagPhase_0.phase;
						goertzelMagPhase_2.samples := ADR(samplesCurr);
						goertzelMagPhase_2.window := ADR(hammingWindow);
						goertzelMagPhase_2.frequency := (Frequency)*3;
						goertzelMagPhase_2.sampleRate := 2500;
						goertzelMagPhase_2();
						phase[2] := goertzelMagPhase_0.phase;
						goertzelMagPhase_3.samples := ADR(samplesCurr);
						goertzelMagPhase_3.window := ADR(hammingWindow);
						goertzelMagPhase_3.frequency := Frequency;
						goertzelMagPhase_3.sampleRate := 2500;
						goertzelMagPhase_3();
						phase[3] := goertzelMagPhase_0.phase;
						oldGoertzelPhaseStart := goertzelPhaseStart;
						goertzelCount := 0;
						goertzelRef := fmod((goertzelMagPhase_3.phase+PI)*3, 2*PI);
						goertzelSignal := goertzelMagPhase_0.phase+PI;
						goertzelPhase := (goertzelRef - goertzelSignal) * 180.0/PI;
						
						
						IF NOT HoldPhase THEN
							Phase := goertzelPhase;
							PhaseValid := TON_PhaseValid.Q;
						END_IF
						
						
						//						goertzelPhase := (goertzelMagPhase_3.phase-goertzelMagPhase_0.phase/3) * 180.0/PI;
						//						IF goertzelPhase <= -120 THEN
						//							goertzelPhase := (goertzelPhase + 240.0) / 120.0 * 360.0;
						//						ELSIF goertzelPhase <= 0 THEN
						//							goertzelPhase := (goertzelPhase + 120.0) / 120.0 * 360.0;
						//						ELSIF goertzelPhase <= 120 THEN
						//							goertzelPhase := (goertzelPhase) / 120.0 * 360.0;
						//						ELSE
						//							goertzelPhase := (goertzelPhase - 120.0) / 120.0 * 360.0;
						//						END_IF
							
						goertzelPhaseComp := goertzelPhase-goertzelPhaseStart*goertzelScaling;
						goertzelPhaseStart := SinePhase;
						
						// Goertzel amplitude
						AmplitudeGoertzel := goertzelMagPhase_0.magnitude/AmplitudeCurrent;
					END_IF
				
		
					
					// last:
					lastBPF := Feedback;
				ELSE
					LookupTbl_Percent.In := 0;
					LookupTbl_Percent();
					LookupTbl_Percent.Enable := FALSE;
					LookupTbl_Percent();
					peakVib := 0;
					Amplitude := 0;
					AmplitudeGoertzel := 0;
					AmplitudeRaw := 0;
					Phase := 0;
					PhaseGoertzel := 0;
					cnt := 0;
					lastBPF := 0;
					time := 0;
					PhaseValid := FALSE;
					AmplitudeValid := FALSE;
	
					ActAmplitudeGoertzel := 0;
					state := 10;
				END_IF
			
			30:
				
				IF NOT Braking THEN
					time := time + dt;
					timeHalfPeriod := (1/Frequency)*0.5;
					voltageZeroCrossing := (voltage[i-1] <= 0 AND voltage[i] > 0) OR (voltage[i-1] >= 0 AND voltage[i] < 0);
					
					IF time >= timeHalfPeriod AND voltageZeroCrossing THEN
						goertzelCount := 0;
						peakVib := 0;
						time := 0;
						peakCurr := Amplitude_out; // amplitude_out was much bigger when brake started - therefore set amplitude_out to the setpoint we use now. That will be much closer to the actual current amplitude.
						state := 20;
					END_IF	
				END_IF
				MTFilterBandPass_3rdHarmonic.In := 0.0;
				MTFilterBandPass_3rdHarmonic();
				MTFilterLowPass_Amplitude.In := BrakingToAmplitudePct; // Prime with the amplitude (in percent) we are braking to open-loop.
				MTFilterLowPass_Amplitude();
			
		END_CASE
	
	END_FOR
	
	lastSinePhase := SinePhase;

	// Calc phase with accelerometer using 800us: (only for testing!!)
	IF Calibrating OR testPhaseUsingAcc THEN
		IF (lastCurrAcc <= 0 AND SineOut > 0) THEN
			tmpTimeAcc := (-lastCurrAcc*0.0008)/(SineOut-lastCurrAcc);  						// Calculate the time of zero crossing
			cntAcc := 0;				
			CalcPhasePosAcc := TRUE;
		END_IF
		
		IF CalcPhasePosAcc THEN
							
			IF (lastRawVib <= 0 AND RawVib > 0) AND cntAcc > 1 THEN
				tmpTimeAirgap := ((-lastRawVib*0.0008)/(RawVib-lastRawVib));
				PhaseAcc := (cntAcc*0.0008 + tmpTimeAirgap + (0.0008 - lastTmpTimeAcc)) / (1.0/(Frequency * 2.0)) * 180.0; 
				CalcPhasePosAcc := FALSE;
			END_IF
			cntAcc := cntAcc + 1;
		END_IF
	END_IF
	
	// Save last
	voltage[0] := voltage[2];
	current[0] := current[2];
	lastRawVib := RawVib;
	lastTmpTimeAcc := tmpTimeAcc;
	lastCurrAcc := SineOut;
END_FUNCTION_BLOCK

FUNCTION_BLOCK VibFeedbackOld
	
	CASE state OF
		0:
			IF Enable THEN
				currentLPF[0] := 0;
				voltageLPF[0] := 0;
				IF Simulation THEN
					state := 100;
				ELSE
					state := 10;
				END_IF
			END_IF
		
		10:
//			
//			MC_BR_CyclicRead_2.Enable := TRUE;
//			MC_BR_CyclicRead_2.Axis := Axis;
//			MC_BR_CyclicRead_2.ParID := 14433;
//			MC_BR_CyclicRead_2.DataType := ncPAR_TYP_REAL;
//			MC_BR_CyclicRead_2.DataAddress := ADR(voltage[1]); // voltage[2] = voltage[i-1]
//			MC_BR_CyclicRead_2();
//		
//			MC_BR_CyclicRead_3.Enable := TRUE;
//			MC_BR_CyclicRead_3.Axis := Axis;
//			MC_BR_CyclicRead_3.ParID := 14425;
//			MC_BR_CyclicRead_3.DataType := ncPAR_TYP_REAL;
//			MC_BR_CyclicRead_3.DataAddress := ADR(voltage[2]); // voltage[3] = voltage[i]
//			MC_BR_CyclicRead_3();
//						
//			MC_BR_CyclicRead_6.Enable := TRUE;
//			MC_BR_CyclicRead_6.Axis := Axis;
//			MC_BR_CyclicRead_6.ParID := 14435;
//			MC_BR_CyclicRead_6.DataType := ncPAR_TYP_REAL;
//			MC_BR_CyclicRead_6.DataAddress := ADR(current[1]); // current[2] = current[i-1]
//			MC_BR_CyclicRead_6();
//				
//			MC_BR_CyclicRead_7.Enable := TRUE;
//			MC_BR_CyclicRead_7.Axis := Axis;
//			MC_BR_CyclicRead_7.ParID := 14427;
//			MC_BR_CyclicRead_7.DataType := ncPAR_TYP_REAL;
//			MC_BR_CyclicRead_7.DataAddress := ADR(current[2]); // current[3] = current[i]
//			MC_BR_CyclicRead_7();
//			
//			MC_BR_CyclicReadDataInfo_0.Enable := TRUE;
//			MC_BR_CyclicReadDataInfo_0.Axis := Axis;
//			MC_BR_CyclicReadDataInfo_0();

			FOR i:=1 TO 2 DO
				// Generating the LPF current and voltage of the subsampled current and voltage from the drive
				MTFilterLowPass_0.Enable := TRUE;
				MTFilterLowPass_0.Order := 4;
				MTFilterLowPass_0.CutOffFrequency := CutOffFrequency;
				MTFilterLowPass_0.In := current[i];
				MTFilterLowPass_0();
					
				MTFilterLowPass_1.Enable := TRUE;
				MTFilterLowPass_1.Order := 4;
				MTFilterLowPass_1.CutOffFrequency := CutOffFrequency;
				MTFilterLowPass_1.In := voltage[i];
				MTFilterLowPass_1();
				
				currentLPF[i] := MTFilterLowPass_0.Out;
							
				TimeDelay_0.Enable := TRUE;
				TimeDelay_0.Dt := 0.0004;
				TimeDelay_0.In := MTFilterLowPass_1.Out;
				TimeDelay_0.Delay := TimeDelayVoltage;
				TimeDelay_0();
				voltageLPF[i] := TimeDelay_0.Out;

			END_FOR
			
			TON_RunDelay.IN := RunCalculation;
			TON_RunDelay.PT := RunDelay;
			TON_RunDelay();
			
			IF NOT TON_RunDelay.Q THEN
				Amplitude := 0;
				AmplitudeFast := 0;
				Phase := 0;
				PhaseHMI := 0;
				IF NOT MTFilterBandPass_Airgap.Enable THEN
					MTFilterBandPass_Airgap.CenterFrequency := 50;
					MTFilterBandPass_Airgap.Bandwidth := 30;
					MTFilterBandPass_Airgap.Order := 1;
				END_IF
				MTFilterBandPass_Airgap.Enable := TRUE;
				MTFilterBandPass_Airgap.In := meanAirgap;
				MTFilterBandPass_Airgap();
				IF NOT MTFilterBandPass_AirgapFast.Enable THEN
					MTFilterBandPass_AirgapFast.CenterFrequency := 50;
					MTFilterBandPass_AirgapFast.Bandwidth := 30;
					MTFilterBandPass_AirgapFast.Order := 1;
				END_IF
				MTFilterBandPass_AirgapFast.Enable := TRUE;
				MTFilterBandPass_AirgapFast.In := meanAirgap;
				MTFilterBandPass_AirgapFast();
			END_IF
			
			TON_CalcDelay.IN := RunCalculation;
			TON_CalcDelay.PT := CalcDelay;
			TON_CalcDelay();
			
			IF RunCalculation THEN
				FOR i:=1 TO 2 DO
					// If zero crossing of the the current has occured (rising or falling)
					IF (currentLPF[i-1] <= 0 AND currentLPF[i] > 0) OR (currentLPF[i-1] >= 0 AND currentLPF[i] < 0) THEN
						// Calculation of the complete commulative integral to the point at zero crossing
						tmpTime := (-currentLPF[i-1]*dt)/(currentLPF[i]-currentLPF[i-1]);  						// Calculate the time of zero crossing
						a := (voltageLPF[i]-voltageLPF[i-1])/dt;					  							// Calculate voltage slope
						zeroVolt := a*tmpTime+voltageLPF[i-1];						  								// Calculate the voltage at zero crossing
						intCurr[i] := intCurr[i-1] + (0.5*(0+currentLPF[i-1])*(tmpTime)); 		  					// Calculate the instantenous integration of the current at zero crossing
						intVolt[i] := intVolt[i-1] + (0.5*(zeroVolt+voltageLPF[i-1])*(tmpTime));  					// Calculate the instantenous integration of the voltage at zero crossing
						IF intCurr[i] <> 0 THEN
							res := intVolt[i]/intCurr[i];
						ELSE
							res := intVolt[i]/0.00000001;
						END_IF
		
						voltZeroOffset := intVolt[i] / 2;
						currZeroOffset := intCurr[i] / 2;
						
						IF TON_RunDelay.Q THEN
							// IMPLEMENTATION OF CONTROL ALGORITHM HERE!
							// Calculate the airgap for half a current wave
							FOR j:=0 TO lastidx-1 DO
								intVoltBuffer[j] := intVoltBuffer[j] - voltZeroOffset;
								intCurrBuffer[j] := intCurrBuffer[j] - currZeroOffset;
								intEMF[j]		:= intVoltBuffer[j]-(res*intCurrBuffer[j]);
								
								
								IF intEMF[j] <> 0 THEN
									tmpAirgap := currentLPFBuffer[j] / intEMF[j] ; // Airgap
								ELSE
									tmpAirgap := currentLPFBuffer[j] / 0.00000001;
								END_IF
								
								tmpAirgap := LIMIT(-1000, tmpAirgap, 1000);
	
								MTFilterBandPass_Airgap.Enable := TRUE;
								MTFilterBandPass_Airgap.In := tmpAirgap;
								MTFilterBandPass_Airgap();
								
								MTFilterBandPass_AirgapFast.Enable := TRUE;
								MTFilterBandPass_AirgapFast.In := tmpAirgap;
								MTFilterBandPass_AirgapFast();
								
								IF RawAirgap THEN
									airgap[j] := MTFilterBandPass_AirgapFast.Out;
								ELSE
									airgap[j] := MTFilterBandPass_Airgap.Out;
								END_IF
								
								
							END_FOR
	
							phaseFound := FALSE;
							FOR j:=1 TO lastidx-1 DO	
								IF ABS(airgap[j]) > peakVib THEN
									peakVib := ABS(airgap[j]); // Peak vibration for comparison
								END_IF
										
								IF (airgap[j-1] >= 0 AND airgap[j] < 0) AND NOT phaseFound THEN // Falling edge	
									tmpTimeAirgap := ((-airgap[j-1]*dt)/(airgap[j]-airgap[j-1]));
									lastTmpTimeMinusDt := dt - lastTmpTime;
									phaseCalc := ((j-1)*dt + tmpTimeAirgap + (dt - lastTmpTime)) / (1.0/(Frequency * 2.0)) * 180.0; 
									phaseCalc := phaseCalc + PhaseOffset;
									IF phaseCalc > 180 THEN
										phaseCalc := phaseCalc - 180;
									END_IF
									indexJ := j-1;
									phaseFound := TRUE;
								END_IF
								
							END_FOR
								
							peak3rdHarmonic := 0.0;
							FOR j:=0 TO idx DO
								
								IF ABS(voltage3rdHarmonic[j]) > peak3rdHarmonic THEN
									peak3rdHarmonic := ABS(voltage3rdHarmonic[j]);
								END_IF
								
							END_FOR
							
							IF NOT MTFilterLowPass_Ampl.Enable THEN
								MTFilterLowPass_Ampl.Enable := TRUE;
								MTFilterLowPass_Ampl.Order := 2;
								MTFilterLowPass_Ampl.CutOffFrequency := 250;
							END_IF
							MTFilterLowPass_Ampl.In := peakVib;
							MTFilterLowPass_Ampl();
							
							KalmanFilter1D_Ampl.Measurement := peakVib;
							KalmanFilter1D_Ampl();
							IF NOT KalmanFilter1D_Ampl.Enable THEN
								KalmanFilter1D_Ampl.Enable := TRUE;
								KalmanFilter1D_Ampl.KalmanGain := 0.1;
								KalmanFilter1D_Ampl.MeasureVariance := 1;
								KalmanFilter1D_Ampl.ProcessVariance := 0.1;
							END_IF
								
							IF NOT MTFilterLowPass_Phase.Enable THEN
								MTFilterLowPass_Phase.Enable := TRUE;
								MTFilterLowPass_Phase.Order := 2;
								MTFilterLowPass_Phase.CutOffFrequency := 250;
							END_IF
							
							IF NOT HoldPhase THEN
								MTFilterLowPass_Phase.In := phaseCalc;
								MTFilterLowPass_Phase();
							END_IF
							
							IF NOT MTBasicsDT1_ActAmpl.Enable THEN
								MTBasicsDT1_ActAmpl.Gain := 1;
								MTBasicsDT1_ActAmpl.TimeConstant := 1;
							END_IF
							MTBasicsDT1_ActAmpl.Enable := TRUE;
							MTBasicsDT1_ActAmpl.In := MTFilterLowPass_Ampl.Out;
							MTBasicsDT1_ActAmpl();
							
							IF TON_RunDelay.Q THEN
								Amplitude := RoundToPrecision(MTFilterLowPass_Ampl.Out, 3);
								AmplitudeFast := RoundToPrecision(MTFilterLowPass_Ampl.In, 3);
								Phase := RoundToPrecision(MTFilterLowPass_Phase.Out, 0);
								PhaseFast := RoundToPrecision(MTFilterLowPass_Phase.In, 0);
//								Amplitude := MTFilterLowPass_Ampl.Out;
//								AmplitudeFast := MTFilterLowPass_Ampl.In;
//								Phase := MTFilterLowPass_Phase.Out;
//								PhaseFast := MTFilterLowPass_Phase.In;
								PhaseHMI := Phase;
							END_IF
						END_IF
							
					
						
						// Value for comparison to correct airgap trace in 800�s
						tmpAirgapTrace := lastidx;
						// Reset last array index and Summed airgap
						lastidx    	:= 0;
						peakVib 	:= 0;
						idx := 0;
						// Reset cummulative integrals
						intCurr[i] := (0.5*(currentLPF[i]+0)*(dt-tmpTime)); 						// Reset the cummulative integration of the current
						intVolt[i] := (0.5*(voltageLPF[i]+zeroVolt)*(dt-tmpTime));  						// Reset the cummulative integration of the voltage
							
						// Put values into buffer and increment the last index 
						intVoltBuffer[lastidx] := intVolt[i];
						intCurrBuffer[lastidx] := intCurr[i];
						currentLPFBuffer[lastidx] := currentLPF[i];
						lastidx := lastidx + 1;
						lastTmpTime := tmpTime;
						// IF NO RISING OR FALLING EDGE ON CURRENT 		
					ELSE
						intCurr[i] := intCurr[i-1] + (0.5*(currentLPF[i]+currentLPF[i-1])*dt);				// Calculate the cummulative integration of the current
						intVolt[i] := intVolt[i-1] + (0.5*(voltageLPF[i]+voltageLPF[i-1])*dt); 			// Calculate the cummulative integration of the voltage
						// Put values into buffer and increment the last index 
						intVoltBuffer[lastidx] := intVolt[i];
						intCurrBuffer[lastidx] := intCurr[i];
						currentLPFBuffer[lastidx] := currentLPF[i];
							
						IF lastidx = tmpAirgapTrace THEN
							airgap1 := airgap[lastidx];
							intCurr1 := intCurrBuffer[lastidx];
							intVolt1 := intVoltBuffer[lastidx];
						ELSIF lastidx < tmpAirgapTrace THEN
							airgap1 := airgap[lastidx];
							airgap2 := airgap[lastidx+1];
							intCurr1 := intCurrBuffer[lastidx];
							intCurr2 := intCurrBuffer[lastidx+1];
							intVolt1 := intVoltBuffer[lastidx];
							intVolt2 := intVoltBuffer[lastidx+1];
						END_IF
						lastidx := lastidx + 1;
					END_IF
					
					
					IF NOT MTFilterBandPass_Voltage3rd.Enable THEN
						MTFilterBandPass_Voltage3rd.CenterFrequency := 75;
						MTFilterBandPass_Voltage3rd.Bandwidth := 5;
						MTFilterBandPass_Voltage3rd.Order := 2;
					END_IF
					MTFilterBandPass_Voltage3rd.Enable := TRUE;
			
				
					IF SimCurrent > 0.0 THEN
						voltage3rdHarmonic[idx] := MTFilterBandPass_Voltage3rd.Out/SimCurrent;
						idx := LIMIT(0,idx+1,255);
						MTFilterBandPass_Voltage3rd.In := voltage[i];
					ELSE
						MTFilterBandPass_Voltage3rd.In := 0;
					END_IF
					MTFilterBandPass_Voltage3rd();
					
				END_FOR

				currentLPF[0] := currentLPF[2]; // Save the last value of this data in the first of next call
				voltageLPF[0] := voltageLPF[2]; // Save the last value of this data in the first of next call
				intCurr[0] := intCurr[2]; 		// Save the last value of this data in the first of next call
				intVolt[0] := intVolt[2]; 		// Save the last value of this data in the first of next call
			ELSE
				FOR i:=1 TO 2 DO
					MTFilterBandPass_Voltage3rd.In := voltage[i];
					MTFilterBandPass_Voltage3rd();
				END_FOR
			END_IF		
		
		100:
			// Simulation
			
			// 10% Current
			// 100% Current
			// 10% Frequency
			// 100% Frequency

			// Calculate amplitude
			simPrc := 10 + (SimCurrent - simCurr10Prc) * (100 - 10) / (simCurr100Prc - simCurr10Prc);
			xi := simResonance + 1 - simPrc*0.02;
			omega := 1 + 0.2*simPrc/10.0; 
			alpha := 20;

			IF NOT MTFilterLowPass_Current.Enable THEN
				MTFilterLowPass_Current.CutOffFrequency := 2;
				MTFilterLowPass_Current.Order := 2;
			END_IF
			MTFilterLowPass_Current.Enable := TRUE;
			MTFilterLowPass_Current.In := MAX(0, SkewedGaussianPDF(Frequency, xi, omega, alpha) * (1.2-(100.0-simPrc)/100.0));;
			MTFilterLowPass_Current();
			
			Amplitude := MTFilterLowPass_Current.Out;
		
			// Calculate phase
			phaseRes := 0.999546746760729*xi+0.142274*omega+0.02238;

			IF NOT MTFilterLowPass_Frequency.Enable THEN
				MTFilterLowPass_Frequency.CutOffFrequency := 5;
				MTFilterLowPass_Frequency.Order := 2;
			END_IF
			MTFilterLowPass_Frequency.Enable := TRUE;
			IF MTFilterLowPass_Frequency.Out <= phaseRes THEN
				MTFilterLowPass_Frequency.In := 180 / (1 + EXP(-3 * (Frequency - phaseRes)));
			ELSE
				MTFilterLowPass_Frequency.In := 180 / (1 + EXP(-0.5 * (Frequency - phaseRes)));
			END_IF
			MTFilterLowPass_Frequency();
		
			Phase := MTFilterLowPass_Frequency.Out;
		
	END_CASE
	
END_FUNCTION_BLOCK

FUNCTION SkewedGaussianPDF 
	
	xPDF := (x - xi) / omega;
	tempNormPDF := EXP(-xPDF * xPDF / 2.0) / SQRT(2.0 * 3.14159265358979323846); // NormPDF((x - xi) / omega);
	
	xCDF := alpha * (x - xi) / omega;
	a := 0.147;
	IF x > 0 THEN
		sign := 1;
	ELSIF x < 0 THEN
		sign := -1;
	ELSE
		sign := 0;
	END_IF;
	temp := 1.0 - EXP(-xCDF * xCDF * (4.0 / 3.14159265358979323846 + a * xCDF * xCDF) / (1.0 + a * xCDF * xCDF));
	tempNormCDF := 0.5 * (1.0 + sign * temp); // NormCDF(alpha * (x - xi) / omega);
    
	SkewedGaussianPDF := 2.0 * tempNormPDF * tempNormCDF;
	
END_FUNCTION

FUNCTION_BLOCK TimeDelay
	IF Enable THEN
		Out := lastIn + ((In-lastIn)/Dt)*(Dt-Delay);
		lastIn := In;
	ELSE
		Out := In;
	END_IF
END_FUNCTION_BLOCK

FUNCTION_BLOCK KalmanFilter1D

	IF NOT Enable AND Active THEN
		state := 0;
		Active := FALSE;
	END_IF

	CASE state OF
		0:
			IF Enable THEN
				Active := TRUE;
				ErrorEstimate := 1;
				state := 10;
			END_IF
		
		10:
			// Prediction phase
			Prediction := Estimation;           // For 1D without control input
			ErrorEstimate := ErrorEstimate + ProcessVariance;

			// Update phase
			KalmanGain := ErrorEstimate / (ErrorEstimate + MeasureVariance);
			Estimation := Prediction + KalmanGain * (Measurement - Prediction);
			ErrorEstimate := (1 - KalmanGain) * ErrorEstimate;
	END_CASE
	
END_FUNCTION_BLOCK

FUNCTION RoundToPrecision

	multiplier := pow(10.0, INT_TO_REAL(precision));
	RoundToPrecision := TRUNC(value * multiplier + 0.5) / multiplier;
	
END_FUNCTION

FUNCTION GetPercentFromAmplitude

	GetPercentFromAmplitude := 2.4261*Amplitude-0.0494; //R2=0.9981
	
END_FUNCTION

FUNCTION GetPhaseDelay

	w := 2 * 3.14159 * Frequency;  (* Convert frequency to angular frequency in rad/s *)
	A := wb / (wc * wc);
	B := 1 / (wc * wc);

	real2 := (A * A * w * w * (A * A * w * w - (B * w * w - 1) * (B * w * w - 1))) / ((A * A * w * w + (B * w * w - 1) * (B * w * w - 1)) * (A * A * w * w + (B * w * w - 1) * (B * w * w - 1)));
	imag2 := -(2 * A * A * A * w * w * w * (B * w * w - 1)) / ((A * A * w * w + (B * w * w - 1) * (B * w * w - 1)) * (A * A * w * w + (B * w * w - 1) * (B * w * w - 1)));

	GetPhaseDelay := atan2(imag2, real2) * (180 / 3.14159);
	
END_FUNCTION

FUNCTION HammingWindow

	HammingWindow := 0.54 - 0.46*COS((2*3.141593*n)/(N-1));
	
END_FUNCTION

