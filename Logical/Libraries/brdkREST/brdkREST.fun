
FUNCTION_BLOCK brdkRESTClient (*REST client implementation.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pURL : UDINT := 0; (*String pointer to host URL.*)
		port : UINT := 0; (*Host port number. Default for http is 80, https is 443.*)
		method : brdk_rest_method_typ := BRDK_REST_GET; (*Method.*)
		contentType : brdk_rest_content_typ := BRDK_REST_HTML; (*Content type.*)
		parameters : ARRAY[0..BRDK_REST_PARAMS_MAX_SIZE] OF brdk_rest_client_params_typ; (*Parameters array.*)
		pRequestBody : UDINT := 0; (*String pointer to request body.*)
		requestBodyLength : UDINT := 0; (*Length of request body. If 0 then string length of pBody is used.*)
		requestBodyMaxSize : UDINT := 0; (*Max size of request body buffer area.*)
		pResponseBody : UDINT := 0; (*String pointer to response data.*)
		responseBodyMaxSize : UDINT := 0; (*Max size of response body buffer area.*)
	END_VAR
	VAR_OUTPUT
		status : UINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
		responseLength : UDINT := 0; (*Length of reponse data.*)
		responseContentType : brdk_rest_content_typ := BRDK_REST_HTML; (*Response content type.*)
		httpStatus : UINT := 0; (*HTTP status code.*)
	END_VAR
	VAR
		internal : brdk_rest_client_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkRESTServer (*REST server implementation.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pName : UDINT := 0; (*String pointer to the name of the service.*)
		protocol : brdk_rest_protocol_typ := BRDK_REST_HTTP; (*Protocol type.*)
		pRequestBody : UDINT := 0; (*String pointer to request body.*)
		requestBodyMaxLength : UDINT := 0; (*Max. length of the request body.*)
		pResponseBody : UDINT := 0; (*String pointer to response data.*)
		responseBodyLength : UDINT := 0; (*Length of response body. If 0 then string length of pBody is used.*)
		responseContentType : brdk_rest_content_typ := BRDK_REST_HTML; (*Response content type.*)
		responseAction : brdk_rest_response_action_typ := BRDK_REST_NO_RESPONSE; (*Response action.*)
		parameters : ARRAY[0..BRDK_REST_PARAMS_MAX_SIZE] OF brdk_rest_server_params_typ; (*Parameters array.*)
	END_VAR
	VAR_OUTPUT
		requestMethod : brdk_rest_method_typ := BRDK_REST_GET; (*Request method.*)
		requestLength : UDINT := 0; (*Length of request data.*)
		requestContentType : brdk_rest_content_typ := BRDK_REST_HTML; (*Request content type.*)
		status : UINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
		url : STRING[BRDK_REST_URL_MAX_SIZE] := ''; (*REST service URL for easy reading and distribution.*)
	END_VAR
	VAR
		internal : brdk_rest_server_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkRESTImgGW (*An image gateway. Gets an image from an URL and hosts a 64 based version of the image.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL := FALSE; (*Enables the function block.*)
		pURL : UDINT := 0; (*String pointer for the URL for the image.*)
		port : UINT := 0; (*Host port number. Default for http is 80, https is 443.*)
		pRawImgBuffer : UDINT := 0; (*Data buffer for the raw image.*)
		rawImgBufferSize : UDINT := 0; (*Size of the raw image buffer area.*)
		pName : UDINT := 0; (*String pointer to the name of the service.*)
		protocol : brdk_rest_protocol_typ := BRDK_REST_HTTP; (*Protocol type.*)
		parameters : ARRAY[0..BRDK_REST_PARAMS_MAX_SIZE] OF brdk_rest_client_params_typ; (*Parameters array.*)
		pEncodedImgBuffer : UDINT := 0; (*Data buffer for the encoded image.*)
		encodedImgBufferSize : UDINT := 0; (*Size of the encoded image buffer area.*)
	END_VAR
	VAR_OUTPUT
		status : UINT := ERR_FUB_ENABLE_FALSE; (*Status of the function block.*)
	END_VAR
	VAR
		internal : brdk_rest_imggw_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK
