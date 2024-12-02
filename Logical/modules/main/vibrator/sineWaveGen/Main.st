
PROGRAM _INIT
	
	acc.enable 	:= 	TRUE;
	acc.samples	:= 103;		// number of samples at 2kHz sample rate ~ 20 = 10ms
	 
	FOR i:=1 TO NUM_VIBRATOR DO
		vibratorControl_0[i].vibratorType := i;	// i=0=CF , i=1=LF
		vibratorControl_0[i].pAxis := SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
	END_FOR
	
END_PROGRAM

PROGRAM _CYCLIC

	FOR i:=1 TO NUM_VIBRATOR DO
		
		IF local[i].readPercentFromAccelerometer OR gVibratorInterface[i].status.calibratingMode OR gVibratorInterface[i].status.forcing THEN
			local[i].percentFromAccelerometer := getPercentFromAcceleration(acc.analogVib,i,gVibratorInterface[0].status.machineType);
			gVibratorInterface[i].status.currAccelerometerPercent := local[i].percentFromAccelerometer;
			gVibratorInterface[i].status.currEstimatedPercent := vibratorControl_0[i].estimatedPercent;
			hmiAccelerometerPercent := local[i].percentFromAccelerometer;
			gVibratorInterface[i].status.currAccelerometerValue := acc.analogVib;
		END_IF
		
		vibratorControl_0[i].enable 		:= gVibratorInterface[i].status.powered;
		vibratorControl_0[i].amplitude		:= gVibratorInterface[i].status.vibAmplitude;
		vibratorControl_0[i].percent		:= gVibratorInterface[i].status.percent;
		vibratorControl_0[i].machineType	:= gVibratorInterface[i].status.machineType;
		vibratorControl_0[i].manualControl	:= (gVibratorInterface[i].status.calibratingMode OR gVibratorInterface[i].status.forcing) AND NOT gVibratorInterface[i].status.caliProdTest;
		vibratorControl_0[i].activateMinMax := gVibratorInterface[i].status.caliProdTest;
		vibratorControl_0[i].manualFrequency := gVibratorInterface[i].status.vibFrequency;
		vibratorControl_0[i].manualBrake	:= gVibratorInterface[i].status.calibrateBrake;
		vibratorControl_0[i].manualBoost	:= gVibratorInterface[i].status.calibrateBoost;
		vibratorControl_0[i].brakeFrequency := gVibratorInterface[i].status.brakeFrequency;
		vibratorControl_0[i].boostFrequency := gVibratorInterface[i].status.boostFrequency;
		vibratorControl_0[i].boostVelocityLow := SEL(gVibratorInterface[i].status.boostVelocityLow = 0, gVibratorInterface[i].status.boostVelocityLow, 40000);
		vibratorControl_0[i].boostVelocityHigh := SEL(gVibratorInterface[i].status.boostVelocityHigh = 0, gVibratorInterface[i].status.boostVelocityHigh, 40000);
		vibratorControl_0[i].brakeVelocity := SEL(gVibratorInterface[i].status.brakeVelocity = 0, gVibratorInterface[i].status.brakeVelocity, 40000);
		vibratorControl_0[i].boostAmplitude := gVibratorInterface[i].status.boostAmpltiude;
		vibratorControl_0[i].brakeAmplitude := gVibratorInterface[i].status.brakeAmplitude;
		vibratorControl_0[i].linearizationAmplitude := gVibratorInterface[i].status.linearizationAmplitude;
		vibratorControl_0[i].linearizationFrequencies := gVibratorInterface[i].status.linearizationFrequencies;
		vibratorControl_0[i].manualBrakeTime := LIMIT(0, gVibratorInterface[i].status.calibrateBraketime, 1);
		vibratorControl_0[i].manualBrakeAmplitudeEnd := gVibratorInterface[i].status.calibrateBrakeAmplitudeEnd;
		vibratorControl_0[i].manualBrakeFrequencyEnd := gVibratorInterface[i].status.calibrateBrakeFrequencyEnd;
		vibratorControl_0[i].currAccelerometerValue := acc.analogVib;
		vibratorControl_0[i].currAccelerometerPercent := local[i].percentFromAccelerometer;
		vibratorControl_0[i].disableBoost := gVibratorInterface[i].status.disableLFBoost;
		vibratorControl_0[i]();
		
		// Output mapping:
		gVibratorInterface[i].status.minAccelerationStart := vibratorControl_0[i].accelerationStart;
		gVibratorInterface[i].status.minAcceleration := vibratorControl_0[i].minAcceleration;
		gVibratorInterface[i].status.minAccelerationTime := vibratorControl_0[i].minAccelerationTime;
		gVibratorInterface[i].status.caliBoostVelocityLow := vibratorControl_0[i].caliBoostVelocityLow;
		gVibratorInterface[i].status.caliBoostVelocityHigh := vibratorControl_0[i].caliBoostVelocityHigh;
		gVibratorInterface[i].status.maxBoostPercent := vibratorControl_0[i].maxBoostPercent;
		gVibratorInterface[i].status.minBreakPercent := vibratorControl_0[i].minBreakPercent;
		gVibratorInterface[i].status.filteredAccelerometerPercent := vibratorControl_0[i].filteredAccelerometerPercent;
		
		// GetPhaseDifference_0.Enable := TRUE;
		GetPhaseDifference_0[i].ReferenceSignal := ABS(vibratorControl_0[i].sin_out);
		GetPhaseDifference_0[i].Signal := acc.rawVib;
		GetPhaseDifference_0[i]();

		
		///////////////////////////////////////////////////
		//// MANUEL CONTROL FOR FORCING AND CALIBRATION////
		///////////////////////////////////////////////////
		IF gVibratorInterface[i].cmd.readCurrentAndVoltage THEN
			local[i].MC_BR_CyclicRead_0.Enable := TRUE;
			local[i].MC_BR_CyclicRead_0.Axis := SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
			local[i].MC_BR_CyclicRead_0.ParID := 214;
			local[i].MC_BR_CyclicRead_0.DataType := ncPAR_TYP_REAL;
			local[i].MC_BR_CyclicRead_0.DataAddress := ADR(local[i].actCurrent);
			local[i].MC_BR_CyclicRead_0();
			
			local[i].MC_BR_CyclicRead_1.Enable := TRUE;
			local[i].MC_BR_CyclicRead_1.Axis := SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
			local[i].MC_BR_CyclicRead_1.ParID := 216;
			local[i].MC_BR_CyclicRead_1.DataType := ncPAR_TYP_REAL;
			local[i].MC_BR_CyclicRead_1.DataAddress := ADR(local[i].actVoltage);
			local[i].MC_BR_CyclicRead_1();
			
			local[i].time := local[i].time + CYCLE_TIME_us;
			local[i].maxPeakCurrent := MAX(ABS(local[i].actCurrent),local[i].maxPeakCurrent);
			IF local[i].time >= 100000 THEN
				// Every 0.25s send max current to vibrator task
				local[i].time := 0;
				gVibratorInterface[i].status.actCurr := local[i].maxPeakCurrent;
				local[i].maxPeakCurrent := 0;
			END_IF
		ELSE
			gVibratorInterface[i].status.actCurr := 0;
			local[i].MC_BR_CyclicRead_0(Enable:=FALSE);	
			local[i].MC_BR_CyclicRead_1(Enable:=FALSE);	
		END_IF
		
		// Max peaks
		IF gVibratorInterface[i].cmd.monitorActPeakValue THEN
			MTFilterMovingAverage_0[i].Enable := TRUE;
			MTFilterMovingAverage_0[i].In := acc.analogVib;
			MTFilterMovingAverage_0[i].WindowLength := 250;	// 400ms moving average
			MTFilterMovingAverage_0[i]();
			
			MTBasicsTimeDelay_0[i].Enable := TRUE;
			MTBasicsTimeDelay_0[i].DelayTime := 0.2;
			MTBasicsTimeDelay_0[i].In := gVibratorInterface[i].status.vibFrequency;;
			MTBasicsTimeDelay_0[i]();
		
			gVibratorInterface[i].status.maxPeakValue := MTFilterMovingAverage_0[i].Out;
			
		ELSIF MTFilterMovingAverage_0[i].Enable THEN
			gVibratorInterface[i].status.highestFrequency := 0;
			gVibratorInterface[i].status.highestAmplitude := 0;
			MTFilterMovingAverage_0[i].Enable := FALSE;
			MTFilterMovingAverage_0[i]();
			MTBasicsTimeDelay_0[i].Enable := FALSE;
			MTBasicsTimeDelay_0[i]();
		END_IF
		
		IF gVibratorInterface[i].cmd.monitorMaxPeakValue THEN
			
			IF gVibratorInterface[i].status.maxPeakValue > gVibratorInterface[i].status.highestAmplitude AND MTBasicsTimeDelay_0[i].Out > 0 THEN
				gVibratorInterface[i].status.highestAmplitude := gVibratorInterface[i].status.maxPeakValue;
				gVibratorInterface[i].status.highestFrequency := MTBasicsTimeDelay_0[i].Out;
			END_IF
		ELSE
			gVibratorInterface[i].status.highestAmplitude := 0;
			gVibratorInterface[i].status.highestFrequency := 0;
		END_IF
	END_FOR
	
	
	IF gVibratorInterface[0].status.isBigCF THEN
		// Big CF must use double samples because the frequency is half
		acc.samples	:= 103;		// number of samples at 2kHz sample rate ~ 1 period on accelerometer
	ELSE
		// big CF
		acc.samples	:= 53;		// number of samples at 2kHz sample rate ~ 1 period on accelerometer
	END_IF
	 
END_PROGRAM

PROGRAM _EXIT

	FOR i:=1 TO NUM_VIBRATOR DO
		MTBasicsTimeDelay_0[i](Enable := FALSE);
		MTFilterMovingAverage_0[i](Enable := FALSE);
	END_FOR
	 
END_PROGRAM

