;--------------------------------------------------
; SET SCREEN
;--------------------------------------------------
	;set colors
	lda #$00	;Set border
	sta $d020
	lda #$00    ;Set bg#00
	sta $d021
	lda #$03	;Set bg#01
	sta $d022
	lda #$0d	;Set bg#02
	sta $d023

; -------------------------------------------------------------
;Organize memory by moving stuff to their original locations
; -------------------------------------------------------------
	+CopyMemoryUp fileNameDataActual, fileNameDataActualEnd, fileNameData
	+CopyMemoryUp charsetBaseActual, charsetBaseActualEnd, charset_data
	+CopyMemoryUp spriteBaseActual, spriteBaseActualEnd, spriteBase
	+CopyMemoryUp musicActual, musicActualEnd, music	
	
	
;	+CopyMemoryUp fileNameDataActual, fileNameDataActualEnd, fileNameData
;	+CopyMemoryUp musicActual, musicActualEnd, music			
;	+CopyMemoryUp charsetBaseActual, charsetBaseActualEnd, charset_data
;	+CopyMemoryUp spriteBaseActual, spriteBaseActualEnd, spriteBase

	
	;copy character set data
	ldx #$00
-	lda charset_data,x
	sta CHARSET,x
	lda charset_data+$ff,x
	sta CHARSET+$ff,x
	lda charset_data+$1fe,x
	sta CHARSET+$1fe,x
	lda charset_data+$2fd,x
	sta CHARSET+$2fd,x
	lda charset_data+$3fc,x
	sta CHARSET+$3fc,x
	inx
	cpx #$ff
	bne -

	lda #$1b		;set VIC pointers
	sta $d018 		;screen ram is at $0400, charset is at $2800-$2fff

	lda #$08		;switch to hires
	and $d016
	sta $d016

	
!zone initialScreenValues {		;copy initial screen values
.fetchNewData:
	;***read***
	.fetchPointer1=*+1 	;read repeat value 
	ldx repeat_bytes 	;x=repeat value
	beq .end 			;finish copying if x=0

	.fetchPointer2=*+1 	
	lda char_bytes 		;A=char value
	.fetchPointer3=*+1 
	ldy color_bytes 	;Y=color value

	;***copy***
	.charFillPointer=*+1
-	sta SCREEN_RAM
	.colorFillPointer=*+1
	sty COLOR_RAM
	+inc16 .charFillPointer
	+inc16 .colorFillPointer

	dex
	bne -

	;***increment pointers***
	+inc16 .fetchPointer1
	+inc16 .fetchPointer2
	+inc16 .fetchPointer3

	jmp .fetchNewData
.end	
}
	;***Print title
	ldy TRANSFERMODE
	BNE .printTurboTitle
	ldx #00
-	lda title,x
	sta SCREEN_RAM+41,x
	inx
	cpx #18
	bne -
	jmp .outTitlePrint
	
.printTurboTitle
	ldx #00
-	lda titleTurbo,x
	sta SCREEN_RAM+41,x
	inx
	cpx #18
	bne -	
.outTitlePrint
	;***Print initial filenames
	jsr printPage

	;***initialize color wash effect for active menu item
	lda #00
	sta activeMenuItem
	lda #<COLOR_RAM+120
	sta activeMenuItemAddr
	lda #>COLOR_RAM+120
	sta activeMenuItemAddr+1


;--------------------------------------------------
; SPRITES
;--------------------------------------------------	
	lda #$ff	
	sta $d015	;enable all sprites
	sta $d01c	;enable multicolor for all

	lda #$00	;undo sprite extend
	sta $d017
	sta $d01d

	lda #$01 	;set sprite multicolor 1
	sta $d025	

	lda #$06 	;set sprite multicolor 2
	sta $d026

	ldx #$08	;set sprite colors
	lda #$0e
-	sta $d026,x
	dex
	bne -

	lda #%11101110
	sta $d010	;sprite-x in second page

	lda #$00
	sta spAnimationCounter

;--------------------------------------------------
; MUSIC
;--------------------------------------------------	
	lda #$00
	jsr music 		;initialize music


;--------------------------------------------------
; INTERRUPTS
;--------------------------------------------------

	sei

	LDY #$7f    	; $7f = %01111111 
    STY $dc0d   	; Turn off CIAs Timer interrupts 
    STY $dd0d  		; Turn off CIAs Timer interrupts 
    LDA $dc0d  		; cancel all CIA-IRQs in queue/unprocessed 
    LDA $dd0d   	; cancel all CIA-IRQs in queue/unprocessed 

    ;Change interrupt routines
	ASL $D019
	LDA #$00
	STA $D01A

	;cli
	
	
	
