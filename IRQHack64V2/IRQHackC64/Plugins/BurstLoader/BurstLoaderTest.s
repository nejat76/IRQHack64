; BurstLoader video displayer for IRQHack64
; 14/07/2016 - Istanbul

;.enc screen

ACTUAL_LOW		= $6C
ACTUAL_HIGH		= $6D

INITIALWAITTIME = 150

;Kernal routines
CHROUT    	= $FFD2
SOFTNMIVECTOR	= $0318
IRQVECTOR	= $0314
IRQ6502			= $FFFE
NMI6502			= $FFFA

STARTRASTER		= 241

;VIC Border color
BORDER		= $D020
SCREEN		= $D021
BITTARGET = $64
CASSETTEBUFFER = $033C
FILENAMESHADOW = $FF00

FG_GATE = $64

PICTUREROW = 3

DELAYFRAMES	.macro
	LDX #\1
	JSR WAITFRAMES
	.endm



	*=$080E	
	JSR IRQ_DisableDisplay			
	JSR INIT				;Clears screen, disables interrupts.	
	JSR IRQ_StartTalking	
	


	;JMP ZIBIRT				;For testing in VICE 

	DELAYFRAMES 1
	; Copy filename from kernal ram area to cassette buffer (possibly useless)
	LDX #32
-	
	LDA FILENAMESHADOW, X
	STA CASSETTEBUFFER, X
	DEX
	BNE - 
	LDA #$37
	STA $01
	LDX #<VIDEOFILE		;CASSETTEBUFFER	
	LDY #>VIDEOFILE		;CASSETTEBUFFER
	LDA #31
	JSR IRQ_SetName
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC +
	JMP ERROR_OPENING_FILE

	
+
	DELAYFRAMES 2
	LDA #50
	JSR IRQ_NIStream
	DELAYFRAMES 2
	
ZIBIRT
	JSR IRQ_EnableDisplay
			
		
		

WAIT
	JSR minikey
  	BEQ WAIT
	
	JSR IRQ_DisableDisplay
	DELAYFRAMES 2	
	
	JSR NMI_000
	
	JSR DisplayReceived
	DELAYFRAMES 50

	JSR IRQ_EnableDisplay
	JMP WAIT
			
	
	
WAITFRAMES
FD
	LDY #$90
-	
	CPY $D012
	BNE -
	LDY #50
-	
	DEY
	BNE - 
	
	DEX
	BNE FD
	RTS

			

INIT		; Input : None, Changed : A
	CLD
	LDA #$93
	JSR CHROUT
	LDA #$00 
	STA $D020
	LDA #$0B
	STA $D021
		
	JSR IRQ_DisableInterrupts
		
	RTS

INC16	.macro
	INC \1
	BNE +
	INC \1 + 1
+	
	.endm

DUMPHEX	.macro
	; \1 -> source addresses
	; \2 -> dump destination
	; \3 -> length
	
	; Init self modified addresses	
	LDA #<\1
	STA DATASOURCE+1
	
	LDA #<\2
	STA HNIBBLESTORE+1
	
	LDA #<\2 + 1
	STA LNIBBLESTORE+1	

	LDA #>\1
	STA DATASOURCE+2
	LDA #>\2
	STA HNIBBLESTORE+2
	LDA #>\2
	STA LNIBBLESTORE+2
	
	LDY #0
-	
DATASOURCE	
	LDA \1,Y
	JSR GetHigh
HNIBBLESTORE	
	STA \2
	
	LDA \1,Y
	JSR GetLow
LNIBBLESTORE
	STA \2 + 1

	INC16 HNIBBLESTORE+1
	INC16 HNIBBLESTORE+1
	INC16 LNIBBLESTORE+1
	INC16 LNIBBLESTORE+1
	INY
	CPY #\3
	BNE - 
	.endm	
	
	; X have first byte, 	Y have second byte
DisplayReceived
	;Read through C000-C190 Dump each byte to screen in hexadecimal
	;DUMPHEX $2000, $0400, $08	
	DUMPHEX $2000, $0400, $00	
	
	DUMPHEX $2100, $0600, $90
	
	RTS
	

GetHigh
	LSR
	LSR
	LSR
	LSR
	TAX
	LDA  HEXTOSCREEN, X
	RTS

GetLow
	AND #$0F
	TAX
	LDA  HEXTOSCREEN, X
	RTS
	
minikey:
	lda #$0
	sta $dc03	; port b ddr (input)
	lda #$ff
	sta $dc02	; port a ddr (output)
			
	lda #$00
	sta $dc00	; port a
	lda $dc01       ; port b
	cmp #$ff
	beq nokey
	; got column
	tay
			
	lda #$7f
	sta nokey2+1
	ldx #8
nokey2:
	lda #0
	sta $dc00	; port a
	
	sec
	ror nokey2+1
	dex
	bmi nokey
			
	lda $dc01       ; port b
	cmp #$ff
	beq nokey2
			
	; got row in X
	txa
	ora columntab,y
	sec
	rts
			
nokey:
	clc
	rts

columntab:
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $70
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $60
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $50
.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,$FF, $FF, $FF, $FF,$FF, $FF, $FF, $40,$FF, $FF, $FF, $FF, $FF, $FF, $FF, $30,$FF, $FF, $FF, $20,$FF, $10, $00, $FF

HEXTOSCREEN
	.BYTE 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 1, 2, 3, 4, 5, 6

VIDEOFILE	
	.TEXT "BADAPPLE.CVID"
	.BYTE  0

	
; We do nothing at the moment	
PETGLPLUGINREAD			; TODO : Remove
ERROR_OPENING_FILE	
	JMP *
	
	
.include "..\..\Loader\CartLib.s"	
.include "MyCartLibHi.s"
.include "Common.65s"
   
	
ENDOFEXECUTABLE			
	
; * = $C1A0
 * = $4000
 .include "NMI.65s"	
 RTS
 * = $2000 
 .BYTE 1, 2, 3, 4, $11, $12, $13, $14
 
 

	
