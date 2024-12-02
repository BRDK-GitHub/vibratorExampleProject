#include <brdkSTR_func.h>

static const float rounds[] = {
	0.5,				
	0.05,				
	0.005,				
	0.0005,				
	0.00005,			
	0.000005,			
	0.0000005,			
	0.00000005,			
	0.000000005,		
	0.0000000005,		
	0.00000000005		
};

signed long brdkStrRealToA(float value, unsigned long pString, unsigned char precision) {
	signed long i = 0;
	char tmpChar;
	unsigned long integer;
	if(precision > 10) precision = 10;
	if (value < 0) {
		value = -value;
		((char*)pString)[i++] = BRDK_STR_ASCII_HYPHEN;
	}

	if(precision) value += rounds[precision];

	/* handle integer section */
	integer = value;
	value -= integer;
   
	if(integer > 0) i += brdkStrUdintToA(integer,pString+i,BRDK_STR_CONVERT_DECIMAL);
	else ((char*)pString)[i++] = BRDK_STR_ASCII_0;

	/* handle decimal section */
	if(precision) {
		((char*)pString)[i++] = BRDK_STR_ASCII_DOT;

		while(precision--) {
			value *= 10.0;
			tmpChar = value;
			((char*)pString)[i++] = BRDK_STR_ASCII_0 + tmpChar;
			value -= tmpChar;
		}
	}
	
	((char*)pString)[i] = BRDK_STR_ASCII_NULL;
	return i;
}
