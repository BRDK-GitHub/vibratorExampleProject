#include <brdkSTR_func.h>

unsigned char brdkStrIsDigit(unsigned long pString) {
	unsigned long len = 0;
	while(((char*)pString)[len]) if(!isDigit(((char*)pString)[len++])) return 0;
	return 1;
}


