asm prova4
import ../StandardLibrary

signature:
	dynamic abstract domain Message 
	
	static aSM1: Agent
	static aSM2: Agent	
	static aSM3: Agent
	static aSM4: Agent
	static aSM5: Agent
	
	dynamic controlled timestamp: Message -> Integer	
	dynamic controlled print: Integer
	dynamic controlled isConsumed: Message -> Boolean
	
definitions:			
	
	rule r_Create($timestamp in Integer) =
		choose $msg in Message with(isConsumed($msg) = true) do
			par
				if ($timestamp = 0) then
					timestamp($msg) := currTimeNanosecs
				else
					timestamp($msg) := $timestamp
				endif
				isConsumed($msg) := false
			endpar
		ifnone
			extend Message with $m1 do
				seq
					if ($timestamp = 0) then
						timestamp($m1) := currTimeNanosecs
					else
						timestamp($m1) := $timestamp
					endif
					isConsumed($m1) := false
				endseq
	
	rule r_Broadcast =
		let ($timestamp = currTimeNanosecs) in
			forall $dest in Agent do
				r_Create[$timestamp]
		endlet
	
	rule r_Process =
		choose $msg in Message with(not(exist $msg1 in Message with(timestamp($msg1) < timestamp($msg) and isConsumed($msg) = false and isConsumed($msg1) = false))) do 
			seq
				print := timestamp($msg)
				isConsumed($msg) := true
			endseq
		
	main rule r_Main =	
		seq
			r_Create[0]
			r_Create[0]
			r_Process[]
		endseq
		
default init s0:
		
