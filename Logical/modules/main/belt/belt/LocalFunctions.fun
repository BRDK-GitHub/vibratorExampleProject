
FUNCTION_BLOCK BrickGapMeasure
	VAR_INPUT
		Enable : BOOL;
		Signal : {REDUND_UNREPLICABLE} BOOL;
		BeltPosition : REAL;
	END_VAR
	VAR_OUTPUT
		BrickGap : REAL;
	END_VAR
	VAR
		state : USINT;
		lastBeltPosition : REAL;
		totalBrickGap : REAL;
		brickCount : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK AutoMode
	VAR_INPUT
		Enable : BOOL;
		BeltPosition : REAL;
		BrickGap : REAL;
		BrickCount : UDINT;
		TargetBrickGap : REAL;
	END_VAR
	VAR_OUTPUT
		Measure : BOOL;
		GapOK : BOOL;
		BeltWaitSpeed : REAL;
		CFCountSpeed : REAL;
		CFWaitSpeed : REAL;
		LFCountSpeed : REAL;
		LFWaitSpeed : REAL;
	END_VAR
	VAR
		state : UINT;
		currentBrickCount : UDINT;
		speed : REAL;
		lastBeltPosition : REAL;
		gain : REAL := 0.001;
		totalGapCount : UDINT;
		gapOKCount : UDINT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK AutoModeSimple
	VAR_INPUT
		Enable : BOOL;
		BrickCount : UDINT := 0;
		BrickGap : REAL;
		TargetBrickGap : REAL;
	END_VAR
	VAR_OUTPUT
		AdjustPercent : SINT;
		GapOK : BOOL;
	END_VAR
	VAR
		currentBrickCount : UDINT;
		state : USINT;
		evaluationCount : UDINT := 15; (*We evalate if we should change adjustPercent every time we count this many bricks*)
		evaluationGap : REAL := 10; (*Target gap +- this variable is accepted*)
	END_VAR
END_FUNCTION_BLOCK

