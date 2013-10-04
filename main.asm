.data

playerText:
	.asciiz "The player took a turn\n"
	.align 2
computerText:
	.asciiz "The computer took a turn\n"
	.align 2

.text
	.globl main
	
	#the engine for the turned based program
	.include "engine.asm"
	.include "helpers.asm"

main:

	lw $t0, maxTurns
	li $t0, 5
	sw $t0, maxTurns
	
	la $t0, playerTurn
	sw $t0, humanAddress
	la $t0, computerTurnLabel
	sw $t0, computerAddress
	
	#and so it begins
	j engineSetup

playerTurn:
	move $t0, $ra
	la $a0, playerText
	jal printText
	jr $t0
	
computerTurnLabel:
	move $t0, $ra
	la $a0, computerText
	jal printText
	jr $t0
