
PROGRAM _INIT

	MaxCurr := 1.5;		 // Max current [A]
	frequency := 49.0;	 // frequency [Hz]
	
	initParIDs := TRUE;
	
END_PROGRAM

PROGRAM _CYCLIC
	
	MC_Power_0.Enable := Run;
	MC_Power_0.Axis := ADR(gAxisVibC);
	MC_Power_0();
	
	IF MC_Power_0.Status THEN
//		............................ Wave Generator ..................................
//		...............o......o.......................................................
//		............o............o....................................................
//		..........o................o..................................................
//		........o....................o................................................
//		.......o......................o...............................................
//		.....o..........................o.............................................
//		....o............................o............................................
//		...o...............................o..........................................
//		....................................o..............................o..........
//		.....................................o............................o...........
//		......................................o..........................o............
//		........................................o......................o..............
//		.........................................o....................o...............
//		...........................................o................o.................
//		.............................................o............o...................
//		................................................o......o......................
		
		amplitude_out := LIMIT(-MaxCurr,amplitude_out,MaxCurr);
		sin_out := amplitude_out*SIN(phi);
		phi := fmod(phi + frequency*2*PI*CYCLE_TIME_s, 2*PI);
	ELSE
		sin_out := 0.0;
	END_IF
	
	// Write sine wave to vibrator parID (Will be interpolated in drive with SPT Function Block)
	MC_BR_CyclicWrite_0.Enable := Run;
	MC_BR_CyclicWrite_0.Axis := ADR(gAxisVibC);
	MC_BR_CyclicWrite_0.DataType := ncPAR_TYP_REAL;
	MC_BR_CyclicWrite_0.DataAddress := ADR(sin_out);
	MC_BR_CyclicWrite_0.ParID := ACP10PAR_USER_R4_VAR1;
	MC_BR_CyclicWrite_0();
	
	
	
	IF initParIDs THEN
			
		// Have to overwrite in code to "cheat" the drive into using Current Controller for 1 phase control (doesn't work in parameter table)
		MC_BR_WriteParID_0.Execute 			:= TRUE;
		MC_BR_WriteParID_0.Axis 			:= ADR(gAxisVibC);
		MC_BR_WriteParID_0.ParID 			:= ACP10PAR_CONTROLLER_MODE;
		MC_BR_WriteParID_0.DataType 		:= ncPAR_TYP_USINT;
		MC_BR_WriteParID_0.DataAddress	 	:= ADR(CONTROLLER_MODE_CURR_CTRL); // 5=Current Controller
		MC_BR_WriteParID_0();
		
		MC_BR_WriteParID_1.Execute 			:= TRUE;
		MC_BR_WriteParID_1.Axis 			:= ADR(gAxisVibC);
		MC_BR_WriteParID_1.ParID 			:= ACP10PAR_ICTRL_SET_PARID;	// SetPoint to ACP10 Current Controller
		MC_BR_WriteParID_1.DataType 		:= ncPAR_TYP_UINT;
		MC_BR_WriteParID_1.DataAddress 		:= ADR(PARID_IPL1_OUT);
		MC_BR_WriteParID_1();
		
		IF MC_BR_WriteParID_0.Done AND MC_BR_WriteParID_1.Done THEN
			MC_BR_WriteParID_0.Execute := FALSE;
			MC_BR_WriteParID_0();
			MC_BR_WriteParID_1.Execute := FALSE;
			MC_BR_WriteParID_1();
			
			initParIDs := FALSE; // Done
		END_IF
		
	END_IF
		

END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

