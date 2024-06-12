;============================================================================
;  This is based on and contains excerpts of:
;  bandwidth, a benchmark to estimate memory transfer bandwidth.
;  Copyright (C) 2005-2023 by Zack T Smith.
;
;  This program is free software; you can redistribute it and/or modify
;  it under the terms of the GNU General Public License as published by
;  the Free Software Foundation; either version 2 of the License, or
;  (at your option) any later version.
;
;  This program is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License
;  along with this program; if not, write to the Free Software
;  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;
;  The author of bandwidth may be reached at 1 at zsmith dot co.
;
;  Author of the changes: Christopher Reinwardt <creinwar@iis.ee.ethz.ch>
;  Date of changes: 12.06.2024
;=============================================================================


%ifidn __OUTPUT_FORMAT__, win64
; Windows 64 ABI says integer param are put in these registers in this order:
;	rcx, rdx, r8, r9 (floating point is xmm0)
	%define P1 rcx
	%define P2 rdx
	%define P3 r8
	%define P4 r9
%else
; Unix ABI says integer param are put in these registers in this order:
;	rdi, rsi, rdx, rcx, r8, r9
	%define P1 rdi
	%define P2 rsi
	%define P3 rdx
	%define P4 rcx
	%define P5 r8
	%define P6 r9
%endif

bits	64
cpu	ia64

global asm_stream_read
global asm_stream_write

global asm_stride_read
global asm_stride_write

global asm_random_read
global asm_random_write

	section .text

;------------------------------------------------------------------------------
; Name:		asm_stream_read
; Purpose:	Reads 32 64-bit values sequentially from an area of memory.
; Params:	P1 = ptr to memory area
; 		    P2 = length in bytes
;			P3 = loop iterations
;------------------------------------------------------------------------------
	align 64
asm_stream_read:
	push	r10

	add	P2, P1	; P2 now points to end.

.L1:
	mov	r10, P1

.L2:
	mov	rax, [r10]
	mov	rax, [8+r10]
	mov	rax, [16+r10]
	mov	rax, [24+r10]
	mov	rax, [32+r10]
	mov	rax, [40+r10]
	mov	rax, [48+r10]
	mov	rax, [56+r10]
	mov	rax, [64+r10]
	mov	rax, [72+r10]
	mov	rax, [80+r10]
	mov	rax, [88+r10]
	mov	rax, [96+r10]
	mov	rax, [104+r10]
	mov	rax, [112+r10]
	mov	rax, [120+r10]
	mov	rax, [128+r10]
	mov	rax, [136+r10]
	mov	rax, [144+r10]
	mov	rax, [152+r10]
	mov	rax, [160+r10]
	mov	rax, [168+r10]
	mov	rax, [176+r10]
	mov	rax, [184+r10]
	mov	rax, [192+r10]
	mov	rax, [200+r10]
	mov	rax, [208+r10]
	mov	rax, [216+r10]
	mov	rax, [224+r10]
	mov	rax, [232+r10]
	mov	rax, [240+r10]
	mov	rax, [248+r10]

	add	r10, 256
	cmp	r10, P2
	jb	.L2

	dec P3
	jnz .L1

	pop	r10
	ret

;------------------------------------------------------------------------------
; Name:		asm_stream_write
; Purpose:	Writes 32 64-bit values sequentially to an area of memory.
; Params:	P1 = ptr to memory area
; 		    P2 = length in bytes
;			P3 = loop iterations
;------------------------------------------------------------------------------
	align 64
asm_stream_write:
	push	r10

	add	P2, P1	; P2 now points to end.

.L1:
	mov	r10, P1

.L2:
	mov	[r10],		rax
	mov	[8+r10],	rax
	mov	[16+r10],  	rax
	mov	[24+r10],  	rax
	mov	[32+r10],  	rax
	mov	[40+r10],  	rax
	mov	[48+r10],  	rax
	mov	[56+r10],  	rax
	mov	[64+r10],  	rax
	mov	[72+r10],  	rax
	mov	[80+r10],  	rax
	mov	[88+r10],  	rax
	mov	[96+r10],  	rax
	mov	[104+r10], 	rax
	mov	[112+r10], 	rax
	mov	[120+r10], 	rax
	mov	[128+r10], 	rax
	mov	[136+r10], 	rax
	mov	[144+r10], 	rax
	mov	[152+r10], 	rax
	mov	[160+r10], 	rax
	mov	[168+r10], 	rax
	mov	[176+r10], 	rax
	mov	[184+r10], 	rax
	mov	[192+r10], 	rax
	mov	[200+r10], 	rax
	mov	[208+r10], 	rax
	mov	[216+r10], 	rax
	mov	[224+r10], 	rax
	mov	[232+r10], 	rax
	mov	[240+r10], 	rax
	mov	[248+r10], 	rax

	add	r10, 256
	cmp	r10, P2
	jb	.L2

	dec P3
	jnz .L1

	pop	r10

	ret

;------------------------------------------------------------------------------
; Name:		asm_stride_read
; Purpose:	Reads 64-bit values with a stride from an area of memory.
; Params:	P1 = ptr to memory area
; 		    P2 = number of accesses
;			P3 = stride
;			P4 = loop iterations
;------------------------------------------------------------------------------
	align 64
asm_stride_read:
	push	r8
	push	r9
	push	r10
	push	r11
	push    r12
	push    r13
	push    r14
	push    r15
	push 	P3

.L1:
	; Initialize 8 memory pointers with the correct stride
	pop 	P3
	mov r8, P1
	mov r9, P3
	add r9, r8
	mov	r10, P3
	add r10, r9
	mov r11, P3
	add r11, r10
	mov r12, P3
	add r12, r11
	mov r13, P3
	add r13, r12
	mov r14, P3
	add r14, r13
	mov r15, P3
	add r15, r14

	; Multiply the stride by 8 (as we have 8 pointers)
	push P3
	mov rax, 8
	mul P3
	mov P3, rax

	push P2
