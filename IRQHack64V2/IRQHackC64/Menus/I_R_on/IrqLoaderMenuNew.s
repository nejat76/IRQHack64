; Plugin supporting menu program for IrqHack64
; 31/07/2018 - Istanbul

;.enc ascii
; How menu works
; Micro sends this menu when user presses the button on the cartridge.
; Different from previous version, this version uses cartridge api for the low level work.
; It will employ plugins to react to different type of programs. (Video playing, wav playing so on.)


;Zero page addresses used to address screen
COLLOW	  	= $FB
COLHIGH	  	= $FC

;Zero page addresses used to access file names
NAMELOW	  	= $FD
NAMEHIGH  	= $FE


;Loader on the cartridge rom sets the 6th bit of this location. Which is tested by BIT $64
;command and waiting if overflow flag (which is the 6th bit of this location) is clear.
;BITTARGET	= $64

;Next page command
COMMANDNEXTPAGE = $43

;Previous page command
COMMANDPREVPAGE = $41

;Part of the command byte that flags controlling micro that a file/folder is selected.
COMMANDENTERMASK = $01

;Starting address of the data to be transferred. Menu uses this location to get next / previous
;page of contents from controlling micro. DATA_HIGH is not incremented by the loader. Instead
;ACTUAL_HIGH is used. DATA_LOW, DATA_HIGH is also used to launch the loaded program by the loader.
;DATA_LOW	= $69
;DATA_HIGH 	= $6A

;Length (page) of data to be transferred
;DATA_LENGTH	= $6B

RESERVED	= $6C

;These are set to DATA_LOW and DATA_HIGH respectively before transfer. 
;Loader uses these locations for actual transfer.
;ACTUAL_LOW		= $6C
;ACTUAL_HIGH		= $6D

;Actual end address of loaded program file. These are not used by menu.
;ACTUAL_END_LOW	= $6E
;ACTUAL_END_HIGH	= $6F
TYPE			= $70
TRANSMODE		= $71
RESERVED3		= $72

;Nmi handler on cart that does the initial transfer of 4 bytes metadata (data_low, data_high, length, reserved)
;Nmi handler on the cart changes the handler to the fast one upon these 4 bytes finishes transferring.



;Locations used by kernal to jump to user provided nmi/irq handler respectively
SOFTNMIVECTOR	= $0318
IRQVECTOR	= $0314

;Kernal NMI handler - used to restore nmi handler on nmi vector.
ROMNMIHANDLER	= $FE47

;Kernal IRQ handler - not used
ROMIRQHANDLER	= $FF48

IRQ6502			= $FFFE

;VIC Border color
BORDER		= $D020

;Play address of the sid
;SID tunes that use $C000 and onwards are preferred by this menu since menu occupies the space from $0801
;SIDPLAY		= $C000
SIDPLAY		= $2200

;Init address of the tune
;SIDINIT		= $C003
SIDINIT		= $2203

SIDLOAD		= $2200

;Kernal routines
CHROUT    	= $FFD2
GETIN 	  	= $FFE4
SCNKEY 		=  $FF9F 

CASSETTEBUFFER = $033C
FILENAMESHADOW = $FF00
DIRSTACKTEMP = $FD00
CURRENTDIRINDEX	= CASSETTEBUFFER + MAXFILENAMELENGTH
CURRENTDIRINDEXSHADOW = FILENAMESHADOW + MAXFILENAMELENGTH

DEBUG			= 1


	
DELAYFRAMES	.macro
	LDX #\1
	JSR WAITFRAMES
	.endm




	*=$080E		
	LDX #$FB
	TXS	
;	LDA MODULATION_ADDRESS
;	DELAYFRAMES	10		
;	LDA #PP_CONFIG_RAM_ON_BASIC
;	STA PROCESSOR_PORT
	JSR PREINIT
	JSR DISPLAYPETGRAPHICS
	DELAYFRAMES 75

	JSR IRQ_DisableDisplay	
	JSR DISPLAYSCREENGRAPHICS
	;JSR POSTINIT		;Clears screen, disables interrupts, copies sid to $C000 and inits it.	
	;JMP INPUT_GET
.if DEBUG = 0 
	JSR IRQ_StartTalking
.else
	NOP
	NOP
	NOP
.endif		
	LDA #<DIRLOAD
	STA IRQ_DATA_LOW
	LDA #>DIRLOAD
	STA IRQ_DATA_HIGH
	LDA #$03		;Max 256*3 bytes of data
	STA IRQ_DATA_LENGTH	
	LDA #<(DIRREAD-1)
	STA IRQ_CALLBACK_LO
	LDA #>(DIRREAD-1)
	STA IRQ_CALLBACK_HI	

	TSX
	STX $C000
	
	LDY #$00		
	LDX #MAXDIRITEMS
	LDA CURPAGEINDEX
	
.if DEBUG = 0 
	JSR IRQ_ReadDirectory	
.else
	JSR SETDIR1
	JSR DIRREAD
.endif		
		
	; Do error handling if directory can't be read (carry is set)

		
;Start of main loop	
INPUT_GET
	LDA ISMUSICPLAYING	;Decide to play music or not (ISMUSICPLAYING is just a hardcoded constant)
	BEQ SKIPMUSIC
	LDA #$A1	

