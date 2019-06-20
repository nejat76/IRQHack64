MRH_{0}      	
	LDA {1}				; 2
	STA ACTUAL_LOW		; 3
	LDA {2}				; 4		
	STA ACTUAL_HIGH	 	; 3
	LDA {3}				; 2			
	STA $D012			; 4
	
	LDA {4}				; 2
	STA IRQ6502			; 4
	LDA {5}				; 2
	STA IRQ6502+1		; 4
	LDY #$00			; 2			
	ASL $D019			; 6
	RTI					; 6	