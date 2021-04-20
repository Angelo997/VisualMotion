asm prova5
import ../StandardLibrary

signature:
	dynamic abstract domain Message 
	
	static aSM1: Agent
	static aSM2: Agent	
	static aSM3: Agent
	static aSM4: Agent
	static aSM5: Agent
	
	dynamic monitored wantsToCommunicate: Prod(Agent,Agent) -> Boolean
	dynamic monitored wantsToBeInitiator: Agent -> Boolean
	dynamic monitored wantsToBeRouter: Agent -> Boolean
	
	dynamic controlled timestamp: Message -> Integer	
	dynamic controlled printMsg: Message -> String
	
	dynamic controlled initiator: Message -> Agent
	dynamic controlled destination: Message -> Agent
	dynamic controlled nextHop: Message -> Agent
	
definitions:			
	
	rule r_Send($msg in Message, $dest in Agent, $nextHop in Agent) =
		seq
			par
				initiator($msg) := self
				destination($msg) := $dest
				nextHop($msg) := $nextHop
				timestamp($msg) := currTimeNanosecs		
			endpar			
			printMsg($msg) := "Message: [initiator=" + toString(self) + ",nextHop=" + toString($nextHop) + ",destination=" + toString($dest) + "]"	
		endseq
	
	rule r_Forward($msg in Message) =
		choose $rand in Agent with($rand != self and $rand != nextHop($msg)) do
			nextHop($msg) := $rand
		
	
	rule r_Broadcast($dest in Agent) =
		forall $neighb in Agent with($neighb != self) do
			extend Message with $msg do
				r_Send[$msg, $dest, $neighb]
	
	rule r_Process =
		choose $msg in Message with(not(exist $msg1 in Message with(nextHop($msg) = self and nextHop($msg1) = self and timestamp($msg1) < timestamp($msg)))) do 
			if (destination($msg) = self) then
				printMsg($msg) := "Message received"
			else
				r_Forward[$msg]
			endif
			
	rule r_AodvSpec =
		par
			if (wantsToBeInitiator(self) = true) then
				forall $dest in Agent with($dest != self) do
					if(wantsToCommunicate(self,$dest)) then
						r_Broadcast[$dest]
					endif
			endif
			if (wantsToBeRouter(self) = true) then
				r_Process[]
			endif
		endpar
		
	main rule r_Main = 
		forall $a in Agent do
			program($a) 

default init s0:		
	agent Agent: r_AodvSpec[]	
		
