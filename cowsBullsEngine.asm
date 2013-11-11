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
		.space 36
		.align 2		
invCharPrompt:
	.asciiz "\nERROR: valid digits are 0-9 and A-F only\n"
	.align 2
reusedDigitPrompt:
	.asciiz "\nERROR: all digits in the number must be unique\n"	
	.align 2
alreadyGuessedPrompt:
	.asciiz "\nERROR: number has already been guessed\n"
	.align 2		
playerWinPrompt:
	.asciiz "\n4 bulls -> YOU WIN!\n"		
	.align 2
computerWinPrompt:
	.asciiz "\nComputer got 4 bulls -> YOU LOSE!\n"		
	.align 2	
numberOfBullsString:
		.asciiz "Number of Bulls: "
		.align 2
numberOfCowsString:
		.asciiz " Number of Cows: "
		.align 2
.text

.globl main

	.include "engine.asm"
	.include "helpers.asm"
	.include "hexIntConversion.asm"
	.include "checkguess.asm"
	.include "CpuGuess.asm"
	.include "previousGuesses.asm"

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
	
############ human turn ####################	
humanTurnCallback:
	la $a0, seperatorText
	jal printText
	jal printPreviousGuesses
   getInput:
	la $a0, humanGUIText
	jal printText
	la $a0, playerInputBuffer	#the input buffer for the
	li $a1, 5			#max number of characters
	jal readString
	lw $s6, ($a0)   #s6 has the string read in
	jal atoi
	beq $v0, -1, handleInvChar #ERROR:number uses invalid characters
	move $a0, $v0
	lw $a1, computerSecretNumber
	jal checkguess
	move $s5, $v0  #s5 has the result from checkguess in it
	move $s0, $v0
	jal printNewline
	move $a0, $s0
   #checkGuessValidity:
	move $t1, $a0 
	andi $t0, $t1, 0xF000	#check for validity
	beq $t0, 0x8000, handleReusedDigit #ERROR: number uses a digit more than once
   #check for win
   	andi $t0, $t1, 0x000000F0
   	beq $t0, 0x00000040, playerWin
	la $a0, playerInputBuffer
	lw $a1, turnNumber
	jal alreadyGuessed
	beq $v0, 1, handleAlreadyGuessed #ERROR: number was already guessed
	storeArrayHalfWord(playerPreviousResults, turnNumber, $s5)	#save the result in the array of results
	storeArrayWord(playerPreviousGuess, turnNumber, $s6) #save the guess in the array of guesses
   exitHumanTurn:		
	j computerTurn #jump back to the engine

playerWin:
	la $a0, playerWinPrompt
	jal printText
	jal endGame
	
# error handling 
handleInvChar:
	la $a0, invCharPrompt
	j errorOut
handleReusedDigit:
	la $a0, reusedDigitPrompt
	j errorOut
handleAlreadyGuessed:
	la $a0, alreadyGuessedPrompt
	j errorOut
errorOut:
	jal printText
	j getInput		
	
############ computer turn ####################	
computerTurnCallback:
	#TODO: call function for computer guess
	lw $t0, turnNumber
	bgt $t0, 1, getPreviousResult
  initialSetup:
  	add	$a0, $zero, $zero
	j callAI
  getPreviousResult:
  	pop($a0)
  callAI:
  	jal	cpuguess
  storeResult:
  	push($v0)
  	add	$s0, $zero, $v0	# save guess
  	
  	# convert integer in $a0 back to ascii for display
	# $v0 points to ascii buffer (not null terminated)
	add $a0, $zero, $s0
	jal itoa 
	
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t0, 0($v0)
	sw $t0, playerInputBuffer
	sw $zero, playerInputBuffer + 4
  checkResult:
  	move $a0, $s0
  	lw $a1, playerSecretNumber
  	jal checkguess
	move $t1, $v0 
   #check for win
   	andi $t0, $t1, 0x000000F0
   	beq $t0, 0x00000040, computerWin
   	srl $t0, $t0, 4                       #t0 now has the number of bulls
   	andi $t1, $t1, 0x0000000F             #t1 now has the number of cows
	
  printResult:
  	la $a0, seperatorText
  	jal printText 
  	la $a0, computerPromptText
  	jal printText
  	la $a0, playerInputBuffer
  	jal printText
  	jal printNewline
  	la $a0, numberOfBullsString
  	jal printText
  	move $a0, $t0
  	jal printInteger
  	la $a0, numberOfCowsString
  	jal printText
  	move $a0, $t1
  	jal printInteger
  	jal printNewline
  	
  exitComputerCallback:			
	j doEndTurn
	
computerWin:
	la $a0, computerWinPrompt
	jal printText
	jal endGame		