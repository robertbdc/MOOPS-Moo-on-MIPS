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
#		$t3 = bull/cow count
#		$t7 = counter

checkguess:
	beq	$a0, $a1, correct	# Simplest case: is the guess right?

	# Is the guess valid?
	add	$t0, $a0, $zero		# make a copy of guess
	add	$t7, $zero, $zero	# init counter
rollme:
	# End result of this section: rotate one hex digit, ABCD becomes BCDA
	# (like a 'rol' on just the bottom half)
	sll	$t6, $t0, 4		# last 4 of $t6 are BCD0
	srl	$t5, $t0, 12		# last 4 of $t5 are 000A
	or	$t0, $t5, $t6		# last 4 of $t0 are BCDA
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

	# Guess is valid. Let's see how well it did.
	add	$v0, $zero, $zero	# initialize return value
		
	# Check for bulls
	add	$t3, $zero, $zero	# initialize bull count
	xor 	$t1, $a0, $a1		# If a bit is the same, result is 0
	andi 	$t2, $t1, 0xF000	# Check digit
	bne	$t2, $zero, chk2
	addi	$t3, $t3, 1		# Found one!
chk2:	andi 	$t2, $t1, 0x0F00	# Check digit
	bne	$t2, $zero, chk3
	addi	$t3, $t3, 1		# Found one!
chk3:	andi 	$t2, $t1, 0x00F0	# Check digit
	bne	$t2, $zero, chk4
	addi	$t3, $t3, 1		# Found one!
chk4:	andi 	$t2, $t1, 0x000F	# Check digit
	bne	$t2, $zero, setbull
	addi	$t3, $t3, 1		# Found one!

setbull:
	sll	$t3, $t3, 4		# Bulls go here: 00x0
	or	$v0, $v0, $t3
	
	# Check for cows
		
# return labels
counted:
	jr	$ra

correct:
	add	$v0, $zero, 0x0040	# The magic number! 4 bulls 0 cows
	jr	$ra
			
badpat:
	add	$v0, $zero, 0x8000	# bad pattern
	jr	$ra
	
	
