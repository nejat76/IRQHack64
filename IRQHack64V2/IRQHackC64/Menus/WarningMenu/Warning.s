; Default menu on IRQHack64
; 23/05/2016 - Istanbul

.enc screen

;Kernal routines
CHROUT    	= $FFD2
GETIN 	  	= $FFE4
SCNKEY 		=  $FF9F 
RESETROUTINE = $FCE2
IRQVECTOR	= $0314
RASTERTIME	= $FB
WAITTIME	= 100

;VIC Border color
BORDER		= $D020

;Loader on the cartridge rom sets the 6th bit of this location. Which is tested by BIT $64
;command and waiting if overflow flag (which is the 6th bit of this location) is clear.
BITTARGET	= $64

	*=$080E						  	  	  	  	

	JSR INIT		;Clears screen, disables interrupts.		
	JSR PRINTTITLE		
	JSR PRINTTITLE2		
LOOP
	JMP LOOP

INIT		; Input : None, Changed : A
	CLD
	LDA #$93
	JSR CHROUT
	LDA #$00 
	STA $D020
	LDA #$0B
	STA $D021
	JSR INITPC
		
	JSR DISABLEINTERRUPTS		
	JSR KILLCIA
		
	RTS

INITPC
	LDX #$00
	LDA #$0F
CBL
	STA $D800,X
	STA $D900,X
	STA $DA00,X
	STA $DB00,X	
	INX
	BNE CBL
	RTS
	
KILLCIA
	;LDA #$00
	;STA ISMUSICPLAYING
	LDY #$7f    ; $7f = %01111111 
    STY $dc0d   ; Turn off CIAs Timer interrupts 
    STY $dd0d   ; Turn off CIAs Timer interrupts 
    LDA $dc0d   ; cancel all CIA-IRQs in queue/unprocessed 
    LDA $dd0d   ; cancel all CIA-IRQs in queue/unprocessed 
	RTS	

DISABLEINTERRUPTS
    LDY #$7f    				; $7f = %01111111 
    STY $dc0d   				; Turn off CIAs Timer interrupts 
    STY $dd0d  				; Turn off CIAs Timer interrupts 
    LDA $dc0d  				; cancel all CIA-IRQs in queue/unprocessed 
    LDA $dd0d   				; cancel all CIA-IRQs in queue/unprocessed 
	
					
; 	Change interrupt routines
	ASL $D019
	LDA #$00
	STA $D01A
	RTS


PRINTTITLE	; Input : None, Changed : A, X
	LDX #$00
NEXTCHAR	
	LDA TITLE1, X
	BEQ OUTTITLEPRINT
	STA $0568, X
	INX
	BNE NEXTCHAR
OUTTITLEPRINT
	RTS
	
PRINTTITLE2	; Input : None, Changed : A, X
	LDX #$00
NEXTCHAR2	
	LDA TITLE2, X
	BEQ OUTTITLEPRINT2
	STA $05E0, X
	INX
	BNE NEXTCHAR2
OUTTITLEPRINT2
	RTS	
	
	
TITLE1	
	.TEXT "- YOU SHOULD PLACE IRQHACK64.PRG ON SD  CARD!"
	.BYTE 0
	
TITLE2
	.TEXT "- SD KARTA IRQHACK64.PRG DOSYASINI       YERLESTIRMELISIN!"
	.BYTE 0	
	

	