#include <brdkSTR_func.h>

float brdkStrAToReal(unsigned long pString) {
	float value = 0.0, fraction = 0.1;
	signed long exponent = 0;
	unsigned char sign = 0;
	unsigned long i = 0;

	while (((char*)pString)[i] == BRDK_STR_ASCII_SPACE || ((char*)pString)[i] == BRDK_STR_ASCII_PLUS) i++;	/* Remove white spaces or + sign */
	if(((char*)pString)[i] == BRDK_STR_ASCII_HYPHEN) {
		sign = 1;
		i++;
	}
	/* integer section */
	while(isDigit(((char*)pString)[i])) { 
		value = (value * 10.0) + (((char*)pString)[i]-BRDK_STR_ASCII_0);	
		i++;
	}
	/* fraction section */
	if((((char*)pString)[i]) == BRDK_STR_ASCII_DOT) { 
		i++;
		while(isDigit(((char*)pString)[i])) { 
			value += (((char*)pString)[i]-BRDK_STR_ASCII_0) * fraction;
			fraction *= 0.1;
			i++;
		}
	}
	/* exponent section */
	if((((char*)pString)[i]) == BRDK_STR_ASCII_E || (((char*)pString)[i]) == BRDK_STR_ASCII_e) { 
		i++;
		exponent = brdkStrAToDint(pString+i,BRDK_STR_CONVERT_DECIMAL);
		while(exponent != 0) {
			if(exponent < 0) {
				value *= 0.1;
				exponent++;
			}
			else {
				value *= 10.0;
				exponent--;
			}
		}
	}
	
	if(sign) value *= -1.0;
	return (value);
}
