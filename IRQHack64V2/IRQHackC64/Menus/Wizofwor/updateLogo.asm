;###############################################################################
; show_logo.asm
; display sprite logo
;###############################################################################
!zone show_logo {
	;**********  increment animation counter *********
	inc spAnimationCounter
	lda spAnimationCounter
	cmp #64
	bne +
	lda #00
	sta spAnimationCounter
+	
	ldx spAnimationCounter
	lda spriteSinus,x
	sta var1

	;***********  color wash effect ******************
	inc spColorWashCounter
	lda spColorWashCounter
	cmp #128
	bne +
	lda #00
	sta spColorWashCounter
+	
	ldx spColorWashCounter
	lda spColorOffset,x
	tax

	lda spColor1,x 	;set sprite multicolor 1
	sta $d025	

	lda spColor2,x 	;set sprite multicolor 2
	sta $d026

	ldy #$08	;set sprite colors
	lda spColor3,x
-	sta $d026,y
	dey
	bne -

	;********** print first and second row ***********
	lda #60 		;wait for raster
-	cmp $d012
	bne -

	;set sprite pointers
	lda #spriteBase/$40
	jsr .setSpritePointers

	;set spriteX
	jsr .setSpriteX

	;set sprite Y
	lda spriteY+0
	ldy spriteY+1
	jsr .setSpriteY

	;*********** print third and fourth row **********
	lda #106 		;wait for raster
-	cmp $d012
	bne -

	;increase swing offset
	ldx spAnimationCounter
	lda spriteSinus+21,x
	sta var1

	;set sprite pointers
	lda #spriteBase/$40+8
	jsr .setSpritePointers

	;set sprite X
	jsr .setSpriteX

	;mind the gap :)
	dec $d000 	
	dec $d000
	dec $d008
	dec $d008

	;set sprite Y
	lda spriteY+2
	ldy spriteY+3
	jsr .setSpriteY

	;********* print Fifth & sixth row ***************
	lda #153 		;wait for raster
-	cmp $d012
	bne -

	;set sprite pointers
	lda #spriteBase/$40+16
	jsr .setSpritePointers

	;increase swing offset
	ldx spAnimationCounter
	lda spriteSinus+42,x
	sta var1

	;set sprite X
	jsr .setSpriteX

	;set sprite Y
	lda spriteY+4
	ldy spriteY+5
	ldx #4
	jsr .setSpriteY



	jmp .end ;skip subroutines

	;********* Subroutines *************************
.setSpriteX
	ldx #$00
	ldy #$00
-	clc
	lda spriteX,x
	adc var1 
	sta $d000,y
	sta $d008,y
	iny
	iny
	inx
	cpx #04
	bne -
	rts

.setSpriteY	
	sta $d001
	sta $d003
	sta $d005
	sta $d007
	sty $d009
	sty $d00b
	sty $d00d
	sty $d00f
	rts

.setSpritePointers
	ldx #$00
	;lda #spriteBase/$40
-	sta $07f8,x
	clc
	adc #$01 
	inx 
	cpx #08
	bne -	
	rts

	;********* end *************************
.end
}