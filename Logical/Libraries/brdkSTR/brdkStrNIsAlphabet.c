#include <brdkSTR_func.h>

unsigned char brdkStrNIsAlphabet(unsigned long pString, unsigned long amount) {
	unsigned long len = 0;
	while(len < amount) if(!isAlphabet(((char*)pString)[len++])) return 0;
	return 1;
}
