
(* Implementation of Goertzel algorithm in Structured Text *)
FUNCTION getHammingWindow
	
	getHammingWindow := 0.54 - 0.46 * COS(((PI*2) * n)/(N - 1));;
	
END_FUNCTION

