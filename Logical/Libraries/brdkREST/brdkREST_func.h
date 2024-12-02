#ifndef BRDK_REST_FUNCS
#define BRDK_REST_FUNCS 1

#include <brdkREST.h>
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

unsigned short getMethod(brdk_rest_method_typ method);
brdk_rest_method_typ setMethod(unsigned short method);
brdk_rest_content_typ findContentType(unsigned long pStr);
void setContentType(unsigned long pDestination, brdk_rest_content_typ type);
void setHttpStatus(brdk_rest_response_action_typ status, unsigned long pStr);
unsigned char validateServerParams(brdkRESTServer_typ* inst, brdk_rest_server_internal_typ* this);

#endif /* !BRDK_REST_FUNCS */
