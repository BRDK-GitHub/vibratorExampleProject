FUNCTION_BLOCK vibratorControl

	CASE state OF
		
		0:
			IF enable THEN
				IF vibratorType=0 THEN
					state := 5;
				ELSE
					//LF
					state := 8;
				END_IF
			END_IF
		
		5: // CF Running
			IF manualControl THEN
				state := 200;
			ELSIF percent < estimatedPercent AND frequency <> 0.0 THEN
				time := 0;
				brakePercent := percent;
				state := 20;
			ELSIF percent > estimatedPercent AND frequency <> 0.0 THEN
				time := 0;
				oldPercent := percent;
				state := 10;
			ELSE
				amplitude_out := amplitude;
				MTLookUpTable_0.InX := amplitude;
				MTLookUpTable_0();
				frequency := MTLookUpTable_0.Out;
			END_IF
			
		8: // LF Running
			IF manualControl THEN
				state := 200;
			ELSE
				amplitude_out := amplitude;
				MTLookUpTable_0.InX := amplitude;
				MTLookUpTable_0();
				frequency := MTLookUpTable_0.Out;
			END_IF
			
			
		10: // wait for zero crossing			
			IF sin_ref >= 0.0 AND old_sin < 0.0 THEN
				amplitude_out := boostAmplitude;
				estimatedPercent := MAX(estimatedPercent, startPercentBoost);
		
				MTDataMinMax_0.Enable := FALSE;
				MTDataMinMax_0();
				state := 15;
			ELSIF sin_ref <= 0.0 AND old_sin > 0.0 THEN
				amplitude_out := boostAmplitude;
				estimatedPercent := MAX(estimatedPercent, startPercentBoost);
				
				MTDataMinMax_0.Enable := FALSE;
				MTDataMinMax_0();
				state := 15;
			END_IF
			
		15: // Boosting
			amplitude_out := boostAmplitude; 
			frequency := boostFrequency;

			IF estimatedPercent <= boostHighLowSeperatorPercent THEN
				estimatedPercent := applyBoost(estimatedPercent, boostVelocityLow, vibratorType, machineType);
			ELSE
				estimatedPercent := applyBoost(estimatedPercent, boostVelocityHigh, vibratorType, machineType);
			END_IF
			time := time + CYCLE_TIME_s;
			
			IF percent <> oldPercent THEN
				state := 5;
			ELSIF estimatedPercent >= percent OR disableBoost THEN
				estimatedPercent := percent;
				state := 5;
			END_IF
		
		20: 
			IF sin_ref >= 0.0 AND old_sin < 0.0 THEN
				amplitude_out := brakeAmplitude;
				phi := phi - (PI/2.0);
				
				MTDataMinMax_0.Enable := FALSE;
				MTDataMinMax_0();
				state := 25;
			ELSIF sin_ref <= 0.0 AND old_sin > 0.0 THEN
				amplitude_out := brakeAmplitude;
				phi := phi - (PI/2.0);
				
				MTDataMinMax_0.Enable := FALSE;
				MTDataMinMax_0();
				state := 25;
			END_IF
			
		25: // Braking
			amplitude_out := brakeAmplitude;
			frequency := brakeFrequency;

			estimatedPercent := applyBrake(estimatedPercent, brakeVelocity, vibratorType, machineType);
			
			time := time + CYCLE_TIME_s;
			
			IF estimatedPercent <= brakePercent THEN
				estimatedPercent := brakePercent;
				
				amplitude_out := 0.0;
				phi := phi + (PI/2.0);
				state := 5;
			END_IF	
		
		100:
			amplitude_out := amplitude;
			MTLookUpTable_0.InX := amplitude;
			MTLookUpTable_0();
			frequency := MTLookUpTable_0.Out;
		
		200:
			frequency := manualFrequency;
			amplitude_out := amplitude;
		
			IF manualBrake THEN
				state := 210;
				time := 0;
			ELSIF manualBoost THEN
				time := 0.0;
				state := 250;
			ELSIF NOT manualControl THEN
				estimatedPercent := 0;
				MTLookUpTable_0.Enable := FALSE;
				MTLookUpTable_0();
				state := 5;
			END_IF
		
		210: 
			IF sin_ref >= 0.0 AND old_sin < 0.0 THEN
				amplitude_out := brakeAmplitude;
				phi := phi - (PI/2.0);
				accelerationStart := currAccelerometerValue;
				minAcceleration := 99999999;
				state := 220;
			ELSIF sin_ref <= 0.0 AND old_sin > 0.0 THEN
				amplitude_out := brakeAmplitude;
				phi := phi - (PI/2.0);
				accelerationStart := currAccelerometerValue;
				timeStart := 0;
				minAcceleration := 99999999;
				state := 220;
			END_IF
			
		220: // Braking
			amplitude_out := brakeAmplitude;
			frequency := brakeFrequency;
			
			time := time + CYCLE_TIME_s;
			
			IF time > manualBrakeTime OR NOT manualBrake THEN
				amplitude_out := manualBrakeAmplitudeEnd;
				frequency := manualBrakeFrequencyEnd;
				phi := phi + (PI/2.0);
				state := 230;
			END_IF
			
			IF currAccelerometerValue < minAcceleration THEN
				IF timeStart > 0 AND time-timeStart >= CYCLE_TIME_s*2 THEN
					accelerationStart := accelerationStart20pct;
					minAcceleration := currAccelerometerValue;
					minAccelerationTime := time-timeStart;
				ELSE
					minAcceleration := currAccelerometerValue;
					minAccelerationTime := time;
				END_IF
			END_IF	
			
			// If acceleromter falls more than 20% save that point as "start point".
			IF currAccelerometerValue < (accelerationStart*0.8) AND timeStart=0 THEN
				accelerationStart20pct := currAccelerometerValue;
				timeStart := time;
			END_IF
		
		230:
			IF currAccelerometerValue < minAcceleration THEN
				IF timeStart > 0 AND time-timeStart >= CYCLE_TIME_s*2 THEN
					accelerationStart := accelerationStart20pct;
					minAcceleration := currAccelerometerValue;
					minAccelerationTime := time-timeStart;
				ELSE
					minAcceleration := currAccelerometerValue;
					minAccelerationTime := time;
				END_IF
			END_IF	
			
			// If acceleromter falls more than 20% save that point as "start point".
			IF currAccelerometerValue < (accelerationStart*0.8) AND timeStart=0 THEN
				accelerationStart20pct := currAccelerometerValue;
				timeStart := time;
			END_IF
			
			IF NOT manualBrake THEN
				amplitude_out := 0;
				state := 200;
			END_IF
		
		250: // wait for zero crossing			
			IF sin_ref >= 0.0 AND old_sin < 0.0 THEN
				amplitude_out := boostAmplitude;
				state := 260;
			ELSIF sin_ref <= 0.0 AND old_sin > 0.0 THEN
				amplitude_out := boostAmplitude;
				state := 260;
			END_IF
			
		260: // Boosting
			amplitude_out := boostAmplitude; 
			frequency := boostFrequency;
			
			time := time + CYCLE_TIME_s;
			caliBoostVelocityLow := currAccelerometerValue / time;
			
			IF time >= 0.5 OR NOT manualBoost OR currAccelerometerPercent >= 50.0 THEN
				time := 0;
				accelerationStart := currAccelerometerValue;
				state := 270;
			END_IF
		
		270:
			amplitude_out := boostAmplitude; 
			frequency := boostFrequency;
			
			time := time + CYCLE_TIME_s;
			caliBoostVelocityHigh := (currAccelerometerValue-accelerationStart) / time;
			
			IF time >= 0.5 THEN
				caliBoostVelocityHigh := caliBoostVelocityLow;

				amplitude_out := 0.0;
				state := 280;
			ELSIF NOT manualBoost OR currAccelerometerPercent >= 90.0 THEN
				amplitude_out := 0.0;
				state := 280;
			END_IF
			
		280:
			IF NOT manualBoost THEN
				state := 200;
			END_IF
		
	END_CASE

	IF NOT enable AND state <> 0 THEN
		estimatedPercent := 0;
		state := 0;
		amplitude_out := 0;
		frequency_out := 0;
	END_IF
		
	// Lookup table for frequencies
	IF enable AND NOT MTLookUpTable_0.Enable THEN
		MTLookUpTable_0.Mode := mtLOOKUP_LINEAR_EXTRAPOLATION;
		
		MTLookUpTable_0.NumberOfNodes := 0;
		FOR j:=0 TO 4 DO
			IF linearizationAmplitude[j]=0.0 THEN
				EXIT;
			END_IF
			MTLookUpTable_0.NodeVectorX[j] := linearizationAmplitude[j];
			MTLookUpTable_0.FcnValues[j] := linearizationFrequencies[j];
			MTLookUpTable_0.NumberOfNodes := MTLookUpTable_0.NumberOfNodes + 1;
		END_FOR
	END_IF
	MTLookUpTable_0.Enable := enable;
	MTLookUpTable_0();
	
	IF activateMinMax OR manualControl THEN
		IF currAccelerometerValue <> oldCurrAccelerometerValue THEN
			oldCurrAccelerometerValue := currAccelerometerValue;
			
			MTFilterMovingAverage_0.Enable := TRUE;
			MTFilterMovingAverage_0.In := currAccelerometerValue;
			MTFilterMovingAverage_0.WindowLength := 10;
			MTFilterMovingAverage_0();
			
			MTDataMinMax_0.Enable := TRUE;
			MTDataMinMax_0.In := MTFilterMovingAverage_0.Out;
			MTDataMinMax_0();
			minBreakPercent := getPercentFromAcceleration(MTDataMinMax_0.MinValue ,vibratorType,machineType);
			maxBoostPercent := getPercentFromAcceleration(MTDataMinMax_0.MaxValue ,vibratorType,machineType);
			filteredAccelerometerPercent := getPercentFromAcceleration(MTFilterMovingAverage_0.Out,vibratorType,machineType);
		END_IF
	END_IF
	
	old_sin := sin_ref;
	
	// create sinewave amplitude with defined frequency
	sin_out := amplitude_out*SIN(phi+phaseShift);
	sin_abs := ABS(sin_out);
	phi := fmod(phi + frequency*2*PI*CYCLE_TIME_s, 2*PI);
	sin_ref := SIN(phi+phaseShift);
	phaseShift := fmod(phaseShift, 2*PI);
	phaseShiftLocal := fmod(phaseShiftLocal, 2*PI);
	
	// Write sine wave to vibrator parID
	MC_BR_CyclicWrite_0.Enable := enable;
	MC_BR_CyclicWrite_0.Axis := pAxis;
	MC_BR_CyclicWrite_0.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicWrite_0.DataAddress := ADR(sin_out);
	MC_BR_CyclicWrite_0.ParID := ACP10PAR_USER_R4_VAR1;
	MC_BR_CyclicWrite_0();
	
	// If machineType changes we must change parameters.
	IF machineType <> oldMachineType OR vibratorType <> oldVibratorType THEN
		oldMachineType := machineType;
		oldVibratorType := vibratorType;
		
		IF machineType=0 THEN
			IF vibratorType=0 THEN
				// small CF
			//	startPercentBoost := 5.0;
				brakeAmplitude := 1.5;
				boostAmplitude := 1.5;
				boostVelocityLow := 60500;
			ELSE
				// small LF
			//	startPercentBoost := 10.0;
				brakeAmplitude := 0.06;
				boostAmplitude := 0.12;
				boostVelocityLow := 29195;
			END_IF
		ELSE
			IF vibratorType=0 THEN
				// big CF
			//	startPercentBoost := 5.0;
				brakeAmplitude := 2.5;
				boostAmplitude := 2.5;
				boostVelocityLow := 29195;
			ELSE
				// big LF
			//	startPercentBoost := 10.0;
				brakeAmplitude := 0.06;
				boostAmplitude := 0.12;
				boostVelocityLow := 29195;
			END_IF
		END_IF
		
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION getPercentFromAcceleration
	
	IF machineType=0 THEN
		IF vibratorType=0 THEN
			// 10%=2756 , 100%=17420
			getPercentFromAcceleration := (acc-1126.7)/162.93;
		ELSE
			// 10%=1300 , 100%=10140
			getPercentFromAcceleration := (acc-317.78)/98.222;
		END_IF
	ELSE
		IF vibratorType=0 THEN
			// 10%=1456 , 100%=8060
			getPercentFromAcceleration := (acc-722.22)/73.378;;
		ELSE
			// 10%=1508 , 100%=8840
			getPercentFromAcceleration := (acc-693.33)/81.467;
		END_IF
	END_IF
	
