
ACTION simCapcon:

	IF capcon.activated THEN 
		
		//===============================================================================
		//						Set inputs
		//===============================================================================
		
		capcon.var.beltPosition := gBeltInterface.status.actualPosition;
		
		IF capcon.var.beltPosition > belt.var.bricksAtEdge[0] AND belt.var.bricksAtEdgeIdx > 0 THEN
			capcon.var.signals[capcon.var.signalIdx] := 0;
			capcon.var.rejects[capcon.var.signalIdx] := random() < REAL_TO_INT(65534*(capcon.var.errorRate/100)-32767);
			capcon.var.signalIdx := capcon.var.signalIdx + 1;
			IF belt.var.bricksAtEdgeIdx > 0 THEN
				FOR capcon.var.i:=1 TO belt.var.bricksAtEdgeIdx DO
					belt.var.bricksAtEdge[capcon.var.i-1] := belt.var.bricksAtEdge[capcon.var.i];
				END_FOR
				belt.var.bricksAtEdgeIdx := belt.var.bricksAtEdgeIdx - 1;
			END_IF
		END_IF
		
		capcon.var.currSignal := 0;
		IF capcon.var.signalIdx > 0 THEN
			FOR capcon.var.i:=0 TO capcon.var.signalIdx-1 DO
				IF capcon.var.signals[capcon.var.i] > 50 THEN
					capcon.var.x := (capcon.var.signals[capcon.var.i]-97)/4.6;
					IF capcon.var.x = 0 THEN
						capcon.var.x := 0.001;
					END_IF
					capcon.var.currSignal := capcon.var.currSignal + (SIN(capcon.var.x)*SEL(capcon.var.rejects[capcon.var.i], capcon.var.signalHeight, capcon.var.signalHeight*3)/capcon.var.x) * (1/SQRT(2*amPI*pow(0.3, 2))) * EXP((-pow(capcon.var.x-0, 2))/2*pow(0.3, 2));
				END_IF
				capcon.var.signals[capcon.var.i] := capcon.var.signals[capcon.var.i] + 1;
			END_FOR
			IF capcon.var.signals[0] > 143 THEN
				FOR capcon.var.i:=1 TO capcon.var.signalIdx DO
					capcon.var.signals[capcon.var.i-1] := capcon.var.signals[capcon.var.i];
					capcon.var.rejects[capcon.var.i-1] := capcon.var.rejects[capcon.var.i];
				END_FOR
				capcon.var.signalIdx := capcon.var.signalIdx - 1;
			END_IF
		END_IF
		
		gSimCapcon.status.simSignal := REAL_TO_INT(capcon.var.currSignal);
	END_IF

END_ACTION
