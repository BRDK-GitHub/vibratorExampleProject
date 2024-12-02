(*Lamp*)

TYPE
	plc_lamp_typ : 	STRUCT 
		color : lamp_color_typ; (*Activate color*)
		flash : lamp_flash_typ; (*Activate flash*)
		temperature : SINT; (*Read temperature*)
		io : plc_lamp_io_typ; (*I/O structure*)
		timeoutActive : BOOL;
		timeoutElapsedTime : UDINT;
	END_STRUCT;
	lamp_color_typ : 
		(
		COLOR_OFF := 0, (*NO COLOR*)
		COLOR_GREEN := 1, (*GREEN*)
		COLOR_RED := 2, (*RED*)
		COLOR_YELLOW := 3, (*YELLOW*)
		COLOR_BLUE := 4, (*BLUE*)
		COLOR_ORANGE := 5, (*ORANGE*)
		COLOR_OWN := 6, (*OWN*)
		COLOR_WHITE := 7 (*WHITE*)
		) := COLOR_OFF;
	lamp_flash_typ : 
		(
		FLASH_PERMANENT := 0,
		FLASH_FLASH := 1,
		FLASH_BLINK := 2
		) := FLASH_PERMANENT;
	plc_lamp_io_typ : 	STRUCT 
		output : USINT; (*Variable mapped to X67DS438A module*)
		status : USINT; (*Variable mapped to X67DS438A module*)
	END_STRUCT;
	status_string_typ : 	STRUCT 
		lamp : status_lamp_typ;
	END_STRUCT;
	status_lamp_typ : 	STRUCT 
		color : lamp_color_typ; (*Activate color*)
		flash : lamp_flash_typ; (*Activate flash*)
		repeat : UDINT;
		timeout : UDINT;
	END_STRUCT;
	flash_typ : 	STRUCT 
		elapsedTime : UDINT;
		on : BOOL;
	END_STRUCT;
END_TYPE

(*config*)

TYPE
	config_typ : 	STRUCT 
		brightness : config_color_typ;
		ownColor : config_color_typ;
		healthCheck : config_healthcheck_typ;
		permanent : config_permanent_typ;
		testPosition : config_test_position_typ;
		flash : config_flash_typ;
		blink : config_blink_typ;
	END_STRUCT;
	config_lamp_typ : 	STRUCT 
		subStringNo : UDINT;
	END_STRUCT;
	config_permanent_typ : 	STRUCT 
		timeout : UDINT := 120000; (*2min*)
	END_STRUCT;
	config_flash_typ : 	STRUCT 
		timeout : UDINT := 120000; (*2min*)
		onTime : UDINT := 1000; (*1s*)
		offTime : UDINT := 1000; (*1s*)
	END_STRUCT;
	config_blink_typ : 	STRUCT 
		onTime : UDINT := 1000; (*1s*)
		offTime : UDINT := 1000; (*1s*)
		repeat : UDINT;
	END_STRUCT;
	config_healthcheck_typ : 	STRUCT 
		colorSequence : ARRAY[0..6]OF lamp_color_typ := [COLOR_GREEN,COLOR_BLUE,COLOR_ORANGE,COLOR_RED,COLOR_WHITE,2(COLOR_OFF)];
		timeout : UDINT := 10000; (*10s*)
	END_STRUCT;
	config_color_typ : 	STRUCT 
		blue : USINT := 100;
		green : USINT := 100;
		red : USINT := 100;
	END_STRUCT;
	config_test_position_typ : 	STRUCT 
		color : lamp_color_typ := COLOR_GREEN; (*Activate color*)
		timeout : UDINT := 2000; (*2s*)
	END_STRUCT;
END_TYPE

(*IO-LINK communication*)

TYPE
	lamp_iolink_typ : 	STRUCT 
		state : DINT;
		ioLinkWrite_0 : ioLinkWrite;
		ioLinkRead_0 : ioLinkRead;
		setBrightness : BOOL;
		setOwnColor : BOOL;
		data : ARRAY[0..2]OF USINT;
		deviceName : STRING[80];
		node : USINT;
		subIndex : USINT;
		temperature : SINT;
		stringNo : USINT;
		elapsedTime : UDINT;
	END_STRUCT;
END_TYPE