END_FUNCTION

FUNCTION getAccelerationFromPercent
	
	IF machineType=0 THEN
		IF vibratorType=0 THEN
			// 10%=2756 , 100%=17420
			getAccelerationFromPercent := percent*162.93+1126.7;
		ELSE
			// 10%=1300 , 100%=10140
			getAccelerationFromPercent := percent*98.222+317.78;
		END_IF
	ELSE
		IF vibratorType=0 THEN
			// 10%=1456 , 100%=8060
			getAccelerationFromPercent := percent*73.378+722.22;
		ELSE
			// 10%=1508 , 100%=8840
			getAccelerationFromPercent := percent*81.467+693.33;
		END_IF
	END_IF
	
END_FUNCTION

FUNCTION applyBoost
	acc := getAccelerationFromPercent(percent,vibratorType,machineType);
	applyBoost := getPercentFromAcceleration(acc+(boostVelocity*CYCLE_TIME_s),vibratorType,machineType);
	
//	IF machineType=0 THEN
//		IF vibratorType=0 THEN
//			applyBoost := getPercentFromAcceleration(acc+(55910*CYCLE_TIME_s),vibratorType,machineType);
//		ELSE
//			applyBoost := getPercentFromAcceleration(acc+(29195*CYCLE_TIME_s),vibratorType,machineType);
//		END_IF
//	ELSE
//		IF vibratorType=0 THEN
//			// big CF
//			applyBoost := getPercentFromAcceleration(acc+(29195*CYCLE_TIME_s),vibratorType,machineType);
//		ELSE
//			applyBoost := getPercentFromAcceleration(acc+(29195*CYCLE_TIME_s),vibratorType,machineType);
//		END_IF
//	END_IF
	
