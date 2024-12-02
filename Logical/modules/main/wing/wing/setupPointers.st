
ACTION setupPointers:
	recipe ACCESS ADR(this.hmi.recipe);
	config ACCESS ADR(this.hmi.config);
	interface ACCESS ADR(gWingInterface);
END_ACTION
