#include <brdkUpdate_func.h>

void brdkUpdateDistributeFTP(struct brdkUpdateDistributeFTP* inst) {
	brdk_update_dist_ftp_int_typ* this = (brdk_update_dist_ftp_int_typ*) &inst->internal;
	
	if(!inst->enable) {
		inst->status = ERR_FUB_ENABLE_FALSE;	
		this->state = 0;
	}
	else {
		switch(this->state) {
		
			case 0: /* check that the file device pointer is set */
				if(inst->pFileDevice != 0) {
					inst->status = ERR_OK;
					inst->ready = true;
					this->state = 100;
				}
				else {
					inst->status 	= BRDK_UPDATE_POINTER_ERROR;
					this->state 	= 999;
				}
				break;
		
			case 100: /* wait for command */
				if(inst->cmd.distributeUpdate || inst->cmd.checkUpdate) {
					inst->ready 						= false;
					inst->status 						= ERR_FUB_BUSY;
					this->brdkUpdateCheck_0.enable 		= false;
					brdkUpdateCheck(&this->brdkUpdateCheck_0);
					this->brdkUpdateCheck_0.enable 		= true;
					this->brdkUpdateCheck_0.pFileDevice	= inst->pFileDevice;
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
						brdkStrCpy((unsigned long)&inst->id,(unsigned long)&this->brdkUpdateCheck_0.id);
						brdkStrCpy((unsigned long)&inst->version,(unsigned long)&this->brdkUpdateCheck_0.version);
						inst->artransferFileSize = this->brdkUpdateCheck_0.artransferFileSize;
						if(inst->cmd.checkUpdate) {
							inst->cmd.checkUpdate	= false;
							inst->status 			= ERR_OK;
							inst->ready 			= true;
							this->state 			= 100;
						}
						else if(inst->cmd.distributeUpdate) {
							inst->cmd.distributeUpdate = false;
							this->cIdx = 0;						/* reset client idx */
							inst->updatePackagesSent = 0;		/* reset packages sent */
							if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pIPAddress)) {
								brdkStrCpy((unsigned long)&this->paramStr,(unsigned long)&"/PROTOCOL=ftp");
								brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /SIP=");
								brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pIPAddress);
								if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pUser)) {
									brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /USER=");
									brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pUser);
									if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pPassword)) {
										brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /PASSWORD=");
										brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pPassword);
									}
								}
								this->DevLink_0.enable = false;
								DevLink(&this->DevLink_0);
								this->DevLink_0.enable 	= true;
								this->DevLink_0.pDevice = (unsigned long)&BRDK_UPDATE_FTP_DEVICE_NAME;
								this->DevLink_0.pParam 	= (unsigned long)&this->paramStr;
								this->state 			= 120;
							}	
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
				
					default:
						inst->status = this->brdkUpdateCheck_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 		= false;
							inst->cmd.distributeUpdate 	= false;
							inst->cmd.checkUpdate 		= false;
							inst->status 				= ERR_OK;
							inst->ready 				= true;
							this->state 				= 100;
						}
						break;
				}
				break;
				
			case 120: /* create dev link for FTP */
				DevLink(&this->DevLink_0);
				switch(this->DevLink_0.status) {
				
					case ERR_OK:
						this->DirCopy_0.enable 		= false;
						DirCopy(&this->DirCopy_0);
						this->DirCopy_0.enable 		= true;
						this->DirCopy_0.pSrcDev 	= inst->pFileDevice;
						this->DirCopy_0.pSrcDir 	= (unsigned long)&this->brdkUpdateCheck_0.updateFolderPath;
						this->DirCopy_0.pDestDev 	= this->DevLink_0.pDevice;
						this->DirCopy_0.pDestDir 	= 0;
						this->DirCopy_0.option 		= fiOVERWRITE;
						this->state 				= 130;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status 				= this->DevLink_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 	= false;
							inst->status 			= ERR_OK;
							inst->ready 			= true;
							this->state 			= 100;
						}
						break;
				
				}
				break;
				
			case 130: /* copy update folder to ftp server */
				DirCopy(&this->DirCopy_0);
				switch(this->DirCopy_0.status) {
				
					case ERR_OK:
						this->FileCopy_0.enable 	= false;
						FileCopy(&this->FileCopy_0);
						this->FileCopy_0.enable 	= true;
						this->FileCopy_0.pSrcDev 	= this->DirCopy_0.pSrcDev;
						this->FileCopy_0.pSrc 		= (unsigned long)&BRDK_UPDATE_DEFAULT_FILE_NAME;
						this->FileCopy_0.pDestDev 	= this->DirCopy_0.pDestDev;
						this->FileCopy_0.pDest 		= this->FileCopy_0.pSrc;
						this->FileCopy_0.option 	= fiOVERWRITE;
						this->state 				= 140;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status 				= this->DirCopy_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 	= false;
							inst->status 			= ERR_OK;
							inst->ready 			= true;
							this->state 			= 100;
						}
						break;
				
				}
				break;
				
			case 140: /* copy file */
				FileCopy(&this->FileCopy_0);
				switch(this->FileCopy_0.status) {
				
					case ERR_OK:
						this->DevUnlink_0.enable 	= false;
						DevUnlink(&this->DevUnlink_0);
						this->DevUnlink_0.enable 	= true;
						this->DevUnlink_0.handle 	= this->DevLink_0.handle;
						this->state 				= 150;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status 				= this->FileCopy_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 	= false;
							inst->status 			= ERR_OK;
							inst->ready 			= true;
							this->state 			= 100;
						}
						break;
				
				}
				break;
		
			case 150: /* unlink file device */
				DevUnlink(&this->DevUnlink_0);
				switch(this->DevUnlink_0.status) {
				
					case ERR_OK:
						this->cIdx++;						/* reset client idx */
						inst->updatePackagesSent++;			/* Amount of packages sent	*/
						if(this->cIdx < BRDK_UPDATE_MAX_FTP_CLIENTS) {
							if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pIPAddress)) {
								brdkStrCpy((unsigned long)&this->paramStr,(unsigned long)&"/PROTOCOL=ftp");
								brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /SIP=");
								brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pIPAddress);
								if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pUser)) {
									brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /USER=");
									brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pUser);
									if(!brdkStrIsEmpty((unsigned long)&inst->client[this->cIdx].pPassword)) {
										brdkStrCat((unsigned long)&this->paramStr,(unsigned long)&" /PASSWORD=");
										brdkStrCat((unsigned long)&this->paramStr,inst->client[this->cIdx].pPassword);
									}
								}
								this->DevLink_0.enable = false;
								DevLink(&this->DevLink_0);
								this->DevLink_0.enable 	= true;
								this->DevLink_0.pDevice = (unsigned long)&BRDK_UPDATE_FTP_DEVICE_NAME;
								this->DevLink_0.pParam 	= (unsigned long)&this->paramStr;
								this->state 			= 120;
							}
							else {
								inst->status = ERR_OK;
								inst->ready = true;
								this->state = 100;
							}
						}
						else {
							inst->status = ERR_OK;
							inst->ready = true;
							this->state = 100;
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status 				= this->DevUnlink_0.status;
						if(inst->cmd.errorReset) {
							inst->cmd.errorReset 	= false;
							inst->status 			= ERR_OK;
							inst->ready 			= true;
							this->state 			= 100;
						}
						break;
				
				}
				break;
				
			case 200: /* delete update folder */
				brdkUpdateDelete(&this->brdkUpdateDelete_0);
				switch(this->brdkUpdateDelete_0.status) {
				
					case ERR_OK:
						inst->id[0] 		= 0;
						inst->version[0] 	= 0;
						inst->status 		= BRDK_UPDATE_NOT_FOUND;
						inst->status 		= ERR_OK;
						inst->ready 		= true;
						this->state 		= 100;
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
				
		}
	
	}
}