;Waits until a certain raster line is reached to call the sid's play routine	
WAITPLAYRASTER			
	CMP $D012
	BNE WAITPLAYRASTER
	STA BORDER
	JSR SIDPLAY
	LDX #$00
	LDY $D012
	INY
	INY
WAITPLAYRASTEREND	
	CPY $D012
	BNE WAITPLAYRASTEREND
	
	STX BORDER

SKIPMUSIC	
	JSR SCNKEY		; Call kernal's key scan routine
 	JSR GETIN		; Get the pressed key by the kernal routine
  	BEQ INPUT_GET		; If zero then no key is pressed so repeat
  	CMP #$2E		; IF it's a > character 
  	BEQ NEXTPAGE		; Then continue to request next page from micro
  	CMP #$2C		; IF it's a < character
  	BEQ PREVPAGE 		; Then continue to request previous page from micro
  	CMP #$2B		; IF it's a + character
  	BEQ UP			; Then continue iterate up in the menu
  	CMP #$2D		; IF it's a - character
  	BEQ DOWN 		; Then continue iterate down in the menu
  	CMP #$0D		; IF it's ENTER character
  	BEQ ENTER		; Then launch the selected item
	JMP INPUT_GET		; If other key then leave control to the main loop
		  	
UP	
	LDX #COMMANDENTERMASK
	STX COMMANDBYTE
	JSR GETCURRENTROW
	JSR CLEARARROW
	TXA
	BNE NORMALUP
	LDX CURPAGEITEMS
NORMALUP	
	DEX
	JSR SETCURRENTROWHEAD 	
	JSR SETARROW
	JMP INPUT_GET

DOWN
	LDX #COMMANDENTERMASK
	STX COMMANDBYTE	
	JSR GETCURRENTROW	
	JSR CLEARARROW
	INX
	CPX CURPAGEITEMS
	BNE ROLLINGDOWN
	LDX #$00
ROLLINGDOWN	
	JSR SETCURRENTROWHEAD 
	JSR SETARROW
	JMP INPUT_GET	

; Below routine fills the COMMANDBYTE to the relevant action taken by the user.
; With the start of the ENTER control byte is sent to micro by modulating raster interrupts


NEXTPAGE  	
	LDX CURPAGEINDEX
	INX
	CPX PAGECOUNT	  	
	BLT EXECNEXT
	JMP INPUT_GET
EXECNEXT
	INC CURPAGEINDEX	
	LDX #COMMANDNEXTPAGE
	STX COMMANDBYTE
	JSR IRQ_DisableDisplay
	JMP DOREADDIRECTORY
	
SPLAY 	
	LDX #$45
	STX COMMANDBYTE
	CLV
	BVC ENTER
	
PREVPAGE  	  	  	
  	LDX CURPAGEINDEX
  	BNE EXECPREV
  	JMP INPUT_GET 
EXECPREV
	DEC CURPAGEINDEX
	LDX #COMMANDPREVPAGE
	STX COMMANDBYTE	
	JSR IRQ_DisableDisplay	
	JMP DOREADDIRECTORY
	
ENTER  	  

	JSR IRQ_DisableDisplay
	;Decide if it's a file selection or special command (previous / next)
	LDA COMMANDBYTE
	AND #$40
	BNE SPECIALCMD
	JSR GETCURRENTROW
	JSR ISDIRECTORY	
	BNE NODIRECTORY	

	JSR ISPREVIOUSDIRECTORY
	BCS NOPREV
.if DEBUG = 1	
	DEC DIRLEVEL	
.endif	
	JSR POPDIRNAME
	JSR GOBACK
	;JMP NEWCONTENT
	JMP DOREADDIRECTORY
	
NOPREV	
	JSR PUSHDIRNAME
	
	;Setting name of the file
	JSR SETFILENAME	
.if DEBUG=0
	JSR IRQ_ChangeDirectory
	BCS CHANGEDIRFAIL	
.else
	INC DIRLEVEL
.endif	

	
	DELAYFRAMES 2
	; Read directory
DOREADDIRECTORY	
	LDA #<DIRLOAD
	STA IRQ_DATA_LOW
	LDA #>DIRLOAD
	STA IRQ_DATA_HIGH
	LDA #$03		;Max 256*3 bytes of data
	STA IRQ_DATA_LENGTH	
	
	LDY #$00		
	LDX #20			;Max 20 directory items
	LDA CURPAGEINDEX
.if DEBUG = 0
	JSR IRQ_ReadDirectoryNC
.else
	LDA DIRLEVEL
	CMP #00
	BNE +
	JSR SETDIR1
	JMP OUTDIRSET
+	
	CMP #01
	BNE +
	JSR SETDIR2
	JMP OUTDIRSET	
+	
	CMP #02
	BNE +
	JSR SETDIR3
OUTDIRSET	
.endif
	
	JMP NEWCONTENT
	
	
CHANGEDIRFAIL
	LDA #$07
	STA BORDER
	JMP *
	; Do an error text
NODIRECTORY	
	;JMP INVOKEPETG
	JSR GETCURRENTROW				; We have current row in X
	
	LDA NAMESLO, X
	TAY
	LDA NAMESHI, X
	TAX
	TYA

	JSR CHECKFILENAME
	JSR ISPRG
	BCC PROGRAM
	CMP #TYPE_PROGRAM
	BEQ PROGRAM
	CMP #TYPE_CHECK_PLUGIN
	BEQ PLUGIN
	
	; ERROR
