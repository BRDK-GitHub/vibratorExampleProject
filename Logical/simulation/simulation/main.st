
PROGRAM _INIT

//	gSimulation.status.simulateAllButWing := TRUE; // REMOVE BEFORE PRODUCTION
	
END_PROGRAM

PROGRAM _CYCLIC
	
	IF gMainInterface.status.simulation THEN
		capcon.activated := TRUE;
		feeder.activated := TRUE;
		belt.activated := TRUE;
		wing.activated := TRUE;
		cassette.activated := TRUE;
		vision.activated := TRUE;
	ELSIF gSimulation.status.simulateAllButWing THEN
		capcon.activated := TRUE;
		feeder.activated := FALSE;
		belt.activated := TRUE;
		wing.activated := FALSE;
		cassette.activated := FALSE;
		vision.activated := FALSE;
	ELSE
		capcon.activated := FALSE;
		feeder.activated := FALSE;
		belt.activated := FALSE;
		wing.activated := FALSE;
		cassette.activated := FALSE;
		vision.activated := FALSE;
	END_IF
	
	//vibrator; // remove warning 
	
	cassette.activated := gWingInterface.status.simCassette;
	
	//simulation of feeder
	simFeeder;
	
	//simulation of vibrator
	//simVibrator;
	
	//simulation of belt
	simBelt;
	
	//simulation of capcon
	simCapcon;
	
	//simulation of wing unit
	//simWing;
	
	//simulation of cassette
	simCassette;
	 
END_PROGRAM

PROGRAM _EXIT
	FOR i:=0 TO MAX_INPUT_CASSETTE DO
		cassette.hw.in[i](enable := FALSE);
	END_FOR
	FOR i:=0 TO MAX_OUTPUT_CASSETTE DO
		cassette.hw.out[i](enable := FALSE);
	END_FOR
	
END_PROGRAM

