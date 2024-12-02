
ACTION ioMappingInput: 
	
	IF this.hwWu[0].di_wingUnitActive THEN
		this.flap.WUstepperConnected := TRUE;
		this.flap.positionFromWUstepper := this.hwWu[0].flapPosition;
	ELSIF this.hwWu[1].di_wingUnitActive THEN
		this.flap.WUstepperConnected := TRUE;
		this.flap.positionFromWUstepper := this.hwWu[1].flapPosition;
	ELSE
		this.flap.WUstepperConnected := FALSE;
	END_IF
	
	gWingInterface.status.stepperWUConnected	:= this.hwWu[0].di_wingUnitActive OR this.hwWu[1].di_wingUnitActive;
	
END_ACTION
