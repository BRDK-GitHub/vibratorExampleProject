
(* TODO: Add your comment here *)
FUNCTION cmIsRunning
	
	cmIsRunning := speed = lego_speed_counting OR speed = lego_speed_wait;

END_FUNCTION

FUNCTION elementNeedsLowFilling

	elementNeedsLowFilling := DesignId = 3741 OR DesignId = 24855 OR DesignId = 2447 OR DesignId = 35334 OR DesignId = 35315 OR DesignId = 35287 OR DesignId = 2586 OR DesignId = 19119;

END_FUNCTION