-	
	INC $D020
	JMP - 
PLUGIN	
	JSR BUILDPLUGINNAME_BIN
	LDA #>PLUGINNAME
	TAY
	LDA #<PLUGINNAME
	TAX
	LDA #31
	JSR IRQ_SetName			
	
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC BINPLUGINEXISTS
	
	DELAYFRAMES 1
	
	JSR BUILDPLUGINNAME_PRG
	LDA #>PLUGINNAME
	TAY
	LDA #<PLUGINNAME
	TAX
	LDA #31
	JSR IRQ_SetName			
	LDX #01		; Flags=read
	JSR IRQ_OpenFile
	BCC PRGPLUGINEXISTS
	JMP PROGRAM
	

	
BINPLUGINEXISTS
	DELAYFRAMES	20
		
	LDA #<$C000
	STA IRQ_DATA_LOW
	LDA #>$C000
	STA IRQ_DATA_HIGH
	LDA #15			;PLUGIN LENGTH
	STA IRQ_DATA_LENGTH
	
	JSR IRQ_DisableDisplay
	LDY #$00
	JSR IRQ_ReadFileNoCallback

	LDA #1
	STA $D020
	
	;JSR IRQ_EnableDisplay	
	
PETGLPLUGINREAD

	DELAYFRAMES	1	
	JSR IRQ_CloseFile	
	
	JSR IRQ_EnableDisplay
	
	JSR GETCURRENTROW	

	JSR PrepareFileNameParameter
	
	JMP $C000						; TODO Should be loaded from read file	

		
PRGPLUGINEXISTS	
	DELAYFRAMES	1	
	JSR IRQ_CloseFile	
	
	JSR GETCURRENTROW	
	JSR PrepareFileNameParameter

	JSR IRQ_InvokeWithName

	JMP *

PROGRAM	
	LDA #$02 
	STA BORDER
	JSR GETCURRENTROW	
	;Setting name of the file
	JSR SETFILENAME	
	;Invoking with name
	LDX #01		; Reserved flag
	JSR IRQ_InvokeWithName
	BCC SUCCEEDINVOKE
	JSR IRQ_EnableDisplay
SUCCEEDINVOKE	

	JMP *
	
SPECIALCMD		

	; INVOKE PLUGIN

	
GOBACK
	; Go to root.. Traverse stack starting from root... Change directories
	; Change directory to root
	LDA #>PARENTDIR
	TAY
	LDA #<PARENTDIR
	TAX
	LDA #31
	JSR IRQ_SetName			
.if DEBUG = 0	
	JSR IRQ_ChangeDirectory
.else
	LDA #00
	STA	DIRLEVEL
.endif
	DELAYFRAMES 2
	
	; From 0 to CURRENTDIRINDEX change dirs (current dir will be popped of stack beforehand)
	LDY CURRENTDIRINDEX
	BEQ +
	LDY #00
-		
	TYA
	PHA
	LDA DIRNAMESLO, Y
	TAX
	LDA DIRNAMESHI, Y
	TAY
	LDA #31
	JSR IRQ_SetName
.if DEBUG = 0	
	JSR IRQ_ChangeDirectory
.else
	INC DIRLEVEL
.endif
	DELAYFRAMES 2
	PLA
	TAY
	INY
	CPY CURRENTDIRINDEX
	BNE -
			
 +	
	RTS
	
	
ISPREVIOUSDIRECTORY	
.enc screen
	LDY #$00
	LDA (NAMELOW), Y
	CMP #$2E
	BNE + 
	INY 
	LDA (NAMELOW), Y
	CMP #$2E
	BNE +
	CLC
	RTS
+	
	SEC
	RTS
.enc none
	
NEWCONTENT
; Update the screen with the new content got from micro		
	INC BORDER

	JSR IRQ_EnableDisplay	
	JSR GETCURRENTROW	
	JSR CLEARARROW	
	JSR PRINTPAGE
	LDX #00
	JSR SETCURRENTROWHEAD 
	JSR SETARROW

	CLI
	JMP INPUT_GET
  	
	RTS	

DIRREAD		
;	LDA #$02
;	STA BORDER

;	DELAYFRAMES 10
	JSR IRQ_EnableDisplay	
		
	;JSR PRINTTITLE		


	;Call it elsewhere
	JSR PRINTPAGE		;Prints the initial filenames that's added to the program by the micro.
	LDX #$00		;Puts the selector 
	JSR SETCURRENTROWHEAD	;to the first entry in the
	JSR SETARROW		;list
	CLC
	RTS

.if DEBUG=1	
SETDIR1	
	LDY #(DIR2-DIR1)
-	
	LDA DIR1, Y
	STA DIRLOAD, Y
	DEY
	BNE - 
	RTS 
SETDIR2
	LDY #(DIR3-DIR2)
-	
	LDA DIR2, Y
	STA DIRLOAD, Y
	DEY
	BNE - 
	RTS 
SETDIR3
	LDY #(DIR3END-DIR3)
-	
	LDA DIR3, Y
	STA DIRLOAD, Y
	DEY
	BNE - 
	RTS 
.endif

	
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
	
