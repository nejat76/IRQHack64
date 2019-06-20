;###############################################################################
; SUBROUTINES
;###############################################################################

!zone printPage { 	

	;Prints the initial filenames that's added to the program by the micro.

printPage:

	LDX #COMMANDENTERMASK
	STX COMMANDBYTE
	;Onceki sayfanin icerigi temizlensin diye default 20'ye set ettim - nejat
	;ldx numberOfItems
	ldx #20
--	ldy #20
	.fetchPointer=*+1
-	lda itemList-1,y
	;petscii -> screen code - nejat
	cmp #$3f
	bmi +
	clc
	sbc #$3f
+
	.fillPointer=*+1
	sta SCREEN_RAM+121,y

	dey
	bne -

	clc
	lda .fetchPointer
	adc #32
	sta .fetchPointer
	lda .fetchPointer+1
	adc #00
	sta .fetchPointer+1

	clc
	lda .fillPointer
	adc #40
	sta .fillPointer
	lda .fillPointer+1
	adc #00
	sta .fillPointer+1

	dex
	bne --

	;Self modify ile deðiþmiþ adresleri tekrar init - nejat
	lda #<itemList-1
	sta .fetchPointer
	lda #>itemList-1
	sta .fetchPointer+1
	
	lda #<SCREEN_RAM+121
	sta .fillPointer
	lda #>SCREEN_RAM+121
	sta .fillPointer+1
	rts
}

;-------------------------------------------------------

!zone enter {
enter:

	;clear old coloring
	ldy #22
	lda #$0f
-	sta (activeMenuItemAddr),y
	dey
	bne -
	

	;Launches the selected item	

!if SIMULATION <> 1 {
	
	;Transfer starts with the lowest bit
	lda #$00
	sta BITPOS

	;Clear 8th bit of raster line
	lda #$7F
	and $D011
	sta $D011

	;Kill cia interrupts
	jsr killCIA

	;Decide if it's a file selection or special command (previous / next)
	lda COMMANDBYTE
	and #$40
	bne SPECIALCMD
	jsr GETCURRENTROW
	inx
	txa
	sec
	rol
	tax
	stx COMMANDBYTE

SPECIALCMD		
	; Last bit is not used and always sent as 1. This was tested to be less problematic.
	; Init code for S0 state is redundant in the code.
	SEC
	BCC S0INIT	

	;Raster interrupt to occur at A0 line.
S160INIT
	LDA #$7F
	AND $D011
	STA $D011 
	LDA #$A0
	STA $D012
	LDA #<IRQHANDLER2
	STA IRQVECTOR
	LDA #>IRQHANDLER2
	STA IRQVECTOR+1

WAITRASTER1 		;Wait till A1 line
	LDA $D012
	CMP #$A1
	BNE WAITRASTER1
		
	JMP ENABLERASTER	

S0INIT 				;S0	
	LDA #$7F
	AND $D011
	STA $D011 		
	LDA #$00
	STA $D012
	LDA #<IRQHANDLER1
	STA IRQVECTOR
	LDA #>IRQHANDLER1
	STA IRQVECTOR+1

WAITRASTER2
	LDA $D012
	CMP #$01
	BNE WAITRASTER2
	
ENABLERASTER	
	LDA #$01
	STA $D01A	;Enable raster interrupts
	CLI

	LDY #$00	
	CLV	
	STY BITTARGET

WAITIRQ 		; Wait till the command byte transferred to the micro
	BIT BITTARGET	
	BVC WAITIRQ	
	CLV	

; Command is transferred. Prepare loader for the transferring of the actual stuff
; If it's a program then micro resets c64 so below code is not relevant.
; If micro will be transferring a directory transfers a directory dump 	
	SEI
	JSR SETUPTRANSFER
	
; Init transfer variables that loader will use. 	
	JSR INITTRANSVAR
	LDY #$00	
	CLV	
	STY BITTARGET

; Wait signal from loader that the transfer is finished
WAITNMI
	BIT BITTARGET	
	BVC WAITNMI	
	CLV
	
	JSR ENDTRANSFER
	JSR ENABLEDISPLAY
	
	; Reset active menu item
	lda #00
	sta activeMenuItem
	lda #<COLOR_RAM+120
	sta activeMenuItemAddr
	lda #>COLOR_RAM+120
	sta activeMenuItemAddr+1
	
	jsr printPage ;Update the screen with the new content got from micro		
	jmp main
	cli
	;jmp INPUT_GET
  	
 	rts	

} else {

	lda #00
	sta activeMenuItem
	lda #<COLOR_RAM+120
	sta activeMenuItemAddr
	lda #>COLOR_RAM+120
	sta activeMenuItemAddr+1
	
	
	;Give the effect that the content was actually changing
	;If there is a . in the memory range of itemList change them to O
	;if there is a O then change them to .
	;Just two blocks of data changed to keep it simple

	lda #<itemList
	sta $fb
	lda #>itemList
	sta $fc
	ldx #$02
	ldy #$00
-	lda ($fb), y
	cmp #$2E  ;"."
	bne +
	lda #$4F  ;"O"
	clv		  
	bvc ++	  ;unconditional branch
+	
	cmp #$4F  ;"O"
	bne ++
	lda #$2E  ;"."
++
	sta ($fb), y
	iny
	bne -
	inc $fc
	dex
	bne -
				

	jsr printPage ;Update the screen with the new content got from micro		
	jmp main
	
	;simulation mode when cartridge is not available
	!set PC = *	
numberOfItems
	!by 20

numberOfPages
	!by 5

PAGEINDEX
	!by 1
	
TRANSFERMODE
	!by 1

itemList
	!scr "menu item 01 ..................."
	!scr "menu item 02 ..................."
	!scr "menu item 03 ..................."
	!scr "menu item 04 ..................."
	!scr "menu item 05 ..................."
	!scr "menu item 06 ..................."
	!scr "menu item 07 ..................."
	!scr "menu item 08 ..................."
	!scr "menu item 09 ..................."
	!scr "menu item 10 ..................."
	!scr "menu item 11 ..................."
	!scr "menu item 12 ..................."
	!scr "menu item 13 ..................."
	!scr "menu item 14 ..................."
	!scr "menu item 15 ..................."
	!scr "menu item 16 ..................."
	!scr "menu item 17 ..................."
	!scr "menu item 18 ..................."
	!scr "menu item 19 ..................."
	!scr "menu item 20 OOOOOOOOOOOOOOOOOOO"	

};end of else if

COMMANDBYTE !by 0
BITPOS !by 0

};end of zone

