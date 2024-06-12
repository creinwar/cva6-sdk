/*============================================================================
 *  This is based on and contains excerpts of:
 *  bandwidth, a benchmark to estimate memory transfer bandwidth.
 *  Copyright (C) 2005-2023 by Zack T Smith.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  The author of bandwidth may be reached at 1 at zsmith dot co.
 *
 *  Author of the changes: Christopher Reinwardt <creinwar@iis.ee.ethz.ch>
 *  Date of the changes: 12.06.2024
 *===========================================================================*/

.global asm_stream_read
.global asm_stream_write

.global asm_stride_read
.global asm_stride_write

.global asm_random_read
.global asm_random_write

.section .text

/* ------------------------------------------------------------------------------
 *  Name:		asm_stream_read
 *  Purpose:	Reads 32 64-bit values sequentially from an area of memory.
 *  Params:		a0 = ptr to memory area
 *  		    a1 = length in bytes
 * 				a2 = loop iterations
 * ------------------------------------------------------------------------------ */
.align 6
asm_stream_read:
	add a1, a1, a0 /* a1 now points to the end */

1:
	add t0, a0, x0

2:
	ld t1,   0(t0)
	ld t1,   8(t0)
	ld t1,  16(t0)
	ld t1,  24(t0)
	ld t1,  32(t0)
	ld t1,  40(t0)
	ld t1,  48(t0)
	ld t1,  56(t0)
	ld t1,  64(t0)
	ld t1,  72(t0)
	ld t1,  80(t0)
	ld t1,  88(t0)
	ld t1,  96(t0)
	ld t1, 104(t0)
	ld t1, 112(t0)
	ld t1, 120(t0)
	ld t1, 128(t0)
	ld t1, 136(t0)
	ld t1, 144(t0)
	ld t1, 152(t0)
	ld t1, 160(t0)
	ld t1, 168(t0)
	ld t1, 176(t0)
	ld t1, 184(t0)
	ld t1, 192(t0)
	ld t1, 200(t0)
	ld t1, 208(t0)
	ld t1, 216(t0)
	ld t1, 224(t0)
	ld t1, 232(t0)
	ld t1, 240(t0)
	ld t1, 248(t0)

	addi t0, t0, 256
	ble t0, a1, 2b

	addi a2, a2, -1
	blt x0, a2, 1b

	ret

/*------------------------------------------------------------------------------
  Name:		asm_stream_write
  Purpose:	Writes 32 64-bit values sequentially to an area of memory.
  Params:	a0 = ptr to memory area
  		    a1 = length in bytes
 			a2 = loop iterations
 ------------------------------------------------------------------------------*/
.align 6
asm_stream_write:
	add a1, a1, a0	/* a1 now points to the end. */

1:
	add t0, a0, x0

2:
	sd t1,   0(t0)
	sd t1,   8(t0)
	sd t1,  16(t0)
	sd t1,  24(t0)
	sd t1,  32(t0)
	sd t1,  40(t0)
	sd t1,  48(t0)
	sd t1,  56(t0)
	sd t1,  64(t0)
	sd t1,  72(t0)
	sd t1,  80(t0)
	sd t1,  88(t0)
	sd t1,  96(t0)
	sd t1, 104(t0)
	sd t1, 112(t0)
	sd t1, 120(t0)
	sd t1, 128(t0)
	sd t1, 136(t0)
	sd t1, 144(t0)
	sd t1, 152(t0)
	sd t1, 160(t0)
	sd t1, 168(t0)
	sd t1, 176(t0)
	sd t1, 184(t0)
	sd t1, 192(t0)
	sd t1, 200(t0)
	sd t1, 208(t0)
	sd t1, 216(t0)
	sd t1, 224(t0)
	sd t1, 232(t0)
	sd t1, 240(t0)
	sd t1, 248(t0)

	addi t0, t0, 256
	ble t0, a1, 2b

	addi a2, a2, -1
	blt x0, a2, 1b

	ret

/*------------------------------------------------------------------------------
  Name:		asm_stride_read
  Purpose:	Reads 64-bit values with a stride from an area of memory.
  Params:	a0 = ptr to memory area
  		    a1 = number of accesses
 			a2 = stride
 			a3 = loop iterations
 ------------------------------------------------------------------------------*/
.align 6
asm_stride_read:
	addi sp, sp, -64

	sd s9, 0(sp)
	sd s8, 8(sp)
	sd s7, 16(sp)
	sd s6, 24(sp)
	sd s5, 32(sp)
	sd s4, 40(sp)
	sd s3, 48(sp)
	sd s2, 56(sp)

1:
	/* Initialize 8 memory pointers with the correct stride */
	add s2, a0, x0
	add s3, s2, a2
	add s4, s3, a2
	add s5, s4, a2
	add s6, s5, a2
	add s7, s6, a2
	add s8, s7, a2
	add s9, s8, a2

	/* Multiply the stride by 8 (as we have 8 pointers) */
	slli t1, a2, 3

	/* Save number of accesses */
	add t0, x0, a1

2:
	ld t2, (s2)
	ld t2, (s3)
	ld t2, (s4)
	ld t2, (s5)
	ld t2, (s6)
	ld t2, (s7)
	ld t2, (s8)
	ld t2, (s9)

	add s2, s2, t1
	add s3, s3, t1
	add s4, s4, t1
	add s5, s5, t1
	add s6, s6, t1
	add s7, s7, t1
	add s8, s8, t1
	add s9, s9, t1

	addi t0, t0, -1
	blt x0, t0, 2b

	addi a3, a3, -1
	blt x0, a3, 1b

	ld s9, 0(sp)
	ld s8, 8(sp)
	ld s7, 16(sp)
	ld s6, 24(sp)
	ld s5, 32(sp)
	ld s4, 40(sp)
	ld s3, 48(sp)
	ld s2, 56(sp)

	addi sp, sp, 64

	ret

