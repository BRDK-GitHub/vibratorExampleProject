
ACTION simBelt: 

	IF belt.activated THEN
		
		IF belt.usePWMforSim THEN 
			// using the PWM
			 
			//===============================================================================
			//						Read outputs
			//===============================================================================
			//this.MTBasicsLimiter_0.Out
			belt.hw.out[0].enable := TRUE;
			belt.hw.out[0].pvName := 'belt:this.MTBasicsLimiter_0.Out';
			belt.hw.out[0]();
			
			belt.var.convSpeed := UDINT_TO_REAL(belt.hw.out[0].actValue);
			
			//===============================================================================
			//						Set inputs
			//===============================================================================
			IF belt.hw.in[0].setValue = 0 THEN
				belt.var.TON_sensor.PT := T#300ms;
				belt.var.TON_sensor.IN := SEL(belt.var.convSpeed > 0, FALSE, TRUE);
			ELSE
				belt.var.TON_sensor.PT := T#100ms;
				belt.var.TON_sensor.IN := SEL(belt.var.convSpeed > 0, FALSE, TRUE);		
			END_IF
					
			belt.var.TON_sensor();
			
			
			IF belt.var.TON_sensor.Q THEN
				belt.var.TON_sensor.IN := FALSE;
				belt.var.TON_sensor();
				belt.hw.in[0].setValue := SEL(belt.hw.in[0].setValue = 0, 0, 1);
			END_IF
			
		
		ELSE 
			// using the Servo motor 
			//===============================================================================
			//						Read outputs
			//===============================================================================
			//this.MTBasicsLimiter_0.Out
			belt.hw.out[0].enable := TRUE;
			belt.hw.out[0].pvName := 'belt:axis.status.actPosition';
			belt.hw.out[0]();
			
			belt.var.convPosition := gBeltInterface.status.actualPosition;
		
			//===============================================================================
			//						Set inputs
			//===============================================================================
			CASE belt.var.state OF
				0:
					belt.var.brickEnd := belt.var.convPosition + belt.var.brickLength;
					IF belt.var.bricksAtEdgeIdx < 300 THEN
						belt.var.bricksAtEdge[belt.var.bricksAtEdgeIdx] := belt.var.brickEnd + 10;
						belt.var.bricksAtEdgeIdx := belt.var.bricksAtEdgeIdx + 1;
					END_IF
					belt.var.brickStart := belt.var.convPosition;
					belt.hw.in[0].setValue := TRUE;
					belt.var.state := 10;
					
				10:
					IF belt.var.convPosition >= belt.var.brickEnd THEN
						belt.hw.in[0].setValue := FALSE;
						belt.var.gapLength := belt.var.brickLength / ((USINT_TO_REAL(gVibratorInterface[1].status.countingSpeed)/100)*belt.var.percentToSpeed);
						belt.var.gapLengthVarMin := REAL_TO_UDINT(belt.var.gapLength - belt.var.gapLength * belt.var.gapVariancePrc);
						belt.var.gapLengthVarMax := REAL_TO_UDINT(belt.var.gapLength + belt.var.gapLength * belt.var.gapVariancePrc);
						belt.var.brickGap := belt.var.convPosition + UDINT_TO_REAL(rand_interval(belt.var.gapLengthVarMin, belt.var.gapLengthVarMax));
						belt.var.gapStart := belt.var.convPosition;
						belt.var.state := 20;
					ELSIF belt.var.convPosition < belt.var.brickStart THEN
						brsmemset(ADR(belt.var.bricksAtEdge), 0, SIZEOF(belt.var.bricksAtEdge));
						belt.var.bricksAtEdgeIdx := 0;
						brsmemset(ADR(capcon.var.signals), 0, SIZEOF(capcon.var.signals));
						brsmemset(ADR(capcon.var.rejects), 0, SIZEOF(capcon.var.rejects));
						capcon.var.signalIdx := 0;
						belt.var.state := 0;
					END_IF
				
				20:
					IF belt.var.convPosition >= belt.var.brickGap THEN
						belt.var.state := 0;
					ELSIF belt.var.convPosition < belt.var.gapStart THEN
						brsmemset(ADR(belt.var.bricksAtEdge), 0, SIZEOF(belt.var.bricksAtEdge));
						belt.var.bricksAtEdgeIdx := 0;
						brsmemset(ADR(capcon.var.signals), 0, SIZEOF(capcon.var.signals));
						brsmemset(ADR(capcon.var.rejects), 0, SIZEOF(capcon.var.rejects));
						capcon.var.signalIdx := 0;	
						belt.var.state := 0;
					END_IF
			END_CASE
			
			gSimulation.status.photoSensor := belt.hw.in[0].setValue = 1;
			
//			IF (REAL_TO_UDINT(belt.var.convPosition) MOD 400) > 370 THEN
//				belt.hw.in[0].setValue := TRUE;
//			ELSE
//				belt.hw.in[0].setValue := FALSE;
//			END_IF
		
		END_IF
	END_IF

END_ACTION
