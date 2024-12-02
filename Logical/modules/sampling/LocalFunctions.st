
(* TODO: Add your comment here *)
FUNCTION_BLOCK BrickDetector	
	brickPresent := FALSE;
	brickNotPresent := FALSE;
	IF enable THEN
		buffer[fifoIdx] := signal;
		endIdx := fifoIdx;
		IF fifoIdx = RMS_BUFFER_LEN THEN
			fifoIdx := 0;
			ready := TRUE;
		ELSE
			fifoIdx := fifoIdx + 1;
		END_IF
		IF ready THEN
			a := (buffer[endIdx]-buffer[fifoIdx])/ USINT_TO_REAL(RMS_BUFFER_LEN);
			b := buffer[fifoIdx];
			rms := 0;
			FOR i:=0 TO RMS_BUFFER_LEN DO
				rms := rms + EXPT((buffer[(fifoIdx+i) MOD (RMS_BUFFER_LEN+1)]) - (a*UDINT_TO_REAL(i)+b), 2);
			END_FOR
			rms := rms / USINT_TO_REAL(RMS_BUFFER_LEN + 1);
		
			IF rms > rmsMax THEN
				rmsMax := rms;
			END_IF
			
			slope := a;
			rmsThreshold := LIMIT(threshold,rmsMaxThreshold*factorRmsMax,450);
			
			IF rms < rmsThreshold AND ABS(slope) < 1 THEN
				brickCandidate := FALSE;
			END_IF
			
			IF rms > rmsThreshold THEN
				brickCandidate := TRUE;
				presentCounter := SEL(presentCounter >= RMS_COUNT_THRESHOLD, presentCounter + 1, RMS_COUNT_THRESHOLD);
				IF presentCounter >= RMS_COUNT_THRESHOLD AND rmsMax > 500 THEN
					brickPresent := TRUE;
				ELSIF presentCounter > 250 THEN
					brickCandidate := FALSE;
					presentCounter := 0;
				END_IF
			ELSIF rms < rmsThreshold AND ABS(slope) < 2.5 THEN
				presentCounter := SEL(presentCounter = 0, presentCounter - 1, 0);
				IF presentCounter = 0 THEN
					brickNotPresent := TRUE;
					brickCandidate := FALSE;
					currentRmsMax := rmsMax;
					rmsMax := 0;
				END_IF
			END_IF
		END_IF
	ELSE
		fifoIdx := 0;
		ready := FALSE;
		brickCandidate := FALSE;
	END_IF
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickIntegral
	IF enable THEN
		IF NOT bufferFull THEN
			buffer[bufferIdx] := signal;
			IF bufferIdx < 1250 THEN
				bufferIdx := bufferIdx + 1;
			ELSE
				bufferFull := TRUE;
			END_IF
		END_IF
		
		CASE state OF
			0:
				IF calculate THEN
					IF bufferIdx > RMS_COUNT_THRESHOLD+1 THEN
						a := (baselineEnd-baselineStart)/(bufferIdx-RMS_COUNT_THRESHOLD+1);
						b := baselineStart;
						startDive := buffer[0];
						firstDive := TRUE;
						highestPeak := buffer[0];
						currBufferIdx := 0;
						state := 10;
					ELSE
						state := 100;
					END_IF
				END_IF
			
			10:
				FOR i:=currBufferIdx TO bufferIdx-RMS_COUNT_THRESHOLD+1 DO
					IF (a*i+b) - buffer[i] > startDive AND firstDive THEN
						startDive := (a*i+b) - buffer[i];
					END_IF
					IF buffer[i] > highestPeak THEN
						highestPeak := buffer[i];
					END_IF
					IF buffer[i] - baselineStart > lastHighestPeak * 0.2 THEN
						firstDive := FALSE;
					END_IF
					IF buffer[i] > (a*i+b) THEN
						peakIntegrals[noPeaks] := peakIntegrals[noPeaks] + buffer[i] - (a*i+b);
						IF peakStart[noPeaks] = 0 THEN
							peakStart[noPeaks] := i;
						END_IF
					ELSE
						IF peakIntegrals[noPeaks] < 500 THEN
							peakIntegrals[noPeaks] := 0;
						ELSE
							peakEnd[noPeaks] := i;
							startDives[noPeaks] := startDive;
							totalPeakIntegral := peakIntegrals[noPeaks];
							noPeaks := MIN(noPeaks + 1, MAX_PEAKS);
							firstDive := TRUE;
							startDive := 0;
						END_IF
					END_IF
				
					integral := integral + buffer[i] - (a*i+b-startDive);
					
					IF i >= currBufferIdx + 100 THEN
						currBufferIdx := i;
						EXIT;
					END_IF
				END_FOR
				
				IF i > bufferIdx-RMS_COUNT_THRESHOLD+1 THEN
					state := 20;
				END_IF
				
			20:
				// Remove small integrals
				sortedNoPeaks := 0;
				IF noPeaks > 0 AND totalPeakIntegral <> 0 THEN
					FOR j:=0 TO noPeaks-1 DO
						IF peakIntegrals[j] / totalPeakIntegral > 0.05 THEN
							peakIntegrals[sortedNoPeaks] := peakIntegrals[j];
							peakStart[sortedNoPeaks] := peakStart[j];
							peakEnd[sortedNoPeaks] := peakEnd[j];
							startDives[sortedNoPeaks] := startDives[j];
							sortedNoPeaks := sortedNoPeaks + 1;
						END_IF
					END_FOR
				END_IF
				
				state := 30;
				
			30:
				// Calculate integral for each peak
				IF sortedNoPeaks > 0 THEN				
					FOR j:=0 TO sortedNoPeaks-1 DO
						// Find start index
						IF j = 0 THEN
							startIdx := peakStart[j];
						ELSE
							startIdx := peakStart[j] - (peakStart[j]-peakEnd[j-1])/2;
						END_IF
						// Find end index
						IF j = sortedNoPeaks-1 THEN
							endIdx := peakEnd[j];
						ELSE
							endIdx := peakEnd[j] + (peakStart[j+1]-peakEnd[j])/2;
						END_IF
						startDive := startDives[j];
						FOR i:=startIdx TO endIdx DO
							integrals[j] := integrals[j] + buffer[i] - (a*i+b-startDive);
						END_FOR
					END_FOR
				END_IF

				noPeaks := sortedNoPeaks;
				
				state := 100;
				
			100:
				done := TRUE;

				IF NOT calculate THEN
					done := FALSE;
					lastHighestPeak := highestPeak;
					state := 0;
				END_IF

		END_CASE
		oldEnable := TRUE;
	ELSIF oldEnable THEN
		bufferIdx := 0;
		integral := 0;
		noPeaks := 0;
		sortedNoPeaks := 0;
		totalPeakIntegral := 0;
		FOR i:=0 TO MAX_PEAKS DO
			peakIntegrals[i] := 0;
			integrals[i] := 0;
			peakStart[i] := 0;
			peakEnd[i] := 0;
			startDives[i] := 0;
		END_FOR
		
		bufferFull := FALSE;
		oldEnable := FALSE;
	END_IF
	bufferSize := bufferIdx;			
