asm AODV

import StandardLibrary

signature:
	dynamic abstract domain Message 	
	dynamic abstract domain RoutingTable 
	enum domain MessageType = {RREQ | RREP | RERR} 
						
	dynamic controlled active: RoutingTable -> Boolean 		
	dynamic controlled curSeqNum: Agent -> Integer  
	dynamic controlled entry: RoutingTable -> Prod(Agent, Integer, Integer, Agent) 	
	dynamic controlled entryFor: Agent -> RoutingTable
	dynamic controlled isConsumed: Prod(Agent, Message) -> Boolean
	dynamic controlled isLinked: Prod(Agent, Agent) -> Boolean
	dynamic controlled lastKnownDestSeqNum: Prod(Agent,Agent) -> Integer
	dynamic controlled localReqCount: Agent -> Integer
	dynamic controlled messageRERR: Message -> Prod(Agent, Integer, Agent)	
	dynamic controlled messageRREP: Message -> Prod(Agent, Integer, Agent, Integer, Agent)	
	dynamic controlled messageRREQ: Message -> Prod(Agent, Integer, Integer, Agent, Integer, Integer, Agent)
	dynamic controlled messageType: Message -> MessageType								
	dynamic controlled owner: RoutingTable -> Agent	
	dynamic controlled precursor: RoutingTable -> Seq(Agent)
	dynamic controlled receivedReq: Agent -> Seq(Prod(Integer, Agent))	
	dynamic controlled waitingForRouteTo: Prod(Agent, Agent) -> Boolean 
	
	dynamic controlled rreq_update: Agent -> Integer
	dynamic controlled rrep_update: Agent -> Integer
	dynamic controlled rerr_update: Agent -> Integer
	dynamic controlled ca_success: Prod(Agent,Agent) -> Integer
	dynamic controlled ca_failure: Prod(Agent,Agent) -> Integer
	dynamic controlled ca_tot: Prod(Agent,Agent) -> Integer
	
	dynamic controlled rt_update: Agent -> Integer
	dynamic controlled waitingForRouteToTmp: Prod(Agent, Agent) -> Integer
	
	static host1: Agent
	static host2: Agent
	static host3: Agent
	static host4: Agent
	static host5: Agent
	static host6: Agent
	static host7: Agent
	static host8: Agent
	static host9: Agent
	static host10: Agent
	static host11: Agent
	static host12: Agent
	static host13: Agent
	static host14: Agent
	static host15: Agent
	static host16: Agent
	static host17: Agent
	static host18: Agent
	
	derived dest: Message -> Agent	
	derived destSeqNum: Message -> Integer	
	derived hopCount: Message -> Integer
	derived localId: Message -> Integer	
	derived origin: Message -> Agent	
	derived originSeqNum: Message -> Integer
	derived sender: Message -> Agent	
	
	derived entryDest: RoutingTable -> Agent
	derived entrySeqNum: RoutingTable -> Integer
	derived entryHopCount: RoutingTable -> Integer
	derived entryNextHop: RoutingTable -> Agent	
	
	derived alreadyReceivedBefore: Message -> Boolean
	derived foundValidPathFor: Message -> Boolean
	derived globalId: Message -> Prod(Integer, Agent)
	derived hasNewForwardRouteInfo: Message -> Boolean
	derived hasNewDestInfo: Message -> Boolean
	derived hasNewOriginInfo: Message -> Boolean
	derived hasNewReverseRouteInfo: Message -> Boolean		
	derived knowsActiveRouteTo: Agent -> Boolean 
	derived knowsFreshEnoughRouteFor: Message -> Boolean
	derived linkBreak: Agent -> Boolean
	derived mustForward: Message -> Boolean
	derived thereIsNoRouteInfoFor: Agent -> Boolean
	derived thereIsRouteInfoFor: Agent -> Boolean
	derived validDestSeqNum: RoutingTable -> Boolean
	
