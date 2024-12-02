ACTION producing:
	
	CASE em.state OF

		STATE_STOPPED:
			interface.status.ready 		:= FALSE;
			em.cmd.sc 					:= TRUE;
			em.cmd.reset 				:= TRUE;
	
		STATE_IDLE:
			em.cmd.start := em.cmd.sc := TRUE;

		STATE_EXECUTE:
		
			
			CASE em.substate OF

				
				0:
					em.description := 'waiting for cassette to arrive';

					this.time.elapsed := 0;
					this.time.maximum := interface.parameter.cassetteDetectTime;
					IF NOT(this.hw.di_cassetteReady) THEN //casetteReady=FALSE means cassette is ready - Signal active low
						em.substate := 10;
					END_IF
					
				10:
					em.description := ' waiting for ready signal high in detect time';					
					
					IF NOT(this.hw.di_cassetteReady) THEN //Cassette ready signal must still be FALSE
						this.time.elapsed	:= this.time.elapsed + em.status.cycleTime; //Casette signal must be stable for detect time (Works like a filter?)
						IF this.time.elapsed >= this.time.maximum THEN 
							interface.status.ready 	:= TRUE;
							em.substate := 30;
						END_IF
					ELSE //Casette is no longer present
						em.substate := 0;
					END_IF
				
				30:
					em.description := 'waiting for start command';

					interface.status.ready := TRUE;
					
					IF interface.cmd.start <> interface.status.startAck THEN
						interface.status.ready 	:= FALSE;
						interface.status.dosing := FALSE;
						em.substate := 40;
					ELSIF interface.cmd.dosing AND NOT gBottomFlapInterface.status.approvedPortion AND NOT gBottomFlapInterface.status.neighbourDisappeared THEN
						interface.status.ready := FALSE;
						interface.status.dosing := TRUE;
						interface.status.startAck := interface.cmd.start - 1;
						interface.status.syncAck := interface.cmd.start - 1;
						em.substate := 40;
					ELSIF gMainInterface.line.bypassCassette AND this.hw.di_neighbourIsDosing THEN
						em.substate := 200;
					END_IF
					
				40:
					em.description := 'Wait for cassetteQueue to be free';
					
					IF this.hw.di_cassetteQueue THEN
						em.substate := 50;
					END_IF
					
				50:
					em.description := 'request to release cassette with other CM';
					
					IF gBottomFlapInterface.status.neighbourWaiting AND NOT this.hw.di_neighbourIsDosing AND NOT gBottomFlapInterface.status.approvedPortion THEN
						this.CassetteSync_0.Cancel := TRUE;
						this.CassetteSync_0.Request := FALSE;
					ELSE
						this.CassetteSync_0.Cancel := FALSE;
						this.CassetteSync_0.Request := TRUE;
					END_IF
					
					IF this.CassetteSync_0.Approved THEN
						this.CassetteSync_0.Request := FALSE;
						interface.status.syncAck := interface.cmd.start;
						em.substate := 70;
					ELSIF this.CassetteSync_0.CancelApproved THEN
						this.CassetteSync_0.Request := FALSE;
						this.CassetteSync_0.Cancel := FALSE;
						interface.status.syncAck := interface.cmd.start;
						interface.status.startAck := interface.cmd.start;
						em.substate := 30;
					END_IF

				70:
					em.description := 'waiting for cassette to leave sensor';

					this.hw.do_cassetteRelease := TRUE;
					
					IF this.hw.di_cassetteReady THEN
						this.time.elapsed := 0;
						this.time.maximum := interface.parameter.releaseTime;
						em.substate := 80;
					END_IF
					
				80:
					em.description := 'waiting for release time';

					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					IF this.time.elapsed >= this.time.maximum THEN
						this.hw.do_cassetteRelease 			:= FALSE;
						
						this.cassetteCounter := this.cassetteCounter + 1;
						interface.status.startAck := interface.cmd.start;
						em.substate := 0;
					END_IF
				
				200:
					em.description := 'Wait for cassetteQueue to be free';
					
					IF this.hw.di_cassetteQueue THEN
						em.substate := 210;
					END_IF
				
				210:
					em.description := 'waiting for cassette to leave sensor';

					this.hw.do_cassetteRelease := TRUE;
					
					IF this.hw.di_cassetteReady THEN
						this.time.elapsed := 0;
						this.time.maximum := interface.parameter.releaseTime;
						em.substate := 220;
					END_IF
				
				220:
					em.description := 'waiting for release time';

					this.time.elapsed := this.time.elapsed + em.status.cycleTime;
					IF this.time.elapsed >= this.time.maximum THEN
						this.hw.do_cassetteRelease 			:= FALSE;
						
						em.substate := 230;
					END_IF
				
				230:
					em.description := 'waiting for cassette to arrive';

					this.time.elapsed := 0;
					this.time.maximum := interface.parameter.cassetteDetectTime;
					IF NOT(this.hw.di_cassetteReady) THEN //casetteReady=FALSE means cassette is ready - Signal active low
						em.substate := 240;
					END_IF
					
				240:
					em.description := 'waiting for ready signal high in detect time';					
					
					IF NOT(this.hw.di_cassetteReady) THEN //Cassette ready signal must still be FALSE
						this.time.elapsed	:= this.time.elapsed + em.status.cycleTime; //Casette signal must be stable for detect time (Works like a filter?)
						IF this.time.elapsed >= this.time.maximum THEN 
							
							IF gMainInterface.line.bypassCassette AND this.hw.di_neighbourIsDosing THEN
								em.substate := 200;
							ELSE
								em.substate := 30;
							END_IF
						END_IF
					ELSE //Casette is no longer present
						em.substate := 230;
					END_IF
					
			END_CASE
			
			IF em.substate = 0 OR em.substate = 10 THEN
				this.statistics.waitForCassette := this.statistics.waitForCassette + (em.status.cycleTime / 1000);
			END_IF
			
			IF em.substate = 40 THEN
				this.statistics.cassetteQueue := this.statistics.cassetteQueue + (em.status.cycleTime / 1000);
			END_IF
			
			IF em.substate = 20 OR em.substate = 30 THEN
				this.statistics.waitForPortion := this.statistics.waitForPortion + (em.status.cycleTime / 1000);
			END_IF
			
			IF em.substate = 50 THEN
				this.statistics.waitForNeighbour := this.statistics.waitForNeighbour + (em.status.cycleTime / 1000);
			END_IF
			
			IF em.substate = 70 OR em.substate = 80 THEN
				this.statistics.realeaseCassette := this.statistics.realeaseCassette + (em.status.cycleTime / 1000);
			END_IF
			
		STATE_STOPPING,STATE_ABORTING,STATE_SUSPENDING:
			em.description 						:= 'stop all movement';
			this.hmi.status 					:= 1;
			interface.status.ready 				:= FALSE;
			this.hw.do_cassetteRelease 			:= FALSE;
			em.cmd.sc							:= TRUE;
			this.CassetteSync_0.Request 		:= FALSE;
			
		STATE_ABORTED, STATE_SUSPENDED:
			this.hmi.status 					:= 2;
		
			em.cmd.clear := em.state = STATE_ABORTED;
			em.cmd.start := em.state = STATE_SUSPENDED;
			em.cmd.sc := TRUE;

			
		STATE_CLEARING, STATE_UNSUSPENDING:
			brsmemset(ADR(this.alarm), 0, SIZEOF(this.alarm));
			
			em.cmd.sc := TRUE;
		
		ELSE
			em.cmd.sc := TRUE;
			
	END_CASE
 
END_ACTION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        