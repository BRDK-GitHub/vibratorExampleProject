
ACTION lampCtrl:

	brdkOPCUAMethodOperate_LampMode();
	IF brdkOPCUAMethodOperate_LampMode.state = BRDK_OPCUA_METHOD_IS_CALLED THEN
		this.timeElapsedAfterLampCmd := 0;
		this.countBlinksLamp := 0;
		this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_OFF);
		TON_lamp.IN := FALSE;
		TON_lamp();
		gMachineInterface.cmd.digitalSiloCmdActive := TRUE;
		this.oldSecond := gMachineInterface.status.heartBeatFromGateway;
		brdkOPCUAMethodOperate_LampMode.finish := TRUE;
	END_IF

	IF this.hmi.startLightTowerTest THEN
		
		this.TON_BalluffLightTowerTest.IN := TRUE;
		this.TON_BalluffLightTowerTest.PT := T#1500ms;
		this.TON_BalluffLightTowerTest();
				
		IF this.TON_BalluffLightTowerTest.Q THEN
			this.TON_BalluffLightTowerTest.IN := FALSE;
			this.TON_BalluffLightTowerTest();
			
			this.count := this.count + 1;
		
			CASE this.count OF
				1: this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_RED);
				2: this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_GREEN);
				3: this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_BLUE);
			ELSE
				this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_OFF);
				this.count := 0;
				this.hmi.startLightTowerTest := FALSE;
			END_CASE
			
		END_IF
		
		IF EDGEPOS(this.hmi.startLightTowerTest) THEN
			this.count := 0;
		END_IF
	
		ELSIF NOT gMachineInterface.cmd.digitalSiloCmdActive THEN
		
			// Digital Silo Inactive - use "normal" digital output from machine.
			IF this.hw.do_alarmBeacon THEN
				this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_BLUE);
			ELSE
				this.hw.output_lightTowerBalluff := 0;
			END_IF
		
		ELSE
			// Digital silo active
		
			CASE lampFlash OF
		
				FLASH_PERMANENT:
					// Digital Silo active
					this.hw.output_lightTowerBalluff := DINT_TO_USINT(lampColor);
			
					// Timeout
					this.timeElapsedAfterLampCmd := this.timeElapsedAfterLampCmd + em.status.cycleTime;
					IF this.timeElapsedAfterLampCmd >= (lampTimeout*1000) THEN
						this.timeElapsedAfterLampCmd := 0;
						lampColor := COLOR_OFF;
						lampFlash := FLASH_PERMANENT;
						gMachineInterface.cmd.digitalSiloCmdActive := FALSE;
					END_IF
		
		
				FLASH_FLASH:
			
				// Flash interval is controlled from gateway via. UDP
				IF gMachineInterface.status.heartBeatFromGateway <> this.oldSecond THEN
				
					IF (gMachineInterface.status.heartBeatFromGateway MOD 2) = 0 THEN
						this.hw.output_lightTowerBalluff := DINT_TO_USINT(lampColor);
					ELSE
						this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_OFF);
					END_IF
					
				END_IF
				this.oldSecond := gMachineInterface.status.heartBeatFromGateway;
					
				// Timeout
				this.timeElapsedAfterLampCmd := this.timeElapsedAfterLampCmd + em.status.cycleTime;
				IF this.timeElapsedAfterLampCmd >= (lampTimeout*1000) THEN
					this.timeElapsedAfterLampCmd := 0;
					lampColor := COLOR_OFF;
					lampFlash := FLASH_PERMANENT;
					gMachineInterface.cmd.digitalSiloCmdActive := FALSE;
				END_IF
		
			FLASH_BLINK:
			
				// Blink interval is controlled from gateway via. UDP
				IF gMachineInterface.status.heartBeatFromGateway <> this.oldSecond THEN
					
					IF (gMachineInterface.status.heartBeatFromGateway MOD 2) = 0 THEN
						this.hw.output_lightTowerBalluff := DINT_TO_USINT(lampColor);
						this.countBlinksLamp := this.countBlinksLamp + 1;
					ELSE
						this.hw.output_lightTowerBalluff := DINT_TO_USINT(COLOR_OFF);
					END_IF
					
				END_IF
				this.oldSecond := gMachineInterface.status.heartBeatFromGateway;
				
				// lamp repeat limit
				IF this.countBlinksLamp >= lampRepeat THEN
					this.countBlinksLamp := 0;
					lampColor := COLOR_OFF;
					lampFlash := FLASH_PERMANENT;
					gMachineInterface.cmd.digitalSiloCmdActive := FALSE;
				END_IF
			
		END_CASE
		
	END_IF


END_ACTION
