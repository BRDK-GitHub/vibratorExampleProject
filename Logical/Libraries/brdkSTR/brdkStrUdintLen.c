#include <brdkSTR_func.h>

signed long brdkStrUdintLen(unsigned long value) {
	if(value < 10) return 1;
	else if(value < 100) return 2;
	else if(value < 1000) return 3;
	else if(value < 10000) return 4;
	else if(value < 100000) return 5;
	else if(value < 1000000) return 6;
	else if(value < 10000000) return 7;
	else if(value < 100000000) return 8;
	else if(value < 1000000000) return 9;
	else return 10;
}
