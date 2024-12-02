
TYPE
	local_typ : 	STRUCT 
		strURL : STRING[300];
		oldItemNumber : STRING[20];
		errorCode : UINT;
		responeStruct : responeStruct_typ; (*JSON response will be parsed into this structure*)
		responseStructMini : responeStruct_typ;
		TON_0 : TON;
		imageURL : STRING[60];
		tmpStr : STRING[20];
		countPictureChanged : UDINT;
		tmpImageURL : STRING[60];
		TON_client : TON;
		errorCount : USINT;
	END_STRUCT;
	responeStruct_typ : 	STRUCT 
		itemNo : DINT;
		image : STRING[99999];
	END_STRUCT;
END_TYPE
