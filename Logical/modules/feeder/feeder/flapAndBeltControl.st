ACTION flapControl:
	
	this.flap.internal.TON_delaySwitch.PT  := T#100ms;
	this.flap.internal.TON_maxOpenTime.PT  := config.maxOpenCloseTime;
	this.flap.internal.TON_maxCloseTime.PT := config.maxOpenCloseTime;
	this.flap.internal.TON_overCurrentProtect.PT := config.overCurrentProtectTime;
	
	IF this.flap.state <> this.flap.internal.oldState THEN
		
		this.flap.internal.TON_delaySwitch(IN:=FALSE);
		this.flap.internal.TON_maxOpenTime(IN:=FALSE);
		this.flap.internal.TON_maxCloseTime(IN:=FALSE);
		this.flap.internal.TON_overCurrentProtect(IN:=FALSE);
		this.flap.internal.oldState := this.flap.state;
	END_IF
	
	flapOpening := this.hw.do_flapOpen;
	flapClosing := this.hw.do_flapClose;
	
	CASE this.flap.state OF
		
		FEEDER_FLAP_IDLE:
			
			this.hw.do_flapOpen := this.hw.do_flapClose := FALSE;
			
			IF this.flap.cmd.open THEN
				this.flap.state := FEEDER_FLAP_OPENING;
			ELSIF this.flap.cmd.close THEN
				this.flap.state := FEEDER_FLAP_CLOSING;
			ELSE
				IF NOT this.hw.di_flapIsOpen THEN
					this.flap.state := FEEDER_FLAP_OPENED;
				ELSIF this.hw.di_flapIsClosed THEN
					this.flap.state := FEEDER_FLAP_CLOSED;
				END_IF
			END_IF
			
		FEEDER_FLAP_OPENING:
			
			this.hw.do_flapClose := this.flap.cmd.close := FALSE;
			
			IF NOT this.hw.di_flapIsOpen THEN
				this.hw.do_flapOpen := this.flap.cmd.open := FALSE;
				this.flap.state := FEEDER_FLAP_OPENED;
			ELSIF this.flap.cmd.open THEN
				this.flap.internal.TON_maxOpenTime(IN := TRUE);
				this.hw.do_flapOpen := TRUE;
				this.flap.internal.TON_overCurrentProtect(IN := this.hw.di_flapIsClosed);
			ELSE
				this.flap.internal.TON_delaySwitch(IN := TRUE);
				this.hw.do_flapOpen := FALSE;
				IF this.flap.internal.TON_delaySwitch.Q THEN
					this.flap.internal.TON_delaySwitch(IN := FALSE);
					this.flap.internal.TON_maxOpenTime(IN := FALSE);
					this.flap.internal.TON_overCurrentProtect(IN := FALSE);
					this.flap.state := FEEDER_FLAP_IDLE;
				END_IF
			END_IF

			IF this.flap.internal.TON_maxOpenTime.Q OR this.flap.internal.TON_overCurrentProtect.Q THEN
				this.flap.internal.TON_maxOpenTime(IN := FALSE);
				this.flap.internal.TON_overCurrentProtect(IN := FALSE);
				this.hw.do_flapOpen := FALSE;
				this.alarm.cannotOpenFlap.active := TRUE;
				this.flap.state := FEEDER_FLAP_IDLE;
			END_IF
			
		FEEDER_FLAP_OPENED:
			
			this.hw.do_flapOpen := FALSE;
			
			IF this.hw.di_flapIsOpen THEN
				this.flap.state := FEEDER_FLAP_IDLE;
			ELSIF this.flap.cmd.close AND NOT this.flap.cmd.open THEN
				this.flap.state := FEEDER_FLAP_CLOSING;
			END_IF
						
		FEEDER_FLAP_CLOSING:			
			
			this.hw.do_flapOpen := this.flap.cmd.open := FALSE;
			
			IF this.hw.di_flapIsClosed THEN
				this.hw.do_flapClose := this.flap.cmd.close := FALSE;
				this.flap.state := FEEDER_FLAP_CLOSED;
			ELSIF this.flap.cmd.close THEN
				this.flap.internal.TON_maxCloseTime(IN := TRUE);
				this.hw.do_flapClose := TRUE;
				this.flap.internal.TON_overCurrentProtect(IN := NOT this.hw.di_flapIsOpen);
			ELSE
				this.flap.internal.TON_delaySwitch(IN := TRUE);
				this.hw.do_flapClose := FALSE;
				IF this.flap.internal.TON_delaySwitch.Q THEN
					this.flap.internal.TON_delaySwitch(IN := FALSE);
					this.flap.internal.TON_maxCloseTime(IN := FALSE);
					this.flap.internal.TON_overCurrentProtect(IN := FALSE);
					this.flap.state := FEEDER_FLAP_IDLE;
				END_IF
			END_IF
			
			IF this.flap.internal.TON_maxCloseTime.Q OR this.flap.internal.TON_overCurrentProtect.Q THEN
				this.flap.internal.TON_maxCloseTime(IN := FALSE);
				this.flap.internal.TON_overCurrentProtect(IN := FALSE);
				this.hw.do_flapClose := FALSE;
				this.alarm.cannotCloseFlap.active := TRUE;
				this.flap.state := FEEDER_FLAP_IDLE;
			END_IF
			
		FEEDER_FLAP_CLOSED:
		
			this.hw.do_flapClose := FALSE;
			
			IF NOT this.hw.di_flapIsClosed THEN
				this.flap.state := FEEDER_FLAP_IDLE;
			ELSIF this.flap.cmd.open AND NOT this.flap.cmd.close THEN
				this.flap.state := FEEDER_FLAP_OPENING;
			END_IF
		
	END_CASE
	
	this.hmi.status.flapOpen := this.flap.state = FEEDER_FLAP_OPENED;
	this.hmi.status.flapClose := this.flap.state = FEEDER_FLAP_CLOSED;
	
