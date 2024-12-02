
#include <bur/plctypes.h>
#include <sys_lib.h>
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
void brdkSimOutput(struct brdkSimOutput* inst)
{	
	if (!inst->enable && inst->internal.state > 0) {
		inst->internal.state = 0;
		inst->internal.pvAdr = 0;
		inst->internal.pvCheck = 0;
		inst->internal.pvLen = 0;
		inst->internal.pvStatus = 0;
		inst->internal.state = 0;	
	}
	
	switch (inst->internal.state) {
		case 0: //wait for enable
			inst->status.fbStatus = brdkSIM_NOT_ENABLED;
			inst->status.error = false;
			inst->status.errorCode = 0;
			
			if(inst->enable) {
				brsstrcpy((UDINT)inst->internal.pvCmpString, (UDINT) "");
				inst->internal.pvCheck = brsstrcmp((UDINT)inst->pvName, (UDINT)inst->internal.pvCmpString);
				if(inst->internal.pvCheck != 0) {
					inst->internal.state = 10;
				}
				else {
					inst->status.fbStatus = brdkSIM_ERROR;
					inst->status.error = true;
					inst->status.errorCode = 1000;
					inst->internal.state = 200;
				}
			}
			break;
		
		case 10: //get address of the pv
			inst->status.fbStatus = brdkSIM_BUSY;
			inst->internal.pvStatus = PV_xgetadr(&inst->pvName, &inst->internal.pvAdr, &inst->internal.pvLen);
		
			if(inst->internal.pvStatus != 0) {
				inst->status.fbStatus = brdkSIM_ERROR;
				inst->status.error = true;
				inst->status.errorCode = inst->internal.pvStatus;
				inst->internal.state = 200;
			}
			else {
				inst->internal.state = 20;
			}
			break;
		
		case 20: //check value
			inst->status.fbStatus = brdkSIM_RUNNING;
			brsmemcpy((UDINT)&inst->actValue, (UDINT)inst->internal.pvAdr, inst->internal.pvLen);
			break;
		
		case 200: //error
			break;
	}
}
