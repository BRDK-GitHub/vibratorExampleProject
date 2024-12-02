#include <brdkJSON_func.h>

unsigned long brdkJSONstringify(unsigned long pDestination, unsigned long pName, unsigned long pValue, enum brdk_json_dt_typ datatype, unsigned long size, unsigned long position) {
	unsigned long i = 0;
	if(position == 0) {
		while(((char*)pDestination)[position] != BRDK_STR_ASCII_NULL && ((char*)pDestination)[position] != BRDK_STR_ASCII_CLOSE_BRACE) {
			position++;
		}
	}
	if(position < (size-2)) {
		if(position != 0) ((char*)pDestination)[position++] = BRDK_STR_ASCII_COMMA;		/* property before, add comma */
		else ((char*)pDestination)[position++] = BRDK_STR_ASCII_OPEN_BRACE;				/* first property, add open brace */
		((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;				/* add double quote for name */
	}
	else return -5;

	while(((char*)pName)[i] != BRDK_STR_ASCII_NULL) {
		if(position < size) ((char*)pDestination)[position++] = ((char*)pName)[i++];	/* add name */
		else return -5;
	}
	if(position < (size-2)) {
		((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;				/* add last double quote of name */	
		((char*)pDestination)[position++] = BRDK_STR_ASCII_COLON;						/* add colon before value */	
	}	
	else return -5;
	
	switch(datatype) {
	
		case BRDK_JSON_STRING_TO_STRING:
			if(position < size) ((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
			else return -5;
			i = 0;
			while(((char*)pValue)[i] != BRDK_STR_ASCII_NULL) {
				if(position < size) ((char*)pDestination)[position++] = ((char*)pValue)[i++];
				else return -5;
			}
			if(position < size) ((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
			else return -5;
			break;
			
		case BRDK_JSON_STRING_TO_UDINT: case BRDK_JSON_STRING_TO_DINT: case BRDK_JSON_STRING_TO_REAL:
			i = 0;
			while(((char*)pValue)[i] != BRDK_STR_ASCII_NULL) {
				if(position < size) ((char*)pDestination)[position++] = ((char*)pValue)[i++];
				else return -5;
			}
			break;
			
		case BRDK_JSON_STRING_TO_BOOL:
			if(position < (size-5)) {
				if(brdkStrCmp(pValue,(unsigned long)&"false") == 0 || brdkStrCmp(pValue,(unsigned long)&"0") == 0) {
					position = appendBOOL(false, pDestination, position, size);
				}
				else if(brdkStrCmp(pValue,(unsigned long)&"true") == 0 || brdkStrCmp(pValue,(unsigned long)&"1") == 0) {
					position = appendBOOL(true, pDestination, position, size);
				}
			}
			else return -5;
			break;
	
		
		case BRDK_JSON_DINT_TO_STRING:
			if(position < (size-13)) {	/* max. size of DINT + hypen + 2 x double quotes */
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
				signed long* tmpVal = ((signed long*)pValue);
				brdkStrAppendDintToA(*tmpVal,pDestination,BRDK_STR_CONVERT_DECIMAL,position);
				position += brdkStrDintLen(*tmpVal);
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
			}
			else return -5;
			break;
			
		case BRDK_JSON_DINT_TO_DINT:
			if(position < (size-11)) {	/* max. size of DINT + hypen */
				signed long* tmpVal = ((signed long*)pValue);
				brdkStrAppendDintToA(*tmpVal,pDestination,BRDK_STR_CONVERT_DECIMAL,position);
				position += brdkStrDintLen(*tmpVal);
			}
			else return -5;
			break;
			
		case BRDK_JSON_DINT_TO_BOOL:
			if(position < (size-6)) {	/* max. size of false */
				signed long* tmpVal = ((signed long*)pValue);
				if(!*tmpVal) position = appendBOOL(false, pDestination, position, size);
				else position = appendBOOL(true, pDestination, position, size);
			}
			else return -5;
			break;
			
		case BRDK_JSON_UDINT_TO_STRING:
			if(position < (size-12)) {	/* max. size of UDINT + 2 x double quotes */
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
				unsigned long* tmpVal = ((unsigned long*)pValue);
				brdkStrAppendUdintToA(*tmpVal,pDestination,BRDK_STR_CONVERT_DECIMAL,position);
				position += brdkStrUdintLen(*tmpVal);
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
			}
			else return -5;
			break;
			
		case BRDK_JSON_UDINT_TO_UDINT:
			if(position < (size-10)) {	/* max. size of UDINT */
				unsigned long* tmpVal = ((unsigned long*)pValue);
				brdkStrAppendUdintToA(*tmpVal,pDestination,BRDK_STR_CONVERT_DECIMAL,position);
				position += brdkStrUdintLen(*tmpVal);
			}
			else return -5;
			break;
			
		case BRDK_JSON_UDINT_TO_BOOL:
			if(position < (size-6)) {	/* max. size of false */
				unsigned long* tmpVal = ((unsigned long*)pValue);
				if(!*tmpVal) position = appendBOOL(false, pDestination, position, size);
				else position = appendBOOL(true, pDestination, position, size);
			}
			else return -5;
			break;
			
		case BRDK_JSON_BOOL_TO_STRING:
			if(position < (size-8)) {	/* max. size of false + 2 x diuble quotes */
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
				char* tmpVal = ((char*)pValue);
				if(!*tmpVal) position = appendBOOL(false, pDestination, position, size);
				else position = appendBOOL(true, pDestination, position, size);
				((char*)pDestination)[position++] = BRDK_STR_ASCII_DOUBLE_QUOTES;
			}
			else return -5;
			break;
			
		case BRDK_JSON_BOOL_TO_UDINT: case BRDK_JSON_BOOL_TO_DINT:
			if(position < size) {	/* max. size of 1 */
				char* tmpVal = ((char*)pValue);
				if(!*tmpVal) ((char*)pDestination)[position++] = BRDK_STR_ASCII_0;
				else ((char*)pDestination)[position++] = BRDK_STR_ASCII_1;
			}
			else return -5;
			break;
			
		case BRDK_JSON_BOOL_TO_BOOL:
			if(position < (size-6)) {	/* max. size of false */
				char* tmpVal = ((char*)pValue);
				if(!*tmpVal) position = appendBOOL(false, pDestination, position, size);
				else position = appendBOOL(true, pDestination, position, size);
			}
			else return -5;
			break;
			
		default:
			return -4;	/* error not supported in this function */
			break;
				
	}
	if(position < (size-2)) {
		((char*)pDestination)[position] = BRDK_STR_ASCII_CLOSE_BRACE;
		((char*)pDestination)[position+1] = BRDK_STR_ASCII_NULL;
	}
	else return -5;
	return position;
}
