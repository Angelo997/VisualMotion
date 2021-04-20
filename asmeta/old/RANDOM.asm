asm RANDOM

import StandardLibrary

signature:
					
	dynamic controlled wishToInitiate: Prod(Agent,Agent) -> Boolean 
																					
	static host1: Agent
	static host2: Agent
	static host3: Agent	
	static host4: Agent
	static host5: Agent
	static host6: Agent	
	static host7: Agent
	static host8: Agent
						
	
definitions:
	
	rule r_ObserverProgram = 
		forall $ag1 in Agent do
			forall $ag2 in Agent with($ag2 != $ag1) do
				choose $val in Boolean with true do
					wishToInitiate($ag1,$ag2) := $val 
	
	main rule r_Main = 
			r_ObserverProgram[] 

default init s0:	
