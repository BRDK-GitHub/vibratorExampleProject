
PROGRAM _INIT

	RTInfo_0(enable := TRUE);
	 
	lampIOLink.setOwnColor := TRUE;
	lampIOLink.setBrightness := TRUE;
END_PROGRAM

PROGRAM _CYCLIC

	// call rt info to get cycle time of current task
	IF RTInfo_0.status <> ERR_OK THEN
		RTInfo_0();
	END_IF
	
	// change the flash for every flash time elapsed
	flash.elapsedTime := flash.elapsedTime + RTInfo_0.cycle_time;
	IF NOT flash.on THEN
		IF flash.elapsedTime >= (config.flash.offTime*1000) THEN
			flash.elapsedTime 	:= 0;
			flash.on 			:= TRUE;
		END_IF
	ELSE
		IF flash.elapsedTime >= (config.flash.onTime*1000) THEN
			flash.elapsedTime 	:= 0;
			flash.on 			:= FALSE;
		END_IF
	END_IF
	
	// change the blink for every flash time elapsed
	blink.elapsedTime := blink.elapsedTime + RTInfo_0.cycle_time;
	IF NOT blink.on THEN
		IF blink.elapsedTime >= (config.blink.offTime*1000) THEN
			blink.elapsedTime 	:= 0;
			blink.on 			:= TRUE;
		END_IF
	ELSE
		IF blink.elapsedTime >= (config.blink.onTime*1000) THEN
			blink.elapsedTime 	:= 0;
			blink.on 			:= FALSE;
		END_IF
	END_IF
	
	(*****************************
	
	IO HANDLING
	
	*****************************)
	

	lamp.timeoutActive := FALSE;		// tmp set it to false
	// based on the flash or the color sets the right output to the lamp io
	CASE lamp.flash OF
	
		FLASH_PERMANENT:
			lamp.io.output := DINT_TO_USINT(lamp.color);	
	
		FLASH_FLASH:
			IF NOT flash.on THEN	
				lamp.io.output := DINT_TO_USINT(COLOR_OFF);
			ELSE
				lamp.io.output := DINT_TO_USINT(lamp.color);
			END_IF
			
		FLASH_BLINK:
			IF NOT blink.on THEN	
				lamp.io.output := DINT_TO_USINT(COLOR_OFF);
			ELSE
				lamp.io.output := DINT_TO_USINT(lamp.color);
			END_IF
	
	END_CASE

	IF lamp.color <> COLOR_OFF THEN
		lamp.timeoutActive := TRUE;
	END_IF
	
	// store the actual color and flash in the status structure which is remanent
	statusString.lamp.color 	:= lamp.color;
	statusString.lamp.flash		:= lamp.flash;

	
	
	
	
	
	(*****************************
	
	IO-LINK PARAMETERS
	
	*****************************)
	
	IF gConfig.status.loaded THEN
	
		CASE lampIOLink.state OF
			
				0:	// waiting for command
					lampIOLink.elapsedTime := lampIOLink.elapsedTime + RTInfo_0.cycle_time;
					IF lampIOLink.setBrightness THEN
						IF config.brightness.green <> 0 OR config.brightness.red <> 0 OR config.brightness.blue <> 0 THEN
							lampIOLink.setBrightness 				:= FALSE;
							lampIOLink.ioLinkWrite_0(enable := FALSE);
							lampIOLink.data[0] 					:= LIMIT(0,UINT_TO_USINT((USINT_TO_UINT(config.brightness.red)*127)/100),127);	// 100% = 127
							lampIOLink.data[1] 					:= LIMIT(0,UINT_TO_USINT((USINT_TO_UINT(config.brightness.green)*127)/100),127);	// 100% = 127
							lampIOLink.data[2] 					:= LIMIT(0,UINT_TO_USINT((USINT_TO_UINT(config.brightness.blue)*127)/100),127);	// 100% = 127
							lampIOLink.ioLinkWrite_0.index 		:= 16#51;			// set brightness
							lampIOLink.ioLinkWrite_0.subIndex		:= 1;
							lampIOLink.ioLinkWrite_0.datatype		:= ioLinkTYPE_USINT;
							lampIOLink.ioLinkWrite_0.pData		:= ADR(lampIOLink.data[0]);
							lampIOLink.ioLinkWrite_0.dataLen		:= SIZEOF(lampIOLink.data[0]);
							lampIOLink.ioLinkWrite_0.pDeviceName 	:= ADR(lampIOLink.deviceName);
							lampIOLink.node						:= 2;
							lampIOLink.subIndex					:= 1;
							lampIOLink.stringNo					:= 0; // 0 = G01, 1 = G02
						
						//							brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));
						//							brdkStrAppendUdintToA(lampIOLink.node,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
						//							brdkStrCat(ADR(lampIOLink.deviceName),ADR('.IF'));
						//							brdkStrAppendUdintToA(cIdx+1,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
							lampIOLink.deviceName := 'IF6.ST1.IF2';	
						
							lampIOLink.ioLinkWrite_0.enable		:= TRUE;
							lampIOLink.state						:= 10;
						END_IF							
					ELSIF lampIOLink.setOwnColor THEN
						IF config.ownColor.green <> 0 OR config.ownColor.red <> 0 OR config.ownColor.blue <> 0 THEN
							lampIOLink.setOwnColor 				:= FALSE;
							lampIOLink.ioLinkWrite_0(enable := FALSE);
							lampIOLink.data[0]					:= config.ownColor.red;
							lampIOLink.data[1]					:= config.ownColor.green;
							lampIOLink.data[2]					:= config.ownColor.blue;
							lampIOLink.ioLinkWrite_0(enable := FALSE);
							lampIOLink.ioLinkWrite_0.index 		:= 16#FC;				// set own color
							lampIOLink.ioLinkWrite_0.subIndex		:= 1;
							lampIOLink.ioLinkWrite_0.datatype		:= ioLinkTYPE_USINT;
							lampIOLink.ioLinkWrite_0.pData		:= ADR(lampIOLink.data[0]);
							lampIOLink.ioLinkWrite_0.dataLen		:= SIZEOF(lampIOLink.data[0]);
							lampIOLink.ioLinkWrite_0.pDeviceName 	:= ADR(lampIOLink.deviceName);
							lampIOLink.node						:= 2;
							lampIOLink.subIndex					:= 1;
							lampIOLink.stringNo					:= 0; // 0 = G01, 1 = G02
