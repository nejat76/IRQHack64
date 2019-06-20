; Input:  A NUL-terminated, <255-length pattern at address PATTERN.
;         A NUL-terminated, <255-length string pointed to by STR.
;
; Output: Carry bit = 1 if the string matches the pattern, = 0 if not.
;
; Notes:  Clobbers A, X, Y. Each * in the pattern uses 4 bytes of stack.
;

MATCH1  = "?"         ; Matches exactly 1 character
MATCHN  = "*"         ; Matches any string (including "")
STR     = $6          ; Pointer to string to match

PATTERNMATCH:
    LDX #$00        ; X is an index in the pattern
    LDY #$FF        ; Y is an index in the string
NEXTPM   
	LDA $C000,X   ; Look at next pattern character		(Nejat: $C000 is just a placeholder)
    CMP #MATCHN     ; Is it a star?
    BEQ STAR        ; Yes, do the complicated stuff
    INY             ; No, let's look at the string
    CMP #MATCH1     ; Is the pattern caracter a ques?
    BNE REG         ; No, it's a regular character
    LDA (STR),Y     ; Yes, so it will match anything
    BEQ FAILPM        ;  except the end of string
REG 
    CMP (STR),Y     ; Are both characters the same?
    BNE FAILPM        ; No, so no match
    INX             ; Yes, keep checking
    CMP #0          ; Are we at end of string?
    BNE NEXTPM        ; Not yet, loop
	
FOUNDPM   
	RTS             ; Success, return with C=1

STAR    
	INX             ; Skip star in pattern
CMPSTM	
    CMP $C000,X   ; String of stars equals one star (Nejat: $C000 is just a placeholder)
    BEQ STAR        ;  so skip them also
STLOOP
	TXA             ; We first try to match with * = ""
    PHA             ;  and grow it by 1 character every
    TYA             ;  time we loop
    PHA             ; Save X and Y on stack
    JSR NEXTPM        ; Recursive call
    PLA             ; Restore X and Y
    TAY
    PLA
    TAX
    BCS FOUNDPM       ; We found a match, return with C=1
    INY             ; No match yet, try to grow * string
    LDA (STR),Y     ; Are we at the end of string?
    BNE STLOOP      ; Not yet, add a character
FAILPM
    CLC             ; Yes, no match found, return with C=0
	RTS
	
;--------------------------------------
;A - Low byte of pattern address
;X - High byte of pattern address	
;--------------------------------------
INITPATTERN
	STA CMPSTM+1
	STX CMPSTM+2
	STA NEXTPM+1
	STX NEXTPM+2	
	
	RTS