
ACTION simFeeder: 

	IF feeder.activated THEN
		
		//===============================================================================
		//						Read outputs
		//===============================================================================
		//feeder:this.hw.do_flapOpen
		feeder.hw.out[0].enable := TRUE;
		feeder.hw.out[0].pvName := 'feeder:this.hw.do_flapOpen';
		feeder.hw.out[0]();
		
		//feeder:this.hw.do_flapClose
		feeder.hw.out[1].enable := TRUE;
		feeder.hw.out[1].pvName := 'feeder:this.hw.do_flapClose';
		feeder.hw.out[1]();
		
		//feeder:this.hw.do_beltBackwards
		feeder.hw.out[2].enable := TRUE;
		feeder.hw.out[2].pvName := 'feeder:this.hw.do_beltBackwards';
		feeder.hw.out[2]();
		
		//===============================================================================
		//						Set inputs
		//===============================================================================
		
		// Set level sensor in bowl high for 5s and low for 10s
		feeder.var.TOF_levelSensorOn(IN := feeder.var.TON_levelSensorOff.Q, PT := T#5s);
		feeder.var.TON_levelSensorOff(IN := NOT feeder.var.TOF_levelSensorOn.Q, PT := T#10s);
		feeder.hw.in[4].setValue := SEL(feeder.var.TOF_levelSensorOn.Q, 0, 1);
				
		// Set state for flap
		feeder.var.TON_0.PT := T#5s;
		CASE feeder.var.stateFlap OF
			0:
				IF feeder.hw.out[0].actValue = 1 THEN
					feeder.var.stateFlap := 10;
				ELSIF feeder.hw.out[1].actValue = 1 THEN
					feeder.var.stateFlap := 20;
				END_IF
			10:
				feeder.var.TON_0(IN := TRUE);
						
				IF feeder.var.TON_0.Q THEN
					feeder.var.TON_0(IN := FALSE);
					feeder.hw.in[2].setValue :=	feeder.hw.in[3].setValue := 0;
					feeder.var.stateFlap := 0;
				END_IF
			20:
				feeder.var.TON_0(IN := TRUE);
						
				IF feeder.var.TON_0.Q THEN
					feeder.var.TON_0(IN := FALSE);
					feeder.hw.in[2].setValue := feeder.hw.in[3].setValue := 1;
					feeder.var.stateFlap := 0;
				END_IF
		END_CASE
				
		// Set stateFlap for box ready
		feeder.hw.in[1].setValue := feeder.hw.out[2].actValue = 0;
		
		//::feeder:this.hw.di_levelSensorBelt
		feeder.hw.in[0].enable := TRUE;
		feeder.hw.in[0].dpName := '%IX.IF6.ST9.DigitalInput03';
		feeder.hw.in[0].setValue := 1;
		feeder.hw.in[0]();
		
		//::feeder:this.hw.di_boxIsReadyAtFlap
		feeder.hw.in[1].enable := TRUE;
		feeder.hw.in[1].dpName := '%IX.IF6.ST9.DigitalInput05';
		feeder.hw.in[1]();
		
		//::feeder:this.hw.di_flapIsClosed
		feeder.hw.in[2].enable := TRUE;
		feeder.hw.in[2].dpName := '%IX.IF6.ST9.DigitalInput04';
		feeder.hw.in[2]();
		
		//::feeder:this.hw.di_flapIsOpen
		feeder.hw.in[3].enable := TRUE;
		feeder.hw.in[3].dpName := '%IX.IF6.ST9.DigitalInput02';
		feeder.hw.in[3]();
		
		//::feeder:this.hw.di_levelSensorInBowl
		feeder.hw.in[4].enable := TRUE;
		feeder.hw.in[4].dpName := '%IX.IF6.ST1.DigitalInput01';
		feeder.hw.in[4]();
		
	END_IF

END_ACTION
