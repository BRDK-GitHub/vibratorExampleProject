
ACTION ioMappingInput: 
	
	IF this.hwWu[0].di_wingUnitActive THEN
		this.flap.WUstepperConnected 	:= TRUE;
		this.flap.positionFromWUstepper	:= this.hwWu[0].flapPosition;
	ELSIF this.hwWu[1].di_wingUnitActive THEN
		this.flap.WUstepperConnected 	:= TRUE;
		this.flap.positionFromWUstepper	:= this.hwWu[1].flapPosition;
	ELSE
		this.flap.WUstepperConnected := FALSE;
	END_IF
	
END_ACTION
