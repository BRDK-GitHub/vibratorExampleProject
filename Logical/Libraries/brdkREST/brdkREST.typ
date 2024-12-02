
TYPE
	brdk_rest_response_action_typ : 
		( (*Response action type.*)
		BRDK_REST_NO_RESPONSE := 0, (*No response set.*)
		BRDK_REST_200_OK := 200, (*HTTP status 200 OK.*)
		BRDK_REST_400_BAD_REQUEST := 400, (*HTTP status 400 Bad request.*)
		BRDK_REST_401_UNAUTHORIZED := 401, (*HTTP status 401 Unauthorized.*)
		BRDK_REST_403_FORBIDDEN := 403, (*HTTP status 403 Forbidden.*)
		BRDK_REST_404_NOT_FOUND := 404, (*HTTP status 404 Not found.*)
		BRDK_REST_500_INT_SERVER_ERROR := 500, (*HTTP status 500 Internal Server Error.*)
		BRDK_REST_501_NOT_IMPLEMENTED := 501, (*HTTP status 501 Not Implemented.*)
		BRDK_REST_503_SRV_UNAVAILABLE := 503, (*HTTP status 503 Service Unavailable.*)
		BRDK_REST_ABORT := 999 (*Send abort.*)
		);
	brdk_rest_protocol_typ : 
		( (*Protocol type.*)
		BRDK_REST_HTTP := 0, (*HTTP protocol.*)
		BRDK_REST_HTTPS := 1 (*HTTPS protocol.*)
		);
	brdk_rest_method_typ : 
		( (*Method type.*)
		BRDK_REST_GET := 0, (*Get method.*)
		BRDK_REST_POST := 1, (*Post method.*)
		BRDK_REST_PUT := 2, (*Put method.*)
		BRDK_REST_DELETE := 3 (*Delete method.*)
		);
	brdk_rest_client_internal_typ : 	STRUCT  (*Internal variables.*)
		state : DINT; (*Internal state.*)
		httpsClient_0 : httpsClient; (*httpsClient fb.*)
		httpClient_0 : httpClient; (*httpClient fb.*)
		httpRequestHeader : httpRequestHeader_t; (*httpRequestHeader_t structure.*)
		httpResponseHeader : httpResponseHeader_t; (*httpResponseHeader_t structure.*)
		uri : STRING[BRDK_REST_URI_STRING_MAX_SIZE]; (*URI string.*)
	END_STRUCT;
	brdk_rest_server_request_typ : 	STRUCT  (*Server request type.*)
		header : httpRequestHeader_t; (*Request header.*)
		pQuery : UDINT; (*Pointer to request query data.*)
		maxQuerySize : UDINT; (*Maximum size of query data.*)
		pBody : UDINT; (*Pointer to request body data.*)
		maxBodySize : UDINT; (*Maximum size of body data.*)
	END_STRUCT;
	brdk_rest_server_response_typ : 	STRUCT  (*Server response type.*)
		header : httpResponseHeader_t; (*Response header.*)
		pReponse : UDINT; (*Pointer to reponse data.*)
		length : UDINT; (*Length of reponse data.*)
	END_STRUCT;
	brdk_rest_server_internal_typ : 	STRUCT  (*Internal variables.*)
		state : DINT; (*Internal state.*)
		httpsService_0 : httpsService; (*httpsClient fb.*)
		httpService_0 : httpService; (*httpClient fb.*)
		httpRequestHeader : httpRequestHeader_t; (*httpRequestHeader_t structure.*)
		httpResponseHeader : httpResponseHeader_t; (*httpResponseHeader_t structure.*)
		uri : STRING[BRDK_REST_URI_STRING_MAX_SIZE]; (*URI string.*)
		CfgGetIPAddr_0 : CfgGetIPAddr; (*CfgGetIPAddr fb.*)
	END_STRUCT;
	brdk_rest_content_typ : 
		( (*Content types.*)
		BRDK_REST_NONE := 0, (*text/html*)
		BRDK_REST_HTML := 1, (*text/html*)
		BRDK_REST_TEXT := 2, (*text/plain*)
		BRDK_REST_JSON := 3, (*application/json*)
		BRDK_REST_XML := 4, (*application/xml*)
		BRDK_REST_CSV := 5, (*text/csv*)
		BRDK_REST_CSS := 6, (*text/css*)
		BRDK_REST_JAVASCRIPT := 7, (*text/javascript*)
		BRDK_REST_JPEG := 8, (*image/jpeg*)
		BRDK_REST_GZIP := 9, (*application/gzip*)
		BRDK_REST_ZIP := 10, (*application/zip*)
		BRDK_REST_PNG := 11, (*image/png*)
		BRDK_REST_GIF := 12, (*image/gif*)
		BRDK_REST_BMP := 13, (*image/bmp*)
		BRDK_REST_JPG := 14 (*image/jpg*)
		);
	brdk_rest_client_add_to_typ : 
		( (*Add to type.*)
		BRDK_REST_PARAMETERS := 0, (*Part of parameter query.*)
		BRDK_REST_HEADER := 1, (*Part of header.*)
		BRDK_REST_BODY_JSON := 2 (*Part of body in JSON format.*)
		);
	brdk_rest_client_params_typ : 	STRUCT  (*Parameters.*)
		addTo : brdk_rest_client_add_to_typ := BRDK_REST_PARAMETERS; (*Add to type.*)
		pKey : UDINT; (*String pointer to key.*)
		pValue : UDINT; (*Pointer to value.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_STRING_TO_STRING; (*Value datatype. Used for sending in JSON body format.*)
	END_STRUCT;
	brdk_rest_server_params_typ : 	STRUCT  (*Parameters.*)
		from : brdk_rest_client_add_to_typ := BRDK_REST_PARAMETERS; (*Add to type.*)
		pKey : UDINT; (*String pointer to key.*)
		pValue : UDINT; (*Pointer to value.*)
		datatype : brdk_json_dt_typ := BRDK_JSON_STRING_TO_STRING; (*Value datatype. Used for sending in JSON body format.*)
	END_STRUCT;
	brdk_rest_imggw_internal_typ : 	STRUCT  (*Internal variables.*)
		state : DINT := 0; (*Internal state.*)
		brdkRESTClient_0 : brdkRESTClient; (*brdkRESTClient.*)
		brdkRESTServer_0 : brdkRESTServer; (*brdkRESTServer.*)
		httpEncodeBase64_0 : httpEncodeBase64; (*httpEncodeBase64_0.*)
		serverState : DINT := 0; (*Internal server state.*)
		length : DINT := 0; (*Data length.*)
	END_STRUCT;
END_TYPE