END_FUNCTION

FUNCTION applyBrake
	acc := getAccelerationFromPercent(percent,vibratorType,machineType);
	applyBrake := getPercentFromAcceleration(acc-(brakeVelocity*CYCLE_TIME_s),vibratorType,machineType);
	
	//	IF vibratorSize=0 THEN
	//		IF vibratorType=0 THEN
	//			applyBrake := getPercentFromAcceleration(acc-(48000*CYCLE_TIME_s),vibratorType,vibratorSize); //applyBrake := getPercentFromAcceleration(acc-(94349*CYCLE_TIME_s),vibratorType,vibratorSize);
	//		ELSE
	//			applyBrake := getPercentFromAcceleration(acc-(48000*CYCLE_TIME_s),vibratorType,vibratorSize);
	//		END_IF
	//	ELSE
	//		IF vibratorType=0 THEN
	//			// big CF
	//			applyBrake := getPercentFromAcceleration(acc-(42000*CYCLE_TIME_s),vibratorType,vibratorSize);
	//		ELSE
	//			applyBrake := getPercentFromAcceleration(acc-(48000*CYCLE_TIME_s),vibratorType,vibratorSize);
	//		END_IF
	//	END_IF
		
END_FUNCTION

FUNCTION_BLOCK GetPhaseDifference
	
	CASE state OF
		0:
			IF Enable THEN
				idx := 0;
				state := 10;
			END_IF
		
		10:
			x[idx] := ReferenceSignal;
			y[idx] := Signal;
			
			idx := idx + 1;
			
			IF idx > MAX_SIGNAL_LENGTH THEN
				idx := 0;
				state := 20;
			END_IF
		
		20:
			maxVal := 0;
			maxIdx := 0;
			minVal := 999999999;
			minIdx := 0;
	
			FOR i:=0 TO MAX_OUTPUT_LENGTH DO
				sum := 0;
				offset := UINT_TO_INT(i)-UINT_TO_INT(MAX_SIGNAL_LENGTH);
				FOR j:=0 TO MAX_SIGNAL_LENGTH DO
					IF UINT_TO_INT(j)+offset >= 0 AND UINT_TO_INT(j)+offset <= MAX_SIGNAL_LENGTH THEN
						sum := sum + (x[j] * y[j+offset]);
					END_IF
				END_FOR
				IF sum >= maxVal THEN
					maxVal := sum;
					maxIdx := i;
				END_IF
				IF sum <= minVal THEN
					minVal := sum;
					minIdx := i;
				END_IF
						
				r[i] := sum;
			END_FOR
			
			Phase := UINT_TO_REAL(maxIdx)-UINT_TO_REAL(MAX_SIGNAL_LENGTH);
			PhaseInv := UINT_TO_REAL(minIdx)-UINT_TO_REAL(MAX_SIGNAL_LENGTH);
			
			state := 10;

	END_CASE
	
	IF NOT Enable AND state > 0 THEN
		state := 0;
	END_IF
	
END_FUNCTION_BLOCK
