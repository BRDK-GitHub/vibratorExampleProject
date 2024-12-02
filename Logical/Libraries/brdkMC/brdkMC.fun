
FUNCTION_BLOCK brdkMcBasic (*brdk Motion basic*)
	VAR_INPUT
		command : brdk_mc_command_typ; (*command input*)
		parameter : brdk_mc_parameter_typ; (*parameter input*)
		configuration : brdk_mc_configuration_typ; (*configuration input*)
	END_VAR
	VAR_OUTPUT
		status : brdk_mc_status_typ; (*status output*)
		info : brdk_mc_info_typ; (*information output*)
	END_VAR
	VAR
		state : state_enum; (*state enumeration*)
		internal : brdk_mc_internal_typ; (*internal structure*)
		pAxis : REFERENCE TO ACP10AXIS_typ; (*internal axis pointer reference*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION dstoa : UINT (****)
	VAR_INPUT
		driveState : Status_enum;
		pString : UDINT;
	END_VAR
END_FUNCTION
