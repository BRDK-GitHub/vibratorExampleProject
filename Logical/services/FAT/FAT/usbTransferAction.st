
ACTION usbTransferAction: 

		//-----------------------------------------------------
			//----------------- USB Handling ----------------------
			//-----------------------------------------------------
	UsbNodeListGet_0.enable 		:= TRUE;
	UsbNodeListGet_0.pBuffer 		:= ADR(nodeIdList);
	UsbNodeListGet_0.bufferSize 	:= SIZEOF(nodeIdList);
	UsbNodeListGet_0();
		
	IF UsbNodeListGet_0.status <> ERR_FUB_BUSY THEN
		
		IF UsbNodeListGet_0.status = ERR_OK THEN
			this.hmiUsbPresent := TRUE;
			this.hmiUsbNotPresent := FALSE;
		ELSE
			this.hmiUsbPresent := FALSE;
			this.hmiUsbNotPresent := TRUE;
		END_IF
		
	END_IF
			
	CASE usbState OF
				
		0:
			IF this.hmi.cmd.transferToUsb THEN
				this.hmi.cmd.transferToUsb := FALSE;
				this.hmi.TransferedToUsb := FALSE;
				usbState := 10;
			END_IF
				
		10:	// wait for node list ready
			IF UsbNodeListGet_0.status = ERR_OK THEN
				UsbNodeGet_0(enable 	:= FALSE);
				UsbNodeGet_0.enable 	:= TRUE;
				UsbNodeGet_0.nodeId 	:= nodeIdList[0];
				UsbNodeGet_0.pBuffer 	:= ADR(buffer);
				UsbNodeGet_0.bufferSize := SIZEOF(buffer);
				usbState := 20;
			END_IF
				
		20:	// get usb info
			UsbNodeGet_0();
			IF UsbNodeGet_0.status = ERR_OK THEN
				DevLink_0(enable := FALSE);
				paramString := '/DEVICE=';
				brdkStrCat(ADR(paramString),ADR(buffer.ifName));
				DevLink_0.pDevice 	:= ADR('USB');
				DevLink_0.pParam 	:= ADR(paramString);
				DevLink_0.enable 	:= TRUE;
				usbState		:= 30;
			END_IF
				
		30:	// get dev link
			DevLink_0();
			IF DevLink_0.status = ERR_OK OR DevLink_0.status = fiERR_DEVICE_ALREADY_EXIST THEN
				DevLink_0(enable := FALSE);
				
				IF resultFAT.additionalInfo.typeNoAndSerialNo='' THEN
					this.fileNameDest := 'DataCM20';
				ELSE
					this.fileNameDest := resultFAT.additionalInfo.typeNoAndSerialNo;
					this.tmpString := 'DataCM20';
					brdkStrCat(ADR(this.fileNameDest),ADR(this.tmpString));
				END_IF
				
				usbState := 40;
			END_IF
				
		40: // dir create
			//	 'Create a folder on USB before we dirCopy';
			
			dirCreate_0.enable := TRUE;
			dirCreate_0.pDevice := ADR('USB');
			dirCreate_0.pName := ADR(this.fileNameDest);
			dirCreate_0();
			
			IF dirCreate_0.status = ERR_OK OR dirCreate_0.status = fiERR_DIR_ALREADY_EXIST  THEN
				dirCreate_0(enable := FALSE);
				this.folderNameUSB := this.fileNameDest;
				this.fileNameSrc := 'config.xml';
				IF resultFAT.additionalInfo.typeNoAndSerialNo='' THEN
					this.fileNameDest := 'DataCM20\config.xml';
				ELSE
					this.tmpString := '\';
					brdkStrCat(ADR(this.fileNameDest),ADR(this.tmpString));
					this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
					brdkStrCat(ADR(this.fileNameDest),ADR(this.tmpString));
					this.tmpString := 'config.xml';
					brdkStrCat(ADR(this.fileNameDest),ADR(this.tmpString));
				END_IF
				usbState := 50;
			ELSIF dirCreate_0.status <> ERR_FUB_BUSY THEN
				dirCreate_0(enable := FALSE);
				usbState := 9999;
			END_IF
				
		50: // copy config file
			this.fileCopy_0.enable := TRUE;
			this.fileCopy_0.pSrcDev := ADR('CONFIG');
			this.fileCopy_0.pSrc := ADR(this.fileNameSrc);
			this.fileCopy_0.pDestDev := ADR('USB');
			this.fileCopy_0.pDest := ADR(this.fileNameDest);
			this.fileCopy_0.option := fiOVERWRITE;
			this.fileCopy_0();
			
			IF this.fileCopy_0.status = ERR_OK THEN
				this.fileCopy_0(enable := FALSE);
				// Create ftp param for PLC devlink creation.
				this.actServerCardIpAddress := '192.168.2.11';
				this.ftpParamPLC := '/SIP=';
				brdkStrCat(ADR(this.ftpParamPLC),ADR(this.actServerCardIpAddress));
				this.tmpString := ' /PROTOCOL=ftp /USER=superuser /PASSWORD=superuser';
				brdkStrCat(ADR(this.ftpParamPLC),ADR(this.tmpString));
				usbState := 55;
			ELSIF this.fileCopy_0.status <> ERR_FUB_BUSY THEN
				usbState := 9999;
			END_IF
				
		55: // create plc dev link
			this.devLinkPLC_0.enable := TRUE;
			this.devLinkPLC_0.pDevice := ADR('PLC');
			this.devLinkPLC_0.pParam := ADR(this.ftpParamPLC);
			this.devLinkPLC_0();
			IF this.devLinkPLC_0.status=0 OR this.devLinkPLC_0.status=fiERR_DEVICE_ALREADY_EXIST THEN	// devLink created successfully or it's already created.
				this.devLinkPLC_0(enable := FALSE);
				this.dirPathPLC := 'F:\data';
				IF resultFAT.additionalInfo.typeNoAndSerialNo='' THEN
					this.dirPathUSB := 'DataCM20\data';
				ELSE
					this.dirPathUSB := this.folderNameUSB;
					this.tmpString := '\';
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
					this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
					this.tmpString := 'data';
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
				END_IF
				usbState := 60;
			ELSIF this.devLinkPLC_0.status <> ERR_FUB_BUSY THEN
				this.devLinkPLC_0(enable := FALSE);
				usbState := 9999;
			END_IF
				
		60:
			// 'Copy data DIR to usb';
		
			this.dirCopy_0.enable := TRUE;
			this.dirCopy_0.pSrcDev := ADR('PLC');
			this.dirCopy_0.pSrcDir := ADR(this.dirPathPLC);
			this.dirCopy_0.pDestDev := ADR('USB');
			this.dirCopy_0.pDestDir := ADR(this.dirPathUSB);
			this.dirCopy_0.option := fiOVERWRITE;
			this.dirCopy_0();
			
			IF this.dirCopy_0.status = 0 THEN
				this.dirCopy_0(enable := FALSE);
				this.dirPathPLC := 'F:\report';
				IF resultFAT.additionalInfo.typeNoAndSerialNo='' THEN
					this.dirPathUSB := 'DataCM20\report';
				ELSE
					this.dirPathUSB := this.folderNameUSB;
					this.tmpString := '\';
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
					this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
					this.tmpString := 'reports';
					brdkStrCat(ADR(this.dirPathUSB),ADR(this.tmpString));
				END_IF
				usbState := 70;
			ELSIF this.dirCopy_0.status <> ERR_FUB_BUSY THEN
				this.dirCopy_0(enable := FALSE);
				usbState := 9999;
			END_IF
				
		70:
			// 'Copy report DIR to usb';
			
			this.dirCopy_0.enable := TRUE;
			this.dirCopy_0.pSrcDev := ADR('PLC');
			this.dirCopy_0.pSrcDir := ADR(this.dirPathPLC);
			this.dirCopy_0.pDestDev := ADR('USB');
			this.dirCopy_0.pDestDir := ADR(this.dirPathUSB);
			this.dirCopy_0.option := fiOVERWRITE;
			this.dirCopy_0();
			
			IF this.dirCopy_0.status = 0 THEN
				this.dirCopy_0(enable := FALSE);
				IF resultFAT.additionalInfo.typeNoAndSerialNo = '' THEN
					this.hmi.TransferedToUsb := TRUE;
					this.hmi.cmd.transferToUsb := FALSE;
					usbState := 0;
				ELSE
					// create names for rename
					this.currentName := this.dirPathUSB; //report path on USB
					this.tmpString := '\CM20Protocol.pdf';
					brdkStrCat(ADR(this.currentName),ADR(this.tmpString));
					// New name
					this.newName := this.dirPathUSB;
					this.tmpString := '\';
					brdkStrCat(ADR(this.newName),ADR(this.tmpString));
					this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
					brdkStrCat(ADR(this.newName),ADR(this.tmpString));
					this.tmpString := 'CM20Protocol.pdf';
					brdkStrCat(ADR(this.newName),ADR(this.tmpString));
					
					usbState := 72;
				END_IF
			ELSIF this.dirCopy_0.status <> ERR_FUB_BUSY THEN
				this.dirCopy_0(enable := FALSE);
				usbState := 9999;
			END_IF
			
		72:
			// 'Rename protocol report';
			
			this.FileRename_0.enable := TRUE;
			this.FileRename_0.pDevice := ADR('USB');
			this.FileRename_0.pName := ADR(this.currentName);
			this.FileRename_0.pNewName := ADR(this.newName);
			this.FileRename_0();
			
			IF this.FileRename_0.status = 0 THEN
				this.FileRename_0(enable:=FALSE);
				// create names for rename
				this.currentName := this.dirPathUSB; //report path on USB
				this.tmpString := '\CM20Checklist.pdf';
				brdkStrCat(ADR(this.currentName),ADR(this.tmpString));
				// New name
				this.newName := this.dirPathUSB;
				this.tmpString := '\';
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				this.tmpString := 'CM20Checklist.pdf';
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				
				usbState := 74;
				
			ELSIF this.FileRename_0.status=fiERR_EXIST THEN
				this.FileRename_0(enable:=FALSE);
				this.previousState := usbState;
				this.fileToBeDeleted := this.newName;
				
				usbState := 222;
			ELSIF this.FileRename_0.status <> ERR_FUB_BUSY THEN
				this.FileRename_0(enable:=FALSE);
				usbState := 9999;
			END_IF
			
			
		74:
			// 'Rename checklist report';
			
			this.FileRename_0.enable := TRUE;
			this.FileRename_0.pDevice := ADR('USB');
			this.FileRename_0.pName := ADR(this.currentName);
			this.FileRename_0.pNewName := ADR(this.newName);
			this.FileRename_0();
			
			IF this.FileRename_0.status = 0 THEN
				this.FileRename_0(enable:=FALSE);
				// create names for rename
				this.currentName := this.dirPathUSB; //report path on USB
				this.tmpString := '\CM20hwReport.pdf';
				brdkStrCat(ADR(this.currentName),ADR(this.tmpString));
				// New name
				this.newName := this.dirPathUSB;
				this.tmpString := '\';
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				this.tmpString := resultFAT.additionalInfo.typeNoAndSerialNo;
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				this.tmpString := 'CM20hwReport.pdf';
				brdkStrCat(ADR(this.newName),ADR(this.tmpString));
				
				usbState := 76;
			ELSIF this.FileRename_0.status=fiERR_EXIST THEN
				this.FileRename_0(enable:=FALSE);
				this.previousState := usbState;
				this.fileToBeDeleted := this.newName;
				
				usbState := 222;
			ELSIF this.FileRename_0.status <> ERR_FUB_BUSY THEN
				this.FileRename_0(enable:=FALSE);
				usbState := 9999;
			END_IF
			
		76:
			// 'Rename hw report';	
			
			this.hmi.TransferedToUsb := TRUE;
			this.hmi.cmd.transferToUsb := FALSE;
				
			usbState := 0;
			
			
		222:
			//'Delete file and return to previous state';
			
			this.FileDelete_0.enable := TRUE;
			this.FileDelete_0.pDevice := ADR('USB');
			this.FileDelete_0.pName := ADR(this.fileToBeDeleted);
			this.FileDelete_0();
			
			IF this.FileDelete_0.status=0 THEN
				this.FileDelete_0(enable:=FALSE);
				usbState := this.previousState;
			ELSIF this.FileDelete_0.status <> ERR_FUB_BUSY THEN
				this.FileDelete_0(enable:=FALSE);
				usbState := 9999;
			END_IF
			
			
			
		9999:
			UsbNodeListGet_0(enable := FALSE);
			UsbNodeGet_0(enable := FALSE);
			this.FileRename_0(enable:=FALSE);
			this.dirCopy_0(enable := FALSE);
			this.devLinkPLC_0(enable := FALSE);
			this.fileCopy_0(enable := FALSE);
		
			usbState := 0;
				
					
				
	END_CASE
	
END_ACTION
