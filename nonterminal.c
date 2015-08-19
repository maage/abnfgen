/*
 *
 */

#include "abnfgenp.h"

int ag_complained_lookup_symbol(
	ag_handle 		* ag,
	ag_symbol		  name)
{
	return !!haccess(&ag->complained, char, &name, sizeof(name));
}

void ag_complained_make_symbol(ag_handle * ag, ag_symbol name)
{
	(void)hnew(&ag->complained, char, &name, sizeof(name));
}

ag_nonterminal * ag_nonterminal_lookup_symbol(
	ag_handle 		* ag,
	ag_symbol		  name)
{
	return haccess(&ag->nonterminals, ag_nonterminal,
		&name, sizeof(name));
}

ag_nonterminal * ag_nonterminal_make_symbol(
	ag_handle 		* ag,
	ag_symbol		  name)
{
	return hnew(&ag->nonterminals, ag_nonterminal, &name, sizeof(name));
}

char const * ag_nonterminal_name(
	ag_handle		* ag,
	ag_nonterminal const	* nt)
{
	ag_symbol		* mem;

	assert(nt);
	mem = (void *)hmem(&ag->nonterminals, ag_nonterminal, nt);
	return ag_symbol_text(ag, *mem);
}

ag_symbol ag_nonterminal_symbol(
	ag_handle		* ag,
	ag_nonterminal const   * nt)
{
	ag_symbol		* mem;

	assert(nt);
	mem = (void *)hmem(&ag->nonterminals, ag_nonterminal, nt);
	return *mem;
}

