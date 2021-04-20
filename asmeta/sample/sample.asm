asm sample

import ../StandardLibrary

signature:
	domain Probability subsetof Integer	
	static aSM1: Agent
	static aSM2: Agent	
	static aSM3: Agent
	static aSM4: Agent
	static aSM5: Agent
	dynamic controlled counter: Agent -> Integer
	dynamic controlled isRunInitialized: Boolean
		
definitions:
	domain Probability = {1..100}
	
	rule r_ASM =		
		choose $c in Probability with true do	
			if ($c < 50 and counter(self) < 3) then
				counter(self) := counter(self) + 1	
			endif	
	
	rule r_Initializer =
		if (isRunInitialized = false) then
			par
				//BEGIN_INITIALIZER
				counter(aSM1) := 0
				counter(aSM2) := 0
				counter(aSM3) := 0
				counter(aSM4) := 0
				counter(aSM5) := 0
				//END_INITIALIZER	
				isRunInitialized := true
			endpar
		endif
	
	main rule r_Main =	
		seq
			r_Initializer[]
			forall $asm in Agent do
				program($asm) 
		endseq

default init s0:			
	function isRunInitialized = false
	agent Agent: r_ASM[]			 	
	
