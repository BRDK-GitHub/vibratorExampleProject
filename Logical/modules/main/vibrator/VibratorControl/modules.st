
ACTION modules: 
	
	// Function block for accelerometer processing
	this.Accelerometer_0.Enable := this.Accelerometer_0.ModuleOkCalibrationTool OR this.Accelerometer_0.ModuleOkBusCtrl;
	this.Accelerometer_0();
	
	// Function block for calculating airgap phase and amplitude
	this.VibFeedback_0.Enable := gVibratorInterface[i].status.powered;
	this.VibFeedback_0.Axis := SEL(i=0, ADR(gAxisVibL), ADR(gAxisVibC));
	this.VibFeedback_0.Amplitude_out := this.VibControl_0.amplitude_out;
	this.VibFeedback_0.Frequency := this.VibControl_0.frequency_out;
	this.VibFeedback_0.HoldPhase := this.VibControl_0.HoldPhase;
	this.VibFeedback_0.SinePhase := this.VibControl_0.SinePhase;
	this.VibFeedback_0.SineOut := this.VibControl_0.SineOut;
	this.VibFeedback_0.Braking := this.VibControl_0.Braking;
	this.VibFeedback_0.RawVib := this.Accelerometer_0.Raw; // only for phase verification
	this.VibFeedback_0.BrakingToAmplitudePct := this.VibControl_0.BrakingToAmplitudePct;
	this.VibFeedback_0();
	
	// Function block for closed loop phase and amplitude control, as well as setpoint generation for current controller
	this.VibControl_0.Enable := gVibratorInterface[i].status.powered;
	this.VibControl_0.Axis := SEL(i=0, ADR(gAxisVibL), ADR(gAxisVibC));
	this.VibControl_0.Percent := this.Accelerometer_0.Percent;
	this.VibControl_0.SetAmplitude := gVibratorInterface[i].status.percent;
	this.VibControl_0.ActPhase := this.VibFeedback_0.Phase;
	this.VibControl_0.ActPhaseValid := this.VibFeedback_0.PhaseValid;
	this.VibControl_0.ActPhaseAcc := this.VibFeedback_0.PhaseAcc;
	this.VibControl_0.ActAmplitude := SEL(this.testAccFeedback,this.VibFeedback_0.Amplitude,this.Accelerometer_0.Percent); 
	this.VibControl_0.ActAmplitudeValid := this.VibFeedback_0.AmplitudeValid;
	this.VibControl_0.ManualControl := (gVibratorInterface[i].status.forcing) AND NOT gVibratorInterface[i].status.caliProdTest;
