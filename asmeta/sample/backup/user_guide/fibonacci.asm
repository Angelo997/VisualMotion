asm fibonacci
import StandardLibrary
signature:
dynamic monitored size: Integer //number of Fibonacci numbers
dynamic controlled num_fibo: Integer
dynamic controlled index: Integer
dynamic controlled succ_fibo: Seq(Integer)
definitions:
macro rule r_insert_number =
if(num_fibo=2) then
num_fibo := size
endif
macro rule r_fibonacci =
if(index<num_fibo) then
seq
succ_fibo := append(succ_fibo,at(succ_fibo,iton(index-1))+
at(succ_fibo,iton(index-2)))
index := index+1
endseq
endif
main rule r_Main =
seq
r_insert_number[]
r_fibonacci[]
endseq
default init s0:
function succ_fibo = [1, 1]
function index = 2
function num_fibo = 2
