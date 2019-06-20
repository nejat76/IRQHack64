; PRG plugin for IRQHack64V2
; Aim : Replace standard kernal functions so that basic tools using standard kernal can work with IRQHack64V2
; 26/08/2018 - Istanbul
; I.R.on


.enc screen

KERNAL_FILENAME_LENGTH	= $B7
KERNAL_FILENAME_HIGH	= $BC
KERNAL_FILENAME_LOW		= $BB

KERNAL_LOGICAL_NUMBER	= $B8
KERNAL_DEVICE_NUMBER	= $BA
KERNAL_SECONDARY_ADDRESS	= $B9

KERNAL_STATUS 			= $90

FAT_FILE_LENGTH_INDEX	= 28

LOAD_START_LO	= $AE
LOAD_START_HI	= $AF

;Kernal routines
CHROUT    	= $FFD2
GETIN 	  	= $FFE4
SCNKEY 		=  $FF9F 

;We'll implement these basic 5 functions for opening & reading files.
;setnam          = $ffbd		; No need to implement... $B7 contains file length, $BC high byte for filename, $BB low byte for filename
;setlfs          = $ffba		; No need to implement... 
;load            = $ffd5
;save            = $ffd8
chrin           = $ffcf
open            = $ffc0
close           = $ffc3
chkin           = $ffc6
;chkout          = $ffc9
clrchn          = $ffcc
;chrout          = $ffd2



chrinVector = $0324
openVector = $031A
closeVector = $031C
chkinVector = $031E
clrchnVector = $0322


RESETROUTINE = $FCE2
SOFTNMIVECTOR	= $0318
IRQVECTOR	= $0314
IRQ6502			= $FFFE
;VIC Border color
BORDER		= $D020
DEFAULT_NMI_HANDLER = $FE47	

NMI_LO			= $0318
NMI_HI			= $0319

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

	
EQ16	.macro
	LDA #<\1
	CMP #<\2 
	BNE +
	LDA #>(\1 + 1)
	CMP #>(\2 + 1)
+
	.endm
	
INC16	.macro
	INC \1
	BNE +
	INC \1 + 1
+	
	.endm
	
ADD16	.macro
	CLC 
	LDA \1
	ADC \2
	STA \3
	LDA \1 + 1
	ADC \2 + 1
	STA \3 + 1
	.endm
	
	
	*=$C000
	JMP MAIN
	
	*=$C700
MAIN	
	JSR INIT		;Clears screen, disables interrupts.	

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
	JMP EXITFAIL
OPENINGCONT	
	JSR IRQ_EnableDisplay

	PRINTSTATUSANDWAIT OPENINGSUCCESS, 200

	LDA #<GENERALBUFFER
	STA IRQ_DATA_LOW
	LDA #>GENERALBUFFER
	STA IRQ_DATA_HIGH
	
	JSR IRQ_DisableDisplay
	
	LDY #$00
	JSR IRQ_GetInfoForFile
	BCC +
	JMP EXITFAIL
+	
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX
	STA FILELENGTH
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 1
	STA FILELENGTH + 1
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 2
	STA FILELENGTH + 2
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 3
	STA FILELENGTH + 3
		
	DELAYFRAMES 2		

	LDY #$00
	LDA #<GENERALBUFFER
	STA IRQ_DATA_LOW
	LDA #>GENERALBUFFER
	STA IRQ_DATA_HIGH
	LDA #1
	STA IRQ_DATA_LENGTH
		
	JSR IRQ_ReadFileNoCallback	
	BCC +
	JMP EXITFAIL
+	
RESUMELOADING		
	; We need to seek to the start of the file first, optionally we can skip 2 bytes 
	; which signifies the loading address of the file at the start.
	
	LDX #SEEK_DIRECTION_START
	LDA #2
	STA IRQ_SEEK_LOW
	LDA #0
	STA IRQ_SEEK_HIGH
	JSR IRQ_SeekFile
	BCC + 
	JMP EXITFAIL
+	
	DELAYFRAMES  2
	LDY #$00
	; Get low address of loading
	LDA GENERALBUFFER
	STA STARTADDRESSLO
	STA IRQ_DATA_LOW
	; Get high address of loading	
	LDA GENERALBUFFER + 1
	STA STARTADDRESSHI
	STA IRQ_DATA_HIGH
	
	; Get 8-15 bits of 32 bit number
	LDA FILELENGTH + 1
	CLC
	; Add one to request 1 more block necessary for the whole file. 
	; TODO: Should fix this but cart supports only block reads at the moment.. unless one streams data
	ADC #$01		
	STA IRQ_DATA_LENGTH


	ADD16 STARTADDRESS, FILELENGTH16BIT, ENDADDRESS
	
	
