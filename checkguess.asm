.data	
.text

#.globl checkguess
# Params:	$a0 = guess
#		$a1 = correct answer
# Returns:	$v0 = status, see below

# Lower 16 bits of $v0 will be set as follows:
# i000 g000 0bbb 0ccc
#
# i = 1 for invalid (0x8000)
# g = 1 if already guessed (0x0800) - I may still need this for the AI
# bbb = 0-4 bulls (0x0040 means win)
# ccc = 0-4 cows (0x0004 means all present but in wrong order)

# Some temps used here (for reference when debugging):
#		$t0 = copy of guess
#		$t1 = result after XOR
#		$t2 = digit we're checking
#		$t3 = match count
#		$t4 = bulls
#		$t5 = cows
#		$t7 = counter
#		$t8, $t9 = scratch vars

checkguess:
	beq	$a0, $a1, correct	# Simplest case: is the guess right?
	push($ra)
	jal 	checkValidity
	beq 	$v0, 0x8000, returnFromCheckGuess       # return now if bad pattern
	jal 	checkBullsCows                         # otherwise check the bulls/cows 
   returnFromCheckGuess:	
	pop($ra)
	jr 	$ra

checkValidity:
	# Is the guess valid?
	add	$t0, $a0, $zero		# make a copy of guess
	add	$t7, $zero, $zero	# init counter
   rollme:
	# End result of this section: rotate one hex digit, ABCD becomes BCDA
	# (like a 'rol' on just the bottom half)
	sll	$t8, $t0, 4		# last 4 of $t8 are BCD0
	srl	$t9, $t0, 12		# last 4 of $t9 are 000A
	or	$t0, $t9, $t8		# last 4 of $t0 are BCDA
	andi	$t0, $t0, 0xFFFF	# dump the A that got shifted into first 4

	# Now check each digit for sameness
	xor 	$t1, $t0, $a0		# If a bit is the same, result is 0
	andi 	$t2, $t1, 0xF000	# Check first digit
	beq	$t2, $zero, badpat
	andi 	$t2, $t1, 0x0F00	# Check second digit
	beq	$t2, $zero, badpat
	andi 	$t2, $t1, 0x00F0	# Check third digit
	beq	$t2, $zero, badpat
	andi 	$t2, $t1, 0x000F	# Check fourth digit
	beq	$t2, $zero, badpat
	# made it, try next digit
	addi	$t7, $t7, 1
	blt	$t7, 3, rollme		# Repeat 3x (after 4, it is back like it started!)
   exitValidCheck:
   	add 	$v0, $zero, $zero
   	jr 	$ra	
   badpat:
	add	$v0, $zero, 0x8000	# bad pattern
	jr	$ra

checkBullsCows:
	# Guess is valid. Let's see how well it did.
	# Check for bulls (first pass) or cows (other passes)
	add	$t4, $zero, $zero	# initialize bulls
	add	$t5, $zero, $zero	# initialize cows
		
	add	$t0, $a0, $zero		# make a copy of guess
	add	$t7, $zero, $zero	# init counter
	# Different from the bad value loop because the first check doesn't rotate
	j	checkbullcow
   rollbullcow:
	# (Rotate is just like the bad value loop)
	sll	$t8, $t0, 4		# last 4 of $t8 are BCD0
	srl	$t9, $t0, 12		# last 4 of $t9 are 000A
	or	$t0, $t9, $t8		# last 4 of $t0 are BCDA
	andi	$t0, $t0, 0xFFFF	# dump the A that got shifted into first 4
   checkbullcow:	
	add	$t3, $zero, $zero	# initialize match count
	xor 	$t1, $t0, $a1		# If a bit is the same, result is 0
	andi 	$t2, $t1, 0xF000	# Check digit
	bne	$t2, $zero, chk2
	addi	$t3, $t3, 1		# Found one!
   chk2:	
        andi 	$t2, $t1, 0x0F00	# Check digit
	bne	$t2, $zero, chk3
	addi	$t3, $t3, 1		# Found one!
   chk3:
   	andi 	$t2, $t1, 0x00F0	# Check digit
	bne	$t2, $zero, chk4
	addi	$t3, $t3, 1		# Found one!
   chk4:
   	andi 	$t2, $t1, 0x000F	# Check digit
	bne	$t2, $zero, setmatch
	addi	$t3, $t3, 1		# Found one!

   setmatch:
	bne	$t7, $zero, setcow
	# First time through is bulls
	add	$t4, $t4, $t3
	j	nextdigit
   setcow:
	# Add to cow count
	add	$t5, $t5, $t3
	
	# made it, try next digit
   nextdigit:
	addi	$t7, $t7, 1
	blt	$t7, 4, rollbullcow		# Repeat 4x
	
	# set bulls and cows in return value
	sll	$v0, $t4, 4		# Bulls go here: 00x0
	or	$v0, $v0, $t5		# Cows go here: 000x
		
# return labels
  counted:	#nextdigit falls through to here if it counted the # of bulls/cows
	jr	$ra

  correct:
	add	$v0, $zero, 0x0040	# The magic number! 4 bulls 0 cows
	jr	$ra
			

	
	
