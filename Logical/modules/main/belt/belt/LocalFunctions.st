
(* TODO: Add your comment here *)
FUNCTION_BLOCK BrickDetector
	CASE state OF
		
		0:
			IF Signal THEN
				Out := TRUE;
				BricksCounted := BricksCounted + 1;
				tmpPosition := BeltPosition;
				flickerFilterDist := SEL(ItemGap,FlickeringFilterGap,FlickeringFilterGapLong); // Use 2 mm extra if itemGap is enabled.
				state := SEL(flickerFilterDist>0.0,30,10);
			END_IF
			
		10:
			IF NOT Signal THEN
				tmpPositionFlicker := BeltPosition;
				state := 20;
			END_IF
			
		20:
			IF Signal THEN
				state := 10;
			ELSIF NOT Signal AND ABS(BeltPosition - tmpPositionFlicker) > flickerFilterDist AND ABS(BeltPosition - tmpPosition) > minPosItemGap THEN
				Out := FALSE;
				state := 0;
			END_IF
		
		30:
			IF NOT Signal THEN
				Out := FALSE;
				state := 0;
			END_IF
		
	END_CASE
	
	CASE state2 OF
		0:
			IF ItemGap AND minPosItemGap = 0 THEN
				Teaching := TRUE;
				state2 := 10;
			END_IF
		10:
			IF Signal THEN
				lastBeltPosition := BeltPosition;
				state2 := 20;
			END_IF
		20:
			IF NOT Signal THEN
				brickLength := ABS(BeltPosition-lastBeltPosition);
				teachingCount := teachingCount + 1;
				avgBrickLength := avgBrickLength + brickLength;

				state2 := 10;
				IF teachingCount > 10 THEN
					Teaching := FALSE;
					teachingCount := 0;
					minPosItemGap := avgBrickLength/10.0;
					state2 := 0;
				END_IF
			END_IF		
	END_CASE
	
	IF NOT ItemGap THEN
		minPosItemGap := 0;
		teachingCount := 0;
		avgBrickLength := 0;
		Teaching := FALSE;
		state2 := 0;
	END_IF

