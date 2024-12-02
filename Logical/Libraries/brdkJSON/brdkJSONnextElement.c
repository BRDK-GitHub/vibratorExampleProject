#include <brdkJSON_func.h>

enum brdk_json_find_typ brdkJSONnextElement(unsigned long pSource, unsigned long pPosition) {
	enum brdk_json_find_typ find = BRDK_JSON_SOURCE_END;
	signed long* pos = (signed long*)pPosition;
	unsigned char run = true;
	while(run) {
		switch(((char*)pSource)[*pos]) {
			case BRDK_STR_ASCII_NULL: find = BRDK_JSON_SOURCE_END; run = false; break;
			case BRDK_STR_ASCII_OPEN_BRACE: find = BRDK_JSON_OBJECT_START; run = false; break;
			case BRDK_STR_ASCII_CLOSE_BRACE: find = BRDK_JSON_OBJECT_END; run = false; break;
			case BRDK_STR_ASCII_OPEN_BRACKET: find = BRDK_JSON_ARRAY_START; run = false; break;
			case BRDK_STR_ASCII_COMMA: find = BRDK_JSON_ARRAY_ELEMENT; run = false; break;
			case BRDK_STR_ASCII_CLOSE_BRACKET: find = BRDK_JSON_ARRAY_END; run = false; break;
			case BRDK_STR_ASCII_COLON: find = BRDK_JSON_OBJECT_VALUE; run = false; break;
			default: *pos += 1; break;
		}
		
	}
	*pos += 1;
	if(((char*)pSource)[*pos] == BRDK_STR_ASCII_NULL) *pos = -1;
	return find;
}
