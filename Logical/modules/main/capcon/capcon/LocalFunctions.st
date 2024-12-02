
FUNCTION_BLOCK TeachIntegral
	
	CASE state OF
		0:
			IF Enable THEN
				IF NOT teachCandidate THEN
					teachCandidateIntegral[0] := In;
					Out := In;
					teachCandidateCounter := 1;
					teachCandidate := TRUE;
				ELSE
					IF NoPeaks <> BrickCount AND CapconModeOn THEN
						teachCandidate := FALSE;
						teachCandidateCounter := 0;	
						teachCounter := teachCounter + 1;
						IF teachCounter = 18 THEN
							state := 100;	
						END_IF
					ELSE
						teachCandidateIntegral[teachCandidateCounter] := In;
						teachCandidateCounter := teachCandidateCounter + 1;
						IF teachCandidateCounter > MIN(MAX_TEACH_CANDIDATES, NoPortions) THEN
							teachIntegral := 0;
							FOR i:=0 TO MAX_TEACH_CANDIDATES DO
								teachIntegral := teachIntegral + teachCandidateIntegral[i];
							END_FOR
							teachIntegral := teachIntegral / USINT_TO_REAL(MIN(MAX_TEACH_CANDIDATES, NoPortions)+1);
							state := 10;
						END_IF
					END_IF
				END_IF
			END_IF

		10:
			Done := TRUE;

		100:
			Error := TRUE;
			
	END_CASE
	
	IF NOT Enable THEN
		Done := FALSE;
		Error := FALSE;
		brsmemset(ADR(teachCandidateIntegral), 0, SIZEOF(teachCandidateIntegral));
		teachCandidate := FALSE;
		teachIntegral := 0;
		state := 0;	
	END_IF

END_FUNCTION_BLOCK
