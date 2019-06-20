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

TRANSFERBUFFER = $A000

DELAYFRAMES	.macro
	LDX #\1
	JSR WAITFRAMES
	.endm



	*=$080E	
	JSR IRQ_DisableDisplay		
	JSR INIT				;Clears screen, disables interrupts.	
	JSR IRQ_StartTalking	
	.CHANGEBANK 2	
	
	JSR INIT_GFX_MEM
	JSR SET_LO_COLOR
	JSR SET_HI_COLOR
	JSR SETMULTICOLOR
	
	LDA #$00
	STA $D01A
	STA $D015	

	;JMP ZIBIRT				;For testing in VICE 
	LDA #$35
	STA $01
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
	JSR ENABLEDISPLAY		;JSR IRQ_EnableDisplay

	
	
	JSR PREPAREJMPTAB	
	;JSR INITIALWAIT
	
	LDA $d011                     ; clear high bit of raster line
	AND #$7f
	STA $d011		
	
	LDA #STARTRASTER
	STA $D012

	LDA #<SIMPLEHANDLER
	STA IRQ6502
	LDA #>SIMPLEHANDLER
	STA IRQ6502+1
	
	
		
	LDA #$35
	STA $01
	
	LDY #$00
	LDX #$00
	
	LDA #$00
	STA FG_GATE	
	
	LDA #$01
	STA $D01A	
	CLI
AGAIN	

	CLV
	
LOOP 	
	BIT FG_GATE
	; A taken branch can't be interrupted by an NMI - http://forum.6502.org/viewtopic.php?f=4&t=1634&start=15	
	; We are using non branching instruction... while interruptable BVS will not branch.
	; Jitter will be 2 or 3 cycles
	BVS EXIT		
	JMP LOOP
EXIT
	LDA #$37			
	STA $01	
	LDA #$01
	STA BORDER
	JSR NMI_000			; Do the transfer job (9985482)
	;JSR TRANSFERROUTINE
	;Acknowledge transfer			(9988949)  --> 3467 cycle
	LDA #$00
	STA BORDER	
		
	LDA #$00
	STA FG_GATE
	
	LDA #$35
	STA $01	
	
	DEC BORDER

	
	;
	;
	
	;At this point Raster moved to $20 or so and this foreground task has time to do something for the
	;last transferred 400 byte at $C000
	;The format of this data is
	;160x8 multicolor bitmap data = 320 bytes 
	;40 bytes screen color data
	;40 bytes d800 colors
	;bitmap data will be copied to current bank at current location
	;screen color data will be copied to screen memory to current bank at current location
	;D800 colors will be cached in a buffer for the initial 9 transfers. On last transfer cache will be copied to $d800 along with the 40 byte of the 
	;10th transfer
	
	;At this point both X and Y registers are free and unused by both NMI and IRQ handlers.
	;We have around 12000 cycles to complete our job.
	
	LDA #05
	STA BORDER
.include "FGStuff.s"

OUTCOPY	
	LDA #00
	STA BORDER

	INY
	CPY #20
	BNE +
	LDY #$00
+	
	JMP AGAIN
	
;TRANSFERROUTINE
;	LDX #$00
;-	
; 	BIT MODULATION_ADDRESS
;	NOP	
;	LDA CARTRIDGE_BANK_VALUE
;	STA $C000,X		
;	INX
;	BNE - 

;	TYA
;	PHA
;	LDY #$90
;-		
; 	BIT MODULATION_ADDRESS
;	INX
;	LDA CARTRIDGE_BANK_VALUE
;	STA $C0FF,X		
;	DEY
;	BNE -
	
;	PLA
;	TAY	
;	RTS	
	
SIMPLEHANDLER
	NOP	
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	LDA #$64
	STA FG_GATE			; Let foreground task unleash
	ASL $D019			; Acknowledge interrupt
	LDA #1
	STA $D01A
	
	RTI	
	
	
	
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

	
;WASTELINES
;	LDX #20
;CONSUME	
;	DEX
;	BNE CONSUME		
;	RTS	


;INITIALWAIT
;	LDY #INITIALWAITTIME	
;-	
;	LDA $D012
;	BNE -
;	JSR WASTELINES
;	DEY 
;	BNE -
;	RTS	
	
	

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
	
; We do nothing at the moment	
PETGLPLUGINREAD			; TODO : Remove
ERROR_OPENING_FILE	
	JMP *
	

	
COPYCOLOR
.for line = 0,line<9,line=line+1
	.for src = 0, src<40, src = src + 1
		LDA COLORBUFFER+line*40 + src
		STA $D800 + (PICTUREROW + line*2)*40 + src
		STA $D800 + (PICTUREROW + line*2 + 1)*40 + src		
	.next
.next

.for line = 9,line<10,line=line+1
	.for src = 0, src<40, src = src + 1
		LDA TRANSFERBUFFER + $168+src
		STA $D800 + (PICTUREROW + line*2)*40 + src
		STA $D800 + (PICTUREROW + line*2 + 1)*40 + src	
	.next
.next

	RTS	
	
.include "..\..\Loader\CartLib.s"	
.include "MyCartLibHi.s"

VIDEO_B0 = PICTURE_LO 

VIDEO_B1 = PICTURE_HI 
   
ENDOFEXECUTABLE			

COLORBUFFER	= $4000

* = $4190


VIDEOFILE	
	.TEXT "BADAPPLE.CVID"
	.BYTE  0
	
.include "Common.s"


; * = $C1A0
 * = $C000
.include "NMI.s"	  
	RTS


 
	
