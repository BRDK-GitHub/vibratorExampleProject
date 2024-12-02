
PROGRAM _INIT

	ST_name(0,ADR(this.configName),0);
	brdkStrCat(ADR(this.configName),ADR(':this.config'));
	ST_name(0,ADR(this.resultName),0);
	brdkStrCat(ADR(this.resultName),ADR(':resultFAT'));
	
	MpRecipeRegPar_Config.Enable := TRUE;
	this.MpRecipeXml_0.Load := TRUE;
	this.ton_chekForChanges.PT := T#5s;

	
END_PROGRAM

PROGRAM _CYCLIC
	
	// If machine aborts stop all tests.
	IF gMainInterface.status.state = STATE_ABORTED THEN
		this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
	END_IF
	
	CASE state OF
		
		0:
			IF gFile.status.ready AND (gConfig.status.saved OR gConfig.status.loaded) AND this.resultsFATLoaded  THEN
				
				this.config.timeLeft88h := 88.0-(this.config.timeElapsed88h/3600);
				this.config.timeLeft88h := getHourMinutsFromDecimal(this.config.timeLeft88h);
				this.config.timeLeft12h := 12.0-(this.config.timeElapsed12h/3600);
				this.config.timeLeft12h := getHourMinutsFromDecimal(this.config.timeLeft12h);
				this.hmi.cmd.enableArrowNext := this.hmi.cmd.enableMenuNavigation := resultFAT.initialGroundMeas.done;
				
				state := 5;
			
			END_IF
		
		5:
			IF this.hmi.cmd.startFAT THEN
				// Only go to these states if FAT have been opened
				IF stateRetain > 0 THEN
					state := stateRetain;
				ELSE
					state := 10;
				END_IF
			END_IF
			
		10:
			// Initial ground measurements
			
			resultFAT.initialGroundMeas.firstMeasurementDone := resultFAT.initialGroundMeas.measurementValue <= 0.1 AND resultFAT.initialGroundMeas.measurementValue > 0.0;
					
			resultFAT.resistanceMeas2.done := TRUE;
			FOR i:=0 TO 9 DO
						
				CASE i OF
							
					0,1,2,3,7,8:	// 10ohm max resistance.
						IF resultFAT.resistanceMeas2.measurementArr[i]=0.0 OR resultFAT.resistanceMeas2.measurementArr[i] > 0.10 THEN
							resultFAT.resistanceMeas2.done := FALSE;
							resultFAT.resistanceMeas2.measurementOK[i] := FALSE;
						ELSE
							resultFAT.resistanceMeas2.measurementOK[i] := TRUE;
						END_IF
							
					4,5,6:		// 0.33ohm max resistance.
						IF resultFAT.resistanceMeas2.measurementArr[i]=0.0 OR resultFAT.resistanceMeas2.measurementArr[i] > 0.33 THEN
							resultFAT.resistanceMeas2.done := FALSE;
							resultFAT.resistanceMeas2.measurementOK[i] := FALSE;
						ELSE
							resultFAT.resistanceMeas2.measurementOK[i] := TRUE;
						END_IF
							
				END_CASE
			END_FOR
					
			resultFAT.initialGroundMeas.done := resultFAT.initialGroundMeas.firstMeasurementDone AND resultFAT.resistanceMeas2.done;
					
			this.hmi.cmd.enableArrowNext := this.hmi.cmd.enableMenuNavigation := resultFAT.initialGroundMeas.done;
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;
				IF resultFAT.initialGroundMeas.done THEN // only continue if it's done.
					state := 20;
				END_IF
			END_IF
		
		20:
			// Machine setup
			
			// On edgepos of input disable the oppsite (only 1 of 2 is valid)
			// A lot of information is depending on the machine type. All this information will be used at later steps in the FAT.
			IF EDGEPOS(this.hmi.cmd.smallCfToggleButton) THEN
				this.hmi.cmd.bigCfToggleButton := FALSE;
				gVibratorInterface[0].parameter.CFType := 0;
				gVibratorInterface[0].cmd.setCfType := TRUE;
				resultFAT.machineSetup.strCfSize := 'CM20 small';
				resultFAT.machineSetup.strMaxSpecsCF := 'MAX (2A/200V)';
				resultFAT.additionalInfo.weightOfCf := '5.5kg';
				resultFAT.CFSpringAdjust.strTargetFrequency := '48 - 51';
				resultFAT.CFCoilAdjust.magneticGap := 1.2;
				resultFAT.LFCoilAdjust.magneticGap := 0.6;
				resultFAT.machineSetup.cfSize := 0;
			ELSIF EDGEPOS(this.hmi.cmd.bigCfToggleButton) THEN
				this.hmi.cmd.smallCfToggleButton := FALSE;
				gVibratorInterface[0].parameter.CFType := 1;
				gVibratorInterface[0].cmd.setCfType := TRUE;
				resultFAT.machineSetup.strCfSize := 'CM20 large';
				resultFAT.machineSetup.strMaxSpecsCF := 'MAX (2A/200V)';
				resultFAT.additionalInfo.weightOfCf := '13.5kg';
				resultFAT.CFSpringAdjust.strTargetFrequency := '23.7 - 25.5';
				resultFAT.CFCoilAdjust.magneticGap := 2.5;
				resultFAT.LFCoilAdjust.magneticGap := 0.5;
				resultFAT.machineSetup.cfSize := 1;
			ELSIF EDGEPOS(this.hmi.cmd.leftDirectionOfRotation) THEN
				// direction should be 1 on left machine
				this.hmi.cmd.rightDirectionOfRotation := FALSE;
				gBeltInterface.cmd.setDirection := TRUE;
				gBeltInterface.parameter.direction := 1;
				resultFAT.machineSetup.strMachineType := 'Right';		// A machine with "left direction of rotation" is a right machine.	
				resultFAT.machineSetup.strIsItALeftMachine := 'X (Left direction)';
				resultFAT.machineSetup.strIsItARightMachine := '';
				resultFAT.machineSetup.machineType := 0;	// left machine
				//config.machineType := 1;
			ELSIF EDGEPOS(this.hmi.cmd.rightDirectionOfRotation) THEN
				// direction should be 0 on right machine.
				this.hmi.cmd.leftDirectionOfRotation := FALSE;
				gBeltInterface.cmd.setDirection := TRUE;
				gBeltInterface.parameter.direction := 0;
				resultFAT.machineSetup.strMachineType := 'Left';		// A machine with "Right direction of rotation" is a left machine.	
				resultFAT.machineSetup.strIsItALeftMachine := '';
				resultFAT.machineSetup.strIsItARightMachine := 'X (Right direction)';
				resultFAT.machineSetup.machineType := 1;	// right machine
				//config.machineType := 0;
			END_IF
					
			IF resultFAT.machineSetup.done THEN	// in order to load "this.hmi" if machine is restarted. They are not remanent.
				this.hmi.cmd.rightDirectionOfRotation := resultFAT.machineSetup.machineType=1;
				this.hmi.cmd.leftDirectionOfRotation := resultFAT.machineSetup.machineType=0;
				this.hmi.cmd.smallCfToggleButton := resultFAT.machineSetup.cfSize=0;
				this.hmi.cmd.bigCfToggleButton := resultFAT.machineSetup.cfSize=1;
			END_IF
					
			// Allow user to continue ONLY if their input is valid
			IF (this.hmi.cmd.smallCfToggleButton XOR this.hmi.cmd.bigCfToggleButton) AND
				(this.hmi.cmd.leftDirectionOfRotation XOR this.hmi.cmd.rightDirectionOfRotation) THEN
				resultFAT.machineSetup.done := TRUE;
				this.hmi.cmd.enableArrowNext := TRUE;
			ELSE
				resultFAT.machineSetup.done := FALSE;
				this.hmi.cmd.enableArrowNext := FALSE;
			END_IF
					
					
			// COMMENT OUT - this string anyways make 0 sense for report today?
