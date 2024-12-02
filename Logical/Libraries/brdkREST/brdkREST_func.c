#include <brdkREST_func.h>

unsigned short getMethod(brdk_rest_method_typ method) {
	switch(method) {
		case BRDK_REST_GET: return httpMETHOD_GET;
		case BRDK_REST_POST: return httpMETHOD_POST;
		case BRDK_REST_PUT: return httpMETHOD_PUT;
		case BRDK_REST_DELETE: return httpMETHOD_DELETE;
	}
	return httpMETHOD_GET;
}

brdk_rest_method_typ setMethod(unsigned short method) {
	switch(method) {
		case httpMETHOD_GET: return BRDK_REST_GET;
		case httpMETHOD_POST: return BRDK_REST_POST;
		case httpMETHOD_PUT: return BRDK_REST_PUT;
		case httpMETHOD_DELETE: return BRDK_REST_DELETE;
	}
	return BRDK_REST_GET;
}

void setHttpStatus(brdk_rest_response_action_typ status, unsigned long pStr) {
	switch(status) {
		case BRDK_REST_200_OK: brdkStrCpy(pStr, (unsigned long)&"200 OK"); break;
		case BRDK_REST_401_UNAUTHORIZED: brdkStrCpy(pStr, (unsigned long)&"401 Unauthorized"); break;
		case BRDK_REST_403_FORBIDDEN: brdkStrCpy(pStr, (unsigned long)&"403 Forbidden"); break;
		case BRDK_REST_404_NOT_FOUND: brdkStrCpy(pStr, (unsigned long)&"404 Not Found"); break;
		case BRDK_REST_500_INT_SERVER_ERROR: brdkStrCpy(pStr, (unsigned long)&"500 Internal Server Error"); break;
		case BRDK_REST_501_NOT_IMPLEMENTED: brdkStrCpy(pStr, (unsigned long)&"501 Not Implemented"); break;
		case BRDK_REST_503_SRV_UNAVAILABLE: brdkStrCpy(pStr, (unsigned long)&"503 Service Unavailable"); break;
		default: brdkStrCpy(pStr, (unsigned long)&"400 Bad Request"); break;
	}
}

brdk_rest_content_typ findContentType(unsigned long pStr) {
	if(brdkStrSearch(pStr, (unsigned long)&"html") > -1) return BRDK_REST_HTML;
	else if(brdkStrSearch(pStr, (unsigned long)&"plain") > -1) return BRDK_REST_TEXT;
	else if(brdkStrSearch(pStr, (unsigned long)&"json") > -1) return BRDK_REST_JSON;
	else if(brdkStrSearch(pStr, (unsigned long)&"xml") > -1) return BRDK_REST_XML;
	else if(brdkStrSearch(pStr, (unsigned long)&"csv") > -1) return BRDK_REST_CSV;
	else if(brdkStrSearch(pStr, (unsigned long)&"css") > -1) return BRDK_REST_CSS;
	else if(brdkStrSearch(pStr, (unsigned long)&"java") > -1) return BRDK_REST_JAVASCRIPT;
	else if(brdkStrSearch(pStr, (unsigned long)&"jpeg") > -1) return BRDK_REST_JPEG;
	else if(brdkStrSearch(pStr, (unsigned long)&"gzip") > -1) return BRDK_REST_GZIP;
	else if(brdkStrSearch(pStr, (unsigned long)&"zip") > -1) return BRDK_REST_ZIP;
	else if(brdkStrSearch(pStr, (unsigned long)&"png") > -1) return BRDK_REST_PNG;
	else if(brdkStrSearch(pStr, (unsigned long)&"gif") > -1) return BRDK_REST_GIF;
	else if(brdkStrSearch(pStr, (unsigned long)&"bmp") > -1) return BRDK_REST_BMP;
	else if(brdkStrSearch(pStr, (unsigned long)&"jpg") > -1) return BRDK_REST_JPG;
	return BRDK_REST_NONE;
}