//							brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));
//							brdkStrAppendUdintToA(lampIOLink.node,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
//							brdkStrCat(ADR(lampIOLink.deviceName),ADR('.IF'));
//							brdkStrAppendUdintToA(cIdx+1,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
							lampIOLink.deviceName := 'IF6.ST1.IF2';		
							lampIOLink.ioLinkWrite_0.enable		:= TRUE;
							lampIOLink.state						:= 10;
						END_IF							
					ELSIF lampIOLink.elapsedTime >= 60000000 THEN	// read temperature only every minute
						lampIOLink.ioLinkRead_0(enable := FALSE);
						lampIOLink.ioLinkRead_0.index 		:= 16#59;				// read temperature
						lampIOLink.ioLinkRead_0.subIndex		:= 1;
						lampIOLink.ioLinkRead_0.datatype		:= ioLinkTYPE_SINT;
						lampIOLink.ioLinkRead_0.pData			:= ADR(lampIOLink.temperature);
						lampIOLink.ioLinkRead_0.dataLen		:= SIZEOF(lampIOLink.temperature);
						lampIOLink.ioLinkRead_0.pDeviceName 	:= ADR(lampIOLink.deviceName);
						lampIOLink.node						:= 2;
						lampIOLink.stringNo					:= 0; // 0 = G01, 1 = G02
//						brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));
//						brdkStrAppendUdintToA(lampIOLink.node,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
//						brdkStrCat(ADR(lampIOLink.deviceName),ADR('.IF'));
//						brdkStrAppendUdintToA(cIdx+1,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
						lampIOLink.deviceName := 'IF6.ST1.IF2';	
						lampIOLink.ioLinkRead_0.enable		:= TRUE;
						lampIOLink.temperature				:= 0;
						lampIOLink.state						:= 20;
					END_IF
					
				10: // wait for ioLinkWrite_0 status ok
					lampIOLink.ioLinkWrite_0();
					
