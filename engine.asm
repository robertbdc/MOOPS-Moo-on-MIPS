.data
turnNumber:
	.align 2
	.space 256 #just nice numbers. I don't really have a sense of actual sizes right now
	
#The address for the label for the 
humanAddress:
	.align 2
	.space 32
	
#The address for the label for the computer's turn
computerAddress:
	.align 2
	.space 32
	
maxTurns:
	.align 2
	.space 32
endGameText:
	.align 2
	.asciiz "Game has ended"
.text
	
#Entry point for engine, initalizes all vars to expected values
engineSetup:	
	la $t0, turnNumber
	li $t1, 1
	sw $t1, 0($t0)
gameLoop:
	jal checkForGameEnd
	beq $v0, 1, endGame	#end the game if checkForGameEnd returned 'true'
	#this will load the proper label addresses from their stored locations
humanTurn:
	la $t0, humanAddress
	lw $t1, 0($t0)
	jalr $t1
computerTurn:
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
	j gameLoop
#Stores result in $v0
#Returns 0 for false, 1 for true

#https://gist.github.com/mlohstroh/dbc2d5a13db11c7c3d97
checkForGameEnd:
	la $t0, turnNumber
	lw $t1, 0($t0)
	la $t0, maxTurns
	lw $t2, 0($t0)
	beq $t2, 0, gameDidNotEnd
	beq $t1, $t2, gameEnded
gameDidNotEnd: 
	li $v0, 0
	jr $ra 
gameEnded:
	li $v0, 1
	jr $ra
	
endGame:
	la $a0, endGameText
	jal printText
	j killProcess
	
