;	Altirra - Atari 800/800XL/5200 emulator
;	Modular Kernel ROM - Miscellaneous data
;	Copyright (C) 2008-2012 Avery Lee
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

;==========================================================================
;Used by PBI and display/editor.
;
.proc ReversedBitMasks
		dta		$80,$40,$20,$10,$08,$04,$02,$01
.endp

;==========================================================================
;Used by CIO devices
.proc CIOExitSuccess
		ldy		#1
exit_not_supported:
		rts
.endp

CIOExitNotSupported = CIOExitSuccess.exit_not_supported

;==========================================================================
; Sound a bell using the console speaker.
;
; Entry:
;	Y = duration
;
; Modified:
;	X
;
; Preserved:
;	A
;
.proc Bell
	pha
	lda		#$08
soundloop:
	ldx		#4
	pha
delay:
	lda		vcount
	cmp:req	vcount
	dex
	bne		delay
	pla
	eor		#$08
	sta		consol
	bne		soundloop
	dey
	bne		soundloop
	pla
	rts
.endp