#include <brdkUpdate_func.h>

signed long brdkUpdateCmpVersion(unsigned long pNewVersion, unsigned long pOldVersion) {
	unsigned long newIdx = 0, oldIdx = 0, newVal = 0, oldVal = 0, cnt = 0;
	char noZero;
	if(pNewVersion != 0 && pOldVersion != 0) {
		while(cnt < 3) {
			noZero = 0;
			while(((char*)pNewVersion)[newIdx] != 46 && ((char*)pNewVersion)[newIdx] != 0) {	/* look for a . */
				if((((char*)pNewVersion)[newIdx]) > 48) noZero = true;	/* make sure that first char is not a 0 */
				if(noZero) newVal += ((char*)pNewVersion)[newIdx];
				newIdx++;
			}
			newIdx++;
			noZero = 0;
			while(((char*)pOldVersion)[oldIdx] != 46 && ((char*)pOldVersion)[oldIdx] != 0) {	/* look for a . */
				if((((char*)pOldVersion)[oldIdx]) > 48) noZero = true;	/* make sure that first char is not a 0 */
				if(noZero) oldVal += ((char*)pOldVersion)[oldIdx];
				oldIdx++;
			}
			oldIdx++;
			if(newVal > oldVal) return 1;
			else if(newVal < oldVal) return -1;
			newVal = oldVal = 0;
			cnt++;
		}	
	}
	else return BRDK_UPDATE_POINTER_ERROR;
	return 0;
}
