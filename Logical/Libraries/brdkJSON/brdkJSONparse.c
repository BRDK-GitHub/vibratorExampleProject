#include <brdkJSON_func.h>

signed long brdkJSONparse(unsigned long pSource, unsigned long pName, unsigned long pValue, enum brdk_json_dt_typ datatype, unsigned long position) {
	/* {"test": "1234", "test2": "9876"} */
	/* {"test": 1234, "test": 9876} */
	char str[12], run, quoteCnt = 0;
	signed long i, pos = brdkStrSearch((unsigned long)&(((char*)pSource)[position]), pName);
	if(pos > -1) {
		pos += brdkStrLen(pName) + 2 + position;
		switch(datatype) {
				
			case BRDK_JSON_DINT_TO_DINT: case BRDK_JSON_STRING_TO_DINT:
			case BRDK_JSON_UDINT_TO_UDINT: case BRDK_JSON_STRING_TO_UDINT:
			case BRDK_JSON_REAL_TO_REAL: case BRDK_JSON_STRING_TO_REAL:
				i = 0;
				run = true;
				while(run) {
					switch(((char*)pSource)[pos]) {
						case BRDK_STR_ASCII_NULL: run = false; pos = -2; break;	/* error null cannot be here */
						case BRDK_STR_ASCII_TAB: case BRDK_STR_ASCII_SPACE: case BRDK_STR_ASCII_COLON: case BRDK_STR_ASCII_CR: case BRDK_STR_ASCII_LF: pos++; break;	/* white space and colon can be ok from beginning */
						case BRDK_STR_ASCII_COMMA: case BRDK_STR_ASCII_CLOSE_BRACE: pos++; run = false; break; /* , or } we are finished */
						case BRDK_STR_ASCII_DOUBLE_QUOTES:
							if(quoteCnt > 1 || datatype == BRDK_JSON_DINT_TO_DINT || datatype == BRDK_JSON_UDINT_TO_UDINT || datatype == BRDK_JSON_REAL_TO_REAL) {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							else quoteCnt++;
							pos++;
							break;
						case BRDK_STR_ASCII_HYPHEN: 
							if(datatype != BRDK_JSON_DINT_TO_DINT && datatype != BRDK_JSON_STRING_TO_DINT && datatype != BRDK_JSON_REAL_TO_REAL && datatype != BRDK_JSON_STRING_TO_REAL) {
								run = false; 
								pos = -3;/* error illegal character */
							}
							else ((char*)str)[i++] = ((char*)pSource)[pos++];
							break;
						case BRDK_STR_ASCII_DOT:
							if(datatype != BRDK_JSON_REAL_TO_REAL && datatype != BRDK_JSON_STRING_TO_REAL) {
								run = false; 
								pos = -3;/* error illegal character */
							}
							else ((char*)str)[i++] = ((char*)pSource)[pos++];
							break;
						case BRDK_STR_ASCII_0: case BRDK_STR_ASCII_1: case BRDK_STR_ASCII_2: case BRDK_STR_ASCII_3:
						case BRDK_STR_ASCII_4: case BRDK_STR_ASCII_5: case BRDK_STR_ASCII_6: case BRDK_STR_ASCII_7:
						case BRDK_STR_ASCII_8: case BRDK_STR_ASCII_9: 
							((char*)str)[i++] = ((char*)pSource)[pos++];
							break;
						default: run = false; pos = -3; break;	/* error illegal character */
					} 
				}
				if(pos > -1) {
					((char*)str)[i] = BRDK_STR_ASCII_NULL;
					setValue(datatype, pValue, (unsigned long)&str);
				}
				break;
				
			case BRDK_JSON_BOOL_TO_BOOL: case BRDK_JSON_STRING_TO_BOOL: case BRDK_JSON_UDINT_TO_BOOL:
			case BRDK_JSON_DINT_TO_BOOL: case BRDK_JSON_BOOL_TO_DINT: case BRDK_JSON_BOOL_TO_UDINT:
				i = 0;
				run = true;
				while(run) {
					switch(((char*)pSource)[pos]) {
						case BRDK_STR_ASCII_NULL: run = false; pos = -2; break;	/* error null cannot be here */
						case BRDK_STR_ASCII_TAB: case BRDK_STR_ASCII_CR: case BRDK_STR_ASCII_LF: case BRDK_STR_ASCII_SPACE: case BRDK_STR_ASCII_COLON: pos++; break;	/* white space can be ok from beginning */
						case BRDK_STR_ASCII_DOUBLE_QUOTES:
							if(quoteCnt > 1 || datatype == BRDK_JSON_BOOL_TO_BOOL || datatype == BRDK_JSON_DINT_TO_BOOL || 
								datatype == BRDK_JSON_UDINT_TO_BOOL || datatype == BRDK_JSON_BOOL_TO_DINT || datatype == BRDK_JSON_BOOL_TO_UDINT) {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							else quoteCnt++;
							pos++;
							break;
						case BRDK_STR_ASCII_COMMA: case BRDK_STR_ASCII_CLOSE_BRACE: pos++; run = false; break; /* , or } we are finished */
						case BRDK_STR_ASCII_t: case BRDK_STR_ASCII_r: case BRDK_STR_ASCII_u: case BRDK_STR_ASCII_e:
						case BRDK_STR_ASCII_f: case BRDK_STR_ASCII_a: case BRDK_STR_ASCII_l: case BRDK_STR_ASCII_s:
							if(datatype != BRDK_JSON_UDINT_TO_BOOL && datatype != BRDK_JSON_DINT_TO_BOOL) ((char*)str)[i++] = ((char*)pSource)[pos++];
							else {
								run = false; 
								pos = -3;	/* error illegal character */
							}
							break;
						
						case BRDK_STR_ASCII_0: case BRDK_STR_ASCII_1: 
							((char*)str)[i++] = ((char*)pSource)[pos++];
							break;
						default: run = false; pos = -3; break;	/* error illegal character */
					}
				}
				if(pos > -1) {
					((char*)str)[i] = BRDK_STR_ASCII_NULL;
					if(datatype == BRDK_JSON_BOOL_TO_DINT) {
						signed long* tmpVal = ((signed long*)pValue);
						if(brdkStrCmp((unsigned long)&str, (unsigned long)&"true") == 0) *tmpVal = true;
						else if(brdkStrCmp((unsigned long)&str, (unsigned long)&"false") == 0) *tmpVal = false;
						else pos = -3; break;	/* error illegal character */
					}
					else if(datatype == BRDK_JSON_BOOL_TO_UDINT) {
						unsigned long* tmpVal = ((unsigned long*)pValue);
						if(brdkStrCmp((unsigned long)&str, (unsigned long)&"true") == 0) *tmpVal = true;
						else if(brdkStrCmp((unsigned long)&str, (unsigned long)&"false") == 0) *tmpVal = false;
						else pos = -3; break;	/* error illegal character */
					}
					else {
						char* tmpVal = ((char*)pValue);
						if(brdkStrCmp((unsigned long)&str, (unsigned long)&"true") == 0) *tmpVal = true;
						else if(brdkStrCmp((unsigned long)&str, (unsigned long)&"1") == 0) *tmpVal = true;
						else if(brdkStrCmp((unsigned long)&str, (unsigned long)&"false") == 0) *tmpVal = false;
						else if(brdkStrCmp((unsigned long)&str, (unsigned long)&"0") == 0) *tmpVal = false;
						else pos = -3; break;	/* error illegal character */
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
