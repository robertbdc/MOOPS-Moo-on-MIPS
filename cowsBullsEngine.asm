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
filledHexArray:
		.asciiz "123456789abcdef"
		.align 2
chosenArray:
		.space 32
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
	jal atoi			#get the integer value from the hex string
	beq $v0, -1, errorOut		#if in put was invalid, errorOut
	sw $v0, playerSecretNumber	#store it off
	
generateComputerSecretNumber: 	#I might redo this label here
	la $s0, chosenArray	#the start of our array of already chosen vars
	la $s1, filledHexArray
	la $s2, computerSecretNumber
	li $s3, 0		#$s3 will serve as our counter for how many numbers we have generated
genLoop:
	li $a1, 16
	jal randomInteger
	move $t0, $a0		#put the index into $t0
	add $t0, $s1, $t0 	#get the exact position of the index in memory
	lb $t1, ($t0)		#get the value at that index
checkIfValueExists:
	li $t2, 0		#set the currentIndex to zero
checkLoop:
	add $t3, $s0, $t2	#get the exact memory position
	lb $t4, ($t3)
	beq $t4, $t1, genLoop	#if we found the value, regenerate
	addi $t2, $t2, 1	#increment index
	bne $t2, 4, checkLoop	#the hard coded value for how many numbers in the array
	#if we got to this point, that value does not exist, increment generatedIndex and store value
	add $t2, $s0, $s3	#get the memory position of where to store the next integer
	sb $t1, ($t2)		#store off the value
	addi $s3, $s3, 1
	bne $s3, 4, genLoop	#if we don't have 4 numbers	
	jal printNewline
	la $a0, chosenArray
	jal printText
	
	
	
errorOut:
	#this is just a placeholder for now, will change in future
	jal printNewline
	la $a0, errorText
	jal printText
	j killProcess
	