;	JSR IRQ_EnableDisplay
;-	
;	JSR minikey
;	BEQ -
	
;	JSR DisplayReceived
	
;	JMP *

	
	JSR IRQ_ReadFileNoCallback
	
RESUMEFULLLOAD	
	DELAYFRAMES  2
	JSR IRQ_CloseFile
	BCC +
	JMP EXITFAIL
+		

	JSR IRQ_EndTalking	
	BCC +
	JMP EXITFAIL	
+	
	; Now we need to change the kernal vectors and launch the program.
	; GET BACK HERE - GET BACK HERE - GET BACK HERE 
	
	STX $D016					; Turn on VIC for PAL / NTSC check
	JSR $FDA3					; IOINIT - Init CIA chips
	;JSR $FD50					; RANTAM - Clear/test system RAM
	;JSR ALTRANTAM				; Metallic's fast alternative to RANTAM
	JSR $FD15					; RESTOR - Init KERNAL RAM vectors
	JSR $FF5B					; CINT   - Init VIC and screen editor
	JSR SETVECTORS	
	CLI							; Re-enable IRQ interrupts	

;	BASIC RESET  Routine

	JSR $E453					; Init BASIC RAM vectors
	JSR $E3BF					; Main BASIC RAM Init routine
	JSR $E422					; Power-up message / NEW command
	LDX #$FB
	TXS		
	
	
	LDY ENDADDRESSLO
	STY $2D
	STY $2F
	STY LOAD_START_LO
	LDA ENDADDRESSHI
	STA $2E
	STA $30
	STA LOAD_START_HI
	
	JSR CLEANUP
		
	LDA #$37					;Restore default memory layout
	STA $01	
	
	JSR IRQ_EnableDisplay
	
	LDA #$08					;Initialize current device number as 8
	STA $BA
	
	LDA #$81					;%10000001 ; Enable CIA interrupts
	STA $DC0D	
		
	JMP $0840
		
LAUNCH	
	LDA #$08					
	CMP STARTADDRESSHI
	BNE MACHINELANG				
	LDA STARTADDRESSLO
	CMP #$01
	BNE MACHINELANG
		
	JSR $A659 ;"CLR" 	
	JMP $A7AE ;"RUN" 
 	
MACHINELANG 
	LDA STARTADDRESSLO
	STA $FB
	LDA STARTADDRESSHI
	STA $FC
	JMP ($00FB)				; Leave control to loaded stuff 	
			
	
	
	
	
INPUT_GET
	JSR SCNKEY		; Call kernal's key scan routine
 	JSR GETIN		; Get the pressed key by the kernal routine
  	BEQ INPUT_GET		; If zero then no key is pressed so repeat
	
EXITFAIL	
	LDA #$02 
	STA BORDER
	JSR IRQ_EnableDisplay

	JMP INPUT_GET
	
	
CLEANUP
	; Restore nmi vector
	LDA #<DEFAULT_NMI_HANDLER
	STA NMI_LO
	LDA #>DEFAULT_NMI_HANDLER
	STA NMI_HI	

	RTS
	
SETVECTORS
	LDA #<NEW_CHRIN
	STA chrinVector
	LDA #>NEW_CHRIN
	STA chrinVector	+ 1
	
	LDA #<NEW_OPEN
	STA openVector 
	LDA #>NEW_OPEN
	STA openVector 	+ 1
	
	LDA #<NEW_CLOSE
	STA closeVector  
	LDA #>NEW_CLOSE
	STA closeVector + 1	

	LDA #<NEW_CHKIN
	STA chkinVector  
	LDA #>NEW_CHKIN
	STA chkinVector + 1	

	LDA #<NEW_CLRCHN
	STA clrchnVector  
	LDA #>NEW_CLRCHN
	STA clrchnVector + 1	
	RTS
	
	
INIT		; Input : None, Changed : A
	CLD
	LDA #$93
	JSR CHROUT
;	LDA #$00 
;	STA $D020
;	LDA #$0B
;	STA $D021
		
	JSR DISABLEINTERRUPTS		
	JSR KILLCIA
		
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


TALK_STATUS
	.BYTE	
TALK_DIRECTION
	.BYTE
TALK_FILE
	.BYTE	
HAS_OPENED_FILE
	.BYTE
	

