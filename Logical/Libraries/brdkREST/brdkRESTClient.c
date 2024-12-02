#include <brdkREST_func.h>

void brdkRESTClient(struct brdkRESTClient* inst) {
	brdk_rest_client_internal_typ* this = (brdk_rest_client_internal_typ*)&inst->internal;	
	signed long startPos;
	unsigned long i, j, init;
	unsigned char questionAdded;
	
	if(inst->enable) {
	
		switch(this->state) {
	
			case 0:	/* setup httpClient fb */	
				inst->status 			= ERR_FUB_BUSY;
				inst->httpStatus 		= 0;
				inst->responseLength 	= 0;
				startPos = brdkStrSearch(inst->pURL,(unsigned long)&"://");
				if(startPos > -1) startPos += 3;
				else startPos = 0;	
				
				i = 0;
				brdkStrCpy((unsigned long)&this->uri,(unsigned long)&"");
				brdkStrMemClear((unsigned long)&this->httpRequestHeader.host,sizeof(this->httpRequestHeader.host));
				while(((char*)inst->pURL)[startPos] != BRDK_STR_ASCII_FRONT_SLASH && ((char*)inst->pURL)[startPos] != BRDK_STR_ASCII_NULL) {
					((char*)this->httpRequestHeader.host)[i++] = ((char*)inst->pURL)[startPos++];
				}
				((char*)this->httpRequestHeader.host)[i] = BRDK_STR_ASCII_NULL;
				i = 0;
				while(((char*)inst->pURL)[startPos] != BRDK_STR_ASCII_NULL) {
					this->uri[i++] = ((char*)inst->pURL)[startPos++];
				}
				this->uri[i] = BRDK_STR_ASCII_NULL;
				
				/* setup request header */
				brdkStrCpy((unsigned long)&this->httpRequestHeader.protocol,(unsigned long)&"HTTP/1.1");
				brdkStrCpy((unsigned long)&this->httpRequestHeader.connection,(unsigned long)&"keep-alive");
				setContentType((unsigned long)&this->httpRequestHeader.contentType, inst->contentType);
				
				questionAdded = false;
				j = 0;
				init = true;
				startPos = 0;
				for(i = 0; i <= BRDK_REST_PARAMS_MAX_SIZE; i++) {
					if(inst->parameters[i].pKey != 0) {
						switch(inst->parameters[i].addTo) {
						
							case BRDK_REST_PARAMETERS:
								if(!questionAdded) {
									questionAdded = true;
									brdkStrCat((unsigned long)&this->uri,(unsigned long)&"?");
								}
								else brdkStrCat((unsigned long)&this->uri,(unsigned long)&"&");
								brdkStrCat((unsigned long)&this->uri, inst->parameters[i].pKey);
								brdkStrCat((unsigned long)&this->uri,(unsigned long)&"=");
								brdkStrCat((unsigned long)&this->uri, inst->parameters[i].pValue);
								break;
						
							case BRDK_REST_HEADER:
								brdkStrCpy((unsigned long)&this->httpRequestHeader.userLine[j].name, inst->parameters[i].pKey);
								brdkStrCpy((unsigned long)&this->httpRequestHeader.userLine[j++].value, inst->parameters[i].pValue);
								break;
								
							case BRDK_REST_BODY_JSON:
								if(inst->pRequestBody != 0 && inst->requestBodyMaxSize > 0) {
									if(init) {
										init = false;
										brdkStrMemClear(inst->pRequestBody,inst->requestBodyMaxSize);
									}
									startPos = brdkJSONstringify(inst->pRequestBody, inst->parameters[i].pKey, inst->parameters[i].pValue, inst->parameters[i].datatype, inst->requestBodyMaxSize, startPos);
								}
								else {
									inst->status = httpERR_BUFFER_SIZE;
									this->state = 999;
								}
								break;
								
						}
						
					}
					else break;
				}
				if(this->state != 999) {	
					if(((char*)inst->pURL)[4] == BRDK_STR_ASCII_s) { /* https */
						this->httpsClient_0.enable 				= false;
						httpsClient(&this->httpsClient_0);
						this->httpsClient_0.enable 				= true;
						this->httpsClient_0.pRequestHeader 		= (unsigned long)&this->httpRequestHeader;
						this->httpsClient_0.pResponseHeader 	= (unsigned long)&this->httpResponseHeader;
						this->httpsClient_0.pRequestData		= inst->pRequestBody;
						if(inst->requestBodyLength == 0 && this->httpsClient_0.pRequestData != 0) this->httpsClient_0.requestDataLen = brdkStrLen(this->httpsClient_0.pRequestData);
						else this->httpsClient_0.requestDataLen = inst->requestBodyLength;
						this->httpRequestHeader.contentLength 	= this->httpsClient_0.requestDataLen;
						this->httpsClient_0.pResponseData		= inst->pResponseBody;
						this->httpsClient_0.responseDataSize 	= inst->responseBodyMaxSize;
						this->httpsClient_0.pHost	 			= (unsigned long)&this->httpRequestHeader.host;
						this->httpsClient_0.pUri				= (unsigned long)&this->uri;
						
						
						this->httpsClient_0.option 				= httpOPTION_HTTP_11;	/* always use HTTP/1.1 */
						this->httpsClient_0.method				= getMethod(inst->method);
						this->httpsClient_0.send 				= true;
						this->state								= 200;
					}
					else {	/* http */
						this->httpClient_0.enable 			= false;
						httpClient(&this->httpClient_0);
						this->httpClient_0.enable 			= true;
						this->httpClient_0.pRequestHeader 	= (unsigned long)&this->httpRequestHeader;
						this->httpClient_0.pResponseHeader 	= (unsigned long)&this->httpResponseHeader;
						this->httpClient_0.pRequestData		= inst->pRequestBody;
						if(inst->requestBodyLength == 0 && this->httpClient_0.pRequestData != 0) this->httpClient_0.requestDataLen = brdkStrLen(this->httpClient_0.pRequestData);
						else this->httpClient_0.requestDataLen = inst->requestBodyLength;
						this->httpRequestHeader.contentLength 	= this->httpClient_0.requestDataLen;
						this->httpClient_0.pResponseData	= inst->pResponseBody;
						this->httpClient_0.responseDataSize = inst->responseBodyMaxSize;
						this->httpClient_0.pHost 			= (unsigned long)&this->httpRequestHeader.host;
						this->httpClient_0.hostPort 		= inst->port;
						this->httpClient_0.pUri				= (unsigned long)&this->uri;
						this->httpClient_0.option 			= httpOPTION_HTTP_11;	/* always use HTTP/1.1 */
						this->httpClient_0.method			= getMethod(inst->method);
						this->httpClient_0.send 			= true;
						this->state							= 100;
					}
				}
				break;
				
			case 100:	/* http */
				httpClient(&this->httpClient_0);
				switch(this->httpClient_0.status) {
				
					case ERR_OK:
						inst->status 				= ERR_OK;
						inst->httpStatus 			= this->httpClient_0.httpStatus;
						inst->responseLength 		= this->httpClient_0.responseDataLen;
						inst->responseContentType 	= findContentType((unsigned long)&this->httpResponseHeader.contentType);
						this->state 				= 300;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->httpsClient_0.status;
						this->state = 999;
						break;
				
				}
				break;
				
				
			case 200:	/* https */
				httpsClient(&this->httpsClient_0);
				switch(this->httpsClient_0.status) {
				
					case ERR_OK:
						inst->status 				= ERR_OK;
						inst->httpStatus 			= this->httpsClient_0.httpStatus;
						inst->responseLength 		= this->httpsClient_0.responseDataLen;
						inst->responseContentType 	= findContentType((unsigned long)&this->httpResponseHeader.contentType);
						this->state 				= 300;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->httpsClient_0.status;
						this->state = 999;
						break;
				
				}
				break;
				
			case 300: /* done - flip enable to make a new request */
				break;
			
			case 999: /* error */
				break;
		
		}
		
	}
	else {
		switch(this->state) {
		
			case 100: /* http */
				this->httpClient_0.abort = true;
				httpClient(&this->httpClient_0);
				this->httpClient_0.enable = false;
				httpClient(&this->httpClient_0);
				this->state = 0;
				break;
			
			case 200: /* https */
				this->httpsClient_0.abort = true;
				httpsClient(&this->httpsClient_0);
				this->httpsClient_0.enable = false;
				httpsClient(&this->httpsClient_0);
				this->state = 0;
				break;
		
			default:
				this->state = 0;
				inst->status = ERR_FUB_ENABLE_FALSE;
		
		}
	}
}
