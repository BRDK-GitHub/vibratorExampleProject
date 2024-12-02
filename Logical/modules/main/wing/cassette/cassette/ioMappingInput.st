
ACTION ioMappingInput: 
	
	IF this.hwWu[0].di_wingUnitActive THEN
		IF interface.cmd.cassetteIsBeingSimulated THEN
			this.hw.di_cassetteQueue			 := this.hwAir.di_cassetteQueue;
			this.hw.di_cassetteReady			 := this.hwAir.di_cassetteReady;	
		ELSE
			this.hw.di_cassetteQueue			 := this.hwWu[0].di_cassetteQueue;
			this.hw.di_cassetteReady			 := this.hwWu[0].di_cassetteReady;
		END_IF
		this.hw.di_neighbourActive 			 := this.hwWu[0].di_neighbourActive;
		this.hw.di_neighbourIsDosing 		 := this.hwWu[0].di_neighbourIsDosing;
		this.hw.di_neighbourBricksInCassette := this.hwWu[0].di_neighbourBricksInCassette;
	ELSIF this.hwWu[1].di_wingUnitActive THEN
		IF interface.cmd.cassetteIsBeingSimulated THEN
			this.hw.di_cassetteQueue			 := this.hwAir.di_cassetteQueue;
			this.hw.di_cassetteReady			 := this.hwAir.di_cassetteReady;	
		ELSE
			this.hw.di_cassetteQueue			 := this.hwWu[1].di_cassetteQueue;
			this.hw.di_cassetteReady			 := this.hwWu[1].di_cassetteReady;
		END_IF
		this.hw.di_neighbourActive 			 := this.hwWu[1].di_neighbourActive;
		this.hw.di_neighbourIsDosing 		 := this.hwWu[1].di_neighbourIsDosing;
		this.hw.di_neighbourBricksInCassette := this.hwWu[1].di_neighbourBricksInCassette;
	ELSE
		this.hw.di_cassetteQueue			 := this.hwAir.di_cassetteQueue;
		this.hw.di_cassetteReady			 := this.hwAir.di_cassetteReady;
		this.hw.di_neighbourActive 			 := this.hwAir.di_neighbourActive;
		this.hw.di_neighbourIsDosing 		 := this.hwAir.di_neighbourIsDosing;
		this.hw.di_neighbourBricksInCassette := this.hwAir.di_neighbourBricksInCassette;
	END_IF
	
END_ACTION
