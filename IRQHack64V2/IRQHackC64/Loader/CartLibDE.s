;----------------------------------------------------------------------------------------------------------
; Low level interface to the IRQHack64 cartridge.
;----------------------------------------------------------------------------------------------------------
; Routines that are exposed are as below.
; IRQ_StartTalking
; IRQ_EndTalking
; IRQ_Send
; IRQ_SendFragment
; IRQ_ReceiveFragment
;
; Code is relocatable and fits into the datasette buffer. 
; Refer to the CartLibHi for more higher level api for interfacing to the cartridge.
;----------------------------------------------------------------------------------------------------------

.include "CartLibCommonDE.s"

;----------- Utility routines ----------------------

MODULATION_ADDRESS	= $DF00

;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_DisableVICInterrupts
	ASL VIC_INT_ACK
	LDA #$00
	STA VIC_INT_CONTROL	
	RTS

;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_DisableCIAInterrupts
	LDA #$7f    					; $7f = %01111111 
    STA CIA_1_BASE + CIA_INT_MASK	; Turn off CIA 1 interrupts 
    STA CIA_2_BASE + CIA_INT_MASK	; Turn off CIA 2 interrupts 	
    LDA CIA_1_BASE + CIA_INT_MASK	; cancel all CIA-IRQs in queue/unprocessed 
    LDA CIA_2_BASE + CIA_INT_MASK	; cancel all CIA-IRQs in queue/unprocessed 
	RTS
	
;-----------------------------------------
; Registers In : None
; Registers Used : A
;-----------------------------------------	
IRQ_DisableInterrupts
	JSR IRQ_DisableVICInterrupts
	JSR IRQ_DisableCIAInterrupts
	RTS


	
	

	
NMITAB	
	.BYTE <CARTRIDGENMIHANDLERX1, <CARTRIDGENMIHANDLERX4,<CARTRIDGENMIHANDLERX8


;----------- API routines ----------------------
	
; Sends a special set of bytes to wake the cartridge to listen for actual
; commands. With the esp8266 version sending is accomplished using two ports so
; IRQs are not used.
;-----------------------------------------
;Registers In : None
;Registers Used : A
;-----------------------------------------
IRQ_StartTalking
	LDA MODULATION_ADDRESS
	;JSR IRQ_DisableInterrupts
		
	LDA #$64;#73							; I	
	JSR IRQ_Send
	LDA #$46;#82							; R	
	JSR IRQ_Send
	LDA #$17;#81							; Q	
	JSR IRQ_Send
		
	RTS

;-----------------------------------------
;Registers In : None
;Registers Used : A
;-----------------------------------------
IRQ_EndTalking
	LDA #30							;End Talking command
	JSR IRQ_Send
	;JSR IRQ_DisableCIAInterrupts
		
	LDA #PP_CONFIG_DEFAULT
	STA PROCESSOR_PORT
	RTS	
	

	
;-----------------------------------------
;Registers In : A (Byte to send)
;Registers Used : X
;-----------------------------------------
IRQ_SendBit
	JSR WasteTooMuchTime
	LSR
	BCC +
	;LDX #255
	LDX #12
	BNE _continue					; Fake unconditional jump, to make code relocatable.
+
	;LDX #128
	LDX #6
_continue
	
	LDY MODULATION_ADDRESS						; Cause interrupt on Attiny85
	JSR WasteCertainTime		
	LDY MODULATION_ADDRESS

		

	RTS
	

WasteCertainTime
-	
	DEX
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	;
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

	BNE -
	RTS

WasteTooMuchTime	
	;LDX #15
	LDX #1
OUTERWASTE	
	LDY #$FF
-	
	DEY
	NOP
	BNE -
	DEX
	BNE OUTERWASTE
	RTS
	


;----------- API routines ----------------------
	


; We will send 
; long interval Kernal Accesses for transmitting 1
; short interval Kernal Accesses for transmitting 0
; The idea here is : Receiver will measure the signal on /OE line. 
; It will measure how long the signal is kept high between two low states. (L/H/L) __|''|__
; If its in the range say N-Epsilon, N+Epsilon than c64 is transmitting a ZERO
; If its in the range say N*2-Epsilon, N*2+Epsilon than c64 is transmitting a ONE
;-----------------------------------------
; Registers In : A (Byte to send)
; Registers Used : X
;-----------------------------------------
IRQ_Send
	STA IRQ_TEMP
	TXA
	PHA
	TYA
	PHA
	LDA IRQ_TEMP
	
	JSR IRQ_SendBit
	JSR IRQ_SendBit
	JSR IRQ_SendBit
	JSR IRQ_SendBit	
	JSR IRQ_SendBit
	JSR IRQ_SendBit
	JSR IRQ_SendBit
	JSR IRQ_SendBit
	
	PLA
	TAY
	PLA
	TAX
	
	RTS
	
	