END_FUNCTION_BLOCK

FUNCTION_BLOCK VerifyPeaks

	noVerifiedPeaks := 0;
	brsmemset(ADR(peakCount), 0, SIZEOF(peakCount));
	IF noPeaks > 0 THEN
		FOR i:=0 TO noPeaks-1 DO
			FOR j:=1 TO 6 DO
				IF j > 1 AND controlPercent < 50 THEN
					lowerIntegralLimit := upperIntegralLimit;
				ELSE
					lowerIntegralLimit := (teachIntegral*UINT_TO_REAL(j))-(teachIntegral*(USINT_TO_REAL((controlPercent))/100.0));
				END_IF
				upperIntegralLimit := (teachIntegral*UINT_TO_REAL(j))+(teachIntegral*(USINT_TO_REAL(controlPercent)/100.0));
				IF peakIntegral[i] > lowerIntegralLimit AND peakIntegral[i] <= upperIntegralLimit THEN
					noVerifiedPeaks := noVerifiedPeaks + DINT_TO_USINT(j);
					peakCount[i] := DINT_TO_USINT(j);
					EXIT;
				END_IF
			END_FOR
			IF peakIntegral[i] >= (teachIntegral*6)+(teachIntegral*(USINT_TO_REAL(controlPercent)/100.0)) THEN
				noVerifiedPeaks := noVerifiedPeaks + 7;
				peakCount[i] := 7;
			END_IF
		END_FOR
	END_IF
	
END_FUNCTION_BLOCK

FUNCTION_BLOCK CapconNoiseMeassure

	CASE state OF
		
		0:
			TON_0.IN := beltSpeed = lego_speed_stop;
			TON_0.PT := T#10s;
			TON_0();
		
			IF TON_0.Q THEN
				TON_0.IN := FALSE;
				TON_0();
				MTDataMinMax_0.Enable := FALSE;
				MTDataMinMax_0();
				state := 10;
			END_IF
		
		10:
			
			MTDataMinMax_0.Enable := TRUE;
			MTDataMinMax_0.In := rms;
			MTDataMinMax_0();
			
			TON_0.IN := TRUE;
			TON_0.PT := T#1s;
			TON_0();
		
			IF beltSpeed <> lego_speed_stop THEN
				TON_0.IN := FALSE;
				TON_0();
				state := 0;
			ELSIF TON_0.Q THEN
				TON_0.IN := FALSE;
				TON_0();
				
				Out := MTDataMinMax_0.MaxValue;
				state := 0;
			END_IF
		
		
		
	END_CASE
	
END_FUNCTION_BLOCK
