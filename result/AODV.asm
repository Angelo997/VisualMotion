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
			isLinked(host1,host6):=true
			isLinked(host6,host1):=true
			isLinked(host2,host3):=true
			isLinked(host3,host2):=true
			isLinked(host2,host4):=true
			isLinked(host4,host2):=true
			isLinked(host2,host5):=true
			isLinked(host5,host2):=true
			isLinked(host2,host6):=true
			isLinked(host6,host2):=true
			isLinked(host3,host4):=true
			isLinked(host4,host3):=true
			isLinked(host4,host5):=true
			isLinked(host5,host4):=true
			isLinked(host4,host6):=true
			isLinked(host6,host4):=true
			isLinked(host4,host7):=true
			isLinked(host7,host4):=true
			isLinked(host6,host7):=true
			isLinked(host7,host6):=true

			curSeqNum(host1):=3
			curSeqNum(host2):=3
			curSeqNum(host3):=3
			curSeqNum(host4):=3
			curSeqNum(host5):=2
			curSeqNum(host6):=4
			curSeqNum(host7):=3
			lastKnownDestSeqNum(host1,host2):=undef
			lastKnownDestSeqNum(host1,host3):=undef
			lastKnownDestSeqNum(host1,host4):=undef
			lastKnownDestSeqNum(host1,host5):=undef
			lastKnownDestSeqNum(host1,host6):=undef
			lastKnownDestSeqNum(host1,host7):=undef
			lastKnownDestSeqNum(host2,host1):=undef
			lastKnownDestSeqNum(host2,host3):=undef
			lastKnownDestSeqNum(host2,host4):=undef
			lastKnownDestSeqNum(host2,host5):=undef
			lastKnownDestSeqNum(host2,host6):=undef
			lastKnownDestSeqNum(host2,host7):=undef
			lastKnownDestSeqNum(host3,host1):=undef
			lastKnownDestSeqNum(host3,host2):=undef
			lastKnownDestSeqNum(host3,host4):=undef
			lastKnownDestSeqNum(host3,host5):=undef
			lastKnownDestSeqNum(host3,host6):=undef
			lastKnownDestSeqNum(host3,host7):=undef
			lastKnownDestSeqNum(host4,host1):=undef
			lastKnownDestSeqNum(host4,host3):=undef
			lastKnownDestSeqNum(host4,host5):=undef
			lastKnownDestSeqNum(host4,host6):=undef
			lastKnownDestSeqNum(host4,host7):=undef
			lastKnownDestSeqNum(host5,host1):=undef
			lastKnownDestSeqNum(host5,host2):=undef
			lastKnownDestSeqNum(host5,host3):=undef
			lastKnownDestSeqNum(host5,host4):=undef
			lastKnownDestSeqNum(host5,host6):=undef
			lastKnownDestSeqNum(host5,host7):=undef
			lastKnownDestSeqNum(host6,host1):=undef
			lastKnownDestSeqNum(host6,host2):=undef
			lastKnownDestSeqNum(host6,host3):=undef
			lastKnownDestSeqNum(host6,host4):=undef
			lastKnownDestSeqNum(host6,host5):=2
			lastKnownDestSeqNum(host6,host7):=undef
			lastKnownDestSeqNum(host7,host1):=undef
			lastKnownDestSeqNum(host7,host2):=undef
			lastKnownDestSeqNum(host7,host3):=undef
			lastKnownDestSeqNum(host7,host5):=undef
			lastKnownDestSeqNum(host7,host6):=undef
			localReqCount(host1):=3
			localReqCount(host2):=3
			localReqCount(host3):=3
			localReqCount(host4):=3
			localReqCount(host5):=2
			localReqCount(host6):=4
			localReqCount(host7):=3
			receivedReq(host1):=[(1,host1),(2,host1),(3,host1),(1,host5),(1,host4),(2,host5)]
			receivedReq(host2):=[(1,host2),(2,host2),(3,host2),(2,host7),(1,host4),(2,host6),(2,host4),(3,host6),(1,host5),(3,host4),(2,host3),(1,host7),(3,host3)]
			receivedReq(host3):=[(1,host3),(2,host3),(3,host3),(1,host4),(2,host2),(1,host5),(2,host6),(3,host6),(3,host2),(2,host4)]
			receivedReq(host4):=[(1,host4),(2,host4),(1,host7),(2,host2),(1,host5),(2,host6),(3,host4),(2,host7),(3,host1),(3,host3),(3,host6),(3,host2)]
			receivedReq(host5):=[(1,host5),(1,host7),(2,host5),(2,host4),(3,host1),(1,host4),(3,host3),(3,host4)]
			receivedReq(host6):=[(1,host6),(2,host6),(3,host6),(2,host4),(2,host2),(1,host5),(1,host4),(3,host4),(2,host3),(1,host7),(3,host2),(3,host3),(2,host7),(4,host6)]
			receivedReq(host7):=[(1,host7),(1,host4),(1,host5),(2,host7),(2,host1),(3,host1),(2,host4),(2,host2),(2,host6),(3,host6),(3,host4),(3,host2),(3,host7)]
			waitingForRouteTo(host1,host2):=true
			waitingForRouteTo(host1,host3):=true
			waitingForRouteTo(host1,host6):=true
			waitingForRouteTo(host1,host7):=true
			waitingForRouteTo(host2,host3):=true
			waitingForRouteTo(host2,host5):=true
			waitingForRouteTo(host3,host1):=true
			waitingForRouteTo(host3,host7):=true
			waitingForRouteTo(host4,host1):=true
			waitingForRouteTo(host5,host6):=true
			waitingForRouteTo(host6,host1):=true
			waitingForRouteTo(host6,host5):=true
			waitingForRouteTo(host7,host3):=true
			waitingForRouteToTmp(host1,host2):=0
			waitingForRouteToTmp(host1,host3):=0
			waitingForRouteToTmp(host1,host4):=2
			waitingForRouteToTmp(host1,host5):=1
			waitingForRouteToTmp(host1,host6):=1
			waitingForRouteToTmp(host1,host7):=0
			waitingForRouteToTmp(host2,host1):=0
			waitingForRouteToTmp(host2,host3):=0
			waitingForRouteToTmp(host2,host4):=0
			waitingForRouteToTmp(host2,host5):=1
			waitingForRouteToTmp(host2,host6):=0
			waitingForRouteToTmp(host2,host7):=0
			waitingForRouteToTmp(host3,host1):=2
			waitingForRouteToTmp(host3,host2):=1
			waitingForRouteToTmp(host3,host4):=2
			waitingForRouteToTmp(host3,host5):=0
			waitingForRouteToTmp(host3,host6):=3
			waitingForRouteToTmp(host3,host7):=1
			waitingForRouteToTmp(host4,host1):=2
			waitingForRouteToTmp(host4,host3):=0
			waitingForRouteToTmp(host4,host5):=2
			waitingForRouteToTmp(host4,host6):=2
			waitingForRouteToTmp(host4,host7):=3
			waitingForRouteToTmp(host5,host1):=0
			waitingForRouteToTmp(host5,host2):=0
			waitingForRouteToTmp(host5,host4):=2
			waitingForRouteToTmp(host5,host6):=1
			waitingForRouteToTmp(host5,host7):=3
			waitingForRouteToTmp(host6,host1):=1
			waitingForRouteToTmp(host6,host2):=1
			waitingForRouteToTmp(host6,host3):=0
			waitingForRouteToTmp(host6,host4):=2
			waitingForRouteToTmp(host6,host5):=5
			waitingForRouteToTmp(host6,host7):=1
			waitingForRouteToTmp(host7,host1):=1
			waitingForRouteToTmp(host7,host2):=1
			waitingForRouteToTmp(host7,host3):=5
			waitingForRouteToTmp(host7,host5):=3
			waitingForRouteToTmp(host7,host6):=3

			extend RoutingTable with $_rt1,$_rt2,$_rt3,$_rt4,$_rt5,$_rt6,$_rt7,$_rt8,$_rt9,$_rt10,$_rt11,$_rt12,$_rt13,$_rt14,$_rt15,$_rt16,$_rt17,$_rt18,$_rt19,$_rt20,$_rt21,$_rt22,$_rt23,$_rt24,$_rt25,$_rt26,$_rt27,$_rt28,$_rt29,$_rt30,$_rt31 do
				par
									active($_rt1):=true
					active($_rt10):=true
					active($_rt11):=false
					active($_rt12):=true
					active($_rt13):=true
					active($_rt14):=true
					active($_rt15):=false
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
					active($_rt3):=false
					active($_rt30):=true
					active($_rt31):=true
					active($_rt4):=true
					active($_rt5):=true
					active($_rt6):=true
					active($_rt7):=true
					active($_rt8):=true
					active($_rt9):=true
					entry($_rt1):=(host7,1,1,host7)
					entry($_rt10):=(host2,3,1,host2)
					entry($_rt11):=(host5,2,2,host7)
					entry($_rt12):=(host5,2,1,host5)
					entry($_rt13):=(host4,1,2,host7)
					entry($_rt14):=(host1,3,1,host1)
					entry($_rt15):=(host1,4,1,host1)
					entry($_rt16):=(host2,3,1,host2)
					entry($_rt17):=(host6,3,1,host6)
					entry($_rt18):=(host4,2,2,host6)
					entry($_rt19):=(host2,3,1,host2)
					entry($_rt2):=(host4,3,1,host4)
					entry($_rt20):=(host5,1,3,host6)
					entry($_rt21):=(host6,3,1,host6)
					entry($_rt22):=(host3,3,1,host3)
					entry($_rt23):=(host7,2,2,host2)
					entry($_rt24):=(host7,2,1,host7)
					entry($_rt25):=(host4,3,1,host4)
					entry($_rt26):=(host6,3,2,host3)
					entry($_rt27):=(host5,1,3,host6)
					entry($_rt28):=(host3,3,1,host3)
					entry($_rt29):=(host1,3,2,host7)
					entry($_rt3):=(host5,2,1,host5)
					entry($_rt30):=(host3,3,2,host6)
					entry($_rt31):=(host3,3,2,host6)
					entry($_rt4):=(host4,3,2,host6)
					entry($_rt5):=(host7,2,1,host7)
					entry($_rt6):=(host2,3,1,host2)
					entry($_rt7):=(host5,1,2,host7)
					entry($_rt8):=(host6,3,1,host6)
					entry($_rt9):=(host4,3,1,host4)
					entryFor(host1):=$_rt12
					entryFor(host2):=$_rt27
					entryFor(host3):=$_rt20
					entryFor(host4):=$_rt5
					entryFor(host5):=$_rt14
					entryFor(host6):=$_rt23
					entryFor(host7):=$_rt3
					owner($_rt1):=host5
					owner($_rt10):=host6
					owner($_rt11):=host6
					owner($_rt12):=host1
					owner($_rt13):=host1
					owner($_rt14):=host5
					owner($_rt15):=host7
					owner($_rt16):=host7
					owner($_rt17):=host7
					owner($_rt18):=host3
					owner($_rt19):=host3
					owner($_rt2):=host7
					owner($_rt20):=host3
					owner($_rt21):=host3
					owner($_rt22):=host6
					owner($_rt23):=host6
					owner($_rt24):=host2
					owner($_rt25):=host2
					owner($_rt26):=host2
					owner($_rt27):=host2
					owner($_rt28):=host2
					owner($_rt29):=host4
					owner($_rt3):=host7
					owner($_rt30):=host4
					owner($_rt31):=host5
					owner($_rt4):=host5
					owner($_rt5):=host4
					owner($_rt6):=host4
					owner($_rt7):=host4
					owner($_rt8):=host4
					owner($_rt9):=host6
					precursor($_rt1):=[]
					precursor($_rt10):=[]
					precursor($_rt11):=[]
					precursor($_rt12):=[]
					precursor($_rt13):=[]
					precursor($_rt14):=[host6,host6]
					precursor($_rt15):=[]
					precursor($_rt16):=[]
					precursor($_rt17):=[]
					precursor($_rt18):=[]
					precursor($_rt19):=[]
					precursor($_rt2):=[host1]
					precursor($_rt20):=[host2,host6]
					precursor($_rt21):=[]
					precursor($_rt22):=[]
					precursor($_rt23):=[]
					precursor($_rt24):=[host3]
					precursor($_rt25):=[host3]
					precursor($_rt26):=[]
					precursor($_rt27):=[host4]
					precursor($_rt28):=[]
					precursor($_rt29):=[host6,host6]
					precursor($_rt3):=[]
					precursor($_rt30):=[]
					precursor($_rt31):=[]
					precursor($_rt4):=[]
					precursor($_rt5):=[host6]
					precursor($_rt6):=[]
					precursor($_rt7):=[host2]
					precursor($_rt8):=[host7,host7]
					precursor($_rt9):=[host3]
				endpar
			extend Message with $_message1,$_message2,$_message3,$_message4,$_message5,$_message6,$_message7,$_message8,$_message9,$_message10,$_message11,$_message12,$_message13,$_message14,$_message15,$_message16,$_message17,$_message18,$_message19,$_message20,$_message21,$_message22,$_message23,$_message24,$_message25,$_message26,$_message27,$_message28,$_message29,$_message30,$_message31,$_message32,$_message33,$_message34,$_message35,$_message36,$_message37,$_message38,$_message39,$_message40,$_message41,$_message42,$_message43,$_message44,$_message45,$_message46,$_message47,$_message48,$_message49,$_message50,$_message51,$_message52,$_message53,$_message54,$_message55,$_message56,$_message57,$_message58,$_message59,$_message60,$_message61,$_message62,$_message63,$_message64,$_message65,$_message66,$_message67,$_message68,$_message69,$_message70,$_message71,$_message72,$_message73,$_message74,$_message75,$_message76,$_message77,$_message78,$_message79,$_message80,$_message81,$_message82,$_message83,$_message84,$_message85,$_message86,$_message87,$_message88,$_message89,$_message90,$_message91,$_message92,$_message93,$_message94,$_message95,$_message96,$_message97,$_message98,$_message99,$_message100,$_message101,$_message102,$_message103,$_message104,$_message105,$_message106 do
				par
									isConsumed(host1,$_message103):=false
					isConsumed(host1,$_message106):=false
					isConsumed(host1,$_message25):=true
					isConsumed(host1,$_message26):=true
					isConsumed(host1,$_message33):=true
					isConsumed(host1,$_message39):=false
					isConsumed(host1,$_message52):=true
					isConsumed(host1,$_message53):=true
					isConsumed(host1,$_message55):=false
					isConsumed(host1,$_message56):=false
					isConsumed(host1,$_message58):=false
					isConsumed(host2,$_message104):=false
					isConsumed(host2,$_message106):=false
					isConsumed(host2,$_message23):=true
					isConsumed(host2,$_message24):=true
					isConsumed(host2,$_message25):=true
					isConsumed(host2,$_message26):=true
					isConsumed(host2,$_message27):=true
					isConsumed(host2,$_message35):=true
					isConsumed(host2,$_message36):=true
					isConsumed(host2,$_message37):=true
					isConsumed(host2,$_message39):=true
					isConsumed(host2,$_message40):=true
					isConsumed(host2,$_message41):=true
					isConsumed(host2,$_message42):=true
					isConsumed(host2,$_message43):=true
					isConsumed(host2,$_message44):=true
					isConsumed(host2,$_message48):=true
					isConsumed(host2,$_message49):=true
					isConsumed(host2,$_message50):=true
					isConsumed(host2,$_message54):=true
					isConsumed(host2,$_message62):=true
					isConsumed(host2,$_message65):=true
					isConsumed(host2,$_message66):=true
					isConsumed(host2,$_message67):=true
					isConsumed(host2,$_message68):=true
					isConsumed(host2,$_message71):=false
					isConsumed(host2,$_message72):=false
					isConsumed(host2,$_message75):=false
					isConsumed(host2,$_message76):=false
					isConsumed(host2,$_message77):=false
					isConsumed(host2,$_message95):=false
					isConsumed(host2,$_message98):=false
					isConsumed(host2,$_message99):=false
					isConsumed(host3,$_message106):=false
					isConsumed(host3,$_message23):=false
					isConsumed(host3,$_message24):=false
					isConsumed(host3,$_message27):=true
					isConsumed(host3,$_message40):=true
					isConsumed(host3,$_message41):=true
					isConsumed(host3,$_message42):=true
					isConsumed(host3,$_message43):=true
					isConsumed(host3,$_message44):=true
					isConsumed(host3,$_message51):=true
					isConsumed(host3,$_message72):=false
					isConsumed(host3,$_message73):=false
					isConsumed(host3,$_message76):=false
					isConsumed(host3,$_message81):=false
					isConsumed(host3,$_message82):=false
					isConsumed(host3,$_message83):=false
					isConsumed(host3,$_message84):=false
					isConsumed(host3,$_message85):=false
					isConsumed(host3,$_message86):=false
					isConsumed(host3,$_message87):=false
					isConsumed(host3,$_message88):=false
					isConsumed(host3,$_message90):=false
					isConsumed(host4,$_message10):=true
					isConsumed(host4,$_message102):=false
					isConsumed(host4,$_message104):=false
					isConsumed(host4,$_message105):=false
					isConsumed(host4,$_message106):=false
					isConsumed(host4,$_message25):=true
					isConsumed(host4,$_message26):=true
					isConsumed(host4,$_message27):=true
					isConsumed(host4,$_message32):=true
					isConsumed(host4,$_message33):=false
					isConsumed(host4,$_message34):=false
					isConsumed(host4,$_message39):=true
					isConsumed(host4,$_message40):=true
					isConsumed(host4,$_message41):=true
					isConsumed(host4,$_message42):=true
					isConsumed(host4,$_message43):=true
					isConsumed(host4,$_message44):=true
					isConsumed(host4,$_message51):=true
					isConsumed(host4,$_message56):=true
					isConsumed(host4,$_message57):=true
					isConsumed(host4,$_message58):=true
					isConsumed(host4,$_message7):=true
					isConsumed(host4,$_message70):=true
					isConsumed(host4,$_message72):=true
					isConsumed(host4,$_message74):=true
					isConsumed(host4,$_message76):=true
					isConsumed(host4,$_message78):=true
					isConsumed(host4,$_message79):=true
					isConsumed(host4,$_message8):=true
					isConsumed(host4,$_message81):=true
					isConsumed(host4,$_message82):=true
					isConsumed(host4,$_message84):=true
					isConsumed(host4,$_message85):=true
					isConsumed(host4,$_message86):=true
					isConsumed(host4,$_message87):=true
					isConsumed(host4,$_message89):=true
					isConsumed(host4,$_message9):=true
					isConsumed(host4,$_message90):=true
					isConsumed(host4,$_message99):=false
					isConsumed(host5,$_message10):=true
					isConsumed(host5,$_message106):=false
					isConsumed(host5,$_message23):=true
					isConsumed(host5,$_message24):=true
					isConsumed(host5,$_message25):=true
					isConsumed(host5,$_message26):=true
					isConsumed(host5,$_message35):=false
					isConsumed(host5,$_message36):=false
					isConsumed(host5,$_message37):=false
					isConsumed(host5,$_message45):=true
					isConsumed(host5,$_message47):=true
					isConsumed(host5,$_message56):=false
					isConsumed(host5,$_message58):=false
					isConsumed(host5,$_message61):=false
					isConsumed(host5,$_message7):=true
					isConsumed(host5,$_message72):=true
					isConsumed(host5,$_message76):=true
					isConsumed(host5,$_message8):=true
					isConsumed(host5,$_message80):=true
					isConsumed(host5,$_message9):=true
					isConsumed(host6,$_message100):=false
					isConsumed(host6,$_message101):=false
					isConsumed(host6,$_message102):=false
					isConsumed(host6,$_message105):=false
					isConsumed(host6,$_message23):=true
					isConsumed(host6,$_message24):=true
					isConsumed(host6,$_message25):=true
					isConsumed(host6,$_message26):=true
					isConsumed(host6,$_message32):=true
					isConsumed(host6,$_message35):=true
					isConsumed(host6,$_message36):=true
					isConsumed(host6,$_message37):=true
					isConsumed(host6,$_message38):=true
					isConsumed(host6,$_message39):=false
					isConsumed(host6,$_message48):=true
					isConsumed(host6,$_message49):=true
					isConsumed(host6,$_message50):=true
					isConsumed(host6,$_message51):=true
					isConsumed(host6,$_message54):=true
					isConsumed(host6,$_message56):=false
					isConsumed(host6,$_message58):=false
					isConsumed(host6,$_message59):=false
					isConsumed(host6,$_message60):=false
					isConsumed(host6,$_message62):=true
					isConsumed(host6,$_message63):=true
					isConsumed(host6,$_message64):=true
					isConsumed(host6,$_message65):=true
					isConsumed(host6,$_message66):=true
					isConsumed(host6,$_message67):=true
					isConsumed(host6,$_message69):=true
					isConsumed(host6,$_message81):=true
					isConsumed(host6,$_message82):=true
					isConsumed(host6,$_message84):=true
					isConsumed(host6,$_message85):=true
					isConsumed(host6,$_message86):=true
					isConsumed(host6,$_message87):=true
					isConsumed(host6,$_message90):=true
					isConsumed(host6,$_message93):=false
					isConsumed(host6,$_message94):=false
					isConsumed(host7,$_message1):=true
					isConsumed(host7,$_message106):=false
					isConsumed(host7,$_message2):=true
					isConsumed(host7,$_message22):=true
					isConsumed(host7,$_message23):=true
					isConsumed(host7,$_message24):=true
					isConsumed(host7,$_message27):=true
					isConsumed(host7,$_message28):=true
					isConsumed(host7,$_message29):=true
					isConsumed(host7,$_message3):=true
					isConsumed(host7,$_message30):=true
					isConsumed(host7,$_message31):=true
					isConsumed(host7,$_message32):=true
					isConsumed(host7,$_message35):=true
					isConsumed(host7,$_message36):=true
					isConsumed(host7,$_message37):=true
					isConsumed(host7,$_message4):=true
					isConsumed(host7,$_message40):=true
					isConsumed(host7,$_message41):=true
					isConsumed(host7,$_message42):=true
					isConsumed(host7,$_message43):=true
					isConsumed(host7,$_message44):=true
					isConsumed(host7,$_message45):=true
					isConsumed(host7,$_message46):=true
					isConsumed(host7,$_message47):=true
					isConsumed(host7,$_message5):=true
					isConsumed(host7,$_message51):=true
					isConsumed(host7,$_message52):=true
					isConsumed(host7,$_message53):=true
					isConsumed(host7,$_message54):=true
					isConsumed(host7,$_message6):=true
					isConsumed(host7,$_message81):=false
					isConsumed(host7,$_message82):=false
					isConsumed(host7,$_message84):=false
					isConsumed(host7,$_message85):=false
					isConsumed(host7,$_message86):=false
					isConsumed(host7,$_message87):=false
					isConsumed(host7,$_message90):=false
					isConsumed(host7,$_message91):=true
					isConsumed(host7,$_message92):=true
					isConsumed(host7,$_message96):=true
					isConsumed(host7,$_message97):=true
					messageRERR($_message104):=(host5,2,host7)
					messageRERR($_message105):=(host1,4,host7)
					messageRERR($_message99):=(host5,2,host6)
					messageRREP($_message100):=(host3,1,host1,3,host5)
					messageRREP($_message101):=(host4,1,host1,3,host5)
					messageRREP($_message103):=(host1,1,host6,2,host7)
					messageRREP($_message22):=(host7,0,host5,1,host5)
					messageRREP($_message34):=(host4,0,host5,2,host5)
					messageRREP($_message38):=(host6,1,host7,1,host4)
					messageRREP($_message46):=(host5,0,host1,3,host1)
					messageRREP($_message55):=(host1,1,host4,1,host7)
					messageRREP($_message57):=(host4,1,host5,1,host7)
					messageRREP($_message59):=(host6,0,host7,2,host7)
					messageRREP($_message60):=(host6,1,host1,3,host7)
					messageRREP($_message61):=(host5,1,host1,3,host7)
					messageRREP($_message63):=(host4,0,host3,3,host3)
					messageRREP($_message64):=(host2,0,host3,3,host3)
					messageRREP($_message68):=(host2,3,host5,1,host3)
					messageRREP($_message69):=(host4,3,host5,1,host3)
					messageRREP($_message70):=(host4,1,host1,3,host7)
					messageRREP($_message71):=(host2,1,host5,1,host7)
					messageRREP($_message73):=(host3,1,host4,3,host6)
					messageRREP($_message74):=(host7,2,host5,1,host6)
					messageRREP($_message75):=(host2,2,host5,1,host6)
					messageRREP($_message77):=(host2,1,host3,3,host6)
					messageRREP($_message78):=(host4,2,host5,1,host6)
					messageRREP($_message79):=(host4,1,host3,3,host6)
					messageRREP($_message83):=(host6,1,host7,2,host2)
					messageRREP($_message88):=(host3,1,host4,3,host2)
					messageRREP($_message89):=(host7,3,host5,1,host2)
					messageRREP($_message91):=(host7,1,host6,2,host4)
					messageRREP($_message92):=(host1,1,host6,2,host4)
					messageRREP($_message93):=(host3,2,host1,3,host4)
					messageRREP($_message94):=(host6,2,host1,3,host4)
					messageRREP($_message95):=(host2,2,host5,1,host4)
					messageRREP($_message96):=(host7,2,host5,1,host4)
					messageRREP($_message97):=(host7,2,host5,1,host4)
					messageRREP($_message98):=(host7,0,host6,3,host6)
					messageRREQ($_message1):=(host5,1,0,host4,undef,1,host5)
					messageRREQ($_message10):=(host7,1,0,host2,undef,1,host7)
					messageRREQ($_message102):=(host7,3,0,host3,undef,3,host7)
					messageRREQ($_message106):=(host6,4,0,host5,2,4,host6)
					messageRREQ($_message11):=(host6,1,0,host5,undef,1,host6)
					messageRREQ($_message12):=(host6,1,0,host4,undef,1,host6)
					messageRREQ($_message13):=(host6,1,0,host3,undef,1,host6)
					messageRREQ($_message14):=(host6,1,0,host2,undef,1,host6)
					messageRREQ($_message15):=(host1,1,0,host5,undef,1,host1)
					messageRREQ($_message16):=(host3,1,0,host5,undef,1,host3)
					messageRREQ($_message17):=(host3,1,0,host2,undef,1,host3)
					messageRREQ($_message18):=(host2,1,0,host4,undef,1,host2)
					messageRREQ($_message19):=(host2,1,0,host7,undef,1,host2)
					messageRREQ($_message2):=(host5,1,0,host7,undef,1,host5)
					messageRREQ($_message20):=(host2,1,0,host6,undef,1,host2)
					messageRREQ($_message21):=(host2,1,0,host1,undef,1,host2)
					messageRREQ($_message23):=(host4,2,0,host5,undef,2,host4)
					messageRREQ($_message24):=(host4,2,0,host7,undef,2,host4)
					messageRREQ($_message25):=(host4,1,1,host3,undef,1,host7)
					messageRREQ($_message26):=(host5,1,1,host1,undef,1,host7)
					messageRREQ($_message27):=(host6,2,0,host7,undef,2,host6)
					messageRREQ($_message28):=(host1,2,0,host4,undef,2,host1)
					messageRREQ($_message29):=(host1,2,0,host7,undef,2,host1)
					messageRREQ($_message3):=(host5,1,0,host1,undef,1,host5)
					messageRREQ($_message30):=(host1,2,0,host3,undef,2,host1)
					messageRREQ($_message31):=(host1,2,0,host2,undef,2,host1)
					messageRREQ($_message32):=(host2,2,0,host3,undef,2,host2)
					messageRREQ($_message33):=(host5,2,0,host6,undef,2,host5)
					messageRREQ($_message35):=(host7,1,1,host5,undef,1,host4)
					messageRREQ($_message36):=(host2,2,1,host3,undef,2,host4)
					messageRREQ($_message37):=(host5,1,2,host1,undef,1,host4)
					messageRREQ($_message39):=(host7,2,0,host6,undef,2,host7)
					messageRREQ($_message4):=(host5,1,0,host2,undef,1,host5)
					messageRREQ($_message40):=(host6,3,0,host1,undef,3,host6)
					messageRREQ($_message41):=(host4,2,1,host5,undef,2,host6)
					messageRREQ($_message42):=(host2,2,1,host3,undef,2,host6)
					messageRREQ($_message43):=(host5,1,2,host1,undef,1,host6)
					messageRREQ($_message44):=(host4,1,2,host3,undef,1,host6)
					messageRREQ($_message45):=(host1,3,0,host6,undef,3,host1)
					messageRREQ($_message47):=(host4,1,2,host3,undef,1,host1)
					messageRREQ($_message48):=(host3,2,0,host4,undef,2,host3)
					messageRREQ($_message49):=(host3,2,0,host7,undef,2,host3)
					messageRREQ($_message5):=(host4,1,0,host6,undef,1,host4)
					messageRREQ($_message50):=(host3,2,0,host6,undef,2,host3)
					messageRREQ($_message51):=(host2,3,0,host5,undef,3,host2)
					messageRREQ($_message52):=(host1,3,1,host6,undef,3,host5)
					messageRREQ($_message53):=(host4,1,3,host3,undef,1,host5)
					messageRREQ($_message54):=(host4,3,0,host1,undef,3,host4)
					messageRREQ($_message56):=(host1,3,1,host6,undef,3,host7)
					messageRREQ($_message58):=(host2,2,2,host3,undef,2,host7)
					messageRREQ($_message6):=(host4,1,0,host3,undef,1,host4)
					messageRREQ($_message62):=(host3,3,0,host1,undef,3,host3)
					messageRREQ($_message65):=(host5,1,3,host1,undef,1,host3)
					messageRREQ($_message66):=(host6,2,1,host7,undef,2,host3)
					messageRREQ($_message67):=(host6,3,1,host1,undef,3,host3)
					messageRREQ($_message7):=(host7,1,0,host5,undef,1,host7)
					messageRREQ($_message72):=(host4,3,1,host1,undef,3,host6)
					messageRREQ($_message76):=(host3,3,1,host1,undef,3,host6)
					messageRREQ($_message8):=(host7,1,0,host1,undef,1,host7)
					messageRREQ($_message80):=(host5,2,1,host6,undef,2,host1)
					messageRREQ($_message81):=(host7,2,1,host6,undef,2,host2)
					messageRREQ($_message82):=(host4,1,3,host3,undef,1,host2)
					messageRREQ($_message84):=(host4,2,1,host5,undef,2,host2)
					messageRREQ($_message85):=(host6,3,2,host1,undef,3,host2)
					messageRREQ($_message86):=(host5,1,3,host1,undef,1,host2)
					messageRREQ($_message87):=(host4,3,1,host1,undef,3,host2)
					messageRREQ($_message9):=(host7,1,0,host3,undef,1,host7)
					messageRREQ($_message90):=(host3,3,1,host1,undef,3,host2)
					messageType($_message1):=RREQ
					messageType($_message10):=RREQ
					messageType($_message100):=RREP
					messageType($_message101):=RREP
					messageType($_message102):=RREQ
					messageType($_message103):=RREP
					messageType($_message104):=RERR
					messageType($_message105):=RERR
					messageType($_message106):=RREQ
					messageType($_message11):=RREQ
					messageType($_message12):=RREQ
					messageType($_message13):=RREQ
					messageType($_message14):=RREQ
					messageType($_message15):=RREQ
					messageType($_message16):=RREQ
					messageType($_message17):=RREQ
					messageType($_message18):=RREQ
					messageType($_message19):=RREQ
					messageType($_message2):=RREQ
					messageType($_message20):=RREQ
					messageType($_message21):=RREQ
					messageType($_message22):=RREP
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
					messageType($_message34):=RREP
					messageType($_message35):=RREQ
					messageType($_message36):=RREQ
					messageType($_message37):=RREQ
					messageType($_message38):=RREP
					messageType($_message39):=RREQ
					messageType($_message4):=RREQ
					messageType($_message40):=RREQ
					messageType($_message41):=RREQ
					messageType($_message42):=RREQ
					messageType($_message43):=RREQ
					messageType($_message44):=RREQ
					messageType($_message45):=RREQ
					messageType($_message46):=RREP
					messageType($_message47):=RREQ
					messageType($_message48):=RREQ
					messageType($_message49):=RREQ
					messageType($_message5):=RREQ
					messageType($_message50):=RREQ
					messageType($_message51):=RREQ
					messageType($_message52):=RREQ
					messageType($_message53):=RREQ
					messageType($_message54):=RREQ
					messageType($_message55):=RREP
					messageType($_message56):=RREQ
					messageType($_message57):=RREP
					messageType($_message58):=RREQ
					messageType($_message59):=RREP
					messageType($_message6):=RREQ
					messageType($_message60):=RREP
					messageType($_message61):=RREP
					messageType($_message62):=RREQ
					messageType($_message63):=RREP
					messageType($_message64):=RREP
					messageType($_message65):=RREQ
					messageType($_message66):=RREQ
					messageType($_message67):=RREQ
					messageType($_message68):=RREP
					messageType($_message69):=RREP
					messageType($_message7):=RREQ
					messageType($_message70):=RREP
					messageType($_message71):=RREP
					messageType($_message72):=RREQ
					messageType($_message73):=RREP
					messageType($_message74):=RREP
					messageType($_message75):=RREP
					messageType($_message76):=RREQ
					messageType($_message77):=RREP
					messageType($_message78):=RREP
					messageType($_message79):=RREP
					messageType($_message8):=RREQ
					messageType($_message80):=RREQ
					messageType($_message81):=RREQ
					messageType($_message82):=RREQ
					messageType($_message83):=RREP
					messageType($_message84):=RREQ
					messageType($_message85):=RREQ
					messageType($_message86):=RREQ
					messageType($_message87):=RREQ
					messageType($_message88):=RREP
					messageType($_message89):=RREP
					messageType($_message9):=RREQ
					messageType($_message90):=RREQ
					messageType($_message91):=RREP
					messageType($_message92):=RREP
					messageType($_message93):=RREP
					messageType($_message94):=RREP
					messageType($_message95):=RREP
					messageType($_message96):=RREP
					messageType($_message97):=RREP
					messageType($_message98):=RREP
					messageType($_message99):=RERR
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
				if($c <= 100) then
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
