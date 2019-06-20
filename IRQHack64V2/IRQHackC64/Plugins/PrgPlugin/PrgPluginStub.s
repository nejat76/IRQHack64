; PRG plugin for IRQHack64V2
; Aim : Replace standard kernal functions so that basic tools 
; using standard kernal can work with IRQHack64V2
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
;chkout          = $ffc9
;chrout          = $ffd2

orgchrin           = $ffcf
orgopen            = $ffc0
orgclose           = $ffc3
orgchkin           = $ffc6
orgclrchn          = $ffcc




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

DEBUG = 1


DELAYFRAMES	.macro
.if DEBUG = 1
	LDX #\1
	JSR WAITFRAMES
.endif	
	.endm
		
	
EQ16	.macro
	LDA \1
	CMP \2 
	BNE +
	LDA \1 + 1
	CMP \2 + 1
+
	.endm

EQ16_IM	.macro
	LDA \1
	CMP #<\2 
	BNE +
	LDA \1 + 1
	CMP #>\2
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
	
	
	*=$CA30
	
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

STATUS_INDEX
	.BYTE 0
MM_CONFIG
	.BYTE 0	
TALK_STATUS
	.BYTE 0
TALK_DIRECTION
	.BYTE 0
TALK_FILE
	.BYTE 0
HAS_OPENED_FILE
	.BYTE 0
ERROR
	.BYTE 0		
TEXT
	.TEXT "NABER?"
TEXTEND
	
INITSTATUS
	LDY #$00 
	LDX #$00	
	LDA ERROR
	BPL +
	LDA #00
	STA STATUS_INDEX	
	BEQ +
	LDA ERROR
+	
	STA GENERALBUFFER, X	
	INX
-	
	LDA TEXT, Y
	STA GENERALBUFFER, X
	INX	
	INY
	CPY #(TEXTEND-TEXT)
	BNE -	
	
	LDA #13
	STA GENERALBUFFER, X	
	
	RTS

INITMAP
	;LDA PROCESSOR_PORT
	LDA #$36
	STA MM_CONFIG
	LDA #PP_CONFIG_DEFAULT
	STA PROCESSOR_PORT
	RTS
	
NEW_OPEN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP orgopen
+
	LDA KERNAL_LOGICAL_NUMBER
	CMP #15 ;Command channel
	BNE HANDLE_FILE
	JSR INITSTATUS
	JMP NEW_OPEN_FINISH_2
	
HANDLE_FILE:	
	SEI
	JSR INITMAP
	JSR IRQ_DisableDisplay		
	JSR IRQ_StartTalking	
	DELAYFRAMES 2
	LDX KERNAL_FILENAME_LOW	
	LDY KERNAL_FILENAME_HIGH
	LDA KERNAL_FILENAME_LENGTH
	JSR IRQ_SetName
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC OPEN_SUCCESS
	STA ERROR
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
	EQ16_IM OPENEDFILELENGTH16BIT, 0
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
	
		
				
	LDA MM_CONFIG
	STA PROCESSOR_PORT
	;CLI
NEW_OPEN_FINISH_2	
	RTS
	
NEW_CHKIN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP orgchkin
+
	STX TALK_FILE
	LDA #$00
	STA TALK_DIRECTION		; Program wants to read
	
	RTS
	
NEW_CLOSE
	SEI
	JSR INITMAP
	
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP orgclose
+
	LDA KERNAL_LOGICAL_NUMBER
	CMP #15 ;Command channel
	BNE FILECLOSE
	JMP NEW_CLOSE_FINISH	
	
FILECLOSE	
	DELAYFRAMES 3
	JSR IRQ_DisableDisplay
	
	JSR IRQ_StartTalking
		
	LDA #$04 
	STA $D020	

	LDA MODULATION_ADDRESS	
	DELAYFRAMES 4
	JSR IRQ_CloseFile
	BCC + 
	LDA #128
	STA KERNAL_STATUS
	SEC
	JMP NEW_CLOSE_FINISH
+	
	DELAYFRAMES 2
	JSR IRQ_EndTalking
NEW_CLOSE_FINISH:		
	JSR IRQ_EnableDisplay
	LDA MM_CONFIG
	STA PROCESSOR_PORT
	CLI
	RTS	

NEW_CLRCHN
	INC $D020
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP orgclrchn
+
	RTS
	
	;First chrin will be pulling 256 bytes from the micro
	;then it will serve the calling program from this buffer.
	;for the next 256 bytes it will call the micro again.
	;so this way calling program will be able to invoke other api functions like close and such.
NEW_CHRIN
	SEI
	LDA KERNAL_DEVICE_NUMBER
	CMP #08
	BEQ + 
	JMP orgchrin
+
	LDA KERNAL_LOGICAL_NUMBER
	CMP #15 ;Command channel
	BNE FILEOP
	LDA KERNAL_FILENAME_LENGTH
	BNE NOTSUPPORTED
	
	LDX STATUS_INDEX
	LDA GENERALBUFFER, X
	INX
	STA STATUS_INDEX
	JMP NEW_CHRIN_FINISH
	
	
NOTSUPPORTED:	

FILEOP:	
	; File open control?
	EQ16 FILEINDEX, OPENEDFILELENGTH16BIT
	BNE +
	LDA #64
	STA KERNAL_STATUS
	RTS
+	
	LDA FILEINDEXLOW
	BNE +			;Read from already filled buffer

;hayde:
;	INC $d020
;	JMP hayde
	;nobug
	JSR INITMAP
	;bug	
	JSR IRQ_DisableDisplay	
	
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

;hayde:
;	INC $d020
;	JMP hayde	
	DELAYFRAMES 2
	JSR IRQ_EndTalking
	
	LDA MM_CONFIG
	STA PROCESSOR_PORT

	JSR IRQ_EnableDisplay
	; Error handling?
+
	LDA #$00
	STA KERNAL_STATUS
	INC $D020
	LDX FILEINDEXLOW
	LDA GENERALBUFFER, X	
	INC16 FILEINDEX
	
NEW_CHRIN_FINISH
	CLI

	RTS
	
	


.include "..\..\Loader\CartLibDE.s"
.include "..\..\Loader\CartLibHiDE.s"

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
	

