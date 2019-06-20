; standart.asm
; macros for standart codes
;============================================================================

!macro SET_START .address {

	;Inject SYS .addres in BASIC memory

	* = $0801
	
	!byte $0c,$08,$0a,$00,$9e 	; 10SYS
	!byte (.address/10000)+48
	!byte (.address/1000)%10+48
	!byte (.address/100)%10+48
	!byte (.address/10)%10+48
	!byte (.address%10)+48
	!byte 0
	
	* = .address
}

!macro CLEAR_SCREEN {
	
	ldx #00
	lda #$20
.loop:
	sta SCREEN_RAM,x
	sta SCREEN_RAM+255,x
	sta SCREEN_RAM+510,x
	sta SCREEN_RAM+765,x
	sta SCREEN_RAM+1020,x
	dex
	bne .loop
}

!macro inc16 .address{

	;16bit unsigned increase
	inc .address
	bne *+5
	inc .address+1
}

!macro dec16 .address{
	;16bit unsigned increase
	lda .address
	bne *+5
	dec .address+1
	dec .address
}

; define a pixel row of a C64 hardware sprite
!macro SpriteLine .v {
	!by .v>>16, (.v>>8)&255, .v&255
}

; general purpose copy memory routine
!macro CopyMemoryUp .fromStart, .fromEnd, .toStart {

ldy	#(.fromEnd - .fromStart + 1) % 256
.loop
.LoadLoc = *+1
lda .fromEnd

.StoreLoc = *+1
sta .toStart + (.fromEnd - .fromStart)
+dec16 .LoadLoc
+dec16 .StoreLoc
dey
bne .loop

lda .LoadLoc
sta .LoadBlockLoc
lda .LoadLoc+1
sta .LoadBlockLoc+1

lda .StoreLoc
sta .StoreBlockLoc
lda .StoreLoc+1
sta .StoreBlockLoc+1


ldx	#(.fromEnd - .fromStart + 1) / 256
; Y is already zero with the last DEY above
.loopBlock
.LoadBlockLoc = *+1
lda $0000				; Address is dummy, to be modified

.StoreBlockLoc = *+1
sta $0000				; Address is dummy, to be modified
+dec16 .LoadBlockLoc
+dec16 .StoreBlockLoc
dey
bne .loopBlock
dex
bne .loopBlock
}

; KERNAL ROUTUNES
;============================================================================
SCINIT = $FF81
CHROUT = $FFD2
GETIN  = $FFE4
SCNKEY =  $FF9F 