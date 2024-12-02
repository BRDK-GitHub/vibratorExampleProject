
PROGRAM _INIT
	RemoteUpdate_0.IpEndpoint := '192.168.200.21';
	RemoteUpdate_0.CheckVersion := TRUE; // check version 1 time on boot.
END_PROGRAM

PROGRAM _CYCLIC

	
	RemoteUpdate_0.Enable := gFile.status.ready;
	RemoteUpdate_0();
	 

END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

