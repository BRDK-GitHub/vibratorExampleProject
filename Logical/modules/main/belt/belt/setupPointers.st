
ACTION setupPointers:
	recipe ACCESS ADR(this.hmi.recipe);
	config ACCESS ADR(this.hmi.config);
	interface ACCESS ADR(gBeltInterface);
	axis.configuration.axis				:= ADR(gAxisBelt);
END_ACTION
