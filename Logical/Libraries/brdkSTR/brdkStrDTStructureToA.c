#include <brdkSTR_func.h>

signed long brdkStrDTStructureToA(unsigned long pDTStructure, unsigned long pString, unsigned char format) {
	/* format 0 = 2020-01-01 01:01:01.001 */
	/* format 1 = 2020-01-01 01:01:01 */
	/* format 2 = 2020-01-01 */
	/* format 3 = 01:01:01 */
	/* format 4 = 01:01:01.001 */
	DTStructure* dtStruct = (DTStructure*)pDTStructure;
	unsigned char pos = 0;
	if(format != 3 && format != 4) {
		brdkStrUdintToA(dtStruct->year,(unsigned long)&(((char*)pString)[0]),BRDK_STR_CONVERT_DECIMAL);
		((char*)pString)[4] = BRDK_STR_ASCII_HYPHEN;
		if(dtStruct->month < 10) {
			((char*)pString)[5] = BRDK_STR_ASCII_0;
			brdkStrUdintToA(dtStruct->month,(unsigned long)&(((char*)pString)[6]),BRDK_STR_CONVERT_DECIMAL);
		}
		else brdkStrUdintToA(dtStruct->month,(unsigned long)&(((char*)pString)[5]),BRDK_STR_CONVERT_DECIMAL);
		((char*)pString)[7] = BRDK_STR_ASCII_HYPHEN;
		if(dtStruct->day < 10) {
			((char*)pString)[8] = BRDK_STR_ASCII_0;
			brdkStrUdintToA(dtStruct->day,(unsigned long)&(((char*)pString)[9]),BRDK_STR_CONVERT_DECIMAL);
		}
		else brdkStrUdintToA(dtStruct->day,(unsigned long)&(((char*)pString)[8]),BRDK_STR_CONVERT_DECIMAL);
		if(format == 2) {
			((char*)pString)[10] = BRDK_STR_ASCII_NULL;
			return 10; 
		}
		((char*)pString)[10] = BRDK_STR_ASCII_SPACE;
		pos = 11;
	}
	if(dtStruct->hour < 10) {
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		brdkStrUdintToA(dtStruct->hour,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
	}
	else {
		brdkStrUdintToA(dtStruct->hour,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
		pos++;
	}
	((char*)pString)[pos++] = BRDK_STR_ASCII_COLON;
	if(dtStruct->minute < 10) {
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		brdkStrUdintToA(dtStruct->minute,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
	}
	else {
		brdkStrUdintToA(dtStruct->minute,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
		pos++;
	}
	((char*)pString)[pos++] = BRDK_STR_ASCII_COLON;
	if(dtStruct->second < 10) {
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		brdkStrUdintToA(dtStruct->second,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
	}
	else {
		brdkStrUdintToA(dtStruct->second,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
		pos++;
	}
	if(format == 1 || format == 3) {
		((char*)pString)[pos] = BRDK_STR_ASCII_NULL;
		return pos;
	}
	((char*)pString)[pos++] = BRDK_STR_ASCII_DOT;
	if(dtStruct->millisec < 10) {
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		brdkStrUdintToA(dtStruct->millisec,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
	}
	else if(dtStruct->millisec < 100) {
		((char*)pString)[pos++] = BRDK_STR_ASCII_0;
		brdkStrUdintToA(dtStruct->millisec,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
		pos++;
	}
	else {
		brdkStrUdintToA(dtStruct->millisec,(unsigned long)&(((char*)pString)[pos++]),BRDK_STR_CONVERT_DECIMAL);
		pos += 2;
	}
	if(format == 4) {
		((char*)pString)[pos] = BRDK_STR_ASCII_NULL;
		return pos;
	}
	((char*)pString)[pos] = BRDK_STR_ASCII_NULL;
	return pos; 
}
