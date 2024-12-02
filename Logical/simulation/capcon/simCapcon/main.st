
PROGRAM _INIT

	gSimCapcon.parameter.fileName := 'simData.csv';

	IF gMainInterface.status.simulation THEN
		gSimCapcon.cmd.readFile := TRUE;
	END_IF

END_PROGRAM

PROGRAM _CYCLIC
	
	CASE cm.state OF

		0:
			cm.description := 'waiting for command';
			IF gSimCapcon.cmd.readFile THEN
				gSimCapcon.cmd.readFile := FALSE;
				cm.state := 100;
			END_IF

		10:


		100:
			cm.description := 'wait for open file ok';
			this.FileOpen_0.enable 	:= TRUE;
			this.FileOpen_0.pDevice := ADR('SIMDATA');
			this.FileOpen_0.pFile 	:= ADR(gSimCapcon.parameter.fileName);
			this.FileOpen_0.mode 	:= fiREAD_ONLY;
			this.FileOpen_0();
			IF this.FileOpen_0.status = ERR_OK THEN
				brdkStrMemSet(ADR(this.tmpData),0,SIZEOF(this.tmpData));
				this.FileRead_0.ident 	:= this.FileOpen_0.ident;
				this.FileRead_0.offset 	:= 0;
				this.FileRead_0.pDest 	:= ADR(this.tmpData);
				this.FileRead_0.len 	:= SIZEOF(this.tmpData);
				this.FileRead_0.enable	:= TRUE;
				cm.state 				:= 110;
			END_IF

		110:
			cm.description := 'waiting for read file';
			this.FileRead_0();
			IF this.FileRead_0.status = ERR_OK THEN
				this.FileRead_0(enable := FALSE);
				this.FileClose_0.enable := TRUE;
				this.FileClose_0.ident 	:= this.FileOpen_0.ident;
				cm.state := 120;
			END_IF

		120:
			cm.description := 'waiting for file close';
			this.FileClose_0();
			IF this.FileClose_0.status = ERR_OK THEN
				this.FileOpen_0(enable := FALSE);
				this.FileClose_0(enable := FALSE);
				this.lfCnt := 0;
				this.offset := 0;
				brdkStrMemSet(ADR(this.tmpStr),0,SIZEOF(this.tmpStr));
				cm.state := 130;
			END_IF

		130:
			cm.description := 'parse a line';
			FOR this.offset := this.offset TO MAX_FILE_SIZE DO
				CASE this.tmpData[this.offset] OF

					0:	// found end of file
						cm.state := 0;
						EXIT;
						
					10: // found a line feed
						this.lfCnt 		:= this.lfCnt + 1;
						this.colCnt 	:= 0;					// reset ; count

					59:	// found a ;
						IF this.lfCnt >= START_LINE_FEEDS AND this.colCnt >= START_COLS AND this.colCnt <= MAX_COLS THEN
							gSimCapcon.status.data.record[this.lfCnt - START_LINE_FEEDS].value[this.colCnt - START_COLS] := DINT_TO_INT(brdkStrAToDint(ADR(this.tmpStr),BRDK_STR_CONVERT_DECIMAL));
							brdkStrMemSet(ADR(this.tmpStr),0,SIZEOF(this.tmpStr));
							this.charCnt := 0;
						END_IF
						this.colCnt := this.colCnt + 1;

					32..57:	// numbers and some signs
						IF this.lfCnt >= START_LINE_FEEDS AND this.colCnt >= START_COLS AND this.colCnt <= MAX_COLS THEN
							this.tmpStr[this.charCnt] := this.tmpData[this.offset];
							this.charCnt := this.charCnt + 1;
						END_IF
		
				END_CASE					

			END_FOR

	END_CASE

	cm;
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

