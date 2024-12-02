#include <brdkSTR_func.h>

signed long brdkStrAppendDintToA(signed long value, unsigned long pString, unsigned char base, signed long position) {
	signed long start,i,cnt=0;
	if(value < 0) {
		if(position > -1) start = position;
		else start = brdkStrLen(pString);
		
		brdkStrFill(pString,1,(unsigned long)&"-",start++);
		i = start;
		value *= -1;
		base = !base ? 10 : base;	/* make sure base is not 0 */
		while (value > 0) {
			unsigned long rem = value % base;
			unsigned char tmp = (rem > 9)? (rem-10) + BRDK_STR_ASCII_A : rem + BRDK_STR_ASCII_0;
			brdkStrFill(pString,1,(unsigned long)&tmp,i++);
	       	value = value/base;
			cnt++;
		}
		brdkStrReverse(pString,start,--i);
		if(position < 0) ((char*)pString)[start+cnt] = BRDK_STR_ASCII_NULL;
		return start+cnt+brdkStrLen(pString+start+cnt);
	}
	else return brdkStrAppendUdintToA(value,pString,base,position);
}
