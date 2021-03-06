PICTURE_LO = $2000
SCREEN_LO = $0400
PICTURE_HI = $6000 
SCREEN_HI = $4400

;KILLCIA
;	LDY #$7f    ; $7f = %01111111 
;    STY $dc0d   ; Turn off CIAs Timer interrupts 
;    STY $dd0d   ; Turn off CIAs Timer interrupts 
;    LDA $dc0d   ; cancel all CIA-IRQs in queue/unprocessed 
;    LDA $dd0d   ; cancel all CIA-IRQs in queue/unprocessed 
;	RTS	

;DISABLERASTERIRQ
;	LDA #$00
;	STA $D01A
;	RTS

;ENABLEIRQ
;	LDA #$3B	
;	STA $D011
;	LDA #$01
;	STA $D01A
;	RTS

;DISABLEDISPLAY
;	LDA #$0B				;%00001011 ; Disable VIC display until the end of transfer
;	STA $D011	
;	RTS
	
ENABLEDISPLAY
	LDA #$3B				
	STA $D011	
	RTS

SET_LO_COLOR
	LDA #$00
	STA $D020		;00 pixel value
	LDA #$00
	STA $D021		;00 pixel value  - BLACK
	LDX #$00
-	
	LDA #$BF		;01 pixel value = Dark Gray / 10 pixel value = Light Gray
	STA $0400, X
	STA $0500, X
	STA $0600, X
	STA $06E8, X	
	LDA #$01		;11 pixel value = White
	STA $D800, X
	STA $D900, X
	STA $DA00, X
	STA $DAE8, X
	INX
	BNE -
	RTS

SET_HI_COLOR
	LDA #$00
	STA $D020		;00 pixel value
	LDA #$00
	STA $D021		;00 pixel value  - BLACK
	LDX #$00
-	
	LDA #$BF		;01 pixel value = Dark Gray / 10 pixel value = Light Gray
	STA $4400, X
	STA $4500, X
	STA $4600, X
	STA $46E8, X	
	LDA #$01		;11 pixel value = White
	STA $D800, X
	STA $D900, X
	STA $DA00, X
	STA $DAE8, X
	INX
	BNE -
	RTS	

INIT_GFX_MEM
	LDX #$00
	LDA #$00
-	
	STA PICTURE_LO, X
	STA PICTURE_LO + $100, X
	STA PICTURE_LO + $200, X
	STA PICTURE_LO + $300, X
	STA PICTURE_LO + $400, X
	STA PICTURE_LO + $500, X
	STA PICTURE_LO + $600, X
	STA PICTURE_LO + $700, X
	STA PICTURE_LO + $800, X
	STA PICTURE_LO + $900, X
	STA PICTURE_LO + $a00, X
	STA PICTURE_LO + $b00, X
	STA PICTURE_LO + $c00, X
	STA PICTURE_LO + $d00, X	
	STA PICTURE_LO + $e00, X	
	STA PICTURE_LO + $f00, X	
	STA PICTURE_LO + $1000, X	
	STA PICTURE_LO + $1100, X	
	STA PICTURE_LO + $1200, X	
	STA PICTURE_LO + $1300, X	
	STA PICTURE_LO + $1400, X	
	STA PICTURE_LO + $1500, X		
	STA PICTURE_LO + $1600, X		
	STA PICTURE_LO + $1700, X	
	STA PICTURE_LO + $1800, X		
	STA PICTURE_LO + $1900, X	
	STA PICTURE_LO + $1A00, X
	STA PICTURE_LO + $1B00, X
	STA PICTURE_LO + $1C00, X
	STA PICTURE_LO + $1D00, X
	STA PICTURE_LO + $1E00, X
	STA PICTURE_LO + $1F00, X
	
	INX
	BNE -
	
	
	LDX #$00
	LDA #$00
-	
	STA PICTURE_HI, X
	STA PICTURE_HI + $100, X
	STA PICTURE_HI + $200, X
	STA PICTURE_HI + $300, X
	STA PICTURE_HI + $400, X
	STA PICTURE_HI + $500, X
	STA PICTURE_HI + $600, X
	STA PICTURE_HI + $700, X
	STA PICTURE_HI + $800, X
	STA PICTURE_HI + $900, X
	STA PICTURE_HI + $a00, X
	STA PICTURE_HI + $b00, X
	STA PICTURE_HI + $c00, X
	STA PICTURE_HI + $d00, X	
	STA PICTURE_HI + $e00, X	
	STA PICTURE_HI + $f00, X	
	STA PICTURE_HI + $1000, X	
	STA PICTURE_HI + $1100, X	
	STA PICTURE_HI + $1200, X	
	STA PICTURE_HI + $1300, X	
	STA PICTURE_HI + $1400, X	
	STA PICTURE_HI + $1500, X		
	STA PICTURE_HI + $1600, X		
	STA PICTURE_HI + $1700, X	
	STA PICTURE_HI + $1800, X		
	STA PICTURE_HI + $1900, X	
	STA PICTURE_HI + $1A00, X
	STA PICTURE_HI + $1B00, X
	STA PICTURE_HI + $1C00, X
	STA PICTURE_HI + $1D00, X
	STA PICTURE_HI + $1E00, X
	STA PICTURE_HI + $1F00, X
	
	INX
	BNE -
	
	RTS


SETMULTICOLOR
;Enable bitmap
	LDA #$3B
	STA $D011

; Enable MultiColor
	LDA #$D8
	STA $D016

; Bank select for screen & bitmap
	LDA #$18
	STA $D018

	RTS


CHANGEBANK	.macro
	LDA $DD00
	AND #%11111100
	ORA #\1
	STA $DD00
	.endm
	