#ifndef BRDK_JSON_FUNCS
#define BRDK_JSON_FUNCS 1

#include <brdkJSON.h>
#include <bur/plctypes.h>

#ifdef __cplusplus
	extern "C"
	{
#endif

#ifdef __cplusplus
	};
#endif

#define false 0
#define true 1
#define NULL 0

unsigned long appendBOOL(char value, unsigned long pDestination, unsigned long position, unsigned long size);
unsigned long setValue(enum brdk_json_dt_typ datatype, unsigned long pValue, unsigned long str);
unsigned char getSize(enum brdk_json_dt_typ datatype);

#endif /* !BRDK_JSON_FUNCS */