definitions:

	function origin($m in Message) =
		switch messageType($m)
			case RREQ: first(messageRREQ($m))
			case RREP: first(messageRREP($m))
		endswitch
	
	function originSeqNum($m in Message) =
		second(messageRREQ($m))
	
	function hopCount($m in Message) =
		switch messageType($m)
			case RREQ: third(messageRREQ($m))
			case RREP: second(messageRREP($m))
		endswitch
		
	function dest($m in Message) =
		switch messageType($m)
			case RREQ: fourth(messageRREQ($m))
			case RREP: third(messageRREP($m))
			case RERR: first(messageRERR($m))
		endswitch
		
	function destSeqNum($m in Message) =
		switch messageType($m)
			case RREQ: fifth(messageRREQ($m))
			case RREP: fourth(messageRREP($m))
			case RERR: second(messageRERR($m))
		endswitch
		
	function localId($m in Message) =
		sixth(messageRREQ($m))
		
	function sender($m in Message) =
		switch messageType($m)
			case RREQ: seventh(messageRREQ($m))
			case RREP: fifth(messageRREP($m))
			case RERR: third(messageRERR($m))
		endswitch

	function entryDest($e in RoutingTable) = first(entry($e))	
	function entrySeqNum($e in RoutingTable) = 
		if isDef($e) then
			second(entry($e))
		else
			undef
		endif
	function entryHopCount($e in RoutingTable) = third(entry($e))
	function entryNextHop($e in RoutingTable) = fourth(entry($e))
		
	function knowsActiveRouteTo($dest in Agent) = 
		(exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest and active($e)))
		
	function alreadyReceivedBefore($m in Message) =
		(exist $r in asSet(receivedReq(self)) with ($r = globalId($m)))
		
	function globalId($m in Message) =
		(localId($m), origin($m))
	
	function hasNewDestInfo($m in Message) =
		if (entryFor(self)!=undef) then
			if (destSeqNum($m) > entrySeqNum(entryFor(self)) or (destSeqNum($m) = entrySeqNum(entryFor(self)) and (hopCount($m) + 1) < entryHopCount(entryFor(self))) or (destSeqNum($m) = entrySeqNum(entryFor(self)) and active(entryFor(self)) = false)) then
				true
			else
				false
			endif
		else
			true
		endif			
	
	function hasNewOriginInfo($m in Message) =
		if (entryFor(self) = undef) then
			true
		else
			if (originSeqNum($m) > entrySeqNum(entryFor(self))) then
				true
			else
				false
			endif	
		endif	
		
	function knowsFreshEnoughRouteFor($m in Message) =
		if (destSeqNum($m)!=undef) then
			(exist $e in RoutingTable with (owner($e)=self and entryDest($e)=dest($m) and validDestSeqNum($e) and entrySeqNum($e) >= destSeqNum($m) and active($e)))
		else
			(exist $el in RoutingTable with (owner($el)=self and entryDest($el)=dest($m) and validDestSeqNum($el) and active($el)))
		endif
		
	function foundValidPathFor($m in Message) =
		if (dest($m)=self or knowsFreshEnoughRouteFor($m)) then
			true
		else 
			false
		endif
		
	function linkBreak($a in Agent) = 
		(isLinked(self, $a)=false)
		
	function mustForward($m in Message) =
		if (origin($m) != self) then
			true
		else
			false
		endif
		
	function thereIsRouteInfoFor($dest in Agent) =
		(exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest))
		
	function thereIsNoRouteInfoFor($dest in Agent) =
		not(thereIsRouteInfoFor($dest))
		
	function hasNewForwardRouteInfo($m in Message) =
		if (messageType($m) = RREP and thereIsNoRouteInfoFor(dest($m)) or (thereIsRouteInfoFor(dest($m)) and hasNewDestInfo($m))) then
			true
		else
			false
		endif 
	
	function hasNewReverseRouteInfo($m in Message) =
		if (messageType($m) = RREQ and thereIsNoRouteInfoFor(origin($m)) or (thereIsRouteInfoFor(origin($m)) and hasNewOriginInfo($m))) then
			true
		else
			false
		endif 
		
	function validDestSeqNum($e in RoutingTable) =
		if (entrySeqNum($e)!=undef) then
			true
		else
			false
		endif
					
	rule r_StartCommunicationWith($dest in Agent) = 
		ca_success(self,$dest) := ca_success(self,$dest) + 1
	
	rule r_LastKnownDestSeqNum($dest in Agent) =
		choose $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest and entrySeqNum($e)!=undef) do 
			lastKnownDestSeqNum(self,$dest) := entrySeqNum($e)
		ifnone 
			lastKnownDestSeqNum(self,$dest) := undef
	
	rule r_EntryFor($dest in Agent) =
		choose $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest) do
			entryFor(self) := $e
		ifnone
			entryFor(self) := undef

	rule r_Insert($globalId in Prod(Integer, Agent)) = 
		receivedReq(self) := append(receivedReq(self), $globalId)
		
	rule r_Insert($n in Agent, $precursor in Seq(Agent)) = 
		$precursor := append($precursor, $n)
	
	rule r_Send($m in Message, $n in Agent) = 		
		isConsumed($n, $m) := false
	
	rule r_Broadcast($m in Message) = 
		let($queue = {$n in Agent | (isLinked(self,$n) and self != $n) : $n}, $neighb = chooseone(Agent)) in
			while(notEmpty($queue)) do
				seq
					$neighb := chooseone($queue)
					$queue := excluding($queue, $neighb)
					r_Send[$m, $neighb]
					if(messageType($m) = RREQ) then
						rreq_update(self) := rreq_update(self) + 1
					endif
				endseq
		endlet		
	
	rule r_Buffer($m in Message) =
		receivedReq(self) := append(receivedReq(self), globalId($m))
		
	rule r_Consume($m in Message) =
		isConsumed(self, $m) := true
	
	rule r_GenerateRouteErr = 
		if(notEmpty(RoutingTable)) then
			let($queue = {$e in RoutingTable | (owner($e)=self and active($e) and linkBreak(entryNextHop($e)) and not(isEmpty(precursor($e))) ) : $e}, $entry = chooseone(RoutingTable)) in
					while(notEmpty($queue)) do
						seq
							$entry := chooseone($queue)
							$queue := excluding($queue,$entry)
							active($entry) := false
							rerr_update(self) := rerr_update(self) + 1
							entry($entry) := (entryDest($entry), entrySeqNum($entry) + 1, entryHopCount($entry), entryNextHop($entry))
							extend Message with $newrerr do 
								seq
									messageType($newrerr) := RERR
									messageRERR($newrerr) := (entryDest($entry),
															entrySeqNum($entry),
															self)
									forall $a in asSet(precursor($entry)) do
										r_Send[$newrerr, $a]
									precursor($entry) := []
								endseq
						endseq
				endlet
		endif
	
	rule r_ReGenerateRouteReq($dest in Agent) =
		par
	 		waitingForRouteTo(self, $dest) := false
	 		ca_failure(self,$dest) := ca_failure(self,$dest) + 1
	 	endpar
		 
	
	rule r_GenerateRouteReq($dest in Agent) = 	
		extend Message with $newrreq do 
			seq
				r_LastKnownDestSeqNum[$dest]
				messageType($newrreq) := RREQ
				messageRREQ($newrreq) := (self, 
										curSeqNum(self) + 1,  
										0, 
										$dest, 										
										lastKnownDestSeqNum(self,$dest),
										localReqCount(self) + 1,
										self)
				curSeqNum(self) := curSeqNum(self) + 1
				localReqCount(self) := localReqCount(self) + 1
				r_Broadcast[$newrreq]
				r_Buffer[$newrreq]
			endseq
			
	rule r_PrecursorInsertion($a in Agent, $e in RoutingTable) = 
		r_Insert[$a, precursor($e)]
	
	rule r_GenerateRouteReply($m in Message) = 
		extend Message with $newrrep do 
			seq
				rrep_update(self) := rrep_update(self) + 1
				if (dest($m) = self) then
					seq
						messageType($newrrep) := RREP
						if (destSeqNum($m) = undef) then								
							messageRREP($newrrep) := (origin($m), 
													0,  
													dest($m), 
													curSeqNum(self),
													self)								
						else
							if ((curSeqNum(self) + 1) = destSeqNum($m)) then
								seq
									messageRREP($newrrep) := (origin($m), 
														0,  
														dest($m), 
														curSeqNum(self) + 1,
														self)
									curSeqNum(self) := curSeqNum(self) + 1
								endseq
							else
								seq
									messageRREP($newrrep) := (origin($m), 
														0,  
														dest($m), 
														curSeqNum(self),
														self)
									curSeqNum(self) := max(curSeqNum(self),destSeqNum($m))
								endseq
							endif
						endif
					endseq	
				else
					seq
						r_EntryFor[dest($m)] 
						let ($fwdEntry = entryFor(self)) in
							seq
								messageType($newrrep) := RREP
								messageRREP($newrrep) := (origin($m), 
														entryHopCount($fwdEntry),  
														dest($m), 
														entrySeqNum($fwdEntry),
														self)							
								r_PrecursorInsertion[sender($m), $fwdEntry] 
							endseq
						endlet	
					endseq					
				endif
				r_Send[$newrrep, sender($m)]
			endseq
	
	rule r_PropagateRouteErr = 
		let($queue = {$m in Message | (messageType($m) = RERR and isLinked(self,sender($m)) and isConsumed(self,$m)=false) : $m} , $rerr = chooseone(Message)) in
			while(notEmpty($queue)) do
				seq
					$rerr := chooseone($queue)
					$queue := excluding($queue,$rerr)
					rerr_update(self) := rerr_update(self) + 1
					par
						forall $e in RoutingTable with (owner($e)=self and entryDest($e)=dest($rerr) and entryNextHop($e)=sender($rerr)) do
							par
								active($e) := false
								entry($e) := (entryDest($e), destSeqNum($rerr), entryHopCount($e), entryNextHop($e)) 
								seq
									forall $a in asSet(precursor($e)) do
										r_Send[$rerr, $a]
									precursor($e) := []
								endseq
								if (waitingForRouteTo(self, dest($rerr))) then
									r_ReGenerateRouteReq[dest($rerr)]
								endif
							endpar	
						r_Consume[$rerr]
					endpar
				endseq
			endlet
			
	rule r_PrepareComm = 
		forall $dest in Agent with ($dest != self) do
			choose $wantsToCommunicateWith in Boolean with true do
					if ($wantsToCommunicateWith) then
						par
							if(not(waitingForRouteTo(self,$dest))) then 
								ca_tot(self, $dest) := ca_tot(self, $dest) + 1
								endif
							if (knowsActiveRouteTo($dest)) then
								par
									r_StartCommunicationWith[$dest]
									waitingForRouteTo(self, $dest) := false
								endpar
							else
								if not(waitingForRouteTo(self, $dest)) then
									par
										r_GenerateRouteReq[$dest]
										waitingForRouteTo(self, $dest) := true
										waitingForRouteToTmp(self,$dest) := 5
									endpar									
								endif
							endif
						endpar
					endif
	
	rule r_UpdateReverseRoute($e in RoutingTable, $m in Message) = 
		par
			rt_update(self) := rt_update(self) + 1
			entry($e) := (entryDest($e), originSeqNum($m), hopCount($m) + 1, sender($m))
			active($e) := true
		endpar
	
	rule r_ExtendReverseRoute($m in Message) = 
		extend RoutingTable with $newentry do 
			seq
				owner($newentry) := self
				entry($newentry) := (origin($m), undef, undef, undef) 
				precursor($newentry) := []
				r_UpdateReverseRoute[$newentry, $m]
			endseq
	
	rule r_RefreshReverseRoute($m in Message) = 
		seq
			r_EntryFor[origin($m)]
			r_UpdateReverseRoute[entryFor(self),$m]
		endseq
				
	rule r_BuildReverseRoute($m in Message) = 
		if (thereIsRouteInfoFor(origin($m))) then
			r_RefreshReverseRoute[$m]
		else
			r_ExtendReverseRoute[$m]
		endif
		
	rule r_ForwardRefreshedReq($m in Message) = 
		extend Message with $newrreq do 
			seq
				r_LastKnownDestSeqNum[dest($m)]
				messageType($newrreq) := RREQ
				if (destSeqNum($m) != undef and lastKnownDestSeqNum(self,dest($m)) != undef) then
					messageRREQ($newrreq) := (origin($m), 
											originSeqNum($m),  
											hopCount($m) + 1, 
											dest($m), 										
											max(destSeqNum($m), lastKnownDestSeqNum(self,dest($m))),
											localId($m),
											self)		
				else
					if (destSeqNum($m) != undef) then
						messageRREQ($newrreq) := (origin($m), 
											originSeqNum($m),  
											hopCount($m) + 1, 
											dest($m), 										
											destSeqNum($m),
											localId($m),
											self)	
					else
						if (lastKnownDestSeqNum(self,dest($m)) != undef) then
							messageRREQ($newrreq) := (origin($m), 
												originSeqNum($m),  
												hopCount($m) + 1, 
												dest($m), 										
												lastKnownDestSeqNum(self,dest($m)),
												localId($m),
												self)	
						else
							messageRREQ($newrreq) := (origin($m), 
												originSeqNum($m),  
												hopCount($m) + 1, 
												dest($m), 										
												undef,
												localId($m),
												self)
						endif
					endif
				endif
				r_Broadcast[$newrreq]
			endseq
	
	rule r_ProcessRouteReq = 
		let($queue = {$m in Message | messageType($m) = RREQ and isLinked(self,sender($m)) and isConsumed(self,$m)=false : $m} , $rreq = chooseone(Message)) in
			while(notEmpty($queue)) do
				seq
					$rreq := chooseone($queue)
					$queue := excluding($queue,$rreq)
					par
						if not(alreadyReceivedBefore($rreq)) then
							seq
								r_Insert[globalId($rreq)]
								r_EntryFor[origin($rreq)] 
								if (hasNewReverseRouteInfo($rreq)) then
									r_BuildReverseRoute[$rreq]
								endif
								if (foundValidPathFor($rreq)) then
									r_GenerateRouteReply[$rreq]
								else
									r_ForwardRefreshedReq[$rreq]
								endif	
							endseq
						endif
						r_Consume[$rreq]
					endpar
				endseq
			endlet
	
	rule r_SetPrecursor($m in Message, $e in RoutingTable) =
		if (mustForward($m)) then
			seq
				r_EntryFor[origin($m)]
				r_Insert[entryNextHop(entryFor(self)), precursor($e)]
			endseq
		endif
	
	rule r_UpdateForwardRoute($e in RoutingTable, $m in Message) = 
		par
			rt_update(self) := rt_update(self) + 1
			entry($e) := (dest($m), destSeqNum($m), hopCount($m) + 1, sender($m))
			active($e) := true
			r_SetPrecursor[$m, $e]
		endpar
	
	rule r_RefreshForwardRoute($m in Message) = 
		seq
			r_EntryFor[dest($m)]
			r_UpdateForwardRoute[entryFor(self), $m]
		endseq
		
	rule r_ExtendForwardRoute($m in Message) = 
		extend RoutingTable with $newentry do 
			seq
				owner($newentry) := self
				entry($newentry) := (dest($m), undef, undef, undef)
				precursor($newentry) := [] 
				r_UpdateForwardRoute[$newentry, $m]
			endseq
	
	rule r_BuildForwardRoute($m in Message) = 
		if (thereIsRouteInfoFor(dest($m))) then
			r_RefreshForwardRoute[$m]
		else
			r_ExtendForwardRoute[$m]
		endif
	
	rule r_ForwardRefreshedRep($m in Message) =
		 extend Message with $newrrep do 
		 	seq		 
		 		rrep_update(self) := rrep_update(self)+1
		 		r_EntryFor[dest($m)] 
				if (hasNewForwardRouteInfo($m)) then
					seq
						messageType($newrrep) := RREP
						messageRREP($newrrep) := (origin($m),  
												hopCount($m) + 1, 
												dest($m), 										
												destSeqNum($m),
												self)			
						r_EntryFor[origin($m)]	
						r_Send[$newrrep, entryNextHop(entryFor(self))]
					endseq
				else
					seq
						r_EntryFor[dest($m)] 
						messageType($newrrep) := RREP
						messageRREP($newrrep) := (origin($m),  
												entryHopCount(entryFor(self)), 
												dest($m), 										
												destSeqNum($m),
												self)	
						r_EntryFor[origin($m)]				
						r_Send[$newrrep, entryNextHop(entryFor(self))]
					endseq
				endif	
			endseq			
		
	rule r_ProcessRouteRep =
		let($queue = {$m in Message | messageType($m) = RREP and isLinked(self,sender($m)) and isConsumed(self,$m)=false : $m} , $rrep = chooseone(Message)) in
			while(notEmpty($queue)) do
				seq
					$rrep := chooseone($queue)
					$queue := excluding($queue, $rrep)
					par
						if (dest($rrep) != self) then
							seq
								r_EntryFor[dest($rrep)] 
								if (hasNewForwardRouteInfo($rrep)) then
									r_BuildForwardRoute[$rrep]
								endif
								if (mustForward($rrep)) then
									r_ForwardRefreshedRep[$rrep]
								endif
							endseq
						endif
						r_Consume[$rrep]
					endpar
				endseq
		endlet
		
	rule r_ProcessRouteErr = 
		choose $c in Boolean with true do 
			if $c then
				r_GenerateRouteErr[]
			else
				r_PropagateRouteErr[] 
			endif
	
	rule r_Router = 
		seq
			r_ProcessRouteReq[]
			r_ProcessRouteRep[]
			r_ProcessRouteErr[]
		endseq
		
	/* START PAR */
			rule r_MemoryManager =
			par
			isLinked(host1,host5):=true
			isLinked(host5,host1):=true
			isLinked(host1,host7):=true
			isLinked(host7,host1):=true
			isLinked(host1,host8):=true
			isLinked(host8,host1):=true
			isLinked(host1,host9):=true
			isLinked(host9,host1):=true
			isLinked(host1,host10):=true
			isLinked(host10,host1):=true
			isLinked(host1,host11):=true
			isLinked(host11,host1):=true
			isLinked(host1,host15):=true
			isLinked(host15,host1):=true
			isLinked(host1,host16):=true
			isLinked(host16,host1):=true
			isLinked(host1,host17):=true
			isLinked(host17,host1):=true
			isLinked(host2,host4):=true
			isLinked(host4,host2):=true
			isLinked(host2,host7):=true
			isLinked(host7,host2):=true
			isLinked(host2,host9):=true
			isLinked(host9,host2):=true
			isLinked(host2,host10):=true
			isLinked(host10,host2):=true
			isLinked(host2,host11):=true
			isLinked(host11,host2):=true
			isLinked(host2,host12):=true
			isLinked(host12,host2):=true
			isLinked(host2,host14):=true
			isLinked(host14,host2):=true
			isLinked(host2,host15):=true
			isLinked(host15,host2):=true
			isLinked(host2,host16):=true
			isLinked(host16,host2):=true
			isLinked(host2,host17):=true
			isLinked(host17,host2):=true
			isLinked(host3,host5):=true
			isLinked(host5,host3):=true
			isLinked(host3,host7):=true
			isLinked(host7,host3):=true
			isLinked(host3,host8):=true
			isLinked(host8,host3):=true
			isLinked(host3,host9):=true
			isLinked(host9,host3):=true
			isLinked(host3,host17):=true
			isLinked(host17,host3):=true
			isLinked(host3,host18):=true
			isLinked(host18,host3):=true
			isLinked(host4,host6):=true
			isLinked(host6,host4):=true
			isLinked(host4,host7):=true
			isLinked(host7,host4):=true
			isLinked(host4,host8):=true
			isLinked(host8,host4):=true
			isLinked(host4,host9):=true
			isLinked(host9,host4):=true
			isLinked(host4,host10):=true
			isLinked(host10,host4):=true
			isLinked(host4,host12):=true
			isLinked(host12,host4):=true
			isLinked(host4,host13):=true
			isLinked(host13,host4):=true
			isLinked(host4,host14):=true
			isLinked(host14,host4):=true
			isLinked(host4,host16):=true
			isLinked(host16,host4):=true
			isLinked(host4,host18):=true
			isLinked(host18,host4):=true
			isLinked(host5,host6):=true
			isLinked(host6,host5):=true
			isLinked(host5,host7):=true
			isLinked(host7,host5):=true
			isLinked(host5,host9):=true
			isLinked(host9,host5):=true
			isLinked(host5,host14):=true
			isLinked(host14,host5):=true
			isLinked(host5,host18):=true
			isLinked(host18,host5):=true
			isLinked(host6,host7):=true
			isLinked(host7,host6):=true
			isLinked(host6,host9):=true
			isLinked(host9,host6):=true
			isLinked(host6,host11):=true
			isLinked(host11,host6):=true
			isLinked(host6,host12):=true
			isLinked(host12,host6):=true
			isLinked(host6,host13):=true
			isLinked(host13,host6):=true
			isLinked(host6,host14):=true
			isLinked(host14,host6):=true
			isLinked(host6,host16):=true
			isLinked(host16,host6):=true
			isLinked(host6,host17):=true
			isLinked(host17,host6):=true
			isLinked(host7,host8):=true
			isLinked(host8,host7):=true
			isLinked(host7,host13):=true
			isLinked(host13,host7):=true
			isLinked(host7,host14):=true
			isLinked(host14,host7):=true
			isLinked(host7,host15):=true
			isLinked(host15,host7):=true
			isLinked(host7,host16):=true
			isLinked(host16,host7):=true
			isLinked(host7,host17):=true
			isLinked(host17,host7):=true
			isLinked(host8,host10):=true
			isLinked(host10,host8):=true
			isLinked(host8,host12):=true
			isLinked(host12,host8):=true
			isLinked(host8,host13):=true
			isLinked(host13,host8):=true
			isLinked(host8,host15):=true
			isLinked(host15,host8):=true
			isLinked(host8,host16):=true
			isLinked(host16,host8):=true
			isLinked(host9,host10):=true
			isLinked(host10,host9):=true
			isLinked(host9,host11):=true
			isLinked(host11,host9):=true
			isLinked(host9,host12):=true
			isLinked(host12,host9):=true
			isLinked(host9,host14):=true
			isLinked(host14,host9):=true
			isLinked(host9,host16):=true
			isLinked(host16,host9):=true
			isLinked(host9,host18):=true
			isLinked(host18,host9):=true
			isLinked(host10,host11):=true
			isLinked(host11,host10):=true
			isLinked(host10,host13):=true
			isLinked(host13,host10):=true
			isLinked(host10,host15):=true
			isLinked(host15,host10):=true
			isLinked(host10,host16):=true
			isLinked(host16,host10):=true
			isLinked(host11,host12):=true
			isLinked(host12,host11):=true
			isLinked(host11,host14):=true
			isLinked(host14,host11):=true
			isLinked(host11,host16):=true
			isLinked(host16,host11):=true
			isLinked(host11,host18):=true
			isLinked(host18,host11):=true
			isLinked(host12,host14):=true
			isLinked(host14,host12):=true
			isLinked(host12,host15):=true
			isLinked(host15,host12):=true
			isLinked(host12,host18):=true
			isLinked(host18,host12):=true
			isLinked(host13,host15):=true
			isLinked(host15,host13):=true
			isLinked(host13,host17):=true
			isLinked(host17,host13):=true
			isLinked(host13,host18):=true
			isLinked(host18,host13):=true
			isLinked(host14,host17):=true
			isLinked(host17,host14):=true
			isLinked(host15,host17):=true
			isLinked(host17,host15):=true
			isLinked(host15,host18):=true
			isLinked(host18,host15):=true
			isLinked(host16,host17):=true
			isLinked(host17,host16):=true
			isLinked(host17,host18):=true
			isLinked(host18,host17):=true

			curSeqNum(host10):=1
			curSeqNum(host12):=2
			curSeqNum(host14):=1
			curSeqNum(host15):=3
			curSeqNum(host18):=1
			curSeqNum(host2):=1
			curSeqNum(host5):=1
			curSeqNum(host6):=1
			curSeqNum(host8):=1
			curSeqNum(host9):=1
			lastKnownDestSeqNum(host1,host11):=undef
			lastKnownDestSeqNum(host1,host12):=undef
			lastKnownDestSeqNum(host1,host17):=undef
			lastKnownDestSeqNum(host1,host3):=undef
			lastKnownDestSeqNum(host1,host7):=undef
			lastKnownDestSeqNum(host1,host9):=undef
			lastKnownDestSeqNum(host10,host1):=undef
			lastKnownDestSeqNum(host10,host11):=undef
			lastKnownDestSeqNum(host10,host13):=undef
			lastKnownDestSeqNum(host10,host14):=undef
			lastKnownDestSeqNum(host10,host17):=undef
			lastKnownDestSeqNum(host10,host18):=undef
			lastKnownDestSeqNum(host10,host2):=undef
			lastKnownDestSeqNum(host10,host5):=undef
			lastKnownDestSeqNum(host10,host6):=undef
			lastKnownDestSeqNum(host10,host7):=undef
			lastKnownDestSeqNum(host10,host8):=undef
			lastKnownDestSeqNum(host10,host9):=undef
			lastKnownDestSeqNum(host11,host17):=undef
			lastKnownDestSeqNum(host11,host5):=undef
			lastKnownDestSeqNum(host11,host6):=undef
			lastKnownDestSeqNum(host11,host7):=undef
			lastKnownDestSeqNum(host12,host1):=undef
			lastKnownDestSeqNum(host12,host11):=undef
			lastKnownDestSeqNum(host12,host13):=undef
			lastKnownDestSeqNum(host12,host14):=undef
			lastKnownDestSeqNum(host12,host17):=undef
			lastKnownDestSeqNum(host12,host18):=undef
			lastKnownDestSeqNum(host12,host3):=undef
			lastKnownDestSeqNum(host12,host4):=undef
			lastKnownDestSeqNum(host12,host5):=undef
			lastKnownDestSeqNum(host12,host6):=undef
			lastKnownDestSeqNum(host12,host7):=undef
			lastKnownDestSeqNum(host12,host8):=undef
			lastKnownDestSeqNum(host12,host9):=undef
			lastKnownDestSeqNum(host13,host12):=undef
			lastKnownDestSeqNum(host13,host17):=undef
			lastKnownDestSeqNum(host13,host3):=undef
			lastKnownDestSeqNum(host13,host5):=undef
			lastKnownDestSeqNum(host13,host6):=undef
			lastKnownDestSeqNum(host13,host7):=undef
			lastKnownDestSeqNum(host13,host9):=undef
			lastKnownDestSeqNum(host14,host1):=undef
			lastKnownDestSeqNum(host14,host11):=undef
			lastKnownDestSeqNum(host14,host16):=undef
			lastKnownDestSeqNum(host14,host17):=undef
			lastKnownDestSeqNum(host14,host18):=undef
			lastKnownDestSeqNum(host14,host2):=undef
			lastKnownDestSeqNum(host14,host4):=undef
			lastKnownDestSeqNum(host14,host7):=undef
			lastKnownDestSeqNum(host14,host9):=undef
			lastKnownDestSeqNum(host15,host1):=undef
			lastKnownDestSeqNum(host15,host11):=undef
			lastKnownDestSeqNum(host15,host12):=undef
			lastKnownDestSeqNum(host15,host13):=undef
			lastKnownDestSeqNum(host15,host14):=undef
			lastKnownDestSeqNum(host15,host16):=undef
			lastKnownDestSeqNum(host15,host17):=undef
			lastKnownDestSeqNum(host15,host18):=undef
			lastKnownDestSeqNum(host15,host2):=undef
			lastKnownDestSeqNum(host15,host3):=undef
			lastKnownDestSeqNum(host15,host4):=undef
			lastKnownDestSeqNum(host15,host5):=undef
			lastKnownDestSeqNum(host15,host6):=undef
			lastKnownDestSeqNum(host15,host7):=undef
			lastKnownDestSeqNum(host15,host8):=undef
			lastKnownDestSeqNum(host15,host9):=undef
			lastKnownDestSeqNum(host17,host11):=undef
			lastKnownDestSeqNum(host17,host12):=undef
			lastKnownDestSeqNum(host17,host7):=undef
			lastKnownDestSeqNum(host17,host9):=undef
			lastKnownDestSeqNum(host18,host1):=undef
			lastKnownDestSeqNum(host18,host11):=undef
			lastKnownDestSeqNum(host18,host12):=undef
			lastKnownDestSeqNum(host18,host14):=undef
			lastKnownDestSeqNum(host18,host15):=undef
			lastKnownDestSeqNum(host18,host17):=undef
			lastKnownDestSeqNum(host18,host2):=undef
			lastKnownDestSeqNum(host18,host3):=undef
			lastKnownDestSeqNum(host18,host5):=undef
			lastKnownDestSeqNum(host18,host7):=undef
			lastKnownDestSeqNum(host18,host8):=undef
			lastKnownDestSeqNum(host18,host9):=undef
			lastKnownDestSeqNum(host2,host10):=undef
			lastKnownDestSeqNum(host2,host12):=undef
			lastKnownDestSeqNum(host2,host14):=undef
			lastKnownDestSeqNum(host2,host16):=undef
			lastKnownDestSeqNum(host2,host17):=undef
			lastKnownDestSeqNum(host2,host18):=undef
			lastKnownDestSeqNum(host2,host3):=undef
			lastKnownDestSeqNum(host2,host4):=undef
			lastKnownDestSeqNum(host2,host5):=undef
			lastKnownDestSeqNum(host2,host6):=undef
			lastKnownDestSeqNum(host2,host7):=undef
			lastKnownDestSeqNum(host2,host8):=undef
			lastKnownDestSeqNum(host3,host12):=undef
			lastKnownDestSeqNum(host3,host17):=undef
			lastKnownDestSeqNum(host4,host11):=undef
			lastKnownDestSeqNum(host4,host12):=undef
			lastKnownDestSeqNum(host4,host17):=undef
			lastKnownDestSeqNum(host4,host5):=undef
			lastKnownDestSeqNum(host4,host7):=undef
			lastKnownDestSeqNum(host4,host9):=undef
			lastKnownDestSeqNum(host5,host1):=undef
			lastKnownDestSeqNum(host5,host10):=undef
			lastKnownDestSeqNum(host5,host14):=undef
			lastKnownDestSeqNum(host5,host15):=undef
			lastKnownDestSeqNum(host5,host17):=undef
			lastKnownDestSeqNum(host5,host3):=undef
			lastKnownDestSeqNum(host5,host7):=undef
			lastKnownDestSeqNum(host5,host9):=undef
			lastKnownDestSeqNum(host6,host1):=undef
			lastKnownDestSeqNum(host6,host11):=undef
			lastKnownDestSeqNum(host6,host13):=undef
			lastKnownDestSeqNum(host6,host14):=undef
			lastKnownDestSeqNum(host6,host16):=undef
			lastKnownDestSeqNum(host6,host17):=undef
			lastKnownDestSeqNum(host6,host18):=undef
			lastKnownDestSeqNum(host6,host5):=undef
			lastKnownDestSeqNum(host6,host7):=undef
			lastKnownDestSeqNum(host6,host8):=undef
			lastKnownDestSeqNum(host6,host9):=undef
			lastKnownDestSeqNum(host7,host11):=undef
			lastKnownDestSeqNum(host7,host17):=undef
			lastKnownDestSeqNum(host7,host5):=undef
			lastKnownDestSeqNum(host7,host9):=undef
			lastKnownDestSeqNum(host8,host10):=undef
			lastKnownDestSeqNum(host8,host11):=undef
			lastKnownDestSeqNum(host8,host12):=undef
			lastKnownDestSeqNum(host8,host14):=undef
			lastKnownDestSeqNum(host8,host16):=undef
			lastKnownDestSeqNum(host8,host17):=undef
			lastKnownDestSeqNum(host8,host18):=undef
			lastKnownDestSeqNum(host8,host2):=undef
			lastKnownDestSeqNum(host8,host6):=undef
			lastKnownDestSeqNum(host8,host7):=undef
			lastKnownDestSeqNum(host9,host1):=undef
			lastKnownDestSeqNum(host9,host11):=undef
			lastKnownDestSeqNum(host9,host12):=undef
			lastKnownDestSeqNum(host9,host13):=undef
			lastKnownDestSeqNum(host9,host14):=undef
			lastKnownDestSeqNum(host9,host16):=undef
			lastKnownDestSeqNum(host9,host17):=undef
			lastKnownDestSeqNum(host9,host18):=undef
			lastKnownDestSeqNum(host9,host3):=undef
			lastKnownDestSeqNum(host9,host4):=undef
			lastKnownDestSeqNum(host9,host5):=undef
			lastKnownDestSeqNum(host9,host6):=undef
			lastKnownDestSeqNum(host9,host7):=undef
			lastKnownDestSeqNum(host9,host8):=undef
			localReqCount(host10):=1
			localReqCount(host12):=2
			localReqCount(host14):=1
			localReqCount(host15):=3
			localReqCount(host18):=1
			localReqCount(host2):=1
			localReqCount(host5):=1
			localReqCount(host6):=1
			localReqCount(host8):=1
			localReqCount(host9):=1
			receivedReq(host1):=[(1,host18),(1,host5),(2,host15),(1,host10),(1,host12),(3,host15),(1,host6),(1,host15),(1,host8)]
			receivedReq(host10):=[(1,host10),(1,host15)]
			receivedReq(host11):=[(1,host15),(1,host9),(1,host6),(2,host15),(1,host10),(1,host12)]
			receivedReq(host12):=[(1,host12),(2,host15),(1,host10),(1,host15),(2,host12),(1,host9),(3,host15),(1,host6),(1,host2),(1,host18)]
			receivedReq(host13):=[(1,host10),(1,host15),(1,host18),(2,host15),(1,host12),(1,host9),(3,host15),(1,host6)]
			receivedReq(host14):=[(1,host12),(1,host10),(1,host14),(1,host15),(1,host18),(1,host5),(2,host15),(1,host6),(1,host2)]
			receivedReq(host15):=[(1,host15),(2,host15),(3,host15),(1,host10),(1,host12)]
			receivedReq(host17):=[(1,host18),(1,host5),(2,host15),(1,host10),(1,host12)]
			receivedReq(host18):=[(1,host18),(1,host10),(1,host12)]
			receivedReq(host2):=[(1,host2)]
			receivedReq(host3):=[(1,host18),(1,host10)]
			receivedReq(host4):=[(1,host15),(1,host18),(1,host10),(1,host12),(2,host15),(1,host6),(1,host2),(1,host5),(1,host8)]
			receivedReq(host5):=[(1,host5)]
			receivedReq(host6):=[(1,host12),(1,host15),(1,host6),(2,host15),(1,host10)]
			receivedReq(host7):=[(1,host10),(1,host12),(1,host15),(1,host18),(1,host6),(1,host5),(1,host8),(2,host15)]
			receivedReq(host8):=[(1,host8)]
			receivedReq(host9):=[(1,host9),(1,host18),(1,host5),(3,host15),(2,host15),(1,host2),(1,host10),(1,host15),(1,host12)]
			waitingForRouteTo(host10,host1):=true
			waitingForRouteTo(host10,host11):=true
			waitingForRouteTo(host10,host13):=true
			waitingForRouteTo(host10,host14):=true
			waitingForRouteTo(host10,host17):=true
			waitingForRouteTo(host10,host18):=true
			waitingForRouteTo(host10,host2):=true
			waitingForRouteTo(host10,host5):=true
			waitingForRouteTo(host10,host6):=true
			waitingForRouteTo(host10,host8):=true
			waitingForRouteTo(host10,host9):=true
			waitingForRouteTo(host12,host1):=true
			waitingForRouteTo(host12,host13):=true
			waitingForRouteTo(host12,host14):=true
			waitingForRouteTo(host12,host17):=true
			waitingForRouteTo(host12,host18):=true
			waitingForRouteTo(host12,host3):=true
			waitingForRouteTo(host12,host4):=true
			waitingForRouteTo(host12,host6):=true
			waitingForRouteTo(host12,host7):=true
			waitingForRouteTo(host12,host8):=true
			waitingForRouteTo(host14,host1):=true
			waitingForRouteTo(host14,host16):=true
			waitingForRouteTo(host14,host18):=true
			waitingForRouteTo(host14,host2):=true
			waitingForRouteTo(host14,host4):=true
			waitingForRouteTo(host14,host7):=true
			waitingForRouteTo(host15,host1):=true
			waitingForRouteTo(host15,host13):=true
			waitingForRouteTo(host15,host14):=true
			waitingForRouteTo(host15,host16):=true
			waitingForRouteTo(host15,host17):=true
			waitingForRouteTo(host15,host18):=true
			waitingForRouteTo(host15,host2):=true
			waitingForRouteTo(host15,host3):=true
			waitingForRouteTo(host15,host4):=true
			waitingForRouteTo(host15,host5):=true
			waitingForRouteTo(host15,host6):=true
			waitingForRouteTo(host15,host7):=true
			waitingForRouteTo(host15,host8):=true
			waitingForRouteTo(host15,host9):=true
			waitingForRouteTo(host18,host1):=true
			waitingForRouteTo(host18,host11):=true
			waitingForRouteTo(host18,host12):=true
			waitingForRouteTo(host18,host14):=true
			waitingForRouteTo(host18,host15):=true
			waitingForRouteTo(host18,host2):=true
			waitingForRouteTo(host18,host3):=true
			waitingForRouteTo(host18,host5):=true
			waitingForRouteTo(host18,host7):=true
			waitingForRouteTo(host18,host8):=true
			waitingForRouteTo(host18,host9):=true
			waitingForRouteTo(host2,host10):=true
			waitingForRouteTo(host2,host12):=true
			waitingForRouteTo(host2,host14):=true
			waitingForRouteTo(host2,host16):=true
			waitingForRouteTo(host2,host17):=true
			waitingForRouteTo(host2,host18):=true
			waitingForRouteTo(host2,host3):=true
			waitingForRouteTo(host2,host4):=true
			waitingForRouteTo(host2,host5):=true
			waitingForRouteTo(host2,host6):=true
			waitingForRouteTo(host2,host7):=true
			waitingForRouteTo(host2,host8):=true
			waitingForRouteTo(host5,host1):=true
			waitingForRouteTo(host5,host10):=true
			waitingForRouteTo(host5,host14):=true
			waitingForRouteTo(host5,host15):=true
			waitingForRouteTo(host5,host17):=true
			waitingForRouteTo(host5,host3):=true
			waitingForRouteTo(host5,host7):=true
			waitingForRouteTo(host5,host9):=true
			waitingForRouteTo(host6,host1):=true
			waitingForRouteTo(host6,host11):=true
			waitingForRouteTo(host6,host13):=true
			waitingForRouteTo(host6,host14):=true
			waitingForRouteTo(host6,host16):=true
			waitingForRouteTo(host6,host17):=true
			waitingForRouteTo(host6,host18):=true
			waitingForRouteTo(host6,host5):=true
			waitingForRouteTo(host6,host7):=true
			waitingForRouteTo(host6,host8):=true
			waitingForRouteTo(host6,host9):=true
			waitingForRouteTo(host8,host10):=true
			waitingForRouteTo(host8,host11):=true
			waitingForRouteTo(host8,host12):=true
			waitingForRouteTo(host8,host14):=true
			waitingForRouteTo(host8,host16):=true
			waitingForRouteTo(host8,host17):=true
			waitingForRouteTo(host8,host18):=true
			waitingForRouteTo(host8,host2):=true
			waitingForRouteTo(host8,host6):=true
			waitingForRouteTo(host8,host7):=true
			waitingForRouteTo(host9,host1):=true
			waitingForRouteTo(host9,host11):=true
			waitingForRouteTo(host9,host12):=true
			waitingForRouteTo(host9,host13):=true
			waitingForRouteTo(host9,host14):=true
			waitingForRouteTo(host9,host16):=true
			waitingForRouteTo(host9,host17):=true
			waitingForRouteTo(host9,host18):=true
			waitingForRouteTo(host9,host3):=true
			waitingForRouteTo(host9,host4):=true
			waitingForRouteTo(host9,host5):=true
			waitingForRouteTo(host9,host6):=true
			waitingForRouteTo(host9,host7):=true
			waitingForRouteTo(host9,host8):=true
			waitingForRouteToTmp(host10,host1):=2
			waitingForRouteToTmp(host10,host11):=2
			waitingForRouteToTmp(host10,host13):=2
			waitingForRouteToTmp(host10,host14):=2
			waitingForRouteToTmp(host10,host17):=2
			waitingForRouteToTmp(host10,host18):=2
			waitingForRouteToTmp(host10,host2):=2
			waitingForRouteToTmp(host10,host5):=2
			waitingForRouteToTmp(host10,host6):=2
			waitingForRouteToTmp(host10,host8):=2
			waitingForRouteToTmp(host10,host9):=2
			waitingForRouteToTmp(host12,host1):=2
			waitingForRouteToTmp(host12,host13):=2
			waitingForRouteToTmp(host12,host14):=2
			waitingForRouteToTmp(host12,host17):=2
			waitingForRouteToTmp(host12,host18):=2
			waitingForRouteToTmp(host12,host3):=2
			waitingForRouteToTmp(host12,host4):=2
			waitingForRouteToTmp(host12,host6):=2
			waitingForRouteToTmp(host12,host7):=2
			waitingForRouteToTmp(host12,host8):=5
			waitingForRouteToTmp(host14,host1):=5
			waitingForRouteToTmp(host14,host16):=5
			waitingForRouteToTmp(host14,host18):=5
			waitingForRouteToTmp(host14,host2):=5
			waitingForRouteToTmp(host14,host4):=5
			waitingForRouteToTmp(host14,host7):=5
			waitingForRouteToTmp(host15,host1):=3
			waitingForRouteToTmp(host15,host12):=4
			waitingForRouteToTmp(host15,host13):=3
			waitingForRouteToTmp(host15,host14):=2
			waitingForRouteToTmp(host15,host16):=2
			waitingForRouteToTmp(host15,host17):=4
			waitingForRouteToTmp(host15,host18):=2
			waitingForRouteToTmp(host15,host2):=2
			waitingForRouteToTmp(host15,host3):=4
			waitingForRouteToTmp(host15,host4):=3
			waitingForRouteToTmp(host15,host5):=3
			waitingForRouteToTmp(host15,host6):=4
			waitingForRouteToTmp(host15,host7):=2
			waitingForRouteToTmp(host15,host8):=2
			waitingForRouteToTmp(host15,host9):=3
			waitingForRouteToTmp(host18,host1):=3
			waitingForRouteToTmp(host18,host11):=3
			waitingForRouteToTmp(host18,host12):=3
			waitingForRouteToTmp(host18,host14):=3
			waitingForRouteToTmp(host18,host15):=3
			waitingForRouteToTmp(host18,host2):=3
			waitingForRouteToTmp(host18,host3):=3
			waitingForRouteToTmp(host18,host5):=3
			waitingForRouteToTmp(host18,host7):=3
			waitingForRouteToTmp(host18,host8):=3
			waitingForRouteToTmp(host18,host9):=3
			waitingForRouteToTmp(host2,host10):=4
			waitingForRouteToTmp(host2,host12):=4
			waitingForRouteToTmp(host2,host14):=4
			waitingForRouteToTmp(host2,host16):=4
			waitingForRouteToTmp(host2,host17):=4
			waitingForRouteToTmp(host2,host18):=4
			waitingForRouteToTmp(host2,host3):=4
			waitingForRouteToTmp(host2,host4):=4
			waitingForRouteToTmp(host2,host5):=4
			waitingForRouteToTmp(host2,host6):=4
			waitingForRouteToTmp(host2,host7):=4
			waitingForRouteToTmp(host2,host8):=4
			waitingForRouteToTmp(host5,host1):=3
			waitingForRouteToTmp(host5,host10):=3
			waitingForRouteToTmp(host5,host14):=3
			waitingForRouteToTmp(host5,host15):=3
			waitingForRouteToTmp(host5,host17):=3
			waitingForRouteToTmp(host5,host3):=3
			waitingForRouteToTmp(host5,host7):=3
			waitingForRouteToTmp(host5,host9):=3
			waitingForRouteToTmp(host6,host1):=4
			waitingForRouteToTmp(host6,host11):=4
			waitingForRouteToTmp(host6,host13):=4
			waitingForRouteToTmp(host6,host14):=4
			waitingForRouteToTmp(host6,host16):=4
			waitingForRouteToTmp(host6,host17):=4
			waitingForRouteToTmp(host6,host18):=4
			waitingForRouteToTmp(host6,host5):=4
			waitingForRouteToTmp(host6,host7):=4
			waitingForRouteToTmp(host6,host8):=4
			waitingForRouteToTmp(host6,host9):=4
			waitingForRouteToTmp(host8,host10):=4
			waitingForRouteToTmp(host8,host11):=4
			waitingForRouteToTmp(host8,host12):=4
			waitingForRouteToTmp(host8,host14):=4
			waitingForRouteToTmp(host8,host16):=4
			waitingForRouteToTmp(host8,host17):=4
			waitingForRouteToTmp(host8,host18):=4
			waitingForRouteToTmp(host8,host2):=4
			waitingForRouteToTmp(host8,host6):=4
			waitingForRouteToTmp(host8,host7):=4
			waitingForRouteToTmp(host9,host1):=4
			waitingForRouteToTmp(host9,host11):=4
			waitingForRouteToTmp(host9,host12):=4
			waitingForRouteToTmp(host9,host13):=4
			waitingForRouteToTmp(host9,host14):=4
			waitingForRouteToTmp(host9,host16):=4
			waitingForRouteToTmp(host9,host17):=4
			waitingForRouteToTmp(host9,host18):=4
			waitingForRouteToTmp(host9,host3):=4
			waitingForRouteToTmp(host9,host4):=4
			waitingForRouteToTmp(host9,host5):=4
			waitingForRouteToTmp(host9,host6):=4
			waitingForRouteToTmp(host9,host7):=4
			waitingForRouteToTmp(host9,host8):=4

			extend RoutingTable with $_rt1,$_rt2,$_rt3,$_rt4,$_rt5,$_rt6,$_rt7,$_rt8,$_rt9,$_rt10,$_rt11,$_rt12,$_rt13,$_rt14,$_rt15,$_rt16,$_rt17,$_rt18,$_rt19,$_rt20,$_rt21,$_rt22,$_rt23,$_rt24,$_rt25,$_rt26,$_rt27,$_rt28,$_rt29,$_rt30,$_rt31,$_rt32,$_rt33,$_rt34,$_rt35,$_rt36,$_rt37,$_rt38,$_rt39,$_rt40,$_rt41,$_rt42,$_rt43,$_rt44,$_rt45,$_rt46,$_rt47,$_rt48,$_rt49,$_rt50,$_rt51,$_rt52,$_rt53,$_rt54,$_rt55,$_rt56,$_rt57,$_rt58,$_rt59,$_rt60,$_rt61,$_rt62,$_rt63,$_rt64,$_rt65,$_rt66,$_rt67,$_rt68 do
				par
									active($_rt1):=true
					active($_rt10):=true
					active($_rt11):=true
					active($_rt12):=true
					active($_rt13):=true
					active($_rt14):=true
					active($_rt15):=true
					active($_rt16):=true
					active($_rt17):=true
					active($_rt18):=true
					active($_rt19):=true
					active($_rt2):=true
					active($_rt20):=true
					active($_rt21):=true
					active($_rt22):=true
					active($_rt23):=true
					active($_rt24):=true
					active($_rt25):=true
					active($_rt26):=true
					active($_rt27):=true
					active($_rt28):=true
					active($_rt29):=true
					active($_rt3):=true
					active($_rt30):=true
					active($_rt31):=true
					active($_rt32):=true
					active($_rt33):=true
					active($_rt34):=true
					active($_rt35):=true
					active($_rt36):=true
					active($_rt37):=true
					active($_rt38):=true
					active($_rt39):=true
					active($_rt4):=true
					active($_rt40):=true
					active($_rt41):=true
					active($_rt42):=true
					active($_rt43):=true
					active($_rt44):=true
					active($_rt45):=true
					active($_rt46):=true
					active($_rt47):=true
					active($_rt48):=true
					active($_rt49):=true
					active($_rt5):=true
					active($_rt50):=true
					active($_rt51):=true
					active($_rt52):=true
					active($_rt53):=true
					active($_rt54):=true
					active($_rt55):=true
					active($_rt56):=true
					active($_rt57):=true
					active($_rt58):=true
					active($_rt59):=true
					active($_rt6):=true
					active($_rt60):=true
					active($_rt61):=true
					active($_rt62):=true
					active($_rt63):=true
					active($_rt64):=true
					active($_rt65):=true
					active($_rt66):=true
					active($_rt67):=true
					active($_rt68):=true
					active($_rt7):=true
					active($_rt8):=true
					active($_rt9):=true
					entry($_rt1):=(host10,1,1,host10)
					entry($_rt10):=(host18,1,1,host18)
					entry($_rt11):=(host10,1,2,host14)
					entry($_rt12):=(host12,1,2,host6)
					entry($_rt13):=(host10,1,2,host14)
					entry($_rt14):=(host12,1,2,host6)
					entry($_rt15):=(host15,2,2,host6)
					entry($_rt16):=(host10,1,2,host14)
					entry($_rt17):=(host15,3,1,host15)
					entry($_rt18):=(host10,1,2,host14)
					entry($_rt19):=(host18,1,1,host18)
					entry($_rt2):=(host12,1,1,host12)
					entry($_rt20):=(host5,1,1,host5)
					entry($_rt21):=(host15,3,1,host15)
					entry($_rt22):=(host10,1,2,host14)
					entry($_rt23):=(host12,1,2,host14)
					entry($_rt24):=(host18,1,1,host18)
					entry($_rt25):=(host5,1,1,host5)
					entry($_rt26):=(host15,2,1,host15)
					entry($_rt27):=(host10,1,2,host14)
					entry($_rt28):=(host12,1,2,host14)
					entry($_rt29):=(host10,1,2,host14)
					entry($_rt3):=(host10,1,1,host10)
					entry($_rt30):=(host12,1,2,host14)
					entry($_rt31):=(host18,1,1,host18)
					entry($_rt32):=(host10,1,2,host13)
					entry($_rt33):=(host10,1,1,host10)
					entry($_rt34):=(host12,1,2,host6)
					entry($_rt35):=(host15,1,1,host15)
					entry($_rt36):=(host9,1,1,host9)
					entry($_rt37):=(host6,1,1,host6)
					entry($_rt38):=(host6,1,1,host6)
					entry($_rt39):=(host2,1,1,host2)
					entry($_rt4):=(host12,1,1,host12)
					entry($_rt40):=(host5,1,2,host1)
					entry($_rt41):=(host8,1,1,host8)
					entry($_rt42):=(host15,2,2,host12)
					entry($_rt43):=(host18,1,2,host17)
					entry($_rt44):=(host5,1,2,host17)
					entry($_rt45):=(host6,1,1,host6)
					entry($_rt46):=(host2,1,1,host2)
					entry($_rt47):=(host17,0,1,host17)
					entry($_rt48):=(host18,1,2,host17)
					entry($_rt49):=(host6,1,1,host6)
					entry($_rt5):=(host15,2,1,host15)
					entry($_rt50):=(host5,1,2,host17)
					entry($_rt51):=(host8,1,1,host8)
					entry($_rt52):=(host15,2,2,host12)
					entry($_rt53):=(host9,1,1,host9)
					entry($_rt54):=(host6,1,1,host6)
					entry($_rt55):=(host10,1,3,host12)
					entry($_rt56):=(host12,1,2,host6)
					entry($_rt57):=(host9,1,1,host9)
					entry($_rt58):=(host6,1,1,host6)
					entry($_rt59):=(host2,1,1,host2)
					entry($_rt6):=(host15,3,1,host15)
					entry($_rt60):=(host18,1,2,host4)
					entry($_rt61):=(host6,1,1,host6)
					entry($_rt62):=(host8,1,1,host8)
					entry($_rt63):=(host18,1,1,host18)
					entry($_rt64):=(host5,1,2,host17)
					entry($_rt65):=(host15,3,1,host15)
					entry($_rt66):=(host2,1,1,host2)
					entry($_rt67):=(host10,1,3,host12)
					entry($_rt68):=(host12,1,3,host15)
					entry($_rt7):=(host18,1,1,host18)
					entry($_rt8):=(host12,1,2,host6)
					entry($_rt9):=(host15,2,2,host12)
					entryFor(host1):=$_rt61
					entryFor(host10):=undef
					entryFor(host11):=undef
					entryFor(host12):=undef
					entryFor(host13):=undef
					entryFor(host14):=$_rt2
					entryFor(host15):=undef
					entryFor(host17):=undef
					entryFor(host18):=undef
					entryFor(host3):=undef
					entryFor(host4):=$_rt38
					entryFor(host6):=undef
					entryFor(host7):=$_rt15
					entryFor(host9):=undef
					owner($_rt1):=host13
					owner($_rt10):=host4
					owner($_rt11):=host4
					owner($_rt12):=host4
					owner($_rt13):=host7
					owner($_rt14):=host7
					owner($_rt15):=host7
					owner($_rt16):=host6
					owner($_rt17):=host12
					owner($_rt18):=host12
					owner($_rt19):=host1
					owner($_rt2):=host14
					owner($_rt20):=host1
					owner($_rt21):=host1
					owner($_rt22):=host1
					owner($_rt23):=host1
					owner($_rt24):=host17
					owner($_rt25):=host17
					owner($_rt26):=host17
					owner($_rt27):=host17
					owner($_rt28):=host17
					owner($_rt29):=host18
					owner($_rt3):=host14
					owner($_rt30):=host18
					owner($_rt31):=host3
					owner($_rt32):=host3
					owner($_rt33):=host15
					owner($_rt34):=host15
					owner($_rt35):=host10
					owner($_rt36):=host13
					owner($_rt37):=host13
					owner($_rt38):=host4
					owner($_rt39):=host4
					owner($_rt4):=host6
					owner($_rt40):=host4
					owner($_rt41):=host4
					owner($_rt42):=host14
					owner($_rt43):=host14
					owner($_rt44):=host14
					owner($_rt45):=host14
					owner($_rt46):=host14
					owner($_rt47):=host14
					owner($_rt48):=host7
					owner($_rt49):=host7
					owner($_rt5):=host6
					owner($_rt50):=host7
					owner($_rt51):=host7
					owner($_rt52):=host11
					owner($_rt53):=host11
					owner($_rt54):=host11
					owner($_rt55):=host11
					owner($_rt56):=host11
					owner($_rt57):=host12
					owner($_rt58):=host12
					owner($_rt59):=host12
					owner($_rt6):=host13
					owner($_rt60):=host12
					owner($_rt61):=host1
					owner($_rt62):=host1
					owner($_rt63):=host9
					owner($_rt64):=host9
					owner($_rt65):=host9
					owner($_rt66):=host9
					owner($_rt67):=host9
					owner($_rt68):=host9
					owner($_rt7):=host13
					owner($_rt8):=host13
					owner($_rt9):=host4
					precursor($_rt1):=[]
					precursor($_rt10):=[]
					precursor($_rt11):=[]
					precursor($_rt12):=[host2]
					precursor($_rt13):=[]
					precursor($_rt14):=[host17]
					precursor($_rt15):=[]
					precursor($_rt16):=[]
					precursor($_rt17):=[]
					precursor($_rt18):=[]
					precursor($_rt19):=[]
					precursor($_rt2):=[host17,host2]
					precursor($_rt20):=[host6]
					precursor($_rt21):=[]
					precursor($_rt22):=[]
					precursor($_rt23):=[]
					precursor($_rt24):=[]
					precursor($_rt25):=[]
					precursor($_rt26):=[]
					precursor($_rt27):=[]
					precursor($_rt28):=[]
					precursor($_rt29):=[]
					precursor($_rt3):=[]
					precursor($_rt30):=[]
					precursor($_rt31):=[]
					precursor($_rt32):=[]
					precursor($_rt33):=[]
					precursor($_rt34):=[]
					precursor($_rt35):=[]
					precursor($_rt36):=[]
					precursor($_rt37):=[]
					precursor($_rt38):=[host8]
					precursor($_rt39):=[]
					precursor($_rt4):=[]
					precursor($_rt40):=[]
					precursor($_rt41):=[]
					precursor($_rt42):=[]
					precursor($_rt43):=[]
					precursor($_rt44):=[host6]
					precursor($_rt45):=[]
					precursor($_rt46):=[]
					precursor($_rt47):=[host12]
					precursor($_rt48):=[]
					precursor($_rt49):=[host8]
					precursor($_rt5):=[]
					precursor($_rt50):=[]
					precursor($_rt51):=[]
					precursor($_rt52):=[]
					precursor($_rt53):=[host12]
					precursor($_rt54):=[]
					precursor($_rt55):=[]
					precursor($_rt56):=[]
					precursor($_rt57):=[]
					precursor($_rt58):=[]
					precursor($_rt59):=[]
					precursor($_rt6):=[]
					precursor($_rt60):=[]
					precursor($_rt61):=[host8]
					precursor($_rt62):=[]
					precursor($_rt63):=[]
					precursor($_rt64):=[]
					precursor($_rt65):=[]
					precursor($_rt66):=[]
					precursor($_rt67):=[]
					precursor($_rt68):=[]
					precursor($_rt7):=[]
					precursor($_rt8):=[]
					precursor($_rt9):=[]
				endpar
			extend Message with $_message1,$_message2,$_message3,$_message4,$_message5,$_message6,$_message7,$_message8,$_message9,$_message10,$_message11,$_message12,$_message13,$_message14,$_message15,$_message16,$_message17,$_message18,$_message19,$_message20,$_message21,$_message22,$_message23,$_message24,$_message25,$_message26,$_message27,$_message28,$_message29,$_message30,$_message31,$_message32,$_message33,$_message34,$_message35,$_message36,$_message37,$_message38,$_message39,$_message40,$_message41,$_message42,$_message43,$_message44,$_message45,$_message46,$_message47,$_message48,$_message49,$_message50,$_message51,$_message52,$_message53,$_message54,$_message55,$_message56,$_message57,$_message58,$_message59,$_message60,$_message61,$_message62,$_message63,$_message64,$_message65,$_message66,$_message67,$_message68,$_message69,$_message70,$_message71,$_message72,$_message73,$_message74,$_message75,$_message76,$_message77,$_message78,$_message79,$_message80,$_message81,$_message82,$_message83,$_message84,$_message85,$_message86,$_message87,$_message88,$_message89,$_message90,$_message91,$_message92,$_message93,$_message94,$_message95,$_message96,$_message97,$_message98,$_message99,$_message100,$_message101,$_message102,$_message103,$_message104,$_message105,$_message106,$_message107,$_message108,$_message109,$_message110,$_message111,$_message112,$_message113,$_message114,$_message115,$_message116,$_message117,$_message118,$_message119,$_message120,$_message121,$_message122,$_message123,$_message124,$_message125,$_message126,$_message127,$_message128,$_message129,$_message130,$_message131,$_message132,$_message133,$_message134,$_message135,$_message136,$_message137,$_message138,$_message139,$_message140,$_message141,$_message142,$_message143,$_message144,$_message145,$_message146,$_message147,$_message148,$_message149,$_message150,$_message151,$_message152,$_message153,$_message154,$_message155,$_message156,$_message157,$_message158,$_message159,$_message160,$_message161,$_message162,$_message163,$_message164,$_message165,$_message166,$_message167,$_message168,$_message169,$_message170,$_message171,$_message172,$_message173,$_message174,$_message175,$_message176,$_message177,$_message178,$_message179,$_message180,$_message181,$_message182,$_message183,$_message184,$_message185,$_message186,$_message187,$_message188,$_message189 do
				par
									isConsumed(host1,$_message1):=false
					isConsumed(host1,$_message100):=true
					isConsumed(host1,$_message101):=true
					isConsumed(host1,$_message102):=true
					isConsumed(host1,$_message103):=false
					isConsumed(host1,$_message104):=false
					isConsumed(host1,$_message105):=false
					isConsumed(host1,$_message106):=false
					isConsumed(host1,$_message107):=false
					isConsumed(host1,$_message108):=false
					isConsumed(host1,$_message109):=false
					isConsumed(host1,$_message110):=false
					isConsumed(host1,$_message111):=false
					isConsumed(host1,$_message112):=false
					isConsumed(host1,$_message113):=false
					isConsumed(host1,$_message114):=false
					isConsumed(host1,$_message115):=true
					isConsumed(host1,$_message116):=false
					isConsumed(host1,$_message117):=false
					isConsumed(host1,$_message118):=false
					isConsumed(host1,$_message119):=false
					isConsumed(host1,$_message120):=false
					isConsumed(host1,$_message121):=false
					isConsumed(host1,$_message122):=false
					isConsumed(host1,$_message123):=false
					isConsumed(host1,$_message124):=false
					isConsumed(host1,$_message125):=false
					isConsumed(host1,$_message126):=false
					isConsumed(host1,$_message127):=false
					isConsumed(host1,$_message128):=false
					isConsumed(host1,$_message129):=false
					isConsumed(host1,$_message130):=true
					isConsumed(host1,$_message131):=true
					isConsumed(host1,$_message132):=true
					isConsumed(host1,$_message133):=true
					isConsumed(host1,$_message134):=true
					isConsumed(host1,$_message135):=true
					isConsumed(host1,$_message136):=true
					isConsumed(host1,$_message137):=true
					isConsumed(host1,$_message138):=true
					isConsumed(host1,$_message139):=true
					isConsumed(host1,$_message143):=false
					isConsumed(host1,$_message144):=false
					isConsumed(host1,$_message146):=false
					isConsumed(host1,$_message148):=false
					isConsumed(host1,$_message149):=false
					isConsumed(host1,$_message150):=false
					isConsumed(host1,$_message151):=false
					isConsumed(host1,$_message152):=false
					isConsumed(host1,$_message153):=false
					isConsumed(host1,$_message154):=false
					isConsumed(host1,$_message156):=false
					isConsumed(host1,$_message157):=false
					isConsumed(host1,$_message166):=false
					isConsumed(host1,$_message167):=false
					isConsumed(host1,$_message168):=false
					isConsumed(host1,$_message171):=false
					isConsumed(host1,$_message2):=false
					isConsumed(host1,$_message27):=true
					isConsumed(host1,$_message28):=true
					isConsumed(host1,$_message29):=true
					isConsumed(host1,$_message3):=false
					isConsumed(host1,$_message30):=true
					isConsumed(host1,$_message31):=true
					isConsumed(host1,$_message32):=true
					isConsumed(host1,$_message33):=true
					isConsumed(host1,$_message34):=true
					isConsumed(host1,$_message36):=true
					isConsumed(host1,$_message37):=true
					isConsumed(host1,$_message4):=false
					isConsumed(host1,$_message40):=true
					isConsumed(host1,$_message41):=true
					isConsumed(host1,$_message42):=true
					isConsumed(host1,$_message43):=true
					isConsumed(host1,$_message44):=true
					isConsumed(host1,$_message45):=true
					isConsumed(host1,$_message46):=true
					isConsumed(host1,$_message47):=true
					isConsumed(host1,$_message48):=true
					isConsumed(host1,$_message49):=true
					isConsumed(host1,$_message5):=false
					isConsumed(host1,$_message50):=true
					isConsumed(host1,$_message51):=true
					isConsumed(host1,$_message52):=true
					isConsumed(host1,$_message53):=true
					isConsumed(host1,$_message54):=true
					isConsumed(host1,$_message55):=true
					isConsumed(host1,$_message6):=false
					isConsumed(host1,$_message60):=true
					isConsumed(host1,$_message61):=true
					isConsumed(host1,$_message62):=true
					isConsumed(host1,$_message63):=true
					isConsumed(host1,$_message67):=true
					isConsumed(host1,$_message68):=true
					isConsumed(host1,$_message69):=true
					isConsumed(host1,$_message7):=false
					isConsumed(host1,$_message70):=true
					isConsumed(host1,$_message71):=true
					isConsumed(host1,$_message72):=true
					isConsumed(host1,$_message73):=true
					isConsumed(host1,$_message74):=true
					isConsumed(host1,$_message75):=true
					isConsumed(host1,$_message76):=true
					isConsumed(host1,$_message77):=true
					isConsumed(host1,$_message78):=true
					isConsumed(host1,$_message79):=true
					isConsumed(host1,$_message8):=false
					isConsumed(host1,$_message88):=true
					isConsumed(host1,$_message89):=true
					isConsumed(host1,$_message9):=false
					isConsumed(host1,$_message90):=true
					isConsumed(host1,$_message91):=true
					isConsumed(host1,$_message93):=false
					isConsumed(host1,$_message94):=false
					isConsumed(host1,$_message97):=true
					isConsumed(host1,$_message98):=true
					isConsumed(host1,$_message99):=true
					isConsumed(host10,$_message10):=true
					isConsumed(host10,$_message100):=false
					isConsumed(host10,$_message101):=false
					isConsumed(host10,$_message102):=false
					isConsumed(host10,$_message11):=true
					isConsumed(host10,$_message12):=true
					isConsumed(host10,$_message13):=true
					isConsumed(host10,$_message130):=false
					isConsumed(host10,$_message131):=false
					isConsumed(host10,$_message132):=false
					isConsumed(host10,$_message133):=false
					isConsumed(host10,$_message134):=false
					isConsumed(host10,$_message135):=false
					isConsumed(host10,$_message136):=false
					isConsumed(host10,$_message137):=false
					isConsumed(host10,$_message138):=false
					isConsumed(host10,$_message139):=false
					isConsumed(host10,$_message14):=true
					isConsumed(host10,$_message140):=false
					isConsumed(host10,$_message141):=false
					isConsumed(host10,$_message142):=false
					isConsumed(host10,$_message15):=true
					isConsumed(host10,$_message162):=false
					isConsumed(host10,$_message165):=false
					isConsumed(host10,$_message178):=false
					isConsumed(host10,$_message180):=false
					isConsumed(host10,$_message35):=true
					isConsumed(host10,$_message36):=false
					isConsumed(host10,$_message37):=false
					isConsumed(host10,$_message40):=false
					isConsumed(host10,$_message41):=false
					isConsumed(host10,$_message42):=false
					isConsumed(host10,$_message43):=false
					isConsumed(host10,$_message44):=false
					isConsumed(host10,$_message45):=false
					isConsumed(host10,$_message46):=false
					isConsumed(host10,$_message47):=false
					isConsumed(host10,$_message48):=false
					isConsumed(host10,$_message49):=false
					isConsumed(host10,$_message50):=false
					isConsumed(host10,$_message56):=false
					isConsumed(host10,$_message57):=false
					isConsumed(host10,$_message58):=false
					isConsumed(host10,$_message59):=false
					isConsumed(host10,$_message83):=false
					isConsumed(host10,$_message84):=false
					isConsumed(host10,$_message85):=false
					isConsumed(host10,$_message86):=false
					isConsumed(host10,$_message87):=false
					isConsumed(host10,$_message97):=false
					isConsumed(host10,$_message98):=false
					isConsumed(host10,$_message99):=false
					isConsumed(host11,$_message10):=true
					isConsumed(host11,$_message11):=true
					isConsumed(host11,$_message116):=true
					isConsumed(host11,$_message117):=true
					isConsumed(host11,$_message118):=true
					isConsumed(host11,$_message119):=true
					isConsumed(host11,$_message12):=true
					isConsumed(host11,$_message120):=true
					isConsumed(host11,$_message121):=true
					isConsumed(host11,$_message122):=true
					isConsumed(host11,$_message123):=true
					isConsumed(host11,$_message124):=true
					isConsumed(host11,$_message125):=true
					isConsumed(host11,$_message126):=true
					isConsumed(host11,$_message127):=true
					isConsumed(host11,$_message128):=true
					isConsumed(host11,$_message129):=true
					isConsumed(host11,$_message13):=true
					isConsumed(host11,$_message14):=true
					isConsumed(host11,$_message148):=false
					isConsumed(host11,$_message149):=false
					isConsumed(host11,$_message15):=true
					isConsumed(host11,$_message150):=false
					isConsumed(host11,$_message151):=false
					isConsumed(host11,$_message152):=false
					isConsumed(host11,$_message153):=false
					isConsumed(host11,$_message154):=false
					isConsumed(host11,$_message156):=false
					isConsumed(host11,$_message157):=false
					isConsumed(host11,$_message172):=false
					isConsumed(host11,$_message173):=false
					isConsumed(host11,$_message174):=false
					isConsumed(host11,$_message175):=false
					isConsumed(host11,$_message178):=false
					isConsumed(host11,$_message180):=false
					isConsumed(host11,$_message182):=false
					isConsumed(host11,$_message183):=false
					isConsumed(host11,$_message184):=false
					isConsumed(host11,$_message186):=false
					isConsumed(host11,$_message187):=false
					isConsumed(host11,$_message188):=false
					isConsumed(host11,$_message189):=false
					isConsumed(host11,$_message27):=false
					isConsumed(host11,$_message28):=false
					isConsumed(host11,$_message29):=false
					isConsumed(host11,$_message30):=false
					isConsumed(host11,$_message31):=false
					isConsumed(host11,$_message32):=false
					isConsumed(host11,$_message33):=false
					isConsumed(host11,$_message34):=false
					isConsumed(host11,$_message36):=true
					isConsumed(host11,$_message37):=true
					isConsumed(host11,$_message38):=true
					isConsumed(host11,$_message39):=true
					isConsumed(host11,$_message51):=true
					isConsumed(host11,$_message52):=true
					isConsumed(host11,$_message53):=true
					isConsumed(host11,$_message54):=true
					isConsumed(host11,$_message55):=true
					isConsumed(host11,$_message67):=true
					isConsumed(host11,$_message68):=true
					isConsumed(host11,$_message69):=true
					isConsumed(host11,$_message70):=true
					isConsumed(host11,$_message71):=true
					isConsumed(host11,$_message72):=true
					isConsumed(host11,$_message73):=true
					isConsumed(host11,$_message74):=true
					isConsumed(host11,$_message75):=true
					isConsumed(host11,$_message76):=true
					isConsumed(host11,$_message77):=true
					isConsumed(host11,$_message78):=true
					isConsumed(host11,$_message79):=true
					isConsumed(host11,$_message80):=true
					isConsumed(host11,$_message81):=true
					isConsumed(host11,$_message82):=true
					isConsumed(host12,$_message100):=true
					isConsumed(host12,$_message101):=true
					isConsumed(host12,$_message102):=true
					isConsumed(host12,$_message103):=true
					isConsumed(host12,$_message104):=true
					isConsumed(host12,$_message105):=true
					isConsumed(host12,$_message106):=true
					isConsumed(host12,$_message107):=true
					isConsumed(host12,$_message108):=true
					isConsumed(host12,$_message109):=true
					isConsumed(host12,$_message110):=true
					isConsumed(host12,$_message111):=true
					isConsumed(host12,$_message112):=true
					isConsumed(host12,$_message113):=true
					isConsumed(host12,$_message114):=true
					isConsumed(host12,$_message116):=true
					isConsumed(host12,$_message117):=true
					isConsumed(host12,$_message118):=true
					isConsumed(host12,$_message119):=true
					isConsumed(host12,$_message120):=true
					isConsumed(host12,$_message121):=true
					isConsumed(host12,$_message122):=true
					isConsumed(host12,$_message123):=true
					isConsumed(host12,$_message124):=true
					isConsumed(host12,$_message125):=true
					isConsumed(host12,$_message126):=true
					isConsumed(host12,$_message127):=true
					isConsumed(host12,$_message128):=true
					isConsumed(host12,$_message129):=true
					isConsumed(host12,$_message143):=false
					isConsumed(host12,$_message144):=false
					isConsumed(host12,$_message146):=false
					isConsumed(host12,$_message148):=false
					isConsumed(host12,$_message149):=false
					isConsumed(host12,$_message150):=false
					isConsumed(host12,$_message151):=false
					isConsumed(host12,$_message152):=false
					isConsumed(host12,$_message153):=false
					isConsumed(host12,$_message154):=false
					isConsumed(host12,$_message156):=false
					isConsumed(host12,$_message157):=false
					isConsumed(host12,$_message160):=false
					isConsumed(host12,$_message162):=false
					isConsumed(host12,$_message165):=false
					isConsumed(host12,$_message166):=false
					isConsumed(host12,$_message167):=false
					isConsumed(host12,$_message168):=false
					isConsumed(host12,$_message169):=false
					isConsumed(host12,$_message170):=false
					isConsumed(host12,$_message171):=false
					isConsumed(host12,$_message182):=false
					isConsumed(host12,$_message183):=false
					isConsumed(host12,$_message184):=false
					isConsumed(host12,$_message185):=false
					isConsumed(host12,$_message186):=false
					isConsumed(host12,$_message187):=false
					isConsumed(host12,$_message188):=false
					isConsumed(host12,$_message189):=false
					isConsumed(host12,$_message35):=false
					isConsumed(host12,$_message36):=true
					isConsumed(host12,$_message37):=true
					isConsumed(host12,$_message38):=true
					isConsumed(host12,$_message39):=true
					isConsumed(host12,$_message51):=true
					isConsumed(host12,$_message52):=true
					isConsumed(host12,$_message53):=true
					isConsumed(host12,$_message54):=true
					isConsumed(host12,$_message55):=true
					isConsumed(host12,$_message60):=true
					isConsumed(host12,$_message61):=true
					isConsumed(host12,$_message62):=true
					isConsumed(host12,$_message63):=true
					isConsumed(host12,$_message67):=true
					isConsumed(host12,$_message68):=true
					isConsumed(host12,$_message69):=true
					isConsumed(host12,$_message70):=true
					isConsumed(host12,$_message71):=true
					isConsumed(host12,$_message72):=true
					isConsumed(host12,$_message73):=true
					isConsumed(host12,$_message74):=true
					isConsumed(host12,$_message75):=true
					isConsumed(host12,$_message76):=true
					isConsumed(host12,$_message77):=true
					isConsumed(host12,$_message78):=true
					isConsumed(host12,$_message79):=true
					isConsumed(host12,$_message93):=true
					isConsumed(host12,$_message94):=true
					isConsumed(host12,$_message95):=true
					isConsumed(host12,$_message96):=true
					isConsumed(host12,$_message97):=true
					isConsumed(host12,$_message98):=true
					isConsumed(host12,$_message99):=true
					isConsumed(host13,$_message100):=true
					isConsumed(host13,$_message101):=true
					isConsumed(host13,$_message102):=true
					isConsumed(host13,$_message115):=true
					isConsumed(host13,$_message116):=true
					isConsumed(host13,$_message117):=true
					isConsumed(host13,$_message118):=true
					isConsumed(host13,$_message119):=true
					isConsumed(host13,$_message120):=true
					isConsumed(host13,$_message121):=true
					isConsumed(host13,$_message122):=true
					isConsumed(host13,$_message123):=true
					isConsumed(host13,$_message124):=true
					isConsumed(host13,$_message125):=true
					isConsumed(host13,$_message126):=true
					isConsumed(host13,$_message127):=true
					isConsumed(host13,$_message128):=true
					isConsumed(host13,$_message129):=true
					isConsumed(host13,$_message148):=false
					isConsumed(host13,$_message149):=false
					isConsumed(host13,$_message150):=false
					isConsumed(host13,$_message151):=false
					isConsumed(host13,$_message152):=false
					isConsumed(host13,$_message153):=false
					isConsumed(host13,$_message154):=false
					isConsumed(host13,$_message156):=false
					isConsumed(host13,$_message157):=false
					isConsumed(host13,$_message16):=true
					isConsumed(host13,$_message162):=false
					isConsumed(host13,$_message165):=false
					isConsumed(host13,$_message17):=true
					isConsumed(host13,$_message18):=true
					isConsumed(host13,$_message182):=false
					isConsumed(host13,$_message183):=false
					isConsumed(host13,$_message184):=false
					isConsumed(host13,$_message186):=false
					isConsumed(host13,$_message187):=false
					isConsumed(host13,$_message188):=false
					isConsumed(host13,$_message189):=false
					isConsumed(host13,$_message19):=true
					isConsumed(host13,$_message20):=true
					isConsumed(host13,$_message21):=true
					isConsumed(host13,$_message22):=true
					isConsumed(host13,$_message23):=true
					isConsumed(host13,$_message24):=true
					isConsumed(host13,$_message25):=true
					isConsumed(host13,$_message26):=true
					isConsumed(host13,$_message36):=true
					isConsumed(host13,$_message37):=true
					isConsumed(host13,$_message38):=true
					isConsumed(host13,$_message39):=true
					isConsumed(host13,$_message40):=true
					isConsumed(host13,$_message41):=true
					isConsumed(host13,$_message42):=true
					isConsumed(host13,$_message43):=true
					isConsumed(host13,$_message44):=true
					isConsumed(host13,$_message45):=true
					isConsumed(host13,$_message46):=true
					isConsumed(host13,$_message47):=true
					isConsumed(host13,$_message48):=true
					isConsumed(host13,$_message49):=true
					isConsumed(host13,$_message50):=true
					isConsumed(host13,$_message51):=true
					isConsumed(host13,$_message52):=true
					isConsumed(host13,$_message53):=true
					isConsumed(host13,$_message54):=true
					isConsumed(host13,$_message55):=true
					isConsumed(host13,$_message60):=false
					isConsumed(host13,$_message61):=false
					isConsumed(host13,$_message62):=false
					isConsumed(host13,$_message63):=false
					isConsumed(host13,$_message67):=true
					isConsumed(host13,$_message68):=true
					isConsumed(host13,$_message69):=true
					isConsumed(host13,$_message70):=true
					isConsumed(host13,$_message71):=true
					isConsumed(host13,$_message72):=true
					isConsumed(host13,$_message73):=true
					isConsumed(host13,$_message74):=true
					isConsumed(host13,$_message75):=true
					isConsumed(host13,$_message76):=true
					isConsumed(host13,$_message77):=true
					isConsumed(host13,$_message78):=true
					isConsumed(host13,$_message79):=true
					isConsumed(host13,$_message93):=true
					isConsumed(host13,$_message94):=true
					isConsumed(host13,$_message95):=true
					isConsumed(host13,$_message96):=true
					isConsumed(host13,$_message97):=true
					isConsumed(host13,$_message98):=true
					isConsumed(host13,$_message99):=true
					isConsumed(host14,$_message1):=true
					isConsumed(host14,$_message103):=true
					isConsumed(host14,$_message104):=true
					isConsumed(host14,$_message105):=true
					isConsumed(host14,$_message106):=true
					isConsumed(host14,$_message107):=true
					isConsumed(host14,$_message108):=true
					isConsumed(host14,$_message109):=true
					isConsumed(host14,$_message110):=true
					isConsumed(host14,$_message111):=true
					isConsumed(host14,$_message112):=true
					isConsumed(host14,$_message113):=true
					isConsumed(host14,$_message114):=true
					isConsumed(host14,$_message140):=false
					isConsumed(host14,$_message141):=false
					isConsumed(host14,$_message142):=false
					isConsumed(host14,$_message143):=false
					isConsumed(host14,$_message144):=false
					isConsumed(host14,$_message146):=false
					isConsumed(host14,$_message16):=true
					isConsumed(host14,$_message162):=false
					isConsumed(host14,$_message165):=false
					isConsumed(host14,$_message166):=false
					isConsumed(host14,$_message167):=false
					isConsumed(host14,$_message168):=false
					isConsumed(host14,$_message17):=true
					isConsumed(host14,$_message171):=false
					isConsumed(host14,$_message172):=false
					isConsumed(host14,$_message173):=false
					isConsumed(host14,$_message174):=false
					isConsumed(host14,$_message175):=false
					isConsumed(host14,$_message178):=false
					isConsumed(host14,$_message18):=true
					isConsumed(host14,$_message180):=false
					isConsumed(host14,$_message19):=true
					isConsumed(host14,$_message2):=true
					isConsumed(host14,$_message20):=true
					isConsumed(host14,$_message21):=true
					isConsumed(host14,$_message22):=true
					isConsumed(host14,$_message23):=true
					isConsumed(host14,$_message24):=true
					isConsumed(host14,$_message25):=true
					isConsumed(host14,$_message26):=true
					isConsumed(host14,$_message27):=true
					isConsumed(host14,$_message28):=true
					isConsumed(host14,$_message29):=true
					isConsumed(host14,$_message3):=true
					isConsumed(host14,$_message30):=true
					isConsumed(host14,$_message31):=true
					isConsumed(host14,$_message32):=true
					isConsumed(host14,$_message33):=true
					isConsumed(host14,$_message34):=true
					isConsumed(host14,$_message35):=true
					isConsumed(host14,$_message38):=true
					isConsumed(host14,$_message39):=true
					isConsumed(host14,$_message4):=true
					isConsumed(host14,$_message40):=false
					isConsumed(host14,$_message41):=false
					isConsumed(host14,$_message42):=false
					isConsumed(host14,$_message43):=false
					isConsumed(host14,$_message44):=false
					isConsumed(host14,$_message45):=false
					isConsumed(host14,$_message46):=false
					isConsumed(host14,$_message47):=false
					isConsumed(host14,$_message48):=false
					isConsumed(host14,$_message49):=false
					isConsumed(host14,$_message5):=true
					isConsumed(host14,$_message50):=false
					isConsumed(host14,$_message51):=false
					isConsumed(host14,$_message52):=false
					isConsumed(host14,$_message53):=false
					isConsumed(host14,$_message54):=false
					isConsumed(host14,$_message55):=false
					isConsumed(host14,$_message6):=true
					isConsumed(host14,$_message60):=true
					isConsumed(host14,$_message61):=true
					isConsumed(host14,$_message62):=true
					isConsumed(host14,$_message63):=true
					isConsumed(host14,$_message64):=true
					isConsumed(host14,$_message65):=true
					isConsumed(host14,$_message67):=true
					isConsumed(host14,$_message68):=true
					isConsumed(host14,$_message69):=true
					isConsumed(host14,$_message7):=true
					isConsumed(host14,$_message70):=true
					isConsumed(host14,$_message71):=true
					isConsumed(host14,$_message72):=true
					isConsumed(host14,$_message73):=true
					isConsumed(host14,$_message74):=true
					isConsumed(host14,$_message75):=true
					isConsumed(host14,$_message76):=true
					isConsumed(host14,$_message77):=true
					isConsumed(host14,$_message78):=true
					isConsumed(host14,$_message79):=true
					isConsumed(host14,$_message8):=true
					isConsumed(host14,$_message80):=true
					isConsumed(host14,$_message81):=true
					isConsumed(host14,$_message82):=true
					isConsumed(host14,$_message83):=true
					isConsumed(host14,$_message84):=true
					isConsumed(host14,$_message85):=true
					isConsumed(host14,$_message86):=true
					isConsumed(host14,$_message87):=true
					isConsumed(host14,$_message88):=true
					isConsumed(host14,$_message89):=true
					isConsumed(host14,$_message9):=true
					isConsumed(host14,$_message90):=true
					isConsumed(host14,$_message91):=true
					isConsumed(host14,$_message92):=true
					isConsumed(host14,$_message93):=false
					isConsumed(host14,$_message94):=false
					isConsumed(host15,$_message115):=false
					isConsumed(host15,$_message116):=false
					isConsumed(host15,$_message117):=false
					isConsumed(host15,$_message118):=false
					isConsumed(host15,$_message119):=false
					isConsumed(host15,$_message120):=false
					isConsumed(host15,$_message121):=false
					isConsumed(host15,$_message122):=false
					isConsumed(host15,$_message123):=false
					isConsumed(host15,$_message124):=false
					isConsumed(host15,$_message125):=false
					isConsumed(host15,$_message126):=false
					isConsumed(host15,$_message127):=false
					isConsumed(host15,$_message128):=false
					isConsumed(host15,$_message129):=false
					isConsumed(host15,$_message130):=false
					isConsumed(host15,$_message131):=false
					isConsumed(host15,$_message132):=false
					isConsumed(host15,$_message133):=false
					isConsumed(host15,$_message134):=false
					isConsumed(host15,$_message135):=false
					isConsumed(host15,$_message136):=false
					isConsumed(host15,$_message137):=false
					isConsumed(host15,$_message138):=false
					isConsumed(host15,$_message139):=false
					isConsumed(host15,$_message140):=false
					isConsumed(host15,$_message141):=false
					isConsumed(host15,$_message142):=false
					isConsumed(host15,$_message16):=true
					isConsumed(host15,$_message166):=false
					isConsumed(host15,$_message167):=false
					isConsumed(host15,$_message168):=false
					isConsumed(host15,$_message17):=true
					isConsumed(host15,$_message171):=false
					isConsumed(host15,$_message172):=false
					isConsumed(host15,$_message173):=false
					isConsumed(host15,$_message174):=false
					isConsumed(host15,$_message175):=false
					isConsumed(host15,$_message178):=false
					isConsumed(host15,$_message18):=true
					isConsumed(host15,$_message180):=false
					isConsumed(host15,$_message182):=false
					isConsumed(host15,$_message183):=false
					isConsumed(host15,$_message184):=false
					isConsumed(host15,$_message186):=false
					isConsumed(host15,$_message187):=false
					isConsumed(host15,$_message188):=false
					isConsumed(host15,$_message189):=false
					isConsumed(host15,$_message19):=true
					isConsumed(host15,$_message20):=true
					isConsumed(host15,$_message21):=true
					isConsumed(host15,$_message22):=true
					isConsumed(host15,$_message23):=true
					isConsumed(host15,$_message24):=true
					isConsumed(host15,$_message25):=true
					isConsumed(host15,$_message26):=true
					isConsumed(host15,$_message35):=true
					isConsumed(host15,$_message36):=false
					isConsumed(host15,$_message37):=false
					isConsumed(host15,$_message38):=true
					isConsumed(host15,$_message39):=true
					isConsumed(host15,$_message56):=false
					isConsumed(host15,$_message57):=false
					isConsumed(host15,$_message58):=false
					isConsumed(host15,$_message59):=false
					isConsumed(host15,$_message67):=false
					isConsumed(host15,$_message68):=false
					isConsumed(host15,$_message69):=false
					isConsumed(host15,$_message70):=false
					isConsumed(host15,$_message71):=false
					isConsumed(host15,$_message72):=false
					isConsumed(host15,$_message73):=false
					isConsumed(host15,$_message74):=false
					isConsumed(host15,$_message75):=false
					isConsumed(host15,$_message76):=false
					isConsumed(host15,$_message77):=false
					isConsumed(host15,$_message78):=false
					isConsumed(host15,$_message79):=false
					isConsumed(host15,$_message80):=false
					isConsumed(host15,$_message81):=false
					isConsumed(host15,$_message82):=false
					isConsumed(host15,$_message83):=false
					isConsumed(host15,$_message84):=false
					isConsumed(host15,$_message85):=false
					isConsumed(host15,$_message86):=false
					isConsumed(host15,$_message87):=false
					isConsumed(host15,$_message88):=false
					isConsumed(host15,$_message89):=false
					isConsumed(host15,$_message90):=false
					isConsumed(host15,$_message91):=false
					isConsumed(host16,$_message103):=false
					isConsumed(host16,$_message104):=false
					isConsumed(host16,$_message105):=false
					isConsumed(host16,$_message106):=false
					isConsumed(host16,$_message107):=false
					isConsumed(host16,$_message108):=false
					isConsumed(host16,$_message109):=false
					isConsumed(host16,$_message110):=false
					isConsumed(host16,$_message111):=false
					isConsumed(host16,$_message112):=false
					isConsumed(host16,$_message113):=false
					isConsumed(host16,$_message114):=false
					isConsumed(host16,$_message115):=false
					isConsumed(host16,$_message116):=false
					isConsumed(host16,$_message117):=false
					isConsumed(host16,$_message118):=false
					isConsumed(host16,$_message119):=false
					isConsumed(host16,$_message120):=false
					isConsumed(host16,$_message121):=false
					isConsumed(host16,$_message122):=false
					isConsumed(host16,$_message123):=false
					isConsumed(host16,$_message124):=false
					isConsumed(host16,$_message125):=false
					isConsumed(host16,$_message126):=false
					isConsumed(host16,$_message127):=false
					isConsumed(host16,$_message128):=false
					isConsumed(host16,$_message129):=false
					isConsumed(host16,$_message143):=false
					isConsumed(host16,$_message144):=false
					isConsumed(host16,$_message146):=false
					isConsumed(host16,$_message16):=false
					isConsumed(host16,$_message162):=false
					isConsumed(host16,$_message165):=false
					isConsumed(host16,$_message166):=false
					isConsumed(host16,$_message167):=false
					isConsumed(host16,$_message168):=false
					isConsumed(host16,$_message17):=false
					isConsumed(host16,$_message171):=false
					isConsumed(host16,$_message178):=false
					isConsumed(host16,$_message18):=false
					isConsumed(host16,$_message180):=false
					isConsumed(host16,$_message182):=false
					isConsumed(host16,$_message183):=false
					isConsumed(host16,$_message184):=false
					isConsumed(host16,$_message186):=false
					isConsumed(host16,$_message187):=false
					isConsumed(host16,$_message188):=false
					isConsumed(host16,$_message189):=false
					isConsumed(host16,$_message19):=false
					isConsumed(host16,$_message20):=false
					isConsumed(host16,$_message21):=false
					isConsumed(host16,$_message22):=false
					isConsumed(host16,$_message23):=false
					isConsumed(host16,$_message24):=false
					isConsumed(host16,$_message25):=false
					isConsumed(host16,$_message26):=false
					isConsumed(host16,$_message27):=false
					isConsumed(host16,$_message28):=false
					isConsumed(host16,$_message29):=false
					isConsumed(host16,$_message30):=false
					isConsumed(host16,$_message31):=false
					isConsumed(host16,$_message32):=false
					isConsumed(host16,$_message33):=false
					isConsumed(host16,$_message34):=false
					isConsumed(host16,$_message35):=false
					isConsumed(host16,$_message40):=false
					isConsumed(host16,$_message41):=false
					isConsumed(host16,$_message42):=false
					isConsumed(host16,$_message43):=false
					isConsumed(host16,$_message44):=false
					isConsumed(host16,$_message45):=false
					isConsumed(host16,$_message46):=false
					isConsumed(host16,$_message47):=false
					isConsumed(host16,$_message48):=false
					isConsumed(host16,$_message49):=false
					isConsumed(host16,$_message50):=false
					isConsumed(host16,$_message56):=false
					isConsumed(host16,$_message57):=false
					isConsumed(host16,$_message58):=false
					isConsumed(host16,$_message59):=false
					isConsumed(host16,$_message60):=false
					isConsumed(host16,$_message61):=false
					isConsumed(host16,$_message62):=false
					isConsumed(host16,$_message63):=false
					isConsumed(host16,$_message64):=false
					isConsumed(host16,$_message65):=false
					isConsumed(host16,$_message83):=false
					isConsumed(host16,$_message84):=false
					isConsumed(host16,$_message85):=false
					isConsumed(host16,$_message86):=false
					isConsumed(host16,$_message87):=false
					isConsumed(host16,$_message88):=false
					isConsumed(host16,$_message89):=false
					isConsumed(host16,$_message90):=false
					isConsumed(host16,$_message91):=false
					isConsumed(host16,$_message95):=false
					isConsumed(host16,$_message96):=false
					isConsumed(host17,$_message100):=false
					isConsumed(host17,$_message101):=false
					isConsumed(host17,$_message102):=false
					isConsumed(host17,$_message103):=false
					isConsumed(host17,$_message104):=false
					isConsumed(host17,$_message105):=false
					isConsumed(host17,$_message106):=false
					isConsumed(host17,$_message107):=false
					isConsumed(host17,$_message108):=false
					isConsumed(host17,$_message109):=false
					isConsumed(host17,$_message110):=false
					isConsumed(host17,$_message111):=false
					isConsumed(host17,$_message112):=false
					isConsumed(host17,$_message113):=false
					isConsumed(host17,$_message114):=false
					isConsumed(host17,$_message116):=false
					isConsumed(host17,$_message117):=false
					isConsumed(host17,$_message118):=false
					isConsumed(host17,$_message119):=false
					isConsumed(host17,$_message120):=false
					isConsumed(host17,$_message121):=false
					isConsumed(host17,$_message122):=false
					isConsumed(host17,$_message123):=false
					isConsumed(host17,$_message124):=false
					isConsumed(host17,$_message125):=false
					isConsumed(host17,$_message126):=false
					isConsumed(host17,$_message127):=false
					isConsumed(host17,$_message128):=false
					isConsumed(host17,$_message129):=false
					isConsumed(host17,$_message140):=false
					isConsumed(host17,$_message141):=false
					isConsumed(host17,$_message142):=false
					isConsumed(host17,$_message148):=false
					isConsumed(host17,$_message149):=false
					isConsumed(host17,$_message150):=false
					isConsumed(host17,$_message151):=false
					isConsumed(host17,$_message152):=false
					isConsumed(host17,$_message153):=false
					isConsumed(host17,$_message154):=false
					isConsumed(host17,$_message155):=false
					isConsumed(host17,$_message156):=false
					isConsumed(host17,$_message157):=false
					isConsumed(host17,$_message161):=false
					isConsumed(host17,$_message162):=false
					isConsumed(host17,$_message163):=false
					isConsumed(host17,$_message165):=false
					isConsumed(host17,$_message178):=false
					isConsumed(host17,$_message180):=false
					isConsumed(host17,$_message182):=false
					isConsumed(host17,$_message183):=false
					isConsumed(host17,$_message184):=false
					isConsumed(host17,$_message186):=false
					isConsumed(host17,$_message187):=false
					isConsumed(host17,$_message188):=false
					isConsumed(host17,$_message189):=false
					isConsumed(host17,$_message27):=true
					isConsumed(host17,$_message28):=true
					isConsumed(host17,$_message29):=true
					isConsumed(host17,$_message30):=true
					isConsumed(host17,$_message31):=true
					isConsumed(host17,$_message32):=true
					isConsumed(host17,$_message33):=true
					isConsumed(host17,$_message34):=true
					isConsumed(host17,$_message36):=true
					isConsumed(host17,$_message37):=true
					isConsumed(host17,$_message40):=true
					isConsumed(host17,$_message41):=true
					isConsumed(host17,$_message42):=true
					isConsumed(host17,$_message43):=true
					isConsumed(host17,$_message44):=true
					isConsumed(host17,$_message45):=true
					isConsumed(host17,$_message46):=true
					isConsumed(host17,$_message47):=true
					isConsumed(host17,$_message48):=true
					isConsumed(host17,$_message49):=true
					isConsumed(host17,$_message50):=true
					isConsumed(host17,$_message51):=true
					isConsumed(host17,$_message52):=true
					isConsumed(host17,$_message53):=true
					isConsumed(host17,$_message54):=true
					isConsumed(host17,$_message55):=true
					isConsumed(host17,$_message64):=false
					isConsumed(host17,$_message65):=false
					isConsumed(host17,$_message67):=false
					isConsumed(host17,$_message68):=false
					isConsumed(host17,$_message69):=false
					isConsumed(host17,$_message70):=false
					isConsumed(host17,$_message71):=false
					isConsumed(host17,$_message72):=false
					isConsumed(host17,$_message73):=false
					isConsumed(host17,$_message74):=false
					isConsumed(host17,$_message75):=false
					isConsumed(host17,$_message76):=false
					isConsumed(host17,$_message77):=false
					isConsumed(host17,$_message78):=false
					isConsumed(host17,$_message79):=false
					isConsumed(host17,$_message83):=false
					isConsumed(host17,$_message84):=false
					isConsumed(host17,$_message85):=false
					isConsumed(host17,$_message86):=false
					isConsumed(host17,$_message87):=false
					isConsumed(host17,$_message93):=false
					isConsumed(host17,$_message94):=false
					isConsumed(host17,$_message95):=false
					isConsumed(host17,$_message96):=false
					isConsumed(host17,$_message97):=false
					isConsumed(host17,$_message98):=false
					isConsumed(host17,$_message99):=false
					isConsumed(host18,$_message116):=false
					isConsumed(host18,$_message117):=false
					isConsumed(host18,$_message118):=false
					isConsumed(host18,$_message119):=false
					isConsumed(host18,$_message120):=false
					isConsumed(host18,$_message121):=false
					isConsumed(host18,$_message122):=false
					isConsumed(host18,$_message123):=false
					isConsumed(host18,$_message124):=false
					isConsumed(host18,$_message125):=false
					isConsumed(host18,$_message126):=false
					isConsumed(host18,$_message127):=false
					isConsumed(host18,$_message128):=false
					isConsumed(host18,$_message129):=false
					isConsumed(host18,$_message140):=false
					isConsumed(host18,$_message141):=false
					isConsumed(host18,$_message142):=false
					isConsumed(host18,$_message143):=false
					isConsumed(host18,$_message144):=false
					isConsumed(host18,$_message146):=false
					isConsumed(host18,$_message172):=false
					isConsumed(host18,$_message173):=false
					isConsumed(host18,$_message174):=false
					isConsumed(host18,$_message175):=false
					isConsumed(host18,$_message182):=false
					isConsumed(host18,$_message183):=false
					isConsumed(host18,$_message184):=false
					isConsumed(host18,$_message186):=false
					isConsumed(host18,$_message187):=false
					isConsumed(host18,$_message188):=false
					isConsumed(host18,$_message189):=false
					isConsumed(host18,$_message35):=true
					isConsumed(host18,$_message36):=true
					isConsumed(host18,$_message37):=true
					isConsumed(host18,$_message56):=false
					isConsumed(host18,$_message57):=false
					isConsumed(host18,$_message58):=false
					isConsumed(host18,$_message59):=false
					isConsumed(host18,$_message60):=false
					isConsumed(host18,$_message61):=false
					isConsumed(host18,$_message62):=false
					isConsumed(host18,$_message63):=false
					isConsumed(host18,$_message80):=false
					isConsumed(host18,$_message81):=false
					isConsumed(host18,$_message82):=false
					isConsumed(host18,$_message83):=false
					isConsumed(host18,$_message84):=false
					isConsumed(host18,$_message85):=false
					isConsumed(host18,$_message86):=false
					isConsumed(host18,$_message87):=false
					isConsumed(host18,$_message88):=false
					isConsumed(host18,$_message89):=false
					isConsumed(host18,$_message90):=false
					isConsumed(host18,$_message91):=false
					isConsumed(host18,$_message95):=false
					isConsumed(host18,$_message96):=false
					isConsumed(host2,$_message116):=false
					isConsumed(host2,$_message117):=false
					isConsumed(host2,$_message118):=false
					isConsumed(host2,$_message119):=false
					isConsumed(host2,$_message120):=false
					isConsumed(host2,$_message121):=false
					isConsumed(host2,$_message122):=false
					isConsumed(host2,$_message123):=false
					isConsumed(host2,$_message124):=false
					isConsumed(host2,$_message125):=false
					isConsumed(host2,$_message126):=false
					isConsumed(host2,$_message127):=false
					isConsumed(host2,$_message128):=false
					isConsumed(host2,$_message129):=false
					isConsumed(host2,$_message143):=false
					isConsumed(host2,$_message144):=false
					isConsumed(host2,$_message145):=false
					isConsumed(host2,$_message146):=false
					isConsumed(host2,$_message148):=false
					isConsumed(host2,$_message149):=false
					isConsumed(host2,$_message150):=false
					isConsumed(host2,$_message151):=false
					isConsumed(host2,$_message152):=false
					isConsumed(host2,$_message153):=false
					isConsumed(host2,$_message154):=false
					isConsumed(host2,$_message156):=false
					isConsumed(host2,$_message157):=false
					isConsumed(host2,$_message159):=false
					isConsumed(host2,$_message172):=false
					isConsumed(host2,$_message173):=false
					isConsumed(host2,$_message174):=false
					isConsumed(host2,$_message175):=false
					isConsumed(host2,$_message176):=false
					isConsumed(host2,$_message182):=false
					isConsumed(host2,$_message183):=false
					isConsumed(host2,$_message184):=false
					isConsumed(host2,$_message186):=false
					isConsumed(host2,$_message187):=false
					isConsumed(host2,$_message188):=false
					isConsumed(host2,$_message189):=false
					isConsumed(host2,$_message36):=false
					isConsumed(host2,$_message37):=false
					isConsumed(host2,$_message60):=false
					isConsumed(host2,$_message61):=false
					isConsumed(host2,$_message62):=false
					isConsumed(host2,$_message63):=false
					isConsumed(host2,$_message64):=false
					isConsumed(host2,$_message65):=false
					isConsumed(host2,$_message80):=false
					isConsumed(host2,$_message81):=false
					isConsumed(host2,$_message82):=false
					isConsumed(host2,$_message83):=false
					isConsumed(host2,$_message84):=false
					isConsumed(host2,$_message85):=false
					isConsumed(host2,$_message86):=false
					isConsumed(host2,$_message87):=false
					isConsumed(host2,$_message88):=false
					isConsumed(host2,$_message89):=false
					isConsumed(host2,$_message90):=false
					isConsumed(host2,$_message91):=false
					isConsumed(host3,$_message116):=false
					isConsumed(host3,$_message117):=false
					isConsumed(host3,$_message118):=false
					isConsumed(host3,$_message119):=false
					isConsumed(host3,$_message120):=false
					isConsumed(host3,$_message121):=false
					isConsumed(host3,$_message122):=false
					isConsumed(host3,$_message123):=false
					isConsumed(host3,$_message124):=false
					isConsumed(host3,$_message125):=false
					isConsumed(host3,$_message126):=false
					isConsumed(host3,$_message127):=false
					isConsumed(host3,$_message128):=false
					isConsumed(host3,$_message129):=false
					isConsumed(host3,$_message130):=false
					isConsumed(host3,$_message131):=false
					isConsumed(host3,$_message132):=false
					isConsumed(host3,$_message133):=false
					isConsumed(host3,$_message134):=false
					isConsumed(host3,$_message135):=false
					isConsumed(host3,$_message136):=false
					isConsumed(host3,$_message137):=false
					isConsumed(host3,$_message138):=false
					isConsumed(host3,$_message139):=false
					isConsumed(host3,$_message140):=false
					isConsumed(host3,$_message141):=false
					isConsumed(host3,$_message142):=false
					isConsumed(host3,$_message143):=false
					isConsumed(host3,$_message144):=false
					isConsumed(host3,$_message146):=false
					isConsumed(host3,$_message162):=false
					isConsumed(host3,$_message165):=false
					isConsumed(host3,$_message172):=false
					isConsumed(host3,$_message173):=false
					isConsumed(host3,$_message174):=false
					isConsumed(host3,$_message175):=false
					isConsumed(host3,$_message182):=false
					isConsumed(host3,$_message183):=false
					isConsumed(host3,$_message184):=false
					isConsumed(host3,$_message186):=false
					isConsumed(host3,$_message187):=false
					isConsumed(host3,$_message188):=false
					isConsumed(host3,$_message189):=false
					isConsumed(host3,$_message35):=true
					isConsumed(host3,$_message40):=true
					isConsumed(host3,$_message41):=true
					isConsumed(host3,$_message42):=true
					isConsumed(host3,$_message43):=true
					isConsumed(host3,$_message44):=true
					isConsumed(host3,$_message45):=true
					isConsumed(host3,$_message46):=true
					isConsumed(host3,$_message47):=true
					isConsumed(host3,$_message48):=true
					isConsumed(host3,$_message49):=true
					isConsumed(host3,$_message50):=true
					isConsumed(host3,$_message56):=false
					isConsumed(host3,$_message57):=false
					isConsumed(host3,$_message58):=false
					isConsumed(host3,$_message59):=false
					isConsumed(host3,$_message60):=false
					isConsumed(host3,$_message61):=false
					isConsumed(host3,$_message62):=false
					isConsumed(host3,$_message63):=false
					isConsumed(host3,$_message64):=false
					isConsumed(host3,$_message65):=false
					isConsumed(host3,$_message80):=false
					isConsumed(host3,$_message81):=false
					isConsumed(host3,$_message82):=false
					isConsumed(host3,$_message88):=false
					isConsumed(host3,$_message89):=false
					isConsumed(host3,$_message90):=false
					isConsumed(host3,$_message91):=false
					isConsumed(host3,$_message93):=false
					isConsumed(host3,$_message94):=false
					isConsumed(host4,$_message103):=true
					isConsumed(host4,$_message104):=true
					isConsumed(host4,$_message105):=true
					isConsumed(host4,$_message106):=true
					isConsumed(host4,$_message107):=true
					isConsumed(host4,$_message108):=true
					isConsumed(host4,$_message109):=true
					isConsumed(host4,$_message110):=true
					isConsumed(host4,$_message111):=true
					isConsumed(host4,$_message112):=true
					isConsumed(host4,$_message113):=true
					isConsumed(host4,$_message114):=true
					isConsumed(host4,$_message130):=true
					isConsumed(host4,$_message131):=true
					isConsumed(host4,$_message132):=true
					isConsumed(host4,$_message133):=true
					isConsumed(host4,$_message134):=true
					isConsumed(host4,$_message135):=true
					isConsumed(host4,$_message136):=true
					isConsumed(host4,$_message137):=true
					isConsumed(host4,$_message138):=true
					isConsumed(host4,$_message139):=true
					isConsumed(host4,$_message148):=false
					isConsumed(host4,$_message149):=false
					isConsumed(host4,$_message150):=false
					isConsumed(host4,$_message151):=false
					isConsumed(host4,$_message152):=false
					isConsumed(host4,$_message153):=false
					isConsumed(host4,$_message154):=false
					isConsumed(host4,$_message156):=false
					isConsumed(host4,$_message157):=false
					isConsumed(host4,$_message16):=false
					isConsumed(host4,$_message162):=false
					isConsumed(host4,$_message165):=false
					isConsumed(host4,$_message17):=false
					isConsumed(host4,$_message172):=false
					isConsumed(host4,$_message173):=false
					isConsumed(host4,$_message174):=false
					isConsumed(host4,$_message175):=false
					isConsumed(host4,$_message177):=false
					isConsumed(host4,$_message178):=false
					isConsumed(host4,$_message18):=false
					isConsumed(host4,$_message180):=false
					isConsumed(host4,$_message182):=false
					isConsumed(host4,$_message183):=false
					isConsumed(host4,$_message184):=false
					isConsumed(host4,$_message186):=false
					isConsumed(host4,$_message187):=false
					isConsumed(host4,$_message188):=false
					isConsumed(host4,$_message189):=false
					isConsumed(host4,$_message19):=false
					isConsumed(host4,$_message20):=false
					isConsumed(host4,$_message21):=false
					isConsumed(host4,$_message22):=false
					isConsumed(host4,$_message23):=false
					isConsumed(host4,$_message24):=false
					isConsumed(host4,$_message25):=false
					isConsumed(host4,$_message26):=false
					isConsumed(host4,$_message35):=true
					isConsumed(host4,$_message36):=true
					isConsumed(host4,$_message37):=true
					isConsumed(host4,$_message38):=true
					isConsumed(host4,$_message39):=true
					isConsumed(host4,$_message40):=true
					isConsumed(host4,$_message41):=true
					isConsumed(host4,$_message42):=true
					isConsumed(host4,$_message43):=true
					isConsumed(host4,$_message44):=true
					isConsumed(host4,$_message45):=true
					isConsumed(host4,$_message46):=true
					isConsumed(host4,$_message47):=true
					isConsumed(host4,$_message48):=true
					isConsumed(host4,$_message49):=true
					isConsumed(host4,$_message50):=true
					isConsumed(host4,$_message56):=false
					isConsumed(host4,$_message57):=false
					isConsumed(host4,$_message58):=false
					isConsumed(host4,$_message59):=false
					isConsumed(host4,$_message64):=true
					isConsumed(host4,$_message65):=true
					isConsumed(host4,$_message67):=true
					isConsumed(host4,$_message68):=true
					isConsumed(host4,$_message69):=true
					isConsumed(host4,$_message70):=true
					isConsumed(host4,$_message71):=true
					isConsumed(host4,$_message72):=true
					isConsumed(host4,$_message73):=true
					isConsumed(host4,$_message74):=true
					isConsumed(host4,$_message75):=true
					isConsumed(host4,$_message76):=true
					isConsumed(host4,$_message77):=true
					isConsumed(host4,$_message78):=true
					isConsumed(host4,$_message79):=true
					isConsumed(host4,$_message80):=true
					isConsumed(host4,$_message81):=true
					isConsumed(host4,$_message82):=true
					isConsumed(host4,$_message83):=true
					isConsumed(host4,$_message84):=true
					isConsumed(host4,$_message85):=true
					isConsumed(host4,$_message86):=true
					isConsumed(host4,$_message87):=true
					isConsumed(host4,$_message93):=true
					isConsumed(host4,$_message94):=true
					isConsumed(host4,$_message95):=true
					isConsumed(host4,$_message96):=true
					isConsumed(host5,$_message100):=false
					isConsumed(host5,$_message101):=false
					isConsumed(host5,$_message102):=false
					isConsumed(host5,$_message115):=false
					isConsumed(host5,$_message148):=false
					isConsumed(host5,$_message149):=false
					isConsumed(host5,$_message150):=false
					isConsumed(host5,$_message151):=false
					isConsumed(host5,$_message152):=false
					isConsumed(host5,$_message153):=false
					isConsumed(host5,$_message154):=false
					isConsumed(host5,$_message156):=false
					isConsumed(host5,$_message157):=false
					isConsumed(host5,$_message178):=false
					isConsumed(host5,$_message180):=false
					isConsumed(host5,$_message182):=false
					isConsumed(host5,$_message183):=false
					isConsumed(host5,$_message184):=false
					isConsumed(host5,$_message186):=false
					isConsumed(host5,$_message187):=false
					isConsumed(host5,$_message188):=false
					isConsumed(host5,$_message189):=false
					isConsumed(host5,$_message36):=false
					isConsumed(host5,$_message37):=false
					isConsumed(host5,$_message83):=false
					isConsumed(host5,$_message84):=false
					isConsumed(host5,$_message85):=false
					isConsumed(host5,$_message86):=false
					isConsumed(host5,$_message87):=false
					isConsumed(host5,$_message88):=false
					isConsumed(host5,$_message89):=false
					isConsumed(host5,$_message90):=false
					isConsumed(host5,$_message91):=false
					isConsumed(host5,$_message93):=false
					isConsumed(host5,$_message94):=false
					isConsumed(host5,$_message97):=false
					isConsumed(host5,$_message98):=false
					isConsumed(host5,$_message99):=false
					isConsumed(host6,$_message1):=true
					isConsumed(host6,$_message10):=true
					isConsumed(host6,$_message100):=false
					isConsumed(host6,$_message101):=false
					isConsumed(host6,$_message102):=false
					isConsumed(host6,$_message11):=true
					isConsumed(host6,$_message12):=true
					isConsumed(host6,$_message13):=true
					isConsumed(host6,$_message130):=false
					isConsumed(host6,$_message131):=false
					isConsumed(host6,$_message132):=false
					isConsumed(host6,$_message133):=false
					isConsumed(host6,$_message134):=false
					isConsumed(host6,$_message135):=false
					isConsumed(host6,$_message136):=false
					isConsumed(host6,$_message137):=false
					isConsumed(host6,$_message138):=false
					isConsumed(host6,$_message139):=false
					isConsumed(host6,$_message14):=true
					isConsumed(host6,$_message140):=false
					isConsumed(host6,$_message141):=false
					isConsumed(host6,$_message142):=false
					isConsumed(host6,$_message143):=false
					isConsumed(host6,$_message144):=false
					isConsumed(host6,$_message146):=false
					isConsumed(host6,$_message148):=false
					isConsumed(host6,$_message149):=false
					isConsumed(host6,$_message15):=true
					isConsumed(host6,$_message150):=false
					isConsumed(host6,$_message151):=false
					isConsumed(host6,$_message152):=false
					isConsumed(host6,$_message153):=false
					isConsumed(host6,$_message154):=false
					isConsumed(host6,$_message156):=false
					isConsumed(host6,$_message157):=false
					isConsumed(host6,$_message158):=false
					isConsumed(host6,$_message162):=false
					isConsumed(host6,$_message165):=false
					isConsumed(host6,$_message166):=false
					isConsumed(host6,$_message167):=false
					isConsumed(host6,$_message168):=false
					isConsumed(host6,$_message171):=false
					isConsumed(host6,$_message172):=false
					isConsumed(host6,$_message173):=false
					isConsumed(host6,$_message174):=false
					isConsumed(host6,$_message175):=false
					isConsumed(host6,$_message178):=false
					isConsumed(host6,$_message179):=false
					isConsumed(host6,$_message180):=false
					isConsumed(host6,$_message2):=true
					isConsumed(host6,$_message3):=true
					isConsumed(host6,$_message35):=true
					isConsumed(host6,$_message36):=true
					isConsumed(host6,$_message37):=true
					isConsumed(host6,$_message4):=true
					isConsumed(host6,$_message5):=true
					isConsumed(host6,$_message51):=true
					isConsumed(host6,$_message52):=true
					isConsumed(host6,$_message53):=true
					isConsumed(host6,$_message54):=true
					isConsumed(host6,$_message55):=true
					isConsumed(host6,$_message56):=false
					isConsumed(host6,$_message57):=false
					isConsumed(host6,$_message58):=false
					isConsumed(host6,$_message59):=false
					isConsumed(host6,$_message6):=true
					isConsumed(host6,$_message60):=false
					isConsumed(host6,$_message61):=false
					isConsumed(host6,$_message62):=false
					isConsumed(host6,$_message63):=false
					isConsumed(host6,$_message64):=false
					isConsumed(host6,$_message65):=false
					isConsumed(host6,$_message66):=false
					isConsumed(host6,$_message7):=true
					isConsumed(host6,$_message8):=true
					isConsumed(host6,$_message80):=false
					isConsumed(host6,$_message81):=false
					isConsumed(host6,$_message82):=false
					isConsumed(host6,$_message83):=false
					isConsumed(host6,$_message84):=false
					isConsumed(host6,$_message85):=false
					isConsumed(host6,$_message86):=false
					isConsumed(host6,$_message87):=false
					isConsumed(host6,$_message88):=false
					isConsumed(host6,$_message89):=false
					isConsumed(host6,$_message9):=true
					isConsumed(host6,$_message90):=false
					isConsumed(host6,$_message91):=false
					isConsumed(host6,$_message97):=false
					isConsumed(host6,$_message98):=false
					isConsumed(host6,$_message99):=false
					isConsumed(host7,$_message1):=true
					isConsumed(host7,$_message103):=false
					isConsumed(host7,$_message104):=false
					isConsumed(host7,$_message105):=false
					isConsumed(host7,$_message106):=false
					isConsumed(host7,$_message107):=false
					isConsumed(host7,$_message108):=false
					isConsumed(host7,$_message109):=false
					isConsumed(host7,$_message110):=false
					isConsumed(host7,$_message111):=false
					isConsumed(host7,$_message112):=false
					isConsumed(host7,$_message113):=false
					isConsumed(host7,$_message114):=false
					isConsumed(host7,$_message130):=true
					isConsumed(host7,$_message131):=true
					isConsumed(host7,$_message132):=true
					isConsumed(host7,$_message133):=true
					isConsumed(host7,$_message134):=true
					isConsumed(host7,$_message135):=true
					isConsumed(host7,$_message136):=true
					isConsumed(host7,$_message137):=true
					isConsumed(host7,$_message138):=true
					isConsumed(host7,$_message139):=true
					isConsumed(host7,$_message140):=false
					isConsumed(host7,$_message141):=false
					isConsumed(host7,$_message142):=false
					isConsumed(host7,$_message143):=false
					isConsumed(host7,$_message144):=false
					isConsumed(host7,$_message146):=false
					isConsumed(host7,$_message148):=false
					isConsumed(host7,$_message149):=false
					isConsumed(host7,$_message150):=false
					isConsumed(host7,$_message151):=false
					isConsumed(host7,$_message152):=false
					isConsumed(host7,$_message153):=false
					isConsumed(host7,$_message154):=false
					isConsumed(host7,$_message156):=false
					isConsumed(host7,$_message157):=false
					isConsumed(host7,$_message172):=false
					isConsumed(host7,$_message173):=false
					isConsumed(host7,$_message174):=false
					isConsumed(host7,$_message175):=false
					isConsumed(host7,$_message2):=true
					isConsumed(host7,$_message27):=false
					isConsumed(host7,$_message28):=false
					isConsumed(host7,$_message29):=false
					isConsumed(host7,$_message3):=true
					isConsumed(host7,$_message30):=false
					isConsumed(host7,$_message31):=false
					isConsumed(host7,$_message32):=false
					isConsumed(host7,$_message33):=false
					isConsumed(host7,$_message34):=false
					isConsumed(host7,$_message35):=true
					isConsumed(host7,$_message36):=true
					isConsumed(host7,$_message37):=true
					isConsumed(host7,$_message38):=true
					isConsumed(host7,$_message39):=true
					isConsumed(host7,$_message4):=true
					isConsumed(host7,$_message5):=true
					isConsumed(host7,$_message6):=true
					isConsumed(host7,$_message60):=true
					isConsumed(host7,$_message61):=true
					isConsumed(host7,$_message62):=true
					isConsumed(host7,$_message63):=true
					isConsumed(host7,$_message67):=true
					isConsumed(host7,$_message68):=true
					isConsumed(host7,$_message69):=true
					isConsumed(host7,$_message7):=true
					isConsumed(host7,$_message70):=true
					isConsumed(host7,$_message71):=true
					isConsumed(host7,$_message72):=true
					isConsumed(host7,$_message73):=true
					isConsumed(host7,$_message74):=true
					isConsumed(host7,$_message75):=true
					isConsumed(host7,$_message76):=true
					isConsumed(host7,$_message77):=true
					isConsumed(host7,$_message78):=true
					isConsumed(host7,$_message79):=true
					isConsumed(host7,$_message8):=true
					isConsumed(host7,$_message88):=true
					isConsumed(host7,$_message89):=true
					isConsumed(host7,$_message9):=true
					isConsumed(host7,$_message90):=true
					isConsumed(host7,$_message91):=true
					isConsumed(host7,$_message95):=true
					isConsumed(host7,$_message96):=true
					isConsumed(host8,$_message100):=false
					isConsumed(host8,$_message101):=false
					isConsumed(host8,$_message102):=false
					isConsumed(host8,$_message115):=false
					isConsumed(host8,$_message116):=false
					isConsumed(host8,$_message117):=false
					isConsumed(host8,$_message118):=false
					isConsumed(host8,$_message119):=false
					isConsumed(host8,$_message120):=false
					isConsumed(host8,$_message121):=false
					isConsumed(host8,$_message122):=false
					isConsumed(host8,$_message123):=false
					isConsumed(host8,$_message124):=false
					isConsumed(host8,$_message125):=false
					isConsumed(host8,$_message126):=false
					isConsumed(host8,$_message127):=false
					isConsumed(host8,$_message128):=false
					isConsumed(host8,$_message129):=false
					isConsumed(host8,$_message140):=false
					isConsumed(host8,$_message141):=false
					isConsumed(host8,$_message142):=false
					isConsumed(host8,$_message143):=false
					isConsumed(host8,$_message144):=false
					isConsumed(host8,$_message146):=false
					isConsumed(host8,$_message147):=false
					isConsumed(host8,$_message162):=false
					isConsumed(host8,$_message164):=false
					isConsumed(host8,$_message165):=false
					isConsumed(host8,$_message178):=false
					isConsumed(host8,$_message180):=false
					isConsumed(host8,$_message181):=false
					isConsumed(host8,$_message38):=false
					isConsumed(host8,$_message39):=false
					isConsumed(host8,$_message40):=false
					isConsumed(host8,$_message41):=false
					isConsumed(host8,$_message42):=false
					isConsumed(host8,$_message43):=false
					isConsumed(host8,$_message44):=false
					isConsumed(host8,$_message45):=false
					isConsumed(host8,$_message46):=false
					isConsumed(host8,$_message47):=false
					isConsumed(host8,$_message48):=false
					isConsumed(host8,$_message49):=false
					isConsumed(host8,$_message50):=false
					isConsumed(host8,$_message51):=false
					isConsumed(host8,$_message52):=false
					isConsumed(host8,$_message53):=false
					isConsumed(host8,$_message54):=false
					isConsumed(host8,$_message55):=false
					isConsumed(host8,$_message60):=false
					isConsumed(host8,$_message61):=false
					isConsumed(host8,$_message62):=false
					isConsumed(host8,$_message63):=false
					isConsumed(host8,$_message64):=false
					isConsumed(host8,$_message65):=false
					isConsumed(host8,$_message67):=false
					isConsumed(host8,$_message68):=false
					isConsumed(host8,$_message69):=false
					isConsumed(host8,$_message70):=false
					isConsumed(host8,$_message71):=false
					isConsumed(host8,$_message72):=false
					isConsumed(host8,$_message73):=false
					isConsumed(host8,$_message74):=false
					isConsumed(host8,$_message75):=false
					isConsumed(host8,$_message76):=false
					isConsumed(host8,$_message77):=false
					isConsumed(host8,$_message78):=false
					isConsumed(host8,$_message79):=false
					isConsumed(host8,$_message83):=false
					isConsumed(host8,$_message84):=false
					isConsumed(host8,$_message85):=false
					isConsumed(host8,$_message86):=false
					isConsumed(host8,$_message87):=false
					isConsumed(host8,$_message95):=false
					isConsumed(host8,$_message96):=false
					isConsumed(host8,$_message97):=false
					isConsumed(host8,$_message98):=false
					isConsumed(host8,$_message99):=false
					isConsumed(host9,$_message100):=true
					isConsumed(host9,$_message101):=true
					isConsumed(host9,$_message102):=true
					isConsumed(host9,$_message103):=true
					isConsumed(host9,$_message104):=true
					isConsumed(host9,$_message105):=true
					isConsumed(host9,$_message106):=true
					isConsumed(host9,$_message107):=true
					isConsumed(host9,$_message108):=true
					isConsumed(host9,$_message109):=true
					isConsumed(host9,$_message110):=true
					isConsumed(host9,$_message111):=true
					isConsumed(host9,$_message112):=true
					isConsumed(host9,$_message113):=true
					isConsumed(host9,$_message114):=true
					isConsumed(host9,$_message130):=false
					isConsumed(host9,$_message131):=false
					isConsumed(host9,$_message132):=false
					isConsumed(host9,$_message133):=false
					isConsumed(host9,$_message134):=false
					isConsumed(host9,$_message135):=false
					isConsumed(host9,$_message136):=false
					isConsumed(host9,$_message137):=false
					isConsumed(host9,$_message138):=false
					isConsumed(host9,$_message139):=false
					isConsumed(host9,$_message140):=false
					isConsumed(host9,$_message141):=false
					isConsumed(host9,$_message142):=false
					isConsumed(host9,$_message143):=false
					isConsumed(host9,$_message144):=false
					isConsumed(host9,$_message146):=false
					isConsumed(host9,$_message16):=false
					isConsumed(host9,$_message166):=false
					isConsumed(host9,$_message167):=false
					isConsumed(host9,$_message168):=false
					isConsumed(host9,$_message17):=false
					isConsumed(host9,$_message171):=false
					isConsumed(host9,$_message172):=false
					isConsumed(host9,$_message173):=false
					isConsumed(host9,$_message174):=false
					isConsumed(host9,$_message175):=false
					isConsumed(host9,$_message18):=false
					isConsumed(host9,$_message19):=false
					isConsumed(host9,$_message20):=false
					isConsumed(host9,$_message21):=false
					isConsumed(host9,$_message22):=false
					isConsumed(host9,$_message23):=false
					isConsumed(host9,$_message24):=false
					isConsumed(host9,$_message25):=false
					isConsumed(host9,$_message26):=false
					isConsumed(host9,$_message35):=true
					isConsumed(host9,$_message40):=true
					isConsumed(host9,$_message41):=true
					isConsumed(host9,$_message42):=true
					isConsumed(host9,$_message43):=true
					isConsumed(host9,$_message44):=true
					isConsumed(host9,$_message45):=true
					isConsumed(host9,$_message46):=true
					isConsumed(host9,$_message47):=true
					isConsumed(host9,$_message48):=true
					isConsumed(host9,$_message49):=true
					isConsumed(host9,$_message50):=true
					isConsumed(host9,$_message51):=true
					isConsumed(host9,$_message52):=true
					isConsumed(host9,$_message53):=true
					isConsumed(host9,$_message54):=true
					isConsumed(host9,$_message55):=true
					isConsumed(host9,$_message56):=true
					isConsumed(host9,$_message57):=true
					isConsumed(host9,$_message58):=true
					isConsumed(host9,$_message59):=true
					isConsumed(host9,$_message80):=true
					isConsumed(host9,$_message81):=true
					isConsumed(host9,$_message82):=true
					isConsumed(host9,$_message83):=false
					isConsumed(host9,$_message84):=false
					isConsumed(host9,$_message85):=false
					isConsumed(host9,$_message86):=false
					isConsumed(host9,$_message87):=false
					isConsumed(host9,$_message88):=true
					isConsumed(host9,$_message89):=true
					isConsumed(host9,$_message90):=true
					isConsumed(host9,$_message91):=true
					isConsumed(host9,$_message93):=true
					isConsumed(host9,$_message94):=true
					isConsumed(host9,$_message95):=true
					isConsumed(host9,$_message96):=true
					isConsumed(host9,$_message97):=true
					isConsumed(host9,$_message98):=true
					isConsumed(host9,$_message99):=true
					messageRREP($_message145):=(host2,2,host12,1,host4)
					messageRREP($_message147):=(host8,1,host6,1,host4)
					messageRREP($_message155):=(host18,1,host12,1,host14)
					messageRREP($_message158):=(host6,2,host5,1,host14)
					messageRREP($_message159):=(host2,1,host12,1,host14)
					messageRREP($_message160):=(host12,1,host17,0,host14)
					messageRREP($_message161):=(host18,2,host12,1,host7)
					messageRREP($_message163):=(host5,0,host7,0,host7)
					messageRREP($_message164):=(host8,1,host6,1,host7)
					messageRREP($_message169):=(host15,1,host9,1,host11)
					messageRREP($_message170):=(host10,0,host11,0,host11)
					messageRREP($_message176):=(host2,0,host12,2,host12)
					messageRREP($_message177):=(host18,0,host12,2,host12)
					messageRREP($_message179):=(host6,1,host5,1,host1)
					messageRREP($_message181):=(host8,1,host6,1,host1)
					messageRREP($_message185):=(host15,0,host9,1,host9)
					messageRREP($_message66):=(host15,0,host7,0,host7)
					messageRREP($_message92):=(host12,0,host17,0,host17)
					messageRREQ($_message1):=(host12,1,0,host13,undef,1,host12)
					messageRREQ($_message10):=(host15,1,0,host14,undef,1,host15)
					messageRREQ($_message100):=(host15,3,0,host3,undef,3,host15)
					messageRREQ($_message101):=(host10,1,1,host11,undef,1,host15)
					messageRREQ($_message102):=(host12,1,2,host17,undef,1,host15)
					messageRREQ($_message103):=(host2,1,0,host5,undef,1,host2)
					messageRREQ($_message104):=(host2,1,0,host4,undef,1,host2)
					messageRREQ($_message105):=(host2,1,0,host14,undef,1,host2)
					messageRREQ($_message106):=(host2,1,0,host7,undef,1,host2)
					messageRREQ($_message107):=(host2,1,0,host6,undef,1,host2)
					messageRREQ($_message108):=(host2,1,0,host12,undef,1,host2)
					messageRREQ($_message109):=(host2,1,0,host17,undef,1,host2)
					messageRREQ($_message11):=(host15,1,0,host7,undef,1,host15)
					messageRREQ($_message110):=(host2,1,0,host18,undef,1,host2)
					messageRREQ($_message111):=(host2,1,0,host3,undef,1,host2)
					messageRREQ($_message112):=(host2,1,0,host16,undef,1,host2)
					messageRREQ($_message113):=(host2,1,0,host10,undef,1,host2)
					messageRREQ($_message114):=(host2,1,0,host8,undef,1,host2)
					messageRREQ($_message115):=(host15,1,1,host7,undef,1,host10)
					messageRREQ($_message116):=(host9,1,0,host5,undef,1,host9)
					messageRREQ($_message117):=(host9,1,0,host13,undef,1,host9)
					messageRREQ($_message118):=(host9,1,0,host4,undef,1,host9)
					messageRREQ($_message119):=(host9,1,0,host14,undef,1,host9)
					messageRREQ($_message12):=(host15,1,0,host18,undef,1,host15)
					messageRREQ($_message120):=(host9,1,0,host7,undef,1,host9)
					messageRREQ($_message121):=(host9,1,0,host11,undef,1,host9)
					messageRREQ($_message122):=(host9,1,0,host6,undef,1,host9)
					messageRREQ($_message123):=(host9,1,0,host12,undef,1,host9)
					messageRREQ($_message124):=(host9,1,0,host1,undef,1,host9)
					messageRREQ($_message125):=(host9,1,0,host17,undef,1,host9)
					messageRREQ($_message126):=(host9,1,0,host18,undef,1,host9)
					messageRREQ($_message127):=(host9,1,0,host3,undef,1,host9)
					messageRREQ($_message128):=(host9,1,0,host16,undef,1,host9)
					messageRREQ($_message129):=(host9,1,0,host8,undef,1,host9)
					messageRREQ($_message13):=(host15,1,0,host2,undef,1,host15)
					messageRREQ($_message130):=(host8,1,0,host14,undef,1,host8)
					messageRREQ($_message131):=(host8,1,0,host7,undef,1,host8)
					messageRREQ($_message132):=(host8,1,0,host11,undef,1,host8)
					messageRREQ($_message133):=(host8,1,0,host6,undef,1,host8)
					messageRREQ($_message134):=(host8,1,0,host12,undef,1,host8)
					messageRREQ($_message135):=(host8,1,0,host17,undef,1,host8)
					messageRREQ($_message136):=(host8,1,0,host18,undef,1,host8)
					messageRREQ($_message137):=(host8,1,0,host2,undef,1,host8)
					messageRREQ($_message138):=(host8,1,0,host16,undef,1,host8)
					messageRREQ($_message139):=(host8,1,0,host10,undef,1,host8)
					messageRREQ($_message14):=(host15,1,0,host16,undef,1,host15)
					messageRREQ($_message140):=(host9,1,1,host6,undef,1,host13)
					messageRREQ($_message141):=(host15,3,1,host3,undef,3,host13)
					messageRREQ($_message142):=(host6,1,1,host5,undef,1,host13)
					messageRREQ($_message143):=(host15,2,2,host9,undef,2,host4)
					messageRREQ($_message144):=(host6,1,1,host5,undef,1,host4)
					messageRREQ($_message146):=(host5,1,2,host7,undef,1,host4)
					messageRREQ($_message148):=(host14,1,0,host4,undef,1,host14)
					messageRREQ($_message149):=(host14,1,0,host7,undef,1,host14)
					messageRREQ($_message15):=(host15,1,0,host8,undef,1,host15)
					messageRREQ($_message150):=(host14,1,0,host1,undef,1,host14)
					messageRREQ($_message151):=(host14,1,0,host18,undef,1,host14)
					messageRREQ($_message152):=(host14,1,0,host2,undef,1,host14)
					messageRREQ($_message153):=(host14,1,0,host16,undef,1,host14)
					messageRREQ($_message154):=(host15,1,2,host7,undef,1,host14)
					messageRREQ($_message156):=(host5,1,2,host7,undef,1,host14)
					messageRREQ($_message157):=(host15,2,2,host9,undef,2,host14)
					messageRREQ($_message16):=(host10,1,0,host5,undef,1,host10)
					messageRREQ($_message162):=(host6,1,1,host5,undef,1,host7)
					messageRREQ($_message165):=(host15,2,2,host9,undef,2,host7)
					messageRREQ($_message166):=(host15,1,2,host7,undef,1,host11)
					messageRREQ($_message167):=(host9,1,1,host6,undef,1,host11)
					messageRREQ($_message168):=(host6,1,1,host5,undef,1,host11)
					messageRREQ($_message17):=(host10,1,0,host13,undef,1,host10)
					messageRREQ($_message171):=(host12,1,2,host17,undef,1,host11)
					messageRREQ($_message172):=(host12,2,0,host8,undef,2,host12)
					messageRREQ($_message173):=(host9,1,1,host6,undef,1,host12)
					messageRREQ($_message174):=(host15,3,1,host3,undef,3,host12)
					messageRREQ($_message175):=(host6,1,1,host5,undef,1,host12)
					messageRREQ($_message178):=(host15,3,1,host3,undef,3,host1)
					messageRREQ($_message18):=(host10,1,0,host14,undef,1,host10)
					messageRREQ($_message180):=(host15,1,3,host7,undef,1,host1)
					messageRREQ($_message182):=(host18,1,1,host12,undef,1,host9)
					messageRREQ($_message183):=(host5,1,2,host7,undef,1,host9)
					messageRREQ($_message184):=(host15,3,1,host3,undef,3,host9)
					messageRREQ($_message186):=(host2,1,1,host12,undef,1,host9)
					messageRREQ($_message187):=(host10,1,3,host11,undef,1,host9)
					messageRREQ($_message188):=(host15,1,3,host7,undef,1,host9)
					messageRREQ($_message189):=(host12,1,3,host17,undef,1,host9)
					messageRREQ($_message19):=(host10,1,0,host11,undef,1,host10)
					messageRREQ($_message2):=(host12,1,0,host4,undef,1,host12)
					messageRREQ($_message20):=(host10,1,0,host6,undef,1,host10)
					messageRREQ($_message21):=(host10,1,0,host1,undef,1,host10)
					messageRREQ($_message22):=(host10,1,0,host17,undef,1,host10)
					messageRREQ($_message23):=(host10,1,0,host18,undef,1,host10)
					messageRREQ($_message24):=(host10,1,0,host2,undef,1,host10)
					messageRREQ($_message25):=(host10,1,0,host9,undef,1,host10)
					messageRREQ($_message26):=(host10,1,0,host8,undef,1,host10)
					messageRREQ($_message27):=(host5,1,0,host14,undef,1,host5)
					messageRREQ($_message28):=(host5,1,0,host7,undef,1,host5)
					messageRREQ($_message29):=(host5,1,0,host1,undef,1,host5)
					messageRREQ($_message3):=(host12,1,0,host14,undef,1,host12)
					messageRREQ($_message30):=(host5,1,0,host17,undef,1,host5)
					messageRREQ($_message31):=(host5,1,0,host3,undef,1,host5)
					messageRREQ($_message32):=(host5,1,0,host15,undef,1,host5)
					messageRREQ($_message33):=(host5,1,0,host10,undef,1,host5)
					messageRREQ($_message34):=(host5,1,0,host9,undef,1,host5)
					messageRREQ($_message35):=(host10,1,1,host17,undef,1,host13)
					messageRREQ($_message36):=(host12,1,1,host17,undef,1,host14)
					messageRREQ($_message37):=(host10,1,1,host11,undef,1,host14)
					messageRREQ($_message38):=(host12,1,1,host17,undef,1,host6)
					messageRREQ($_message39):=(host15,1,1,host7,undef,1,host6)
					messageRREQ($_message4):=(host12,1,0,host7,undef,1,host12)
					messageRREQ($_message40):=(host18,1,0,host5,undef,1,host18)
					messageRREQ($_message41):=(host18,1,0,host14,undef,1,host18)
					messageRREQ($_message42):=(host18,1,0,host7,undef,1,host18)
					messageRREQ($_message43):=(host18,1,0,host11,undef,1,host18)
					messageRREQ($_message44):=(host18,1,0,host12,undef,1,host18)
					messageRREQ($_message45):=(host18,1,0,host1,undef,1,host18)
					messageRREQ($_message46):=(host18,1,0,host3,undef,1,host18)
					messageRREQ($_message47):=(host18,1,0,host15,undef,1,host18)
					messageRREQ($_message48):=(host18,1,0,host2,undef,1,host18)
					messageRREQ($_message49):=(host18,1,0,host9,undef,1,host18)
					messageRREQ($_message5):=(host12,1,0,host6,undef,1,host12)
					messageRREQ($_message50):=(host18,1,0,host8,undef,1,host18)
					messageRREQ($_message51):=(host15,2,0,host5,undef,2,host15)
					messageRREQ($_message52):=(host15,2,0,host13,undef,2,host15)
					messageRREQ($_message53):=(host15,2,0,host4,undef,2,host15)
					messageRREQ($_message54):=(host15,2,0,host1,undef,2,host15)
					messageRREQ($_message55):=(host15,2,0,host9,undef,2,host15)
					messageRREQ($_message56):=(host15,1,2,host7,undef,1,host13)
					messageRREQ($_message57):=(host18,1,1,host12,undef,1,host13)
					messageRREQ($_message58):=(host15,2,1,host9,undef,2,host13)
					messageRREQ($_message59):=(host12,1,2,host17,undef,1,host13)
					messageRREQ($_message6):=(host12,1,0,host1,undef,1,host12)
					messageRREQ($_message60):=(host15,1,2,host7,undef,1,host4)
					messageRREQ($_message61):=(host18,1,1,host12,undef,1,host4)
					messageRREQ($_message62):=(host10,1,2,host11,undef,1,host4)
					messageRREQ($_message63):=(host12,1,2,host17,undef,1,host4)
					messageRREQ($_message64):=(host10,1,2,host11,undef,1,host7)
					messageRREQ($_message65):=(host12,1,2,host17,undef,1,host7)
					messageRREQ($_message67):=(host6,1,0,host5,undef,1,host6)
					messageRREQ($_message68):=(host6,1,0,host13,undef,1,host6)
					messageRREQ($_message69):=(host6,1,0,host14,undef,1,host6)
					messageRREQ($_message7):=(host12,1,0,host17,undef,1,host12)
					messageRREQ($_message70):=(host6,1,0,host7,undef,1,host6)
					messageRREQ($_message71):=(host6,1,0,host11,undef,1,host6)
					messageRREQ($_message72):=(host6,1,0,host1,undef,1,host6)
					messageRREQ($_message73):=(host6,1,0,host17,undef,1,host6)
					messageRREQ($_message74):=(host6,1,0,host18,undef,1,host6)
					messageRREQ($_message75):=(host6,1,0,host16,undef,1,host6)
					messageRREQ($_message76):=(host6,1,0,host9,undef,1,host6)
					messageRREQ($_message77):=(host6,1,0,host8,undef,1,host6)
					messageRREQ($_message78):=(host15,2,1,host9,undef,2,host6)
					messageRREQ($_message79):=(host10,1,2,host11,undef,1,host6)
					messageRREQ($_message8):=(host12,1,0,host18,undef,1,host12)
					messageRREQ($_message80):=(host15,2,1,host9,undef,2,host12)
					messageRREQ($_message81):=(host10,1,2,host11,undef,1,host12)
					messageRREQ($_message82):=(host15,1,2,host7,undef,1,host12)
					messageRREQ($_message83):=(host18,1,1,host12,undef,1,host1)
					messageRREQ($_message84):=(host5,1,1,host7,undef,1,host1)
					messageRREQ($_message85):=(host15,2,1,host9,undef,2,host1)
					messageRREQ($_message86):=(host10,1,2,host11,undef,1,host1)
					messageRREQ($_message87):=(host12,1,2,host17,undef,1,host1)
					messageRREQ($_message88):=(host18,1,1,host12,undef,1,host17)
					messageRREQ($_message89):=(host5,1,1,host7,undef,1,host17)
					messageRREQ($_message9):=(host12,1,0,host3,undef,1,host12)
					messageRREQ($_message90):=(host15,2,1,host9,undef,2,host17)
					messageRREQ($_message91):=(host10,1,2,host11,undef,1,host17)
					messageRREQ($_message93):=(host10,1,2,host11,undef,1,host18)
					messageRREQ($_message94):=(host12,1,2,host17,undef,1,host18)
					messageRREQ($_message95):=(host18,1,1,host12,undef,1,host3)
					messageRREQ($_message96):=(host10,1,2,host17,undef,1,host3)
					messageRREQ($_message97):=(host15,3,0,host6,undef,3,host15)
					messageRREQ($_message98):=(host15,3,0,host12,undef,3,host15)
					messageRREQ($_message99):=(host15,3,0,host17,undef,3,host15)
					messageType($_message1):=RREQ
					messageType($_message10):=RREQ
					messageType($_message100):=RREQ
					messageType($_message101):=RREQ
					messageType($_message102):=RREQ
					messageType($_message103):=RREQ
					messageType($_message104):=RREQ
					messageType($_message105):=RREQ
					messageType($_message106):=RREQ
					messageType($_message107):=RREQ
					messageType($_message108):=RREQ
					messageType($_message109):=RREQ
					messageType($_message11):=RREQ
					messageType($_message110):=RREQ
					messageType($_message111):=RREQ
					messageType($_message112):=RREQ
					messageType($_message113):=RREQ
					messageType($_message114):=RREQ
					messageType($_message115):=RREQ
					messageType($_message116):=RREQ
					messageType($_message117):=RREQ
					messageType($_message118):=RREQ
					messageType($_message119):=RREQ
					messageType($_message12):=RREQ
					messageType($_message120):=RREQ
					messageType($_message121):=RREQ
					messageType($_message122):=RREQ
					messageType($_message123):=RREQ
					messageType($_message124):=RREQ
					messageType($_message125):=RREQ
					messageType($_message126):=RREQ
					messageType($_message127):=RREQ
					messageType($_message128):=RREQ
					messageType($_message129):=RREQ
					messageType($_message13):=RREQ
					messageType($_message130):=RREQ
					messageType($_message131):=RREQ
					messageType($_message132):=RREQ
					messageType($_message133):=RREQ
					messageType($_message134):=RREQ
					messageType($_message135):=RREQ
					messageType($_message136):=RREQ
					messageType($_message137):=RREQ
					messageType($_message138):=RREQ
					messageType($_message139):=RREQ
					messageType($_message14):=RREQ
					messageType($_message140):=RREQ
					messageType($_message141):=RREQ
					messageType($_message142):=RREQ
					messageType($_message143):=RREQ
					messageType($_message144):=RREQ
					messageType($_message145):=RREP
					messageType($_message146):=RREQ
					messageType($_message147):=RREP
					messageType($_message148):=RREQ
					messageType($_message149):=RREQ
					messageType($_message15):=RREQ
					messageType($_message150):=RREQ
					messageType($_message151):=RREQ
					messageType($_message152):=RREQ
					messageType($_message153):=RREQ
					messageType($_message154):=RREQ
					messageType($_message155):=RREP
					messageType($_message156):=RREQ
					messageType($_message157):=RREQ
					messageType($_message158):=RREP
					messageType($_message159):=RREP
					messageType($_message16):=RREQ
					messageType($_message160):=RREP
					messageType($_message161):=RREP
					messageType($_message162):=RREQ
					messageType($_message163):=RREP
					messageType($_message164):=RREP
					messageType($_message165):=RREQ
					messageType($_message166):=RREQ
					messageType($_message167):=RREQ
					messageType($_message168):=RREQ
					messageType($_message169):=RREP
					messageType($_message17):=RREQ
					messageType($_message170):=RREP
					messageType($_message171):=RREQ
					messageType($_message172):=RREQ
					messageType($_message173):=RREQ
					messageType($_message174):=RREQ
					messageType($_message175):=RREQ
					messageType($_message176):=RREP
					messageType($_message177):=RREP
					messageType($_message178):=RREQ
					messageType($_message179):=RREP
					messageType($_message18):=RREQ
					messageType($_message180):=RREQ
					messageType($_message181):=RREP
					messageType($_message182):=RREQ
					messageType($_message183):=RREQ
					messageType($_message184):=RREQ
					messageType($_message185):=RREP
					messageType($_message186):=RREQ
					messageType($_message187):=RREQ
					messageType($_message188):=RREQ
					messageType($_message189):=RREQ
					messageType($_message19):=RREQ
					messageType($_message2):=RREQ
					messageType($_message20):=RREQ
					messageType($_message21):=RREQ
					messageType($_message22):=RREQ
					messageType($_message23):=RREQ
					messageType($_message24):=RREQ
					messageType($_message25):=RREQ
					messageType($_message26):=RREQ
					messageType($_message27):=RREQ
					messageType($_message28):=RREQ
					messageType($_message29):=RREQ
					messageType($_message3):=RREQ
					messageType($_message30):=RREQ
					messageType($_message31):=RREQ
					messageType($_message32):=RREQ
					messageType($_message33):=RREQ
					messageType($_message34):=RREQ
					messageType($_message35):=RREQ
					messageType($_message36):=RREQ
					messageType($_message37):=RREQ
					messageType($_message38):=RREQ
					messageType($_message39):=RREQ
					messageType($_message4):=RREQ
					messageType($_message40):=RREQ
					messageType($_message41):=RREQ
					messageType($_message42):=RREQ
					messageType($_message43):=RREQ
					messageType($_message44):=RREQ
					messageType($_message45):=RREQ
					messageType($_message46):=RREQ
					messageType($_message47):=RREQ
					messageType($_message48):=RREQ
					messageType($_message49):=RREQ
					messageType($_message5):=RREQ
					messageType($_message50):=RREQ
					messageType($_message51):=RREQ
					messageType($_message52):=RREQ
					messageType($_message53):=RREQ
					messageType($_message54):=RREQ
					messageType($_message55):=RREQ
					messageType($_message56):=RREQ
					messageType($_message57):=RREQ
					messageType($_message58):=RREQ
					messageType($_message59):=RREQ
					messageType($_message6):=RREQ
					messageType($_message60):=RREQ
					messageType($_message61):=RREQ
					messageType($_message62):=RREQ
					messageType($_message63):=RREQ
					messageType($_message64):=RREQ
					messageType($_message65):=RREQ
					messageType($_message66):=RREP
					messageType($_message67):=RREQ
					messageType($_message68):=RREQ
					messageType($_message69):=RREQ
					messageType($_message7):=RREQ
					messageType($_message70):=RREQ
					messageType($_message71):=RREQ
					messageType($_message72):=RREQ
					messageType($_message73):=RREQ
					messageType($_message74):=RREQ
					messageType($_message75):=RREQ
					messageType($_message76):=RREQ
					messageType($_message77):=RREQ
					messageType($_message78):=RREQ
					messageType($_message79):=RREQ
					messageType($_message8):=RREQ
					messageType($_message80):=RREQ
					messageType($_message81):=RREQ
					messageType($_message82):=RREQ
					messageType($_message83):=RREQ
					messageType($_message84):=RREQ
					messageType($_message85):=RREQ
					messageType($_message86):=RREQ
					messageType($_message87):=RREQ
					messageType($_message88):=RREQ
					messageType($_message89):=RREQ
					messageType($_message9):=RREQ
					messageType($_message90):=RREQ
					messageType($_message91):=RREQ
					messageType($_message92):=RREP
					messageType($_message93):=RREQ
					messageType($_message94):=RREQ
					messageType($_message95):=RREQ
					messageType($_message96):=RREQ
					messageType($_message97):=RREQ
					messageType($_message98):=RREQ
					messageType($_message99):=RREQ
				endpar
	/* END PAR */
			endpar

	rule r_AodvSpec = 
		seq 
			forall $dest in Agent with ($dest != self) do
				if(waitingForRouteTo(self,$dest)) then
					if (waitingForRouteToTmp(self,$dest)  > 0) then
						waitingForRouteToTmp(self,$dest) := waitingForRouteToTmp(self,$dest)-1
					else
						par
							waitingForRouteTo(self, $dest) := false
							ca_failure(self,$dest) := ca_failure(self,$dest) + 1
						endpar
					endif
				endif
			choose $c in {1..100} with true do 
				if($c <= 20) then
					r_PrepareComm[]
				endif
			choose $d in Boolean with true do 
				if $d and notEmpty(Message) then
					r_Router[]
				endif
		endseq
	
	main rule r_Main = 
		/* START SEQ MAIN */
			seq
				r_MemoryManager[]
			forall $a in Agent do
				program($a) 
		/* END SEQ MAIN */
			endseq


default init s0:	
	function isLinked($a in Agent, $b in Agent) = false
	
	function curSeqNum($a in Agent) = 0	
	function localReqCount($a in Agent) = 0
	function receivedReq($a in Agent) = []
	function waitingForRouteTo($a in Agent,$b in Agent) = false
	function isConsumed($a in Agent, $m in Message) = undef
	
	function rreq_update($a in Agent) = 0
	function rrep_update($a in Agent) = 0
	function rerr_update($a in Agent) = 0
	function rt_update($a in Agent) = 0
	
	function ca_tot($a in Agent, $b in Agent) = 0
	function ca_success($a in Agent, $b in Agent) = 0
	function ca_failure($a in Agent, $b in Agent) = 0
	
	agent Agent: r_AodvSpec[]	 	
