#include <brdkJSON_func.h>

signed long brdkJSONparseToStringArray(unsigned long pSource, unsigned long pName, unsigned long pValue, enum brdk_json_dt_typ datatype, unsigned long size, unsigned long arraySize, unsigned long position) {
	char run, quoteCnt = 0, bracketOpen = false;
	signed long i, index = 0, pos = 0;
	if(pName != 0) pos = brdkStrSearch((unsigned long)&(((char*)pSource)[position]), pName);
	if(pos > -1) {
		if(pName != 0) pos += brdkStrLen(pName) + 2 + position;
		switch(datatype) {
			
			case BRDK_JSON_STRING_TO_STRING: case BRDK_JSON_DINT_TO_STRING: case BRDK_JSON_UDINT_TO_STRING: case BRDK_JSON_BOOL_TO_STRING: case BRDK_JSON_REAL_TO_STRING:
				i = 0;
				run = true;
				char bckslash = false;
				while(run) {
					/* find the first square bracket */
					switch(((char*)pSource)[pos]) {
						case BRDK_STR_ASCII_NULL: run = false; pos = -2; break;	/* error null cannot be here */
						case BRDK_STR_ASCII_TAB: case BRDK_STR_ASCII_CR: case BRDK_STR_ASCII_LF: pos++; break;
						case BRDK_STR_ASCII_CLOSE_BRACKET:
							if(bracketOpen && quoteCnt == 1 && datatype == BRDK_JSON_STRING_TO_STRING) {
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							}
							else {
								bracketOpen = false;
								if(pName != 0) {
									if(run) pos++;	/* pName == 0 is allowed for e.g. [1,2,3] */
								}
								else {
									((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
									i = 0;
									for(;index < arraySize; index++) {
										pValue += size;
										((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
									} 
									pos++;
									run = false;
								}
							}
							break;
						case BRDK_STR_ASCII_COMMA:
							if(quoteCnt < 2 && datatype == BRDK_JSON_STRING_TO_STRING) {
								if(!bracketOpen) {
								 	i = 0;
									for(;index < arraySize; index++) {
										pValue += size;
										((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
									}
									run = false;
								}
								else {
									if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
									else {
										run = false; 
										pos = -5;	/* error string size too small */
									}
								}
							}
							else {
								((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
								pos++;
								/* bracket is closed -> comma after array element -> we are finished */
								if(!bracketOpen) {
								 	i = 0;
									for(;index < arraySize; index++) {
										pValue += size;
										((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
									}
									run = false;
								}
								else {	/* bracket still open -> next element in array */
									index++;
									if(index < arraySize) {
										pValue += size;
										quoteCnt = 0;
										i = 0;
									}
									else {
										run = false; 
										pos = -6;	/* array size too small */
									}	
								}
							}
							break;
						case BRDK_STR_ASCII_CLOSE_BRACE:
							if(quoteCnt == 1 && datatype == BRDK_JSON_STRING_TO_STRING) 
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							else {
								if(datatype != BRDK_JSON_STRING_TO_STRING) ((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
								i = 0;
								for(;index < arraySize; index++) {
									pValue += size;
									((char*)pValue)[i] = BRDK_STR_ASCII_NULL;
								} 
								pos++;
								run = false;
							}
							break;
						case BRDK_STR_ASCII_DOUBLE_QUOTES:
							if(datatype == BRDK_JSON_STRING_TO_STRING) {
								if(!bckslash) {
									if(quoteCnt > 1) {
										run = false; 
										pos = -3;	/* error illegal character */
									}
									else quoteCnt++;
								}
								else bckslash = false;
								pos++;
							}
							else {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							break;
						case BRDK_STR_ASCII_HYPHEN: 
							if(datatype == BRDK_JSON_DINT_TO_STRING || datatype == BRDK_JSON_STRING_TO_STRING || datatype == BRDK_JSON_REAL_TO_STRING) {
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							}
							else {
								run = false; 
								pos = -3;/* error illegal character */
							}	
							break;
						case BRDK_STR_ASCII_DOT:
							if(datatype == BRDK_JSON_REAL_TO_STRING || datatype == BRDK_JSON_STRING_TO_STRING) {
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							}
							else {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							break;
						case BRDK_STR_ASCII_BACK_SLASH:
							if(datatype == BRDK_JSON_STRING_TO_STRING) {
								if(!bckslash) bckslash = true;
								else {
									if(i < size) {
										((char*)pValue)[i++] = ((char*)pSource)[pos];
										bckslash = false;
									}
									else {
										run = false; 
										pos = -5;	/* error string size too small */
									}
								}
								if(run) pos++;
							}
							else {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							break;
						case BRDK_STR_ASCII_SPACE: case BRDK_STR_ASCII_COLON:
							if(quoteCnt == 1) {
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							}
							if(run) pos++;
							break;
						case BRDK_STR_ASCII_OPEN_BRACKET:
							bracketOpen = true;
							if(quoteCnt > 0) {
								if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos];
								else {
									run = false; 
									pos = -5;	/* error string size too small */
								}
							}
							if(run) pos++;
							break;
						default:
							if(datatype == BRDK_JSON_STRING_TO_STRING) {
								if(quoteCnt > 0) {
									if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
									else {
										run = false; 
										pos = -5;	/* error string size too small */
									}
								}
								else {
									run = false; 
									pos = -3;	/* error illegal character */
								}
							}
							else if(datatype == BRDK_JSON_DINT_TO_STRING || datatype == BRDK_JSON_UDINT_TO_STRING || datatype == BRDK_JSON_REAL_TO_STRING) {
								switch(((char*)pSource)[pos]) {
									case BRDK_STR_ASCII_0: case BRDK_STR_ASCII_1: case BRDK_STR_ASCII_2: case BRDK_STR_ASCII_3:
									case BRDK_STR_ASCII_4: case BRDK_STR_ASCII_5: case BRDK_STR_ASCII_6: case BRDK_STR_ASCII_7:
									case BRDK_STR_ASCII_8: case BRDK_STR_ASCII_9: 
										if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
										else {
											run = false; 
											pos = -5;	/* error string size too small */
										}
										break;
								
									default:
										run = false; 
										pos = -3;	/* error illegal character */
										break;
								}
							}
							else if(datatype == BRDK_JSON_BOOL_TO_STRING) {
								switch(((char*)pSource)[pos]) {
										case BRDK_STR_ASCII_t: case BRDK_STR_ASCII_r: case BRDK_STR_ASCII_u: case BRDK_STR_ASCII_e:
										case BRDK_STR_ASCII_f: case BRDK_STR_ASCII_a: case BRDK_STR_ASCII_l: case BRDK_STR_ASCII_s: 
										if(i < size) ((char*)pValue)[i++] = ((char*)pSource)[pos++];
										else {
											run = false; 
											pos = -5;	/* error string size too small */
										}
										break;
								
									default:
										run = false; 
										pos = -3;	/* error illegal character */
										break;
								}
							}
							break;
					}
				}
				break;
		
			default:
				run = false; 
				pos = -4;	/* error not supported in this function */
				break;
		}
	}
	return pos;
}
