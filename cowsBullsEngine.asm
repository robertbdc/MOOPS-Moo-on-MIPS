.data

playerSecretNumber:
		.space 32
		.align 2
computerSecretNumber:
		.space 32
		.align 2
		
humanPromptText:
		.asciiz "Please input your secret number in hex: "
		.align 2
humanGUIText:
		.asciiz "Please try and guess the secret number: "
		.align 2
		
seperatorText:
		.asciiz "\n---------------------------------------------------------\n"
		.align 2
		
errorText:
		.asciiz "An error occurred\n"
		.align 2
filledHexArray:
		.asciiz "0123456789abcdef"
		.align 2
chosenArray:
		.space 32
		.align 2
		
computerPromptText:
		.asciiz "Computers guess was: "
		.align 2
playerInputBuffer:
		.space 32
		.align 2		
numberOfBullsString:
		.asciiz "Number of Bulls: "
		.align 2
numberOfCowsString:
		.asciiz "Number of Cows: "
		.align 2
#store preious guesses as 4 bytes of ASCII		
playerPreviousGuess:
#how much space do we need? how many possible guesses are there?
#16 choose 4 = 16*15*14*13 = 43680 guesses * 4bytes/guess = 174720 bytes
		.space 174720
		.align 2		
playerPreviousResults:
#really only need 3 bits for each guess, because the most cows/bulls you can have is 4
#lets align this one on the half word to make life easier (who wants a 6 bit array?)
#least signifigant byte of 1/2 word will hold number of cows
#most signifigant byte of halfword will hold number of bulls
		.space 87360 #174720/2
		.align 1
.text

.globl main

	.include "engine.asm"
	.include "helpers.asm"
	.include "hexIntConversion.asm"
	.include "checkguess.asm"

main:
	la $a0, humanPromptText
	jal printText
	#j generateComputerSecretNumber
	
inputSecretNumber:
	li $a1, 5
	la $a0, playerInputBuffer
	jal readString
	jal atoi			#get the integer value from the hex string
	beq $v0, -1, errorOut		#if in put was invalid, errorOut
	sw $v0, playerSecretNumber
	
generateComputerSecretNumber:
	la $s0, computerSecretNumber	#the start of our array of already chosen vars
	la $s1, filledHexArray
	li $s3, 0		#$s3 will serve as our counter for how many numbers we have generated
genLoop:
	li $a1, 17
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
	la $a0, computerPromptText #this is all for debugging purposes
	jal printText
	move $a0, $s0
	jal printText #print the comp's secret number
	jal printNewline
	move $a0, $s0
	jal atoi
	sw $v0, computerSecretNumber
setupBasics:
	la $t0, humanTurnCallback	#store off the addresses
	sw $t0, humanAddress
	la $t0, computerTurnCallback
	sw $t0, computerAddress
	sw $zero, maxTurns	#infinite max turns
	
	j engineSetup		#boot up the engine
humanTurnCallback:
	la $a0, humanGUIText
	jal printText
	la $a0, playerInputBuffer	#the input buffer for the
	li $a1, 5			#max number of characters
	jal readString
	lw $a1, ($a0)
	storeArrayWord(playerPreviousGuess, turnNumber, $a1) #save the guess in the array of guesses
	jal atoi
	move $a0, $v0
	lw $a1, computerSecretNumber
	jal checkguess
	storeArrayHalfWord(playerPreviousResults, turnNumber, $v0)	#save the result in the array of results
	move $s0, $v0
	jal printNewline
	move $a0, $s0
	jal compareGuess

computerTurnCallback:
	

	
errorOut:
	#this is just a placeholder for now, will change in future
	jal printNewline
	la $a0, errorText
	jal printText
	j killProcess
	
compareGuess:
	move $t1, $a0 
	move $t7, $ra	#$t7 is the return address
	andi $t0, $t1, 0xF000	#check for validity
	beq $t0, 8 errorOut
	andi $t0, $t1, 0x00F0
	srl $t0, $t0, 4
	la $a0, numberOfBullsString
	jal printText
	move $a0, $t0
	jal printInteger
	push($a0)
	jal printNewline
	pop($a0)
	andi $t0, $t1, 0x000F
	la $a0, numberOfCowsString
	jal printText
	move $a0, $t0
	jal printInteger
	push($a0)
	jal printNewline
	pop($a0)
	jr $t7	#I stored off the return address in $t7
	
