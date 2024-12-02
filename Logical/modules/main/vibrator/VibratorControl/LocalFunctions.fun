
{REDUND_ERROR} FUNCTION_BLOCK Accelerometer (*TODO: Add your comment here*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Enable : {REDUND_UNREPLICABLE} BOOL;
		VibratorType : USINT;
		MachineSize : USINT; (*0=Small CM, 1=Big CM*)
	END_VAR
	VAR_OUTPUT
		ModuleOkBusCtrl : BOOL; (*If using buscontroller*)
		ModuleOkCalibrationTool : BOOL;
		Percent : {REDUND_UNREPLICABLE} REAL;
		Raw : {REDUND_UNREPLICABLE} REAL;
		ai_rawValue : REAL;
		ai_peakValue : REAL;
		ai_rawValueBusCtrl : REAL;
		ai_peakValueBusCtrl : REAL;
		do_enableSampling : BOOL := TRUE;
		ao_samples : UINT := 103;
		isBigCF : BOOL;
	END_VAR
END_FUNCTION_BLOCK

FUNCTION CheckCalibrationFrequency : calibrationResult_enum
	VAR_INPUT
		ressFrequency : REAL;
		MachineSize : USINT;
		VibratorType : USINT;
	END_VAR
END_FUNCTION
