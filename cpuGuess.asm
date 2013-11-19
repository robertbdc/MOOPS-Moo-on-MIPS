#.globl cpuguess
# Params:	$a0 = result from previous guess, format from checkguess (see below)
# Returns:	$v0 = current guess

# Lower 16 bits of $a0 will be set as follows:
# i000 g000 0bbb 0ccc
#
# i = 1 for invalid (0x8000)
# g = 1 if already guessed (0x0800) - I may still need this for the AI
# bbb = 0-4 bulls (0x0040 means win)
# ccc = 0-4 cows (0x0004 means all present but in wrong order)

# Registers used (preserved on stack)
#		$s0 = current guess
#		$s1 = current phase
#		$s2 = current mode or pointer (within phase)
#		$s3 = previous guess
#		$s4 = bovine count (bulls + cows)
# Commonly used temps (for reference when debugging):
#		$t0 = 
#		$t1 = 
#		$t2 = 
#		$t3 = 
#		$t4 = 
#		$t5 = 
#		$t7 = rotating previous guess
#		$t8 = bulls (for Phase 4)
#		$t9 = scratch

.data

possibles:
	.word 0:16 # 16 words initialized to 0 (possible)

.align 2

# 16 initial guesses (store by byte so we don't have to have nybble-size pointer)
set0:
	.byte 0,1,2,3
	.byte 4,5,6,7
	.byte 8,9,0xA,0xB
	.byte 0xC,0xD,0xE,0xF
set1:
	.byte 4,9,0xE,3
	.byte 8,0xD,2,7
	.byte 0xC,1,6,0xB
	.byte 0,5,0xA,0xF
set2:
	.byte 8,1,0xA,3
	.byte 0xC,5,0xE,7
	.byte 0,9,2,0xB
	.byte 4,0xD,6,0xF
set3:
	.byte 0xC,9,6,3
	.byte 0,0xD,0xA,7
	.byte 4,1,0xE,0xB
	.byte 8,5,2,0xF
outofguesses:
	.word 0xFFFFFFFF	# Just want this label to check for "out of options"
digitoffset:
	.word 0 # points to current digit. 0xXY: X = set, Y = digit

phase:
	.word 0 # Current phase
round:
	.word 0 # Current round within phase
curguess:
	.word 0 # Last submitted guess
result:
	.word 0 # Result of last submitted guess

cows3:
	.word 0 # the guess that has 3 cows
cows1:
	.word 0 # the guess that has 1 cow

errortext:
	.asciiz "\nThe computer had to give up and start over!\n"

.text

#.globl cpuguess
# Params:	$a0 = result from previous guess, format from checkguess (see below)
# Returns:	$v0 = current guess
cpuguess:
	# use standard macro to save registers
	push ($s0)
	push ($s1)
	push ($s2)
	push ($s3)
	push ($s4)
	push ($ra)

	lw	$s1, phase
	beq	$s1, $zero, firstguess	# no previous guess
	
	# Store result of previous guess and get cattle count
	sw	$a0, result		# Result of last guess
	lw	$s3, curguess		# Last guess made
	andi	$t8, $a0, 0x00F0
	srl	$t8, $t8, 4		# bulls (in $t8 for use by Phase 4)
	andi	$t9, $a0, 0x000F	# cows (in $t9 for temp use below)
	add	$s4, $t9, $t8		# total cattle count in $s4
	
	# If we have 4 cows, we don't need to add to counters.
	beq	$t9, 4, phase4check	# Have 4 cows!
	
	# Add to digit counters
	# Add bovine count to all the digits in last guess ($s3)
	add	$t9, $zero, $zero	# counter
	add	$t7, $s3, $zero		# put guess in temp reg 
	beq	$s4, $zero, allgoats	# Unless it's zero - that means none are possible, all can be discarded
hasbovines:
	andi	$t3, $t7, 0x000F	# digit of last guess
	sll	$t3, $t3, 2		# get a word
	lw	$t4, possibles($t3)	# current count for this char, init to 0
	add	$t4, $t4, $s4		# add to count
	sw	$t4, possibles($t3)	# store result
	beq	$t9, 3, digitloopdone
	srl	$t7, $t7, 4		# get next digit
	addi	$t9, $t9, 1
	j	hasbovines

allgoats:
	# Bad news, this set of digits is all goats
	addi	$t4, $zero, -1