SETFILENAME	
	JSR GETCURRENTROW
	LDA NAMESHI, X
	TAY
	LDA NAMESLO, X
	TAX
	LDA #31
	JSR IRQ_SetName
	RTS
	
ISDIRECTORY
	LDA NAMESLO, X
	STA NAMELOW
	LDA NAMESHI, X
	STA NAMEHIGH
	LDY #31
	LDA (NAMELOW), Y	
	CMP #$04
	RTS
			
SETARROW 	; Input : X (current row), Changed : A, Y 
	LDY #$00
	LDA #$3E	; > sign
	STA (COLLOW),Y
	RTS

CLEARARROW	; Input : X (current row), Changed : A, Y 
	LDY #$00
	LDA #$20	; Space
	STA (COLLOW),Y
	RTS
	
SETCURRENTROW	; Input : X (current row), Changed : None
	PHA
	STX CURRENTROW
	TXA
	PHA
	ASL
	TAX
	LDA COLS+2,X
	STA COLLOW
	INX
	LDA COLS+2,X
	STA COLHIGH	
	PLA
	TAX
	PLA
	RTS
	
SETCURRENTROWHEAD ; Input : X (current row), Changed : None
	PHA
	STX CURRENTROW
	TXA
	PHA
	ASL
	TAX
	LDA COLS+2,X
	CLC
	SBC #01
	STA COLLOW
	INX
	LDA COLS+2,X
	STA COLHIGH	
	PLA
	TAX
	PLA
	RTS
		
GETCURRENTROW	; Input : None, Output : X (current row)
	LDX CURRENTROW
	RTS	
	
PRINTFILENAME	; Input : None, Changed: Y, A
	LDY #$00
FILENAMEPRINT	
	LDA (NAMELOW), Y
	BNE NOTEND
	LDA #$20
NOTEND	
	CMP #$3F
	BMI SYMBOL
	CLC
	SBC #$3f
SYMBOL	
	STA (COLLOW), Y
	INY
	CPY #$20
	BNE FILENAMEPRINT
	RTS
	
FROMASCII
	CMP #$5B
	BMI +
	CMP #$7F
	BPL +	
	EOR #$20
	JMP ENDFROMASCII	
+
	CMP #$41
	BMI +
	CMP #$5A
	BPL +
	ORA #$80
+
ENDFROMASCII
	RTS
	
PRINTASCIIFILENAME	; Input : None, Changed: Y, A
	LDY #$00
FILENAMEPRINT_A
	LDA (NAMELOW), Y
	BNE NOTEND_A
	LDA #$20
NOTEND_A
	JSR FROMASCII		
	CMP #$3F
	BMI SYMBOL_A
	CLC
	SBC #$3f
SYMBOL_A
	STA (COLLOW), Y
	INY
	CPY #$20
	BNE FILENAMEPRINT_A
	RTS	

CLEARLINE	; Input : None, Changed: Y, A
	LDY #$00
	LDA #$20	
ICLEARLINE		
	STA (COLLOW), Y
	INY
	CPY #$20
	BNE ICLEARLINE
	RTS
	
	
FREQ    = 19704


PREINIT		; Input : None, Changed : A
	LDA #00
	STA CURRENTDIRINDEX  
	JSR DISABLEINTERRUPTS	
	JSR KILLCIA
	JSR STARTMUSIC
		
	RTS


POSTINIT		; Input : None, Changed : A
	CLD
	LDA #$93
	JSR CHROUT
	LDA #$00 
	STA $D020
	LDA #$0B
	STA $D021
	JSR INITPC					
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
	

STARTMUSIC
	;JSR COPYMUSIC
	;LDA #$00
	;JSR SIDINIT	
	RTS	


KILLCIA
	LDY #$7f    ; $7f = %01111111 
    STY $dc0d   ; Turn off CIAs Timer interrupts 
    STY $dd0d   ; Turn off CIAs Timer interrupts 
    LDA $dc0d   ; cancel all CIA-IRQs in queue/unprocessed 
    LDA $dd0d   ; cancel all CIA-IRQs in queue/unprocessed 
	RTS	

DISABLEINTERRUPTS
	LDY #$7f    ; $7f = %01111111 
    STY $dc0d   ; Turn off CIAs Timer interrupts 
    STY $dd0d   ; Turn off CIAs Timer interrupts 
    LDA $dc0d   ; cancel all CIA-IRQs in queue/unprocessed 
    LDA $dd0d   ; cancel all CIA-IRQs in queue/unprocessed 
	
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
	
SIDREG = $d400

		
	
COPYMUSIC
	LDX #$10		; Copy 16 blocks
	;Set source
	LDA #<SID
	STA $FB
	LDA #>SID
	STA $FC
	
	;Set target
	LDA #<SIDLOAD
	STA $FD
	LDA #>SIDLOAD
	STA $FE
	
	LDY #$00
COPYBLOCK	
	LDA ($FB), Y
	STA ($FD), Y
	INY
	BNE COPYBLOCK
	INC $FC
	INC $FE
	DEX
	BNE COPYBLOCK	
	RTS
	

PRINTTITLE	; Input : None, Changed : A, X
	LDX #$00
NEXTCHAR	
	LDA TITLE, X
	BEQ OUTTITLEPRINT
	CMP #$3F
	BMI NOTSPACE
	CLC
	SBC #$3f
