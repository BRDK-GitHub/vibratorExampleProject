#include <brdkSTR_func.h>

signed long brdkStrDintLen(signed long value) {
	if(value < 10 && value > -10) return 1 + (value < 0);
	else if(value < 100 && value > -100) return 2 + (value < 0);
	else if(value < 1000 && value > -1000) return 3 + (value < 0);
	else if(value < 10000 && value > -10000) return 4 + (value < 0);
	else if(value < 100000 && value > -100000) return 5 + (value < 0);
	else if(value < 1000000 && value > -1000000) return 6 + (value < 0);
	else if(value < 10000000 && value > -10000000) return 7 + (value < 0);
	else if(value < 100000000 && value > -100000000) return 8 + (value < 0);
	else if(value < 1000000000 && value > -1000000000) return 9 + (value < 0);
	else return 10;
}
