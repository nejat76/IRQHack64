;###############################################################################
;	Global.asm
;###############################################################################

;vic-ii data locations
SCREEN_RAM 	= $0400
COLOR_RAM  	= $d800
CHARSET    	= $2800

;Music
music		= $1400		;Müzik dosyasinin yuklenecegi adres
musicPlay	= music+3	;Müzik player adresi

;music		= $6000		;Müzik dosyasinin yuklenecegi adres
;musicPlay	= music+6	;Müzik player adresi

spriteBase = $2140
charset_data = $3480
fileNameData = $C000

;Nmi handler on cart that does the initial transfer of 10 bytes metadata (data_low, data_high, length.. so on)
;Nmi handler on the cart changes the handler to the fast one upon these 10 bytes finishes transferring.
CARTRIDGENMIHANDLER = $8093

CARTRIDGENMIHANDLERX1 = $80af
CARTRIDGENMIHANDLERX4 = $80a0
CARTRIDGENMIHANDLERX8 = $808c

;Locations used by kernal to jump to user provided nmi/irq handler respectively
SOFTNMIVECTOR	= $0318
IRQVECTOR		= $0314

ROMNMIHANDLER	= $FE47 ;Kernal NMI handler - used to restore nmi handler on nmi vector.
ROMIRQHANDLER	= $FF48 ;Kernal IRQ handler - not used

;!if COMPILED_VERSION = VERSION_FLASH OR SIMULATION = 1 {
;numberOfItems	= $2BF0
;numberOfPages	= $2BF1
;PAGEINDEX		= $2BF2
;itemList		= $2C00
;}

MICROLOADSTART	= numberOfItems


;ZERO PAGE ADRESSES
;============================================================================
spAnimationCounter = $10
spColorWashCounter = $11
activeMenuItem  = $12 	;Selected row's number
activeMenuItemAddr = $14 	;Selected row's first color ram address
;           	= $15   ;hi byte for active row's color ram addres
RESERVED 	  	= $05 	;Not used

;temprary variables
var1 			= $18 
var2 			= $19				

;Starting address of data transferred. Menu uses this location to get next / previous
;page of contents from micro.
;DATA_HIGH is not incremented by the loader. Instead ACTUAL_HIGH is used.
;DATA_LOW, DATA_HIGH is also used to launch the loaded program by the loader.
DATA_LOW		= $69
DATA_HIGH 		= $6A
DATA_LENGTH   	= $6B 	;Length (page) of data to be transferred
	
;These are set to DATA_LOW and DATA_HIGH respectively before transfer. 
;Loader uses these locations for actual transfer.
ACTUAL_LOW		= $6C   
ACTUAL_HIGH   	= $6D
ACTUAL_END_LOW	= $6E
ACTUAL_END_HIGH	= $6F


;CONSTANTS
;============================================================================

;Loader on the cartridge rom sets the 6th bit of this location. Which is tested by BIT $64
;command and waiting if overflow flag (which is the 6th bit of this location) is clear.
BITTARGET		= $64
COMMANDINIT		= $45 ;Init command (Micro sends initial state of sd card)
COMMANDNEXTPAGE = $43 ;Next page command
COMMANDPREVPAGE = $41 ;Previous page command
COMMANDENTERMASK= $01 ;Part of the command byte that flags controlling micro that a file/folder is selected.
WAITCOUNT		= 60 ; Frame count to wait between Launching & requesting file list from micro
GOTLISTFROMMICRO = $01 ; Menu state - Got list from micro

