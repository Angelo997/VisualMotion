asm prova3
import ../StandardLibrary

signature:
	dynamic abstract domain Message 
	
	dynamic controlled timestamp: Message -> Integer	
	dynamic controlled print: Integer
	dynamic controlled isConsumed: Message -> Boolean
	
definitions:
	
	rule r_Create = skip
	
	rule r_Process =
		choose $msg in Message with(not(exist $msg1 in Message with(timestamp($msg1) < timestamp($msg)))) do 
			seq
				print := timestamp($msg)
				isConsumed($msg) := true
				timestamp($msg) := 999999999999999
			endseq
		ifnone
			print := 0
		
	main rule r_Main =
		seq
			extend Message with $m1 do
				seq
				timestamp($m1) := currTimeNanosecs
				isConsumed($m1) := false
				endseq
			extend Message with $m2 do
				seq
				timestamp($m2) := currTimeNanosecs
				isConsumed($m2) := false
				endseq
			extend Message with $m3 do
				seq
				timestamp($m3) := currTimeNanosecs
				isConsumed($m3) := false
				endseq
			r_Process[] 
		endseq
			
default init s0: