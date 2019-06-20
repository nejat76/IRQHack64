IRQ_WaitHandle			= $64
IRQ_DATA_LOW 			= $6C
IRQ_DATA_HIGH 			= $6D
;IRQ_DATA_LENGTH 		= $6E
IRQ_DATA_LENGTH 		= $6B
IRQ_CALLBACK_LO 		= $80
IRQ_CALLBACK_HI 		= $81

IRQ_SEEK_LOW = $69
IRQ_SEEK_HIGH = $6A
IRQ_SEEK_UPPER_LOW = $80
IRQ_SEEK_UPPER_HIGH = $81

IRQ_TEMP = $82

ROM_IRQ_HANDLER			= $FFFE
ROM_NMI_HANDLER			= $FFFA
IRQ_SOFTNMIVECTOR		= $0318
CARTRIDGENMIHANDLERX1 	= $80af
CARTRIDGENMIHANDLERX4	= $80a0
CARTRIDGENMIHANDLERX8 	= $808c

;CARTRIDGE_BANK_VALUE	= $80FF			;On new roms
CARTRIDGE_BANK_VALUE	= $80AB			;On old roms

; CART_SEND_PORT			= $DE00
; CART_SEND_COMPLETED_PORT = $DE01


;-- Cartridge Bank Value ------------------------

CARTRIDGE_READY 		= $00					; Cartridge is idle waiting a talk message or a command
CARTRIDGE_PROCESSING	= $01					; Cartridge is processing a command
CARTRIDGE_FILE_IO_ERROR	= $02					; A file error occured.
;TODO : Add other error descriptors when available
CARTRIDGE_PROCESS_OK	= $80					; Cartridge performed requested operation successfully


;-- Complex Interface Adapter -------------------

CIA_1_BASE 				= $DC00
CIA_2_BASE 				= $DD00

DATA_A					= 0
DATA_B					= 1

DDR_A					= 2
DDR_B					= 3

TIMER_A_LO				= $04
TIMER_A_HI				= $05

;-- CIA Registers
CIA_INT_MASK			= $0D
CIA_TIMER_A_CTRL		= $0E
CIA_TIMER_B_CTRL		= $0F

;-- CIA Enums
CRA_TOD_IN_50HZ			= 128
CRA_SP_MODE_OUTPUT		= 64
CRA_IN_MODE_CNT 		= 32
CRA_FORCE_LOAD 			= 16
CRA_RUN_MODE_ONE_SHOT 	= 8
CRA_OUT_MODE_TOGGLE 	= 4
CRA_PB6_ON 				= 2
CRA_START 				= 1

;-- Video Interface Chip ------------------------
VIC_CONTROL_1			= $D011
VIC_INT_CONTROL			= $D01A
VIC_INT_ACK				= $D019
VIC_BORDER_COLOR		= $D020

;-- VIC Enums
VIC_DEN					= 16	

;-- 
PROCESSOR_PORT			= $01
PP_CONFIG_ALL_RAM		= $34			; RAM visible in $A000-$BFFF, $E000-$FFFF, $D000-$DFFF
PP_CONFIG_RAM_ON_ROM	= $35			; RAM visible in $A000-$BFFF, $E000-$FFFF
PP_CONFIG_RAM_ON_BASIC	= $36			; RAM visible in $A000-$BFFF
PP_CONFIG_DEFAULT		= $37			; $A000-$BFFF, $E000-$FFFF is ROM, default config.