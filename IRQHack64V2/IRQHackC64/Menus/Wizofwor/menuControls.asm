;##############################################################################
; IRQHack64 Cartridge Main Menu - by wizofwor
; Menu Controls
;##############################################################################

!zone keyboardScan {

.keyboardScan:

	jsr SCNKEY		; Call kernal's key scan routine
 	jsr GETIN		; Get the pressed key by the kernal routine
 	cmp #$2d 		; IF char is '-'
 	beq .down 		; go down in menu
 	cmp #$2b 		; IF char is '+'
 	beq .up 		; go up in menu
 	cmp #$2e 		; IF char is '>'
 	beq .nextPage 	; request next page from micro
 	cmp #$2c 		; IF char is '<'
 	beq .prevPage 	; request previous page from micro
 	cmp #$0d 		; IF char is 'ENTER'
 	beq j1 			; launch selected item
    cmp #$0f 		; IF char is 'F'
    ;beq .simulation ; Display simulation menu
 	jmp .end

.nextPage:

	ldx PAGEINDEX
	inx
	cpx numberOfPages	  	
	bcc .execNext	;BLT
	jmp .end
	
.execNext:

	inc PAGEINDEX
	ldx #COMMANDNEXTPAGE
	stx COMMANDBYTE
	jmp j1
	
.prevPage

	ldx PAGEINDEX
	bne .execPrev
	jmp .end
	
.execPrev

	dec PAGEINDEX
	ldx #COMMANDPREVPAGE
	stx COMMANDBYTE	
	
j1: jmp enter

.down

	;clear old coloring
	ldy #22
	lda #$0f
-	sta (activeMenuItemAddr),y
	dey
	bne -

	;increment ACTIVE_ITEM
	ldx numberOfItems 	;check if the cursor is
	dex 				;already at end of page
	cpx activeMenuItem 	
	beq .end
	inc activeMenuItem

	clc
	lda activeMenuItemAddr
	adc #40
	sta activeMenuItemAddr
	lda activeMenuItemAddr+1
	adc #00
	sta activeMenuItemAddr+1

	jmp .end

.up

	;clear old coloring
	ldy #22
	lda #$0f
-	sta (activeMenuItemAddr),y
	dey
	bne -

	;decrement ACTIVE_ITEM
	lda #00 			;check if the cursor is
	cmp activeMenuItem 	;already at end of page
	beq .end
	dec activeMenuItem

	sec
	lda activeMenuItemAddr
	sbc #40
	sta activeMenuItemAddr
	lda activeMenuItemAddr+1
	sbc #00
	sta activeMenuItemAddr+1

	jmp .end 	

.end

}

!zone colorwash {
	ldy #22
	lda #$07
-	sta (activeMenuItemAddr),y
	dey
	bne -
}