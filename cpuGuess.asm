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
.align 2

## Common to all phases
phase:
	.word 0 # Current phase
mode:
	.word 0 # Current mode within phase
curguess:
	.word 0 # Last submitted guess
result:
	.word 0 # Result of last submitted guess
possibles:
	.word 0:16 # 16 words initialized to 0 (possible)

## Phase 1 storage
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

## Phase 2 storage
pen: .word 0 # the guess that has 2 (or 3) cows
pencount: .word 0 # the number of Bovines in the Pen
field: .word 0 # the guess that has 1 (or 2) cows
fieldcount: .word 0 # the number of Bovines in the Field
# Pen digits: penA, penB, penC, penD
penA: .word 0
penB: .word 0
penC: .word 0
penD: .word 0
# Unknown digit pointers: penUnk1, penUnk2, penUnk3, penUnk4
penUnk1: .word 0
penUnk2: .word 0
penUnk3: .word 0
penUnk4: .word 0
# Known digit pointers: penK1, penK2, penK3 (no need for 4)
penK1: .word 0
penK2: .word 0
penK3: .word 0

# Field digits: fldA, fldB, fldC, fldD
fldA: .word 0
fldB: .word 0
fldC: .word 0
fldD: .word 0
# Unknown digit pointers: fldUnk1, fldUnk2, fldUnk3, fldUnk4
fldUnk1: .word 0
fldUnk2: .word 0
fldUnk3: .word 0
fldUnk4: .word 0
# Known digit pointers: fldK1, fldK2 (no need for 3/4)
fldK1: .word 0
fldK2: .word 0


## Output messages from the computer. Partly for debugging, partly for entertainment.
errortext:
	.asciiz "\nCOMPUTER: I give up! I'm starting over.\n"
	.align 2
kibMyTurn:
	.asciiz "\nCOMPUTER: It's my turn.\n"
	.align 2
kibLetsGo:
	.asciiz "\nCOMPUTER: Let's get started. I'm feeling lucky!\n"
	.align 2
kibPhase1:
	.asciiz "COMPUTER: I just picked from a pre-programmed list, but eliminated known Goats.\n"
	.align 2
kibPh1Goats:
	.asciiz "COMPUTER: That was all Goats? Well, that's good to know.\n"
	.align 2
kibPh1Bovines:
	.asciiz "COMPUTER: Good, there were Bovines in that guess.\n"
	.align 2
kibPh2Start:
	.asciiz "COMPUTER: I have four Bovines in two Guesses. I'm on a roll now!\n"
	.align 2
kibPh2Swap:
	.asciiz "COMPUTER: I just swapped digits between two Guesses. Will it be better... or worse?\n"
	.align 2

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
	
	la $a0, kibMyTurn
	jal printText

	# If we have 4 cows, we don't need to add to counters.
	beq	$t9, 4, phase3check	# Have 4 cows!
	
	# Add to digit counters
	# Add bovine count to all the digits in last guess ($s3)
	add	$t9, $zero, $zero	# counter
	add	$t7, $s3, $zero		# put guess in temp reg 
	beq	$s4, $zero, allgoats	# Unless it's zero - that means none are possible, all can be discarded

	la $a0, kibPh1Bovines
	jal printText
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
	la $a0, kibPh1Goats
	jal printText

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

	la $a0, kibLetsGo
	jal printText
	
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
	# If it has 1, save it in field and see if we have 2+1
	# If it has 2 or 3, save it in pen and see if we have 2+1
	beq	$s4, 3, ph1savepen
	beq	$s4, 2, ph1savepen
	beq	$s4, 1, ph1savefield
	j	phase1play	# 0, no effect
ph1savepen:
	sw	$s3, pen
	sw	$s4, pencount
	add	$t4, $zero, $s3	# t4 = pen
	lw	$t5, field	# t5 = field
	j	ph1chkpenfield
ph1savefield:
	sw	$s3, field
	sw	$s4, fieldcount
	add	$t5, $zero, $s3	# t5 = field
	lw	$t4, pen	# t4 = pen
	# fall through to ph1chkpenfield
