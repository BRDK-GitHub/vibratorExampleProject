
(* TODO: Add your comment here *)
FUNCTION getHourMinutsFromDecimal
	
	hours := TRUNC(decimalTime);
	minutes := TRUNC((decimalTime - hours) * 60);
	
	getHourMinutsFromDecimal := INT_TO_REAL(hours)+INT_TO_REAL(minutes)/100;
	
END_FUNCTION