;-------------------------------------------------------
;IRQ Handlers
;-------------------------------------------------------
; Use IRQ as a covert channel to send selected file information
; Arduino has attached an interrupt on it's end 
; It will measure time between falling edges of IRQ

IRQHANDLER1
	SEI	
	ASL $D019	;Acknowledge interrupt
	LDA COMMANDBYTE
	LDY BITPOS					
	CPY #$08
	BEQ FINISHSENDING1
	INC BITPOS
	INY 

SHIFTBYTE1	
	LSR			;Move rightmost bit right moving it to carry
	DEY
	BNE SHIFTBYTE1
	BCC IRQHANDLE1CONT
	
	LDA #$7F
	AND $D011
	STA $D011 
			
	LDA #$A0
	STA $D012			
	LDA #<IRQHANDLER2
	STA IRQVECTOR
	LDA #>IRQHANDLER2
	STA IRQVECTOR+1

	CLI
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI

;-------------------------------------------------------

IRQHANDLE1CONT	

	LDA #$7F
	AND $D011
	STA $D011 
	LDA #$00
	STA $D012		

	CLI	
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI	
;-------------------------------------------------------

FINISHSENDING1

	LDA #$64
	STA BITTARGET		; Break foreground wait
	
	;LDA #$00
	;STA $D01A
		
	CLI
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI

;-------------------------------------------------------

IRQHANDLER2

	SEI
	ASL $D019	;Acknowledge interrupt
	LDA COMMANDBYTE
	LDY BITPOS					
	CPY #$08
	BEQ FINISHSENDING2
	INC BITPOS
	INY 

