#include <brdkUpdate_func.h>

void brdkUpdateCheck(struct brdkUpdateCheck* inst) {
	brdk_update_check_internal_typ* this = (brdk_update_check_internal_typ*)&inst->internal;	

	if(!inst->enable) {
		inst->status = ERR_FUB_ENABLE_FALSE;	
		this->state = 0;
	}
	else {
	
		switch(this->state) {
		
			case 0: /* check that all pointers are set */
				inst->status = ERR_FUB_BUSY;
				if(inst->pFileDevice != 0) {
					this->simulation = DiagCpuIsARsim();
					this->brdkFileRead_0.enable 		= false;
					brdkFileRead(&this->brdkFileRead_0);
					this->brdkFileRead_0.enable 		= true;
					this->brdkFileRead_0.pFileDevice 	= inst->pFileDevice;
					this->brdkFileRead_0.pFileName 		= (unsigned long)&BRDK_UPDATE_DEFAULT_FILE_NAME;
					this->brdkFileRead_0.pData 			= (unsigned long)&this->buffer;
					this->brdkFileRead_0.dataLength 	= sizeof(this->buffer);
					this->state 						= 10;
				}
				else {
					inst->status 	= BRDK_UPDATE_POINTER_ERROR;
					this->state 	= 999;
				}
				break;
			
			case 10: /* wait for file to be read */
				brdkFileRead(&this->brdkFileRead_0);
				switch(this->brdkFileRead_0.status) {
				
					case ERR_OK:
						/* find Path= */
						if(!brdkStrSubStrSearch((unsigned long)&inst->pipFilePath,(unsigned long)&this->buffer,(unsigned long)&"Path",(unsigned long)&"\"",2,true)) {
							inst->status = BRDK_UPDATE_PIP_FILE_ERROR;
							this->state = 999;
						}
						else {
							this->position = brdkStrSearch((unsigned long)&inst->pipFilePath, (unsigned long)&"/");
							if(this->position < 0) {
								inst->status = BRDK_UPDATE_PIP_FILE_ERROR;
								this->state = 999;
							}
							else {
								brdkStrMemClear((unsigned long)&inst->updateFolderPath,sizeof(inst->updateFolderPath));
								brdkStrMemCpy((unsigned long)&inst->updateFolderPath, (unsigned long)&inst->pipFilePath, this->position);
								if(!this->simulation) {
									this->ArProjectGetPackageInfo_0.Execute = false;
									ArProjectGetPackageInfo(&this->ArProjectGetPackageInfo_0);
									brdkStrCpy((unsigned long)&this->ArProjectGetPackageInfo_0.DeviceName, inst->pFileDevice);
									brdkStrCpy((unsigned long)&this->ArProjectGetPackageInfo_0.FilePath, (unsigned long)&inst->pipFilePath);
									this->ArProjectGetPackageInfo_0.Execute = true;
									this->state 							= 20;
								}
								else {	/* ArProjectGetPackageInfo_0 does not work in simulation :-( we will just read the file our self ;-) */
									this->brdkFileRead_0.enable 		= false;
									brdkFileRead(&this->brdkFileRead_0);
									this->brdkFileRead_0.enable 		= true;
									this->brdkFileRead_0.pFileDevice 	= inst->pFileDevice;
									this->brdkFileRead_0.pFileName 		= (unsigned long)&inst->pipFilePath;
									this->brdkFileRead_0.pData 			= (unsigned long)&this->buffer;
									this->brdkFileRead_0.dataLength 	= sizeof(this->buffer);
									this->state 						= 30;
								}
							}
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
				
					default:
						inst->status = this->brdkFileRead_0.status;
						break;
				}
				break;
			
			case 20: /* read update package info */
				ArProjectGetPackageInfo(&this->ArProjectGetPackageInfo_0);
				if(!this->ArProjectGetPackageInfo_0.Error) {
					if(this->ArProjectGetPackageInfo_0.Done) {
						brdkStrCpy((unsigned long)&inst->id,(unsigned long)&this->ArProjectGetPackageInfo_0.ConfigurationID);
						brdkStrCpy((unsigned long)&inst->version,(unsigned long)&this->ArProjectGetPackageInfo_0.ConfigurationVersion);
						
						this->FileInfo_0.enable = false;
						FileInfo(&this->FileInfo_0);
						this->FileInfo_0.enable = true;
						this->FileInfo_0.pDevice = inst->pFileDevice;
						brdkStrMemClear((unsigned long)&inst->artransferFilePath,sizeof(inst->artransferFilePath));
						brdkStrMemCpy((unsigned long)&inst->artransferFilePath,(unsigned long)&inst->updateFolderPath,sizeof(inst->updateFolderPath));
						brdkStrCat((unsigned long)&inst->artransferFilePath,(unsigned long)&BRDK_UPDATE_AR_TRANSFER_PATH);
						this->FileInfo_0.pName = (unsigned long)&inst->artransferFilePath;
						this->FileInfo_0.pInfo = (unsigned long)&this->updateFileInfo;
						this->state 	= 25;
					}
				}
				else {
					inst->status = this->ArProjectGetPackageInfo_0.StatusID;
				}
				break;
			
			case 25: /* Read file size of the binary update file "artransfer.br" */
				FileInfo(&this->FileInfo_0);
				switch(this->FileInfo_0.status){
				
					case ERR_OK:
						inst->artransferFileSize = this->updateFileInfo.size;
						inst->status = ERR_OK;
						this->state = 100;
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->FileInfo_0.status;
						break;
				
				}
				break;
			
				
			case 30: /* file open pipconfig.xml NB! only for simulation !!! */
				brdkFileRead(&this->brdkFileRead_0);
				switch(this->brdkFileRead_0.status) {
				
					case ERR_OK:
						/* find configuration ID e.g. <ConfigId>brdkUpdate_Config1</ConfigId> */
						if(!brdkStrSubStrSearch((unsigned long)&inst->id,(unsigned long)&this->buffer,(unsigned long)&"ConfigId",(unsigned long)&"<",1,true)) {
							inst->status = BRDK_UPDATE_PIP_FILE_ERROR;
							this->state = 999;
						}
						else {
							/* find configuration version e.g. <ConfigVersion>1.0.1</ConfigVersion> */
							if(!brdkStrSubStrSearch((unsigned long)&inst->version,(unsigned long)&this->buffer,(unsigned long)&"ConfigVersion",(unsigned long)&"<",1,true)) {
								inst->status = BRDK_UPDATE_PIP_FILE_ERROR;
								this->state = 999;
							}
							else {
								inst->status 	= ERR_OK;
								this->state 	= 100;
							}
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
				
					default:
						inst->status = this->brdkFileRead_0.status;
						break;
				}
				break;
				
			case 100:
				break;
		
		}
	}
}
