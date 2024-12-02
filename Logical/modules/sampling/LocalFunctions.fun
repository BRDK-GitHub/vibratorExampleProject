
FUNCTION_BLOCK VerifyPeaks
	VAR_INPUT
		teachIntegral : REAL;
		controlPercent : USINT;
		peakIntegral : REFERENCE TO ARRAY[0..MAX_PEAKS] OF REAL;
		noPeaks : UINT;
	END_VAR
	VAR_OUTPUT
		noVerifiedPeaks : USINT;
		peakCount : ARRAY[0..MAX_PEAKS] OF USINT;
	END_VAR
	VAR
		j : UINT;
		i : UINT;
		upperIntegralLimit : REAL;
		lowerIntegralLimit : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickDetector
	VAR_INPUT
		enable : BOOL;
		signal : REAL;
		threshold : REAL; (*Rms threshold for when it is considered a brick*)
		factorRmsMax : REAL := 0.001;
		rmsMaxThreshold : REAL;
	END_VAR
	VAR_OUTPUT
		ready : BOOL;
		rms : REAL;
		slope : REAL;
		brickPresent : BOOL;
		brickNotPresent : BOOL;
		brickCandidate : BOOL;
		currentRmsMax : REAL;
	END_VAR
	VAR
		rmsThreshold : REAL;
		fifoIdx : UDINT;
		endIdx : UDINT;
		buffer : ARRAY[0..49] OF REAL;
		a : REAL;
		b : REAL;
		i : UDINT;
		rmsMax : REAL;
		presentCounter : UDINT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickIntegral
	VAR_INPUT
		enable : BOOL; (*Enable function block and start buffering signal*)
		calculate : BOOL; (*Integral calculated when true*)
		signal : REAL;
		baselineStart : REAL;
		baselineEnd : REAL;
	END_VAR
	VAR_OUTPUT
		done : BOOL;
		integral : REAL; (*The integral calculated when calculate is true*)
		bufferSize : UINT;
		bufferFull : BOOL; (*The internal buffer is full and the integral is wrong after this point*)
		noPeaks : USINT;
		peakIntegrals : ARRAY[0..MAX_PEAKS] OF REAL;
		integrals : ARRAY[0..MAX_PEAKS] OF REAL;
		startDive : REAL;
		highestPeak : REAL;
	END_VAR
	VAR
		state : UINT;
		buffer : ARRAY[0..2500] OF REAL;
		bufferIdx : UINT;
		currBufferIdx : UINT;
		i : UINT;
		j : UINT;
		a : REAL;
		b : REAL;
		totalPeakIntegral : REAL;
		peakStart : ARRAY[0..MAX_PEAKS] OF UINT;
		peakEnd : ARRAY[0..MAX_PEAKS] OF UINT;
		startDives : ARRAY[0..MAX_PEAKS] OF REAL;
		startIdx : UINT;
		endIdx : UINT;
		sortedNoPeaks : USINT;
		oldEnable : BOOL;
		firstDive : BOOL;
		lastHighestPeak : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK CapconNoiseMeassure
	VAR_INPUT
		beltSpeed : LEGO_SPEED_ENUM;
		rms : REAL;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
	END_VAR
	VAR
		MTDataMinMax_0 : MTDataMinMax;
		state : USINT;
		TON_0 : TON;
	END_VAR
END_FUNCTION_BLOCK
