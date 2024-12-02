
ACTION setupPointers:
	recipe ACCESS ADR(this.hmi.recipe);
	config ACCESS ADR(this.hmi.config);
	interface ACCESS ADR(gCapconInterface);
END_ACTION
