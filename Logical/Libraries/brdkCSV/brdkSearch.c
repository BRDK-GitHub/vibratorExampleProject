
#include <bur/plctypes.h>
#include <string.h>

#ifdef __cplusplus
	extern "C"
	{
#endif
	#include "brdkCSV.h"
#ifdef __cplusplus
	};
#endif
/* TODO: Add your comment here */
plcbit brdkSearch(plcstring* line, unsigned short columnNum, unsigned short column, unsigned short row, plcstring* result)
{

	signed long idx = 0;
	unsigned long size = (row * columnNum) + column;	
	plcstring* tok;
//	char internal[100];
	
//	strcpy(internal, line);
	
	tok = strtok(line, ";");
   
	if(size == 0){
		strcpy(result, tok);
		return 1;
	}
	
	/* walk through other tokens */
	while( tok != NULL ) {
		tok = strtok(NULL, ";");
		idx++;
		if(idx >= size){
			strcpy(result, tok);
			return 1;
		}
	}

	return NULL;
}

