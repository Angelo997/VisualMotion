asm prova
import ../StandardLibrary

// PROVA: controlled non sono mai UNDEF, per cui non serve il costrutto CHOOSE esplicito in modo random!
signature:
	domain Host subsetof Agent
	dynamic monitored m_wishToInitiate: Prod(Agent, Agent) -> Boolean
	dynamic controlled c_wishToInitiate: Prod(Agent, Agent) -> Boolean
	
	dynamic controlled coda: Prod(Agent,Integer) -> Integer
	dynamic controlled print: Agent -> Integer
		
	static host1: Host
	static host2: Host
	static host3: Host
	
definitions:

	rule r_Leggi =
		if (not(exist $t in Integer, $u in Integer with (coda(self,$t) != coda(self,$u) and $t < $u))) then
			print(self) := 3
		endif
	
	rule r_Fsm =
		seq
			forall $f in Agent with ($f != self) do
				par
					let ($c = m_wishToInitiate(self,$f)) in
						c_wishToInitiate(self,$f) := $c
					endlet
					let ($t = currTimeNanosecs) in
						coda($f,$t) := 3
					endlet
				endpar
			r_Leggi[]
		endseq
		
	main rule r_Main =
		forall $asm in Host do
			program($asm) 
			
default init s0:
	// INIZIALIZZAZIONE MULTIPLA
	//function coda($a in Agent) = []
	agent Host: r_Fsm[]	 