; Use to send buffered 32 bytes to the micro. (For ex. writing to a file)
;-----------------------------------------
; Setup : 
; IRQ_DATA_LOW = $69
; IRQ_DATA_HIGH = $6A
;-----------------------------------------
; Registers in : None
; Registers used : A, X, Y
;-----------------------------------------
IRQ_SendFragment
	LDY #$00
-	
	LDA (IRQ_DATA_LOW), Y
	JSR IRQ_Send
	CPY #$20
	BNE -
	RTS


; Reads/Receives content from currently opened file. Caller supplies the target address where the data will be transferred.
; Caller supplies return address at CALLBACK_LO / CALLBACK_HI and this routine will resume control from that address using a fake RTS.
; In this way, loading and invoking another executable is made simple.
; Screen should be disabled or one should ensure that no cycle is stealed (VIC) during this routine.
;-----------------------------------------
; Setup : 
; IRQ_DATA_LOW = $6C
; IRQ_DATA_HIGH = $6D
; IRQ_DATA_LENGTH = $6E
; IRQ_CALLBACK_LO = $80
; IRQ_CALLBACK_HI = $81
;-----------------------------------------
; Registers In  : Y - (Transfer Mode)
; Registers Out : None
;-----------------------------------------
IRQ_ReceiveFragment
	;JSR IRQ_DisableInterrupts
	LDA NMITAB, Y
	STA IRQ_SOFTNMIVECTOR	
	LDA #$80					;HIGH portion of $8000 (Cartridge ROM address)
	STA IRQ_SOFTNMIVECTOR+1	

	LDA #$00
	STA IRQ_WaitHandle
	
	LDA #PP_CONFIG_DEFAULT
	STA PROCESSOR_PORT

	LDX IRQ_DATA_LENGTH
   	LDY #$00	;Setup for transfer routine  	
	
	CLV	
-
	BIT IRQ_WaitHandle	
	BVC -		

	
;	TSX 
;	STX $C100
;AG	
;	LDY #00
;-	
;	LDA $0100, Y
;	STA $C000, Y
;	INY
;	BNE -

	;JMP AG
	;JMP *
	; Remove last RTS
	;TSX
	;INX
	;INX
	;TXS
	;JMP $0905
	; Do a fake RTS
	LDA IRQ_CALLBACK_HI
	PHA
	LDA IRQ_CALLBACK_LO
	PHA
	RTS
	
	


; Reads/Receives content from micro. Caller supplies the target address where the data will be transferred.
; In this way, loading and invoking another executable is made simple.
; Screen should be disabled or one should ensure that no cycle is stealed (VIC) during this routine.
;-----------------------------------------
; Setup : 
; IRQ_DATA_LOW = $6C
; IRQ_DATA_HIGH = $6D
; IRQ_DATA_LENGTH = $6E
;-----------------------------------------
; Registers In  : Y - (Transfer Mode)
; Registers Out : None
;-----------------------------------------
IRQ_ReceiveFragmentNoCallback
	;JSR IRQ_DisableInterrupts
	LDA NMITAB, Y
	STA IRQ_SOFTNMIVECTOR	
	LDA #$80					;HIGH portion of $8000 (Cartridge ROM address)
	STA IRQ_SOFTNMIVECTOR+1	

	LDA #$00
	STA IRQ_WaitHandle
	
	LDA #PP_CONFIG_DEFAULT
	STA PROCESSOR_PORT

	LDX IRQ_DATA_LENGTH
   	LDY #$00	;Setup for transfer routine  	
	
	CLV	
-
	BIT IRQ_WaitHandle	
	BVC -		

	LDA #0	
	CLC		;Indicate successful execution of command that invoked this (instead of using callback)
	RTS	
	
	
;FE43   78         SEI			;2
;FE44   6C 18 03   JMP ($0318)  ;5
TransferHandler					;7
	LDA CARTRIDGE_BANK_VALUE	;4
	STA (IRQ_DATA_LOW), Y		;6
	INY							;2
	BEQ ENDOFBLOCK				;2-3	
	RTI							;6
	
ENDOFBLOCK
	INC IRQ_DATA_HIGH				; Next 256 bytes
	DEX							; Decrement data length (set in STARTNMI)
	BEQ ENDOFTRANSFER			; If all pages  transferred exit foreground loop
	RTI
ENDOFTRANSFER
	LDA #$64
	STA IRQ_WaitHandle												
	RTI		

