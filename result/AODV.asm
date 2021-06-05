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
			isLinked(host1,host2):=true
			isLinked(host2,host1):=true
			isLinked(host1,host3):=true
			isLinked(host3,host1):=true
			isLinked(host1,host4):=true
			isLinked(host4,host1):=true
			isLinked(host1,host5):=true
			isLinked(host5,host1):=true
			isLinked(host2,host4):=true
			isLinked(host4,host2):=true
			isLinked(host2,host5):=true
			isLinked(host5,host2):=true
			isLinked(host3,host4):=true
			isLinked(host4,host3):=true
			isLinked(host3,host5):=true
			isLinked(host5,host3):=true
			isLinked(host4,host5):=true
			isLinked(host5,host4):=true

			curSeqNum(host1):=2
			curSeqNum(host3):=1
			curSeqNum(host4):=1
			curSeqNum(host5):=1
			lastKnownDestSeqNum(host1,host2):=undef
			lastKnownDestSeqNum(host1,host4):=undef
			lastKnownDestSeqNum(host1,host5):=undef
			lastKnownDestSeqNum(host3,host1):=undef
			lastKnownDestSeqNum(host4,host1):=undef
			lastKnownDestSeqNum(host4,host3):=undef
			lastKnownDestSeqNum(host4,host5):=undef
			lastKnownDestSeqNum(host5,host3):=undef
			localReqCount(host1):=2
			localReqCount(host3):=1
			localReqCount(host4):=1
			localReqCount(host5):=1
			receivedReq(host1):=[(1,host1),(2,host1)]
			receivedReq(host3):=[(1,host3)]
			receivedReq(host4):=[(1,host4)]
			receivedReq(host5):=[(1,host5)]
			waitingForRouteTo(host1,host2):=true
			waitingForRouteTo(host1,host4):=true
			waitingForRouteTo(host1,host5):=true
			waitingForRouteTo(host3,host1):=true
			waitingForRouteTo(host4,host1):=true
			waitingForRouteTo(host4,host3):=true
			waitingForRouteTo(host4,host5):=true
			waitingForRouteTo(host5,host3):=true
			waitingForRouteToTmp(host1,host2):=4
			waitingForRouteToTmp(host1,host4):=4
			waitingForRouteToTmp(host1,host5):=5
			waitingForRouteToTmp(host3,host1):=5
			waitingForRouteToTmp(host4,host1):=3
			waitingForRouteToTmp(host4,host3):=3
			waitingForRouteToTmp(host4,host5):=3
			waitingForRouteToTmp(host5,host3):=4


			extend Message with $_message1,$_message2,$_message3,$_message4,$_message5,$_message6,$_message7,$_message8 do
				par
									isConsumed(host2,$_message5):=false
					isConsumed(host2,$_message6):=false
					isConsumed(host2,$_message7):=false
					isConsumed(host3,$_message5):=false
					isConsumed(host3,$_message6):=false
					isConsumed(host4,$_message4):=false
					isConsumed(host4,$_message5):=false
					isConsumed(host4,$_message6):=false
					isConsumed(host4,$_message7):=false
					isConsumed(host5,$_message1):=false
					isConsumed(host5,$_message2):=false
					isConsumed(host5,$_message3):=false
					isConsumed(host5,$_message7):=false
					messageRREQ($_message1):=(host4,1,0,host5,undef,1,host4)
					messageRREQ($_message2):=(host4,1,0,host1,undef,1,host4)
					messageRREQ($_message3):=(host4,1,0,host3,undef,1,host4)
					messageRREQ($_message4):=(host5,1,0,host3,undef,1,host5)
					messageRREQ($_message5):=(host1,1,0,host4,undef,1,host1)
					messageRREQ($_message6):=(host1,1,0,host2,undef,1,host1)
					messageRREQ($_message7):=(host1,2,0,host5,undef,2,host1)
					messageRREQ($_message8):=(host3,1,0,host1,undef,1,host3)
					messageType($_message1):=RREQ
					messageType($_message2):=RREQ
					messageType($_message3):=RREQ
					messageType($_message4):=RREQ
					messageType($_message5):=RREQ
					messageType($_message6):=RREQ
					messageType($_message7):=RREQ
					messageType($_message8):=RREQ
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
