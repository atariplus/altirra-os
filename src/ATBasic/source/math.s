; Altirra BASIC - Misc math module
; Copyright (C) 2014 Avery Lee, All Rights Reserved.
;
; Copying and distribution of this file, with or without modification,
; are permitted in any medium without royalty provided the copyright
; notice and this notice are preserved.  This file is offered as-is,
; without any warranty.

;===========================================================================
;FCOMP		Floating point compare routine.
;
; Inputs:
;	FR0
;	FR1
;
; Outputs:
;	Z, C set for comparison result like SBC
;
.proc fcomp
		;check for sign difference
		lda		fr1
		tax
		eor		fr0
		bpl		signs_same

		;signs are different
		cpx		fr0
xit:
		rts

signs_same:
		;check for both values being zero, as only signexp and first
		;mantissa byte are guaranteed to be $00 in that case
		txa
		ora		fr0
		beq		xit

		;compare signexp and mantissa bytes in order
		ldx		#<-6
loop:
		lda		fr0+6,x
		cmp		fr1+6,x
		bne		diff
		inx
		bne		loop
		rts

diff:
		;okay, we've confirmed that the numbers are different, but the
		;carry flag may be going the wrong way if the numbers are
		;negative... so let's fix that.
		ror
		eor		fr0
		sec
		rol
		rts
.endp

;===========================================================================
.proc	MathFloor
		;if exponent is > $44 then there can be no decimals
		lda		fr0
		and		#$7f
		cmp		#$45
		bcs		done

		;if exponent is < $40 then we have zero or -1
		cmp		#$40
		bcs		not_tiny
		asl		fr0
		php
		jsr		zfr0
		plp
		bcs		round_down
done:
		rts

not_tiny:
		;ok... using the exponent, compute the first digit offset we should
		;check
		adc		#$bb		;note: carry is set coming in
		tax

		;check digit pairs until we find a non-zero fractional digit pair,
		;zeroing as we go
		lda		#0
		tay
zero_loop:
		ora		fr0+6,x
		sty		fr0+6,x
		inx
		bne		zero_loop

		;skip rounding if it was already integral
		tay
		beq		done

		;check if we have a negative number; if so, we need to subtract one
		lda		fr0
		bpl		done

round_down:
		;subtract one to round down
		jsr		MathLoadOneFR1
		jmp		fsub

.endp

;===========================================================================
; Extract sign from FR0 into funScratch1 and take abs(FR0).
;
.proc MathSplitSign
		lda		fr0
		sta		funScratch1
		and		#$7f
		sta		fr0
xit:
		rts
.endp

;===========================================================================
.proc MathByteToFP
		ldx		#0
.def :MathWordToFP = *
		stx		fr0+1
.def :MathWordToFP_FR0Hi_A = *
		sta		fr0
		jmp		ifp
.endp

;===========================================================================
.proc MathLoadOneFR1
		ldx		#<const_one
.def :MathLoadConstFR1 = *
		ldy		#>const_one
		bne		MathLoadFR1_FPSCR.fld1r_trampoline
.endp

;===========================================================================
.proc MathStoreFR0_FPSCR
		ldx		#<fpscr
.def :MathStoreFR0_Page5 = *
		ldy		#>fpscr
		jmp		fst0r
.endp

;===========================================================================
.proc MathLoadFR1_FPSCR
		ldx		#<fpscr
.def :MathLoadFR1_Page5 = *
		ldy		#>fpscr
fld1r_trampoline:
		jmp		fld1r
.endp
