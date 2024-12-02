#include <brdkSTR_func.h>

signed long brdkStrUdintToA(unsigned long value, unsigned long pString, unsigned char base) {
	signed long len = 0;
	if (value != 0) {
		((char*)pString)[0] = 0;
		base = !base ? 10 : base;	/* make sure base is not 0 */
		while (value > 0) {
			unsigned long rem = value % base;
	       	((char*)pString)[len++] = (rem > 9)? (rem-10) + BRDK_STR_ASCII_A : rem + BRDK_STR_ASCII_0;
	       	value = value/base;
		}
		((char*)pString)[len] = BRDK_STR_ASCII_NULL;	
		brdkStrReverse(pString,0,-1);
	}
	else {
		((char*)pString)[0] = BRDK_STR_ASCII_0;
		((char*)pString)[1] = BRDK_STR_ASCII_NULL;
		len = 1;
	}
	return len;
}
