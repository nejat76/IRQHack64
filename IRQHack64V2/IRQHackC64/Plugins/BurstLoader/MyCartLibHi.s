;----------------------------------------------------------------------------------------------------------
; High level interface to the IRQHack64 cartridge.
;----------------------------------------------------------------------------------------------------------
; This interface will deal with opening / closing files. writing / reading them and a bunch of other stuff.
; Each command to the cartridge will have
; A command byte
; <N bytes argument related to the command>
;
; A special location on cartridge rom is used to handshake and get the error status from the cartridge.
; This location is actually used to transfer stuff from cartridge to c64. Cartridge can set a value here
; between 00 and FF. There are more than one such location and its dependent on the loader on the eprom.
; One with a nifty locations is especially left for this interfaces purpose. 
; Its on $80FF and its mirrored on ($81FF, $82FF and so on)
; While cartridge is idle waiting a command this location will always reflect the value of #$00
; While its processing stuff it will have a value of #$01
; Upon performing stuff the value will reflect the error status of the operation. #$80 will be the 
; successful state.
;----------------------------------------------------------------------------------------------------------
; .include "CartLibCommon.s"
; .include "CartLib.s"


;------ Command Byte ------
COMMAND_READ_FILE = 78
COMMAND_OPEN_FILE = 2
COMMAND_CLOSE_FILE = 3
COMMAND_WRITE_FILE = 4
COMMAND_DELETE_FILE = 5
COMMAND_SEEK_FILE = 6
COMMAND_LONG_SEEK_FILE = 7
COMMAND_GET_INFO_FOR_FILE = 8

COMMAND_READ_DIR = 10
COMMAND_CHANGE_DIR = 11
COMMAND_DELETE_DIR = 12
COMMAND_CREATE_DIR = 13

COMMAND_READ_EEPROM = 15
COMMAND_SEEK_EEPROM = 16
COMMAND_WRITE_EEPROM = 17

COMMAND_SET_PORT  = 20
COMMAND_SET_IO  = 21
COMMAND_SET_SOURCE  = 22
COMMAND_INVOKE_WITH_NAME	= 23
COMMAND_INVOKE_WITH_INDEX	= 24
COMMAND_STREAM	= 25
COMMAND_NI_STREAM = 26

COMMAND_END_TALKING  = 30
COMMAND_EXIT_TO_MENU  = 31

;------ Kernal params ------
FILE_LENGTH		= $B7
FILENAME_LOW	= $BB
FILENAME_HIGH	= $BC

SOURCE_TYPE_SD  = 1
SOURCE_TYPE_HTTP  = 2
SOURCE_TYPE_FTP  = 3


;------------- File functions ------------

;-----------------------------------------
; Registers In : None
; Registers Used : A
; Registers Out : A (Processing status)
;-----------------------------------------
IRQ_WaitProcessing
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
-
	LDA CARTRIDGE_BANK_VALUE	
	BEQ -
	BPL +
	CLC
	RTS
+
	SEC	
	RTS


; Used to retrieve error status along with a one byte response
; Like normal commands CARTRIDGE_BANK_VALUE initially set as 0 by the micro
; When the processing is done, cartridge sets this value to a 1-$7F for error response.
; If there is no error than the low byte of response is encoded in the successful response 
; which would be B1xxxxxxV where V is the least significant bit of the response.
; Then c64 would read another value from the CARTRIDGE_BANK_VALUE that is positive in the form B0VVVVVVV
; Where VVVVVVV is the most significant 7 bits of the response.
; This is (I hope) is simpler than triggering an nmi interrupt and setting a bank value for response.

IRQ_ReadErrorOrByte	
-
	LDA CARTRIDGE_BANK_VALUE	
	BEQ -						; Wait response being switched from zero to non zero value

	BPL +						; If its a non negative value than its an error
	LSR							; Put the least significant bit in the carry

-
	LDA CARTRIDGE_BANK_VALUE	
	BMI -						; Wait till the micro switches to the non zero response
	ASL                         ; Combine the least significant bit into the response
	CLC 						; Successful
	RTS
+
	SEC							; Specify error condition A register contains the error
	RTS

;-----------------------------------------
; Registers In : A (size of file name), X (high address of filename buffer), Y (low address of filename buffer)
; Registers Used : None
;-----------------------------------------
IRQ_SetName
	STA FILE_LENGTH
	STX FILENAME_LOW
	STY FILENAME_HIGH
	RTS

;-----------------------------------------
; Registers In : None
; Registers Used : A, X, Y
;-----------------------------------------
IRQ_SendFileName
	LDA FILE_LENGTH
	JSR IRQ_Send	
	LDX FILE_LENGTH
	LDY #$00
-	
	LDA (FILENAME_LOW), Y
	JSR IRQ_Send
	INY
	DEX
	BNE -
	RTS

IRQ_ProcessFileCommand	.macro
	JSR IRQ_SendFileName	
	JSR IRQ_WaitProcessing	
	.endm

; Opens file for reading/writing
;-----------------------------------------
; Registers In : X (Opening mode)
; Registers Used : A, X, Y
; Registers Out : A (Status of operation)
;-----------------------------------------	
IRQ_OpenFile
	LDA #COMMAND_OPEN_FILE
	JSR IRQ_Send
	TXA
	JSR IRQ_Send ;Send flags

	IRQ_ProcessFileCommand
	RTS


; Closes currently opened file
;-----------------------------------------
; Registers In : None
; Registers Used : A
; Registers Out : A (Status of operation)
;-----------------------------------------	
IRQ_CloseFile
	LDA #COMMAND_CLOSE_FILE
	JSR IRQ_Send
	JSR IRQ_WaitProcessing	
	RTS



; Sets up micro to stream content from current open file. 
; Micro sends 8 bytes for each flagging of cartridge receive port
; Receiver should hard syncronize itself to this 8 bytes.
; Receiver should send the number of 8 bytes to receive. This should not exceed 50 or else the command fails.
; Unlike normal streaming micro handles this type of streaming in the foreground and doesn't use interrupts.
; To stop streaming...[TODO]
;-----------------------------------------
; Registers In : A (8 byte fragment count)
; Registers Used : A, X, Y
; Registers Out : A (Status of operation)
;-----------------------------------------	
IRQ_NIStream
	PHA
	LDA #COMMAND_NI_STREAM
	JSR IRQ_Send	
	PLA
	JSR IRQ_Send
	
	JSR IRQ_WaitProcessing		
	RTS	
	
	
; Ends talking and exits to menu
;-----------------------------------------
; Registers In : None
; Registers Used : A
; Registers Out : A (Status of operation)
;-----------------------------------------	
IRQ_ExitToMenu
	LDA #COMMAND_EXIT_TO_MENU
	JSR IRQ_Send
	JSR IRQ_WaitProcessing	
	RTS	
	
;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_DisableDisplay
	LDA VIC_CONTROL_1
	AND #$EF
	STA VIC_CONTROL_1	
	RTS
	
;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_EnableDisplay
	LDA VIC_CONTROL_1
	ORA #VIC_DEN
	STA VIC_CONTROL_1	
	RTS	

;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_EnableRasterInterrupts
	LDA #$01
	STA VIC_INT_CONTROL	;Enable raster interrupts
	RTS