/*------------------------------------------------------------------------------
  Name:		asm_stride_write
  Purpose:	Write 64-bit values with a stride to an area of memory.
  Params:	a0 = ptr to memory area
  		    a1 = number of accesses
 			a2 = stride
 			a3 = loop iterations
 ------------------------------------------------------------------------------*/
.align 6
asm_stride_write:
	addi sp, sp, -64

	sd s9, 0(sp)
	sd s8, 8(sp)
	sd s7, 16(sp)
	sd s6, 24(sp)
	sd s5, 32(sp)
	sd s4, 40(sp)
	sd s3, 48(sp)
	sd s2, 56(sp)

.L1:
	/* Initialize 8 memory pointers with the correct stride */
	add s2, a0, x0
	add s3, s2, a2
	add s4, s3, a2
	add s5, s4, a2
	add s6, s5, a2
	add s7, s6, a2
	add s8, s7, a2
	add s9, s8, a2

	/* Multiply the stride by 8 (as we have 8 pointers) */
	slli t1, a2, 3

	/* Save number of accesses */
	add t0, x0, a1

.L2:
	sd t2, (s2)
	sd t2, (s3)
	sd t2, (s4)
	sd t2, (s5)
	sd t2, (s6)
	sd t2, (s7)
	sd t2, (s8)
	sd t2, (s9)

	add s2, s2, t1
	add s3, s3, t1
	add s4, s4, t1
	add s5, s5, t1
	add s6, s6, t1
	add s7, s7, t1
	add s8, s8, t1
	add s9, s9, t1

	addi t0, t0, -1
	blt x0, t0, 2b

	addi a3, a3, -1
	blt x0, a3, 1b

	ld s9, 0(sp)
	ld s8, 8(sp)
	ld s7, 16(sp)
	ld s6, 24(sp)
	ld s5, 32(sp)
	ld s4, 40(sp)
	ld s3, 48(sp)
	ld s2, 56(sp)

	addi sp, sp, 64

	ret

/*------------------------------------------------------------------------------
  Name:		asm_random_read
  Purpose:	Reads 32 64-bit values randomly from an area of memory.
  Params:	a0 = ptr to array of chunk pointers
  			a1 = # of chunks
  			a2 = loops
 ------------------------------------------------------------------------------*/
.align 6
asm_random_read:

1:
	add t1, x0, x0

2:
	slli t2, t1, 3
	add t0, a0, t2

	ld t3, 96(t0)
	ld t3, (t0)
	ld t3, 120(t0)
	ld t3, 184(t0)
	ld t3, 160(t0)
	ld t3, 176(t0)
	ld t3, 112(t0)
	ld t3, 80(t0)
	ld t3, 32(t0)
	ld t3, 128(t0)
	ld t3, 88(t0)
	ld t3, 40(t0)
	ld t3, 48(t0)
	ld t3, 72(t0)
	ld t3, 200(t0)
	ld t3, 24(t0)
	ld t3, 152(t0)
	ld t3, 16(t0)
	ld t3, 248(t0)
	ld t3, 56(t0)
	ld t3, 240(t0)
	ld t3, 208(t0)
	ld t3, 104(t0)
	ld t3, 216(t0)
	ld t3, 136(t0)
	ld t3, 232(t0)
	ld t3, 64(t0)
	ld t3, 224(t0)
	ld t3, 144(t0)
	ld t3, 192(t0)
	ld t3, 8(t0)
	ld t3, 168(t0)

	addi t1, t1, 1
	blt t1, a1, 2b

	addi a2, a2, -1
	blt x0, a2, 1b

	ret

/*------------------------------------------------------------------------------
  Name:		asm_random_write
  Purpose:	Writes 32 64-bit values randomly to an area of memory.
  Params:	a0 = ptr to array of chunk pointers
  			a1 = # of chunks
  			a2 = loops
 ------------------------------------------------------------------------------*/
.align 6
asm_random_write:
1:
	add t1, x0, x0

2:
	slli t2, t1, 3
	add t0, a0, t2

	ld t3, 96(t0)
	ld t3, (t0)
	ld t3, 120(t0)
	ld t3, 184(t0)
	ld t3, 160(t0)
	ld t3, 176(t0)
	ld t3, 112(t0)
	ld t3, 80(t0)
	ld t3, 32(t0)
	ld t3, 128(t0)
	ld t3, 88(t0)
	ld t3, 40(t0)
	ld t3, 48(t0)
	ld t3, 72(t0)
	ld t3, 200(t0)
	ld t3, 24(t0)
	ld t3, 152(t0)
	ld t3, 16(t0)
	ld t3, 248(t0)
	ld t3, 56(t0)
	ld t3, 240(t0)
	ld t3, 208(t0)
	ld t3, 104(t0)
	ld t3, 216(t0)
	ld t3, 136(t0)
	ld t3, 232(t0)
	ld t3, 64(t0)
	ld t3, 224(t0)
	ld t3, 144(t0)
	ld t3, 192(t0)
	ld t3, 8(t0)
	ld t3, 168(t0)

	addi t1, t1, 1
	blt t1, a1, 2b

	addi a2, a2, -1
	blt x0, a2, 1b

	ret
