.text

.globl main

	.include "engine.asm"
	.include "helpers.asm"
	.include "hexIntConversion.asm"
	.include "previousGuesses.asm"
	.include "checkguess.asm"
	.include "cpuGuess.asm"
	.include "music.asm"
	
main:
  introduction:
	la $a0, introText
	jal printText
  introMusic:
  	la $a0, soundIntroText
  	jal printText
	la $a0, introTextBull
	jal printText
	li $a0, 1			#play 1 bull
	jal playBulls
	la $a0, introTextCow
	jal printText
	li $a1, 1			#play 1 cow
	jal playCows
  modeSelection:	
	la $a0, modeSelectionText
	jal printText
	jal readInt
	blt $v0, 0, modeError
	bgt $v0, 3, modeError
	beq $v0, 0, introMusic
	beq $v0, 1, mode1
	beq $v0, 2, mode2
	beq $v0, 3, mode3
    mode1:                               #1 player
	jal generateComputerSecretNumber	
	la $t0, humanTurnCallback	
	sw $t0, humanAddress
	la $t0, doEndTurn
	sw $t0, computerAddress		#skip over computer turn
	j exitModeSelection
    mode2:                               #AI only
	jal inputSecretNumber
	la $t0, computerTurnCallback	#skip over the human turn
	sw $t0, humanAddress
	la $t0, doEndTurn
	sw $t0, computerAddress
	j exitModeSelection
    mode3:                               #Player vs. AI
    	jal inputSecretNumber
    	jal generateComputerSecretNumber
	la $t0, humanTurnCallback	
	sw $t0, humanAddress
	la $t0, computerTurnCallback
	sw $t0, computerAddress
	j exitModeSelection
    exitModeSelection:
	sw $zero, maxTurns		#infinite max turns 
	j engineSetup			#boot up the engine    		 
    modeError:
	la $a0, modeErrorText
	jal printText
	j modeSelection	
	
  inputSecretNumber:
  	push($ra)
	la $a0, humanPromptText
	jal printText
	li $a1, 5
	la $a0, playerInputBuffer
	jal readString
	jal atoi			        #get the integer value from the hex string
	beq $v0, -1, handleInvChar		#if input was invalid, errorOut
	sw $v0, playerSecretNumber
	move $a0, $v0
	jal checkValidity                       #check for repeated digits
	move $t1, $v0 
	andi $t0, $t1, 0xF000	                #check for validity
	beq $t0, 0x8000, handleReusedDigit      #ERROR: number uses a digit more than once
	pop($ra)
	jr $ra
	
  generateComputerSecretNumber:
  	push ($ra)
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
	move $a0, $s0
	jal atoi
	sw $v0, computerSecretNumber
	pop($ra)
	jr $ra
	
############ human turn ####################	
humanTurnCallback:
	la $a0, seperatorText
	jal printText
   printTurnNumber:	
	la $a0, turnString
	jal printText
	lw $a0, turnNumber 
	jal itoa
	move $t0, $v0          #t0 has address of turn # string
	sb $zero, 5($t0)
    removeLeadingZeros:	
	lw $t1, ($t0)            #t1 has the turn string	
	andi $t2, $t1, 0x00FFFFFF #three leading zeros
	bne $t2, 0x00303030, check2leading
     handle3leading:
        srl $t1, $t1, 24
        sw $t1, ($t0)
        j printIt	
     check2leading:
        andi $t2, $t1, 0x0000FFFF #two leading zeros
	bne $t2, 0x00003030, check1leading	
     handle2leading:
     	srl $t1, $t1, 16
        sw $t1, ($t0)
        j printIt
     check1leading:
        andi $t2, $t1, 0x000000FF #one leading zero
	bne $t2, 0x00000030, printIt	
     handle1leading:
        srl $t1, $t1, 8
        sw $t1, ($t0)
        j printIt	
     printIt:
     	move $a0, $t0	
	jal printText
	la $a0, seperatorText
	jal printText
	#la $a0, playerPrevGuessHeader
	#jal printText
	li $a0, 1
	jal printPreviousGuesses
   getInput:
	la $a0, humanGUIText
	jal printText
	la $a0, playerInputBuffer	#the input buffer for the
					#max number of characters
	li $a1, 5			#5 characters to allow it to be null terminated later				
	jal readString
	lw $s6, playerInputBuffer       #save the input for later
	jal atoi
	beq $v0, -1, handleInvChar #ERROR:number uses invalid characters
	move $a0, $v0
	lw $a1, computerSecretNumber
	jal checkguess
	move $s5, $v0  #s5 has the result from checkguess in it
   checkGuessValidity:
	move $t1, $s5 
	andi $t0, $t1, 0xF000	#check for validity
	beq $t0, 0x8000, handleReusedDigit #ERROR: number uses a digit more than once
   checkForWin:
	andi $t0, $t1, 0x000000F0
	beq $t0, 0x00000040, playerWin
	la $a0, playerInputBuffer
	lw $a1, turnNumber
	li $a2, 1
	jal alreadyGuessed
	beq $v0, 1, handleAlreadyGuessed #ERROR: number was already guessed
   printHumanResult:
	jal printNewline
	
	la $a0, numberOfBullsString
	jal printText
	
	andi $a0, $s5, 0x000000F0
	srl $a0, $a0, 4
	jal printInteger

	move $t0, $a0
	
	la $a0, numberOfCowsString
	jal printText
	
	andi $a0, $s5, 0x0000000F
	jal printInteger
	
	lw $t9, muteCows # If the cows are keeping the chickens awake, make them be quiet!
	bne $t9, $zero, noPlayCows
	move $a1, $a0
	move $a0, $t0
	jal playCowsAndBulls
