
PROGRAM _INIT

	EIPInit_0.enable := TRUE;
	EIPInit_0.pconfig := ADR('eipconf');
	EIPInit_0();
	
	remoteInputArray;
	remoteOutputArray;
	remoteCommectionStatus;
END_PROGRAM

PROGRAM _CYCLIC

	CASE state OF
		
		0:
			IF gMachineInterface.parameter.actualServerIP <> '' THEN
				
				tmpStr := '';
				brdkStrSubStr(ADR(tmpStr),ADR(gMachineInterface.parameter.actualServerIP),-1,3);
				strInternalLineIP := '192.168.1.';
				strInternalLineIP := CONCAT(strInternalLineIP,tmpStr);
				
				EIPCyclic_0.handle := EIPInit_0.handle;
				EIPCyclic_0.enable := TRUE;
				state := 10;
			END_IF
		
		10:
			interface ACCESS ADR(gEthernetIPInterface);
			
			remoteOutputArray.0  := interface.status.stop;
			remoteOutputArray.1  := interface.status.start;
			remoteOutputArray.2	 := interface.status.empty;
			remoteOutputArray.3  := interface.status.emptyMode;
			remoteOutputArray.4  := interface.status.bypassCassette;
			remoteOutputArray.13 := interface.status.di_cassetteReady;
			remoteOutputArray.14 := interface.status.di_cassetteQueue;
			remoteOutputArray.15 := interface.status.do_cassetteRelease;
			
			EIPCyclic_0();
		
			gMainInterface.cmd.stopEthIP := remoteInputArray.0;
			gMainInterface.cmd.startEthIP := remoteInputArray.1;
			gMainInterface.cmd.emptyEthIP := remoteInputArray.2;
			gMainInterface.cmd.emptyModeEthIP := remoteInputArray.3;
			gMainInterface.cmd.bypassCassetteEthIP := remoteInputArray.4;
		
		
			
	END_CASE

END_PROGRAM

PROGRAM _EXIT

	EIPExit_0.handle := EIPCyclic_0.handle;
	EIPExit_0.enable := TRUE;
	EIPExit_0();
	 
END_PROGRAM

