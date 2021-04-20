asm AODV__10_01_2018

import StandardLibrary

signature:
	dynamic abstract domain Message 	
	dynamic abstract domain RoutingTable 
	enum domain MessageType = {RREQ | RREP | RERR} 
						
	dynamic controlled active: RoutingTable -> Boolean 		
	dynamic controlled curSeqNum: Agent -> Integer  
	dynamic controlled entry: RoutingTable -> Prod(Agent, Integer, Integer, Agent) 
	dynamic controlled errors: Agent -> Seq(Message)
	dynamic controlled isLinked: Prod(Agent, Agent) -> Boolean
	dynamic controlled isInitialized: Boolean
	dynamic controlled localReqCount: Agent -> Integer
	dynamic controlled messageRERR: Message -> Prod(Agent, Integer, Agent)	
	dynamic controlled messageRREP: Message -> Prod(Agent, Integer, Agent, Integer, Agent)	
	dynamic controlled messageRREQ: Message -> Prod(Agent, Integer, Integer, Agent, Integer, Integer, Agent)
	dynamic controlled messageType: Message -> MessageType								
	dynamic controlled owner: RoutingTable -> Agent	
	dynamic controlled precursor: RoutingTable -> Seq(Agent)
	dynamic controlled receivedReq: Agent -> Seq(Prod(Integer, Agent))	
	dynamic controlled replies: Agent -> Seq(Message)		
	dynamic controlled requests: Agent -> Seq(Message)			
	dynamic controlled waitingForRouteTo: Prod(Agent, Agent) -> Boolean 	
	
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
	derived entryFor: Agent -> RoutingTable
	derived foundValidPathFor: Message -> Boolean
	derived globalId: Message -> Prod(Integer, Agent)
	derived hasNewForwardRouteInfo: Message -> Boolean
	derived hasNewDestInfo: Message -> Boolean
	derived hasNewOriginInfo: Message -> Boolean
	derived hasNewReverseRouteInfo: Message -> Boolean		
	derived knowsActiveRouteTo: Agent -> Boolean 
	derived knowsFreshEnoughRouteFor: Message -> Boolean
	derived lastKnownDestSeqNum: Agent -> Integer
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
	function entrySeqNum($e in RoutingTable) = second(entry($e))
	function entryHopCount($e in RoutingTable) = third(entry($e))
	function entryNextHop($e in RoutingTable) = fourth(entry($e))
		
	function knowsActiveRouteTo($dest in Agent) = 
		(exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest and active($e)))
		
	function alreadyReceivedBefore($m in Message) =
		(exist $r in asSet(receivedReq(self)) with ($r = globalId($m)))
		
	function entryFor($dest in Agent) =
		if (exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest)) then
			$e
		else
			undef
		endif
		
	function globalId($m in Message) =
		(localId($m), origin($m))
	
	function hasNewDestInfo($m in Message) =
		if (destSeqNum($m) > entrySeqNum(entryFor(dest($m))) or (destSeqNum($m) = entrySeqNum(entryFor(dest($m))) and (hopCount($m) + 1) < entryHopCount(entryFor(dest($m)))) or (destSeqNum($m) = entrySeqNum(entryFor(dest($m))) and active(entryFor(dest($m))) = false)) then
			true
		else
			false
		endif
	
	// modificato
	function hasNewOriginInfo($m in Message) =
		if (entryFor(origin($m)) = undef) then
			true
		else
			if (originSeqNum($m) > entrySeqNum(entryFor(origin($m)))) then
				true
			else
				false
			endif	
		endif	
		
	function knowsFreshEnoughRouteFor($m in Message) =
		(exist $e in RoutingTable with (owner($e)=self and entryDest($e)=dest($m) and validDestSeqNum($e) and entrySeqNum($e) >= destSeqNum($m) and active($e)))
		
	function foundValidPathFor($m in Message) =
		if (dest($m)=self or knowsFreshEnoughRouteFor($m)) then
			true
		else 
			false
		endif
		
	function lastKnownDestSeqNum($dest in Agent) =
		if (exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest and entrySeqNum($e)!=undef)) then
			entrySeqNum($e)
		else
			undef
		endif
		
	function linkBreak($a in Agent) =
		if (not(isLinked(self, $a))) then
			true
		else
			false
		endif
		
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
					
	rule r_StartCommunicationWith($dest in Agent) = skip	
	
	rule r_Insert($globalId in Prod(Integer, Agent)) = 
		receivedReq(self) := append(receivedReq(self), $globalId)
		
	rule r_Insert($n in Agent, $precursor in Seq(Agent)) = 
		$precursor := append($precursor, $n)
	
	rule r_Send($m in Message, $n in Agent) = 		
		switch messageType($m) 
			case RREQ: requests($n) := append(requests($n), $m)
			case RREP: replies($n) := append(replies($n), $m)  
			case RERR: errors($n) := append(errors($n), $m)   
		endswitch
	
	rule r_Broadcast($m in Message) = 
		forall $neighb in Agent with (isLinked(self,$neighb) and self != $neighb) do
			r_Send[$m, $neighb]		
	
	rule r_Buffer($m in Message) = 
		receivedReq(self) := append(receivedReq(self), globalId($m))
		
	rule r_Consume($m in Message) =
		switch messageType($m) 
			case RREQ: requests(self) := excluding(requests(self),$m) 
			case RREP: replies(self) := excluding(replies(self),$m)  
			case RERR: errors(self) := excluding(errors(self),$m)   
		endswitch
	
	// da modificare
	rule r_GenerateRouteErr = 
		forall $e in RoutingTable with (owner($e)=self and active($e) and linkBreak(entryNextHop($e)) and not(isEmpty(precursor($e)))) do
			seq
				active($e) := false
				entry($e) := (entryDest($e), entrySeqNum($e) + 1, entryHopCount($e), entryNextHop($e))
				extend Message with $newrerr do 
					seq
						messageType($newrerr) := RERR
						messageRERR($newrerr) := (entryDest($e),
												entrySeqNum($e) + 1,
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
				messageType($newrreq) := RREQ
				messageRREQ($newrreq) := (self, 
										curSeqNum(self) + 1,  
										0, 
										$dest, 										
										lastKnownDestSeqNum($dest),
										localReqCount(self) + 1,
										self)
				curSeqNum(self) := curSeqNum(self) + 1
				localReqCount(self) := localReqCount(self) + 1
				r_Broadcast[$newrreq]
				r_Buffer[$newrreq]
			endseq
			
	rule r_PrecursorInsertion($a in Agent, $e in RoutingTable) = 
		r_Insert[$a, precursor($e)]
	
	// modificato
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
					let ($fwdEntry = entryFor(dest($m))) in
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
				endif
				r_Send[$newrrep, sender($m)]
			endseq
	
	// modificato
	rule r_PropagateRouteErr = 
		if not(isEmpty(errors(self))) then 
			let($rerr = first(errors(self))) in 
				par
					forall $e in RoutingTable with (owner($e)=self and entryDest($e)=dest($rerr) and entryNextHop($e)=sender($rerr)) do
						par
							active(entryFor(entryDest($e))) := false
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
			endlet
		endif
	
	// modificato
	rule r_PrepareComm = 
		choose $dest in Agent with ($dest != self) do
			choose $wantsToCommunicateWith in Boolean with true do
				if ($wantsToCommunicateWith) then
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
							endpar
						endif
					endif
				endif
	
	rule r_UpdateReverseRoute($e in RoutingTable, $m in Message) = 
		par
			entry($e) := (entryDest($e), originSeqNum($m), hopCount($m) + 1, sender($m))
			active($e) := true
		endpar
	
	rule r_ExtendReverseRoute($m in Message) = 
		extend RoutingTable with $newentry do 
			seq
				owner($newentry) := self
				entry($newentry) := (origin($m), undef, undef, undef) 
				r_UpdateReverseRoute[$newentry, $m]
			endseq
	
	rule r_RefreshReverseRoute($m in Message) = 
		r_UpdateReverseRoute[entryFor(origin($m)),$m]
				
	rule r_BuildReverseRoute($m in Message) = 
		if (thereIsRouteInfoFor(origin($m))) then
			r_RefreshReverseRoute[$m]
		else
			r_ExtendReverseRoute[$m]
		endif
		
	rule r_ForwardRefreshedReq($m in Message) = 
		extend Message with $newrreq do 
			seq
				messageType($newrreq) := RREQ
				if (destSeqNum($m) != undef and lastKnownDestSeqNum(dest($m)) != undef) then
					messageRREQ($newrreq) := (origin($m), 
											originSeqNum($m),  
											hopCount($m) + 1, 
											dest($m), 										
											max(destSeqNum($m), lastKnownDestSeqNum(dest($m))),
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
						if (lastKnownDestSeqNum(dest($m)) != undef) then
							messageRREQ($newrreq) := (origin($m), 
												originSeqNum($m),  
												hopCount($m) + 1, 
												dest($m), 										
												lastKnownDestSeqNum(dest($m)),
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
		if not(isEmpty(requests(self))) then 
			let($rreq = first(requests(self))) in
				par
					if not(alreadyReceivedBefore($rreq)) then
						par
							r_Insert[globalId($rreq)]
							if (hasNewReverseRouteInfo($rreq)) then
								r_BuildReverseRoute[$rreq]
							endif
							if (foundValidPathFor($rreq)) then
								r_GenerateRouteReply[$rreq]
							else
								r_ForwardRefreshedReq[$rreq]
							endif	
						endpar
					endif
					r_Consume[$rreq]
				endpar
			endlet
		endif		
	
	rule r_SetPrecursor($m in Message, $e in RoutingTable) =
		if (mustForward($m)) then
			r_Insert[entryNextHop(entryFor(origin($m))), precursor($e)]
		endif
	
	rule r_UpdateForwardRoute($e in RoutingTable, $m in Message) = 
		par
			entry($e) := (dest($m), destSeqNum($m), hopCount($m) + 1, sender($m))
			active($e) := true
			r_SetPrecursor[$m, $e]
		endpar
	
	rule r_RefreshForwardRoute($m in Message) = 
		r_UpdateForwardRoute[entryFor(dest($m)), $m]
		
	rule r_ExtendForwardRoute($m in Message) = 
		extend RoutingTable with $newentry do 
			seq
				owner($newentry) := self
				entry($newentry) := (dest($m), undef, undef, undef) 
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
			if (hasNewForwardRouteInfo($m)) then
				seq
					messageType($newrrep) := RREP
					messageRREP($newrrep) := (origin($m),  
											hopCount($m) + 1, 
											dest($m), 										
											destSeqNum($m),
											self)				
					r_Send[$newrrep, entryNextHop(entryFor(origin($m)))]
				endseq
			else
				seq
					messageType($newrrep) := RREP
					messageRREP($newrrep) := (origin($m),  
											entryHopCount(entryFor(dest($m))), 
											dest($m), 										
											destSeqNum($m),
											self)				
					r_Send[$newrrep, entryNextHop(entryFor(origin($m)))]
				endseq
			endif				
	
	// modificato	
	rule r_ProcessRouteRep =
		if not(isEmpty(replies(self))) then 
			let($rrep = first(replies(self))) in
				par
					if (dest($rrep) != self) then
						par
							if (hasNewForwardRouteInfo($rrep)) then
								r_BuildForwardRoute[$rrep]
							endif
							if (mustForward($rrep)) then
								r_ForwardRefreshedRep[$rrep]
							endif
						endpar
					endif
					r_Consume[$rrep]
				endpar
			endlet
		endif						
	
	rule r_ProcessRouteErr = 
		choose $c in Boolean with true do 
			if $c then
				r_GenerateRouteErr[]
			else
				r_PropagateRouteErr[] 
			endif
	
	rule r_Router = 
		choose $c in asSet([1..3]) with true do 
			switch($c) 
				case 1: r_ProcessRouteReq[]
				case 2: r_ProcessRouteRep[]
				case 3: r_ProcessRouteErr[]
			endswitch
	
	rule r_AodvSpec = 
		choose $c in Boolean with true do 
			if $c then
				r_PrepareComm[]
			else
				r_Router[] 
			endif
	
	rule r_MobilityModel =
		forall $ag1 in Agent do
			forall $ag2 in Agent with($ag1 != $ag2) do
				seq
					choose $val in asSet([1..100]) with true do	
						if($val < 5) then
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
			if (isInitialized = undef) then	
				forall $a in Agent do	
					seq 							
						curSeqNum($a) := 0	
						errors($a) := []
						localReqCount($a) := 0
						receivedReq($a) := []
						replies($a) := []	
						requests($a) := []					
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
	
	main rule r_Main = 
		seq 
			r_ObserverProgram[] 
			
			forall $a in Agent do
				program($a) 
		endseq

default init s0:		
	agent Agent: r_AodvSpec[]	 	