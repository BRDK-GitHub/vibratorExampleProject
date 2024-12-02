(********************************************************************
 * COPYRIGHT -- Bernecker + Rainer
 ********************************************************************
 * Library: BRDK_MC
 * File: dstoa.st
 * Author: olsenm
 * Created: February 20, 2012
 ********************************************************************
 * Implementation of library BRDK_MC
 ********************************************************************) 

 (* Converts an ENUM drive state to ascii *)
FUNCTION dstoa

	IF pString <> 0 THEN
	
		CASE driveState OF

			DISABLED: brsstrcpy(pString, ADR('DISABLED')); 
				
			STANDSTILL: brsstrcpy(pString, ADR('STANDSTILL'));
			
			HOMING: brsstrcpy(pString, ADR('HOMING'));
			
			CONTINOUS_MOTION: brsstrcpy(pString, ADR('CONTINOUS_MOTION'));
			
			DISCRETE_MOTION: brsstrcpy(pString, ADR('DISCRETE_MOTION'));
			
			SYNCHRONIZED_MOTION: brsstrcpy(pString, ADR('SYNCHRONIZED_MOTION'));
			
			STOPPING: brsstrcpy(pString, ADR('STOPPING'));
			
			ERROR_STOP: brsstrcpy(pString, ADR('ERROR_STOP'));
			
		END_CASE
		
		dstoa := 1;
		
	ELSE
		dstoa := 0;
	END_IF
	
END_FUNCTION