
TYPE
	brdk_opcua_method_op_int_typ : 	STRUCT  (*Internal variables for brdkOPCUAMethodOperate function block.*)
		UaSrv_MethodOperate_0 : UaSrv_MethodOperate; (*UaSrv_MethodOperate.*)
		state : DINT; (*State.*)
	END_STRUCT;
	brdk_opcua_method_op_state_typ : 
		( (*Method state type.*)
		BRDK_OPCUA_METHOD_NOT_ENABLED := 0,
		BRDK_OPCUA_METHOD_ERROR := 1,
		BRDK_OPCUA_METHOD_WAIT_FOR_CALL := 2,
		BRDK_OPCUA_METHOD_IS_CALLED := 3,
		BRDK_OPCUA_METHOD_NO_NAME_SET := 4,
		BRDK_OPCUA_METHOD_FINISHING := 5
		);
	brdk_opcua_event_internal_typ : 	STRUCT  (*Internal variables for brdkOPCUAMethodOperate function block.*)
		UaSrv_GetNamespaceIndex_0 : UaSrv_GetNamespaceIndex; (*UaSrv_GetNamespaceIndex.*)
		UaSrv_FireEvent_0 : UaSrv_FireEvent; (*UaSrv_FireEvent.*)
		state : DINT; (*State.*)
		opcNSidx : UINT; (*Namespace index of OPC UA.*)
		pvNSidx : UINT; (*Namespace index of the PV.*)
		plcNSidx : UINT; (*Namespace index of the PLC.*)
		eventFields : ARRAY[0..4]OF UaSrv_FireEventFieldType; (*Event fields.*)
		eventFieldCnt : USINT; (*Event field count.*)
	END_STRUCT;
END_TYPE
