asm AODV

import StandardLibrary

signature:
	/*
	* 	Control Overhead
	*/
	dynamic abstract domain Message 
	/*
	* 	Routing Table Size
	*/	
	dynamic abstract domain RoutingTable 
	/*
	* 	Update Routing Table
	*/
	dynamic abstract domain Update
	/*
	*	Rate of Success
	*/
	dynamic abstract domain Success
	dynamic abstract domain Trial
	
	enum domain MessageType = {RREQ | RREP} 
					
	dynamic controlled wishToInitiate: Prod(Agent,Agent) -> Boolean 
	dynamic controlled waiting: Prod(Agent,Agent) -> Boolean
	dynamic controlled sequenceNumber: Agent -> Natural
	dynamic controlled broadcastId: Agent -> Natural	
	dynamic controlled startTime: Prod(Agent,Agent) -> Integer		
	dynamic controlled elapsedTime: Agent -> Integer				
	
	derived betterRoute: Message -> Boolean  
	derived routeFound: Boolean 	
	derived alreadyKnown: Message -> Boolean  
	derived alreadyReceived: Prod(Message,Agent) -> Boolean 	
	derived destSequenceNumber: Agent -> Natural
	derived existNeighbor: Agent -> Boolean																	
	
	dynamic controlled messageType: Message -> MessageType														
	// 	RT entry Structure
	//	1. 	Agent: entryDest
	//	2. 	Natural: entrySeqNum
	//	3.	Natural: entryHopCount
	//	4.	Agent: entryNextHop
	dynamic controlled entry: RoutingTable -> Prod(Agent, Natural, Natural, Agent) 								
	dynamic controlled owner: RoutingTable -> Agent																
	// 	RREQ Structure
	//	1. 	Agent: initiator
	//	2. 	Natural: broadcastid
	//	3.	Natural: initiatorSeqNum
	//	4.	Natural: hopcount
	//	5.	Agent: destination
	//	6.	Natural: destinationSeqNum
	//	7.	Agent: sender 
	dynamic controlled messageRREQ: Message -> Prod(Agent, Natural, Natural, Natural, Agent, Natural, Agent)	
	// 	RREP Structure
	//	1. 	Agent: initiator
	//	2.	Natural: initiatorSeqNum
	//	3.	Natural: hopcount
	//	4.	Agent: destination
	//	5.	Natural: destinationSeqNum
	//	6.	Agent: sender
	dynamic controlled messageRREP: Message -> Prod(Agent, Natural, Natural, Agent, Natural, Agent)				

	dynamic controlled isLinked: Prod(Agent,Agent) -> Boolean
	dynamic controlled isInitialized: Boolean	
	dynamic controlled threshold: Integer	
	dynamic controlled elapsedTime: Integer																
	dynamic controlled max: Message	
	
	// METRICS
	// Rate of Success 
	dynamic controlled rs_r: Integer	
	dynamic controlled rs_s: Integer
	// Control Overhead
	dynamic controlled co: Integer		
	// Routing Table Size
	dynamic controlled rts: Integer	
	// Routing Table Updates
	dynamic controlled rtu: Integer	
	// END METRICS
																				
	static host1: Agent
	static host2: Agent
	static host3: Agent	
	static host4: Agent
	static host5: Agent
	static host6: Agent	
	static host7: Agent
	static host8: Agent
	/*static host9: Agent	
	static host10: Agent
	static host11: Agent
	static host12: Agent	
	static host13: Agent
	static host14: Agent
	static host15: Agent	
	static host16: Agent
	static host17: Agent
	static host18: Agent	
	static host19: Agent
	static host20: Agent
	static host21: Agent
	static host22: Agent
	static host23: Agent
	static host24: Agent
	static host25: Agent
	static host26: Agent
	static host27: Agent
	static host28: Agent
	static host29: Agent
	static host30: Agent*/
	dynamic controlled requests: Agent -> Seq(Message)
	dynamic controlled replies: Agent -> Seq(Message)
		
	derived top: Seq(Message) -> Message 	
	
	derived initiator: Message -> Agent	
	derived initiatorSeqNum: Message -> Natural	
	derived hopcount: Message -> Natural
	derived destination: Message -> Agent	
	derived destinationSeqNum: Message -> Natural
	derived sender: Message -> Agent	
	derived broadcastid: Message -> Natural		
	
	derived entryDest: RoutingTable -> Agent
	derived entrySeqNum: RoutingTable -> Natural
	derived entryHopCount: RoutingTable -> Natural
	derived entryNextHop: RoutingTable -> Agent						
	