NOTSPACE	
	STA $040C, X
	INX
	BNE NEXTCHAR
OUTTITLEPRINT
	RTS
	
	
PRINTPAGE	; Input : None, Changed : A, X, Y
	LDA CURPAGENAMELOW
	STA NAMELOW
	LDA CURPAGENAMEHIGH
	STA NAMEHIGH

	LDX #$00
SETCOL	
	JSR SETCURRENTROW

	;JSR PRINTFILENAME
	JSR PRINTASCIIFILENAME
	
	INX
	CPX CURPAGEITEMS
	BEQ FINISH	
	LDA NAMELOW
	CLC
	ADC #$20
	STA NAMELOW
	BCC NEXTFILE
	INC NAMEHIGH
NEXTFILE
	JMP SETCOL	
FINISH
	CPX #$14
	BEQ ACTUALFINISH
	JSR SETCURRENTROW
	JSR CLEARLINE
	INX 
	CLV
	BVC FINISH
	
ACTUALFINISH	
	LDX #COMMANDENTERMASK
	STX COMMANDBYTE	
	RTS
	
	
PrepareFileNameParameter:	
	; We have current row in X
	LDA NAMESLO, X	
	STA $06
	LDA NAMESHI, X
	STA $07	
	LDY #0
-	
	LDA ($06) , Y
	STA CASSETTEBUFFER, Y
	STA FILENAMESHADOW, Y
	INY
	CPY #MAXFILENAMELENGTH
	BNE -
	
	LDA CURRENTDIRINDEX 
	STA CURRENTDIRINDEXSHADOW 
	
; Copy dirstack
	LDY #0
-	
	LDA DIRSTACK, Y
	STA DIRSTACKTEMP, Y
	LDA DIRSTACK+$100, Y
	STA DIRSTACKTEMP+$100, Y
	LDA DIRSTACK+$200, Y
	STA DIRSTACKTEMP+$200, Y
	INY
	BNE - 	
	
	RTS	
	
	
PUSHDIRNAME:	
	; We have current row in X
	LDA NAMESLO, X	
	STA $06
	LDA NAMESHI, X
	STA $07	
	
COPYDIRNAME	
	LDX CURRENTDIRINDEX
	LDA DIRNAMESLO, X	
	STA $08
	LDA DIRNAMESHI, X
	STA $09	

	
	LDY #0
-	
	LDA ($06) , Y
	STA ($08) , Y
	STA CASSETTEBUFFER, Y
	STA FILENAMESHADOW, Y
	INY
	CPY #MAXFILENAMELENGTH
	BNE -
	
	INX
	STX CURRENTDIRINDEX
	RTS		

POPDIRNAME:		
	LDY CURRENTDIRINDEX
	BEQ +
	DEY 
	STY CURRENTDIRINDEX
+	
	RTS
	
DISPLAYPETGRAPHICS
	; set to 25 line text mode and turn on the screen
	lda #$1B
	sta $D011

	LDA CHARDATA
	STA $D020
	LDA CHARDATA+1
	STA $D021

	LDA #<CHARDATA+2
	STA $FB
	LDA #>CHARDATA+2
	STA $FC

	LDA #00
	STA $FD
	LDA #04
	STA $FE
	
	LDX #$04
	LDY #$00
-	
	LDA ($FB), Y
	STA ($FD),Y
	INY
	BNE -
	INC $FC	
	INC $FE
	DEX	
	BNE -
	
	
	LDA #<(CHARDATA+1002)
	STA $FB
	LDA #>(CHARDATA+1002)
	STA $FC

	LDA #00
	STA $FD
	LDA #$D8
	STA $FE
	
	LDX #$04
	LDY #$00
-	
	LDA ($FB), Y
	STA ($FD),Y
	INY
	BNE -
	INC $FC	
	INC $FE
	DEX	
	BNE -	
	RTS
	
DISPLAYSCREENGRAPHICS
	; set to 25 line text mode and turn on the screen

	LDA PRGSCREENDATA
	STA $D020
	LDA PRGSCREENDATA+1
	STA $D021

	LDA #<PRGSCREENDATA+2
	STA $FB
	LDA #>PRGSCREENDATA+2
	STA $FC

	LDA #00
	STA $FD
	LDA #04
	STA $FE
	
	LDX #$04
	LDY #$00
-	
	LDA ($FB), Y
	STA ($FD),Y
	INY
	BNE -
	INC $FC	
	INC $FE
	DEX	
	BNE -
	
	
	LDA #<(PRGSCREENDATA+1002)
	STA $FB
	LDA #>(PRGSCREENDATA+1002)
	STA $FC

	LDA #00
	STA $FD
	LDA #$D8
	STA $FE
	
	LDX #$04
	LDY #$00
-	
	LDA ($FB), Y
	STA ($FD),Y
	INY
	BNE -
	INC $FC	
	INC $FE
	DEX	
	BNE -	
	RTS	

	
	
COMMANDBYTE	.BYTE 0
COMMANDARG  .BYTE 0, 0, 0, 0
CURRENTROW	.BYTE 0
CURPAGENAMELOW	.BYTE <GAMELIST
CURPAGENAMEHIGH .BYTE >GAMELIST
BITPOS		.BYTE 0
ISMUSICPLAYING	.BYTE 0


