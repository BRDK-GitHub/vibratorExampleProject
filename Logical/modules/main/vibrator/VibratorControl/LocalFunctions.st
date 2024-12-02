
(* TODO: Add your comment here *)
FUNCTION_BLOCK Accelerometer
	
	IF Enable THEN
		IF ModuleOkBusCtrl THEN
			ai_peakValue := ai_peakValueBusCtrl;
			ai_rawValue := ai_rawValueBusCtrl;
			do_enableSampling := TRUE;
			ao_samples := SEL(MachineSize=1,53,103);		// Big bowl cf is half the frequency and need to use more samples in the accelerometer module.
		END_IF
		
		IF VibratorType=0 THEN
			Percent := SEL(MachineSize=0,(ai_peakValue-722.22)/73.378,(ai_peakValue-1300)/150);
		ELSE
			Percent := SEL(MachineSize=0,(ai_peakValue-693.33)/81.467,(ai_peakValue-317.78)/98.222); 			// 10%=1300 , 100%=10140
		END_IF
		Raw := ai_rawValue;
		isBigCF := MachineSize=1;
	ELSE
		Percent := 0.0;
		Raw := 0.0;
	END_IF
	
	
	// Small CF:		10%=2756 , 100%=17420
	// Small LF:		10%=1300 , 100%=10140
	// Big CF:			10%=1456 , 100%=8060
	// Big LF: 			10%=1508 , 100%=8840
	
END_FUNCTION_BLOCK

FUNCTION CheckCalibrationFrequency

	IF VibratorType=0 THEN
		//CF
		CASE MachineSize OF
			
			0:
				// small CF
				IF ressFrequency < 15 THEN
					CheckCalibrationFrequency := CALIBRATION_NOT_DONE;
				ELSIF ressFrequency < 96.0 OR ressFrequency > 102 THEN
					CheckCalibrationFrequency := SMALL_CF_CALIBRATION_NOK;
				ELSE
					CheckCalibrationFrequency := SMALL_CF_CALIBRATION_OK;
				END_IF
				
			1:
				// big CF
				IF ressFrequency < 15 THEN
					CheckCalibrationFrequency := CALIBRATION_NOT_DONE;
				ELSIF ressFrequency < 47.0 OR ressFrequency > 52.0 THEN
					CheckCalibrationFrequency := BIG_CF_CALIBRATION_NOK;
				ELSE
					CheckCalibrationFrequency := BIG_CF_CALIBRATION_OK;
				END_IF
			
		END_CASE
		
	ELSE
		//LF
		IF ressFrequency < 15 THEN
			CheckCalibrationFrequency := CALIBRATION_NOT_DONE;
		ELSIF ressFrequency < 96.0 OR ressFrequency > 106 THEN
			CheckCalibrationFrequency := LF_CALIBRATION_NOK;
		ELSE
			CheckCalibrationFrequency := LF_CALIBRATION_OK;
		END_IF
	END_IF
	
	
END_FUNCTION