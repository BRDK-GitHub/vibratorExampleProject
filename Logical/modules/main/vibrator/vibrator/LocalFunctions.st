
FUNCTION RSquared
	mean := 0;
	FOR i:=0 TO 9 DO
		mean := mean + data[i];
	END_FOR
	mean := mean / 10;
	ssTot := 0;
	FOR i:=0 TO 9 DO
		ssTot := ssTot + pow(data[i]-mean, 2);
	END_FOR
	ssRes := 0;
	FOR i:=0 TO 9 DO
		ssRes := ssRes + pow(data[i]-(prc10+(((prc100-prc10)/9)*USINT_TO_REAL(i))), 2);
	END_FOR
	RSquared := 1 - (ssRes/ssTot);
END_FUNCTION

FUNCTION maxPeakToPercent
	IF (Y2-Y1) <> 0 THEN
		slope := 90/(Y2-Y1);
		maxPeakToPercent := LIMIT(0,slope*maxPeakVal+(10-(slope*Y1)),200);
	END_IF
END_FUNCTION

FUNCTION getAccelerationFromPercent
	
	IF machineType=0 THEN
		IF vibratorType=0 THEN
			// 10%=2756 , 100%=17420
			getAccelerationFromPercent := percent*162.93+1126.7;
		ELSE
			// 10%=1300 , 100%=10140
			getAccelerationFromPercent := percent*98.222+317.78;
		END_IF
	ELSE
		IF vibratorType=0 THEN
			// 10%=1456 , 100%=8060
			getAccelerationFromPercent := percent*73.378+722.22;
		ELSE
			// 10%=1508 , 100%=8840
			getAccelerationFromPercent := percent*81.467+693.33;
		END_IF
	END_IF
	
END_FUNCTION