COLS	
	.WORD $042C, $0454, $047C, $04A4, $04CC, $04F4, $051C, $0544, $056C , $0594
	.WORD $05BC, $05E4, $060C, $0634, $065C, $0684, $06AC, $06D4, $06FC , $0724
	.WORD $074C, $0774, $079C, $07C4, $0804

;	.WORD $0404, $042C, $0454, $047C, $04A4, $04CC, $04F4, $051C, $0544, $056C 
;	.WORD $0594, $05BC, $05E4, $060C, $0634, $065C, $0684, $06AC, $06D4, $06FC
;	.WORD $0724, $074C, $0774, $079C, $07C4
	
MAXFILENAMELENGTH = 32	
MAXDIRITEMS = 20	
-       = GAMELIST + range(0, MAXDIRITEMS * MAXFILENAMELENGTH, MAXFILENAMELENGTH)
NAMESLO   .byte <(-)
NAMESHI   .byte >(-)

DIRECTORIESMAXDEPTH	= 10	

-       = DIRSTACK + range(0, MAXFILENAMELENGTH * DIRECTORIESMAXDEPTH, MAXFILENAMELENGTH)
DIRNAMESLO   .byte <(-)
DIRNAMESHI   .byte >(-)

	
TITLE	
	.TEXT "EASYSD V2"
	.BYTE 0

PARENTDIR
	.TEXT ".."
	.FILL 30,0

; Library on the arduino doesn't support opening parent directories, so we need to go to root and then 
; traverse the path to the current path's parent.
DIRSTACK
	.FILL 32 * DIRECTORIESMAXDEPTH

	
;	*=$0E00

SID	
; 	.binary "SidFile.bin"

;.include "PatternMatch.s"	
.include "..\..\Loader\CartLib.s"
.include "..\..\Loader\CartLibHi.s"
;.include "..\..\Loader\FakeCartLib.s"
;.include "..\..\Loader\FakeCartLibHi.s"
.include "Filename.s"		
	

; File name storage area
;	*=$1BEF
;	.BYTE 64
;DATAAREA 

;CURPAGEITEMS	= $1BFE
;PAGECOUNT	= $1BFF
;CURPAGEINDEX	= $1BF2
;GAMELIST	 = $1C00
;IRQBUFFER 	 = $1F00

;DIRLOAD = GAMELIST - 2



;	.BYTE 64
;DATAAREA 

; character data
;*=$2800
PRGSCREENDATA
 	.binary "screen"

CURPAGEINDEX	.BYTE 0

CURPAGEITEMS	.BYTE 5
PAGECOUNT		.BYTE 1
GAMELIST	 

DIRLOAD = GAMELIST - 2

	.TEXT "merhaba"
	.FILL 24, 0
.enc screen
	.TEXT "D"
.enc none
	.TEXT "televole"
	.FILL 24, 0
	.TEXT "hello.prg"
	.FILL 23, 0
	.TEXT "africa.koa"
	.FILL 22, 0
	.TEXT "guzel.petg"
	.FILL 22, 0