allgoatslp:
	andi	$t3, $t7, 0x000F	# digit of last guess
	sll	$t3, $t3, 2		# get a word
	sw	$t4, possibles($t3)	# store result
	beq	$t9, 3, digitloopdone
	srl	$t7, $t7, 4		# get next digit
	addi	$t9, $t9, 1
	j	allgoatslp
		
digitloopdone:
	# todo: add checks to skip phases, and for if all chars in set are used

	# go to current cow-finding phase
	beq	$s1, 1, phase1check
	beq	$s1, 2, phase2check
	beq	$s1, 3, phase3check
	# If we fall through, there's an error.
	j error

firstguess:
	# initialize (note we end up here on error, too)
	addi	$t9, $zero, 1
	sw	$t9, phase # phase 1
	add	$s2, $zero, $zero	# initial offset = 0
	sw	$s2, digitoffset # point at first digit in the list
	j	phase1play

phase1check:
	# If the last digit of the offset is 0, we started a new set
	lw	$s2, digitoffset
	andi	$t9, $s2, 0x000F
	beq	$t9, $zero, ph1clear 
	
	# Last guess has 0-3 bovines
	# If it has 0, no effect
	# If it has 1, save it in cows1 and see if we have 3+1
	# If it has 2, we can't have 3+1
	# If it has 3, save it in cows3 and see if we have 3+1
	beq	$s4, 3, ph1save3
	beq	$s4, 2, ph1clear
	beq	$s4, 1, ph1save1
	j	phase1play	# 0 or 2, so we don't have 3+1
ph1save3:
	sw	$s3, cows3
	add	$t4, $zero, $s3	# t4 = cows3
	lw	$t5, cows1	# t5 = cows1
	j	ph1chk31
ph1save1:
	lw	$t9, cows1	# do we already have a 1?
	beq	$t9, $zero, phase1play	# we already have a 1, so we can't have 3+1
	sw	$s3, cows1
	add	$t5, $zero, $s3	# t5 = cows1
	lw	$t4, cows3	# t4 = cows3
	# fall through to ph1chk31
ph1chk31:
	beq	$t4, $zero, phase1play
	beq	$t5, $zero, phase1play
	# We have a 1-cow and a 3-cow! Go to Phase 2!
	addi	$t9, $zero, 2
	sw	$t9, phase # phase 2
	j	phase2check
	
ph1clear:
	# We don't have 3+1 in this set (or we just started)
	sw	$zero, cows1
	sw	$zero, cows3
	# fall through to phase1play
		
phase1play:
	# todo: If we have 4 total bovines in this set, mark the rest of set as goats, move to next set

	# we want to end up with our next guess in $s0
	add	$s0, $zero, $zero	# init guess
	add	$t9, $zero, $zero	# init counter
	addi	$t8, $zero, 0xFF	# catch out of bounds error

getchar:
	# Get word pointed to by offset
	lb	$t1, set0($s2)	# Get digit at offset into $t1
	addi	$s2, $s2, 1	# bump pointer to next digit
	beq	$t1, $t8, error	# oops, we ran out of guesses!
	sll	$t5, $t1, 2		# turn the character into a word
	lw	$t4, possibles($t5)	# current count for this char
	blt	$t4, $zero, getchar	# if this digit is a goat (poss=-1), get another one
	# if we're here, we have a good digit in $t1
	sll	$s0, $s0, 4	# make a spot
	or	$s0, $s0, $t1	# put digit in the spot
	beq	$t9, 3, phase1done
	addi	$t9, $t9, 1	# bump counter
	j	getchar
	
phase1done:
	# Save position of next digit
	sw	$s2, digitoffset
	add	$v0, $s0, $zero
	j	guessmade
	

# todo: implement more phases
phase2check:
	j error
phase3check:
	j error
phase4check: # 4a
	j error
phase5check: # 4b
	j error

# returns

error:
	# Start back at the beginning, just so we're doing something.
	la $a0, errortext
	jal printText
	# Return to Phase 0
	j	firstguess	 # If things are strange, BREAKPOINT here #############

guessmade:
	# $v0 contains the current guess
	# store for reference and return
	sw	$v0, curguess 

	# use standard macro to restore registers
	pop ($ra)
	pop ($s4)
	pop ($s3)
	pop ($s2)
	pop ($s1)
	pop ($s0)

	jr	$ra

