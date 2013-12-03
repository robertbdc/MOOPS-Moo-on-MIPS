.data

prevGuessHeader:
		.asciiz "Guess   Cows   Bulls\n--------------------\n"
			#-----===----===----- 
		.align 2
prevGuessString:
		.space 22
		.align 2
space:
		.ascii " "
		.align 2
playerPrevGuessHeader:
	.asciiz "\nPlayer's previous guesses:\n"
	.align 2
computerPrevGuessHeader:
	.asciiz "\nART's previous guesses:\n"
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
computerPreviousGuess:
		.space 174720
		.align 2
computerPreviousResults:
		.space 87360 
		.align 1	
		
.text
#.include "helpers.asm"

# Function which checks array for a previous guess
# params: a0 - the address containing the guess
#	  a1 - the current turn number in the game
#         a2 - player number = 1 if player
#                              2 if computer
#                           
# returns; v0 - 1 if the guess has already been guessed
#		0 if the guess has not been guessed

alreadyGuessed:
	push($ra)
	jal toUpper
	pop($ra)
	lw $t0, ($a0) # t0 has string representing guess
	move $t1, $a1 # t1 holds the current turn tumber(of the game)
	li $t2, 1# t2 is counter for current turn number being processed
	li $v0, 0 # initially set return value to 0 (not found)
    guessedLoop:
	bge  $t2, $t1, exitGuessed
	beq $a2, 2, loadComputerGuess
      loadPlayerGuess:	
	loadArrayWord(playerPreviousGuess, $t2, $t3) #t3 holds the guess located at index t2
	j checkGuess
      loadComputerGuess:
        loadArrayWord(computerPreviousGuess, $t2, $t3) #t3 holds the guess located at index t2
      checkGuess:	
	beq $t3, $t0, setGuessed
	addi $t2, $t2, 1
	j guessedLoop	
      setGuessed:
    	li $v0, 1
    exitGuessed:	
	jr $ra

# Function which prints the the orevious guesses
# param: a0 - the player number = 1 if player
#				  2 if computer
#	t1 is counter for the current turn number being processed
#	t3 will be the address of cursor
#	t6 saves the player number
#	t7 stores previous result from checkguess
printPreviousGuesses:
	push($ra)
	move $t6, $a0	#save the player number
	lw $t0, turnNumber #t0 contains the current turn number(in refrence to the game)
	beq $t0, 1, exitPrevGuess #don't print previous guesses on turn 1
	beq $t6, 2, printCompHeader
   printPlayerHeader:
        la $a0, playerPrevGuessHeader
        jal printText
        j printCommonHeader	
   printCompHeader: 
	la $a0, computerPrevGuessHeader
  	jal printText
   printCommonHeader:	
	la $a0, prevGuessHeader
	jal printText
	li $t1, 1 #t1 is counter for the current turn number being processed
   prevGuessLoop:
	beq $t0, $t1, exitPrevGuess
	
	sw $zero, prevGuessString
	la $t3, prevGuessString  #t3 will be the address of cursor
	
	beq $t6, 2, loadComputerGuess1
      loadPlayerGuess1:	
	loadArrayWord(playerPreviousGuess, $t1, $t2) #t2 holds word fron array
	j insertGuess
      loadComputerGuess1:
        loadArrayWord(computerPreviousGuess, $t1, $t2) #t2 holds word fron array
      insertGuess:
        sw $t2, ($t3)	
	lb $t4, space
	sb $t4, 4($t3)
	sb $t4, 5($t3)
	sb $t4, 6($t3)
	sb $t4, 7($t3)
	sb $t4, 8($t3)
	beq $t6, 2, loadComputerResult
      loadPlayerResult:	
	loadArrayHalfWord(playerPreviousResults, $t1, $t2)
	move $t7, $t2
	j extractResult
      loadComputerResult:
        loadArrayHalfWord(computerPreviousResults, $t1, $t2)
        move $t7, $t2
      extractResult:      
	#last byte of t2 has number of cows
	andi $a0, $t2, 0x000F
	push ($t0)
	push ($t1)
	jal itoa
	pop ($t1)
	pop ($t0)
	la $t3, prevGuessString
	
	lw $t4, ($v0)
	andi $t4, $t4, 0xFF000000 
	srl $t4, $t4, 24
	sb $t4, 9($t3)
	lb $t4, space
	sb $t4, 10($t3)
	sb $t4, 11($t3)
	sb $t4, 12($t3)
	sb $t4, 13($t3)
	sb $t4, 14($t3)
	sb $t4, 15($t3)
	#loadArrayHalfWord(playerPreviousResults, $t1, $t2)
	move $t2, $t7 
	#second to last byte of t2 has number of bulls
	andi $a0, $t2, 0x00F0
	
	push ($t0)
	push ($t1)
	jal itoa
	pop ($t1)
	pop ($t0)
	la $t3, prevGuessString
	
	lw $t4, ($v0)
	andi $t4, $t4, 0x00FF0000 
	srl $t4, $t4, 16
	sb $t4, 16($t3)
	lb $t4, newline
	sb $t4, 17($t3)
	li $t5, 1
	lb $t4, newline($t5)
	sb $t4, 18($t3)
	        
	la $a0, prevGuessString	
	jal printText
	
	addi $t1, $t1, 1
	j prevGuessLoop	
   exitPrevGuess:	
	pop($ra)
	jr $ra		

