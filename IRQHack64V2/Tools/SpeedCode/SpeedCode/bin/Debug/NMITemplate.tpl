NMI_{0}  
	LDA #$37			
	STA $01				
	
	LDA $80FF
	STA {1}	

	LDA $80FF
	STA {2}		

	LDA $80FF
	STA {3}	
	
	LDA $80FF
	STA {4}	

	LDA $80FF
	STA {5}	

	LDA $80FF
	STA {6}	

	LDA $80FF
	STA {7}		
	
	LDA $80FF
	STA {8}		
								
	LDA #<NMI_{9}
	STA NMI6502
	LDA #>NMI_{10}
	STA NMI6502 + 1
	
	LDA #$35
	STA $01
	RTI	