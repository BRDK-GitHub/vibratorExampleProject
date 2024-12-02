
TYPE
	local_typ : 	STRUCT 
		configName : STRING[80];
		TON_0 : TON;
		config : config_FAT_typ;
		hmi : local_hmi_typ;
		testRunning : BOOL;
		MpRecipeXml_0 : MpRecipeXml;
		MpRecipeRegPar_result : MpRecipeRegPar;
		ton_chekForChanges : TON;
		resultName : STRING[80];
		resultsFATLoaded : BOOL;
		tmpString : STRING[60];
		oldLREAL : LREAL;
		maxPlusMinusVoltage : REAL := 0.1;
		timeElapsed : UDINT;
		cfCali : BOOL;
		lfCali : BOOL;
		cfCaliHabasit : BOOL;
		hmiUsbPresent : BOOL;
		hmiUsbNotPresent : BOOL;
		fileNameDest : STRING[80];
		folderNameUSB : STRING[80];
		fileNameSrc : STRING[80];
		fileCopy_0 : FileCopy;
		actServerCardIpAddress : STRING[15];
		ftpParamPLC : STRING[80];
		devLinkPLC_0 : DevLink;
		dirPathPLC : STRING[80];
		dirPathUSB : STRING[80];
		dirCopy_0 : DirCopy;
		currentName : STRING[80];
		newName : STRING[80];
		FileRename_0 : FileRename;
		previousState : UINT;
		fileToBeDeleted : STRING[80];
		FileDelete_0 : FileDelete;
		MpReportCore_0 : MpReportCore;
	END_STRUCT;
	local_hmi_typ : 	STRUCT 
		testRunning88h : BOOL;
		testRunning12h : BOOL;
		cmd : hmi_cmd_typ;
		status : hmi_status_typ;
		TransferedToUsb : BOOL;
		yearIdx : UINT;
		monthIdx : UINT;
		dayIdx : UINT;
		dateString : STRING[40];
		date : DATE;
	END_STRUCT;
	hmi_cmd_typ : 	STRUCT 
		startFAT : BOOL;
		arrowNextValue : BOOL;
		arrowBackValue : BOOL;
		enableMenuNavigation : BOOL;
		enableArrowNext : BOOL;
		smallCfToggleButton : BOOL;
		bigCfToggleButton : BOOL;
		leftDirectionOfRotation : BOOL;
		rightDirectionOfRotation : BOOL;
		crossmarkV2 : USINT;
		crossmarkV1 : USINT;
		startCapconTest2 : BOOL;
		doLevelSensorTest : BOOL;
		setLevelSensorLow : BOOL;
		setLevelSensorMedium : BOOL;
		setLevelSensorHigh : BOOL;
		doPhotoSensorTest : BOOL; (*User wants to start automatic test of the photo sensor.*)
		doPhotoSensorTestNoBelt : BOOL;
		doBfFlapTest : BOOL;
		startLightTowerTest : BOOL;
		doWingTestManuel : BOOL;
		startCalibration : BOOL;
		transferToUsb : BOOL;
		createReports : BOOL;
		transferConfigToFT50 : BOOL;
	END_STRUCT;
	hmi_status_typ : 	STRUCT 
		additionalInfo : hmi_status_additionalInfo_typ;
		maxRawSignal : REAL;
		styleToggleInputHigh : BOOL;
		styleToggleInputMedium : BOOL;
		styleToggleInputLow : BOOL;
		photoSensorTestText : USINT;
		isBigMachine : BOOL;
		isSmallMachine : BOOL;
		reportCreationOK : BOOL;
	END_STRUCT;
	hmi_status_additionalInfo_typ : 	STRUCT 
		typeNo : UDINT;
		serialNo : UDINT;
		rnoNo : LREAL;
		topSerialNo : UDINT;
		IRTHno : LREAL;
	END_STRUCT;
	config_FAT_typ : 	STRUCT 
		timeElapsed88h : REAL;
		timeLeft88h : REAL := 88.0;
		timeElapsed12h : REAL;
		timeLeft12h : REAL := 12.0;
		approveBoltsAreTight : BOOL;
		approveCfHasHabasit : BOOL;
	END_STRUCT;
	permanent_typ : 	STRUCT 
		cmState : UINT;
	END_STRUCT;
END_TYPE