definitions:
	
	function initiator($m in Message) =
		switch messageType($m)
			case RREQ: first(messageRREQ($m))
			case RREP: first(messageRREP($m))
		endswitch
	
	function initiatorSeqNum($m in Message) =
		switch messageType($m)
			case RREQ: third(messageRREQ($m))
			case RREP: second(messageRREP($m))
		endswitch
	
	function hopcount($m in Message) =
		switch messageType($m)
			case RREQ: fourth(messageRREQ($m))
			case RREP: third(messageRREP($m))
		endswitch
		
	function destination($m in Message) =
		switch messageType($m)
			case RREQ: fifth(messageRREQ($m))
			case RREP: fourth(messageRREP($m))
		endswitch
	
	function destinationSeqNum($m in Message) =
		switch messageType($m)
			case RREQ: sixth(messageRREQ($m))
			case RREP: fifth(messageRREP($m))
		endswitch
	
	function sender($m in Message) =
		switch messageType($m)
			case RREQ: seventh(messageRREQ($m))
			case RREP: sixth(messageRREP($m))
		endswitch
		
	function broadcastid($m in Message) = second(messageRREQ($m))
		
	
	function entryDest($e in RoutingTable) = first(entry($e))	
	function entrySeqNum($e in RoutingTable) = second(entry($e))
	function entryHopCount($e in RoutingTable) = third(entry($e))
	function entryNextHop($e in RoutingTable) = fourth(entry($e))
	
	
	function top($m in Seq(Message)) = first($m)
	
	function betterRoute($rr in Message) =
		(exist $r in RoutingTable with (owner($r)=self and entryDest($r)=destination($rr) and entrySeqNum($r)>=destinationSeqNum($rr))) 
		
	function routeFound =
		(exist $rrep in asSet(replies(self)) with(initiator($rrep)=self)) 
	
	function alreadyKnown($m in Message) = 
		switch messageType($m)
			case RREQ: (exist $r1 in RoutingTable with (owner($r1)=self) and messageType($m)=RREQ and entryDest($r1)=initiator($m)) 
			case RREP: (exist $r2 in RoutingTable with (owner($r2)=self) and messageType($m)=RREP and entryDest($r2)=initiator($m)) 
		endswitch
	
	function alreadyReceived($m in Message, $a in Agent) =
		(exist $q in asSet(requests($a)) with (initiator($m) = initiator($q) and broadcastid($m) = broadcastid($q))) 
		
	function destSequenceNumber($a in Agent) =
		if(exist $r in RoutingTable with (owner($r)=self and entryDest($r)=$a)) then
			entrySeqNum($r) 
		endif
		
	function existNeighbor($a in Agent) = 
		(exist $ag in Agent with((isLinked(self,$ag) = true) and self != $ag and $ag = $a))



	rule r_enqueue($m in Message, $a in Agent) = 
		switch messageType($m) 
			case RREQ: requests($a) := append(requests($a),$m)
			case RREP: replies($a) := append(replies($a),$m) 
		endswitch
	
	rule r_dequeue($m in Message) = 
		switch messageType($m) 
			case RREQ: requests(self) := excluding(requests(self),$m) 
			case RREP: replies(self) := excluding(replies(self),$m)    
		endswitch
		
	rule r_maxDestSequenceNumber = 																	
		local max_value : Natural [ max_value:=0n ]
			seq
				forall $rrep in asSet(replies(self)) do 
					forall $rr in asSet(replies(self)) with($rr != $rrep) do 
						if(destinationSeqNum($rr) > destinationSeqNum($rrep)) then
							max_value := destinationSeqNum($rr) 
						endif
				
				choose $r in asSet(replies(self)) with(destinationSeqNum($r)=max_value) do
					max := $r 
			endseq
			
			
	rule r_communicationSession($dest in Agent) = 
		/*
		*	Rate of Success
		*/
		extend Success with $new do skip		
		
		
	// UPDATE ROUTING TABLE SUBMACHINE
	rule r_UpdateRoutingTable($m in Message) = 
		par 
			if(messageType($m) = RREQ) then
				par 
					if alreadyKnown($m) then 
						choose $e in RoutingTable with ((owner($e)=self) and entryDest($e)=initiator($m)) do
							par
								if (initiatorSeqNum($m) > entrySeqNum($e)) then 
									par	
										/*
										*	Routing Table Updates
										*/
										extend Update with $rrequpdate do skip
										entry($e) := (initiator($m), 
													initiatorSeqNum($m), 
													hopcount($m), 
													sender($m)) 
									endpar
								endif
								
								if (initiatorSeqNum($m) = entrySeqNum($e)) then 
									if (hopcount($m) < entryHopCount($e)) then
										par	
											/*
											*	Routing Table Updates
											*/
											extend Update with $newrrequpdate do skip
											entry($e) := (initiator($m), 
														initiatorSeqNum($m), 
														hopcount($m), 
														sender($m)) 
										endpar
									endif
								endif
							endpar
					endif
					
					if not alreadyKnown($m) then
						extend RoutingTable with $newentry do 
							par
								owner($newentry) := self
								entry($newentry) := (initiator($m), 
													initiatorSeqNum($m), 
													hopcount($m), 
													sender($m)) 
							endpar
					endif
				endpar
			endif
			
			if(messageType($m) = RREP) then
				par 
					if alreadyKnown($m) then 
						choose $en in RoutingTable with ((owner($en)=self) and entryDest($en)=destination($m)) do
							par
								if (destinationSeqNum($m) > entrySeqNum($en)) then 
									par
										/*
										*	Routing Table Updates
										*/
										extend Update with $rrepupdate do skip
										entry($en) := (destination($m), 
													destinationSeqNum($m), 
													hopcount($m), 
													sender($m)) 
									endpar
								endif
								
								if (destinationSeqNum($m) = entrySeqNum($en)) then 
									if (hopcount($m) < entryHopCount($en)) then
										par
										/*
										*	Routing Table Updates
										*/
										extend Update with $newrrepupdate do skip
										entry($en) := (destination($m), 
													destinationSeqNum($m), 
													hopcount($m), 
													sender($m)) 
										endpar
									endif
								endif
							endpar
					endif
					
					if not alreadyKnown($m) then
						extend RoutingTable with $newrrepentry do 
							par
								owner($newrrepentry) := self
								entry($newrrepentry) := (destination($m), 
														destinationSeqNum($m), 
														hopcount($m), 
														sender($m)) 
							endpar
					endif
				endpar
			endif			
		endpar	 
	
	// BROADCAST RREQ SUBMACHINE					
	rule r_BroadcastRREQ($rreq in Message) = 
		forall $n in Agent with((isLinked(self,$n) = true) and self != $n)  do
			if not alreadyReceived($rreq,$n) then
				par
					r_enqueue[$rreq,$n] 
					/*
					* 	controlOverhead
					*/
					extend Message with $new do skip
				endpar
			endif			
		
	// ROUTER SUBMACHINE							 
	rule r_Router($rreq in Message, $previousHop in Agent) = 
		par
			if existNeighbor(destination($rreq)) then
				extend Message with $newrrep do  
					seq
						messageType($newrrep) := RREP
						messageRREP($newrrep) := (initiator($rreq), 
												initiatorSeqNum($rreq), 
												hopcount($rreq), 
												destination($rreq), 
												destinationSeqNum($rreq), 
												self)
						r_enqueue[$newrrep,$previousHop] 
					endseq
			endif
			
			if ((not existNeighbor(destination($rreq))) and betterRoute($rreq)) then 
				extend Message with $newnewrrep do  
					seq
						messageType($newnewrrep) := RREP
						messageRREP($newnewrrep) := (initiator($rreq), 
													initiatorSeqNum($rreq), 
													hopcount($rreq), 
													destination($rreq), 
													destinationSeqNum($rreq), 
													self)
						r_enqueue[$newnewrrep,$previousHop] 
					endseq
			endif
			
			if ((not existNeighbor(destination($rreq))) and (not betterRoute($rreq))) then
				seq
					messageRREQ($rreq) := (initiator($rreq), 
										broadcastid($rreq), 
										initiatorSeqNum($rreq), 
										hopcount($rreq)+1n, 
										destination($rreq), 
										destinationSeqNum($rreq), 
										self) 		
					r_BroadcastRREQ[$rreq] 
				endseq
			endif		
		endpar
	
	// INITIATOR SUBMACHINE
	rule r_Initiator($dest in Agent) = 
		par
			if (not(waiting(self,$dest)) and (existNeighbor($dest)) or (exist $e in RoutingTable with (owner($e)=self and entryDest($e)=$dest))) then
				par
					r_communicationSession[$dest] 
					wishToInitiate(self,$dest) := false 
				endpar 
			endif
			
			if (not(waiting(self,$dest)) and (not (existNeighbor($dest))) and (not (exist $ne in RoutingTable with (owner($ne)=self and entryDest($ne)=$dest)))) then
				par
					seq
						sequenceNumber(self) := sequenceNumber(self) + 1n
						broadcastId(self) := broadcastId(self) + 1n
						extend Message with $newrreq do 
							seq
								messageType($newrreq) := RREQ
								messageRREQ($newrreq) := (self, 
														broadcastId(self), 
														sequenceNumber(self), 
														0n, 
														$dest, 
														destSequenceNumber($dest), 
														self) 
								r_BroadcastRREQ[$newrreq]
							endseq						 
					endseq
					
					waiting(self,$dest) := true					
					startTime(self, $dest) := currTimeMillisecs		
				endpar
			endif
			
			if (waiting(self,$dest) and (routeFound)) then
				seq
					r_maxDestSequenceNumber[] 					
					let($rrep = max) in 								
						par
							r_UpdateRoutingTable[$rrep]										
							r_communicationSession[$dest] 										
							wishToInitiate(self,$dest) := false 										
							waiting(self,$dest) := false 									
							forall $rr in asSet(replies(self)) with(destination($rr) = self) do
								r_dequeue[$rr] 									 
						endpar								
					endlet 
				endseq
			endif
			
			if (waiting(self,$dest)) then
				if (currTimeMillisecs - startTime(self, $dest) > elapsedTime) then  	
					par
						wishToInitiate(self,$dest) := false
						waiting(self,$dest) := false 
					endpar
				endif
			endif			
		endpar
			
	// HOST PROGRAM	
	rule r_HostProgram = 
		par
			if not isEmpty(requests(self)) then 
				let($rreq = top(requests(self)), $previousHop = sender($rreq)) in 
					par
						r_UpdateRoutingTable[$rreq] 
						r_Router[$rreq,$previousHop] 
						r_dequeue[$rreq] 
					endpar						
				endlet
			endif
			
			forall $dest in Agent with($dest != self) do
				if(wishToInitiate(self,$dest)) then 
					par
						r_Initiator[$dest] 						
						/*
						*	Rate of Success
						*/
						extend Trial with $new do skip
					endpar
				endif
		
			if not isEmpty(replies(self)) then
				let($rrep = top(replies(self))) in
					if(initiator($rrep) != self) then 
						choose $e in RoutingTable with(owner($e)=self and entryDest($e)=initiator($rrep)) do
							par
								seq
									$previousHop := entryNextHop($e) 
									r_enqueue[$rrep,$previousHop] 	
								endseq	
								r_UpdateRoutingTable[$rrep] 
								r_dequeue[$rrep] 							
							endpar
					endif
				endlet
			endif
		endpar			
	
	
	rule r_MobilityModel =
		forall $ag1 in Agent do
				forall $ag2 in Agent with($ag1 != $ag2) do
					seq
						choose $val in asSet([1..100]) with true do	
								if($val < threshold) then
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
			// metrics process
			rs_r := size(Success) - rs_r
			rs_s := size(Trial) - rs_s			
			co := size(Message) - co						
			rts := size(RoutingTable)			
			rtu := size(Update) - rtu
			// end metrics process
			
			if(isInitialized = undef) then	
				forall $a in Agent do	
					seq 	
						requests($a) := []
						replies($a) := []										
						sequenceNumber($a) := 0n
						broadcastId($a) := 0n						
						
						forall $dest in Agent with($dest != $a) do
							seq
								waiting($a,$dest) := false
								isLinked($a,$dest) := false
							endseq
					endseq				
			endif 
			
			if(isInitialized = undef) then
				isInitialized := true	
			endif
			
			forall $ag1 in Agent do
				forall $ag2 in Agent with($ag2 != $ag1) do
					choose $val in Boolean with true do
						wishToInitiate($ag1,$ag2) := $val 
			
			r_MobilityModel[] 	
		endseq
	
	main rule r_Main = 
		seq 
			r_ObserverProgram[] 
			
			forall $a in Agent do
				program($a) 
		endseq

default init s0:	
	function threshold = 0
	function elapsedTime = 0
	// metrics init
	function rs_r = 0
	function rs_s = 0
	function co = 0	
	function rtu = 0
	// end metrics init
	
	agent Agent: r_HostProgram[]	 	