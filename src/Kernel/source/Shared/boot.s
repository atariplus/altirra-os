;	Altirra - Atari 800/800XL/5200 emulator
;	Modular Kernel ROM - Boot Code
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
; Disk boot routine.
;
; Exit:
;	DBUFLO/DBUFHI = $0400	(Undoc; required by Ankh and the 1.atr SMB demo)
;	Last sector in $0400	(Undoc; required by Ankh)
;
.proc BootDisk
	;issue a status request first to see if the disk is active; if this
	;doesn't come back, don't bother trying to read
	lda		#$53
	sta		dcomnd
	ldx		#1
	stx		dunit
	jsr		dskinv
	bmi		xit

	;read first sector to $0400
	ldx		#1
	stx		dunit
	stx		daux1
	dex
	stx		dbuflo
	mva		#$52	dcomnd
	mva		#$04	dbufhi
	jsr		dskinv
	bmi		fail

	ldx		#dosini
	jsr		BootInitHeaders

	;load remaining sectors
sectorloop:
	;copy sector from $0400 to destination (required by Ankh; see above)
	;bump destination address for next sector copy
	jsr		BootCopyBlock

	;exit if this was the last sector (note that 0 means to load 256 sectors!)
	dec		dbsect
	beq		loaddone

	;increment sector (yes, this can overflow to 256)
	inw		daux1

	;read next sector
	jsr		dskinv

	;keep going if we succeeded
	bpl		sectorloop

	;read failed
fail:
	cpy		#SIOErrorTimeout
	bne		failmsg
xit:
	rts

failmsg:
.if _KERNEL_USE_BOOT_SCREEN
	jmp		SelfTestEntry
.else
	jsr		BootShowError
	jmp		BootDisk
.endif

loaddone:
	mva		#1 boot?
	jsr		BootRunLoader
	bcs		failmsg

	;Diskette Boot Process, step 7 (p.161 of the OS Manual) is misleading. It
	;says that DOSVEC is invoked after DOSINI, but actually that should NOT
	;happen here -- it happens AFTER cartridges have had a chance to run.
	;This is necessary for BASIC to gain control before DOS goes to load
	;DUP.SYS.
	jmp		(dosini)
.endp


;============================================================================

.proc BootCassette
	;set continuous mode -- must do this as CSOPIV doesn't
	lda		#$80
	sta		ftype

	;open cassette device
	jsr		csopiv

	;read first block
	jsr		rblokv
	bmi		load_failure

	ldx		#casini
	jsr		BootInitHeaders

block_loop:
	;copy 128 bytes from CASBUF+3 ($0400) to destination
	;update destination pointer
	jsr		BootCopyBlock

	dec		dbsect
	beq		block_loop_exit

	;read next block
	jsr		rblokv
	bmi		load_failure
	jmp		block_loop

block_loop_exit:

	;set cassette boot flag
	mva		#2 boot?

	;run loader
	jsr		BootRunLoader

	;run cassette init routine
	jsr		go_init

	;run application
	jmp		(dosvec)

load_failure:
	jsr		CassetteClose
	jmp		BootShowError

go_init:
	jmp		(casini)
.endp

;============================================================================
.proc BootInitHeaders
	;copy the first four bytes to DFLAGS, DBSECT, and BOOTAD
	ldy		#$fc
	mva:rne	$0400-$fc,y dflags-$fc,y+

	;copy boot address in BOOTAD to BUFADR
	sta		bufadr+1
	lda		bootad
	sta		bufadr

	;copy init vector
	mwa		$0404 0,x
	rts
.endp

;============================================================================
.proc BootRunLoader
	;loader is at load address + 6
	lda		bootad
	add		#$05
	tax
	lda		bootad+1
	adc		#0
	pha
	txa
	pha
	rts
.endp

;============================================================================
.proc BootCopyBlock
	ldy		#$7f
	mva:rpl	$0400,y (bufadr),y-

	lda		bufadr
	eor		#$80
	sta		bufadr
	smi:inc	bufadr+1
	rts
.endp

;============================================================================

.proc BootShowError
	ldx		#$f5
msgloop:
	txa
	pha
	lda		errormsg-$f5,x
	jsr		EditorPutByte
	pla
	tax
	inx
	bne		msgloop
	rts

errormsg:
	dta		'BOOT ERROR',$9B
.endp
