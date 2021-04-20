asm PROVA

import StandardLibrary

signature:
	domain Producer subsetof Agent
	
	dynamic controlled contatore: Integer
	dynamic controlled isCompleted: Agent -> Boolean
	dynamic controlled initialized: Boolean
	dynamic controlled print: String
	
	static producer: Producer
	static host1: Agent
	
definitions:	

	rule r_Host = 
		while(isCompleted(self) = false) do
			if (contatore = 0) then
				isCompleted(self) := true
			endif
	
	rule r_Producer = 
		while (contatore > 0) do	
			contatore := contatore - 1				
			

	main rule r_Main = 
		seq
			if (initialized = undef) then
				par
					contatore := 100
					forall $a in Agent do
						isCompleted($a) := false
				endpar
			endif
			par
				program(producer)
				program(host1)
			endpar
		endseq

default init s0:	
	agent Agent: r_Host[]	 
	agent Producer: r_Producer[]	 	
