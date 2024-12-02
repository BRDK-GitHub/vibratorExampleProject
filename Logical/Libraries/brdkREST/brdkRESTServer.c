#include <brdkREST_func.h>

void brdkRESTServer(struct brdkRESTServer* inst) {
	brdk_rest_server_internal_typ* this = (brdk_rest_server_internal_typ*)&inst->internal;
	unsigned long i,j;
	unsigned char urlStart;
	
	if(inst->enable) {
		switch(this->state) {
		
			case 0:
				inst->status = ERR_FUB_BUSY;
				brdkStrMemClear((unsigned long)&inst->url, sizeof(inst->url));
				brdkStrCpy((unsigned long)&inst->url, (unsigned long)&"http");
				if(inst->protocol != BRDK_REST_HTTP) {
					brdkStrCat((unsigned long)&inst->url, (unsigned long)&"s://");
					urlStart 							= 8;
				}
				else {
					brdkStrCat((unsigned long)&inst->url, (unsigned long)&"://");
					urlStart 							= 7;
				}
				this->CfgGetIPAddr_0.enable 	= false;
				CfgGetIPAddr(&this->CfgGetIPAddr_0);
				this->CfgGetIPAddr_0.enable 	= true;
				this->CfgGetIPAddr_0.pIPAddr 	= (unsigned long)&inst->url[urlStart];
				if(!DiagCpuIsSimulated()) this->CfgGetIPAddr_0.pDevice	= (unsigned long)&"IF3";
				else this->CfgGetIPAddr_0.pDevice	= (unsigned long)&"IF2";
				this->CfgGetIPAddr_0.Len 		= 16;
				this->state						= 10;
				break;
			
			case 10:
				brdkStrCat((unsigned long)&inst->url, (unsigned long)&"192.168.2.11");
				this->state = 20;
				break;
			
		/*	case 10:
				CfgGetIPAddr(&this->CfgGetIPAddr_0);
				switch(this->CfgGetIPAddr_0.status) {
				
					case ERR_OK:
						this->state = 20;
						break;
				
					case ERR_FUB_BUSY:
						break;
				
					default:
						if(DiagCpuIsSimulated()) {
							if(inst->protocol != BRDK_REST_HTTP) brdkStrCpy((unsigned long)&inst->url, (unsigned long)&"https://127.0.0.1");
							else brdkStrCpy((unsigned long)&inst->url, (unsigned long)&"http://127.0.0.1");
						}
						this->state = 20;
						break;
						
				}
				break;
			*/
				
			case 20:
				brdkStrCat((unsigned long)&inst->url, (unsigned long)&"/");
				brdkStrCat((unsigned long)&inst->url, inst->pName);
				if(inst->protocol != BRDK_REST_HTTP) {
					this->httpsService_0.enable 			= false;
					httpsService(&this->httpsService_0);
					this->httpsService_0.enable 			= true;
					this->httpsService_0.send 				= false;
					this->httpsService_0.abort 				= false;
					this->httpsService_0.option 			= httpOPTION_HTTP_11 + httpOPTION_SERVICE_TYPE_NAME;;
					this->httpsService_0.pServiceName 		= inst->pName;
					this->httpsService_0.pUri 				= (unsigned long)&this->uri;
					this->httpsService_0.uriSize 			= sizeof(this->uri);
					this->httpsService_0.pRequestHeader 	= (unsigned long)&this->httpRequestHeader;
					this->httpsService_0.pRequestData 		= inst->pRequestBody;
					this->httpsService_0.requestDataSize 	= inst->requestBodyMaxLength;
					this->httpsService_0.pResponseHeader 	= (unsigned long)&this->httpResponseHeader;
					this->httpsService_0.pResponseData 		= inst->pResponseBody;
					if(inst->responseBodyLength == 0 && this->httpsService_0.pResponseData != 0) this->httpsService_0.responseDataLen = brdkStrLen(this->httpsService_0.pResponseData);
					else this->httpsService_0.responseDataLen = inst->responseBodyLength;
					this->state								= 200;
				}
				else {
					this->httpService_0.enable 			= false;
					httpService(&this->httpService_0);
					this->httpService_0.enable 			= true;
					this->httpService_0.send 			= false;
					this->httpService_0.abort 			= false;
					this->httpService_0.option 			= httpOPTION_HTTP_11 + httpOPTION_SERVICE_TYPE_NAME;
					this->httpService_0.pServiceName 	= inst->pName;
					this->httpService_0.pUri 			= (unsigned long)&this->uri;
					this->httpService_0.uriSize			= sizeof(this->uri);
					this->httpService_0.pRequestHeader 	= (unsigned long)&this->httpRequestHeader;
					this->httpService_0.pRequestData 	= inst->pRequestBody;
					this->httpService_0.requestDataSize = inst->requestBodyMaxLength;
					this->httpService_0.pResponseHeader = (unsigned long)&this->httpResponseHeader;
					this->httpService_0.pResponseData 	= inst->pResponseBody;
					if(inst->responseBodyLength == 0 && this->httpService_0.pResponseData != 0) this->httpService_0.responseDataLen = brdkStrLen(this->httpService_0.pResponseData);
					else this->httpService_0.responseDataLen = inst->responseBodyLength;
					this->state							= 100;
				}
				j = 0;
				for(i=0; i <= BRDK_REST_PARAMS_MAX_SIZE; i++) {
					if(inst->parameters[i].pKey != 0 && inst->parameters[i].from == BRDK_REST_HEADER) {
						brdkStrCpy((unsigned long)&this->httpRequestHeader.userLine[j++].name, inst->parameters[i].pKey);
					}
				}
				break;
				
				
			/* HTTP */	
			case 100: /* WAITING FOR INCOMMING CALL */
				this->httpService_0.pResponseData 	= inst->pResponseBody;
				if(inst->responseBodyLength == 0 && this->httpService_0.pResponseData != 0) this->httpService_0.responseDataLen = brdkStrLen(this->httpService_0.pResponseData);
				else this->httpService_0.responseDataLen = inst->responseBodyLength;
				httpService(&this->httpService_0);
				switch(this->httpService_0.status) {
				
					case ERR_OK:
						switch(this->httpService_0.phase) {
						
							case httpPHASE_RECEIVED:
								if(!validateServerParams(inst, this)) {
									setHttpStatus(BRDK_REST_400_BAD_REQUEST, (unsigned long)&this->httpResponseHeader.status);
									this->httpService_0.send = true;
								}
								else {
									inst->status = ERR_OK;
									this->state = 300;
								}
								break;
								
							default:
								this->httpService_0.send = false;
								break;
								
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->httpService_0.status;
						this->state = 999;
						break;
				
				}
				break;
			
			/* HTTPS */	
			case 200: /* WAITING FOR INCOMMING CALL */
				this->httpsService_0.pResponseData 		= inst->pResponseBody;
				if(inst->responseBodyLength == 0 && this->httpsService_0.pResponseData != 0) this->httpsService_0.responseDataLen = brdkStrLen(this->httpsService_0.pResponseData);
				else this->httpsService_0.responseDataLen = inst->responseBodyLength;
				httpsService(&this->httpsService_0);
				switch(this->httpsService_0.status) {
				
					case ERR_OK:
						switch(this->httpsService_0.phase) {
						
							case httpPHASE_RECEIVED:
								if(!validateServerParams(inst, this)) {
									setHttpStatus(BRDK_REST_400_BAD_REQUEST, (unsigned long)&this->httpResponseHeader.status);
									this->httpsService_0.send = true;
								}
								else {
									inst->status = ERR_OK;
									this->state = 300;
								}
								break;
								
							default:
								this->httpsService_0.send = false;
								break;
								
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->httpsService_0.status;
						this->state = 999;
						break;
				
				}
				break;
	
			/* waiting to send back reply */
			case 300:
				switch(inst->responseAction) {
				
					case BRDK_REST_NO_RESPONSE:
						break;
						
					case BRDK_REST_ABORT:
						inst->status = ERR_FUB_BUSY;
						if(inst->protocol != BRDK_REST_HTTP) {
							this->httpsService_0.abort = true;
							this->state = 200;
						}
						else {
							this->httpService_0.abort = true;
							this->state = 100;
						}
						break;
						
					default:
						inst->status = ERR_FUB_BUSY;
						brdkStrCpy((unsigned long)&this->httpResponseHeader.protocol,(unsigned long)&"HTTP/1.1");
						brdkStrCpy((unsigned long)&this->httpResponseHeader.connection,(unsigned long)&"keep-alive");
						setContentType((unsigned long)&this->httpResponseHeader.contentType, inst->responseContentType);
						setHttpStatus(inst->responseAction, (unsigned long)&this->httpResponseHeader.status);
						
						if(inst->protocol != BRDK_REST_HTTP) {
							if(inst->responseBodyLength == 0 && this->httpsService_0.pResponseData != 0) this->httpsService_0.responseDataLen = brdkStrLen(this->httpsService_0.pResponseData);
							else this->httpsService_0.responseDataLen = inst->responseBodyLength;
							this->httpResponseHeader.contentLength 	= this->httpsService_0.responseDataLen;
							
							this->httpsService_0.send = true;
							this->state = 200;
						
						}
						else {
							if(inst->responseBodyLength == 0 && this->httpService_0.pResponseData != 0) this->httpService_0.responseDataLen = brdkStrLen(this->httpService_0.pResponseData);
							else this->httpService_0.responseDataLen = inst->responseBodyLength;
							this->httpResponseHeader.contentLength 	= this->httpService_0.responseDataLen;
							
							this->httpService_0.send = true;
							this->state = 100;
						}
						inst->responseAction = BRDK_REST_NO_RESPONSE;
						break;
				
					
				}
				break;
		
			case 999: /* error */
				break;
		
		}
	}
	else {
		switch(this->state) {
		
			case 100: /* http */
				this->httpService_0.abort = true;
				httpService(&this->httpService_0);
				this->httpService_0.enable = false;
				httpService(&this->httpService_0);
				this->state = 0;
				break;
			
			case 200: /* https */
				this->httpsService_0.abort = true;
				httpsService(&this->httpsService_0);
				this->httpsService_0.enable = false;
				httpsService(&this->httpsService_0);
				this->state = 0;
				break;
		
			default:
				this->state = 0;
				inst->status = ERR_FUB_ENABLE_FALSE;
		
		}
	}
	
}
