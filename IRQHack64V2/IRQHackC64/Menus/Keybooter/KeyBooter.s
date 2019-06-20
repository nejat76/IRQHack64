; Key booter for IRQHack64
; 27/03/2016 - Istanbul

; An autoboot program for IRQHack64 to launch specific program from
; sd card that's mapped to the key pressed on power on.
; Wait's a predetermined time for a key to be pressed (defined in WAITTIME). 
; If 0..9 is pressed then the corresponding file is launched.
; If these keys are not pressed then c64 just resets.
.enc screen

;Kernal routines
CHROUT    	= $FFD2
GETIN 	  	= $FFE4
SCNKEY 		=  $FF9F 
RESETROUTINE = $FCE2
IRQVECTOR	= $0314
RASTERTIME	= $FB
WAITTIME	= 100

;Loader on the cartridge rom sets the 6th bit of this location. Which is tested by BIT $64
;command and waiting if overflow flag (which is the 6th bit of this location) is clear.
BITTARGET	= $64

;To keep it simple we will map number keys to different programs on the sd card

;VIC Border color
BORDER		= $D020

	*=$080E						  	  	  	  	

	JSR INIT		;Clears screen, disables interrupts.	
	JSR PRINTTITLE		;Prints title of the screen					
	LDA #WAITTIME
	STA RASTERTIME	; Determine WAITTIME frames delay for a key press
	
	
	;Start of main loop	
INPUT_GET
	; Wait for a specific raster line to wait for a key for 2 second
WAITRASTERFORTIMING	
	LDX $D012	
	CPX #$A0
	BNE WAITRASTERFORTIMING
	DEC RASTERTIME
	BNE KEYSCAN		; Check for timeout, keys we are interested are not pressed.	
TIMEOUT 
	JMP RESETROUTINE	
	
KEYSCAN	
	JSR SCNKEY		; Call kernal's key scan routine
 	JSR GETIN		; Get the pressed key by the kernal routine
  	BEQ INPUT_GET		; If zero then no key is pressed so repeat

	LDY  #$0B
KEYCOMPARE	
	CMP KEYS, Y
	BNE +
	LDA COMMANDS, Y
	STA COMMANDBYTE
	JMP ENTER	
+
	DEY
	BNE KEYCOMPARE
	JMP INPUT_GET

ENTER  	  
	;Transfer starts with the lowest bit
	LDA #$00
	STA BITPOS
	
	;Clear 8th bit of raster line
	LDA #$7F
	AND $D011
	STA $D011

	;Kill cia interrupts
	JSR KILLCIA

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
	
	;Wait till A1 line
WAITRASTER1
	LDA $D012
	CMP #$A1
	BNE WAITRASTER1
		
	JMP ENABLERASTER	
	
S0INIT	
	;-- S0 ---
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

	
	LDY #$00	
	CLV	
	STY BITTARGET
; Wait till the command byte transferred to the micro
WAITIRQ
	BIT BITTARGET	
	BVC WAITIRQ	
	CLV	
	

	CLC
INFINITE	
	BCC INFINITE		;At this point micro should be resetting the c64 and loading the actual stuff.
  	
	RTS	
	
			
; Use IRQ as a covert channel to send selected file information
; Arduino has attached an interrupt on it's end 
; It will measure time between falling edges of IRQ

IRQHANDLER1
	SEI	
	;INC $D020	
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

	;DEC $D020	
	CLI
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI
	
	
IRQHANDLE1CONT	
	LDA #$7F
	AND $D011
	STA $D011 
	LDA #$00
	STA $D012		

	;DEC $D020
	CLI	
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI	

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

IRQHANDLER2
	SEI
	;INC $D020	
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
	
	;DEC $D020
	
	CLI
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI	
	
	
IRQHANDLE2CONT	
	LDA #$7F
	AND $D011
	STA $D011 
	LDA #$A0
	STA $D012		

	;DEC $D020
		
	CLI	
	;JMP $EA31 
	PLA
	TAY
	PLA
	TAX
	PLA 
	RTI	

	
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

DISABLEDISPLAY
	LDA #$0B				;%00001011 ; Disable VIC display until the end of transfer
	STA $D011	
	RTS
ENABLEDISPLAY
	LDA #$1B				;%00001011 ; Disable VIC display until the end of transfer
	STA $D011	
	RTS	


PRINTTITLE	; Input : None, Changed : A, X
	LDX #$00
NEXTCHAR	
	LDA TITLE, X
	BEQ OUTTITLEPRINT
	STA $0404, X
	INX
	BNE NEXTCHAR
OUTTITLEPRINT
	RTS
	

COMMANDBYTE	.BYTE 0
BITPOS		.BYTE 0

KEYS		.BYTE	$00, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
COMMANDS	.BYTE	$00, $61, $63, $65, $67, $69, $6B, $6D, $6F, $71, $73
	
TITLE	
	.TEXT "IRQHACK64 AUTOBOOTER / BY I.R.ON"
	.BYTE 0
	

	