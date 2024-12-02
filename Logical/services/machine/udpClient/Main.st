
PROGRAM _INIT
	 
END_PROGRAM


PROGRAM _CYCLIC

	(*
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------- UDP client implementation to synchronize blinking of digital silo cards. ----------------------------------------  
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	The server will broadcast an incrementing UDINT to the subnet (192.168.1.xxx) with a time interval specified in "lampCtrl".
	The client (CM20) will then receive this UDINT making it possible to blink simultaneously.
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------
	*)
	
	CASE Client.sStep OF 
		
		0:
			IF gMachineInterface.cmd.digitalSiloCmdActive THEN
				Client.sStep := 5;
			END_IF
		
		5:	(* Open UDP Port *)
			Client.UdpOpen_0.enable := TRUE;
			Client.UdpOpen_0.pIfAddr := 0;	(* Listen on all TCP/IP Interfaces*)
			Client.UdpOpen_0.port := 12058;	(* Port to listen*)
			Client.UdpOpen_0.options := udpOPT_BROADCAST;
			Client.UdpOpen_0();	
			
			IF Client.UdpOpen_0.status = 0 THEN  (* UdpOpen successful*)
				Client.sStep := 10;	
			ELSIF Client.UdpOpen_0.status = ERR_FUB_BUSY THEN  (* UdpOpen not finished -> redo *)			
				(* Busy *)	
			ELSE  (* Goto Error Step *)
				Client.sStep := 222;
			END_IF
		
		10:	(* Receive Data from the Server *)
			Client.UdpRecv_0.enable := TRUE;
			Client.UdpRecv_0.ident := Client.UdpOpen_0.ident;  (* Connection Ident from AsUDP.UDP_Open *)
			Client.UdpRecv_0.pData	:= ADR(receive_data);  (* Where to store the incoming data *)
			Client.UdpRecv_0.datamax := SIZEOF(receive_data);  (* Lenght of data buffer *)
			Client.UdpRecv_0.pIpAddr := ADR(Client.server_address);
			Client.UdpRecv_0.flags := 0;
			Client.UdpRecv_0();  (* Call the Function*)
		
			IF Client.UdpRecv_0.status = 0 THEN  (* Data was received successfully -> Send next packet *)
				
				// Check that package is coming from the correct IP
				IF gMachineInterface.cmd.digitalSiloCmdActive THEN
					IF Client.server_address='192.168.1.199' OR Client.server_address='192.168.30.207' THEN // Gateway in prod or test IP in Odense
						gMachineInterface.status.heartBeatFromGateway := receive_data;
					END_IF
				ELSE
					// Digital silo not active - close the port.
					Client.sStep := 20;
				END_IF
				
			ELSIF Client.UdpRecv_0.status = udpERR_NO_DATA THEN  (* No data received - wait *)
				(* No Data received *)				  
			ELSIF Client.UdpRecv_0.status = ERR_FUB_BUSY THEN  (* UdpRecv not finished -> redo *)		
				(* Busy *)
			ELSE  (* Goto Error Step *)
				Client.sStep := 222;
			END_IF
			
		20: (* Close connection *)
			Client.UdpClose_0.enable := TRUE;
			Client.UdpClose_0.ident := Client.UdpOpen_0.ident;  (* Connection Ident from AsUDP.UDP_Open *)
			Client.UdpClose_0();
	
			IF Client.UdpClose_0.status = 0 THEN  (* Close successful -> Reopen the interface *)
				Client.sStep := 0;
			ELSIF Client.UdpClose_0.status = ERR_FUB_BUSY THEN  (* UdpClose not finished -> redo *)	
				(* Busy *)
			ELSE  (* Goto Error Step *)
				Client.sStep := 222;
			END_IF
		
		222: (* Here some error Handling has to be implemented *)
		
	END_CASE
	
	
END_PROGRAM


PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

