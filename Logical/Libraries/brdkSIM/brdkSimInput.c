
#include <bur/plctypes.h>
#include <AsIO.h>
#include <AsBrStr.h>

#ifdef __cplusplus
	extern "C"
	{
#endif
	#include "brdkSIM.h"
#ifdef __cplusplus
	};
#endif

#define false 0
#define true 1

/* TODO: Add your comment here */
void brdkSimInput(struct brdkSimInput* inst)
{		
	if (!inst->enable && inst->internal.state > 0 && inst->internal.state < 50) {
		inst->internal.state = 50;	
	}
	
	switch (inst->internal.state) {
		case 0: //wait for enable force
			inst->status.fbStatus = brdkSIM_NOT_ENABLED;
			inst->status.error = false;
			inst->status.errorCode = 0;
			if (inst->enable) {
				inst->internal.state = 10;
			}
			break;
		
		case 10: //enable force
			inst->status.fbStatus = brdkSIM_BUSY;
			if (!inst->internal.AsIOEnableForcing_0.enable) {
				inst->internal.AsIOEnableForcing_0.enable = true;
				inst->internal.AsIOEnableForcing_0.pDatapoint = (UDINT)&inst->dpName;		// set pointer to the var name (address)
				inst->internal.state = 20;
			}
			break;
		
		case 20: //wait for AsIOEnableForcing_0 fb to be ready	
			if (inst->internal.AsIOEnableForcing_0.status == ERR_OK) {
				inst->internal.AsIOEnableForcing_0.enable = false;					// remember to set enable false so the fb is ready for the next dp
				AsIOEnableForcing(&inst->internal.AsIOEnableForcing_0);
				inst->internal.state = 30;
			}
			else if (inst->internal.AsIOEnableForcing_0.status != ERR_OK && inst->internal.AsIOEnableForcing_0.status != ERR_FUB_BUSY && inst->internal.AsIOEnableForcing_0.status != ERR_FUB_ENABLE_FALSE) {
				inst->status.fbStatus = brdkSIM_ERROR;
				inst->status.error = true;
				inst->status.errorCode = inst->internal.AsIOEnableForcing_0.status;
				inst->internal.state = 200;
			}
			break;
		
		case 30: //AsIOSetForceValue_0 fb use to control force value	
			inst->status.fbStatus = brdkSIM_RUNNING;
			inst->internal.AsIOSetForceValue_0.enable 		= true;
			inst->internal.AsIOSetForceValue_0.pDatapoint	= (UDINT)&inst->dpName;		// set pointer to the dp name (address)
			inst->internal.AsIOSetForceValue_0.value 		= inst->setValue;						// set the force value
			
			if (inst->internal.AsIOSetForceValue_0.status != ERR_OK && inst->internal.AsIOSetForceValue_0.status != ERR_FUB_BUSY && inst->internal.AsIOSetForceValue_0.status != ERR_FUB_ENABLE_FALSE) {
				inst->status.fbStatus = brdkSIM_ERROR;
				inst->status.error = true;
				inst->status.errorCode = inst->internal.AsIOSetForceValue_0.status;
				inst->internal.state = 200;
			}
			
			break;
		
		case 50: //set value to 0 before disable
			inst->status.fbStatus = brdkSIM_BUSY;
			if (inst->internal.AsIOSetForceValue_0.value != 0) {
				inst->internal.AsIOSetForceValue_0.enable 		= true;
				inst->internal.AsIOSetForceValue_0.pDatapoint	= (UDINT)&inst->dpName;		// set pointer to the dp name (address)
				inst->internal.AsIOSetForceValue_0.value 		= 0;									// set the force value
			
				if (inst->internal.AsIOSetForceValue_0.status != ERR_OK && inst->internal.AsIOSetForceValue_0.status != ERR_FUB_BUSY && inst->internal.AsIOSetForceValue_0.status != ERR_FUB_ENABLE_FALSE) {
					inst->status.fbStatus = brdkSIM_ERROR;
					inst->status.error = true;
					inst->status.errorCode = inst->internal.AsIOSetForceValue_0.status;
					inst->internal.state = 200;
				}
				else {
					inst->internal.state 	= 60;
				}
			}
			else {
				inst->internal.state 	= 60;
			}
			break;
			
		case 60: //wait for AsIODisableForcing_0 fb to be ready	
			inst->internal.AsIOSetForceValue_0.enable 		= false;
			inst->internal.AsIODisableForcing_0.enable 		= true;
			inst->internal.AsIODisableForcing_0.pDatapoint 	= (UDINT)&inst->dpName;		// set pointer to the dp name (address)
			AsIODisableForcing(&inst->internal.AsIODisableForcing_0);
			
			if (inst->internal.AsIODisableForcing_0.status == ERR_OK) {
				inst->internal.AsIODisableForcing_0.enable 	= false;						// remember to set enable false so the fb is ready for the next dp
				inst->internal.state = 0;
			}
			else if (inst->internal.AsIODisableForcing_0.status != ERR_OK && inst->internal.AsIODisableForcing_0.status != ERR_FUB_BUSY && inst->internal.AsIODisableForcing_0.status != ERR_FUB_ENABLE_FALSE) {
				inst->status.fbStatus = brdkSIM_ERROR;
				inst->status.error = true;
				inst->status.errorCode = inst->internal.AsIODisableForcing_0.status;
				inst->internal.state = 200;
			}
			break;
		
		case 200: //error
			inst->internal.AsIOEnableForcing_0.enable = false;
			inst->internal.AsIOSetForceValue_0.enable = false;
			inst->internal.AsIODisableForcing_0.enable 	= false;
			
			if (!inst->enable) {
				inst->status.error = false;
				inst->status.errorCode = 0;
				inst->internal.state 	= 0;
			}
	}
	
	AsIOEnableForcing(&inst->internal.AsIOEnableForcing_0);
	AsIOSetForceValue(&inst->internal.AsIOSetForceValue_0);
	AsIODisableForcing(&inst->internal.AsIODisableForcing_0);
}
