asm recursive_factorial
import StandardLibrary
signature:
dynamic controlled value: Integer
definitions:
turbo rule r_factorial($n in Integer) in Integer =
local x : Integer [ x:=1 ]
if($n=1) then
result := 1
else
seq
x <- r_factorial($n-1)
result := $n*x
endseq
endif
main rule r_Main =
r_factorial(value)
default init s0:
function value = 5