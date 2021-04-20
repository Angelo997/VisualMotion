asm _DOMAIN

import StandardLibrary

signature:
	dynamic abstract domain Dom 
	
	dynamic controlled rMetric: Integer		// run metric
	dynamic controlled sMetric: Integer		// entire simulation metric
	
	static host1: Agent
	static host2: Agent
	
definitions:

	rule r_AgentProgram =
		extend Dom with $newdom do skip
	
	main rule r_Main = 
		seq
			forall $a in Agent do
				program($a) 
			sMetric := size(Dom)
			rMetric := size(Dom) - rMetric
		endseq

default init s0:

	function rMetric = 0

	agent Agent: r_AgentProgram[] 