ph1chkpenfield:
	bge	$t4, 2, phase1play # 2+ in the pen?
	bge	$t5, 1, phase1play # 1+ in the field?

	# We have a pen and a field! Go to Phase 2!
	la $a0, kibPh2Start
	jal printText

	sw	$zero, mode	# mode 0
	addi	$t9, $zero, 2
	sw	$t9, phase # phase 2
	j	phase2check
	
ph1clear:
	# We don't have 3+1 in this set (or we just started)
	sw	$zero, pen
	sw	$zero, field
	# fall through to phase1play
		
phase1play:
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
	la $a0, kibPhase1
	jal printText

	# Save position of next digit
	sw	$s2, digitoffset
	add	$v0, $s0, $zero
	j	guessmade
	

phase2check:
	# What's in the pen and in the field?
	# $t0 = pen count, $t1 = field count
	# $t2 = bovines known in pen, $t3 = in field
	# $t4 = pen guess, $t5 = field guess
	
	lw	$s2, mode
	beq	$s2, $zero, ph2setup	# Initial setup
	j	ph2setup #### BREAKPOINT - always jump to initial

ph2setup:
	# Pen digits: penA, penB, penC, penD
	# Each one is Bovine 1, Goat -1, or Unknown 0
	# Unknown digit pointers: penUnk1, penUnk2, penUnk3, penUnk4
	# Known digit pointers: penK1, penK2, penK3 (no need for 4)
	la	$t9, penA
	sw	$zero, 0($t9) # penA is unknown
	sw	$t9, penUnk1 # first unknown is penA
	
	la	$t9, penB
	sw	$zero, 0($t9)
	sw	$t9, penUnk2
	
	la	$t9, penC
	sw	$zero, 0($t9)
	sw	$t9, penUnk3
	
	la	$t9, penD
	sw	$zero, 0($t9)
	sw	$t9, penUnk4
	
	# null pointers for known digits
	sw	$zero, penK1
	sw	$zero, penK2
	sw	$zero, penK3
	
	# Field digits: fldA, fldB, fldC, fldD
	# Each one is also Bovine 1, Goat -1, or Unknown 0
	# Unknown digit pointers: fldUnk1, fldUnk2, fldUnk3, fldUnk4
	# Known digit pointers: fldK1, fldK2 (no need for 3/4)
	la	$t9, fldA
	sw	$zero, 0($t9) # fldA is unknown
	sw	$t9, fldUnk1 # first unknown is fldA
	
	la	$t9, fldB
	sw	$zero, 0($t9)
	sw	$t9, fldUnk2
	
	la	$t9, fldC
	sw	$zero, 0($t9)
	sw	$t9, fldUnk3
	
	la	$t9, fldD
	sw	$zero, 0($t9)
	sw	$t9, fldUnk4
	
	# null pointers for known digits
	sw	$zero, fldK1
	sw	$zero, fldK2
	# fall through to swap

ph2swap:
	la $a0, kibPh2Swap
	jal printText

	# Multiple unknowns in both pen and field
	# Swap a digit from the Field into the Pen
	
	# Get first unknown from pen
	lw	$t8, penUnk1 # points to unknown
	lw	$t8, 0($t8) # now we have the digit
	
	# Get first unknown from field
	lw	$t7, fldUnk1
	lw	$t7, 0($t7)
	
	# todo: save what they used to be, somewhere!
	
	# Swap the unknown digits
	sw	$t8, fldUnk1
	sw	$t7, penUnk1
	
ph2guess:
	# Build the new guess from the digits in the pen
	lw	$v0, penA		# digit 1
	sll	$v0, $v0, 4
	lw	$t9, penB
	sll	$v0, $v0, 4
	or	$v0, $v0, $t9
	lw	$t9, penC
	sll	$v0, $v0, 4
	or	$v0, $v0, $t9
	lw	$t9, penD
	sll	$v0, $v0, 4
	or	$v0, $v0, $t9

	j guessmade

phase3check:
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

