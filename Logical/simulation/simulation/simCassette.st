
ACTION simCassette:
	
	IF cassette.activated THEN
		gCassetteInterface.cmd.cassetteIsBeingSimulated := TRUE;
		// init sim (TRUE = no box)
		IF EDGEPOS(cassette.activated) THEN
			cassette.hw.in[0].setValue := TRUE;
			cassette.hw.in[1].setValue := TRUE;
		END_IF
		
		
		//===============================================================================
		//						Read outputs
		//===============================================================================
		//cassette:this.hw.do_bricksReadyInCassette
		cassette.hw.out[0].enable := TRUE;
		cassette.hw.out[0].pvName := 'cassette:this.hw.do_bricksReadyInCassette';
		cassette.hw.out[0]();
		
		//cassette:this.hw.do_cassetteRelease
		cassette.hw.out[1].enable := TRUE;
		cassette.hw.out[1].pvName := 'cassette:this.hw.do_cassetteRelease';
		cassette.hw.out[1]();
		
		
	
		
		//===============================================================================
		//						Set inputs
		//===============================================================================
		
		cassette.hw.in[0].enable   := TRUE;
		cassette.hw.in[0].dpName   := '%IX.IF6.ST6.DigitalInput03';		//cassette:this.hw.di_cassetteReady
		
		cassette.hw.in[1].enable   := TRUE;
		cassette.hw.in[1].dpName   := '%IX.IF6.ST6.DigitalInput01';		//cassette:this.hw.di_cassetteQueue
		
		
		//cassette:this.hw.di_cassetteQueue
		CASE cassette.var.state OF
			0:
				cassette.hw.in[0].setValue := 0; // no cassette on ready sensor
			
				cassette.var.tonDelay(IN := TRUE, PT:=cassette.var.toReadyTime);
				
				IF cassette.var.tonDelay.Q THEN
					cassette.var.tonDelay(IN:=FALSE);
					cassette.var.state := 10;
				END_IF
			10:
				cassette.var.tonDelay(IN := cassette.hw.out[1].actValue > 0, PT:=cassette.var.toReadyTime);

				IF cassette.var.tonDelay.Q THEN
					cassette.var.tonDelay(IN:=FALSE);
					cassette.var.state := 20;
				END_IF

			20:
				cassette.hw.in[0].setValue := 1; // cassette on ready sensor
				
				cassette.var.tonDelay(IN := TRUE, PT:=cassette.var.fromReadyTime);
				
				IF cassette.var.tonDelay.Q THEN
					cassette.var.tonDelay(IN:=FALSE);
					cassette.var.tofDelay(IN := TRUE, PT:=cassette.var.cassetteQueueTime);
					cassette.var.state := 0;
				END_IF
		END_CASE
		
		cassette.var.tofDelay(IN := FALSE, PT:=cassette.var.toReadyTime);
		cassette.hw.in[1].setValue := SEL(cassette.var.tofDelay.Q, 1, 0); // no cassette on queue sensor
		
		
	cassette.hw.in[0]();
	cassette.hw.in[1]();
		
	IF gWingInterface.status.simNeighbour THEN
		//cassette:this.hw.di_neighbourBricksInCassette
		cassette.hw.in[2].enable   := TRUE;
			cassette.hw.in[2].dpName   := '%IX.IF6.ST6.DigitalInput07';
			IF cassette.hw.out[0].actValue > 0 THEN // this machine has brics ready then wing do also.
				cassette.hw.in[2].setValue := 1;
			ELSE
				cassette.hw.in[2].setValue := 0;
			END_IF
		ELSE
			cassette.hw.in[2].enable   := FALSE;
		END_IF
		cassette.hw.in[2]();
		
		
		
	ELSE
		gCassetteInterface.cmd.cassetteIsBeingSimulated := FALSE;
	END_IF
	
END_ACTION