//	this.VibControl_0.AccPercent := this.Accelerometer_0.Percent;
	this.VibControl_0();
	hmi.frequencyTimes2 := this.VibControl_0.frequency_out*2.0; // to show on HMI
	
	// Config handling (it takes too much CPU to run in 0.8ms so we run it with a timer):
	this.timeConfig := this.timeConfig + CYCLE_TIME_us;
	IF this.timeConfig > 80000 THEN // 80ms
		this.timeConfig := 0;
		
		// Slow inputs every 80ms
		this.VibControl_0.config := ADR(config);
		this.VibFeedback_0.config := ADR(config);
		this.VibFeedback_0.UpdateFilter := this.VibControl_0.UpdateFilter;
		this.VibFeedback_0.Calibrating := gVibratorInterface[i].status.calibratingMode AND NOT this.VibControl_0.TestPulses;
		this.Accelerometer_0.MachineSize := config.MachineSize;
		this.VibFeedback_0.MachineSize := config.MachineSize;
		this.VibControl_0.MachineSize := config.MachineSize;
		this.VibControl_0.Calibrate := gVibratorInterface[i].status.calibratingMode;
		this.VibControl_0.RampUp := SEL(gVibratorInterface[i].status.rampUp > 0,0,100/(INT_TO_REAL(gVibratorInterface[i].status.rampUp)/1000)); // ms it takes to go from 0% to 100% -> 100ms ex. 100/0.1 = 1000%/s
		this.VibControl_0.ManualPercent := SEL(gVibratorInterface[i].parameter.speedPctManualTest > 0,this.VibControl_0.ManualPercent,gVibratorInterface[i].parameter.speedPctManualTest);
		this.VibControl_0.MinTimeInCount := config.minTimeInCount;
		this.VibControl_0.MinTimeInCountBigCf := config.minTimeInCountBigCf;
		
		// Slow outputs every 80ms
		gVibratorInterface[i].cmd.calibrationDone := this.VibControl_0.CalibrateDone;
		gVibratorInterface[i].cmd.testPulses := this.VibControl_0.TestPulses;
		gVibratorInterface[i].cmd.emptyPercent := config.emptyPercent;
		gVibratorInterface[i].parameter.machineSize := localVariables[0].config.MachineSize;
		this.VibControl_0.UpdateFilterDone := this.VibFeedback_0.UpdateFilterDone;
		localVariables[1].config.MachineSize := localVariables[0].config.MachineSize; 
		hmi.calibrationNotActive := NOT this.VibControl_0.Calibrate;

		
		IF config.calibrationDone THEN
			config.timeInCalibrationSeconds := config.timeInCalibrationSeconds + 0.08; // Previously used PLC TIME but that gets destroyed by NTP. Rather use a counter even though it can't count if power is OFF.
			hmi.daysSinceCalibration := config.timeInCalibrationSeconds/86400; // Convert seconds to days.
			
			// Auto save every 30min
			timeElapsedMillis := timeElapsedMillis + 80;
			IF timeElapsedMillis > 1800000 THEN
				timeElapsedMillis := 0;
				this.SaveConfig := TRUE;
			END_IF
			
			// Only show this when calibration is done. Otherwise it will show 2 different numbers doing calibration which may confuse
			config.ressonanceFrequencyAt45Pct := config.maxFrequencySweep*2.0; // ressonance (mechanical) frequency is really 2 times output frequency.
		ELSE
			hmi.daysSinceCalibration := 99999;
		END_IF
		
		// Set max current depending which machine size.
		IF config.MachineSize=0 THEN
			this.VibControl_0.MaxCurr := SEL(i=0, 0.20, 2.0);
		ELSE
			this.VibControl_0.MaxCurr := SEL(i=0, 0.20, 3.1);
		END_IF
		
		// Set max current depending which machine size.
		IF config.MachineSize=0 THEN
			// Small bowl						  LF    CF
			hmi.minResonanceFrequency := SEL(i=0, 96, 96);
			hmi.maxResonanceFrequency := SEL(i=0, 106, 102);
			hmi.minCurrent := SEL(i=0, 0.04, 0.4);
			hmi.maxCurrent := SEL(i=0, 0.13, 1.3);
		ELSE
			// Big bowl							  LF    CF
			hmi.minResonanceFrequency := SEL(i=0, 96, 47);
			hmi.maxResonanceFrequency := SEL(i=0, 106, 52);
			hmi.minCurrent := SEL(i=0, 0.04, 0.4);
			hmi.maxCurrent := SEL(i=0, 0.13, 1.9);		
		END_IF
		hmi.resonanceFrequencyOK := this.config.ressonanceFrequencyAt45Pct >= hmi.minResonanceFrequency AND this.config.ressonanceFrequencyAt45Pct <= hmi.maxResonanceFrequency;
		hmi.currentOK := this.config.maxCurrentUsed >= hmi.minCurrent AND this.config.maxCurrentUsed <= hmi.maxCurrent;
		
		// Interface calibration results to FAT (send if calibrate is stopped)
		IF this.VibControl_0.SendCaliResultToFAT THEN
			this.VibControl_0.SendCaliResultToFAT := FALSE;
	
			gVibratorInterface[i].status.calibrationResultFrequencyOK := hmi.resonanceFrequencyOK;
			gVibratorInterface[i].status.calibrationResultCurrentOK := hmi.currentOK;
			gVibratorInterface[i].status.calibrationResultFrequency := this.config.ressonanceFrequencyAt45Pct;
			gVibratorInterface[i].status.calibrationResultCurrent := this.config.maxCurrentUsed;
			gVibratorInterface[i].status.calibrationResultsReady := TRUE;
		END_IF
		gVibratorInterface[i].status.calibrationDone := config.calibrationDone;
		
		// set machinesize (cmd from FAT)
		IF gVibratorInterface[i].cmd.setCfType THEN
			gVibratorInterface[i].cmd.setCfType := FALSE;
			config.MachineSize := gVibratorInterface[i].parameter.CFType; //0=small , 1=big
			this.SaveConfig := TRUE;
		END_IF
		
		
		// State Machine to save config.
		CASE this.stateSave OF
			
			0:
				IF this.VibControl_0.SaveConfig AND gConfig.status.loaded THEN
					// Save from calibration
					gConfig.cmd.save := TRUE;
					gMachineInterface.cmd.requestSaveToT50 := TRUE;
					this.stateSave := 10;
				ELSIF this.SaveConfig AND gConfig.status.loaded THEN
					// Save because HMI variable changed.
					this.SaveConfig := FALSE;
					gConfig.cmd.save := TRUE;
					this.stateSave := 30;
				END_IF
			
			10:
				IF NOT gConfig.cmd.save THEN
					this.VibControl_0.SaveConfigDone := TRUE;
					this.stateSave := 20;
				END_IF
			
			20:
				IF NOT this.VibControl_0.SaveConfig THEN
					this.VibControl_0.SaveConfigDone := FALSE;
					this.stateSave := 0;
				END_IF
			
			30:
				IF NOT gConfig.cmd.save THEN
					this.stateSave := 0;
				END_IF
			
		END_CASE
		
		
	this.MpRecipeRegPar_Config(MpLink := ADR(mpRecipe), PVName := ADR(this.configName), Category := ADR('config'));
END_IF
		
		
	

END_ACTION
