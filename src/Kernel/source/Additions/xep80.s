;	Altirra - Atari 800/800XL/5200 emulator
;	Additions - XEP-80 Handler Relocatable Loader
;	Copyright (C) 2008-2014 Avery Lee
;
;	This program is free software; you can redistribute it and/or modify
;	it under the terms of the GNU General Public License as published by
;	the Free Software Foundation; either version 2 of the License, or
;	(at your option) any later version.
;
;	This program is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;	GNU General Public License for more details.
;
;	You should have received a copy of the GNU General Public License
;	along with this program; if not, write to the Free Software
;	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

		icl		'cio.inc'
		icl		'sio.inc'
		icl		'kerneldb.inc'
		icl		'hardware.inc'

ciov	equ		$e456

;==========================================================================
.macro _ASSERT condition, message
		.if (:condition)=0
		.error	message
		.endif
.endm

;==========================================================================

		org		$00ea
		opt		o-
relocad	dta		a(0)		;this has to be at $EA (nop)
basead	dta		a(0)
srcptr	dta		a(0)
dstptr	dta		a(0)

		org		$3000
		opt		o+

;==========================================================================
.proc _main
		;set base address right below MEMTOP (and move it to more convenient zp)
		lda		memtop
		sta		dstptr
		sec
		sbc		#<[.len HandlerData]
		sta		basead

		lda		memtop+1
		sta		dstptr+1
		sbc		#>[.len HandlerData]
		sta		basead+1

		;move handler data up (descending copy)
		mwa		#HandlerData+[.len HandlerData] srcptr
		ldx		#>[.len HandlerData]
		ldy		#0
page_loop:
		dec		srcptr+1
		dec		dstptr+1
page_copy_loop:
		dey
		mva		(srcptr),y (dstptr),y
		tya
		bne		page_copy_loop
		dex
		bne		page_loop

		.if		<[.len HandlerData]
		ldx		#<[.len HandlerData]
		dec		srcptr+1
		dec		dstptr+1
xtra_loop:
		dey
		lda		(srcptr),y
		sta		(dstptr),y
		dex
		bne		xtra_loop
		.endif

		;relocate low bytes
		ldx		#0
		ldy		#1
		jsr		Relocate

		;relocate words
		lda		#$91
		sta		Relocate.high_write_op
		jsr		Relocate

		;relocate high bytes
		_ASSERT	((FetchDest ^ GetByte)&$ff00)==0, "fetch routines must be in the same page"
		mva		#<GetByte Relocate.fetch_routine
		lda		#{nop}
		sta		Relocate.lo_write_op
		jsr		Relocate

		;execute init
		jsr		do_init

		;fake cold start around cold init so we don't reinit DOS
		lda		warmst
		pha
		mva		#0 warmst
		jsr		do_init2
		pla
		sta		warmst

		lda		#<msg_load_succeeded
		ldy		#>msg_load_succeeded
		jmp		PutMessage

do_init2:
		jmp		(dosini)

do_init:
		jmp		(basead)

msg_load_succeeded:
		dta		'Altirra XEP80 handler V0.4 loaded.',$9B
.endp

;==========================================================================
; Input:
;	Y:A = message
;
.proc PutMessage
		sta		icbal
		sty		icbah
		mva		#CIOCmdPutRecord iccmd
		ldx		#1
		sta		icblh
		dex
		sta		icbll
		jmp		ciov
.endp

;==========================================================================
; Apply relocations.
;
; Inputs:
;	X = 0 for low/word relocations, 2 for high byte relocations
;	Y = 1
;
; Outputs:
;	X, Y preserved
;
.proc Relocate
		;reset relocation pointer
		mwa		basead relocad

reloc_loop:
		;fetch first delta byte
		jsr		GetByte

		;if first delta byte is zero, we're done
		beq		done

ext_addr:
		;add delta byte to relocation pointer
		pha
		clc
		adc		relocad
		sta		relocad
		scc:inc	relocad+1
		pla

		;loop back for more bytes if we have a $FF, but note that $00 is
		;not a terminator after the first byte
		cmp		#$ff
		bne		next_addr_done
		jsr		GetByte
		bcs		ext_addr

next_addr_done:
		jsr		FetchDest			;get dest lo (lo/word), get stream byte (hi)
fetch_routine = *-2
		adc		basead
		sta		(relocad,x)			;turned into nop/nop for (hi)
lo_write_op = *-2
		lda		(relocad),y
		adc		basead+1
		eor		#relocad			;opcode changed from $49 (EOR #imm) (lo) to $91 (STA (zp),Y) (word/hi)
high_write_op = *-2
		jmp		reloc_loop

done:
		rts
.endp

;==========================================================================
.proc FetchDest
		lda		(relocad,x)
		rts
.endp

;==========================================================================
.proc GetByte
		inw		get_ptr
		lda		relocdata_begin-1
get_ptr = *-2
		rts
.endp

;==========================================================================
		opt		l-
		icl		'xep80handler-relocs.inc'
		opt		l+

;==========================================================================
.proc HandlerData
		ins		'xep80handler2.bin'
.endp

;==========================================================================
		run		_main