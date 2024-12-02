
#include <bur/plctypes.h>
#ifdef __cplusplus
	extern "C"
	{
#endif
	#include "legoSTR.h"
#ifdef __cplusplus
	};
#endif
/* Outputs an item string */
void legoSTRItemString(struct legoSTRItemString* inst) {
	legoSTRItem_internal* this = &inst->internal;
	
	if(inst->trigger) {
		inst->trigger = 0;

		switch(inst->value) {

			case 0 ... 9:
				if(this->length < MAX_ITEM_SIZE) {
					inst->item[this->length] = 0x30 + inst->value;
					this->length++;
				}
				break;

			case 20:	/* BACKSPACE */
				if(this->length > 0) {
					inst->item[this->length-1] = 0;
					this->length--;
				}
				break;

			case 30:	/* CLEAR */
				while(this->length > 0) {
					inst->item[this->length-1] = 0;
					this->length--;
				}
				break;

			default:
				break;


		}
		
	}
}
