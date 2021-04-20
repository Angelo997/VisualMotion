asm ATM
import StandardLibrary
signature:
abstract domain NumCard
enum domain State = { AWAITCARD | AWAITPIN | CHOOSE | OUTOFSERVICE |
CHOOSEAMOUNT | STANDARDAMOUNTSELECTION | OTHERAMOUNTSELECTION}
domain MoneySize subsetof Integer //tagli selezionabili
enum domain Service = {BALANCE | WITHDRAWAL | EXIT}
enum domain MoneySizeSelection = {STANDARD | OTHER}
dynamic controlled currCard: NumCard
dynamic controlled atmState: State
dynamic controlled outMess: Any
static pin: NumCard -> Integer
dynamic controlled accessible: NumCard -> Boolean
dynamic controlled moneyLeft: Integer
dynamic controlled balance: NumCard -> Integer
dynamic controlled numOfBalanceChecks: Integer
dynamic monitored insertedCard: NumCard
dynamic monitored insertedPin: Integer
dynamic monitored selectedService: Service
dynamic monitored insertMoneySizeStandard: MoneySize
dynamic monitored insertMoneySizeOther: Integer
dynamic monitored standardOrOther: MoneySizeSelection
derived allowed: Prod(NumCard, Integer) -> Boolean
static card1: NumCard
static card2: NumCard
static card3: NumCard
static minMoney: Integer
static maxPrelievo: Integer
definitions:
domain MoneySize = {10, 20, 40, 50, 100, 150, 200}
function minMoney = 200
function maxPrelievo = 1000
function pin($c in NumCard) =
switch($c)
case card1 : 1
case card2 : 2
case card3 : 3
endswitch
function allowed($c in NumCard, $m in Integer) =
balance($c) >= $m
macro rule r_subtractFrom ($c in NumCard, $m in Integer) =
balance($c) := balance($c) - $m
macro rule r_goOutOfService =
par
atmState := OUTOFSERVICE
outMess := "Out of Service"
endpar
macro rule r_insertcard =
if(atmState=AWAITCARD) then
if(exist $c in NumCard with $c=insertedCard) then
par
currCard := insertedCard
atmState := AWAITPIN
outMess := "Enter pin"
endpar
endif
endif
macro rule r_enterPin =
if(atmState=AWAITPIN) then
if(insertedPin=pin(currCard) and accessible(currCard)) then
par
outMess := "Choose service"
atmState := CHOOSE
numOfBalanceChecks := 0
endpar
else
par
atmState := AWAITCARD
if(insertedPin!=pin(currCard)) then
outMess := "Wrong pin"
endif
if(not(accessible((currCard))) and insertedPin=pin(
currCard)) then
outMess := "Account non accessible"
endif
endpar
endif
endif
macro rule r_chooseService =
if(atmState=CHOOSE) then
par
if(selectedService=BALANCE) then
if(numOfBalanceChecks = 0) then
par
numOfBalanceChecks := numOfBalanceChecks + 1
outMess := balance(currCard)
endpar
else
par
atmState := AWAITCARD
outMess := "You can check only once your balance. Goodbye."
endpar
endif
endif
if(selectedService=WITHDRAWAL) then
par
atmState := CHOOSEAMOUNT
outMess := "Choose Standard or Other"
endpar
endif
if(selectedService=EXIT) then
par
atmState := AWAITCARD
outMess := "Goodbye"
endpar
endif
endpar
endif
rule r_chooseAmount =
if(atmState=CHOOSEAMOUNT) then
par
if(standardOrOther=STANDARD) then
par
atmState := STANDARDAMOUNTSELECTION
outMess := "Select a money size"
endpar
endif
if(standardOrOther=OTHER) then
par
atmState := OTHERAMOUNTSELECTION
outMess := "Enter money size"
endpar
endif
endpar
endif
rule r_grantMoney($m in Integer) =
par
r_subtractFrom[currCard, $m]
moneyLeft := moneyLeft - $m
seq
accessible(currCard) := false
accessible(currCard) := true
endseq
atmState := AWAITCARD
outMess := "Goodbye"
endpar
macro rule r_processMoneyRequest ($m in Integer) =
if(allowed(currCard, $m)) then
r_grantMoney[$m]
else
outMess := "Not enough money in your account"
endif
macro rule r_prelievo =
par
if(atmState=STANDARDAMOUNTSELECTION) then
if(exist $m in MoneySize with $m=insertMoneySizeStandard)
then
if(insertMoneySizeStandard<=moneyLeft) then
r_processMoneyRequest [insertMoneySizeStandard]
else
outMess := "Il bancomat non ha abbastanza soldi"
endif
endif
endif
if(atmState=OTHERAMOUNTSELECTION) then
if(mod(insertMoneySizeOther, 10)=0) then
if(insertMoneySizeOther<=moneyLeft) then
r_processMoneyRequest [insertMoneySizeOther]
else
outMess := "Il bancomat non ha abbastanza soldi"
endif
else
outMess := "Tagli non compatibili"
endif
endif
endpar
main rule r_Main =
if (moneyLeft < minMoney) then
r_goOutOfService[]
else
par
r_insertcard[]
r_enterPin[]
r_chooseService[]
r_chooseAmount[]
r_prelievo[]
endpar
endif
default init s0:
function atmState = AWAITCARD
function moneyLeft = 1000
function balance($c in NumCard) = switch($c)
case card1 : 3000
case card2 : 1652
case card3 : 548
endswitch
function accessible($c in NumCard) = true