NEW_OPEN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP open
+
	JSR IRQ_DisableDisplay		
	JSR IRQ_StartTalking	
	DELAYFRAMES 2
	LDX #<KERNAL_FILENAME_LOW	
	LDY #>KERNAL_FILENAME_HIGH
	LDA #KERNAL_FILENAME_LENGTH
	JSR IRQ_SetName
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC OPEN_SUCCESS
	LDA #128
	SEC
	JMP NEW_OPEN_FINISH	
OPEN_SUCCESS	
	DELAYFRAMES 2
	LDA #<GENERALBUFFER
	STA IRQ_DATA_LOW
	LDA #>GENERALBUFFER
	STA IRQ_DATA_HIGH
	LDY #$00
	JSR IRQ_GetInfoForFile
	
	BCC +
	LDA #128
	SEC
	JMP NEW_OPEN_FINISH
+	
	DELAYFRAMES 2
	JSR IRQ_EndTalking	

	
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX
	STA OPENEDFILELENGTH
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 1
	STA OPENEDFILELENGTH + 1
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 2
	STA OPENEDFILELENGTH + 2
	LDA GENERALBUFFER + FAT_FILE_LENGTH_INDEX + 3
	STA OPENEDFILELENGTH + 3
		
	
	LDA #0
	STA FILEINDEX
	STA FILEINDEX+1
	LDA #1		
	STA HAS_OPENED_FILE	
	EQ16 OPENEDFILELENGTH16BIT, 0
	BNE +
	LDA #64
	SEC
	JMP NEW_OPEN_FINISH
+	
	CLC
	LDA #0
NEW_OPEN_FINISH
	STA KERNAL_STATUS
	JSR IRQ_EnableDisplay	
	
	RTS
	
NEW_CHKIN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP chkin
+
	STX TALK_FILE
	LDA #$00
	STA TALK_DIRECTION		; Program wants to read

	RTS
	
NEW_CLOSE
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP close
+
	JSR IRQ_DisableDisplay
	
	JSR IRQ_StartTalking

	DELAYFRAMES 2
	JSR IRQ_CloseFile
	BCC + 
	LDA #128
	STA KERNAL_STATUS
	SEC
	RTS
+	
	DELAYFRAMES 2
	JSR IRQ_EndTalking
	RTS	

NEW_CLRCHN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP clrchn
+
	RTS
	
	;First chrin will be pulling 256 bytes from the micro
	;then it will serve the calling program from this buffer.
	;for the next 256 bytes it will call the micro again.
	;so this way calling program will be able to invoke other api functions like close and such.
NEW_CHRIN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP chrin
+
	; File open control?
	EQ16 FILEINDEX, OPENEDFILELENGTH16BIT
	BNE +
	LDA #64
	STA KERNAL_STATUS
	RTS
+	
	LDA FILEINDEXLOW
	BNE +			;Read from already filled buffer

	JSR IRQ_StartTalking
	DELAYFRAMES 2
	
	LDY #$00
	LDA #<GENERALBUFFER
	STA IRQ_DATA_LOW
	LDA #>GENERALBUFFER
	STA IRQ_DATA_HIGH
	LDA #1

	STA IRQ_DATA_LENGTH		
	JSR IRQ_ReadFileNoCallback

	DELAYFRAMES 2
	JSR IRQ_EndTalking
	
	; Error handling?
+
	LDA #$00
	STA KERNAL_STATUS
	
	LDX FILEINDEXLOW
	LDA GENERALBUFFER, X	
	TAY
	INC16 FILEINDEX
	TYA	
	RTS
	
	


.include "..\..\Loader\CartLib.s"
.include "..\..\Loader\CartLibHi.s"

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
	DUMPHEX GENERALBUFFER, $0400, $00	
	DUMPHEX GENERALBUFFER+256, $0700, $10		
	
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

GENERALBUFFER
	.FILL 256

; Attributes of launched initial program file	
FILELENGTH16BIT	; F9 36
FILELENGTH
	.FILL 4

STARTADDRESS	; 01 08
STARTADDRESSLO
	.BYTE 0	
STARTADDRESSHI
	.BYTE 0
	
ENDADDRESS		; FA 3E
ENDADDRESSLO
	.BYTE 0	
ENDADDRESSHI
	.BYTE 0	


; Attributes of opened files	
OPENEDFILELENGTH16BIT	; FA 3E
OPENEDFILELENGTH
	.FILL 4

FILEINDEX		; FF FF ; We are supporting only files with 16 bit size at the moment
FILEINDEXLOW
	.FILL 1
FILEINDEXHIGH	
	.FILL 1
	

