
(* Implementation of Goertzel algorithm in Structured Text *)
FUNCTION goertzel
	
	r := (PI*2)/UINT_TO_REAL(sampleRate);

	w := r*frequency; 
	cosine := COS(w);
	sine := SIN(w);
	coeff := 2*cosine;
	Q0 := 0;
	Q1 := 0;
	Q2 := 0;
	
	FOR j:=0 TO MAX_SAMPLES_GOERTZEL DO
		Q0 := coeff * Q1 - Q2 + (samples[j]);
		Q2 := Q1;
		Q1 := Q0;
	END_FOR
	
	real := Q1 - Q2 * cosine;
	imag := Q2 * sine;
	
	goertzel := SQRT(((real*real)+(imag*imag)));
	
END_FUNCTION

FUNCTION goertzelWindowSmooth
	
	r := (PI*2)/UINT_TO_REAL(sampleRate);

	w := r*frequency; 
	cosine := COS(w);
	sine := SIN(w);
	coeff := 2*cosine;
	Q0 := 0;
	Q1 := 0;
	Q2 := 0;
	
	FOR j:=0 TO MAX_SAMPLES_GOERTZEL DO
		Q0 := coeff * Q1 - Q2 + (samples[j]*window[j]);
		Q2 := Q1;
		Q1 := Q0;
	END_FOR
	
	real := Q1 - Q2 * cosine;
	imag := Q2 * sine;
	
	goertzelWindowSmooth := SQRT(((real*real)+(imag*imag)));
	
END_FUNCTION

FUNCTION_BLOCK goertzelMagPhase
	
	r := (PI*2)/UINT_TO_REAL(sampleRate);

	w := r*frequency; 
	cosine := COS(w);
	sine := SIN(w);
	coeff := 2*cosine;
	Q0 := 0;
	Q1 := 0;
	Q2 := 0;
	
	FOR j:=0 TO MAX_SAMPLES_GOERTZEL DO
		Q0 := coeff * Q1 - Q2 + (samples[j]*window[j]);
		Q2 := Q1;
		Q1 := Q0;
	END_FOR
	
	real := Q1 - Q2 * cosine;
	imag := Q2 * sine;
	
	magnitude := SQRT(((real*real)+(imag*imag)));;
	phase := atan2(imag,real);
	
END_FUNCTION_BLOCK
