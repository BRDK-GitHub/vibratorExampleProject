#include <brdkREST_func.h>

void brdkRESTImgGW(struct brdkRESTImgGW* inst) {
	brdk_rest_imggw_internal_typ* this = (brdk_rest_imggw_internal_typ*)&inst->internal;

	if(inst->enable) {
	
		switch(this->state) {
		
			case 0: /* prepare the http client call */
				inst->status = ERR_FUB_BUSY;
				brdkStrMemClear(inst->pRawImgBuffer,inst->rawImgBufferSize);
				this->brdkRESTClient_0.enable 				= false;
				brdkRESTClient(&this->brdkRESTClient_0);
				this->brdkRESTClient_0.enable 				= true;
				this->brdkRESTClient_0.pURL 				= inst->pURL;
				this->brdkRESTClient_0.port 				= inst->port;
				this->brdkRESTClient_0.pResponseBody 		= inst->pRawImgBuffer;
				this->brdkRESTClient_0.responseBodyMaxSize 	= inst->rawImgBufferSize;
				brdkStrMemCpy((unsigned long)&this->brdkRESTClient_0.parameters,(unsigned long)&inst->parameters,sizeof(inst->parameters));
				this->state 								= 10;
				break;
				
			case 10: /* request for the image */
				brdkRESTClient(&this->brdkRESTClient_0);
				switch(this->brdkRESTClient_0.status) {
				
					case ERR_OK:
						brdkStrMemClear(inst->pEncodedImgBuffer,inst->encodedImgBufferSize);
						brdkStrCpy(inst->pEncodedImgBuffer,(unsigned long)&"<img src=\"data:image/");
						switch(this->brdkRESTClient_0.responseContentType) {
							case BRDK_REST_JPEG: brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"jpeg"); break;
							case BRDK_REST_PNG: brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"png"); break;
							case BRDK_REST_GIF: brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"gif"); break;
							case BRDK_REST_BMP: brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"bmp"); break;
							default: brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"jpg"); break;
						
						}
						brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&";base64,");
						this->httpEncodeBase64_0.enable 	= true;
						this->httpEncodeBase64_0.pSrc 		= this->brdkRESTClient_0.pResponseBody;
						this->httpEncodeBase64_0.srcLen 	= this->brdkRESTClient_0.responseLength;
						this->length 						= brdkStrLen(inst->pEncodedImgBuffer);
						this->httpEncodeBase64_0.pDest 		= inst->pEncodedImgBuffer+this->length;
						this->httpEncodeBase64_0.destSize 	= inst->encodedImgBufferSize-this->length;
						this->state 						= 20;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->brdkRESTClient_0.status;
						this->state = 999;
						break;
				
				}
				break;
				
			case 20: /* encode the raw image to base 64 */
				httpEncodeBase64(&this->httpEncodeBase64_0);
				switch(this->httpEncodeBase64_0.status) {
				
					case ERR_OK:
						brdkStrCat(inst->pEncodedImgBuffer,(unsigned long)&"\">");
						this->length += this->httpEncodeBase64_0.destLen + 2;
						inst->status = ERR_OK;
						this->state = 30;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->httpEncodeBase64_0.status;
						this->state = 999;
						break;
				
				}
				break;
				
		}	
		
		/* server state machine */
		switch(this->serverState) {
		
			case 0: /* prepare the server */
				this->brdkRESTServer_0.enable 				= true;
				this->brdkRESTServer_0.pName 				= inst->pName;
				this->brdkRESTServer_0.protocol 			= inst->protocol;
				this->brdkRESTServer_0.responseContentType 	= BRDK_REST_HTML;
				this->serverState 								= 10;
				break;
				
			case 10: /* wait for the call */
				switch(this->brdkRESTServer_0.status) {
				
					case ERR_OK:
						switch(this->state) {
						
							case 30:
								this->brdkRESTServer_0.pResponseBody 		= inst->pEncodedImgBuffer;
								this->brdkRESTServer_0.responseBodyLength 	= this->length;
								this->brdkRESTServer_0.responseAction 		= BRDK_REST_200_OK;
								break;
								
							default:
								this->brdkRESTServer_0.pResponseBody 		= 0;
								this->brdkRESTServer_0.responseBodyLength 	= 0;
								this->brdkRESTServer_0.responseAction 		= BRDK_REST_503_SRV_UNAVAILABLE;
								break;
						
						}
					
						
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->brdkRESTServer_0.status;
						this->serverState = 999;
						this->state = 999;
						break;
				
				
				}
				break;
		
		}
		brdkRESTServer(&this->brdkRESTServer_0);
	
	}
	else {
		inst->status 					= ERR_FUB_ENABLE_FALSE;
		this->state 					= 0;
		this->serverState 				= 0;
		this->brdkRESTServer_0.enable 	= false;
		brdkRESTServer(&this->brdkRESTServer_0);
		this->brdkRESTClient_0.enable 	= false;
		brdkRESTClient(&this->brdkRESTClient_0);
	}
}
