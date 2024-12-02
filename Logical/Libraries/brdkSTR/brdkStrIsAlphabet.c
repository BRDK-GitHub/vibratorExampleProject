#include <brdkSTR_func.h>

unsigned char brdkStrIsAlphabet(unsigned long pString) {
	unsigned long len = 0;
	while(((char*)pString)[len]) if(!isAlphabet(((char*)pString)[len++])) return 0;
	return 1;
}
