asm sample

import StandardLibrary

signature:
	domain Probability subsetof Integer	

	dynamic controlled lista: Seq(Integer)
		
definitions:
	domain Probability = {1..100}
	
	main rule r_Main =	
		forall $elem in Probability with true do
			lista := append(lista, $elem)

default init s0:				 	
	function lista = []