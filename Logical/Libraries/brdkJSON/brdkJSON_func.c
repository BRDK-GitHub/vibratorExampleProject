#include <brdkJSON_func.h>

unsigned long appendBOOL(char value, unsigned long pDestination, unsigned long position, unsigned long size) {
	if(!value) {
		((char*)pDestination)[position++] = BRDK_STR_ASCII_f;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_a;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_l;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_s;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_e;
		return position;
	}
	else {
		((char*)pDestination)[position++] = BRDK_STR_ASCII_t;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_r;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_u;
		((char*)pDestination)[position++] = BRDK_STR_ASCII_e;
		return position;
	}
}

unsigned long setValue(enum brdk_json_dt_typ datatype, unsigned long pValue, unsigned long str) {
	if(datatype == BRDK_JSON_DINT_TO_DINT || datatype == BRDK_JSON_STRING_TO_DINT) {
		signed long* tmpVal = ((signed long*)pValue);
		*tmpVal = brdkStrAToDint(str,BRDK_STR_CONVERT_DECIMAL);
		return 0;
	}
	else if(datatype == BRDK_JSON_UDINT_TO_UDINT || datatype == BRDK_JSON_STRING_TO_UDINT) {
		unsigned long* tmpVal = ((unsigned long*)pValue);
		*tmpVal = brdkStrAToUdint(str,BRDK_STR_CONVERT_DECIMAL);
		return 0;
	}
	else if(datatype == BRDK_JSON_REAL_TO_REAL || datatype == BRDK_JSON_STRING_TO_REAL) {
		float* tmpVal = ((float*)pValue);
		*tmpVal = brdkStrAToReal(str);
		return 0;
	}
	else if(datatype == BRDK_JSON_BOOL_TO_DINT) {
		signed long* tmpVal = ((signed long*)pValue);
		if(brdkStrLen(str) < 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"true") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"1") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"false") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"0") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"") == 0) *tmpVal = false;
		else return 1;	/* error illegal character */
	}
	else if(datatype == BRDK_JSON_BOOL_TO_UDINT) {
		unsigned long* tmpVal = ((unsigned long*)pValue);
		if(brdkStrLen(str) < 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"true") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"1") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"false") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"0") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"") == 0) *tmpVal = false;
		else return 1; 	/* error illegal character */
	}
	else {
		char* tmpVal = ((char*)pValue);
		if(brdkStrLen(str) < 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"true") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"1") == 0) *tmpVal = true;
		else if(brdkStrCmp(str, (unsigned long)&"false") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"0") == 0) *tmpVal = false;
		else if(brdkStrCmp(str, (unsigned long)&"") == 0) *tmpVal = false;
		else return 1; /* error illegal character */
	}
	return 0;
}

unsigned char getSize(enum brdk_json_dt_typ datatype) {
	switch(datatype) {
		case BRDK_JSON_DINT_TO_DINT: case BRDK_JSON_UDINT_TO_UDINT:
		case BRDK_JSON_STRING_TO_DINT: case BRDK_JSON_STRING_TO_UDINT:
		case BRDK_JSON_BOOL_TO_DINT: case BRDK_JSON_BOOL_TO_UDINT:
		case BRDK_JSON_REAL_TO_REAL: case BRDK_JSON_STRING_TO_REAL:
			return 4;
		default: 
			return 1;
	}
}
	
