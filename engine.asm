.data
turnNumber:
	.space 256 #just nice numbers. I don't really have a sense of actual sizes right now
	.align 2
	
#The address for the label for the 
humanAddress:
	.space 32
	.align 2
	
#The address for the label for the computer's turn
computerAddress:
	.space 32
	.align 2
	
.text
	
#Entry point for engine, initalizes all vars to expected values
engineSetup:
	la $t0, playerTurn
	li $t1, 0 #player one goes first
	sw $t1, 0($t0)
	
	la $t0, turnNumber
	li $t1, 1
	sw $t1, 0($t0)
gameLoop:
	jal checkForGameEnd
	beq $v0, 1, endGame	#end the game if checkForGameEnd returned 'true'
	#this will load the proper label addresses from their stored locations
	la $t0, humanAddress
	lw $t1, 0($t0)
	jalr $t1
	#Do something with input
	la $t0, computerAddress
	lw $t1, 0($t0)
	jalr $t1
doEndTurn:
	#clean up anything needed here
	la $t0, turnNumber
	lw $t1, 0($t0)
	add $t1, $t1, 1
	sw $t1, 0($t0)
	
#Stores result in $v0
#Returns 0 for false, 1 for true
checkForGameEnd:
	li $v0, 0
	jr $ra
endGame:
	#nothing yet
