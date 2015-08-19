/*
 *
 */

#include "abnfgenp.h"

#include <execinfo.h>
#define FAIL_MALLOC_BACKTRACE_SIZE 100
struct fail_malloc_backtrace
{
    void *array[FAIL_MALLOC_BACKTRACE_SIZE];
    size_t size;
    char **strings;
    size_t strings_len[FAIL_MALLOC_BACKTRACE_SIZE];
    unsigned int hash;
};

ag_expression * ag_expression_create(ag_handle * ag, int type)
{
	ag_expression * e = ag_emalloc(ag, "expression", sizeof(*e));
	if (e) {
#if 0
		size_t i;
		struct fail_malloc_backtrace bt;
		memset(&bt, 0, sizeof(struct fail_malloc_backtrace));
		bt.size = backtrace(bt.array, FAIL_MALLOC_BACKTRACE_SIZE);
		bt.strings = backtrace_symbols(bt.array, bt.size);
		printf("ag_expression_create: %p %d ", e, type);
		for (i = 0; i < bt.size; i++) {
			printf("--- %s", bt.strings[i]);
		}
		printf("\n");
#endif
		memset(e, 0, sizeof(*e));
		e->any.distance = -1;
		e->type = type;
		e->any.input_name = ag_symbol_make(ag, ag->input_name);
		e->any.input_line = ag->input_line;
		return e;
	}
	return e;
}


void ag_expression_free(ag_handle * ag, ag_expression ** ex)
{
	ag_expression * child, * next;

	if (*ex) {
		switch ((*ex)->type) {
		case AG_EXPRESSION_ALTERNATION:
		case AG_EXPRESSION_CONCATENATION:
			for (next = (*ex)->compound.child; (child = next);) {
				next = child->any.next;
				ag_expression_free(ag, &child);
			}
			break;

		case AG_EXPRESSION_REPETITION:
			ag_expression_free(ag, &(*ex)->repetition.body);
			break;
		default:
			break;
		}
#if 0
		{
		size_t i;
		struct fail_malloc_backtrace bt;
		memset(&bt, 0, sizeof(struct fail_malloc_backtrace));
		bt.size = backtrace(bt.array, FAIL_MALLOC_BACKTRACE_SIZE);
		bt.strings = backtrace_symbols(bt.array, bt.size);
		printf("ag_expression_free: %p %d ", *ex, (*ex)->type);
		for (i = 0; i < bt.size; i++) {
			printf("--- %s", bt.strings[i]);
		}
		printf("\n");
		}
#endif
		free(*ex);
		*ex = 0;
	}
}

int ag_compound_add(
	ag_handle      * ag,
	int		  type,
	ag_expression ** loc,
	ag_expression ** alt)
{
	if (!*loc) {
		*loc = ag_expression_create(ag, type);
		if (!*loc) return AG_ERROR_MEMORY;
	}
	if ((*loc)->type != type) {
		
		ag_expression * new_head = ag_expression_create(ag, type);
		if (!new_head) return AG_ERROR_MEMORY; 

		new_head->compound.child = *loc;
		*loc = new_head;
	}
	for (loc = &(*loc)->compound.child; *loc; loc = &(*loc)->any.next)
		;

	*loc = *alt;
	*alt = 0;

	return 0;
}
