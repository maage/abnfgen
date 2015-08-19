/*
 *
 */

#include "abnfgenp.h"

void * malcpy(void const * old_p, size_t size)
{
	void * new_p = malloc(size);
	if (new_p) 
		memcpy(new_p, old_p, size);
	return new_p;
}
