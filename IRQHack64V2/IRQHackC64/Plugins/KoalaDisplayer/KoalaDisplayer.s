; KOALA displayer plugin for IRQHack64V2
; 15/08/2018 - Istanbul
; I.R.on


.enc screen

;Kernal routines
CHROUT    	= $FFD2
GETIN 	  	= $FFE4
SCNKEY 		=  $FF9F 
RESETROUTINE = $FCE2
SOFTNMIVECTOR	= $0318
IRQVECTOR	= $0314
IRQ6502			= $FFFE
;VIC Border color
BORDER		= $D020
SIDLOAD		= $E000

FILENAME = $033C

DEBUG = 0

PRINTSTATUSANDWAIT	.macro
.if DEBUG = 1
	PRINTSTATUS \1
	DELAYFRAMES \2	
.else
	DELAYFRAMES 1
.endif	
	.endm
	

DELAYFRAMES	.macro
.if DEBUG = 1
	LDX #\1
	JSR WAITFRAMES
.endif	
	.endm
		
PRINTSTATUS	.macro
	LDA #$20
	LDX #40
-	
	STA $0400, X
	DEX
	BNE -
NEXTCHAR	
	LDA \1, X
	BEQ OUTPRINT
	CMP #$3F
	BMI NOTSPACE
	CLC
	SBC #$3f
NOTSPACE	
	STA $0400, X
	INX
	BNE NEXTCHAR
OUTPRINT
	.endm
	
	*=$C000
	JMP MAIN
	
MAIN	
	JSR INIT		;Clears screen, disables interrupts.	
;	JSR DISPLAYPICTURE	
;-	
;	JMP -

	DELAYFRAMES 100
	PRINTSTATUSANDWAIT INITTEXT, 100	
	DELAYFRAMES 250
	
ALTENTRY	

;Lets try to open a file
	PRINTSTATUSANDWAIT OPENINGFILE, 100
	JSR IRQ_DisableDisplay		
	LDX #<FILENAME	
	LDY #>FILENAME
	LDA #31
	JSR IRQ_SetName
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC OPENINGCONT
	JMP ERROR_OPENING_FILE
OPENINGCONT	
	JSR IRQ_EnableDisplay
	
	PRINTSTATUSANDWAIT OPENINGSUCCESS, 200
	;JMP FILEREAD
	PRINTSTATUSANDWAIT READINGFILE, 200

	LDA #<PICTURE-2
	STA IRQ_DATA_LOW
	LDA #>PICTURE-2
	STA IRQ_DATA_HIGH
	LDA #40
	STA IRQ_DATA_LENGTH
	
	LDA #<(FILEREAD-1)
	STA IRQ_CALLBACK_LO
	LDA #>(FILEREAD-1)
	STA IRQ_CALLBACK_HI
	
	JSR IRQ_DisableDisplay
	LDY #$00
	JSR IRQ_ReadFile
	BCS ERRORREADING
	
	PRINTSTATUSANDWAIT CLOSINGFILE, 250	
	PRINTSTATUSANDWAIT CLOSINGFILE, 250	
	JSR IRQ_CloseFile
	BCS ERRORCLOSING
	
CONTINUE	
	PRINTSTATUSANDWAIT FILECLOSED, 200	
	JMP INPUT_GET
ERRORCLOSING
	JSR IRQ_EnableDisplay
	PRINTSTATUSANDWAIT ERRORCLOSINGFILE, 100		
	JMP EXITFAIL
INPUT_GET
	JSR SCNKEY		; Call kernal's key scan routine
 	JSR GETIN		; Get the pressed key by the kernal routine
  	BEQ INPUT_GET		; If zero then no key is pressed so repeat
	
EXITFAIL	
	JSR IRQ_DisableDisplay
	JSR IRQ_ExitToMenu

	JMP INPUT_GET
	
	
ERRORREADING	
	JSR IRQ_EnableDisplay
	PRINTSTATUSANDWAIT READINGFAILED, 200		
	JMP EXITFAIL
	
ERROR_OPENING_FILE	
	JSR IRQ_EnableDisplay
	PRINTSTATUSANDWAIT OPENINGFILEFAILED, 200		
	JMP EXITFAIL	
	
PETGLPLUGINREAD	
FILEREAD
	NOP
	JSR IRQ_EnableDisplay

	
	JSR VIEWKOALA
	
	CLC		;Signal no error
	RTS
	

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
	LDA #$3B				
	STA $D011	
	RTS	

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

PICTURE = $2000
 BITMAP = PICTURE
 VIDEO = PICTURE+$1f40
 COLOR = PICTURE+$2328
 BACKGROUND = PICTURE+$2710	
	
	
VIEWKOALA
 lda #$00
 sta $d020 ; Border Color
 lda BACKGROUND
 sta $d021 ; Screen Color

 ; Transfer Video and Color 
 ldx #$00
LOOPTRANSFER
 ; Transfers video data
 lda VIDEO,x
 sta $0400,x
 lda VIDEO+$100,x
 sta $0500,x
 lda VIDEO+$200,x
 sta $0600,x
 lda VIDEO+$2e8,x
 sta $06e8,x
 ; Transfers color data
 lda COLOR,x
 sta $d800,x
 lda COLOR+$100,x
 sta $d900,x
 lda COLOR+$200,x
 sta $da00,x
 lda COLOR+$2e8,x
 sta $dae8,x
 inx
 bne LOOPTRANSFER
 ;
 ; Bitmap Mode On
 ;
 lda #$3b
 sta $d011
 ;
 ; MultiColor On
 ;
 lda #$d8
 sta $d016
 ;
 ; When bitmap adress is $2000
 ; Screen at $0400 
 ; Value of $d018 is $18
 ;
 lda #$18
 sta $d018
 
	

	RTS
	
	
	
INITTEXT
	.TEXT "IRQHACK64V2 KOALA PLUGIN"
	.BYTE 0	
	
SENDSTARTTALKING
	.TEXT "SENDING START TALKING COMMAND"
	.BYTE 0		

STARTEDTALKING
	.TEXT "STARTED TALKING"
	.BYTE 0		

OPENINGFILE
	.TEXT "OPENING FILE"
	.BYTE 0		

OPENINGFILEFAILED
	.TEXT "OPENING FILE FAILED"
	.BYTE 0	

OPENINGSUCCESS
	.TEXT "FILE OPEN SUCCEEDED"
	.BYTE 0		
	
READINGFILE
	.TEXT "READING FILE"
	.BYTE 0		


READINGFAILED	
	.TEXT "READING FAILED"
	.BYTE 0		
CLOSINGFILE	
	.TEXT "CLOSING FILE"
	.BYTE 0	
	
FILECLOSED
	.TEXT "FILE CLOSING SUCCEEDED"
	.BYTE 0
	
	
ERRORCLOSINGFILE
	.TEXT "CLOSING FAILED"
	.BYTE 0	


.include "..\..\Loader\CartLib.s"
.include "..\..\Loader\CartLibHi.s"

READBUFFER

