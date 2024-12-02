#include <brdkUpdate_func.h>

void brdkUpdateDelete(struct brdkUpdateDelete* inst) {
	brdk_update_delete_internal_typ* this = (brdk_update_delete_internal_typ*)&inst->internal;	

	if(!inst->enable) {
		inst->status = ERR_FUB_ENABLE_FALSE;	
		this->state = 0;
	}
	else {
	
		switch(this->state) {
		
			case 0: /* check that all pointers are set */
				inst->status = ERR_FUB_BUSY;
				if(inst->pFileDevice != 0) {
					inst->status 						= ERR_FUB_BUSY;
					this->brdkUpdateCheck_0.enable 		= false;
					brdkUpdateCheck(&this->brdkUpdateCheck_0);
					this->brdkUpdateCheck_0.enable 		= true;
					this->brdkUpdateCheck_0.pFileDevice = inst->pFileDevice;
					this->state 						= 10;
				}
				else {
					inst->status 	= BRDK_UPDATE_POINTER_ERROR;
					this->state 	= 999;
				}
				break;
				
			case 10:
				brdkUpdateCheck(&this->brdkUpdateCheck_0);
				switch(this->brdkUpdateCheck_0.status) {
					
					case ERR_OK:
						this->DirDeleteEx_0.enable = false;
						DirDeleteEx(&this->DirDeleteEx_0);
						this->DirDeleteEx_0.enable 	= true;
						this->DirDeleteEx_0.pDevice = inst->pFileDevice;
						this->DirDeleteEx_0.pName 	= (unsigned long)&this->brdkUpdateCheck_0.updateFolderPath;
						this->state 				= 20;
						break;
						
					case ERR_FUB_BUSY:
						break;
				
					default:
						inst->status = this->brdkUpdateCheck_0.status;
						break;
				}
				break;
				
			case 20: /* delete update folder */
				DirDeleteEx(&this->DirDeleteEx_0);
				switch(this->DirDeleteEx_0.status) {
				
					case ERR_OK:
						this->FileDelete_0.enable = false;
						FileDelete(&this->FileDelete_0);
						this->FileDelete_0.enable 	= true;
						this->FileDelete_0.pDevice 	= inst->pFileDevice;
						this->FileDelete_0.pName 	= (unsigned long)&BRDK_UPDATE_DEFAULT_FILE_NAME;
						this->state 				= 30;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->DirDeleteEx_0.status;
						break;
				
				}
				break;
				
			case 30: /* delete update file */
				FileDelete(&this->FileDelete_0);
				switch(this->FileDelete_0.status) {
				
					case ERR_OK:
						inst->status 	= ERR_OK;
						this->state 	= 40;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->FileDelete_0.status;
						break;
				
				}
				break;
				
			case 40: /* done */
				break;
			 	
		}			
	}
}
