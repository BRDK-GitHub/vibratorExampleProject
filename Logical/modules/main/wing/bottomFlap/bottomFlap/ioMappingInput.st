
ACTION ioMappingInput: 
	
	IF this.hwWu[0].di_wingUnitActive THEN
		this.hw.di_neigbourIsDosing				 := this.hwWu[0].neigbourIsDosing;
		this.hw.di_neighbourActive				 := this.hwWu[0].neighbourActive;
		this.hw.di_neighbourPortionReady		 := this.hwWu[0].neighbourPortionReady;
		this.flap.WUstepperConnected			 := TRUE;
		this.flap.positionFromWUstepper 		 := this.hwWu[0].flapPosition;
		this.neighbourFlap.WUstepperConnected	 := TRUE;
		this.neighbourFlap.positionFromWUstepper := this.hwWu[0].neighbourFlapPosition;
	ELSIF this.hwWu[1].di_wingUnitActive THEN
		this.hw.di_neigbourIsDosing				 := this.hwWu[1].neigbourIsDosing;
		this.hw.di_neighbourActive				 := this.hwWu[1].neighbourActive;
		this.hw.di_neighbourPortionReady		 := this.hwWu[1].neighbourPortionReady;
		this.flap.WUstepperConnected			 := TRUE;
		this.flap.positionFromWUstepper 		 := this.hwWu[1].flapPosition;
		this.neighbourFlap.WUstepperConnected	 := TRUE;
		this.neighbourFlap.positionFromWUstepper := this.hwWu[1].neighbourFlapPosition;
	ELSE
		this.hw.di_neigbourIsDosing				 := this.hwAir.di_neigbourIsDosing;
		this.hw.di_neighbourActive				 := this.hwAir.di_neighbourActive;
		this.hw.di_neighbourPortionReady		 := this.hwAir.di_neighbourPortionReady;
		this.flap.WUstepperConnected			 := FALSE;
	END_IF
	
END_ACTION
