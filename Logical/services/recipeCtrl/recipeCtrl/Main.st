
PROGRAM _INIT

	brdkOPCUAMethodOperate_CpyRecipe.name 		:= 'CopyRecipe';
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	brdkOPCUAMethodOperate_CpyRecipe(enable := TRUE);
	CASE brdkOPCUAMethodOperate_CpyRecipe.state OF
	
		BRDK_OPCUA_METHOD_IS_CALLED:
			IF method.copyRecipe.direction > 0 AND method.copyRecipe.direction < 3 THEN
				gFeederInterface.cmd.copyRecipe 		:= method.copyRecipe.direction;
				gMainInterface.cmd.copyRecipe 			:= method.copyRecipe.direction;
				gVibratorInterface[0].cmd.copyRecipe 	:= method.copyRecipe.direction;
				gVibratorInterface[1].cmd.copyRecipe 	:= method.copyRecipe.direction;
				gBeltInterface.cmd.copyRecipe 			:= method.copyRecipe.direction;
				gCapconInterface.cmd.copyRecipe 		:= method.copyRecipe.direction;
				gWingInterface.cmd.copyRecipe 			:= method.copyRecipe.direction;
				gRecipe.cmd.saveCurrent := TRUE; 		// save recipe to recipeCurrent.xml after changeover. 
			END_IF	
			
			brdkOPCUAMethodOperate_CpyRecipe.finish := TRUE;

	END_CASE
	 
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 brdkOPCUAMethodOperate_CpyRecipe(enable := FALSE);
END_PROGRAM