void setContentType(unsigned long pDestination, brdk_rest_content_typ type) {
	switch(type) {
		case BRDK_REST_NONE: brdkStrCpy(pDestination,(unsigned long)&""); break;
		case BRDK_REST_HTML: brdkStrCpy(pDestination,(unsigned long)&"text/html"); break;
		case BRDK_REST_TEXT: brdkStrCpy(pDestination,(unsigned long)&"text/plain"); break;
		case BRDK_REST_JSON: brdkStrCpy(pDestination,(unsigned long)&"application/json"); break;
		case BRDK_REST_XML: brdkStrCpy(pDestination,(unsigned long)&"application/xml"); break;
		case BRDK_REST_CSV: brdkStrCpy(pDestination,(unsigned long)&"text/csv"); break;
		case BRDK_REST_CSS: brdkStrCpy(pDestination,(unsigned long)&"text/css"); break;
		case BRDK_REST_JAVASCRIPT: brdkStrCpy(pDestination,(unsigned long)&"text/javascript"); break;
		case BRDK_REST_JPEG: brdkStrCpy(pDestination,(unsigned long)&"image/jpeg"); break;
		case BRDK_REST_GZIP: brdkStrCpy(pDestination,(unsigned long)&"application/gzip"); break;
		case BRDK_REST_ZIP: brdkStrCpy(pDestination,(unsigned long)&"application/zip"); break;
		case BRDK_REST_PNG: brdkStrCpy(pDestination,(unsigned long)&"image/png"); break;
		case BRDK_REST_GIF: brdkStrCpy(pDestination,(unsigned long)&"image/gif"); break;
		case BRDK_REST_BMP: brdkStrCpy(pDestination,(unsigned long)&"image/bmp"); break;
		case BRDK_REST_JPG: brdkStrCpy(pDestination,(unsigned long)&"image/jpg"); break;
	}
}

unsigned char validateServerParams(brdkRESTServer_typ* inst, brdk_rest_server_internal_typ* this) {
	unsigned char i,j,validate = true;
	brdkStrCat((unsigned long)&this->uri, (unsigned long)&"&");
	for(i=0; i <= BRDK_REST_PARAMS_MAX_SIZE; i++) {
		/* try to find in uri */
		if(inst->parameters[i].pKey != 0) {
			validate = false;
			switch(inst->parameters[i].from) {
			
				case BRDK_REST_PARAMETERS:
					validate = brdkStrSubStrSearch(inst->parameters[i].pValue,(unsigned long)&this->uri,inst->parameters[i].pKey,(unsigned long)&("&"), 1, true);
					break;
				
				case BRDK_REST_HEADER:
					for(j=0; j <= BRDK_REST_PARAMS_MAX_SIZE; j++) {
						if(brdkStrCmp(inst->parameters[i].pKey, (unsigned long)&this->httpRequestHeader.userLine[j].name) == 0) {
							validate = !brdkStrIsEmpty((unsigned long)&this->httpRequestHeader.userLine[j].value);
							if(validate) {
								brdkStrCpy(inst->parameters[i].pValue, (unsigned long)&this->httpRequestHeader.userLine[j].value);
								break;	
							}
						}
					}
					break;
					
				case BRDK_REST_BODY_JSON:
					switch(inst->parameters[i].datatype) {
					
						case BRDK_JSON_STRING_TO_STRING: case BRDK_JSON_DINT_TO_STRING: case BRDK_JSON_UDINT_TO_STRING: case BRDK_JSON_BOOL_TO_STRING:
							if(brdkJSONparseToString(inst->pRequestBody, inst->parameters[i].pKey, inst->parameters[i].pValue, inst->parameters[i].datatype, inst->requestBodyMaxLength, 0) > -1) {
								validate = true;
							}	
							break;
							
						default:
							if(brdkJSONparse(inst->pRequestBody, inst->parameters[i].pKey, inst->parameters[i].pValue , inst->parameters[i].datatype, 0) > -1) {
								validate = true;
							}
							break;
					
					}
					break;
			
			}
			if(!validate) break;
		
		}
		else break;
	}
	return validate;
}




