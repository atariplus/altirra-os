; Altirra BASIC - Memory handling module
; Copyright (C) 2014 Avery Lee, All Rights Reserved.
;
; Copying and distribution of this file, with or without modification,
; are permitted in any medium without royalty provided the copyright
; notice and this notice are preserved.  This file is offered as-is,
; without any warranty.

;==========================================================================
; Input:
;	Y:A		Total bytes required
;	X		ZP offset of first pointer to offset
;	A0		Insertion point
.proc expandTable
		;##TRACE "Expanding table: $%04x bytes required, table offset $%02x (%y:%y) [$%04x:$%04x], insert pt=$%04x" y*256+a x x-2 x dw(x-2) dw(x) dw(a0)
		sta		a2
		sty		a2+1
		txa
		pha

		;compute number of bytes to copy
		;##ASSERT dw(a0) <= dw(memtop2)
		sbw		memtop2 a0 a3

		;top of src = memtop2
		;top of dst = memtop2 + N
		clc
		lda		memtop2
		sta		a0
		adc		a2
		sta		a1
		lda		memtop2+1
		sta		a0+1
		adc		a2+1
		sta		a1+1

		jsr		copyDescending

		jmp		contractTable.adjust_table_pointers
.endp

;==========================================================================
; Input:
;	A0	end of source range
;	A1	end of destination range
;	A3	bytes to copy
;
; Modified:
;	A0, A1
;
; Preserved:
;	A2
.proc copyDescending
		;##TRACE "Copy descending src=$%04x-$%04x, dst=$%04x-$%04x (len=$%04x)" dw(a0)-dw(a3) dw(a0) dw(a1)-dw(a3) dw(a1) dw(a3)
		;##ASSERT dw(a3) <= dw(a0) and dw(a3) <= dw(a1)
		ldy		#0

		;check if we have any whole pages to copy
		ldx		a3+1
		beq		leftovers
loop2:
		dec		a0+1
		dec		a1+1
loop:
		dey
		lda		(a0),y
		sta		(a1),y
		tya
		bne		loop
		dex
		bne		loop2
leftovers:
		ldx		a3
		beq		leftovers_done
		dec		a0+1
		dec		a1+1
leftover_loop:
		dey
		lda		(a0),y
		sta		(a1),y
		dex
		bne		leftover_loop
leftovers_done:
		rts
.endp

;==========================================================================
;
; Input:
;	Y:A		Total bytes required (negative)
;	X		ZP offset of first pointer to offset
;	A0		Deletion point
.proc contractTable
		;##TRACE "Memory: Contracting table %y by %u bytes at $%04X" x-2 -(y*256+a)&$ffff dw(a0)
		sta		a2
		sty		a2+1
		ora		a2+1
		beq		nothing_to_do
		txa
		pha

		;compute source position
		sbw		a0 a2 a1

		;compute bytes to copy
		sbw		memtop2 a1 a3

		jsr		copyAscending

adjust_table_pointers:
		pla
		tax
offset_loop:
		lda		0,x
		add		a2
		sta		0,x
		lda		1,x
		adc		a2+1
		sta		1,x
		inx
		inx
		cpx		#memtop2+2
		bne		offset_loop
nothing_to_do:
		rts
.endp

;==========================================================================
; Input:
;	A1	source start
;	A0	destination
;	A3	bytes to copy
;
; Modified:
;	A0, A1
;
; Preserved:
;	A2
.proc copyAscending
		;##TRACE "Copy ascending src=$%04X, dst=$%04X (len=$%04X)" dw(a1) dw(a0) dw(a3)
		ldy		#0
		ldx		a3+1
		beq		do_leftovers

		;copy whole pages
loop:
		lda		(a1),y
		sta		(a0),y
		iny
		bne		loop
		inc		a1+1
		inc		a0+1
		dex
		bne		loop
do_leftovers:

		;copy extra bits
		lda		a3
		beq		leftovers_done
finish_loop:
		lda		(a1),y
		sta		(a0),y
		iny
		cpy		a3
		bne		finish_loop

leftovers_done:
		rts
.endp