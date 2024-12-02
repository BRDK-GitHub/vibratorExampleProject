
TYPE
	local_typ : 	STRUCT 
		FileOpen_0 : FileOpen;
		FileRead_0 : FileRead;
		FileClose_0 : FileClose;
		tmpData : ARRAY[0..MAX_FILE_SIZE]OF USINT;
		offset : UDINT;
		tmpStr : ARRAY[0..9]OF USINT;
		colCnt : UINT;
		lfCnt : USINT;
		charCnt : USINT;
	END_STRUCT;
END_TYPE
