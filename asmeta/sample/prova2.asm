asm prova2
import ../StandardLibrary

// PROVA: controlled non sono mai UNDEF, per cui non serve il costrutto CHOOSE esplicito in modo random!
signature:
	domain Host subsetof Agent
	
	dynamic controlled coda: Prod(Agent,Agent) -> Seq(Prod(Agent,Integer))
	dynamic controlled print: Agent -> Integer
	
	dynamic controlled isInitialized: Agent -> Boolean
		
	static host1: Host
	static host2: Host
	static host3: Host
	
definitions:	
	rule r_Process =
		if(exist $p in asSet(coda(self,self)) with (second(first($p)) > 0)) then
			skip
		endif
	
	rule r_Broadcast =
		if (isInitialized(self) = false) then
			par
				let ($timestamp = currTimeNanosecs) in
					forall $a in Agent with ($a != self) do
						coda(self, $a) := append(coda(self, $a),($a,$timestamp))
				endlet
				isInitialized(self) := true
			endpar
		endif
		
	main rule r_Main =
		forall $asm in Host do
			program($asm) 
			
default init s0:
	function coda($self in Agent, $dest in Agent) = []	
	function isInitialized($a in Agent) = false
	
	agent Host: r_Broadcast[]	 