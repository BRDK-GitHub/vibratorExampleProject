
FUNCTION_BLOCK legoCM20Flap (*Function block for controlling a flap*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL;
		close : BOOL := FALSE; (*Close the flap.*)
		open : BOOL := FALSE; (*Open the flap.*)
		resetError : BOOL;
		di_changeover : BOOL := FALSE; (*Changeover sensor.*)
		flapTime : UDINT := 0; (*Flap movement time.*)
		cycleTime : UDINT := 0; (*Current cycletime.*)
		avgSamples : USINT := 10;
		WUstepperConnected : BOOL;
		simulation : BOOL;
		positionFromWUstepper : legocm20_flap_position_typ; (*8=FLAP_CLOSED, 4=FLAP_OPEN*)
	END_VAR
	VAR_OUTPUT
		position : legocm20_flap_position_typ := FLAP_CLOSED; (*Actual position of the flap.*)
		do_open : BOOL := FALSE; (*Move flap command.*)
		error : BOOL := FALSE; (*Error. Is removed by a new open or close signal.*)
		closingTime : UDINT;
		openTime : UDINT;
		closingTimeAfterChangeover : UDINT;
		openTimeAfterChangeover : UDINT;
		openCloseTime : UDINT;
	END_VAR
	VAR
		internal : legocm20_flap_internal_typ; (*Internal variables.*)
		TON_0 : TON;
		simulatedTimeToOpenCloseFlap : TIME := T#150ms;
	END_VAR
END_FUNCTION_BLOCK
