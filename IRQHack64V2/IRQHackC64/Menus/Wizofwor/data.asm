;-------------------------------------------------------
; INITIAL SCREEN
;-------------------------------------------------------

repeat_bytes:
!by $01,$17,$01,$0f
!by $01,$17,$01,$0f
!by $01,$16,$01,$01,$0f
!for n,1,21 {!by $01,$16,$01,$01,$0f}
!by $01,$17,$01,$0F
!by $00

char_bytes:
!by $40,$41,$42,$00
!by $43,$53,$44,$00
!by $45,$49,$4a,$46,$00
!for n,1,21 {!by $47,$20,$4b,$48,$00}
!by $50,$51,$52,$00

color_bytes:
!by $01,$0d,$01,$00
!by $0d,$05,$0d,$00
!by $0d,$0f,$0b,$0d,$00
!for n,1,21 {!by $0d,$0f,$0b,$0d,$00}
!by $05,$0d,$0d,$00,$00

;* = $3000 ;walkaround for is segment override problem 

spriteX:
!by 232,0,24,48

spriteY:
!by 65,86,112,132,160,181

spriteSinus:
!for n,1,2 {
!by 8,7,6,5,4,4,3,2,2,1,1,0,0,0,0,0
!by 0,0,0,0,0,1,1,2,2,3,3,4,5,6,6,7
!by 8,9,9,10,11,12,12,13,13,14,14,15,15,15,15,15
!by 15,15,15,15,15,14,14,13,13,12,11,11,10,9,8,8
}

spColorOffset:
!by 3,2,2,2,1,1,1,1,0,0,0,0,0,0,0,0
!by 0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,2
!by 3,3,3,4,4,4,4,5,5,5,5,5,5,5,5,5
!by 5,5,5,5,5,5,5,5,4,4,4,4,3,3,3,3
!fill 65,0

spColor1: !by 1,1,15,12,11,0
spColor2: !by 6,6,6,11,11,0
spColor3: !by 14,14,4,12,11,0

;-------------------------------------------------------
; Test Data
;-------------------------------------------------------

title:
!scr "/micro sd         "

titleTurbo:
!scr "/micro sd  (turbo)"


;text:
;!scr " menu item 12345"

;lookup:
;!by 4,44,84,214

menuState:
!by 0			; Menu state (0 = Launched, 1 = Got list from micro)

waitCounter:
!by WAITCOUNT



NMITAB:
!by <CARTRIDGENMIHANDLERX1, <CARTRIDGENMIHANDLERX4, <CARTRIDGENMIHANDLERX8

;-------------------------------------------------------
; Fixed Adress Data
;-------------------------------------------------------

musicActual:
!bin "resources/Jamaica_10_intro_reloc.sid",3167,$7c+2
musicActualEnd = *-1

spriteBaseActual:
!bin "resources/sprites.bin",1536
spriteBaseActualEnd = *-1

charsetBaseActual:
!bin "resources/charset.bin",1000
charsetBaseActualEnd = *-1

fileNameDataActual:
fileNameDataActualEnd = fileNameDataActual + 656

!if SIMULATION = 0 {
numberOfItems = fileNameData
numberOfPages = fileNameData + 1
PAGEINDEX = fileNameData + 2
TRANSFERMODE = fileNameData + 3
itemList = fileNameData + 16
}
