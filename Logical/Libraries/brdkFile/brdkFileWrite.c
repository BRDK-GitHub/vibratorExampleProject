#include <brdkFile_func.h>

void brdkFileWrite(struct brdkFileWrite* inst) {
	brdk_file_write_internal_typ* this = (brdk_file_write_internal_typ*)&inst->internal;

	if(inst->enable) {
	
		switch(this->state) {
		
			case 0: /* initialize fb */
					inst->status 				= ERR_FUB_BUSY;
					this->FileCreate_0.enable 	= false;
					FileCreate(&this->FileCreate_0);
					this->FileCreate_0.enable 	= true;
					this->FileCreate_0.pDevice 	= inst->pFileDevice;
					this->FileCreate_0.pFile 	= inst->pFileName;
					this->state 				= 10;
				break;
	
			case 10: /* create file */
				FileCreate(&this->FileCreate_0);
				switch(this->FileCreate_0.status) {
	
					case ERR_OK:
						this->FileWrite_0.enable 	= false;
						FileWrite(&this->FileWrite_0);
						this->FileWrite_0.enable 	= true;
						this->FileWrite_0.ident 	= this->FileCreate_0.ident;
						this->FileWrite_0.offset 	= 0;
						this->FileWrite_0.pSrc 		= inst->pData;
						this->FileWrite_0.len 		= inst->dataLength != 0 ? inst->dataLength : brdkStrLen(inst->pData);
						this->state 				= 40;					
						break;

					case fiERR_EXIST:
						if(!inst->overwrite) {
							this->FileOpen_0.enable 	= false;
							FileOpen(&this->FileOpen_0);
							this->FileOpen_0.enable 	= true;
							this->FileOpen_0.pDevice 	= inst->pFileDevice;
							this->FileOpen_0.pFile 		= inst->pFileName;
							this->FileOpen_0.mode 		= fiWRITE_ONLY;
							this->state 				= 20;
						}
						else {
							this->FileDelete_0.enable 	= false;
							FileDelete(&this->FileDelete_0);
							this->FileDelete_0.enable 	= true;
							this->FileDelete_0.pDevice 	= inst->pFileDevice;
							this->FileDelete_0.pName 	= inst->pFileName;
							this->state 				= 30;
						}
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status 				= this->FileCreate_0.status;
						break;
	
				}
				break;
	
			case 20: /* file open */
				FileOpen(&this->FileOpen_0);
				switch(this->FileOpen_0.status) {
	
					case ERR_OK:
						this->FileWrite_0.enable 	= false;
						FileWrite(&this->FileWrite_0);
						this->FileWrite_0.enable 	= true;
						this->FileWrite_0.ident 	= this->FileCreate_0.ident;
						this->FileWrite_0.offset 	= 0;
						this->FileWrite_0.pSrc 		= inst->pData;
						this->FileWrite_0.len 		= inst->dataLength != 0 ? inst->dataLength : brdkStrLen(inst->pData);
						this->state 				= 40;	
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status 				= this->FileOpen_0.status;
						break;
	
				}
				break;
	
			case 30:
				FileDelete(&this->FileDelete_0);
				switch(this->FileDelete_0.status) {
					
					case ERR_OK: case fiERR_FILE_NOT_FOUND: 
						this->FileCreate_0.enable 	= false;
						FileCreate(&this->FileCreate_0);
						this->FileCreate_0.enable 	= true;
						this->FileCreate_0.pDevice 	= inst->pFileDevice;
						this->FileCreate_0.pFile 	= inst->pFileName;
						this->state 				= 10;
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status 				= this->FileDelete_0.status;
						break;
	
				}
				break;
	
			case 40:
				FileWrite(&this->FileWrite_0);
				switch(this->FileWrite_0.status) {
					
					case ERR_OK:
						this->FileClose_0.enable 	= false;
						FileClose(&this->FileClose_0);
						this->FileClose_0.enable 	= true;
						this->FileClose_0.ident 	= this->FileWrite_0.ident;
						this->state 				= 50;
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status 				= this->FileWrite_0.status;
						break;
	
				}
				break;
	
			case 50:
				FileClose(&this->FileClose_0);
				switch(this->FileClose_0.status) {
					
					case ERR_OK:	case fiERR_FILE_NOT_OPENED:
						inst->status 	= ERR_OK;
						this->state 	= 60;
						break;
	
					case ERR_FUB_BUSY: break;
	
					default:
						inst->status 				= this->FileClose_0.status;
						break;
	
				}
				break;
	
			case 60:
				break;
	
		}
	}
	else {
		inst->status = ERR_FUB_ENABLE_FALSE;
		this->state = 0;
	}
}
