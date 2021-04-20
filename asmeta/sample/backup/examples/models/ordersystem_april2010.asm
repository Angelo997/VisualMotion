/** without inputs */

asm ordersystem_april2010
	
import ../../STDL/StandardLibrary

signature:
	abstract domain Orders
	abstract domain Products
	domain Quantity subsetof Natural
	enum domain OrderStatus = { INVOICED | PENDING }

	dynamic monitored referencedProduct: Orders -> Products
	dynamic controlled orderState: Orders -> OrderStatus
	dynamic monitored orderQuantity: Orders -> Quantity
	dynamic controlled stockQuantity: Products -> Quantity

	// part added for extensions and variation

	static pendingOrders: Products -> Powerset(Orders)
	static totalQuantity: Powerset(Orders) -> Quantity
	static totalOrderedQuantity: Products -> Quantity
	// for variating at maximum order
	// returns all the posible subsets of the pending orders for a product
	static maxQuantitySubsets: Powerset(Powerset(Orders)) -> Powerset(Powerset(Orders))
	// it returns if a orderset is invoicable
	static invoicable: Powerset(Orders) -> Boolean
	static totalQuantity: Prod(Powerset(Orders),Products) -> Quantity
	static referencedProducts: Powerset(Orders) -> Powerset(Products)

	//Setting the scenario:
	//---------------------
	static o1: Orders
	static o2: Orders
	static o3: Orders

	static p1: Products
	static p2: Products
	static p3: Products
	//-------------------

definitions:

	// aggiunte
	/* given a product return the set of orders of that product that are still PENDING*/	
	function pendingOrders($p in Products) = 
		{$o in Orders | orderState($o) = PENDING and referencedProduct($o) = $p : $o}

	/* given a set of Orders, return the sum of quantity of such orders */
	function totalQuantity($so in Powerset(Orders)) =
		if (isEmpty($so)) then
			0n 
		else
			let ( $first =  chooseone($so)) in
				( orderQuantity($first) + totalQuantity(excluding($so,$first)))
			endlet
		endif

	/* given a product, returns the total ordered quantity - NOT USED */
	function totalOrderedQuantity ($p in Products) = 
		totalQuantity(pendingOrders($p))

	/* given a product, return all the possible subsets of orders
	function maxQuantitySubsets($so in Powerset(Powerset(Orders))) =
	*/

	function totalQuantity($so in Powerset(Orders), $p in Products) =
 		if (isEmpty($so)) then 0n 
		else
			//let ( $first = first(asSequence($so)) in
			//if (referencedProduct($first) = $p) then orderQuantity($first) + totalQuantity(excluding($so,$first),$p)
			//else totalQuantity(excluding($so,$first),$p)
			if (referencedProduct(first(asSequence($so))) = $p) then 
				orderQuantity(first(asSequence($so))) + totalQuantity(excluding($so,first(asSequence($so))),$p)
			else 
				totalQuantity(excluding($so,first(asSequence($so))),$p)
			endif
	endif
      
	function invoicable($so in Powerset(Orders)) = 
		( forall $o in $so with orderState($o) = PENDING)  
		//  and 
		// ( forall $p in Products with totalQuantity($so,$p) <= stockQuantity($p))
	
	function referencedProducts($so in Powerset(Orders)) =
 		if (isEmpty($so)) then {} 
		else
			let ( $first = chooseone($so)) in
			 including(referencedProducts(excluding($so,$first)),referencedProduct($first))
			endlet
		endif

	/// rules
	// nucleo 1 versione

	/*------------ versione 1 */
	
	macro rule  r_DeleteStock($p in Products ,$q in Quantity)= 
       stockQuantity($p):= stockQuantity($p) - $q

	//problema: non c'e' lazy evaluation sull'and e quindi possono essere valutati
	//ordini gia' INVOICED
	/*rule r_InvoiceSingleOrder = 
		choose $order in Orders with orderState($order) = PENDING and
					orderQuantity($order) <= stockQuantity(referencedProduct($order))do
			par
				orderState($order) := INVOICED 
			    r_DeleteStock[referencedProduct($order),orderQuantity($order)] 
			endpar*/

	//per evitare che siano valutati ordini gia' INVOICED
	rule r_InvoiceSingleOrder = 
		choose $order in Orders with orderState($order) = PENDING do
			if(orderQuantity($order) <= stockQuantity(referencedProduct($order))) then
				par
					orderState($order) := INVOICED 
				    r_DeleteStock[referencedProduct($order),orderQuantity($order)] 
				endpar
			endif

	// aggiunte
	/*---------- AllOrNone ------------*/
	rule r_InvoiceAllOrNone =
		choose $product in Products with true do
			let ( $pending = pendingOrders($product) ) in
				let ( $total = totalQuantity($pending) ) in
					if $total <= stockQuantity($product) then 
						par
							forall $order in $pending with true	do orderState($order) := INVOICED 
								r_DeleteStock[$product, $total]	
						endpar
					endif
				endlet
			endlet

	/* ------ choose subset of orders ---*/
	rule r_InvoiceOrdersForOneProduct = 
		choose $product in Products with true do
			let ($pending = pendingOrders($product)) in
				//choose $orderSet in Powerset($pending) with totalQuantity($orderSet) <= stockQuantity($product) do
				choose $orderSet in Powerset(Orders) with totalQuantity($orderSet) <= stockQuantity($product) do
					par
						forall $order in $orderSet with true do orderState($order) := INVOICED 
						r_DeleteStock[$product, totalQuantity($orderSet)]
					endpar
			endlet

	/*------- maximum ord --------*/
	rule r_InvoiceMaxOrdersForOneProduct =
		choose $product in Products with true do
			let ($pending = pendingOrders($product)) in
				//let ($invoicablePending = {$o in Powerset(($pending) | totalQuantity($o) <= stockQuantity($product) : $o} ) in
				let ($invoicablePending = {$o in Powerset(Orders) | totalQuantity($o) <= stockQuantity($product) : $o} ) in
					choose $orderSet in maxQuantitySubsets($invoicablePending) with true do
						par
							forall $order in $orderSet with true do
								orderState($order) := INVOICED 
							r_DeleteStock[$product, totalQuantity($orderSet)]
						endpar
				endlet
			endlet

	/*------- choose subset of orders -----*/
	rule r_InvoiceOrders =
		choose $orderSet in Powerset(Orders) with invoicable($orderSet) do
			par
				forall $order in $orderSet with true do
					orderState($order) := INVOICED 
				forall $product in referencedProducts($orderSet) with true do
					r_DeleteStock[$product, totalQuantity($orderSet,$product)]
			endpar

	/*------- main rule   --------*/       	
	main rule r_ordersystem =
		r_InvoiceSingleOrder[]
		//r_InvoiceAllOrNone[]
		//r_InvoiceOrdersForOneProduct[]//non funziona per problema di choose su set
		//r_InvoiceMaxOrdersForOneProduct[]//non funziona per problema di choose su set
		//r_InvoiceOrders[]//non funziona per problema di choose su set

default init s_1:
	function orderState($o in Orders) = PENDING
	function stockQuantity($p in Products) = 100n
