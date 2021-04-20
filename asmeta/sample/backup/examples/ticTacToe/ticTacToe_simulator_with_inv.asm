asm ticTacToe_simulator_with_inv

//for ESF Strategic Workshop on Correct Software in Web Applications - Hagenberg (Austria), 26-28 September 2011

import ../StandardLibrary

signature:
	domain Coord subsetof Integer
	enum domain Sign = {CROSS | NOUGHT}
	enum domain Status = {TURN_USER | TURN_PC}

	controlled board: Prod(Coord, Coord) -> Sign
	controlled status: Status
	monitored userChoiceX: Coord //scelta coordinata x dell'utente
	monitored userChoiceY: Coord //scelta coordinata y dell'utente
	derived winner: Sign -> Boolean
	derived chosenCells: Sign -> Powerset(Prod(Coord, Coord))
	derived endOfGame: Boolean

definitions:
	domain Coord = {1..3}
	
	function chosenCells($s in Sign) =
		{$x in Coord, $y in Coord | board($x, $y) =  $s: ($x, $y)}

	function winner($s in Sign) =
		(exist $r in Coord with (forall $c in Coord with board($r, $c) = $s)) or
		(exist $c2 in Coord with (forall $r2 in Coord with board($r2, $c2) = $s)) or
		(forall $d in Coord with board($d, $d) = $s) or
		(forall $d1 in Coord with board($d1, 3 - $d1) = $s)

	function endOfGame =
		(exist $s in Sign with winner($s)) or
		(forall $x in Coord, $y in Coord with isDef(board($x, $y)))

	rule r_moveUser =
		if(isUndef(board(userChoiceX, userChoiceY))) then
			par
				board(userChoiceX, userChoiceY) := CROSS
				status := TURN_PC
			endpar
		endif

	rule r_movePC =
		par
			choose $x in Coord, $y in Coord with isUndef(board($x, $y)) do
				board($x, $y) :=  NOUGHT
			status := TURN_USER
		endpar

	invariant over board: abs(size(chosenCells(NOUGHT)) - size(chosenCells(CROSS))) <= 1 

	main rule r_Main =
		if(not(endOfGame)) then
			if(status = TURN_USER) then
				r_moveUser[]
			else
				r_movePC[]
			endif
		endif

default init s0:
	function status = TURN_USER