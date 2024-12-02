
ACTION resetStatistics: 
	this.hmi.count.integral.tooBig := 0;
	this.hmi.count.integral.tooSmall := 0;
	//this.hmi.count.peak.tooBig := 0;
	//this.hmi.count.peak.tooSmall := 0;
//	this.hmi.count.samples.tooBig := 0;
//	this.hmi.count.samples.tooSmall := 0;
	gUpperFlapInterface.status.countAftercount := 0;
	this.hmi.count.invalidBuffer.count := 0;
	this.hmi.count.portions.count := 0;
//	this.hmi.count.timeouts.count := 0;
	this.hmi.count.reject.percent := 0;
	this.hmi.count.reject.count := 0;
END_ACTION