{REDUND_ERROR} FUNCTION_BLOCK BrickInfo (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Signal : {REDUND_UNREPLICABLE} BOOL;
		Speed : LEGO_SPEED_ENUM;
		BeltPosition : REAL;
		Reset : BOOL;
	END_VAR
	VAR_OUTPUT
		BrickGap : REAL;
		BrickLength : REAL;
		MinBrickGap : REAL;
		BrickGap75 : REAL;
		MissingElements : BOOL;
		BricksTooClosePrc : REAL;
		BrickCount : UDINT;
	END_VAR
	VAR
		state : USINT;
		lastBeltPosition : REAL;
		Median_0 : Median;
		Median_1 : Median;
		Median_MinBrickGap : Median;
		TON_MissingElements : TON;
		MTFilterMovingAverage_0 : MTFilterMovingAverage;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickCounter
	VAR_INPUT
		Signal : BOOL;
		Reset : BOOL;
	END_VAR
	VAR_OUTPUT
		Count : UINT;
		TotalCount : UDINT;
	END_VAR
	VAR
		state : UINT;
		oldReset : BOOL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK BrickDetector
	VAR_INPUT
		Signal : BOOL;
		ItemGap : {REDUND_UNREPLICABLE} BOOL;
		BeltPosition : REAL;
		FlickeringFilterGap : REAL := 5; (*[mm] Minimum itemgap that is always on til filter flickering of photosensor*)
		FlickeringFilterGapLong : REAL;
	END_VAR
	VAR_OUTPUT
		Teaching : BOOL;
		Out : BOOL;
		BricksCounted : UDINT;
	END_VAR
	VAR
		state : USINT;
		state2 : USINT;
		tmpPosition : REAL;
		lastBeltPosition : REAL;
		avgBrickLength : REAL;
		brickLength : REAL;
		teachingCount : UINT;
		minPosItemGap : REAL := 10;
		tmpPositionFlicker : REAL;
		flickerFilterDist : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK RampUpTimeCalc
	VAR_INPUT
		Enable : BOOL;
		BeltFeederSensor : BOOL;
		OKPortions : UDINT;
		ChangeOverCounter : UDINT;
		Running : BOOL;
		CFSensor : BOOL := FALSE;
	END_VAR
	VAR_OUTPUT
		RampUpTime : REAL; (*[s]*)
	END_VAR
	VAR
		state : UINT;
		lastChangeOverCounter : UDINT;
		startTime : LREAL;
		lastOKPortions : UDINT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK Median
	VAR_INPUT
		Reset : BOOL;
		In : REAL;
		BufferLength : UINT := 40;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
		Out75 : REAL;
		Out10 : REAL;
		Out20 : REAL;
	END_VAR
	VAR
		buffer : ARRAY[0..39] OF REAL;
		bufferIdx : UINT;
		tmpBuffer : ARRAY[0..39] OF REAL;
		temp : REAL;
		i : UINT;
		j : UINT;
		noBufferElements : UINT;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK SpeedRippleCalc
	VAR_INPUT
		Enable : BOOL;
		Axis : {REDUND_UNREPLICABLE} UDINT;
	END_VAR
	VAR_OUTPUT
		Out : REAL;
	END_VAR
	VAR
		MC_BR_CyclicRead_0 : MC_BR_CyclicRead;
		MTDataStatistics_0 : MTDataStatistics;
		actVelocity : REAL;
	END_VAR
END_FUNCTION_BLOCK
(*Insert your comment here.*)

FUNCTION_BLOCK PIControllerICM
	VAR_INPUT
		Enable : BOOL;
		Hold : BOOL;
		FreezeIntegral : BOOL;
		IntegralLeak : REAL; (*Makes the integral part leaky*)
		LoopRate : UDINT; (*[ms] loop rate*)
		Setpoint : REAL;
		ProcessValue : REAL;
		Kp : REAL;
		KiNegative : REAL;
		KiPositive : REAL;
		MinOutput : REAL;
		MaxOutput : REAL;
		Integral : REAL;
		Output : REAL;
		FeedForward : REAL;
		InverseControl : BOOL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Error : REAL;
	END_VAR
	VAR
		state : INT;
		RTInfo_0 : RTInfo;
		loopTime : REAL;
		MaxOutputChange : REAL := 1.0;
		LastOutput : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK CFController
	VAR_INPUT
		Enable : BOOL;
		StaticOut : REAL;
		Running : BOOL;
		NoElements : BOOL;
		BeltMissingElements : BOOL;
		BrickGap : REAL;
		BrickGapTargetMin : REAL := 40;
		BrickGapTargetMax : REAL;
		MaxOutput : REAL;
		PortionCount : UDINT;
		LFOut : REAL;
		LFOffset : REAL := 10; (*% LF offset to CF output (if 10 then LF will minimum be 10% bigger)*)
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Out : REAL;
	END_VAR
	VAR
		state : INT;
		PIControllerICM_0 : PIControllerICM;
		init : BOOL := TRUE;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK LFController
	VAR_INPUT
		Enable : BOOL;
		StaticOut : REAL;
		Running : BOOL;
		NoElements : BOOL;
		BeltMissingElements : BOOL;
		BrickGap : REAL;
		BrickGapTargetMin : REAL := 40;
		BrickGapTargetMax : REAL;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Out : REAL;
	END_VAR
	VAR
		state : INT;
		PIControllerICM_0 : PIControllerICM;
		init : BOOL := TRUE;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK GetBrickGapTargetMinMax
	VAR_INPUT
		PortionCount : UDINT;
	END_VAR
	VAR_OUTPUT
		CFMin : REAL;
		CFMax : REAL;
		LFMin : REAL;
		LFMax : REAL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION GetBrickGapTargetCF : REAL
	VAR_INPUT
		PortionCount : UDINT;
	END_VAR
END_FUNCTION

FUNCTION GetBrickGapTargetLF : REAL
	VAR_INPUT
		PortionCount : UDINT;
	END_VAR
END_FUNCTION