//			IF EDGENEG(gVibratorInterface[0].cmd.setCfType) THEN	// a negative edge means it's done creating the string in vibrator task.
//				resultFAT.machineSetup.strLinearizationAccValuesCF := gVibratorInterface[0].status.strLinearizationAccValues;	// CF string
//				resultFAT.machineSetup.strLinearizationAccValuesLF := gVibratorInterface[1].status.strLinearizationAccValues;	// LF string
//			END_IF
					
					
					
					
					
			// User input to continue to next step
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
						
				// Set vibrator unit type and "top unit type" auto
				IF resultFAT.machineSetup.cfSize = 0 AND resultFAT.machineSetup.machineType = 0 THEN	//  small and left
					resultFAT.additionalInfo.vibratorUnitType := 'SRC-N 250-2L-LEGO II';
					resultFAT.additionalInfo.topUnitType := 'PJ 2016 HA';
				ELSIF resultFAT.machineSetup.cfSize = 0 AND resultFAT.machineSetup.machineType = 1 THEN	//  small and right
					resultFAT.additionalInfo.vibratorUnitType := 'SRC-N 250-2R-LEGO II';
					resultFAT.additionalInfo.topUnitType := 'PJ 2016 VA';
				ELSIF resultFAT.machineSetup.cfSize = 1 AND resultFAT.machineSetup.machineType = 0 THEN	//  big and left
					resultFAT.additionalInfo.vibratorUnitType := 'SRC-N 400-1L-LEGO III';
					resultFAT.additionalInfo.topUnitType := 'PJ 99 HA';
				ELSIF resultFAT.machineSetup.cfSize = 1 AND resultFAT.machineSetup.machineType = 1 THEN	//  big and right
					resultFAT.additionalInfo.vibratorUnitType := 'SRC-N 400-1R-LEGO III';
					resultFAT.additionalInfo.topUnitType := 'PJ 99 VA';
				END_IF
						
				state := 30;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 10;
			END_IF
		
			
		30:
			// Wing connector (wingTestIO)
		
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 40;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 20;
			END_IF
		
		
		
		40:
			// Additional machine info
					
			// Create string typeNo.-SerialNo.
			IF resultFAT.additionalInfo.serialNo <> '' AND resultFAT.additionalInfo.typeNo <> '' THEN
				brdkStrMemSet(ADR(resultFAT.additionalInfo.typeNoAndSerialNo),0,SIZEOF(resultFAT.additionalInfo.typeNoAndSerialNo));
				brdkStrCat(ADR(resultFAT.additionalInfo.typeNoAndSerialNo),ADR(resultFAT.additionalInfo.typeNo));
				this.tmpString := '-';
				brdkStrCat(ADR(resultFAT.additionalInfo.typeNoAndSerialNo),ADR(this.tmpString));
				brdkStrCat(ADR(resultFAT.additionalInfo.typeNoAndSerialNo),ADR(resultFAT.additionalInfo.serialNo));
						
				// SerialNoDINT
				this.tmpString := '';
				brdkStrCat(ADR(this.tmpString),ADR(resultFAT.additionalInfo.typeNo));
				brdkStrCat(ADR(this.tmpString),ADR(resultFAT.additionalInfo.serialNo));
				gMachineInterface.cmd.serialNoDINT := STRING_TO_DINT(this.tmpString); //interface.par.serialNoDINT := STRING_TO_DINT(this.tmpString);
			END_IF
			//interface.par.serialNo := resultFAT.additionalInfo.typeNoAndSerialNo;
					
			// Load "this.hmi.status" texts if they are empty and resultFAT is not (Happens on a warm restart).
			IF this.hmi.status.additionalInfo.typeNo = 0 AND resultFAT.additionalInfo.typeNo <> '' THEN 
				this.hmi.status.additionalInfo.typeNo := STRING_TO_UDINT(resultFAT.additionalInfo.typeNo);
			END_IF
			IF this.hmi.status.additionalInfo.serialNo = 0 AND resultFAT.additionalInfo.serialNo <> '' THEN
				this.hmi.status.additionalInfo.serialNo := STRING_TO_UDINT(resultFAT.additionalInfo.serialNo);
			END_IF
			IF this.hmi.status.additionalInfo.rnoNo = 0.0 AND resultFAT.additionalInfo.rnaProductNo <> '' THEN
				this.hmi.status.additionalInfo.rnoNo := STRING_TO_LREAL(resultFAT.additionalInfo.rnaProductNo);
			END_IF
			IF this.hmi.status.additionalInfo.topSerialNo = 0 AND resultFAT.additionalInfo.topSerialNo <> '' THEN
				this.hmi.status.additionalInfo.topSerialNo := STRING_TO_UDINT(resultFAT.additionalInfo.topSerialNo);
			END_IF
					
			// Put int into strings for report
			resultFAT.additionalInfo.typeNo := UDINT_TO_STRING(this.hmi.status.additionalInfo.typeNo);
			resultFAT.additionalInfo.serialNo := UDINT_TO_STRING(this.hmi.status.additionalInfo.serialNo);
			resultFAT.additionalInfo.rnaProductNo := LREAL_TO_STRING(this.hmi.status.additionalInfo.rnoNo);
			resultFAT.additionalInfo.topSerialNo := UDINT_TO_STRING(this.hmi.status.additionalInfo.topSerialNo);
					
					
			IF this.hmi.status.additionalInfo.IRTHno <> this.oldLREAL THEN
				resultFAT.additionalInfo.IRTHno := LREAL_TO_STRING(this.hmi.status.additionalInfo.IRTHno);
				brdkStrRemove(ADR(resultFAT.additionalInfo.IRTHno),(brdkStrLen(ADR(resultFAT.additionalInfo.IRTHno))-2),2);
						
				IF this.hmi.status.additionalInfo.IRTHno>10000000 THEN // hacky way to append a space to a numeric input from HMI.
					this.tmpString := ' ';
					brdkStrInsertAtPos(ADR(resultFAT.additionalInfo.IRTHno),ADR(this.tmpString),6);
				END_IF
			END_IF
			this.oldLREAL := this.hmi.status.additionalInfo.IRTHno;
					
					
					
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;
				state := 50;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 30;
			END_IF
					
			// If some chars in all text inputs the test is done:
			IF resultFAT.additionalInfo.IRTHno <> '0' AND resultFAT.additionalInfo.IRTHno <> '0.0' AND resultFAT.additionalInfo.rnaProductNo <> '0.0' AND resultFAT.additionalInfo.typeNo <> '0' AND resultFAT.additionalInfo.serialNo <> '0' AND resultFAT.additionalInfo.topSerialNo <> '0' AND resultFAT.additionalInfo.topUnitType <> '' AND resultFAT.additionalInfo.vibratorUnitType <> '' THEN
				resultFAT.additionalInfo.done := TRUE;
			ELSE
				resultFAT.additionalInfo.done := FALSE;
			END_IF
		
		
		50:
		
			//Capcon voltage measurement
					
			// Check if user input is in the expected interval
			IF resultFAT.capconMeasurement.V1 >= 18 - this.maxPlusMinusVoltage AND resultFAT.capconMeasurement.V1 <= 18 + this.maxPlusMinusVoltage THEN
				this.hmi.cmd.crossmarkV1 := 1;	
			ELSE
				this.hmi.cmd.crossmarkV1 := 0;
			END_IF
					
			// Check if user input is in the expected interval
			IF resultFAT.capconMeasurement.V2 >= -15.8 - this.maxPlusMinusVoltage AND resultFAT.capconMeasurement.V2 <= -15.8 + this.maxPlusMinusVoltage THEN
				this.hmi.cmd.crossmarkV2 := 1;	
			ELSE
				this.hmi.cmd.crossmarkV2 := 0;
			END_IF
					
			IF (this.hmi.cmd.crossmarkV1 > 0 AND this.hmi.cmd.crossmarkV2 > 0) THEN
				resultFAT.capconMeasurement.done := TRUE;
				this.hmi.cmd.enableArrowNext := TRUE;
			ELSE
				resultFAT.capconMeasurement.done := FALSE;
				this.hmi.cmd.enableArrowNext := FALSE;
			END_IF
					
			
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;
				state := 60;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 40;
			END_IF
		
		60:
			//	em.description := 'Capcon signal test';
			// 1st test. Test that an analog input is getting into the machine when dropping something through capcon:
					
			// 2nd test. Auto test MAX speed signal doing a period of 5s.
			IF EDGEPOS(this.hmi.cmd.startCapconTest2) THEN
				gCapconInterface.status.maxRawSignal := 0;
				gCapconInterface.cmd.startSpeedSignalTest := TRUE;
			END_IF
					
			IF EDGENEG(gCapconInterface.cmd.startSpeedSignalTest) THEN
				this.hmi.cmd.startCapconTest2 := FALSE;
				this.hmi.status.maxRawSignal := ABS(gCapconInterface.status.maxRawSignal);
				IF this.hmi.status.maxRawSignal>1 AND ABS(this.hmi.status.maxRawSignal) < 100 THEN // TODO: 40 NEEDS TO BE TESTED!
					resultFAT.capconTest.signalTest2 := TRUE;
				ELSE
					resultFAT.capconTest.signalTest2 := FALSE;
				END_IF
			END_IF
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;
				state := 70;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 50;
			END_IF
					
			resultFAT.capconTest.done := resultFAT.capconTest.signalTest1 AND resultFAT.capconTest.signalTest2;
			
		70:
			// em.description := 'Level sensor test';
				
			gFeederInterface.cmd.levelSensorTestActive := TRUE;	
			
			IF this.hmi.cmd.doLevelSensorTest AND resultFAT.levelSensorTest.receiverOK THEN
					
				// level sensor test.
				CASE levelTestState OF
							
					0:
						gFeederInterface.cmd.setLevelSensor[0] := FALSE;
						gFeederInterface.cmd.setLevelSensor[1] := FALSE;
						gFeederInterface.cmd.setLevelSensor[2] := TRUE;
						resultFAT.levelSensorTest.transmitterLowOK := FALSE;
						resultFAT.levelSensorTest.transmitterMediumOK := FALSE;
						resultFAT.levelSensorTest.transmitterHighOK := FALSE;
						resultFAT.levelSensorTest.operatorApproveLow := resultFAT.levelSensorTest.operatorApproveMedium := resultFAT.levelSensorTest.operatorApproveHigh := FALSE;
								
						this.timeElapsed := 0;
						levelTestState := 5;
								
					5:	// wait 1s
						this.timeElapsed := this.timeElapsed + 40000;
						IF this.timeElapsed > 1000000 THEN
							this.timeElapsed := 0;
							IF gFeederInterface.status.levelSensorReceiverInBowl THEN
								levelTestState := 222;
							ELSE
								this.hmi.status.styleToggleInputHigh := TRUE;
								levelTestState := 10;
							END_IF
						END_IF
							
					10: // Wait for user to approve that HIGH transmitter is flashing.
								
						IF gFeederInterface.status.levelSensorReceiverInBowl THEN
							levelTestState := 222;
						ELSIF resultFAT.levelSensorTest.operatorApproveHigh THEN
							resultFAT.levelSensorTest.transmitterHighOK := TRUE;
									
							gFeederInterface.cmd.setLevelSensor[0] := FALSE;
							gFeederInterface.cmd.setLevelSensor[1] := TRUE;
							gFeederInterface.cmd.setLevelSensor[2] := FALSE;
							this.hmi.status.styleToggleInputHigh := FALSE;
							this.hmi.status.styleToggleInputMedium := TRUE;
							levelTestState := 20;
						END_IF
								
					20: // Wait for user to approve that MEDIUM transmitter is flashing.
								
						IF gFeederInterface.status.levelSensorReceiverInBowl THEN
							levelTestState := 222;
						ELSIF resultFAT.levelSensorTest.operatorApproveMedium THEN
							resultFAT.levelSensorTest.transmitterMediumOK := TRUE;
									
							gFeederInterface.cmd.setLevelSensor[0] := TRUE;
							gFeederInterface.cmd.setLevelSensor[1] := FALSE;
							gFeederInterface.cmd.setLevelSensor[2] := FALSE;
							this.hmi.status.styleToggleInputMedium := FALSE;
							this.hmi.status.styleToggleInputLow := TRUE;
									
							levelTestState := 30;
						END_IF
								
					30: //  Wait for user to approve that LOW transmitter is flashing.
								
						IF gFeederInterface.status.levelSensorReceiverInBowl THEN
							levelTestState := 222;
						ELSIF resultFAT.levelSensorTest.operatorApproveLow THEN
							resultFAT.levelSensorTest.transmitterLowOK := TRUE;
									
							gFeederInterface.cmd.setLevelSensor[0] := FALSE;
							gFeederInterface.cmd.setLevelSensor[1] := FALSE;
							gFeederInterface.cmd.setLevelSensor[2] := FALSE;
							this.hmi.status.styleToggleInputLow := FALSE;
							this.hmi.cmd.doLevelSensorTest := FALSE;
							levelTestState := 0;
						END_IF
							
								
					222:
						//test failed reset everything
						this.hmi.cmd.doLevelSensorTest := FALSE;
						gFeederInterface.cmd.setLevelSensor[0] := FALSE;
						gFeederInterface.cmd.setLevelSensor[1] := FALSE;
						gFeederInterface.cmd.setLevelSensor[2] := FALSE;
						resultFAT.levelSensorTest.operatorApproveHigh := resultFAT.levelSensorTest.operatorApproveMedium := resultFAT.levelSensorTest.operatorApproveLow := FALSE;
						resultFAT.levelSensorTest.transmitterLowOK := FALSE;
						resultFAT.levelSensorTest.transmitterMediumOK := FALSE;
						resultFAT.levelSensorTest.transmitterHighOK := FALSE;
						this.hmi.status.styleToggleInputHigh := this.hmi.status.styleToggleInputMedium := this.hmi.status.styleToggleInputLow := FALSE;
						levelTestState := 0;
								
				END_CASE
						
			ELSIF this.hmi.cmd.doLevelSensorTest THEN
				this.hmi.cmd.doLevelSensorTest := FALSE; // reset if user presses button when receiver is not OK.
			ELSE
				// manuel control from user.
				gFeederInterface.cmd.setLevelSensor[0] := this.hmi.cmd.setLevelSensorLow;
				gFeederInterface.cmd.setLevelSensor[1] := this.hmi.cmd.setLevelSensorMedium;
				gFeederInterface.cmd.setLevelSensor[2] := this.hmi.cmd.setLevelSensorHigh;
						
				IF NOT this.hmi.cmd.setLevelSensorHigh AND NOT this.hmi.cmd.setLevelSensorMedium AND NOT this.hmi.cmd.setLevelSensorLow THEN
					// if receiver is high when all transmitters are low the receiver is OK.
					IF gFeederInterface.status.levelSensorReceiverInBowl THEN
						resultFAT.levelSensorTest.receiverOK := TRUE;
					ELSE
						resultFAT.levelSensorTest.receiverOK := FALSE;
					END_IF
				END_IF
						
			END_IF
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				gFeederInterface.cmd.levelSensorTestActive := FALSE;
				state := 80;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				gFeederInterface.cmd.levelSensorTestActive := FALSE;
				state := 60;
			END_IF
					
			resultFAT.levelSensorTest.done := resultFAT.levelSensorTest.receiverOK AND resultFAT.levelSensorTest.transmitterHighOK AND resultFAT.levelSensorTest.transmitterMediumOK AND resultFAT.levelSensorTest.transmitterLowOK;
			//this.hmi.cmd.enableArrowNext := resultFAT.levelSensorTest.done;
			
		80:
			//  'Photo sensor adjustment';
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				state := 90;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 70;
			END_IF
					
			this.hmi.cmd.enableArrowNext := resultFAT.photoSensorAdjust.done;
		
		90:
		//	em.description := 'Wait for automatic test of photo sensor to be done';
					
			IF EDGEPOS(this.hmi.cmd.doPhotoSensorTest) THEN		// Start the test.
						
				this.hmi.status.photoSensorTestText := 0;
				gBeltInterface.cmd.doPhotoSensorTest := TRUE;						// signal to belt that it should start automatic test.
			ELSIF EDGEPOS(this.hmi.cmd.doPhotoSensorTestNoBelt) THEN
						
				gBeltInterface.cmd.doPhotoSensorTestNoBelt := TRUE;
			ELSE
				IF gBeltInterface.status.photoSensorTestResult = TEST_STOPPED THEN
					resultFAT.photoSensorTest.testWithBelt := FALSE;
					gBeltInterface.status.photoSensorTestResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTest := FALSE;
					this.hmi.status.photoSensorTestText := 3;	// test stopped text
				ELSIF gBeltInterface.status.photoSensorTestResult = TEST_NOT_OK THEN	// Something went wrong doing test.
					resultFAT.photoSensorTest.testWithBelt := FALSE;
					gBeltInterface.status.photoSensorTestResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTest := FALSE;
					this.hmi.status.photoSensorTestText := 2;						
				ELSIF gBeltInterface.status.photoSensorTestResult = TEST_OK THEN
					resultFAT.photoSensorTest.testWithBelt := TRUE;
					gBeltInterface.status.photoSensorTestResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTest := FALSE;
					this.hmi.status.photoSensorTestText := 1;
				END_IF
						
				IF gBeltInterface.status.photoSensorTestNoBeltResult = TEST_STOPPED THEN
					resultFAT.photoSensorTest.testWithNoBelt := FALSE;
					gBeltInterface.status.photoSensorTestNoBeltResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTestNoBelt := FALSE;
				ELSIF gBeltInterface.status.photoSensorTestNoBeltResult = TEST_NOT_OK THEN	// Something went wrong doing test.
					resultFAT.photoSensorTest.testWithNoBelt := FALSE;	
					gBeltInterface.status.photoSensorTestNoBeltResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTestNoBelt := FALSE;
				ELSIF gBeltInterface.status.photoSensorTestNoBeltResult = TEST_OK THEN
					resultFAT.photoSensorTest.testWithNoBelt := TRUE;
					gBeltInterface.status.photoSensorTestNoBeltResult := TEST_NOT_DONE;
					this.hmi.cmd.doPhotoSensorTestNoBelt := FALSE;
				END_IF 
						
			END_IF
					
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 100;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 80;
			END_IF
					
					
			IF resultFAT.photoSensorTest.testWithBelt THEN
				this.hmi.status.photoSensorTestText := 1;
			END_IF
			resultFAT.photoSensorTest.done := resultFAT.photoSensorTest.testWithBelt AND resultFAT.photoSensorTest.testWithNoBelt;
			this.hmi.cmd.enableArrowNext := resultFAT.photoSensorTest.done;
		
		100:
			// 'Belt feeder test IO - 1';
					
			IF EDGEPOS(this.hmi.cmd.doBfFlapTest) THEN
				//	this.hmi.cmd.doBfFlapTest := FALSE;		// reset this when test is done instead!!
				// start flap test in feeder task
				resultFAT.bfTestIO.flapTestDone := FALSE;
				gFeederInterface.cmd.startFlapTest := TRUE;
			ELSE
				// reach on test result from flap test.
				IF gFeederInterface.status.flapTest = TEST_STOPPED THEN
					resultFAT.bfTestIO.flapTestDone := FALSE;
					gFeederInterface.status.flapTest := TEST_NOT_DONE;
					this.hmi.cmd.doBfFlapTest := FALSE;
				ELSIF gFeederInterface.status.flapTest = TEST_NOT_OK THEN	// Something went wrong doing test.
					resultFAT.bfTestIO.flapTestDone := FALSE;	
					gFeederInterface.status.flapTest := TEST_NOT_DONE;
					this.hmi.cmd.doBfFlapTest := FALSE;
				ELSIF gFeederInterface.status.flapTest = TEST_OK THEN
					resultFAT.bfTestIO.flapTestDone := TRUE;
					gFeederInterface.status.flapTest := TEST_NOT_DONE;
					this.hmi.cmd.doBfFlapTest := FALSE;
				END_IF 
			END_IF
					
			resultFAT.bfTestIO.done := resultFAT.bfTestIO.approveIOsManually AND resultFAT.bfTestIO.approveMainsVoltage AND resultFAT.bfTestIO.flapTestDone;
					
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 110;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 90;
			END_IF
		
		110:
			// 'Wing test IO - flap namur sensor, cassette signal, dosing signal, cassette queue';
					
			IF EDGEPOS(this.hmi.cmd.doWingTestManuel) THEN
				//this.hmi.cmd.doWingTestManuel := FALSE;
				gUpperFlapInterface.cmd.wingTestManual := TRUE; // Only start upper - they will start each other "sequantially"
				
				// Reset test results
				resultFAT.wingTestIO.upperFlapOK := FALSE;
				resultFAT.wingTestIO.middleFlapOK := FALSE;
				resultFAT.wingTestIO.bottomFlapOK := FALSE;
				resultFAT.wingTestIO.neighbourFlapOK := FALSE; 
				resultFAT.wingTestIO.cassetteReleaseOK := FALSE;
				resultFAT.wingTestIO.ioTestOK := FALSE;

			END_IF
			
			IF this.hmi.cmd.doWingTestManuel THEN
				
				// Wait for all tests to be done
				IF NOT gUpperFlapInterface.cmd.wingTestManual AND NOT gMiddleFlapInterface.cmd.wingTestManual AND NOT gBottomFlapInterface.cmd.wingTestManual AND NOT gCassetteInterface.cmd.wingTestManual THEN
					this.hmi.cmd.doWingTestManuel := FALSE;
					
					// write result from test into resultFAT struct
					resultFAT.wingTestIO.upperFlapOK := gUpperFlapInterface.status.testResultFAT;
					resultFAT.wingTestIO.middleFlapOK := gMiddleFlapInterface.status.testResultFAT;
					resultFAT.wingTestIO.bottomFlapOK := gBottomFlapInterface.status.testResultFAT;
					resultFAT.wingTestIO.neighbourFlapOK := gBottomFlapInterface.status.testResultFAT; // bottom also test neighbour
					resultFAT.wingTestIO.cassetteReleaseOK := gCassetteInterface.status.testResultFAT;
					resultFAT.wingTestIO.ioTestOK := resultFAT.wingTestIO.upperFlapOK AND resultFAT.wingTestIO.middleFlapOK AND resultFAT.wingTestIO.bottomFlapOK AND resultFAT.wingTestIO.neighbourFlapOK AND resultFAT.wingTestIO.cassetteReleaseOK;
					
				END_IF
				
			END_IF
					
			resultFAT.wingTestIO.done := resultFAT.wingTestIO.ioTestOK AND resultFAT.wingTestIO.approveFunctionality;
					
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 120;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 100;
			END_IF
			
					
		120:
			//	'CF coils adjustments';
			
			this.hmi.status.isSmallMachine := gVibratorInterface[0].parameter.machineSize=0;
			this.hmi.status.isBigMachine := gVibratorInterface[0].parameter.machineSize=1;
			
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				// Set default amount of plates if all plate values are set to 0 (means no user input).
				FOR i:=0 TO 2 DO
					IF resultFAT.CFSpringAdjust.plate08mm[i] > 0 OR resultFAT.CFSpringAdjust.plate09mm[i] > 0 OR resultFAT.CFSpringAdjust.plate15mm[i] > 0 OR resultFAT.CFSpringAdjust.plate20mm[i] > 0 OR resultFAT.CFSpringAdjust.plate25mm[i] > 0 THEN
						EXIT;
					ELSIF i=2 THEN	// If all all values are 0 set the default amount of plates for this CF.
						IF resultFAT.machineSetup.cfSize=0 THEN // Default for small cf is 5 2.0mm plates on each spring.
							resultFAT.CFSpringAdjust.plate20mm[0] := 5;
							resultFAT.CFSpringAdjust.plate20mm[1] := 5;
							resultFAT.CFSpringAdjust.plate20mm[2] := 5;
						ELSE	// default for big cf is 7 2.0mm plates on each spring
							resultFAT.CFSpringAdjust.plate20mm[0] := 7;
							resultFAT.CFSpringAdjust.plate20mm[1] := 7;
							resultFAT.CFSpringAdjust.plate20mm[2] := 7;
						END_IF
					END_IF
								
				END_FOR
							
				state := 130;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 110;
			END_IF
				
		130:
			// CF spring adjustments

			IF this.hmi.cmd.startCalibration THEN
				this.hmi.cmd.startCalibration := FALSE;	
				// Need to use this bool to differentiate if it was a "FAT calibration" or a "normal calibration".
				gVibratorInterface[0].status.calibratingMode := TRUE;
				this.cfCali := TRUE;
			END_IF
			
			IF gVibratorInterface[0].status.calibrationResultsReady THEN
				gVibratorInterface[0].status.calibrationResultsReady := FALSE;
				this.hmi.cmd.startCalibration := FALSE;
			
				IF this.cfCali THEN
					// Take results from calibration and save in resultFAT
					resultFAT.CFSpringAdjust.ressFrequency := gVibratorInterface[0].status.calibrationResultFrequency;
					resultFAT.CFSpringAdjust.maxCurrent := gVibratorInterface[0].status.calibrationResultCurrent;
					resultFAT.CFSpringAdjust.currentOK := gVibratorInterface[0].status.calibrationResultCurrentOK;
					resultFAT.CFSpringAdjust.frequencyOK := gVibratorInterface[0].status.calibrationResultFrequencyOK;
				END_IF
				this.cfCali := FALSE;
			END_IF
			
			resultFAT.CFSpringAdjust.done := resultFAT.CFSpringAdjust.currentOK AND resultFAT.CFSpringAdjust.frequencyOK;	
			
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 140;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 120;
			END_IF
		
		140:
			// 'LF coils adjustment';	// might need to make more substates for CF and LF.
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				// Set default amount of plates if all plate values are set to 0 (means no user input).
				FOR i:=0 TO 1 DO
					IF resultFAT.LFSpringAdjust.plate08mm[i] > 0 OR resultFAT.LFSpringAdjust.plate09mm[i] > 0 OR resultFAT.LFSpringAdjust.plate15mm[i] > 0 OR resultFAT.LFSpringAdjust.plate20mm[i] > 0 OR resultFAT.LFSpringAdjust.plate25mm[i] > 0 THEN
						EXIT;
					ELSIF i=1 THEN	// If all all values are 0 set the default amount of plates for this CF.
						IF resultFAT.machineSetup.cfSize=0 THEN // Default for small cm
							resultFAT.LFSpringAdjust.plate08mm[0] := 2;
							resultFAT.LFSpringAdjust.plate08mm[1] := 1;
						ELSE	// default for big cm
							resultFAT.LFSpringAdjust.plate08mm[0] := 1;
							resultFAT.LFSpringAdjust.plate08mm[1] := 1;
							resultFAT.LFSpringAdjust.plate09mm[0] := 1;
						END_IF
					END_IF
								
				END_FOR
						
				state := 150;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 130;
			END_IF
		
		150:
			// LF calibration
			
			IF this.hmi.cmd.startCalibration THEN
				this.hmi.cmd.startCalibration := FALSE;
				// Need to use this bool to differentiate if it was a "FAT calibration" or a "normal calibration".
				gVibratorInterface[1].status.calibratingMode := TRUE;
				this.lfCali := TRUE;
			END_IF
			
			IF gVibratorInterface[1].status.calibrationResultsReady THEN
				gVibratorInterface[1].status.calibrationResultsReady := FALSE;
				this.hmi.cmd.startCalibration := FALSE;
				
				IF this.lfCali THEN
					// Take results from calibration and save in resultFAT
					resultFAT.LFSpringAdjust.ressFrequency := gVibratorInterface[1].status.calibrationResultFrequency;
					resultFAT.LFSpringAdjust.maxCurrent := gVibratorInterface[1].status.calibrationResultCurrent;
					resultFAT.LFSpringAdjust.currentOK := gVibratorInterface[1].status.calibrationResultCurrentOK;
					resultFAT.LFSpringAdjust.frequencyOK := gVibratorInterface[1].status.calibrationResultFrequencyOK;
					
					resultFAT.LFSpringAdjust.strResultForReport := REAL_TO_STRING(resultFAT.LFSpringAdjust.maxCurrent);
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,'A');
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,' / ');
					this.tmpString := REAL_TO_STRING(resultFAT.LFSpringAdjust.ressFrequency);
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,this.tmpString);
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,'Hz');
					
				END_IF
				this.lfCali := FALSE;
			END_IF
			
			resultFAT.LFSpringAdjust.done := resultFAT.LFSpringAdjust.currentOK AND resultFAT.LFSpringAdjust.frequencyOK;	
					
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 160;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 140;
			END_IF
		
		160:
			// 88h test
			this.testRunning := this.hmi.testRunning88h XOR this.hmi.testRunning12h;
			gBeltInterface.cmd.runManualTest := gVibratorInterface[0].cmd.runManualTest := gVibratorInterface[1].cmd.runManualTest := this.testRunning;
			
			IF this.hmi.testRunning88h AND this.hmi.testRunning12h THEN
				// Both can't run at the same time. Disable both if user tries to do this.
				this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
			ELSIF this.hmi.testRunning88h THEN
				
				// Start belt and vibrators
				gBeltInterface.parameter.speedManualTest := 400.0;
				gVibratorInterface[0].parameter.speedPctManualTest := SEL(this.config.timeElapsed88h > 43200,40.0,80.0); // First 12h use 40% rest of the time use 80% (43200s = 12hours)
				gVibratorInterface[1].parameter.speedPctManualTest := 100.0;
				
				// Calculate time
				this.config.timeElapsed88h := this.config.timeElapsed88h + CYCLE_TIME_seconds;
				this.config.timeLeft88h := 88.0-(this.config.timeElapsed88h/3600);
				this.config.timeLeft88h := getHourMinutsFromDecimal(this.config.timeLeft88h);
				
				IF this.config.timeLeft88h <= 0.0 THEN
					this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
					gConfig.cmd.save := TRUE;
					this.config.timeLeft88h := 0.0;
					resultFAT.longTest88h.done := TRUE;
				END_IF

			END_IF
		
			// Save to config every 10min
			this.TON_0.IN := this.testRunning;
			this.TON_0.PT := T#10m;
			this.TON_0();
	
			IF this.TON_0.Q THEN
				this.TON_0.IN := FALSE;
				this.TON_0();
		
				gConfig.cmd.save := TRUE;
			END_IF
		
			// If test not running set parameter to 0.
			IF NOT this.testRunning THEN
				gVibratorInterface[0].parameter.speedPctManualTest := 0.0;
				gVibratorInterface[1].parameter.speedPctManualTest := 0.0;
			END_IF
		
			IF this.hmi.cmd.arrowNextValue THEN			// go to next
				this.hmi.cmd.arrowNextValue := FALSE;	// reset
				state := 170;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 150;
			END_IF
		
		170:
			// 'After 72H test adjustments';
					
			resultFAT.after72hAdjustments.done := resultFAT.after72hAdjustments.approveCoverMounting AND resultFAT.after72hAdjustments.approveHabasitMounting AND resultFAT.after72hAdjustments.approvePacemakerMarking AND resultFAT.after72hAdjustments.approveRNAmarking;
					
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				state := 180;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 160;
			END_IF
		
		180:
			// Calibrate CF again after habasit (LF should not be needed since it has habasit on from the start)
		
			IF this.hmi.cmd.startCalibration THEN
				this.hmi.cmd.startCalibration := FALSE;
				this.cfCaliHabasit := TRUE; //save what kind of FAT cali which is running.
				gVibratorInterface[0].status.calibratingMode := TRUE;
			END_IF
			
			IF gVibratorInterface[0].status.calibrationResultsReady THEN
				gVibratorInterface[0].status.calibrationResultsReady := FALSE;
				
				IF this.cfCaliHabasit THEN
					// Take results from calibration and save in resultFAT
					resultFAT.CFCaliWithHabasit.ressFrequency := gVibratorInterface[0].status.calibrationResultFrequency;
					resultFAT.CFCaliWithHabasit.maxCurrent := gVibratorInterface[0].status.calibrationResultCurrent;
					resultFAT.CFCaliWithHabasit.currentOK := gVibratorInterface[0].status.calibrationResultCurrentOK;
					resultFAT.CFCaliWithHabasit.frequencyOK := gVibratorInterface[0].status.calibrationResultFrequencyOK;
					
					resultFAT.CFCaliWithHabasit.strResultForReport := REAL_TO_STRING(resultFAT.CFCaliWithHabasit.maxCurrent);
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,'A');
					resultFAT.CFCaliWithHabasit.strResultForReport := CONCAT(resultFAT.CFCaliWithHabasit.strResultForReport,' / ');
					this.tmpString := REAL_TO_STRING(resultFAT.CFCaliWithHabasit.ressFrequency);
					resultFAT.CFCaliWithHabasit.strResultForReport := CONCAT(resultFAT.CFCaliWithHabasit.strResultForReport,this.tmpString);
					resultFAT.LFSpringAdjust.strResultForReport := CONCAT(resultFAT.LFSpringAdjust.strResultForReport,'Hz');
					
				END_IF
				this.cfCaliHabasit := FALSE;
			END_IF
			
			resultFAT.CFCaliWithHabasit.done := resultFAT.CFCaliWithHabasit.currentOK AND resultFAT.CFCaliWithHabasit.frequencyOK;
			
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				state := 190;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 170;
			END_IF
		
		190:
			// 12h test
			
			// 88h test and 12h test
			this.testRunning := this.hmi.testRunning88h XOR this.hmi.testRunning12h;
			gBeltInterface.cmd.runManualTest := gVibratorInterface[0].cmd.runManualTest := gVibratorInterface[1].cmd.runManualTest := this.testRunning;
			
			IF this.hmi.testRunning88h AND this.hmi.testRunning12h THEN
				// Both can't run at the same time. Disable both if user tries to do this.
				this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
			ELSIF this.hmi.testRunning12h THEN
							
				// Start belt and vibrators
				gBeltInterface.parameter.speedManualTest := 400.0;
				gVibratorInterface[0].parameter.speedPctManualTest := 80.0; // First 12h use 40% rest of the time use 80% (43200s = 12hours)
				gVibratorInterface[1].parameter.speedPctManualTest := 100.0;
				
				// Calculate time
				this.config.timeElapsed12h := this.config.timeElapsed12h + CYCLE_TIME_seconds;
				this.config.timeLeft12h := 12.0-(this.config.timeElapsed12h/3600);
				this.config.timeLeft12h := getHourMinutsFromDecimal(this.config.timeLeft12h);
				
				IF this.config.timeLeft12h <= 0.0 THEN
					this.hmi.testRunning12h := this.hmi.testRunning12h := FALSE;
					gConfig.cmd.save := TRUE;
					this.config.timeLeft12h := 0.0;
					resultFAT.longTest12h.done := TRUE;
				END_IF
			END_IF
		
			// Save to config every 10min
			this.TON_0.IN := this.testRunning;
			this.TON_0.PT := T#10m;
			this.TON_0();
	
			IF this.TON_0.Q THEN
				this.TON_0.IN := FALSE;
				this.TON_0();
		
				gConfig.cmd.save := TRUE;
			END_IF
		
			// If test not running set parameter to 0.
			IF NOT this.testRunning THEN
				gVibratorInterface[0].parameter.speedPctManualTest := 0.0;
				gVibratorInterface[1].parameter.speedPctManualTest := 0.0;
			END_IF
			
			
			
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				state := 200;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 180;
			END_IF
		
			
		200:
			// 'Visual inspection of CM marking';
					
			//	NO SAP LABEL -> resultFAT.visualInspection.markingArr[0] 
			//	HAS SAP LABEL -> resultFAT.visualInspection.markingArr[12]
					
						
			FOR i:=1 TO 11 DO	// all machine markings must be approved before the step is done.
				IF NOT resultFAT.visualInspection.markingArr[i] THEN
					resultFAT.visualInspection.done := FALSE;
					EXIT;
				ELSIF i=11 THEN
					resultFAT.visualInspection.done := TRUE;
							
				END_IF
			END_FOR
			IF resultFAT.visualInspection.done THEN
				resultFAT.visualInspection.done :=  resultFAT.visualInspection.markingArr[12] XOR resultFAT.visualInspection.markingArr[0];
			END_IF
					
			this.hmi.cmd.enableArrowNext := resultFAT.visualInspection.done;
					

			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE;	// reset.
				state := 210;
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 190;
			END_IF
			
			
			
			
		
		210:
			// Report and USB transfer (put them together in 1)
		
			IF this.hmi.status.reportCreationOK AND gMachineInterface.status.configSavedToT50 THEN
				resultFAT.FATdone := TRUE;		// FAT is done!
			END_IF
		
			generateReportAction;
			usbTransferAction;
		
			
			IF this.hmi.cmd.arrowNextValue THEN
				this.hmi.cmd.arrowNextValue := FALSE; // last page cant change state
			ELSIF this.hmi.cmd.arrowBackValue THEN
				this.hmi.cmd.arrowBackValue := FALSE;
				state := 200;
			END_IF
			
			
			
			
		
		
			
		
			
		(*
		
		10:
			IF gFile.status.ready AND (gConfig.status.saved OR gConfig.status.loaded)  THEN
				this.config.timeLeft88h := 88.0-(this.config.timeElapsed88h/3600);
				this.config.timeLeft88h := getHourMinutsFromDecimal(this.config.timeLeft88h);
				this.config.timeLeft12h := 12.0-(this.config.timeElapsed12h/3600);
				this.config.timeLeft12h := getHourMinutsFromDecimal(this.config.timeLeft12h);
				
				state := 20;
			END_IF
		
		20:
			// 88h test and 12h test
			this.testRunning := this.hmi.testRunning88h XOR this.hmi.testRunning12h;
			gBeltInterface.cmd.runManualTest := gVibratorInterface[0].cmd.runManualTest := gVibratorInterface[1].cmd.runManualTest := this.testRunning;
			
			IF this.hmi.testRunning88h AND this.hmi.testRunning12h THEN
				// Both can't run at the same time. Disable both if user tries to do this.
				this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
			ELSIF this.hmi.testRunning88h THEN
				
				// Start belt and vibrators
				gBeltInterface.parameter.speedManualTest := 400.0;
				gVibratorInterface[0].parameter.speedPctManualTest := SEL(this.config.timeElapsed88h > 43200,40.0,80.0); // First 12h use 40% rest of the time use 80% (43200s = 12hours)
				gVibratorInterface[1].parameter.speedPctManualTest := 100.0;
				
				// Calculate time
				this.config.timeElapsed88h := this.config.timeElapsed88h + CYCLE_TIME_seconds;
				this.config.timeLeft88h := 88.0-(this.config.timeElapsed88h/3600);
				this.config.timeLeft88h := getHourMinutsFromDecimal(this.config.timeLeft88h);
				
				IF this.config.timeLeft88h <= 0.0 THEN
					this.hmi.testRunning88h := this.hmi.testRunning12h := FALSE;
					gConfig.cmd.save := TRUE;
					this.config.timeLeft88h := 0.0;
				END_IF
			ELSIF this.hmi.testRunning12h THEN
							
				// Start belt and vibrators
				gBeltInterface.parameter.speedManualTest := 400.0;
				gVibratorInterface[0].parameter.speedPctManualTest := 80.0; // First 12h use 40% rest of the time use 80% (43200s = 12hours)
				gVibratorInterface[1].parameter.speedPctManualTest := 100.0;
				
				// Calculate time
				this.config.timeElapsed12h := this.config.timeElapsed12h + CYCLE_TIME_seconds;
				this.config.timeLeft12h := 12.0-(this.config.timeElapsed12h/3600);
				this.config.timeLeft12h := getHourMinutsFromDecimal(this.config.timeLeft12h);
				
				IF this.config.timeLeft12h <= 0.0 THEN
					this.hmi.testRunning12h := this.hmi.testRunning12h := FALSE;
					gConfig.cmd.save := TRUE;
					this.config.timeLeft12h := 0.0;
				END_IF
			END_IF
		
			// Save to config every 10min
			this.TON_0.IN := this.testRunning;
			this.TON_0.PT := T#10m;
			this.TON_0();
	
			IF this.TON_0.Q THEN
				this.TON_0.IN := FALSE;
				this.TON_0();
		
				gConfig.cmd.save := TRUE;
			END_IF
		
			// If test not running set parameter to 0.
			IF NOT this.testRunning THEN
				gVibratorInterface[0].parameter.speedPctManualTest := 0.0;
				gVibratorInterface[1].parameter.speedPctManualTest := 0.0;
			END_IF
		*)
	END_CASE
	
	IF state > 5 THEN
		stateRetain := state;
	END_IF
	
	IF state > 10 THEN
		// just always allow navigation if we are after state 10 (control of resistance)
		this.hmi.cmd.enableArrowNext := state <> 210; // Disable if last page which is 210 (cant go next on the last page)
	END_IF
	
	MpRecipeRegPar_Config.MpLink := ADR(mpRecipe);
	MpRecipeRegPar_Config.PVName := ADR(this.configName);
	MpRecipeRegPar_Config.Category := ADR('config');
	MpRecipeRegPar_Config();

	resultsFATfileHandling;
	
END_PROGRAM

PROGRAM _EXIT
	MpRecipeRegPar_Config.Enable := FALSE;
	MpRecipeRegPar_Config();
	this.MpRecipeRegPar_result.Enable := FALSE;
	this.MpRecipeRegPar_result();
	this.MpReportCore_0.Enable := FALSE;
	this.MpReportCore_0();
END_PROGRAM

