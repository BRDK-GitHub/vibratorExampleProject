#include <brdkFile_func.h>

void brdkFileRead(struct brdkFileRead* inst) {
	brdk_file_read_internal_typ* this = (brdk_file_read_internal_typ*)&inst->internal;

	if(inst->enable) {
	
		switch(this->state) {
		
			case 0: /* initialize fb */
				inst->status = ERR_FUB_BUSY;
				this->FileOpen_0.enable 	= false;
				FileOpen(&this->FileOpen_0);
				this->FileOpen_0.enable 	= true;
				this->FileOpen_0.pDevice 	= inst->pFileDevice;
				this->FileOpen_0.pFile 		= inst->pFileName;
				this->FileOpen_0.mode 		= fiREAD_ONLY;
				this->state 				= 10;
				break;
				
			case 10: /* file open */
				FileOpen(&this->FileOpen_0);
				switch(this->FileOpen_0.status) { 
				
					case ERR_OK:
						if(inst->dataLength >= this->FileOpen_0.filelen+1) {	/* validate that we have enough space to read the file and a 0 */
							brdkStrMemClear(inst->pData,this->FileOpen_0.filelen+1); /* clear enough emeory to read the file */
							this->FileRead_0.enable 	= false;
							FileRead(&this->FileRead_0);
							this->FileRead_0.enable 	= true;
							this->FileRead_0.ident 		= this->FileOpen_0.ident;
							this->FileRead_0.offset 	= 0;
							this->FileRead_0.pDest 		= inst->pData;
							this->FileRead_0.len 		= this->FileOpen_0.filelen;
							this->state 				= 20;
						}
						else {
							inst->status = fiERR_SPACE;
							this->state = 40;
						}
						break;
						
					case ERR_FUB_BUSY:
						break;
						
					default:
						inst->status = this->FileOpen_0.status;
						break;
				
				
				}
				break;
				
			case 20: /* read the file */
				FileRead(&this->FileRead_0);
				switch(this->FileRead_0.status) {
					
					case ERR_OK:
						this->FileClose_0.enable 	= false;
						FileClose(&this->FileClose_0);
						this->FileClose_0.enable 	= true;
						this->FileClose_0.ident 	= this->FileOpen_0.ident;
						this->state 				= 30;
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status = this->FileRead_0.status;
						break;
	
				}
				break;
	
			case 30:
				FileClose(&this->FileClose_0);
				switch(this->FileClose_0.status) {
					
					case ERR_OK: case fiERR_FILE_NOT_OPENED:
						inst->status				= ERR_OK;
						this->state 				= 40;
						break;
	
					case ERR_FUB_BUSY: 
						break;
	
					default:
						inst->status = this->FileRead_0.status;
						break;
	
				}
				break;
	
			case 40:
				break;
				
		}
	}
	else {
		inst->status = ERR_FUB_ENABLE_FALSE;
		this->state = 0;	
	}
}
