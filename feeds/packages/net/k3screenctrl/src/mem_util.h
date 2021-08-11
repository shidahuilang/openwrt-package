#ifndef _MEMWRITE_H
#define _MEMWRITE_H

#include <sys/mman.h>

/*
 * Set the field specified by mask in the byte to given value.
 * E.g. mask_memory_byte(&mybyte, 0xf0, 0xf) will make mybyte[4:7] = 0xf.
 */
int mask_memory_byte(off_t addr, int mask, int field_value);

#endif
