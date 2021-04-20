asm philosophers
import StandardLibrary
signature:
domain Philosophers subsetof Agent
abstract domain Fork
monitored hungry : Philosophers -> Boolean
controlled eating : Philosophers -> Boolean
static right_fork : Philosophers -> Fork
static left_fork : Philosophers -> Fork
controlled owner : Fork -> Philosophers
static phil_1: Philosophers
static phil_2: Philosophers
static phil_3: Philosophers
static phil_4: Philosophers
static phil_5: Philosophers
static fork_1: Fork
static fork_2: Fork
static fork_3: Fork
static fork_4: Fork
static fork_5: Fork
definitions:
function right_fork($a in Philosophers) =
if $a = phil_1 then fork_2
else if $a = phil_2 then fork_3
else if $a = phil_3 then fork_4
else if $a = phil_4 then fork_5
else if $a = phil_5 then fork_1
endif endif endif endif endif
function left_fork($a in Philosophers) =
if $a = phil_1 then fork_1
else if $a = phil_2 then fork_2
else if $a = phil_3 then fork_3
else if $a = phil_4 then fork_4
else if $a = phil_5 then fork_5
endif endif endif endif endif
macro rule r_Eat =
if (hungry(self)) then
if ( isUndef(owner(left_fork(self))) and
isUndef(owner(right_fork(self))) ) then
par
owner(left_fork(self)) := self
owner(right_fork(self)) := self
eating(self) := true
endpar
endif
endif
macro rule r_Think =
if ( not hungry(self)) then
if (eating(self) and owner(left_fork(self)) = self and
owner(right_fork(self)) = self )then
par
owner(left_fork(self)) := undef
owner(right_fork(self)) := undef
eating(self) := false
endpar
endif
endif
main rule r_choose_philo =
forall $p in Philosophers with true do program($p)
default init initial_state:
function eating ($p in Philosophers)= false
function owner ($f in Fork) = undef
agent Philosophers :
par
r_Eat[]
r_Think[]
endpar