END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickInfo
	CASE state OF
		0:
			IF Signal THEN
				state := 10;
			END_IF
		
		10:
			IF NOT Signal THEN
				Median_0.In := ABS(BeltPosition-lastBeltPosition);
				Median_0();
				lastBeltPosition := BeltPosition;
				state := 20;
			END_IF
		
		20:
			IF Signal THEN
				Median_1.In := MIN(200, ABS(BeltPosition-lastBeltPosition));
				Median_1();
				Median_MinBrickGap.In := MIN(150, ABS(BeltPosition-lastBeltPosition));
				Median_MinBrickGap();
				lastBeltPosition := BeltPosition;
				TON_MissingElements.IN := FALSE;
				TON_MissingElements();
				BrickCount := BrickCount + 1;
				state := 10;
			END_IF
		
	END_CASE
	
	IF BeltPosition < lastBeltPosition THEN
		lastBeltPosition := BeltPosition;
	END_IF
	
	Median_0.BufferLength := 40;
	Median_1.BufferLength := 20;
	Median_MinBrickGap.BufferLength := 40;
	
	BrickGap := Median_1.Out;
	MinBrickGap := Median_MinBrickGap.Out20;
	BrickGap75 := Median_MinBrickGap.Out75;
	BrickLength := Median_0.Out75;
	
	TON_MissingElements.IN := TRUE;
	TON_MissingElements.PT := T#3s;
	TON_MissingElements();
	
	MissingElements := TON_MissingElements.Q;
	
	IF Reset THEN
		Reset := FALSE;
		Median_0.Reset := TRUE;
		Median_0();
		Median_1.Reset := TRUE;
		Median_1();
		Median_MinBrickGap.Reset := TRUE;
		Median_MinBrickGap();
		BrickCount := 0;
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickGapMeasure

	CASE state OF
		0:
			IF Enable THEN
				state := 10;
			END_IF
		
		10:
			IF Signal THEN
				state := 20;
			END_IF
		
		20:
			IF NOT Signal THEN
				lastBeltPosition := BeltPosition;
				state := 30;
			END_IF
		
		30:
			IF Signal THEN
				totalBrickGap := totalBrickGap + LIMIT(0, ABS(BeltPosition-lastBeltPosition), 200);
				brickCount := brickCount + 1;
				BrickGap := totalBrickGap / brickCount;
				state := 20;
			END_IF
		
	END_CASE
	
	IF NOT Enable THEN
		totalBrickGap := 0;
		brickCount := 0;
		BrickGap := 0;
		state := 0;
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickCounter

	CASE state OF
		0:
			IF Signal THEN
				state := 10;
			END_IF
		
		10:
			IF NOT Signal THEN
				Count := Count + 1;
				TotalCount := TotalCount + 1;
				state := 0;
			END_IF
	END_CASE
	
	IF Reset AND NOT oldReset THEN
		Count := 0;
	END_IF
	
	oldReset := Reset;
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK AutoMode
	
	CASE state OF
		0:
			IF Enable THEN
				currentBrickCount := BrickCount;
				speed := -0.2;
				BeltWaitSpeed := LIMIT(0, (speed*0.1177+0.288127)*500, 600);
				CFCountSpeed := LIMIT(0, (speed*0.5445+0.334)*87+5, 100);
				CFWaitSpeed := LIMIT(0, (speed*0.357+0.111)*95, 100);
				LFCountSpeed := LIMIT(0, (speed*0.6448+0.31719)*87+13, 100);
				LFWaitSpeed := LIMIT(0, (speed*0.3826+0.1107)*95+5, 100);
				state := 10;
			END_IF
		
		10: // Wait for new brick
			IF BrickCount > currentBrickCount THEN
				lastBeltPosition := BeltPosition;
				Measure := TRUE;
				state := 20;
			END_IF
			
		20: // Wait for belt to move
			IF ABS(BeltPosition-lastBeltPosition) > 1000 THEN
				totalGapCount := totalGapCount + 1;
				IF BrickGap = 0 THEN
					speed := speed + 0.01;
					gapOKCount := 0;
				ELSIF ABS(BrickGap - TargetBrickGap) > 5 THEN
					speed := speed + ((BrickGap - TargetBrickGap) * gain);
					gapOKCount := 0;
				ELSE
					gapOKCount := gapOKCount + 1;
				END_IF
				IF gapOKCount > 1 OR totalGapCount > 7 THEN
					GapOK := TRUE;
				END_IF
				BeltWaitSpeed := LIMIT(0, (speed*0.1177+0.288127)*500, 600);
				CFCountSpeed := LIMIT(0, (speed*0.5445+0.334)*87+5, 100);
				CFWaitSpeed := LIMIT(0, (speed*0.357+0.111)*95, 100);
				LFCountSpeed := LIMIT(0, (speed*0.6448+0.31719)*87+13, 100);
				LFWaitSpeed := LIMIT(0, (speed*0.3826+0.1107)*95+5, 100);
				lastBeltPosition := BeltPosition;
				Measure := FALSE;
				state := 30;
			END_IF
		
		30: // Wait for belt to move to flush bricks
			IF ABS(BeltPosition-lastBeltPosition) > 1000 THEN
				currentBrickCount := BrickCount;
				state := 10;
			END_IF

	END_CASE
	
	IF NOT Enable AND state <> 0 THEN
		GapOK := FALSE;
		Measure := FALSE;
		state := 0;
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK AutoModeSimple
	
	CASE state OF
		
		0:
			IF Enable THEN
				currentBrickCount := BrickCount;
				AdjustPercent := 0;
				GapOK := FALSE;
				state := 10;
			END_IF
		
		10:
			IF BrickCount > currentBrickCount + evaluationCount THEN
				currentBrickCount := BrickCount;
				IF BrickGap > TargetBrickGap + evaluationGap AND AdjustPercent < 20 THEN
					AdjustPercent := AdjustPercent + 1;
				ELSIF BrickGap < TargetBrickGap + evaluationGap AND AdjustPercent > -20 THEN
					AdjustPercent := AdjustPercent - 1;
				ELSIF AdjustPercent < 20 AND AdjustPercent > -20 THEN
					// Signal to capcon that we found OK gap
					GapOK := TRUE;
				END_IF
			ELSIF NOT Enable THEN
				AdjustPercent := 0;
				GapOK := FALSE;
				state := 0;
			END_IF
		

	END_CASE

