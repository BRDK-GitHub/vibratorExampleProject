
FUNCTION_BLOCK brdkOPCUAMethodOperate (*Wrapper function block for operating OPC UA method calls.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL; (*Enables the function block.*)
		name : STRING[255]; (*Name of the method to be operated.*)
		finish : BOOL; (*Command to finish the OPC UA method operation. THis is set after receiving an isCalled status.*)
	END_VAR
	VAR_OUTPUT
		state : brdk_opcua_method_op_state_typ; (*State of the method.*)
		errorID : DWORD; (*Error code in the event of error. See OPC UA StatusCode.*)
	END_VAR
	VAR
		internal : brdk_opcua_method_op_int_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK brdkOPCUAFireEvent (*Wrapper function block for fireing OPC UA events.*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		enable : BOOL; (*Enables the function block.*)
		instanceName : STRING[80]; (*Functioan block instance name.*)
		namespaceUri : ARRAY[0..BRDK_OPCUA_MAX_EVENT_NS] OF STRING[MAX_LENGTH_NAMESPACEURI]; (*Additional namepsace URI's. http://opcfoundation.org/UA/ and http://br-automation.com/OpcUa/PLC/ are defaults.*)
		sourceNode : UANodeID; (*SourceNode identifies the Node that the Event originated from. If the Event is not specific to a Node the NodeId is set to null or not assigned at all. Some subtypes of this BaseEventType may define additional rules for SourceNode.*)
		sourceName : STRING[255]; (*SourceName provides a description of the source of the Event. If the field is not assigned the default value will be set to the DisplayName of the source node.*)
		message : UALocalizedText; (*Event message.*)
		severity : UINT; (*Event severity. Must be between 1 and 1000.*)
		fireEvent : BOOL; (*Fire an event.*)
	END_VAR
	VAR_OUTPUT
		ready : BOOL; (*Ready to fire an event.*)
		errorID : DWORD; (*Error code in the event of error. See OPC UA StatusCode.*)
	END_VAR
	VAR
		internal : brdk_opcua_event_internal_typ; (*Internal variables.*)
	END_VAR
END_FUNCTION_BLOCK