CHARDATA
	.BYTE $0C, $00

	.BYTE	$A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $D1, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0
	.BYTE	$A0, $A0, $A0, $A0, $C2, $A0, $69, $5F, $A0, $A0, $CA, $C9, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $D5, $C0, $C0, $F3, $A0, $C2, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $D5, $CB, $A0
	.BYTE	$A0, $A0, $A0, $A0, $C2, $69, $20, $20, $5F, $A0, $D7, $EB, $C3, $C3, $C3, $D1, $C3, $C3, $C3, $C3, $F2, $CB, $D7, $A0, $C2, $A0, $CA, $C3, $C3, $C3, $F3, $A0, $D7, $A0, $A0, $A0, $A0, $C2, $D7, $A0
	.BYTE	$A0, $A0, $69, $20, $20, $20, $E9, $DF, $20, $20, $20, $20, $20, $20, $5F, $E0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $5F, $D7, $A0, $69, $20, $20, $20, $20, $C3, $D1, $C3, $F1, $C3, $C3
	.BYTE	$A0, $A0, $20, $E9, $E3, $E3, $E3, $A0, $20, $A0, $A0, $A0, $A0, $DF, $20, $20, $20, $E9, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $20, $5F, $69, $20, $E9, $A0, $A0, $20, $A0, $C2, $A0, $A0, $A0, $A0
	.BYTE	$C3, $C3, $20, $A0, $A0, $A0, $A0, $69, $20, $76, $A0, $A0, $A0, $A0, $DF, $20, $20, $A0, $A0, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $20, $20, $E9, $A0, $A0, $69, $20, $C3, $F1, $C3, $C3, $C3, $C3
	.BYTE	$A0, $69, $20, $A0, $A0, $20, $20, $20, $20, $76, $A0, $A0, $5F, $A0, $A0, $DF, $20, $5F, $A0, $A0, $DF, $20, $20, $20, $5F, $A0, $A0, $DF, $E9, $A0, $A0, $69, $20, $E9, $A0, $A0, $A0, $A0, $A0, $A0
	.BYTE	$69, $20, $20, $A0, $A0, $A0, $A0, $A0, $A0, $76, $A0, $A0, $20, $5F, $A0, $A0, $DF, $20, $5F, $A0, $A0, $DF, $20, $20, $20, $5F, $A0, $A0, $A0, $A0, $69, $20, $E9, $A0, $A0, $A0, $A0, $A0, $A0, $C2
	.BYTE	$20, $E9, $20, $A0, $A0, $A0, $A0, $A0, $20, $76, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $20, $5F, $A0, $A0, $DF, $20, $20, $20, $5F, $A0, $A0, $69, $20, $20, $20, $20, $20, $20, $A0, $5F, $D7, $C2
	.BYTE	$20, $5F, $20, $A0, $A0, $A0, $A0, $A0, $20, $76, $A0, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $20, $5F, $A0, $A0, $DF, $20, $20, $20, $A0, $A0, $20, $E9, $A0, $69, $76, $A0, $A0, $DF, $A0, $5F, $CA
	.BYTE	$DF, $20, $20, $A0, $A0, $20, $20, $20, $20, $76, $A0, $A0, $20, $20, $20, $20, $5F, $A0, $A0, $DF, $20, $5F, $A0, $A0, $DF, $20, $20, $A0, $69, $E9, $A0, $69, $20, $76, $A0, $20, $5F, $DF, $20, $5F
	.BYTE	$A0, $DF, $20, $A0, $A0, $20, $20, $5F, $A0, $76, $A0, $A0, $76, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $5F, $A0, $A0, $A0, $76, $75, $69, $E9, $A0, $69, $E9, $A0, $76, $A0, $E1, $DF, $5F, $DF, $20
	.BYTE	$C3, $C3, $20, $A0, $A0, $A0, $A0, $DF, $5F, $76, $A0, $A0, $76, $A0, $A0, $A0, $A0, $DF, $5F, $A0, $A0, $DF, $5F, $A0, $A0, $76, $75, $DF, $5F, $A0, $DF, $5F, $A0, $76, $A0, $E1, $A0, $20, $A0, $20
	.BYTE	$A0, $A0, $20, $E4, $E4, $E4, $E4, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $A0, $20, $20, $20, $A0, $DF, $5F, $A0, $DF, $20, $76, $A0, $20, $20, $20, $A0, $20
	.BYTE	$A0, $A0, $DF, $20, $20, $20, $5F, $69, $20, $20, $20, $E9, $C2, $E0, $E0, $E0, $A0, $C2, $A0, $A0, $D7, $A0, $A0, $C2, $A0, $DF, $20, $5F, $A0, $20, $5F, $A0, $DF, $76, $A0, $20, $20, $E9, $69, $20
	.BYTE	$A0, $A0, $A0, $C2, $A0, $DF, $20, $20, $E9, $A0, $A0, $E0, $C2, $E0, $E0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $D5, $F3, $A0, $A0, $DF, $20, $20, $20, $E9, $A0, $69, $76, $A0, $A0, $A0, $69, $A0, $E9
	.BYTE	$A0, $A0, $A0, $C2, $A0, $A0, $DF, $E9, $A0, $A0, $A0, $E0, $CA, $C0, $C0, $C9, $A0, $C2, $A0, $A0, $A0, $A0, $D1, $C2, $A0, $A0, $A0, $69, $20, $E9, $A0, $69, $20, $20, $20, $20, $20, $20, $E9, $A0
	.BYTE	$A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $E0, $A0, $A0, $A0, $A0, $C2, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $EB, $D1, $A0, $69, $20, $E9, $A0, $69, $A0, $E9, $A0, $C2, $A0, $A0, $A0, $A0, $A0
	.BYTE	$A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $D7, $A0, $A0, $D1, $C3, $C3, $C3, $DB, $C3, $CB, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $69, $20, $E9, $A0, $69, $20, $E9, $A0, $A0, $C2, $A0, $A0, $A0, $D5, $C3
	.BYTE	$A0, $A0, $A0, $CA, $C0, $F2, $C3, $C3, $C9, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $D1, $C3, $F3, $69, $20, $20, $20, $20, $20, $E9, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $C2, $A0
	.BYTE	$20, $C3, $C9, $A0, $A0, $C2, $20, $49, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $D1, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $C2, $A0
	.BYTE	$A0, $A0, $C2, $A0, $A0, $C2, $4A, $20, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $D7, $A0, $A0, $A0, $A0, $D1, $A0, $A0, $A0, $20, $20, $20, $A0, $A0, $20, $20, $20, $20, $20, $20, $20, $A0
	.BYTE	$A0, $A0, $C2, $A0, $A0, $C2, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $CA, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $A0, $02, $19, $20, $C0, $20, $09, $2E, $12, $2E, $0F, $0E, $20, $C0
	.BYTE	$C3, $C3, $D1, $C3, $C3, $CB, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $20, $20, $20, $A0, $A0, $20, $20, $20, $20, $20, $20, $20, $A0
	.BYTE	$87, $86, $98, $D7, $86, $85, $92, $8F, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $C2, $A0, $A0, $A0, $A0, $A0, $A0, $A0