noPlayCows:
	
	jal printNewline
	jal printNewline	
	storeArrayHalfWord(playerPreviousResults, turnNumber, $s5)	#save the result in the array of results
	la $a0, playerInputBuffer
	jal toUpper
	lw $s6, playerInputBuffer
	storeArrayWord(playerPreviousGuess, turnNumber, $s6)            #save the guess in the array of guesses
   exitHumanTurn:		
	j computerTurn #jump back to the engine

playerWin:
	la $a0, playerWinPrompt
	jal printText
	j endGame	# terminates program
	
# error handling 
handleInvChar:
	# Is it a cheat code?
	lw $t9, cheat_soff
	beq $s6, $t9, cheatShutUp
	lw $t9, cheat_look
	beq $s6, $t9, cheatLook
	lw $t9, cheat_exit
	beq $s6, $t9, cheatExit
	j justPlainInvalid
cheatShutUp:
	addi $t9, $zero, 0xFF
	sw $t9, muteCows	# nonzero = shut up
	j cheatDone
cheatLook:
	jal printNewline
	la $a0, computerPromptText #this is all for debugging purposes
	jal printText
	lw $a0, computerSecretNumber
	jal itoa
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t9, 0($v0)
	la $a0, playerInputBuffer
	sw $t9, 0($a0)
	sw $zero, 4($a0)
	jal printText #print the comp's secret number
	j cheatDone
cheatExit:
	# future: add confirmation?
	jal printNewline
	j endGame	# terminates program

cheatDone:
	la $a0, cheatCodePrompt
	j errorOut
justPlainInvalid:			
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
	lw $t6, turnNumber
	beq $t6, 0, inputSecretNumber 
	j getInput		
	
############ computer turn ####################	
computerTurnCallback:
	lw $a0, computerLastGuessResult # is 0xFF the first time, will be ignored
	jal	cpuguess
  storeResult:
	add	$s0, $zero, $v0	# save guess
	
	# convert integer in $a0 back to ascii for display
	# $v0 points to ascii buffer (not null terminated)
	add $a0, $zero, $s0
	jal itoa 
	
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t0, 0($v0)
	sw $t0, playerInputBuffer
	storeArrayWord(computerPreviousGuess, turnNumber, $t0)           #save the guess in the array of guesses
	sw $zero, playerInputBuffer + 4                                  #NULL terminate the string
  checkResult:
	move $a0, $s0
	lw $a1, playerSecretNumber
	jal checkguess
	storeArrayHalfWord(computerPreviousResults, turnNumber, $v0)	#save the result in the array of results
	sw $v0, computerLastGuessResult	                                # save the result for sending back to the AI
	move $t1, $v0 
   #check for win
	andi $t0, $t1, 0x000000F0
	beq $t0, 0x00000040, computerWin
	srl $t0, $t0, 4                       #t0 now has the number of bulls
	andi $t1, $t1, 0x0000000F             #t1 now has the number of cows
	
  printResult:
	#la $a0, seperatorText
	#jal printText 
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
	li $a0, 2
	jal printPreviousGuesses
	
  exitComputerCallback:			
	j doEndTurn
	
computerWin:
	la $a0, computerWinPrompt
	jal printText
	j endGame	# terminates program	

.data

playerSecretNumber:
	.space 32
	.align 2
computerSecretNumber:
	.space 32
	.align 2
computerLastGuessResult:
	.word 0xFF # first time, contents don't matter
introText:
	.ascii "             Welcome to MOOPS: Moo in MIPS\n"
	.ascii "A code breaking game where the player tries to guess a secret\n"
	.ascii "4 digit hexadecimal number using the cow and bull count of their\n"
	.ascii "previous guess.  A bull is a digit which is correct and in the \n"
	.ascii "correct position.  A cow is a digit which is correct, but is not\n"
	.ascii "in the correct position.\n"
	.align 2
soundIntroText:
	.ascii "This program will play sounds to indicate the number of cows and\n"
	.asciiz "bulls of a player's guess.\n"
	.align 2  	
introTextBull:
	.asciiz "The sound for a bull is:\n"
	.align 2
introTextCow:	
	.asciiz "The sound for a cow is:\n"
	.align 2
modeSelectionText:
	.ascii "Please choose from one of the options below:\n"
	.ascii "[0] Replay moos\n"
	.ascii "[1] 1 Player only\n"
	.ascii "[2] AI only\n"
	.ascii "[3] Player vs The AI\n"
	#.ascii "[4] Player vs Player"  #Possible future addition
	.asciiz "(Numbers only): "
	.align 2
modeErrorText:
	.asciiz"ERROR: invalid meny choice\n"
	.align 2	
humanPromptText:
	.asciiz "Please input your secret number in hex: 0x"
	.align 2
humanGUIText:
	.asciiz "Please try and guess the secret number: 0x"
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
	.asciiz "Computer's guess was: 0x"
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
turnString:
	.asciiz "                  Turn 0x"
	.align 2			

# cheat codes
cheatCodePrompt:
	.asciiz "\nCheat code accepted, you rascal.\n"
	.align 2			
cheat_soff:
	.ascii "soff" # not asciiz
	.align 2			
muteCows:	# Set to nonzero to make the cows shut UP.
	.word 0
cheat_look:
	.ascii "look"
	.align 2
cheat_exit:
	.ascii "exit"
	.align 2	