SHIFTBYTE2	

	LSR			;Move rightmost bit right moving it to carry
	DEY
	BNE SHIFTBYTE2
	BCC IRQHANDLE2CONT
	
	LDA #$7F
	AND $D011
	STA $D011 		
	LDA #$00
	STA $D012			
	LDA #<IRQHANDLER1
	STA IRQVECTOR
	LDA #>IRQHANDLER1
	STA IRQVECTOR+1
	
	
	CLI
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI	

;-------------------------------------------------------

FINISHSENDING2
	
	LDA #$64
	STA BITTARGET		; Break foreground wait
	
	;LDA #$00
	;STA $D01A
	
	;JMP $EA31
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI		

;-------------------------------------------------------

IRQHANDLE2CONT	

	LDA #$7F
	AND $D011
	STA $D011 
	LDA #$A0
	STA $D012		

		
	CLI	
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI		

;-------------------------------------------------------
;Other Subs
;-------------------------------------------------------

killCIA

	LDY #$7f    ; $7f = %01111111 
	STY $dc0d   ; Turn off CIAs Timer interrupts 
	STY $dd0d   ; Turn off CIAs Timer interrupts 
	LDA $dc0d   ; cancel all CIA-IRQs in queue/unprocessed 
	LDA $dd0d   ; cancel all CIA-IRQs in queue/unprocessed 
	RTS	

;-------------------------------------------------------	

DISABLEINTERRUPTS

	LDY #$7f    			; $7f = %01111111 
	STY $dc0d   			; Turn off CIAs Timer interrupts 
	STY $dd0d  				; Turn off CIAs Timer interrupts 
	LDA $dc0d  				; cancel all CIA-IRQs in queue/unprocessed 
	LDA $dd0d   			; cancel all CIA-IRQs in queue/unprocessed 
	;Change interrupt routines
	ASL $D019
	LDA #$00
	STA $D01A
	RTS

;-------------------------------------------------------	

GETCURRENTROW				; Input : None, Output : X (current row)
	LDX activeMenuItem
	RTS	

;-------------------------------------------------------

SETUPTRANSFER	

	JSR DISABLEINTERRUPTS
	JSR DISABLEDISPLAY
	LDA #$37
	STA $01	
	; Do not Disable kernal & basic rom	
	
	; Switch between 8byte & 4byte & 1byte transfer routine using micro supplied TRANSFERMODE value.
	LDY TRANSFERMODE
	LDA NMITAB, Y

	STA SOFTNMIVECTOR
	
	LDA #$80
	STA SOFTNMIVECTOR+1	
		
   	LDY #$00	;Setup for transfer routine   	   	
   	;JSR WAITLINE   	
	RTS

;-------------------------------------------------------

WAITLINE   	

   	LDA #$80
   	CMP $D012
   	BNE WAITLINE
   	JSR WASTELINES 
   	INY
   	BNE WAITLINE
   	RTS	
WASTELINES
	LDX #$00
CONSUME	
	NOP
	INX
	BNE CONSUME		
	RTS

;-------------------------------------------------------

INITTRANSVAR

	LDA #<MICROLOADSTART
	STA DATA_LOW
	STA ACTUAL_LOW
	LDA #>MICROLOADSTART
	STA DATA_HIGH
	STA ACTUAL_HIGH	
	LDA #$03
	STA DATA_LENGTH
	TAX		
	LDY #$00
	RTS

;-------------------------------------------------------

ENDTRANSFER

	LDA #<ROMNMIHANDLER
	STA SOFTNMIVECTOR
	LDA #>ROMNMIHANDLER
	STA SOFTNMIVECTOR+1
	RTS

;-------------------------------------------------------		

DISABLEDISPLAY

	LDA #$00
	STA $D015				;Disable sprites
	LDA #$0B				;%00001011 ; Disable VIC display until the end of transfer
	STA $D011	
	RTS

;-------------------------------------------------------

ENABLEDISPLAY
	LDA #$00
	STA $D020
	LDA #$FF
	STA $D015				;Enable sprites
	LDA #$1B				;%00001011 ; Disable VIC display until the end of transfer
	STA $D011	
	RTS				
	