.L2:
	mov rax, [r8]
	mov rax, [r9]
	mov rax, [r10]
	mov rax, [r11]
	mov rax, [r12]
	mov rax, [r13]
	mov rax, [r14]
	mov rax, [r15]

	add r8, P3
	add r9, P3
	add r10, P3
	add r11, P3
	add r12, P3
	add r13, P3
	add r14, P3
	add r15, P3

	dec P2
	jnz .L2

	pop P2

	dec P4
	jnz .L1

	pop P3
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8

	ret

;------------------------------------------------------------------------------
; Name:		asm_stride_write
; Purpose:	Write 64-bit values with a stride to an area of memory.
; Params:	P1 = ptr to memory area
; 		    P2 = number of accesses
;			P3 = stride
;			P4 = loop iterations
;------------------------------------------------------------------------------
	align 64
asm_stride_write:
	push	r8
	push	r9
	push	r10
	push	r11
	push    r12
	push    r13
	push    r14
	push    r15
	push 	P3

.L1:
	; Initialize 8 memory pointers with the correct stride
	pop 	P3
	mov r8, P1
	mov r9, P3
	add r9, r8
	mov	r10, P3
	add r10, r9
	mov r11, P3
	add r11, r10
	mov r12, P3
	add r12, r11
	mov r13, P3
	add r13, r12
	mov r14, P3
	add r14, r13
	mov r15, P3
	add r15, r14

	; Multiply the stride by 8 (as we have 8 pointers)
	push P3
	mov rax, 8
	mul P3
	mov P3, rax

	push P2
.L2:
	mov [r8],  rax
	mov [r9],  rax
	mov [r10], rax
	mov [r11], rax
	mov [r12], rax
	mov [r13], rax
	mov [r14], rax
	mov [r15], rax

	add r8, P3
	add r9, P3
	add r10, P3
	add r11, P3
	add r12, P3
	add r13, P3
	add r14, P3
	add r15, P3

	dec P2
	jnz .L2

	pop P2

	dec P4
	jnz .L1

	pop P3
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8

	ret

;------------------------------------------------------------------------------
; Name:		asm_random_read
; Purpose:	Reads 32 64-bit values randomly from an area of memory.
; Params:	P1 = ptr to array of chunk pointers
; 			P2 = # of chunks
; 			P3 = loops
;------------------------------------------------------------------------------
	align 64
asm_random_read:
	push	r10
	push	r11

.L1:
	xor	r11, r11

.L2:
	mov	r10, [P1 + 8*r11]	; Note, 64-bit pointers.

	mov	rax, [96+r10]
	mov	rax, [r10]
	mov	rax, [120+r10]
	mov	rax, [184+r10]
	mov	rax, [160+r10]
	mov	rax, [176+r10]
	mov	rax, [112+r10]
	mov	rax, [80+r10]
	mov	rax, [32+r10]
	mov	rax, [128+r10]
	mov	rax, [88+r10]
	mov	rax, [40+r10]
	mov	rax, [48+r10]
	mov	rax, [72+r10]
	mov	rax, [200+r10]
	mov	rax, [24+r10]
	mov	rax, [152+r10]
	mov	rax, [16+r10]
	mov	rax, [248+r10]
	mov	rax, [56+r10]
	mov	rax, [240+r10]
	mov	rax, [208+r10]
	mov	rax, [104+r10]
	mov	rax, [216+r10]
	mov	rax, [136+r10]
	mov	rax, [232+r10]
	mov	rax, [64+r10]
	mov	rax, [224+r10]
	mov	rax, [144+r10]
	mov	rax, [192+r10]
	mov	rax, [8+r10]
	mov	rax, [168+r10]

	inc	r11
	cmp	r11, P2
	jb	.L2

	dec	P3
	jnz	.L1

	pop	r11
	pop	r10

	ret

;------------------------------------------------------------------------------
; Name:		asm_random_write
; Purpose:	Writes 32 64-bit values randomly to an area of memory.
; Params:	P1 = ptr to array of chunk pointers
; 			P2 = # of chunks
; 			P3 = loops
;------------------------------------------------------------------------------
	align 64
asm_random_write:
	push	r10
	push	r11

.L1:
	xor	r11, r11

.L2:
	mov	r10, [P1 + 8*r11]	; Note, 64-bit pointers.

	mov	[96+r10],	rax
	mov	[r10],		rax
	mov	[120+r10],	rax
	mov	[184+r10],	rax
	mov	[160+r10],	rax
	mov	[176+r10],	rax
	mov	[112+r10],	rax
	mov	[80+r10],	rax
	mov	[32+r10],	rax
	mov	[128+r10],	rax
	mov	[88+r10],	rax
	mov	[40+r10],	rax
	mov	[48+r10],	rax
	mov	[72+r10],	rax
	mov	[200+r10],	rax
	mov	[24+r10],	rax
	mov	[152+r10],	rax
	mov	[16+r10],	rax
	mov	[248+r10],	rax
	mov	[56+r10],	rax
	mov	[240+r10],	rax
	mov	[208+r10],	rax
	mov	[104+r10],	rax
	mov	[216+r10],	rax
	mov	[136+r10],	rax
	mov	[232+r10],	rax
	mov	[64+r10],	rax
	mov	[224+r10],	rax
	mov	[144+r10],	rax
	mov	[192+r10],	rax
	mov	[8+r10],	rax
	mov	[168+r10],	rax

	inc	r11
	cmp	r11, P2
	jb	.L2

	dec	P3
	jnz	.L1

	pop	r11
	pop	r10

	ret

