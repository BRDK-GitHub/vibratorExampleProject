
ACTION findIndexInGatewayArray: 
	tmpString := this.opcua.actualLocalIpAddress := gMachineInterface.parameter.actualServerIP;
	brdkStrSlice(ADR(tmpString),10,13);
	
	CASE STRING_TO_USINT(tmpString) OF
		
		201: this.opcua.indexInGatewayIpArray := 0;
		202: this.opcua.indexInGatewayIpArray := 1;
		203: this.opcua.indexInGatewayIpArray := 2;
		204: this.opcua.indexInGatewayIpArray := 3;
		205: this.opcua.indexInGatewayIpArray := 4;
		206: this.opcua.indexInGatewayIpArray := 5;
		207: this.opcua.indexInGatewayIpArray := 6;
		208: this.opcua.indexInGatewayIpArray := 7;
		209: this.opcua.indexInGatewayIpArray := 8;
		210: this.opcua.indexInGatewayIpArray := 9;
		211: this.opcua.indexInGatewayIpArray := 10;
		212: this.opcua.indexInGatewayIpArray := 11;
		213: this.opcua.indexInGatewayIpArray := 12;
		214: this.opcua.indexInGatewayIpArray := 13;
		215: this.opcua.indexInGatewayIpArray := 14;
		216: this.opcua.indexInGatewayIpArray := 15;
		217: this.opcua.indexInGatewayIpArray := 16;
		218: this.opcua.indexInGatewayIpArray := 17;
		221: this.opcua.indexInGatewayIpArray := 18;
		222: this.opcua.indexInGatewayIpArray := 19;
		223: this.opcua.indexInGatewayIpArray := 20;
		224: this.opcua.indexInGatewayIpArray := 21;
		225: this.opcua.indexInGatewayIpArray := 22;
		226: this.opcua.indexInGatewayIpArray := 23;
		227: this.opcua.indexInGatewayIpArray := 24;
		228: this.opcua.indexInGatewayIpArray := 25;
		229: this.opcua.indexInGatewayIpArray := 26;
		230: this.opcua.indexInGatewayIpArray := 27;
		231: this.opcua.indexInGatewayIpArray := 28;
		232: this.opcua.indexInGatewayIpArray := 29;
		233: this.opcua.indexInGatewayIpArray := 30;
		234: this.opcua.indexInGatewayIpArray := 31;
		235: this.opcua.indexInGatewayIpArray := 32;
		236: this.opcua.indexInGatewayIpArray := 33;
		237: this.opcua.indexInGatewayIpArray := 34;
		238: this.opcua.indexInGatewayIpArray := 35;
		
	END_CASE
	
	IF this.opcua.actualLocalIpAddress='10.45.10.118' OR this.opcua.actualLocalIpAddress='10.45.10.135'  THEN
		this.opcua.indexInGatewayIpArray := 0; // index 0 when testing in Odense
	ELSIF this.opcua.actualLocalIpAddress='10.45.10.119' OR this.opcua.actualLocalIpAddress='10.45.10.141' THEN
		this.opcua.indexInGatewayIpArray := 1; // index 1 when testing in Odense.
	END_IF
		
END_ACTION
