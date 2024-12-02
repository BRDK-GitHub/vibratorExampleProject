
ACTION setupPointers:
	this ACCESS ADR(localVariables[i]);
	local ACCESS ADR(local_no_opcua[i]);
	em ACCESS ADR(localModule[i]);
	config ACCESS ADR(localVariables[i].hmi.config);
	configTmp ACCESS ADR(local_no_opcua[i].configTmp);
	recipe ACCESS ADR(localVariables[i].hmi.recipe);
	interface ACCESS ADR(gVibratorInterface[i]);
	axis ACCESS ADR(localAxis[i]);
	axis.configuration.axis := SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
END_ACTION
