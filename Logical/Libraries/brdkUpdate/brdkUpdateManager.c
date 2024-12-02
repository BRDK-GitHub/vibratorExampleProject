#include <brdkUpdate_func.h>

void brdkUpdateManager(struct brdkUpdateManager* inst) {
	brdk_update_manager_internal_typ* this = (brdk_update_manager_internal_typ*)&inst->internal;
	
	if(!inst->enable) {
		inst->status = ERR_FUB_ENABLE_FALSE;	
		this->state = 0;
	}
	else {
		switch(this->state) {
			
			case 0: /* check that the file device pointer is set */
				inst->status = ERR_FUB_BUSY;
				if(inst->pFileDevice != 0) {
					this->ArProjectGetInfo_0.Execute = false;
					ArProjectGetInfo(&this->ArProjectGetInfo_0);
					this->ArProjectGetInfo_0.Execute = true;
					this->state = 10;
				}
				else {
					inst->status 	= BRDK_UPDATE_POINTER_ERROR;
					this->state 	= 999;
				}
				break;
			
			case 10: /* read the running id and version */
				ArProjectGetInfo(&this->ArProjectGetInfo_0);
				if(!this->ArProjectGetInfo_0.Error) {
					if(this->ArProjectGetInfo_0.Done) {
						brdkStrCpy((unsigned long)&inst->running.id,(unsigned long)&this->ArProjectGetInfo_0.ConfigurationID);
						brdkStrCpy((unsigned long)&inst->running.version,(unsigned long)&this->ArProjectGetInfo_0.ConfigurationVersion);
						inst->status = ERR_OK;
						inst->ready = true;
						this->state = 100;
					}
				}
				else {
					inst->status = this->ArProjectGetInfo_0.StatusID;
					if(inst->cmd.errorReset) {
						inst->cmd.errorReset = false;
						inst->status = ERR_OK;
						inst->ready = true;
						this->state = 100;
					}
				}	
				break;
				
			case 100: /* check for commands */
				if(inst->cmd.checkForUpdate || inst->cmd.update || inst->cmd.updateReboot) {
					inst->ready 						= false;
					inst->status 						= ERR_FUB_BUSY;
					this->brdkUpdateCheck_0.enable 		= false;
					brdkUpdateCheck(&this->brdkUpdateCheck_0);
					this->brdkUpdateCheck_0.enable 		= true;
					this->brdkUpdateCheck_0.pFileDevice = inst->pFileDevice;
					this->state 						= 110;
				}
				else if(inst->cmd.deleteUpdate) {
					inst->cmd.deleteUpdate 					= false;
					this->brdkUpdateDelete_0.enable			= false;
					brdkUpdateDelete(&this->brdkUpdateDelete_0);
					this->brdkUpdateDelete_0.enable 		= true;
					this->brdkUpdateDelete_0.pFileDevice 	= inst->pFileDevice;
					this->state 							= 200;
				}
				break; 
			
			case 110: /* wait for update to be read */
				brdkUpdateCheck(&this->brdkUpdateCheck_0);
				switch(this->brdkUpdateCheck_0.status) {
					
					case ERR_OK:
						if(inst->cmd.checkForUpdate) {
							inst->cmd.checkForUpdate				= false;
							brdkStrCpy((unsigned long)&inst->update.id,(unsigned long)&this->brdkUpdateCheck_0.id);
							brdkStrCpy((unsigned long)&inst->update.version,(unsigned long)&this->brdkUpdateCheck_0.version);
							inst->update.artransferFileSize = this->brdkUpdateCheck_0.artransferFileSize;
							inst->update.status = BRDK_UPDATE_NOT_FOUND;
							if(brdkStrCmp((unsigned long)&inst->update.id,(unsigned long)&inst->running.id) != 0) inst->update.status = BRDK_UPDATE_NO_ID_MATCH;
							this->versionCmp = brdkUpdateCmpVersion((unsigned long)&inst->update.version,(unsigned long)&inst->running.version);
							if(inst->update.status != BRDK_UPDATE_NO_ID_MATCH) {
								if(this->versionCmp > 0) inst->update.status = BRDK_UPDATE_VERSION_NEW_GREATER;
								else if(this->versionCmp < 0) inst->update.status = BRDK_UPDATE_VERSION_NEW_SMALLER;
								else inst->update.status = BRDK_UPDATE_VERSIONS_EQUAL;
							}
							inst->status 	= ERR_OK;
							inst->ready 	= true;
							this->state 	= 100;
						}
						else if(inst->cmd.update || inst->cmd.updateReboot) {
							inst->cmd.update 						= false;
							this->ArProjectInstallPackage_0.Execute = false;
							ArProjectInstallPackage(&this->ArProjectInstallPackage_0);
							this->ArProjectInstallPackage_0.Execute = true;
							brdkStrCpy((unsigned long)&this->ArProjectInstallPackage_0.DeviceName, inst->pFileDevice);
							brdkStrCpy((unsigned long)&this->ArProjectInstallPackage_0.FilePath, (unsigned long)&this->brdkUpdateCheck_0.pipFilePath);
							this->state 							= 300;
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
				
					default:
						inst->status = this->brdkUpdateCheck_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 		= false;
							inst->cmd.checkForUpdate 	= false;
							inst->cmd.update 			= false;
							inst->cmd.updateReboot		= false;
							inst->status 				= ERR_OK;
							inst->ready 				= true;
							this->state 				= 100;
						}
						break;
				}
				break;
				
			case 200: /* delete update folder */
				brdkUpdateDelete(&this->brdkUpdateDelete_0);
				switch(this->brdkUpdateDelete_0.status) {
				
					case ERR_OK:
						inst->update.id[0] 		= 0;
						inst->update.version[0] = 0;
						inst->update.status 	= BRDK_UPDATE_NOT_FOUND;
						inst->status 			= ERR_OK;
						inst->ready 			= true;
						this->state 			= 100;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->brdkUpdateDelete_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset = false;
							inst->status = ERR_OK;
							inst->ready = true;
							this->state = 100;
						}
						break;
				
				}
				break;
						
			case 300: /* install update package */
				ArProjectInstallPackage(&this->ArProjectInstallPackage_0);
				if(!this->ArProjectInstallPackage_0.Error) {
					if(this->ArProjectInstallPackage_0.Done) {
						if(!inst->cmd.updateReboot) {
							inst->cmd.checkForUpdate 	= true;
							this->state 				= 0;
						}
						else {
							inst->cmd.updateReboot = false;
							SYSreset(true,1);	/* warm restart */
						}
					}
				}
				else {
					inst->status = this->ArProjectInstallPackage_0.StatusID;
					if(inst->cmd.errorReset) {
						inst->cmd.errorReset = false;
						inst->status = ERR_OK;
						inst->ready = true;
						this->state = 100;
					}	
				}
				break;
			
			case 999: /* error state */
				if(inst->cmd.errorReset) {
					inst->cmd.errorReset 	= false;
					inst->cmd.updateReboot 	= false;
					inst->status 			= ERR_OK;
					inst->ready 			= true;
					this->state 			= 100;
				}
				break;
			
		}
		
	}
}
