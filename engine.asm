	.data
playerTurn: 
	.space 4
	.align 2
turnNumber
	.space 256 #just nice numbers. I don't really have a sense of actual sizes right now
	.align 2
	
	.text
	
#Entry point for engine, initalizes all vars to expected values
engineSetup:
	la $t0, playerTurn
	li $t1, 0 #player one goes first
	sw $t1, $t0
	
	la $t0, turnNumber
	li $t1, 1
	sw $t1, $t0

