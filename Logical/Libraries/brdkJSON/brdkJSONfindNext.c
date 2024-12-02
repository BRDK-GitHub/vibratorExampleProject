#include <brdkJSON_func.h>

signed long brdkJSONfindNext(unsigned long pSource, enum brdk_json_find_typ find, unsigned long position) {
	unsigned char findChar;
	switch(find) {
		case BRDK_JSON_OBJECT_START: findChar = BRDK_STR_ASCII_OPEN_BRACE; break;
		case BRDK_JSON_OBJECT_END: findChar = BRDK_STR_ASCII_CLOSE_BRACE; break;
		case BRDK_JSON_ARRAY_START: findChar = BRDK_STR_ASCII_OPEN_BRACKET; break;
		case BRDK_JSON_ARRAY_ELEMENT: findChar = BRDK_STR_ASCII_COMMA; break;
		case BRDK_JSON_ARRAY_END: findChar = BRDK_STR_ASCII_CLOSE_BRACKET; break;
		case BRDK_JSON_OBJECT_VALUE: findChar = BRDK_STR_ASCII_COMMA; break;
		case BRDK_JSON_SOURCE_END: findChar = BRDK_STR_ASCII_NULL; break;
	}
	while(((char*)pSource)[position] != BRDK_STR_ASCII_NULL) {
		if(((char*)pSource)[position++] == findChar) {
			if(((char*)pSource)[position] != BRDK_STR_ASCII_NULL) return position;
			else return -2;
		}
	}
	return -1;
}