//					IF lampIOLink[2].node = 1 THEN
//						lampIOLink[2].node := lampIOLink[2].node;
//					END_IF
					
					CASE lampIOLink.ioLinkWrite_0.status OF
					
						ERR_OK,ioLinkERR_COMMUNICATION_DEVICE,ioLinkERR_INVALID_MASTER,ioLinkERR_DEVICE_DRIVER:
							lampIOLink.ioLinkWrite_0(enable := FALSE);
							lampIOLink.ioLinkWrite_0.enable		:= TRUE;
							lampIOLink.elapsedTime 	:= 0; // ADDED
							lampIOLink.state := 0; // ADDED
						(*
							lampIOLink.subIndex := lampIOLink.subIndex + 1;
							IF lampIOLink.subIndex > 3 THEN
								lampIOLink.subIndex 	:= 1;
								lampIOLink.node		:= lampIOLink.node + 1;
								
								CASE lampIOLink.stringNo OF
								
									0: // G01 - IF6.ST2 -> IF6.ST7
										IF NOT di_G04_10_08Present THEN // SSPP line or DSPP line
											IF lampIOLink.node > 7 THEN
												IF NOT di_G02Present THEN	// SSPP line - only one string
													lampIOLink.state := 0;
												ELSE
													lampIOLink.node						:= 1;
													lampIOLink.subIndex					:= 1;
													lampIOLink.stringNo					:= 1; // 0 = G01, 1 = G02
													brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
												END_IF
											ELSE
												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));		
											END_IF
										ELSE	// PP99 line
											IF lampIOLink.node > 9 THEN
												lampIOLink.node						:= 1;
												lampIOLink.subIndex					:= 1;
												lampIOLink.stringNo					:= 1; // 0 = G01, 1 = G02
												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
											ELSE
												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));		
											END_IF
										END_IF
										
									1: // G02 - SS1.IF1.ST1 -> SS1.IF1.ST6
										IF NOT di_G04_10_08Present THEN // DSPP line
											IF lampIOLink.node > 6 THEN
												lampIOLink.elapsedTime 	:= 0;
												lampIOLink.state 			:= 0;
											ELSE
												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
											END_IF
										ELSE	// PP99 line
											IF lampIOLink.node > 8 THEN
												lampIOLink.elapsedTime 	:= 0;
												lampIOLink.state 			:= 0;
											ELSE
												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
											END_IF
										END_IF
								
								END_CASE
								
								IF lampIOLink.state > 0 THEN
									brdkStrAppendUdintToA(lampIOLink.node,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
									brdkStrCat(ADR(lampIOLink.deviceName),ADR('.IF'));
									brdkStrAppendUdintToA(cIdx+1,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
								END_IF
								
							END_IF
							*)
							lampIOLink.ioLinkWrite_0.subIndex 	:= lampIOLink.subIndex;
							lampIOLink.ioLinkWrite_0.pData		:= ADR(lampIOLink.data[lampIOLink.ioLinkWrite_0.subIndex-1]);
							
										
					END_CASE
					
				20:	// wait for ioLinkRead_0 status ok
					lampIOLink.ioLinkRead_0();
					CASE lampIOLink.ioLinkRead_0.status OF
					
						ERR_OK,ioLinkERR_COMMUNICATION_DEVICE,ioLinkERR_INVALID_MASTER,ioLinkERR_DEVICE_DRIVER:
							lampIOLink.ioLinkRead_0(enable := FALSE);
							lampIOLink.ioLinkRead_0.enable		:= TRUE;
							lampIOLink.elapsedTime 	:= 0;
							lampIOLink.state 			:= 0;
						
//							setTemperature; // call action
//							lampIOLink.temperature := 0;
//							lampIOLink.node		:= lampIOLink.node + 1;
//									
//							CASE lampIOLink.stringNo OF
//								
//								0: // G01 - IF6.ST2 -> IF6.ST7
//									IF NOT di_G04_10_08Present THEN // SSPP line or DSPP line
//										IF lampIOLink.node > 7 THEN
//											IF NOT di_G02Present THEN	// SSPP line - only one string
//												lampIOLink.elapsedTime 	:= 0;
//												lampIOLink.state 			:= 0;
//											ELSE
//												lampIOLink.node						:= 1;
//												lampIOLink.stringNo					:= 1; // 0 = G01, 1 = G02
//												brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
//											END_IF
//										ELSE
//											brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));		
//										END_IF
//									ELSE	// PP99 line
//										IF lampIOLink.node > 9 THEN
//											lampIOLink.node						:= 1;
//											lampIOLink.stringNo					:= 1; // 0 = G01, 1 = G02
//											brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
//										ELSE
//											brdkStrCpy(ADR(lampIOLink.deviceName),ADR('IF6.ST'));		
//										END_IF
//									END_IF
//									
//								1: // G02 - SS1.IF1.ST1 -> SS1.IF1.ST6
//									IF NOT di_G04_10_08Present THEN // DSPP line
//										IF lampIOLink.node > 6 THEN
//											lampIOLink.elapsedTime 	:= 0;
//											lampIOLink.state 			:= 0;
//										ELSE
//											brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
//										END_IF
//									ELSE // PP99 line
//										IF lampIOLink.node > 8 THEN
//											lampIOLink.elapsedTime 	:= 0;
//											lampIOLink.state 			:= 0;
//										ELSE
//											brdkStrCpy(ADR(lampIOLink.deviceName),ADR('SS1.IF1.ST'));
//										END_IF
//									END_IF
//							
//							END_CASE
//								
//							IF lampIOLink.state > 0 THEN
//								brdkStrAppendUdintToA(lampIOLink.node,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
//								brdkStrCat(ADR(lampIOLink.deviceName),ADR('.IF'));
//								brdkStrAppendUdintToA(cIdx+1,ADR(lampIOLink.deviceName),BRDK_STR_CONVERT_DECIMAL,-1);
//							END_IF
//						
					END_CASE
							
			END_CASE
		

	END_IF
	
//	// copy status vlaue to tmp variable for multiple outputs
//	tmpLamp1_1 := plcString[1].lamp[1].io.status;
//	tmpLamp1_4 := plcString[1].lamp[4].io.status;
//	
//	(*****************************
//	
//	STATUS
//	
//	*****************************)
//	// brightness
//	Lamp.Status.Configuration.Brightness.Blue 	:= config.brightness.blue;
//	Lamp.Status.Configuration.Brightness.Green 	:= config.brightness.green;
//	Lamp.Status.Configuration.Brightness.Red 	:= config.brightness.red;
//
//	// own color
//	Lamp.Status.Configuration.OwnColor.Blue 	:= config.ownColor.blue;
//	Lamp.Status.Configuration.OwnColor.Green 	:= config.ownColor.green;
//	Lamp.Status.Configuration.OwnColor.Red 		:= config.ownColor.red;
//	
//	// health check
//	Lamp.Status.Configuration.HealthCheck.ColorTimeout := config.healthCheck.timeout;
//	FOR sIdx := 0 TO 6 DO
//		Lamp.Status.Configuration.HealthCheck.ColorSequence[sIdx].Color := config.healthCheck.colorSequence[sIdx];
//	END_FOR
//	
//	// test position
//	Lamp.Status.Configuration.TestPosition.Color := config.testPosition.color;
//	Lamp.Status.Configuration.TestPosition.Timeout := config.testPosition.timeout;
//	
//	// flashing
//	Lamp.Status.Configuration.Flashing.Permanent.Timeout.Time 	:= config.permanent.timeout;
//	Lamp.Status.Configuration.Flashing.Flash.Timeout.Time		:= config.flash.timeout;
//	Lamp.Status.Configuration.Flashing.Flash.TimeOn.Time		:= config.flash.onTime;
//	Lamp.Status.Configuration.Flashing.Flash.TimeOff.Time		:= config.flash.offTime;
//	Lamp.Status.Configuration.Flashing.Blink.Repeat				:= config.blink.repeat;
//	Lamp.Status.Configuration.Flashing.Blink.TimeOn.Time		:= config.blink.onTime;
//	Lamp.Status.Configuration.Flashing.Blink.TimeOff.Time		:= config.blink.offTime;
//	
//	gStatus;
//
//	MpRecipeRegPar_Config.MpLink 	:= ADR(gRecipeXmlConfig);
//	MpRecipeRegPar_Config.Enable 	:= TRUE;
//	MpRecipeRegPar_Config.PVName 	:= ADR('::lampCtrl:config');
//	MpRecipeRegPar_Config.Category 	:= ADR('config');
//	MpRecipeRegPar_Config();
	
END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

