FUNCTION_BLOCK CFController
	
	CASE state OF
		0:
			Active := FALSE;
			IF Enable THEN
				Active := TRUE;
				PIControllerICM_0.FeedForward := StaticOut;
				PIControllerICM_0.Output := StaticOut;
				PIControllerICM_0.Integral := 0;
				PIControllerICM_0.Enable := TRUE;
				state := 10;
			ELSE
				Out := StaticOut;
			END_IF
		
		10:	
			
			// Minimum offset from LF 
			IF (PIControllerICM_0.Output+LFOffset) >= LFOut THEN
				Out := LFOut-LFOffset;
				PIControllerICM_0.Hold := TRUE;
			ELSE
				// Check if using a SetPoint interval or not
				IF BrickGapTargetMin <> BrickGapTargetMax THEN
					Out := PIControllerICM_0.Output;
					PIControllerICM_0.Hold := NOT Running OR BeltMissingElements OR NoElements OR (BrickGap >= BrickGapTargetMin AND BrickGap <= BrickGapTargetMax);
				ELSE
					Out := PIControllerICM_0.Output;
					PIControllerICM_0.Hold := NOT Running OR BeltMissingElements OR NoElements;
				END_IF
			END_IF
			
			IF NOT Enable THEN
				PIControllerICM_0.Enable := FALSE;
				state := 0;
			END_IF

	END_CASE
	
	IF init THEN
		init := FALSE;
		PIControllerICM_0.InverseControl := TRUE;
		PIControllerICM_0.Kp := 0.011;  
		PIControllerICM_0.KiPositive := 0.011;  
		PIControllerICM_0.KiNegative := 0.011;  
		PIControllerICM_0.LoopRate := 1000;
		PIControllerICM_0.MinOutput := 5;
		PIControllerICM_0.IntegralLeak := 0.05;
		PIControllerICM_0.Hold := TRUE;
	END_IF

	PIControllerICM_0.ProcessValue := BrickGap;
	PIControllerICM_0.Setpoint := BrickGapTargetMin;
	PIControllerICM_0.MaxOutput := MaxOutput;
	PIControllerICM_0();
	

	
END_FUNCTION_BLOCK

FUNCTION_BLOCK LFController
	
	CASE state OF
		0:
			Active := FALSE;
			IF Enable THEN
				Active := TRUE;
				PIControllerICM_0.FeedForward := StaticOut;
				PIControllerICM_0.Output := StaticOut;
				PIControllerICM_0.Integral := 0;
				PIControllerICM_0.Enable := TRUE;
				state := 10;
			ELSE
				Out := StaticOut;
			END_IF
		
		10:	
			// Check if using a SetPoint interval or not
			IF BrickGapTargetMin <> BrickGapTargetMax THEN
				PIControllerICM_0.Hold := NOT Running OR BeltMissingElements OR (BrickGap >= BrickGapTargetMin AND BrickGap <= BrickGapTargetMax);
			ELSE
				PIControllerICM_0.Hold := NOT Running OR BeltMissingElements;
			END_IF
			
			Out := PIControllerICM_0.Output;
			
			IF NOT Enable THEN
				PIControllerICM_0.Enable := FALSE;
				state := 0;
			END_IF

	END_CASE
	
	IF init THEN
		init := FALSE;
		PIControllerICM_0.InverseControl := TRUE;
		PIControllerICM_0.Kp := 0.015; 
		PIControllerICM_0.KiPositive := 0.015;  
		PIControllerICM_0.KiNegative := 0.015;  
		PIControllerICM_0.LoopRate := 1000;
		PIControllerICM_0.MinOutput := 10;
		PIControllerICM_0.MaxOutput := 130;
		PIControllerICM_0.IntegralLeak := 0.05;
		PIControllerICM_0.Hold := TRUE;
	END_IF

	PIControllerICM_0.ProcessValue := BrickGap;
	PIControllerICM_0.Setpoint := BrickGapTargetMin;
	PIControllerICM_0();
	
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK PIControllerICM
	
	IF NOT Enable AND Active THEN
		state := 0;
		Error := 0;
		Integral := 0;
		Output := 0;
		loopTime := 0;
		Active := FALSE;
	END_IF

	CASE state OF
		0:
			IF Enable THEN
				Active := TRUE;
				state := 10;
			END_IF
	
		10:
			RTInfo_0.enable := TRUE;
			RTInfo_0();
			
			IF RTInfo_0.status = ERR_OK THEN
				LastOutput := Output;
				state := 20;
			END_IF
			
		20:
			
			loopTime := loopTime + RTInfo_0.cycle_time / 1000;
		
			
			IF loopTime >= LoopRate THEN
				loopTime := 0;
				
				IF NOT Hold THEN
					
					// Calculate the error
					IF InverseControl THEN
						Error := ProcessValue - Setpoint;
					ELSE
						Error := Setpoint - ProcessValue;
					END_IF
		    		
					// Anti windup if output is saturated
					IF ((Output > MinOutput AND Output < MaxOutput) OR (Output = MinOutput AND Error > 0) OR (Output = MaxOutput AND Error < 0)) AND NOT FreezeIntegral THEN
						// Integral accumulation
						IF Error > 0 THEN
							Integral := Integral + (KiPositive * Error);
						ELSE
							Integral := Integral + (KiNegative * Error);
						END_IF
						
						Integral := Integral - IntegralLeak;
					END_IF
				
					// PI controller formula with limits on output
					Output := LIMIT(MinOutput, Kp * Error + Integral + FeedForward, MaxOutput);  
					
					// Rate limiting to prevent sudden large changes
					IF Output > LastOutput + MaxOutputChange THEN
						Output := LastOutput + MaxOutputChange;
					ELSIF Output < LastOutput - MaxOutputChange THEN
						Output := LastOutput - MaxOutputChange;
					END_IF
					LastOutput := Output;
				
				ELSE
				//	Integral := Integral - IntegralLeak;
				END_IF
			END_IF
	END_CASE
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK GetBrickGapTargetMinMax
	(* Get SetPoint interval *)
	CASE PortionCount OF
		
		0,1:
			CFMin := 55;
			CFMax := 130;
			LFMin := 35;
			LFMax := 70;
			
		2:
			CFMin := 55;
			CFMax := 100;
			LFMin := 35;
			LFMax := 45;
			
		3:
			CFMin := 50;
			CFMax := 60;
			LFMin := 30;
			LFMax := 30;
			
		4:
			CFMin := 50;
			CFMax := 55;
			LFMin := 30;
			LFMax := 30;
			
		ELSE
			CFMin := 55;
			CFMax := 55;
			LFMin := 30;
			LFMax := 30;
			
		
	END_CASE
	
END_FUNCTION_BLOCK

FUNCTION GetBrickGapTargetCF
	CASE PortionCount OF
		0,1:
			GetBrickGapTargetCF := 100;
		2:
			GetBrickGapTargetCF := 80;
		3:
			GetBrickGapTargetCF := 60;
		4:
			GetBrickGapTargetCF := 55;
		ELSE
			GetBrickGapTargetCF := 55;
	END_CASE
END_FUNCTION

FUNCTION GetBrickGapTargetLF
	CASE PortionCount OF
		0,1:
			GetBrickGapTargetLF := 60;
		2:
			GetBrickGapTargetLF := 50;
		3:
			GetBrickGapTargetLF := 40;
		4:
			GetBrickGapTargetLF := 35;
		ELSE
			GetBrickGapTargetLF := 35;
	END_CASE
END_FUNCTION

