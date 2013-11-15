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
#		$s2 = current round (within phase)
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
#		$t8 = 
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
	.word 0xFF	# Just want this label to check for "out of options"
curset:
	.word 0 # current set
curdigit:
	.word 0 # *digit* position within set (0-16)
digitpointer:
	.word 0 # for now, just point to current digit (will be replaced by set/digit logic)

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

	lw	$s1, phase
	beq	$s1, $zero, firstguess	# no previous guess
	
	# Store result of previous guess and get cattle count
	sw	$a0, result		# Result of last guess
	lw	$s3, curguess		# Last guess made
	andi	$t9, $a0, 0x00F0
	srl	$t9, $t9, 4		# bulls
	andi	$s4, $a0, 0x000F	# cows
	add	$s4, $s4, $t9		# total cattle count in $s4
	
	# Add to digit counters
	# Add bovine count to all the digits in last guess ($s3)
	add	$t9, $zero, $zero	# counter
	add $t7, $s3, $zero # put guess in temp reg 
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

	# go to current phase
	beq	$s1, 1, phase1check
	beq	$s1, 2, phase2check
	beq	$s1, 3, phase3check
	beq	$s1, 4, phase4check # 4a
	beq	$s1, 5, phase5check # 4b
	# If we fall through, there's an error.
	j error

firstguess:
	# initialize
	addi	$t9, $zero, 1
	sw	$t9, phase # phase 1
	la	$t9, set0 # for now, point at first digit in our list
	sw	$t9, digitpointer
	j	phase1play

phase1check:
	# Last guess has 0-4 bovines
	# If it has 1, save it in cow1 and see if we have 3+1
	# If it has 3, save it in cow3 and see if we have 3+1
	# If it has 4, skip to bullfinder!
	# todo: implement
	
	# todo: If we have 4 total bovines in this set, mark the rest of set as goats, move to next set
	
	# todo: If we're at the start of a set, reset cow1
	
phase1play:
	# todo: Get word pointed to by curset + curdigit
	# (values were incremented at end of last check, initialized to 0/0)
#	lw $t2, curset # 0-3
#	sll $t2, $t2, 4 # * 16 = position of set relative to set0
#	lw $t3, curdigit # 0-16
#	add $t2, $t2, $t3
	# for now: get raw pointer
	lw	$t2, digitpointer
	# $t2 now points to the next character (offset from set0)
	# we want to end up with our next guess in $s0
	add	$s0, $zero, $zero	# init guess
	add	$t9, $zero, $zero	# init counter
	addi	$t8, $zero, 0xFF	# catch out of bounds error

getchar:
	lb	$t1, 0($t2)	# get the character into $t1
	beq	$t1, $t8, error	# oops, we ran out of guesses!
	sll	$t5, $t1, 2		# turn the character into a word
	lw	$t4, possibles($t5)	# current count for this char
	blt	$t4, $zero, p1nextdigit # if this digit is a goat (poss=-1), get another one
	# if we're here, we have a good digit in $t1
	sll	$s0, $s0, 4	# make a spot
	or	$s0, $s0, $t1	# put digit in the spot
	beq	$t9, 3, phase1done
	addi	$t9, $t9, 1	# bump counter
p1nextdigit:
	addi	$t2, $t2, 1	# point to next digit
	j	getchar
	
phase1done:
	# save position of next digit
	addi	$t2, $t2, 1	# point to next digit
	# todo: we have the raw pointer, need to turn it back into a set and a digit
	# for now, we'll just save the raw pointer
	sw	$t2, digitpointer
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
	# Return something very invalid.
	addi	$v0, $zero, 0xFFFFFFFF
	# fall through to guessmade

guessmade:
	# $v0 contains the current guess
	# store for reference and return
	sw	$v0, curguess 

	# use standard macro to restore registers
	pop ($s4)
	pop ($s3)
	pop ($s2)
	pop ($s1)
	pop ($s0)

	jr	$ra