COLORDATA

	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0F, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0F, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0F, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0E, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0B, $0B, $0B, $0E, $0E, $0E, $06, $03, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0C, $0C, $0C, $0C, $0C, $0E, $0E, $0C, $0E, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0F, $0C, $0E, $03, $03, $03, $03, $03, $0E, $03, $03, $03, $03, $03, $0C, $0C, $0E, $03, $03, $03, $03, $03, $03, $03, $03, $03, $0C, $0C, $0C, $0C, $03, $03, $03, $0E, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0E, $0D, $0D, $0D, $0D, $0D, $0E, $0D, $0D, $0D, $0D, $0D, $0D, $0E, $0E, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0D, $0C, $0C, $0D, $0D, $0D, $0D, $0E, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0E, $07, $07, $0E, $0E, $0E, $0E, $07, $07, $07, $07, $07, $07, $07, $0E, $07, $07, $07, $07, $0E, $0E, $0E, $07, $07, $07, $07, $07, $07, $07, $07, $0E, $0B, $0B, $0B, $0B, $0B, $0B, $0B
	.BYTE	$0C, $0E, $0B, $0F, $0F, $00, $00, $00, $00, $0F, $0F, $0F, $0E, $0F, $0F, $0F, $0F, $0E, $0F, $0F, $0F, $0F, $0E, $0E, $0E, $0F, $0F, $0F, $0F, $0F, $0F, $0E, $0C, $0C, $0F, $0C, $0B, $0C, $0F, $0C
	.BYTE	$0C, $0C, $0B, $01, $01, $01, $01, $01, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $01, $01, $01, $01, $0E, $0E, $0E, $01, $01, $01, $01, $01, $0E, $0E, $0E, $0E, $0E, $00, $0C, $0C, $0C
	.BYTE	$0C, $0B, $0B, $0A, $0A, $0A, $0A, $0A, $0E, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0E, $0A, $0A, $0A, $0A, $0E, $06, $06, $0A, $0A, $01, $01, $01, $01, $01, $01, $01, $01, $00, $0C, $0C
	.BYTE	$0C, $0E, $0B, $02, $02, $0E, $0E, $0E, $0E, $02, $02, $02, $0E, $0E, $0E, $0E, $02, $02, $02, $02, $0E, $02, $02, $02, $02, $0E, $06, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0C
	.BYTE	$0C, $0C, $0E, $04, $04, $0E, $0E, $0C, $0C, $04, $04, $04, $0C, $0C, $0C, $0C, $0C, $04, $04, $04, $04, $04, $04, $04, $04, $0C, $0C, $04, $01, $01, $01, $0C, $0C, $01, $01, $0C, $0C, $01, $01, $0C
	.BYTE	$0C, $0C, $0E, $0E, $0E, $0E, $0E, $0E, $0B, $0E, $0E, $0E, $0B, $0B, $0B, $0B, $0B, $0B, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0B, $0B, $0E, $03, $03, $03, $0B, $0B, $03, $03, $0B, $0B, $0B, $03, $0C
	.BYTE	$0C, $0C, $0E, $06, $06, $06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $00, $0E, $06, $06, $06, $06, $0E, $0E, $0E, $01, $0E, $0E, $01, $01, $01, $0E, $0C
	.BYTE	$0C, $0C, $0C, $0E, $0E, $0E, $0B, $06, $0E, $0E, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0E, $06, $06, $01, $0E, $0E, $0E, $0E, $0E, $01, $01, $0E, $0E, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $01, $01, $01, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $00, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $0C, $0C
	.BYTE	$0B, $0B, $0B, $0C, $0B, $0B, $0B, $0B, $0B, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $06, $06, $06, $00, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $06, $06, $06, $0E, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0E, $0E, $0E, $0E, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0F, $0C, $0B, $0C, $0C, $0F, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0F, $0C, $0F, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $00, $0C, $0C, $0C, $0C, $00, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0B, $0B, $0B, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $00, $01, $01, $0C, $0C, $0C, $01, $01, $01, $01, $01, $01, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0F, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $00, $0C, $0C, $0C, $0C, $00, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	.BYTE	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0B, $0C, $0C, $0C

.if DEBUG=1
DIRLEVEL	.BYTE 0

DIR1
	.BYTE 5
	.BYTE 1
	.TEXT "merhaba"
	.FILL 24, 0
.enc screen
	.TEXT "D"
.enc none
	.TEXT "televole"
	.FILL 24, 0
	.TEXT "hello.prg"
	.FILL 23, 0
	.TEXT "africa.koa"
	.FILL 22, 0
	.TEXT "guzel.petg"
	.FILL 22, 0
	
	
DIR2
	.BYTE 6
	.BYTE 1
	.TEXT ".."
	.FILL 29, 0
.enc screen
	.TEXT "D"
.enc none	
	.TEXT "deneme1"
	.FILL 24, 0
.enc screen
	.TEXT "D"
.enc none
	.TEXT "zubazuba"
	.FILL 24, 0
	.TEXT "first.prg"
	.FILL 23, 0
	.TEXT "latina.koa"
	.FILL 22, 0
	.TEXT "spell.petg"
	.FILL 22, 0	
	
DIR3
	.BYTE 6
	.BYTE 1
	.TEXT ".."
	.FILL 29, 0
.enc screen
	.TEXT "D"
.enc none		
	.TEXT "deneme2"
	.FILL 24, 0
.enc screen
	.TEXT "D"
.enc none
	.TEXT "kubakuba"
	.FILL 24, 0
	.TEXT "firzt.prg"
	.FILL 23, 0
	.TEXT "latiya.koa"
	.FILL 22, 0
	.TEXT "spelz.petg"
	.FILL 22, 0		
.endif
DIR3END

	