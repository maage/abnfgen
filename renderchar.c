/*
 *
 */

#include "abnfgenp.h"

char const * renderchar(unsigned char c)
{
	static char	buf[5];
	char		* s = buf;

	for (;;) {
		if (c < 32) {
			*s++ = '^';
			*s++ = '@' + c;
			*s++ = '\0';
			return buf;
		}
		if (c < 0177) {
			*s++ = c;
			*s++ = '\0';
			return buf;
		}
		if (c == 0177) {
			*s++ = '^';
			*s++ = '?';
			*s++ = '\0';
			return buf;
		}
		c -= 128;
		*s++ = 'M';
		*s++ = '-';
	}
}

