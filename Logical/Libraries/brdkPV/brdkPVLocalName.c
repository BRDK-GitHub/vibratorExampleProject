#include <brdkPV_func.h>

void brdkPVLocalVariable(struct brdkPVLocalVariable* this)
{
	char taskName[20];
	ST_name(0,(char*)&taskName,0);
	brdkStrCat((unsigned long)&taskName,(unsigned long)&":");
	unsigned short i = 0;
	unsigned long adr, length;
	this->status = 0;

	/* create the strings */
	for(;i < BRDK_PV_MAX_PV_NAMES; i++) {
		if(this->pPV[i] != 0) {
			brdkStrCpy((unsigned long)&this->lPV[i],(unsigned long)&taskName);
			brdkStrCat((unsigned long)&this->lPV[i],this->pPV[i]);
			this->status = PV_xgetadr((char*)&this->lPV[i],&adr,&length);
			/* check that the variable exists */
			if(this->status != 0) brdkStrCpy((unsigned long)&this->lPV[i],(unsigned long)&"PV not found. Check spelling");
		}
	}
}
