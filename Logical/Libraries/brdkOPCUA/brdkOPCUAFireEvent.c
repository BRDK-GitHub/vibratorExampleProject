#include <brdkOPCUA_func.h>

void brdkOPCUAFireEvent(struct brdkOPCUAFireEvent* inst) {
	brdk_opcua_event_internal_typ* this = (brdk_opcua_event_internal_typ*)&inst->internal;
	if(inst->enable) {
		switch(this->state) {
			
			case 0: /* setup get name space index */
				this->UaSrv_GetNamespaceIndex_0.Execute 		= true;
				brdkStrCpy((unsigned long)&(this->UaSrv_GetNamespaceIndex_0.NamespaceUri),(unsigned long)&("http://opcfoundation.org/UA/"));
				this->state = 10;
				break;
			
			case 10: /* waiting for namespace index */
				UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
				if(!this->UaSrv_GetNamespaceIndex_0.Error) {
					if(this->UaSrv_GetNamespaceIndex_0.Done) {
						this->opcNSidx = this->UaSrv_GetNamespaceIndex_0.NamespaceIndex;
						this->UaSrv_GetNamespaceIndex_0.Execute = false;
						UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
						this->UaSrv_GetNamespaceIndex_0.Execute = true;
						brdkStrCpy((unsigned long)&(this->UaSrv_GetNamespaceIndex_0.NamespaceUri),(unsigned long)&("http://br-automation.com/OpcUa/PLC/"));
						this->state = 20;
					}
				}
				else {
					inst->errorID = this->UaSrv_GetNamespaceIndex_0.ErrorID;
				}
				break;
				
			case 20: /* waiting for namespace index */
				UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
				if(!this->UaSrv_GetNamespaceIndex_0.Error) {
					if(this->UaSrv_GetNamespaceIndex_0.Done) {
						this->plcNSidx = this->UaSrv_GetNamespaceIndex_0.NamespaceIndex;
						this->UaSrv_GetNamespaceIndex_0.Execute = false;
						UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
						this->UaSrv_GetNamespaceIndex_0.Execute = true;
						brdkStrCpy((unsigned long)&(this->UaSrv_GetNamespaceIndex_0.NamespaceUri),(unsigned long)&("http://br-automation.com/OpcUa/PLC/PV/"));
						this->state = 30;
					}
				}
				else {
					inst->errorID = this->UaSrv_GetNamespaceIndex_0.ErrorID;
				}
				break;
			
			case 30: /* waiting for namespace index */
				UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
				if(!this->UaSrv_GetNamespaceIndex_0.Error) {
					if(this->UaSrv_GetNamespaceIndex_0.Done) {
						this->pvNSidx = this->UaSrv_GetNamespaceIndex_0.NamespaceIndex;
						this->UaSrv_GetNamespaceIndex_0.Execute = false;
						UaSrv_GetNamespaceIndex(&this->UaSrv_GetNamespaceIndex_0);
						this->UaSrv_FireEvent_0.EventFieldCount = 0;
						
						/* check if a source node should be added */
						if(!brdkStrIsEmpty((unsigned long)&inst->sourceNode.Identifier)) {
							switch(inst->sourceNode.NamespaceIndex) {
								case BRDK_OPCUA_EVENT_NS_OPCUA: inst->sourceNode.NamespaceIndex = this->opcNSidx; break;
								case BRDK_OPCUA_EVENT_NS_PV: inst->sourceNode.NamespaceIndex = this->pvNSidx; break;
								case BRDK_OPCUA_EVENT_NS_PLC: inst->sourceNode.NamespaceIndex = this->plcNSidx; break;
									
								default:
									//inst->sourceNode.NamespaceIndex = this->;
									break;
							
							}
							
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].BrowsePath,(unsigned long)&"/SourceNode");
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&inst->instanceName);
							brdkStrCat((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&".sourceNode");
							this->UaSrv_FireEvent_0.EventFieldCount++;
						}
						
						/* check if a source name should be added */
						if(!brdkStrIsEmpty((unsigned long)&inst->sourceName)) {
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].BrowsePath,(unsigned long)&"/SourceName");
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&inst->instanceName);
							brdkStrCat((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&".sourceName");
							this->UaSrv_FireEvent_0.EventFieldCount++;
						}
						
						/* check if a message should be added */
						if(!brdkStrIsEmpty((unsigned long)&inst->message.Text)) {
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].BrowsePath,(unsigned long)&"/Message");
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&inst->instanceName);
							brdkStrCat((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&".message");
							this->UaSrv_FireEvent_0.EventFieldCount++;
						}
						
						/* check is severity should be added */
						if(inst->severity > 0 && inst->severity < 1001) {
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].BrowsePath,(unsigned long)&"/Severity");
							brdkStrCpy((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&inst->instanceName);
							brdkStrCat((unsigned long)&this->eventFields[this->UaSrv_FireEvent_0.EventFieldCount].Variable,(unsigned long)&".severity");
							this->UaSrv_FireEvent_0.EventFieldCount++;
						}
							
						this->UaSrv_FireEvent_0.EventType.NamespaceIndex = this->opcNSidx;
						this->UaSrv_FireEvent_0.EventType.IdentifierType = UAIdentifierType_Numeric; 
						brdkStrCpy((unsigned long)&this->UaSrv_FireEvent_0.EventType.Identifier,(unsigned long)&"2041");
						this->UaSrv_FireEvent_0.EventFields = this->eventFields;
						inst->ready = true;
						this->state = 100;
					}
				}
				else {
					inst->errorID = this->UaSrv_GetNamespaceIndex_0.ErrorID;
				}
				break;	
				
			
			case 100:
				this->UaSrv_FireEvent_0.Execute = inst->fireEvent;
				UaSrv_FireEvent(&this->UaSrv_FireEvent_0);
				if(!this->UaSrv_FireEvent_0.Error) {
					if(this->UaSrv_FireEvent_0.Done) {
						inst->fireEvent = false;
						this->UaSrv_FireEvent_0.Execute = false;
						UaSrv_FireEvent(&this->UaSrv_FireEvent_0);
					}
				}
				break;
				
			
		}
	}
	else {
		inst->ready = false;
		this->UaSrv_FireEvent_0.Execute = false;
		UaSrv_FireEvent(&this->UaSrv_FireEvent_0);
	}
}
