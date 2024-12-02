#include <brdkOPCUA_func.h>

void brdkOPCUAMethodOperate(struct brdkOPCUAMethodOperate* inst) {
	brdk_opcua_method_op_int_typ* this = (brdk_opcua_method_op_int_typ*)&inst->internal;
	if(inst->enable) {
		switch(this->state) {
			
			case 0:	/* checking that the name is different from empty */
				if(!brdkStrIsEmpty((unsigned long)inst->name)) {
					brdkStrCpy((unsigned long)&this->UaSrv_MethodOperate_0.MethodName,(unsigned long)inst->name);
					inst->state = BRDK_OPCUA_METHOD_WAIT_FOR_CALL;
					this->state = 10;
				}
				else inst->state = BRDK_OPCUA_METHOD_NO_NAME_SET;
				break;

			case 10: /* waiting for UaSrv_MethodOperate_0 to be done */
				this->UaSrv_MethodOperate_0.Execute = false;
				UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
				if(!this->UaSrv_MethodOperate_0.Done) {
					this->state = 11;
				}
				break;
				
			case 11:
				this->UaSrv_MethodOperate_0.Execute = !this->UaSrv_MethodOperate_0.Busy;
				this->UaSrv_MethodOperate_0.Action = UaMoa_CheckIsCalled;
				UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
				if(!this->UaSrv_MethodOperate_0.Error) {
					if(this->UaSrv_MethodOperate_0.Done) {
						inst->state = BRDK_OPCUA_METHOD_WAIT_FOR_CALL; // If FB done - we don't have an error anymore.
						if(this->UaSrv_MethodOperate_0.IsCalled) {
							inst->state = BRDK_OPCUA_METHOD_IS_CALLED;
							this->state = 20;
						}
						else {
							this->state = 10;
						}
					}
				}
				else {
					inst->state = BRDK_OPCUA_METHOD_ERROR;
					inst->errorID = this->UaSrv_MethodOperate_0.ErrorID;
				}
				break;

			case 20:	/* waiting for finish command */
				if(inst->finish) {
					inst->finish = false;
					this->UaSrv_MethodOperate_0.Execute = true;
					this->UaSrv_MethodOperate_0.Action = UaMoa_Finished;
					UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
					if(!this->UaSrv_MethodOperate_0.Error) {
						inst->state = BRDK_OPCUA_METHOD_FINISHING;
						if(this->UaSrv_MethodOperate_0.Done) {
							inst->state = BRDK_OPCUA_METHOD_WAIT_FOR_CALL;
							this->UaSrv_MethodOperate_0.Execute = false;
							UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
							this->state = 10;
						}
						else {
							this->state = 30;
						}
					}
					else {
						inst->state = BRDK_OPCUA_METHOD_ERROR;
						inst->errorID = this->UaSrv_MethodOperate_0.ErrorID;
					}
				}
				break;
				
			case 30: /* waiting for UaSrv_MethodOperate_0 to be done */
				UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
				if(!this->UaSrv_MethodOperate_0.Error) {
					if(this->UaSrv_MethodOperate_0.Done) {
						inst->state = BRDK_OPCUA_METHOD_WAIT_FOR_CALL;
						this->UaSrv_MethodOperate_0.Execute = false;
						UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
						this->state = 10;
					}
				}
				else {
					inst->state = BRDK_OPCUA_METHOD_ERROR;
					inst->errorID = this->UaSrv_MethodOperate_0.ErrorID;
				}
				break;
			
		}
	}
	else {
		this->UaSrv_MethodOperate_0.Execute = false;
		UaSrv_MethodOperate(&this->UaSrv_MethodOperate_0);
		inst->state = BRDK_OPCUA_METHOD_NOT_ENABLED;
	}
}
