//Sluice Gate Control
//da articolo "The Abstract State Machines Method for High-Level System Design and Analysis" di Egon Borger
//secondo raffinamento
//con agenti
//funziona solo se gli agenti sono in sequenza
//se gli agenti sono in parallelo viene violato l'invariante

//A small sluice, with a rising and falling gate, is used in a simple
//irrigation system. A computer system is needed to control the sluice
//gate: the requirement is that the gate should be held in the fully open
//position for ten minutes in every three hours and otherwise kept in
//the fully closed position.
//The gate is opened and closed by rotating vertical screws. The screws
//are driven by a small motor, which can be controlled by clockwise,
//anticlockwise, on and off pulses.
asm sluiceGate_with_agents

import ../StandardLibrary

signature:
	domain Minutes subsetof Integer
	abstract domain Position
	enum domain PhaseDomain = { FULLYCLOSED | OPENING | FULLYOPEN | CLOSING }
	enum domain DirectionDomain = { CLOCKWISE | ANTICLOCKWISE }
	enum domain MotorDomain = { MOTORON | MOTOROFF }//per mantenere i termini dell'articolo
	domain PULSESAgent subsetof Agent
	domain SLUICEGATECTLAgent subsetof Agent
	dynamic controlled phase: PhaseDomain
	dynamic controlled dir: DirectionDomain
	dynamic controlled motor: MotorDomain
	static openPeriod: Minutes
	static closedPeriod: Minutes
	static top: Position
	static bottom: Position
	dynamic monitored passed: Minutes -> Boolean
	dynamic monitored event: Position -> Boolean
	
	static pulses: PULSESAgent
	static sluicegatectl: SLUICEGATECTLAgent
	
	//funzioni in overload
	dynamic controlled pulse: DirectionDomain -> Boolean
	dynamic controlled pulse: MotorDomain -> Boolean
	
definitions:
	function openPeriod = 10
	function closedPeriod = 170 //period - (StartToRaiseTime + OpeningTime + StopMotorTime) - (StartToLowerTime + ClosingTime + StopMotorTime)
	
	macro rule r_emit($l in Boolean) =
		$l := true
	
	rule r_start_to_raise =
		par
			r_emit[pulse(CLOCKWISE)]
			r_emit[pulse(MOTORON)]
		endpar
	
	rule r_start_to_lower =
		par
			r_emit[pulse(ANTICLOCKWISE)]
			r_emit[pulse(MOTORON)]
		endpar
		
	rule r_stop_motor =
		r_emit[pulse(MOTOROFF)]
	
	rule r_pulses =
		par
			if(pulse(CLOCKWISE)) then
				par
					dir := CLOCKWISE
					pulse(CLOCKWISE) := false
				endpar
			endif
			if(pulse(ANTICLOCKWISE)) then
				par
					dir := ANTICLOCKWISE
					pulse(ANTICLOCKWISE) := false
				endpar
			endif
			if(pulse(MOTORON)) then
				par
					motor := MOTORON
					pulse(MOTORON) := false
				endpar
			endif
			if(pulse(MOTOROFF)) then
				par
					motor := MOTOROFF
					pulse(MOTOROFF) := false
				endpar
			endif
		endpar

	macro rule r_sluicegate =
		par
			if(phase=FULLYCLOSED) then
				if(passed(closedPeriod)) then
					par
						r_start_to_raise[]
						phase := OPENING
					endpar
				endif
			endif
			if(phase=OPENING) then
				if(event(top)) then
					par
						r_stop_motor[]
						phase := FULLYOPEN
					endpar
				endif
			endif
			if(phase=FULLYOPEN) then
				if(passed(openPeriod)) then
					par
						r_start_to_lower[]
						phase := CLOSING
					endpar
				endif
			endif
			if(phase=CLOSING) then
				if(event(bottom)) then
					par
						r_stop_motor[]
						phase := FULLYCLOSED
					endpar
				endif
			endif
		endpar
		
	invariant over phase:
	((phase=FULLYCLOSED or phase=FULLYOPEN) and motor=MOTOROFF) or
	((phase=OPENING or phase=CLOSING) and motor=MOTORON)
	
	main rule r_Main =
		//par
		seq
			program(sluicegatectl)
			program(pulses)
		endseq
		//endpar
		

default init s0:
	function phase = FULLYCLOSED
	function pulse($d in DirectionDomain) = false
	function pulse($d in MotorDomain) = false
	
	agent SLUICEGATECTLAgent:
		r_sluicegate[]
			
	agent PULSESAgent:
		r_pulses[]