END_FUNCTION_BLOCK

FUNCTION_BLOCK RampUpTimeCalc

	CASE state OF
		0:
			IF Enable THEN
				lastChangeOverCounter := ChangeOverCounter;
				state := 10;
			END_IF

		10:
			IF ChangeOverCounter <> lastChangeOverCounter AND Running THEN
				lastChangeOverCounter := ChangeOverCounter;
				RampUpTime := 0;
				state := 20;
			END_IF

		20:
			IF BeltFeederSensor OR CFSensor THEN
				startTime := TIME_TO_LREAL(clock_ms());
				lastOKPortions := OKPortions;
				state := 30;
			END_IF

		30:
			IF OKPortions > lastOKPortions THEN
				RampUpTime := LREAL_TO_REAL((TIME_TO_LREAL(clock_ms()) - startTime) / 1000);
				lastChangeOverCounter := ChangeOverCounter;
				state := 10;
			END_IF
	END_CASE

	IF NOT Enable AND state <> 0 THEN
		state := 0;
	END_IF

END_FUNCTION_BLOCK

FUNCTION_BLOCK Median

	buffer[bufferIdx] := In;
	bufferIdx := bufferIdx + 1;
	IF bufferIdx > MIN(SIZEOF(buffer), BufferLength) THEN
		bufferIdx := 0;
	END_IF

	brsmemcpy(ADR(tmpBuffer), ADR(buffer), SIZEOF(tmpBuffer));
	temp := 0;
	FOR i:=0 TO noBufferElements DO
		FOR j:=i+1 TO noBufferElements DO
			IF tmpBuffer[i] > tmpBuffer[j] THEN
				temp := tmpBuffer[i];
				tmpBuffer[i] := tmpBuffer[j];
				tmpBuffer[j] := temp;
			END_IF
		END_FOR
	END_FOR
	
	noBufferElements := MIN(BufferLength-1, noBufferElements + 1);
	
	Out10 := tmpBuffer[noBufferElements/10];
	Out20 := tmpBuffer[noBufferElements/5];
	Out := tmpBuffer[noBufferElements/2];
	Out75 := tmpBuffer[noBufferElements*3/5]; // was 3/4 
	
	IF Reset THEN
		Reset := FALSE;
		brsmemset(ADR(buffer), 0, SIZEOF(buffer));
		bufferIdx := 0;
		noBufferElements := 0;
	END_IF
	
END_FUNCTION_BLOCK


FUNCTION_BLOCK SpeedRippleCalc

	MC_BR_CyclicRead_0.Enable := Enable;
	MC_BR_CyclicRead_0.Axis := Axis;
	MC_BR_CyclicRead_0.DataAddress := ADR(actVelocity);
	MC_BR_CyclicRead_0.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicRead_0.ParID := ACP10PAR_PCTRL_V_ACT;
	MC_BR_CyclicRead_0();
	
	MTDataStatistics_0.Enable := Enable AND MC_BR_CyclicRead_0.Valid;
	MTDataStatistics_0.In := ABS(actVelocity/100.0);
	MTDataStatistics_0.MovingWindowLength := 300;
	MTDataStatistics_0();
	
	Out := 1.28*MTDataStatistics_0.StdDeviation;
	
	
END_FUNCTION_BLOCK