
PROGRAM _INIT
	
	
	cm.setup.name := 'sampling';

END_PROGRAM

PROGRAM _CYCLIC

	interface ACCESS ADR(gCapconInterface);

	IF gMainInterface.status.simulation OR gSimulation.status.simulateAllButWing THEN
		executeSim;
	END_IF
	
	IF interface.status.reset THEN
		interface.status.reset := FALSE;
		this.sim.state := 0;
	END_IF
	
	// ************************************************ //
	// *************** Wing Sampling ****************** //
	// ************************************************ //
	IF NOT this.hw.di_upperFlap_change THEN
		this.WingHwTOFs[0].OUT := FALSE;
	END_IF
	
	IF NOT this.hw.di_middleFlap_change THEN
		this.WingHwTOFs[1].OUT := FALSE;
	END_IF
	
	IF NOT this.hw.di_bottomFlap_change THEN
		this.WingHwTOFs[2].OUT := FALSE;
	END_IF
	
	IF NOT this.hw.di_neigbourFlap_change THEN
		this.WingHwTOFs[3].OUT := FALSE;
	END_IF
		
	FOR i:=0 TO 3 BY 1 DO
		IF NOT this.WingHwTOFs[i].OUT THEN
			this.WingHwTOFs[i].ET := this.WingHwTOFs[i].ET +1600; // 0.8 ms
		END_IF
		IF (this.WingHwTOFs[i].ET >= this.WingHwTOFs[i].PT) THEN
			CASE i OF
				
				0:
					IF this.hw.di_upperFlap_change THEN // only reset if changeOver signal is 1 again.
						this.WingHwTOFs[i].OUT := TRUE; 
						this.WingHwTOFs[i].ET := 0;
					END_IF
					
				1:
					IF this.hw.di_middleFlap_change THEN // only reset if changeOver signal is 1 again.
						this.WingHwTOFs[i].OUT := TRUE;
						this.WingHwTOFs[i].ET := 0;
					END_IF
						
				2:
					IF this.hw.di_bottomFlap_change THEN // only reset if changeOver signal is 1 again.
						this.WingHwTOFs[i].OUT := TRUE;
						this.WingHwTOFs[i].ET := 0;
					END_IF
					
				3:
					IF this.hw.di_neigbourFlap_change THEN // only reset if changeOver signal is 1 again.
						this.WingHwTOFs[i].OUT := TRUE;
						this.WingHwTOFs[i].ET := 0;
					END_IF
				
			END_CASE	
		END_IF		
	END_FOR
	
	// ************************************************ //
	// ************** CAPCON ALGORITHM **************** //
	// ************************************************ //
	this.hw.ai_signal[0] := (this.hw.ai_signal[1]+this.lastAiSignal)/2;
	this.lastAiSignal := this.hw.ai_signal[1];
	FOR k:=0 TO 1 DO
		this.MTBasicsTimeDelay_capcon.Enable 	 := TRUE;
		this.MTBasicsTimeDelay_capcon.DelayTime  := 0.032;
		this.MTBasicsTimeDelay_capcon.In 		 := this.hw.ai_signal[k];
		this.MTBasicsTimeDelay_capcon();
		
		this.MTFilterMovingAverage_capcon.Enable		:= TRUE;
		this.MTFilterMovingAverage_capcon.WindowLength  := 40;
		this.MTFilterMovingAverage_capcon.In 			:= this.hw.ai_signal[k];
		this.MTFilterMovingAverage_capcon();
		
		this.BrickDetector_0.enable 	:= TRUE;
		this.BrickDetector_0.signal 	:= this.MTFilterMovingAverage_capcon.Out;
		this.BrickDetector_0.threshold 	:= gCapconInterface.status.capconMinThreshold;		 //15;
		this.BrickDetector_0.factorRmsMax := gCapconInterface.status.factorRmsMax;
		this.BrickDetector_0();
		
		this.CapconNoiseMeassure_0.beltSpeed := gBeltInterface.status.speed;
		this.CapconNoiseMeassure_0.rms := this.BrickDetector_0.rms;
		this.CapconNoiseMeassure_0();
		
		CASE cm.substate OF 
			0:
				cm.description := 'wait for brick';
				
				this.BrickIntegral_0.enable := FALSE;
				this.BrickIntegral_0.calculate := FALSE;
				this.BrickIntegral_0();
				
				IF this.BrickDetector_0.brickCandidate AND NOT gMainInterface.status.emptying THEN
					this.BrickIntegral_0.baselineStart := this.BrickDetector_0.signal;
					cm.substate := 10;
				END_IF
			10:
				cm.description := 'measure brick';
	
				this.BrickIntegral_0.enable := TRUE;
				this.BrickIntegral_0.calculate := FALSE;
				this.BrickIntegral_0.signal := this.MTBasicsTimeDelay_capcon.Out;
				this.BrickIntegral_0();
				
				IF NOT this.BrickDetector_0.brickCandidate THEN
					cm.substate := 0;
				ELSIF this.BrickDetector_0.brickPresent THEN
					cm.substate := 20;
				END_IF
			
			20:
				cm.description := 'measure brick and wait for brick not present';
	
				this.BrickIntegral_0.enable := TRUE;
				this.BrickIntegral_0.calculate := FALSE;
				this.BrickIntegral_0.signal := this.MTBasicsTimeDelay_capcon.Out;
				this.BrickIntegral_0();
				
				IF this.BrickDetector_0.brickNotPresent THEN
					this.BrickIntegral_0.baselineEnd := this.BrickDetector_0.signal;
					this.BrickDetector_0.rmsMaxThreshold := this.BrickDetector_0.currentRmsMax;
					cm.substate := 30;
				END_IF
				
			30:
				cm.description := 'calculate integral';
	
				this.BrickIntegral_0.calculate := TRUE;
				this.BrickIntegral_0();
				
				IF this.BrickIntegral_0.done THEN
					this.BrickIntegral_0.calculate := FALSE;
					this.integralSum := this.integralSum + this.BrickIntegral_0.integral;
					
					cm.substate := 40;
				END_IF
				
			40:
				cm.description := 'Add peak integrals to array';	
				
				IF this.BrickIntegral_0.noPeaks > 0 THEN
					FOR i:=0 TO this.BrickIntegral_0.noPeaks - 1 DO
						IF this.noPeaks <= MAX_PEAKS THEN
							this.peakIntegral[this.noPeaks] := this.BrickIntegral_0.integrals[i];
							this.noPeaks := this.noPeaks + 1;
						END_IF;
					END_FOR
				END_IF
				
				interface.status.noPeaks 	   := this.noPeaks;
				interface.status.peakIntegral  := this.peakIntegral;
				
				cm.substate := 50;
				
			50:
				cm.description := 'Verify peak integrals';
	
				this.VerifyPeaks_0.teachIntegral 	:= interface.status.teachIntegral;
				this.VerifyPeaks_0.controlPercent 	:= interface.parameter.controlPercent;
				this.VerifyPeaks_0.peakIntegral 	:= ADR(this.peakIntegral);
				this.VerifyPeaks_0.noPeaks			:= this.noPeaks;
				this.VerifyPeaks_0();
				
				interface.status.noVerifiedPeaks 	:= this.VerifyPeaks_0.noVerifiedPeaks;
				interface.status.verifiedPeakCount 	:= this.VerifyPeaks_0.peakCount;
				
				cm.substate := 60;
			
			60:
				cm.description := 'Verify adaptive peak integrals';
	
				this.VerifyPeaks_1.teachIntegral 	:= interface.status.adaptiveTeachIntegral;
				this.VerifyPeaks_1.controlPercent 	:= interface.parameter.controlPercent;
				this.VerifyPeaks_1.peakIntegral 	:= ADR(this.peakIntegral);
				this.VerifyPeaks_1.noPeaks			:= this.noPeaks;
				this.VerifyPeaks_1();
				
				interface.status.noAdaptiveVerifiedPeaks := this.VerifyPeaks_1.noVerifiedPeaks;
	
				cm.substate := 0;
	
		END_CASE
	END_FOR
	
	IF EDGEPOS(interface.status.ready) THEN
		this.integralSum := 0;
		this.brickError := FALSE;
		this.noPeaks := 0;
		this.noVerifiedPeaks := 0;
		interface.status.noPeaks := 0;
		interface.status.noVerifiedPeaks := 0;
		interface.status.noAdaptiveVerifiedPeaks := 0;
		FOR i:=0 TO MAX_PEAKS DO
			this.peakIntegral[i] := 0;
		END_FOR
	END_IF
	
	interface.status.integralSum := this.integralSum;
	interface.status.brickDetected := cm.substate >= 10;
	interface.status.brickPresent := cm.substate >= 20;

	// Test from FAT
	IF gCapconInterface.cmd.startSpeedSignalTest THEN
		IF NOT this.TON_0.IN THEN
			this.maxSignal := -30000;
			this.minSignal := 30000;
		END_IF
		
		// Save highest speed doing 5sec
		this.TON_0.PT := T#5s;
		this.TON_0.IN := TRUE;
		this.TON_0();
		this.maxSignal := SEL(this.hw.ai_signal[0]>this.maxSignal,this.maxSignal,this.hw.ai_signal[0]);
		this.minSignal := SEL(this.hw.ai_signal[0]<this.minSignal,this.minSignal,this.hw.ai_signal[0]);
				
		IF this.TON_0.Q THEN
			this.TON_0(IN:=FALSE);
			gCapconInterface.status.maxRawSignal := this.maxSignal-this.minSignal; // max signal peak-to-peak 
			IF gCapconInterface.status.maxRawSignal > 5000 THEN
				gCapconInterface.status.maxRawSignal := 0;
			END_IF
			gCapconInterface.cmd.startSpeedSignalTest := FALSE;
		END_IF
	END_IF
	
END_PROGRAM

PROGRAM _EXIT

END_PROGRAM

