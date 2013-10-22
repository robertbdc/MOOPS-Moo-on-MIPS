.data

playerSecretNumber:
		.space 32
		.align 2
computerSecretNumber:
		.space 32
		.align 2
		
promptText:
		.asciiz "Please input your secret number in hex\n"
		.align 2
		
seperatorText:
		.asciiz "\n---------------------------------------------------------\n"
		.align 2
		
errorText:
		.asciiz "An error occurred\n"
		.align 2

.text

.globl main

	#.include "engine.asm"
	.include "helpers.asm"
	.include "hexIntConversion.asm"

main:
	la $a0, promptText
	jal printText
	
inputSecretNumber:
	li $a1, 5
	jal readString
	jal atoi	#get the integer value from the hex string
	beq $v0, -1, errorOut
	sw $v0, playerSecretNumber
	
errorOut:
	#this is just a placeholder for now, will change in future
	la $a0, errorText
	jal printText
	j killProcess
	