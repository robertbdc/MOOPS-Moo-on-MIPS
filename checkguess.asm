.data	
.text

#.globl checkguess
# Params:	$a0 = guess
#		$a1 = correct answer
# Returns:	$v0 = byte containing status, see below
# Temps:	$t0 = copy of guess
#		$t1 = result after XOR
#		$t2 = digit we're checking
#		$t7 = counter

# Each byte in the return has these bitwise flags:
# igbbbccc
#
# i = bit set if invalid (allows us to compare with 0 (signed)
#     or 0x80 (unsigned) to determine "invalid")
# g = bit set if user guessed this one already (compare with 0x40)
# bbb = bulls (value 0-4, 3 bits, 000-100) (compare with 0x20 to determine "you won")
# ccc = cows (value 0-4, 3 bits, 000-100)

checkguess:
	# Simplest case: is the guess right?
	beq	$a0, $a1, correct	# breakpoint: first statement in checkguess

	# Is the guess valid?
	add	$t0, $a0, $zero		# make a copy of guess
	add	$t7, $zero, $zero	# init counter
rollme:
	# End result of this bit: rotate one hex digit, ABCD becomes BCDA
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
	
	# todo: check bulls and cows
	
# return labels
nothing:
	add	$v0, $zero, $zero	# You got nothin!
	jr	$ra

correct:
	add	$v0, $zero, 0x24	# The magic number! 00 100 100 = 4 bulls, 4 cows
	jr	$ra
			
badpat:
	add	$v0, $zero, 0x80	# 1xxx xxxx = bad pattern
	jr	$ra
	
	