END_ACTION

ACTION beltControl:
	
	this.belt.internal.TON_delaySwitch.PT := T#1000ms;
	
	CASE this.belt.state OF
		
		FEEDER_BELT_IDLE:
			
			this.hw.do_beltBackwards := this.hw.do_beltForwards := FALSE;
			
			IF this.belt.cmd.forwards THEN
				this.belt.state := FEEDER_BELT_FORWARDS;
			ELSIF this.belt.cmd.backwards THEN
				this.belt.state := FEEDER_BELT_BACKWARDS;
			END_IF
			
		FEEDER_BELT_FORWARDS:
			
			this.hw.do_beltBackwards := FALSE;
			
			IF this.belt.cmd.forwards THEN
				this.hw.do_beltForwards := (this.hmi.cmd.enable AND gCapconInterface.status.numBricksInPortion > 0) OR this.hmi.cmd.forceForwards;			// Only run if enabled on HMI
			ELSE
				this.hw.do_beltForwards := FALSE;
				this.belt.internal.TON_delaySwitch(IN := TRUE);
				IF this.belt.internal.TON_delaySwitch.Q THEN
					this.belt.internal.TON_delaySwitch(IN := FALSE);
					this.belt.state := FEEDER_BELT_IDLE;
				END_IF
			END_IF
			
		FEEDER_BELT_BACKWARDS:
			
			this.hw.do_beltForwards := FALSE;
			
			IF this.belt.cmd.backwards THEN
				this.hw.do_beltBackwards := TRUE;
			ELSE
				this.hw.do_beltBackwards := FALSE;
				this.belt.internal.TON_delaySwitch(IN := TRUE);
				IF this.belt.internal.TON_delaySwitch.Q THEN
					this.belt.internal.TON_delaySwitch(IN := FALSE);
					this.belt.state := FEEDER_BELT_IDLE;
				END_IF
			END_IF
		
	END_CASE
	
	END_ACTION