/*
 * Library: libcrc
 * File:    include/checksum.h
 * Author:  Lammert Bies
 *
 * This file is licensed under the MIT License as stated below
 *
 * Copyright (c) 1999-2016 Lammert Bies
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Description
 * -----------
 * The headerfile include/checksum.h contains the definitions and prototypes
 * for routines that can be used to calculate several kinds of checksums.
 */

#ifndef DEF_LIBCRC_CHECKSUM_H
#define DEF_LIBCRC_CHECKSUM_H

#include <stdint.h>

/*
 * #define CRC_POLY_xxxx
 *
 * The constants of the form CRC_POLY_xxxx define the polynomials for some well
 * known CRC calculations.
 */

#define		CRC_POLY_CCITT		0x1021

/*
 * #define CRC_START_xxxx
 *
 * The constants of the form CRC_START_xxxx define the values that are used for
 * initialization of a CRC value for common used calculation methods.
 */

#define		CRC_START_XMODEM	0x0000

/*
 * Prototype list of global functions
 */

uint16_t		crc_xmodem(         const unsigned char *input_str, size_t num_bytes       );
uint16_t		update_crc_ccitt(   uint16_t crc, unsigned char c                          );

#endif  // DEF_LIBCRC_CHECKSUM_H
