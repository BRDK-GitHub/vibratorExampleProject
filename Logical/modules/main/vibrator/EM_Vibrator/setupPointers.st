
ACTION setupPointers:
	this ACCESS ADR(localVariables[i]);
	hmi ACCESS ADR(localHmi[i]);
	em ACCESS ADR(localModule[i]);
	config ACCESS ADR(localVariables[i].hmi.config);
	configTmp ACCESS ADR(localVariables[i].configTmp);
	interface ACCESS ADR(gVibratorInterface[i]);
	axis ACCESS ADR(localAxis[i]);
	axis.configuration.axis := SEL(i=0,ADR(gAxisVibL),ADR(gAxisVibC));
END_ACTION
