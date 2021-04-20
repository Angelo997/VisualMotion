asm factorial
import StandardLibrary
signature:
dynamic monitored value: Integer
dynamic controlled index: Integer
dynamic controlled factorial: Integer
dynamic controlled outMess: Any
derived continue: Integer -> Boolean
definitions:
function continue($i in Integer) =
$i>1
macro rule r_factorial =
if(continue(index)) then
seq
factorial := factorial*index
index := index-1
endseq
endif
main rule r_Main =
seq
if(index=1) then
if(value>0) then
par
index := value
factorial := 1
outMess := "Executing the factorial"
endpar
else
outMess := "Insert a value greater than zero"
endif
endif
r_factorial[]
endseq
default init s0:
function index = 1