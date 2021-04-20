asm BNAODV_COPIA

import StandardLibrary

signature:
	dynamic abstract domain Malicious	
	dynamic abstract domain MaliciousMessage 
	dynamic abstract domain Message	
	dynamic abstract domain RoutingTable 
	dynamic abstract domain Success	
	dynamic abstract domain Time
	dynamic abstract domain Trial
	dynamic abstract domain Update
	enum domain MessageType = {RREQ | RREP | RERR | NACK | CHL | RES} 
	
	domain Blackhole subsetof Agent
	domain Colluder subsetof Agent
	domain Host subsetof Agent
						
	dynamic controlled active: RoutingTable -> Boolean 	
	dynamic controlled challenges: Message -> Agent	
	dynamic controlled curSeqNum: Agent -> Integer  
	dynamic controlled entry: RoutingTable -> Prod(Agent, Integer, Integer, Agent) 	
	dynamic controlled entryFor: Agent -> RoutingTable
	dynamic controlled errors: Prod(Message, Integer) -> Agent
	dynamic controlled interceptedBlackhole: Prod(Malicious,Agent) -> Agent
	dynamic controlled isConsumed: Prod(Message, Integer) -> Boolean
	dynamic controlled isConsumedCHL: Message -> Boolean
	dynamic controlled isConsumedRES: Message -> Boolean
	dynamic controlled isConsumedRREP: Message -> Boolean
	dynamic controlled isConsumedNACK: Message -> Boolean
	dynamic controlled isLinked: Prod(Agent, Agent) -> Boolean
	dynamic controlled isInitialized: Boolean
	dynamic controlled lastKnownDestSeqNum: Prod(Agent,Agent) -> Integer
	dynamic controlled localReqCount: Agent -> Integer
	dynamic controlled maxKnownDestSeqNum: Agent -> Integer
	dynamic controlled messageRERR: Message -> Prod(Agent, Integer, Agent)	
	dynamic controlled messageRREP: Message -> Prod(Agent, Integer, Agent, Integer, Agent, Prod(Integer,Agent))	
	dynamic controlled messageRREQ: Message -> Prod(Agent, Integer, Integer, Agent, Integer, Integer, Agent)
	dynamic controlled messageNACK: Message -> Prod(Agent, Integer, Integer, Agent, Integer, Agent)
	dynamic controlled messageCHL: Message -> Prod(Agent, Agent, Integer, Prod(Integer,Agent), Agent)
	dynamic controlled messageRES: Message -> Prod(Agent, Agent, Integer, Prod(Integer,Agent))
	dynamic controlled messageType: Message -> MessageType	
	dynamic controlled nacks: Message -> Agent		
	dynamic controlled nonce: Prod(Agent,Prod(Integer,Agent)) -> Integer 		
	dynamic controlled owner: RoutingTable -> Agent	
	dynamic controlled precursor: RoutingTable -> Seq(Agent)
	dynamic controlled receivedReq: Agent -> Seq(Prod(Integer, Agent))	
	dynamic controlled replies: Message -> Agent	
	dynamic controlled requests: Prod(Message, Integer) -> Agent	
	dynamic controlled ress: Message -> Agent	
	dynamic controlled set: Time -> Integer
	dynamic controlled trusted: Message -> Boolean
	dynamic controlled waitingForRouteTo: Prod(Agent, Agent) -> Boolean 
	dynamic controlled waitingTime: Message -> Integer
	dynamic controlled waitingTime: Prod(Agent,Agent) -> Integer
	
	dynamic controlled m_controlOverhead: Integer
	dynamic controlled m_interceptedBlackhole: Integer
	dynamic controlled m_maliciousOverhead: Integer
	dynamic controlled m_rateOfSuccess_r: Integer
	dynamic controlled m_rateOfSuccess_s: Integer
	dynamic controlled m_routingTableSize: Integer	
	dynamic controlled m_updateRoutingTable: Integer	
	
	static blackhole1: Blackhole
	static colluder1: Colluder
	static host1: Host
	static host2: Host
	static host3: Host
	static host4: Host
	static host5: Host
	
	derived dest: Message -> Agent	
	derived destSeqNum: Message -> Integer	
	derived hopCount: Message -> Integer
	derived localId: Message -> Integer	
	derived origin: Message -> Agent	
	derived originSeqNum: Message -> Integer
	derived sender: Message -> Agent	
	derived nonce: Message -> Integer
	
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
			case NACK: first(messageNACK($m))
			case CHL: second(messageCHL($m))
			case RES: second(messageRES($m))
		endswitch
	
	function originSeqNum($m in Message) =
		switch messageType($m)
			case RREQ: second(messageRREQ($m))
			case NACK: second(messageNACK($m))
		endswitch
	
	function hopCount($m in Message) =
		switch messageType($m)
			case RREQ: third(messageRREQ($m))
			case RREP: second(messageRREP($m))
			case NACK: third(messageNACK($m))
		endswitch
		
	function dest($m in Message) =
		switch messageType($m)
			case RREQ: fourth(messageRREQ($m))
			case RREP: third(messageRREP($m))
			case RERR: first(messageRERR($m))
			case NACK: fourth(messageNACK($m))
			case CHL: first(messageCHL($m))
			case RES: first(messageRES($m))
		endswitch
		
	function destSeqNum($m in Message) =
		switch messageType($m)
			case RREQ: fifth(messageRREQ($m))
			case RREP: fourth(messageRREP($m))
			case RERR: second(messageRERR($m))
			case NACK: fifth(messageNACK($m))
		endswitch
		
	function localId($m in Message) =
		sixth(messageRREQ($m))
		
	function sender($m in Message) =
		switch messageType($m)
			case RREQ: seventh(messageRREQ($m))
			case RREP: fifth(messageRREP($m))
			case RERR: third(messageRERR($m))
			case NACK: sixth(messageNACK($m))
			case CHL: fifth(messageCHL($m))
		endswitch
	
	function nonce($m in Message) =
		switch messageType($m)
			case CHL: third(messageCHL($m))
			case RES: third(messageRES($m))
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
		switch messageType($m)
			case RREQ: (localId($m), origin($m))	
			case RREP: (first(sixth(messageRREP($m))), origin($m))
			case CHL: (first(fourth(messageCHL($m))), second(fourth(messageCHL($m))))
			case RES: (first(fourth(messageRES($m))), second(fourth(messageRES($m))))
		endswitch		 
			
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
		extend Success with $newsuccess do skip	
	
	rule r_LastKnownDestSeqNum($dest in Agent) =
		choose $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest and entrySeqNum($e)!=undef) do 
			lastKnownDestSeqNum(self,$dest) := entrySeqNum($e)
		ifnone 
			lastKnownDestSeqNum(self,$dest) := undef
			
	rule r_MaxKnownDestSeqNum($destSeqNum in Integer) =
		if ($destSeqNum != undef) then
			if (maxKnownDestSeqNum(self) != undef) then
				if ($destSeqNum > maxKnownDestSeqNum(self)) then
					maxKnownDestSeqNum(self) := $destSeqNum
				endif
			else
				maxKnownDestSeqNum(self) := 100
			endif
		endif
	
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
		switch messageType($m) 
			case RREQ: 
				extend Time with $newtime do
					seq	
						set($newtime) := currTimeNanosecs
						requests($m, set($newtime)) := $n							
						isConsumed($m, set($newtime)) := false
					endseq
			case RREP: 
				par
					replies($m) := $n
					isConsumedRREP($m) := false
				endpar
			case RERR:
				extend Time with $newtimet do
					seq	
						set($newtimet) := currTimeNanosecs
						errors($m, set($newtimet)) := $n
						isConsumed($m, set($newtimet)) := false
					endseq
			case NACK:
				par
					nacks($m) := $n
					isConsumedNACK($m) := false
				endpar
			case CHL:
				par
					challenges($m) := $n
					isConsumedCHL($m) := false
				endpar
			case RES:
				par
					ress($m) := $n
					isConsumedRES($m) := false
				endpar
		endswitch
	
	rule r_Broadcast($m in Message) = 
		forall $neighb in Agent with (isLinked(self,$neighb) and self != $neighb) do
			r_Send[$m, $neighb]		
	
	rule r_Buffer($m in Message) =
		receivedReq(self) := append(receivedReq(self), globalId($m))
		
	rule r_GenerateNonce($m in Message) =
		choose $nonce in asSet([1..100]) with true do 
			nonce(self,globalId($m)) := $nonce
		
	rule r_Consume($m in Message) =
		switch messageType($m) 
			case RREP:
				isConsumedRREP($m) := true
			case NACK:
				isConsumedNACK($m) := true
			case CHL:
				isConsumedCHL($m) := true
			case RES:
				isConsumedRES($m) := true
			otherwise
				choose $t in Time with (isConsumed($m,set($t))=false) do
					isConsumed($m,set($t)) := true
		endswitch
	
	rule r_GenerateRouteErr = 
		forall $e in RoutingTable with (owner($e)=self and active($e) and linkBreak(entryNextHop($e)) and not(isEmpty(precursor($e)))) do 
			seq
				active($e) := false
				extend Update with $newupdate do skip
				entry($e) := (entryDest($e), entrySeqNum($e) + 1, entryHopCount($e), entryNextHop($e))
				extend Message with $newrerr do 
					seq
						messageType($newrerr) := RERR
						messageRERR($newrerr) := (entryDest($e),
												entrySeqNum($e),
												self)
						forall $a in asSet(precursor($e)) do
							r_Send[$newrerr, $a]
						precursor($e) := []
					endseq
			endseq
	
	rule r_ReGenerateRouteReq($dest in Agent) =
		waitingForRouteTo(self, $dest) := false
	
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
				if (dest($m) = self) then
					seq
						messageType($newrrep) := RREP
						if (destSeqNum($m) = undef) then								
							messageRREP($newrrep) := (origin($m), 
													0,  
													dest($m), 
													curSeqNum(self),
													self,
													globalId($m))								
						else
							if ((curSeqNum(self) + 1) = destSeqNum($m)) then
								seq
									messageRREP($newrrep) := (origin($m), 
														0,  
														dest($m), 
														curSeqNum(self) + 1,
														self,
														globalId($m))
									curSeqNum(self) := curSeqNum(self) + 1
								endseq
							else
								seq
									messageRREP($newrrep) := (origin($m), 
														0,  
														dest($m), 
														curSeqNum(self),
														self,
														globalId($m))
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
														self,
														globalId($m))							
								r_PrecursorInsertion[sender($m), $fwdEntry] 
							endseq
						endlet	
					endseq					
				endif
				r_Send[$newrrep, sender($m)]
			endseq
			
	rule r_GenerateNack($m in Message) = 
		if (sender($m)!=origin($m)) then
			extend Message with $newnack do
				seq
					messageType($newnack) := NACK
					messageNACK($newnack) := (self, 
											curSeqNum(self) + 1,  
											0, 
											origin($m), 										
											originSeqNum($m),
											self)
					curSeqNum(self) := curSeqNum(self) + 1
					r_Send[$newnack, sender($m)]
				endseq
		endif
		
	rule r_GenerateChl($m in Message) = 
		extend Message with $newchl do 
			seq
				r_GenerateNonce[$m]
				messageType($newchl) := CHL
				messageCHL($newchl) := (dest($m),
										self,
										nonce(self,globalId($m)),
										globalId($m),
										self)
				r_Send[$newchl, sender($m)]
			endseq
	
	rule r_GenerateRes($m in Message) =
		extend Message with $newres do 
			seq
				messageType($newres) := RES
				messageRES($newres) := (origin($m),
										self,
										nonce($m) - 1,
										globalId($m))
				r_Send[$newres, sender($m)]
			endseq		
	
	rule r_PropagateRouteErr = 
		choose $rerr in Message, $t in Time with (errors($rerr,set($t))=self and isConsumed($rerr,set($t))=false) do
			par
				forall $e in RoutingTable with (owner($e)=self and entryDest($e)=dest($rerr) and entryNextHop($e)=sender($rerr)) do
					par
						active($e) := false
						extend Update with $newupdate do skip
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
	
	rule r_PrepareComm = 
		forall $dest in Agent with ($dest != self) do
			choose $wantsToCommunicateWith in Boolean with true do
				if ($wantsToCommunicateWith) then
					par
						extend Trial with $newtrial do skip
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
									waitingTime(self, $dest) := 5
								endpar
							endif
						endif
					endpar
				endif
	
	rule r_UpdateReverseRoute($e in RoutingTable, $m in Message) = 
		par
			extend Update with $newupdate do skip
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
		choose $rreq in Message, $t in Time with (requests($rreq,set($t))=self and isConsumed($rreq,set($t))=false) do
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
							par
								r_ForwardRefreshedReq[$rreq]
								r_GenerateNack[$rreq]
							endpar
						endif	
					endseq
				endif
				r_Consume[$rreq]
			endpar	
	
	rule r_SetPrecursor($m in Message, $e in RoutingTable) =
		if (mustForward($m)) then
			seq
				r_EntryFor[origin($m)]
				r_Insert[entryNextHop(entryFor(self)), precursor($e)]
			endseq
		endif
	
	rule r_UpdateForwardRoute($e in RoutingTable, $m in Message) = 
		par
			extend Update with $newupdate do skip
			switch messageType($m)
				case RREP:
					par
						entry($e) := (dest($m), destSeqNum($m), hopCount($m) + 1, sender($m))
						active($e) := true
						r_SetPrecursor[$m, $e]
					endpar
				case NACK:
					par
						entry($e) := (origin($m), originSeqNum($m), hopCount($m) + 1, sender($m))
						active($e) := true
					endpar
			endswitch
		endpar
	
	rule r_RefreshForwardRoute($m in Message) = 
		switch messageType($m)
			case RREP:
				seq
					r_EntryFor[dest($m)]
					r_UpdateForwardRoute[entryFor(self), $m]
				endseq
			case NACK:
				seq
					r_EntryFor[origin($m)]
					r_UpdateForwardRoute[entryFor(self), $m]
				endseq
		endswitch
					
		
	rule r_ExtendForwardRoute($m in Message) = 
		extend RoutingTable with $newentry do 
			switch messageType($m)
				case RREP:
					seq
						owner($newentry) := self
						entry($newentry) := (dest($m), undef, undef, undef)
						precursor($newentry) := [] 
						r_UpdateForwardRoute[$newentry, $m]
					endseq
				case NACK:
					seq
						owner($newentry) := self
						entry($newentry) := (origin($m), undef, undef, undef)
						precursor($newentry) := [] 
						r_UpdateForwardRoute[$newentry, $m]
					endseq
			endswitch
	
	rule r_BuildForwardRoute($m in Message) = 
		switch messageType($m)
			case RREP:		
				if (thereIsRouteInfoFor(dest($m))) then
					r_RefreshForwardRoute[$m]
				else
					r_ExtendForwardRoute[$m]
				endif
			case NACK:
				if (thereIsRouteInfoFor(origin($m))) then
					r_RefreshForwardRoute[$m]
				else
					r_ExtendForwardRoute[$m]
				endif
		endswitch
	
	rule r_ForwardRefreshedRep($m in Message) =
		 extend Message with $newrrep do 
		 	seq		 
		 		r_EntryFor[dest($m)] 
				if (hasNewForwardRouteInfo($m)) then
					seq
						messageType($newrrep) := RREP
						messageRREP($newrrep) := (origin($m),  
												hopCount($m) + 1, 
												dest($m), 										
												destSeqNum($m),
												self,
												globalId($m))			
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
												self,
												globalId($m))	
						r_EntryFor[origin($m)]				
						r_Send[$newrrep, entryNextHop(entryFor(self))]
					endseq
				endif	
			endseq			
		
	rule r_ProcessRouteRep =
		choose $rrep in Message with (replies($rrep)=self and isConsumedRREP($rrep)=false) do
			par
				if (trusted($rrep) != undef) then
					if (trusted($rrep)) then
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
					endif
				endif
				if (waitingTime($rrep) = undef) then
					par
						waitingTime($rrep) := 0
						r_GenerateChl[$rrep]
					endpar
				else
					if (waitingTime($rrep) < 5) then 
						waitingTime($rrep) := waitingTime($rrep) + 1
					else
						par
							extend Malicious with $newmalicious do 
								interceptedBlackhole($newmalicious, self) := sender($rrep)
							r_Consume[$rrep]
						endpar
					endif
				endif
			endpar
	
	rule r_ProcessRouteErr = 
		choose $c in Boolean with true do 
			if $c then
				r_GenerateRouteErr[]
			else
				r_PropagateRouteErr[] 
			endif
	
	rule r_ForwardRefreshedNack($m in Message) = 
		extend Message with $newnack do
			seq
				messageType($newnack) := NACK
				messageNACK($newnack) := (origin($m), 
										originSeqNum($m),  
										hopCount($m) + 1, 
										dest($m), 										
										destSeqNum($m),
										self)
				r_EntryFor[dest($m)]	
				r_Send[$newnack, entryNextHop(entryFor(self))] 
			endseq
			
	
	rule r_ProcessNack = 
		choose $nack in Message with (nacks($nack)=self and isConsumedNACK($nack)=false) do
			seq
				r_BuildForwardRoute[$nack] 
				if (dest($nack)!=self) then
					r_ForwardRefreshedNack[$nack]
				endif
				r_Consume[$nack]
			endseq	
			
	rule r_ForwardChl($m in Message) = 
		seq
			r_EntryFor[dest($m)]
			r_Send[$m,entryNextHop(entryFor(self))]
		endseq
					
	rule r_ProcessChl = 
		choose $chl in Message with (challenges($chl)=self and isConsumedCHL($chl)=false) do
			seq
				if (dest($chl)=self) then 
					r_GenerateRes[$chl]
				else 
					r_ForwardChl[$chl]
				endif
				r_Consume[$chl]
			endseq
			
	rule r_Verify($m in Message) = 
		choose $rrep in Message with (replies($rrep)=self and globalId($rrep)=globalId($m)) do
			if (nonce(self,globalId($rrep))=nonce($m)-1) then
				trusted($rrep) := true
			else
				trusted($rrep) := false
			endif
	
	rule r_ForwardRes($m in Message) = 
		seq
			r_EntryFor[dest($m)]
			r_Send[$m,entryNextHop(entryFor(self))]
		endseq
		
	rule r_ProcessRes = 
		choose $res in Message with (ress($res)=self and isConsumedRES($res)=false) do 
			seq
				if (dest($res)=self) then 
					r_Verify[$res]
				else 
					r_ForwardRes[$res] 
				endif	
				r_Consume[$res]
			endseq	
	
	rule r_Router = 
		seq
			r_ProcessRouteReq[]
			r_ProcessRouteRep[]
			r_ProcessRouteErr[]
			r_ProcessNack[]
			r_ProcessChl[]
			r_ProcessRes[]
		endseq
	
	rule r_AodvSpec = 
		seq
			choose $c in Boolean with true do 
				if $c then
					r_PrepareComm[]
				endif
				
			r_Router[] 
			
			forall $a in Agent with($a != self and waitingForRouteTo(self,$a) = true) do
				if (waitingTime(self,$a) != undef) then
					if(waitingTime(self,$a) = 0) then
						par
							waitingForRouteTo(self,$a) := false
							extend Trial with $newtrial do skip
						endpar
					else
						waitingTime(self, $a) := waitingTime(self, $a) - 1
					endif	
				endif				
		endseq
	
	rule r_MobilityModel =
		forall $ag1 in Agent do
			forall $ag2 in Agent with($ag1 != $ag2) do
				seq
					choose $val in asSet([1..100]) with true do	
						if($val < 20) then
							par
								if(isLinked($ag1,$ag2) = true) then
									par
										isLinked($ag1,$ag2) := false
										isLinked($ag2,$ag1) := false
									endpar
								endif 
					
								if(isLinked($ag1,$ag2) = false) then
									par
										isLinked($ag1,$ag2) := true
										isLinked($ag2,$ag1) := true	 	
									endpar 
								endif 
							endpar
						endif
					skip
				endseq
	
	rule r_ObserverProgram = 
		seq					
			m_controlOverhead := size(Message) 
			m_interceptedBlackhole := size(Malicious)
			m_maliciousOverhead := size(MaliciousMessage)
			m_rateOfSuccess_r := size(Success)
			m_rateOfSuccess_s := size(Trial)
			m_routingTableSize := size(RoutingTable)
			m_updateRoutingTable := size(Update)
		
			if (isInitialized = undef) then	
				forall $a in Agent do	
					seq 							
						curSeqNum($a) := 0	
						localReqCount($a) := 0
						receivedReq($a) := []
						forall $dest in Agent with($dest != $a) do
							par
								isLinked($a,$dest) := false
								waitingForRouteTo($a,$dest) := false
							endpar
					endseq				
			endif 
			
			if (isInitialized = undef) then
				isInitialized := true	
			endif
			
			r_MobilityModel[] 	
		endseq
		
	rule r_GenerateRouteRep($m in Message) = 
		extend Message with $newrrep do 
			seq
				messageType($newrrep) := RREP
				r_LastKnownDestSeqNum[dest($m)] 
				r_MaxKnownDestSeqNum[destSeqNum($m)] 
				if (lastKnownDestSeqNum(self,dest($m)) != undef) then
					messageRREP($newrrep) := (origin($m), 
											0,  
											dest($m), 
											lastKnownDestSeqNum(self,dest($m)) + 10,
											self,
											globalId($m))	
				else
					messageRREP($newrrep) := (origin($m), 
											0,  
											dest($m), 
											maxKnownDestSeqNum(self),
											self,
											globalId($m))	
				endif
				r_Send[$newrrep, sender($m)]
			endseq
	
	rule r_BlackHoleProgram =
		choose $rreq in Message, $t in Time with (requests($rreq,set($t))=self and isConsumed($rreq,set($t))=false) do
			par
				if (hasNewReverseRouteInfo($rreq)) then
					r_BuildReverseRoute[$rreq]
				endif
				r_GenerateRouteRep[$rreq]
				extend MaliciousMessage with $newrrep do skip 				
				r_Consume[$rreq]
			endpar	
			
	rule r_ForwardRouteRep($m in Message) =
		seq
			r_EntryFor[origin($m)]
			r_Send[$m,entryNextHop(entryFor(self))]
		endseq
	
	rule r_ColluderProgram =
		choose $rrep in Message with (replies($rrep)=self and isConsumedRREP($rrep)=false) do
			par
				if (dest($rrep)!=self) then
					seq
						r_EntryFor[dest($rrep)] 
						if (hasNewForwardRouteInfo($rrep)) then
							r_BuildForwardRoute[$rrep]
						endif
					endseq
				endif
				r_ForwardRouteRep[$rrep] 
				extend MaliciousMessage with $fwdrrep do skip 
				r_Consume[$rrep]
			endpar
		
	main rule r_Main = 
		seq 
			r_ObserverProgram[] 			
			par
				forall $bh in Blackhole do
					program($bh) 
					
				forall $c in Colluder do
					program($c)
					
				forall $a in Host do
					program($a)
			endpar
		endseq

default init s0:	
	agent Blackhole: r_BlackHoleProgram[]
	agent Colluder: r_ColluderProgram[]	
	agent Host: r_AodvSpec[]	 
	
		
