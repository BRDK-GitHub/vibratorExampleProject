
ACTION simWing:

	IF wing.activated THEN
		
		//===============================================================================
		//						Read outputs
		//===============================================================================
		//upperOpen
		wing.hw.out[0].enable := TRUE;
		wing.hw.out[0].pvName := 'upperFlap:this.hw.do_open';
		wing.hw.out[0]();
		
		//middleOpen
		wing.hw.out[1].enable := TRUE;
		wing.hw.out[1].pvName := 'middleFlap:this.hw.do_open';
		wing.hw.out[1]();
		
		//bottomOpen
		wing.hw.out[2].enable := TRUE;
		wing.hw.out[2].pvName := 'bottomFlap:this.hw.do_open';
		wing.hw.out[2]();
		

		
		
		
		//===============================================================================
		//						Set inputs
		//===============================================================================
		//::upperFlap:this.flap.di_changeover
		wing.hw.in[0].enable   := TRUE;
		wing.hw.in[0].dpName   := '%IX.IF6.ST5.DigitalInput01';
		
		//::middleFlap:this.flap.di_changeover
		wing.hw.in[1].enable   := TRUE;
		wing.hw.in[1].dpName   := '%IX.IF6.ST5.DigitalInput03';
		
		//::bottomFlap:this.flap.di_changeover
		wing.hw.in[2].enable   := TRUE;
		wing.hw.in[2].dpName   := '%IX.IF6.ST5.DigitalInput02';
		

		
		FOR i:=0 TO MAX_WINGS DO
			wing.var.TON_delay[i].PT := T#50ms;
			wing.var.TOF_changeOver[i].PT := T#20ms;
			// check for change
			IF wing.var.oldVal[i] <> wing.hw.out[i].actValue THEN
				wing.var.TON_delay[i].IN := TRUE;
			END_IF
			// after delay time
			wing.var.TOF_changeOver[i].IN := wing.var.TON_delay[i].Q;
	
			IF wing.var.TOF_changeOver[i].Q THEN
				wing.var.TON_delay[i].IN := FALSE;
				wing.hw.in[i].setValue := 1;
			ELSE
				wing.hw.in[i].setValue := 0;
			END_IF
			
			wing.var.TON_delay[i]();
			wing.var.TOF_changeOver[i]();
			wing.var.oldVal[i] := wing.hw.out[i].actValue;
		END_FOR
		
		wing.hw.in[0]();
		wing.hw.in[1]();
		wing.hw.in[2]();
			
	END_IF
	
	IF gWingInterface.status.simNeighbour OR wing.activated THEN
		//neighbourBottomOpen
		wing.hw.out[3].enable := TRUE;
		wing.hw.out[3].pvName := 'bottomFlap:this.hw.do_neighbourOpen';
		wing.hw.out[3]();
					
		//bricksInMiddle
		wing.hw.out[4].enable := TRUE;
		wing.hw.out[4].pvName := 'cassette:this.hw.do_bricksReadyInCassette';
		wing.hw.out[4]();
			
		//bricksInMiddle
		wing.hw.out[5].enable := TRUE;
		wing.hw.out[5].pvName := 'bottomFlap:this.hw.do_neighbourPortionReady';
		wing.hw.out[5]();
		
		//::bottomFlap:this.neighbourFlap.di_changeover
		wing.hw.in[3].enable   := TRUE;
		wing.hw.in[3].dpName   := '%IX.IF6.ST5.DigitalInput04';
			
		 i:=3;
		wing.var.TON_delay[i].PT := T#50ms;
		wing.var.TOF_changeOver[i].PT := T#20ms;
		// check for change
		IF wing.var.oldVal[i] <> wing.hw.out[i].actValue THEN
			wing.var.TON_delay[i].IN := TRUE;
		END_IF
		// after delay time
		wing.var.TOF_changeOver[i].IN := wing.var.TON_delay[i].Q;
	
		IF wing.var.TOF_changeOver[i].Q THEN
			wing.var.TON_delay[i].IN := FALSE;
			wing.hw.in[i].setValue := 1;
		ELSE
			wing.hw.in[i].setValue := 0;
		END_IF
			
		wing.var.TON_delay[i]();
		wing.var.TOF_changeOver[i]();
		wing.var.oldVal[i] := wing.hw.out[i].actValue;
	
		wing.hw.in[3]();
			
	
		//::bottomFlap:this.hw.di_neighbourActive
		wing.hw.in[4].enable   := gWingInterface.status.simNeighbour;
		wing.hw.in[4].dpName   := '%IX.IF6.ST6.DigitalInput02';
		wing.hw.in[4].setValue := 1;
		wing.hw.in[4]();
			
		//::bottomFlap:this.hw.di_neighbourPortionReady
		wing.hw.in[5].enable   :=  gWingInterface.status.simNeighbour;
		wing.hw.in[5].dpName   := '%IX.IF6.ST6.DigitalInput05';
		IF wing.hw.out[5].actValue > 0 THEN
			wing.hw.in[5].setValue := 1;
		ELSE
			wing.hw.in[5].setValue := 0;
		END_IF
		wing.hw.in[5]();
		
	END_IF
	
	
END_ACTION
