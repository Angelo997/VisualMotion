//One-Way Traffic Light
//da articolo "The Abstract State Machines Method for High-Level System Design and Analysis" di Egon Borger
//modello ground
//molte ripetizioni; i quattro r_switchTo... potrebbero essere sostituiti da una sola regola parametrica
//in questo modo, pero', viene mantenuto il modello dell'articolo
// modello conciso

asm oneWayTrafficLight2

import ../../STDL/StandardLibrary

signature:
	abstract domain LightUnit
	enum domain PhaseDomain = { STOP1STOP2 | GO2STOP1 | STOP2STOP1 | GO1STOP2 }
	dynamic controlled phase: PhaseDomain
	dynamic controlled stopLight: LightUnit -> Boolean
	dynamic controlled goLight: LightUnit -> Boolean
	static timer: PhaseDomain -> Integer
	static lightUnit1: LightUnit
	static lightUnit2: LightUnit
	dynamic monitored passed: Integer -> Boolean

	
definitions:

	function timer($p in PhaseDomain) =	switch($p)
											case STOP1STOP2 : 50
											case GO2STOP1 : 120
											case STOP2STOP1 : 50
											case GO1STOP2 : 120
										endswitch
		
	macro rule r_switch($l in Boolean) = $l := not($l)
	
	macro rule r_switchToGo($i in LightUnit) =
		par
			r_switch[goLight($i)]
			r_switch[stopLight($i)]
		endpar
	
	rule r_switchToStop($i in LightUnit) = r_switchToGo[$i] 

	
	rule r_stop1stop2_to_go2stop1 =
		if(phase=STOP1STOP2) then
			if(passed(timer(STOP1STOP2))) then
				par
					r_switchToGo[lightUnit2]
					phase:=GO2STOP1
				endpar
			endif
		endif
		
	rule r_go2stop1_to_stop2stop1 =
		if(phase=GO2STOP1) then
			if(passed(timer(GO2STOP1))) then
				par
					r_switchToStop[lightUnit2]
					phase:=STOP2STOP1
				endpar
			endif
		endif
	
	rule r_stop2stop1_to_go1stop2 =
		if(phase=STOP2STOP1) then
			if(passed(timer(STOP2STOP1))) then
				par
					r_switchToGo[lightUnit1]
					phase:=GO1STOP2
				endpar
			endif
		endif
		
	rule r_go1stop2_to_stop1stop2 =
		if(phase=GO1STOP2) then
			if(passed(timer(GO1STOP2))) then
				par
					r_switchToStop[lightUnit1]
					phase:=STOP1STOP2
				endpar
			endif
		endif

	
	invariant over goLight, stopLight: 
		(goLight(lightUnit1) and not(stopLight(lightUnit1))) or (not(goLight(lightUnit1)) and stopLight(lightUnit1))
	
		
	main rule r_Main =
		par
			r_stop1stop2_to_go2stop1[]
			r_go2stop1_to_stop2stop1[]
			r_stop2stop1_to_go1stop2[]
			r_go1stop2_to_stop1stop2[]
		endpar
	
		

default init s0:
	function stopLight($l in LightUnit) = true
	function goLight($l in LightUnit) = false
	function phase = STOP1STOP2
