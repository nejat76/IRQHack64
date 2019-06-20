;###############################################################################
; IRQHack64 Cartridge Main Menu - by wizofwor/i_r_on
; November 2015 - February 2016
;###############################################################################
!to "build/menu.prg",cbm

SIMULATION = 0 			;0 to compile for read cartrige
						;1 to compile with simulation routines

!src "standart.asm" 	;standard macros & kernal adresses definition 
!src "global.asm" 		;global labels & zp adresses

;--------------------------------------------------------------------------------

;+SET_START $0810
+SET_START $0810

	!src "initialize.asm"

main:
	!src "updateLogo.asm" 	;sprite logo animation
	!src "menuControls.asm"
	jsr musicPlay


jmp main

;--------------------------------------------------------------------------------

!src "subroutines.asm"
!src "data.asm"