(*FAT result structures. Each test point have 1 structs to save results from the test. These are saved on user partition*)

TYPE
	resultFAT_typ : 	STRUCT 
		initialGroundMeas : resultFAT_initialGroundMeas_typ;
		machineSetup : resultFAT_machineSetup_typ;
		visualInspection : resultFAT_visualInspection_typ;
		additionalInfo : resultFAT_additionalInfo_typ;
		capconMeasurement : resultFAT_capconMeasurement_typ;
		capconTest : resultFAT_capconTests_typ;
		levelSensorTest : resultFAT_levelSensorTest_typ;
		photoSensorAdjust : resultFAT_photoSensorAdjust_typ;
		photoSensorTest : resultFAT_photoSensorTest_typ;
		bfTestIO : resultFAT_bfTestIO_typ;
		wingTestIO : resultFAT_wingTestIO_typ;
		CFCoilAdjust : resultFAT_CFCoilAdjust_typ;
		CFSpringAdjust : resultFAT_CFSpringAdjust_typ;
		LFCoilAdjust : resultFAT_LFCoildAdjust_typ;
		LFSpringAdjust : resultFAT_LFSpringAdjust_typ;
		longTest88h : resultFAT_88hTest;
		after72hAdjustments : resultFAT_after72hAdjustments;
		CFCaliWithHabasit : resultFAT_CFCaliWithHabasit;
		longTest12h : resultFAT_12hTest;
		resistanceMeas2 : resultFAT_resistanceMeas2_typ;
		internal : internal_typ;
		FATdone : BOOL; (*If all points are done and report has been generated this will be true and FAT is finished.*)
	END_STRUCT;
	resultFAT_initialGroundMeas_typ : 	STRUCT 
		done : BOOL;
		measurementValue : REAL;
		firstMeasurementDone : BOOL;
	END_STRUCT;
	resultFAT_machineSetup_typ : 	STRUCT 
		done : BOOL;
		cfSize : UINT; (*0 is small, 1 is big*)
		strCfSize : STRING[40];
		strMachineType : STRING[40];
		strMaxSpecsCF : STRING[40]; (*String with current/voltage specs depending of cfSize*)
		strLinearizationAccValuesCF : STRING[40];
		strLinearizationAccValuesLF : STRING[40];
		strIsItALeftMachine : STRING[1]; (*X if yes*)
		strIsItARightMachine : STRING[1]; (*X if yes*)
		machineType : USINT; (*0 is left, 1 is right*)
	END_STRUCT;
	resultFAT_additionalInfo_typ : 	STRUCT 
		done : BOOL;
		typeNo : STRING[40];
		serialNo : STRING[40];
		typeNoAndSerialNo : STRING[40];
		vibratorUnitType : STRING[40];
		topUnitType : STRING[40];
		rnaProductNo : STRING[40];
		weightOfCf : STRING[40];
		topSerialNo : STRING[40];
		IRTHno : STRING[40];
	END_STRUCT;
	resultFAT_capconMeasurement_typ : 	STRUCT 
		done : BOOL;
		V1 : REAL;
		V2 : REAL;
	END_STRUCT;
	resultFAT_capconTests_typ : 	STRUCT 
		done : BOOL;
		signalTest1 : BOOL; (*Test to see if hw signal is comming from capcon to PLC.*)
		signalTest2 : BOOL; (*Test to see if the speed signal is too high. If it is the supply for capcon might be wrong set.*)
	END_STRUCT;
	resultFAT_levelSensorTest_typ : 	STRUCT 
		done : BOOL;
		transmitterHighOK : BOOL;
		transmitterMediumOK : BOOL;
		transmitterLowOK : BOOL;
		receiverOK : BOOL;
		operatorApproveHigh : BOOL;
		operatorApproveMedium : BOOL;
		operatorApproveLow : BOOL;
	END_STRUCT;
	resultFAT_photoSensorAdjust_typ : 	STRUCT 
		done : BOOL;
	END_STRUCT;
	resultFAT_photoSensorTest_typ : 	STRUCT 
		done : BOOL;
		testWithNoBelt : BOOL;
		testWithBelt : BOOL;
	END_STRUCT;
	resultFAT_bfTestIO_typ : 	STRUCT 
		done : BOOL;
		approveMainsVoltage : BOOL;
		approveIOsManually : BOOL;
		flapTestDone : BOOL;
	END_STRUCT;
	resultFAT_wingTestIO_typ : 	STRUCT 
		done : BOOL;
		correctHartingUsed : BOOL;
		approveFunctionality : BOOL;
		ioTestOK : BOOL;
		upperFlapOK : BOOL;
		middleFlapOK : BOOL;
		bottomFlapOK : BOOL;
		neighbourFlapOK : BOOL;
		cassetteReleaseOK : BOOL;
	END_STRUCT;
	resultFAT_CFCoilAdjust_typ : 	STRUCT 
		done : BOOL;
		magneticGap : REAL;
	END_STRUCT;
	resultFAT_CFSpringAdjust_typ : 	STRUCT 
		done : BOOL;
		plate08mm : ARRAY[0..2]OF USINT; (*amount of 0.8mm plates on springs (3 springs)*)
		plate09mm : ARRAY[0..2]OF USINT; (*amount of 0.9mm plates on springs (3 springs)*)
		plate15mm : ARRAY[0..2]OF USINT; (*amount of 1.5mm plates on springs (3 springs)*)
		plate20mm : ARRAY[0..2]OF USINT; (*amount of 2.0mm plates on springs (3 springs)*)
		plate25mm : ARRAY[0..2]OF USINT; (*amount of 2.5mm plates on springs (3 springs)*)
		frequency : REAL;
		freqHertz : REAL; (*axis.parameter.velocity/1000*)
		strTargetFrequency : STRING[40]; (*For report to show target frequency interval*)
		ressFrequency : REAL;
		maxCurrent : REAL;
		currentOK : BOOL;
		frequencyOK : BOOL;
	END_STRUCT;
	resultFAT_LFCoildAdjust_typ : 	STRUCT 
		done : BOOL;
		magneticGap : REAL;
	END_STRUCT;
	resultFAT_LFSpringAdjust_typ : 	STRUCT 
		done : BOOL;
		frequency : REAL;
		freqHertz : REAL; (*axis.parameter.velocity/1000*)
		plate08mm : ARRAY[0..1]OF USINT; (*amount of 0.8mm plates on springs (2 springs)*)
		plate09mm : ARRAY[0..1]OF USINT; (*amount of 0.8mm plates on springs (2 springs)*)
		plate15mm : ARRAY[0..1]OF USINT; (*amount of 0.8mm plates on springs (2 springs)*)
		plate20mm : ARRAY[0..1]OF USINT; (*amount of 0.8mm plates on springs (2 springs)*)
		plate25mm : ARRAY[0..1]OF USINT; (*amount of 0.8mm plates on springs (2 springs)*)
		ressFrequency : REAL;
		maxCurrent : REAL;
		currentOK : BOOL;
		frequencyOK : BOOL;
		strResultForReport : STRING[80];
	END_STRUCT;
	resultFAT_88hTest : 	STRUCT 
		done : BOOL;
	END_STRUCT;
	resultFAT_after72hAdjustments : 	STRUCT 
		done : BOOL;
		approvePacemakerMarking : BOOL;
		approveCoverMounting : BOOL;
		approveRNAmarking : BOOL;
		approveHabasitMounting : BOOL;
	END_STRUCT;
	resultFAT_CFCaliWithHabasit : 	STRUCT 
		done : BOOL;
		ressFrequency : REAL;
		maxCurrent : REAL;
		currentOK : BOOL;
		frequencyOK : BOOL;
		strResultForReport : STRING[80];
	END_STRUCT;
	resultFAT_12hTest : 	STRUCT 
		done : BOOL;
	END_STRUCT;
	resultFAT_resistanceMeas2_typ : 	STRUCT 
		done : BOOL;
		measurementArr : ARRAY[0..8]OF REAL;
		measurementOK : {REDUND_UNREPLICABLE} ARRAY[0..8]OF BOOL;
	END_STRUCT;
	resultFAT_visualInspection_typ : 	STRUCT 
		done : BOOL;
		markingArr : ARRAY[0..12]OF BOOL; (*11 marks to check*)
	END_STRUCT;
	internal_typ : 	STRUCT  (*Internal variables that are saved in a file (used because retain memory sometimes get flushed doing a power fail)*)
		emSubstate : UINT;
		testProgramVersion : STRING[80];
	END_STRUCT;
END_TYPE
