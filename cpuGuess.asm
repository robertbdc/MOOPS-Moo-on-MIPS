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

.data
.align 2

## Common to all phases
phase:
	.word 0 # Current phase
mode:
	.word 0 # Current mode within phase
curguess:
	.word 0 # Last submitted guess

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
	.word -1	# Just want this label to check for "out of options"
digitoffset:
	.word 0 # points to current digit. 0xXY: X = set, Y = digit
ph1Poss:
	.word 0:16 # 16 words initialized to 0 (possible)

## Set by Phase 1 for use in Phase 2
pen: .word 0 # the guess that has 2 (or 3) cows
pencount: .word 0 # the number of Bovines in the Pen
field: .word 0 # the guess that has 1 (or 2) cows
fieldcount: .word 0 # the number of Bovines in the Field
pasture: .word 0 # another guess with 1 cow
pasturecount: .word 0 # the number of Bovines in the Pasture

## Phase 2 storage
# Save what they used to be so we can swap them back
penSwapOut: .word 0
fldSwapOut: .word 0
# Save where they used to be so we can swap them back
penCurUnk: .word 0
fldCurUnk: .word 0
# Quick digit ref: 0 = unk, 1 = Bovine, -1 = Goat
ph2Poss:
	.word 0:16 # 16 words initialized to 0 (unknown)

# Pen digits: penA, penB, penC, penD
penA: .word 0
penB: .word 0
penC: .word 0
penD: .word 0

# Field digits: fldA, fldB, fldC, fldD
fldA: .word 0
fldB: .word 0
fldC: .word 0
fldD: .word 0

## Phase 3 storage
lastbulls: .word -1 # previous guess bull count

## Output messages from the computer. Partly for debugging, partly for entertainment.
errortext:
	.asciiz "\nART: I'm stumped. I give up!\n"
	.align 2
kibMyTurn:
	.asciiz "\nART: It's my turn.\n"
	.align 2
kibLetsGo:
	.asciiz "\nART: Hi, I'm an Artificial Intelligence, but just call me Art. Let's get started!\n"
	.align 2
kibPhase1:
	.asciiz "ART: I'm picking from a preset list, after eliminating known Goats.\n"
	.align 2
kibPh1Set:
	.asciiz "ART: Starting another set of up to 4 preset guesses. Pen, Field, and Pasture emptied.\n"
	.align 2
kibPh1Goats:
	.asciiz "ART: That was all Goats? Well, that's good to know.\n"
	.align 2
kibPh1Pen:
	.asciiz "ART: Looks like I've got a guess with 2 or 3 Bovines. That goes in the Pen.\n"
	.align 2
kibPh1Fld:
	.asciiz "ART: Now I have a guess with 1 or 2 Bovines. That goes in the Field.\n"
	.align 2
kibPh1Pas:
	.asciiz "ART: One more guess has 1 Bovine. That goes in the Pasture.\n"
	.align 2

kibPh2Start:
	.asciiz "ART: I have 4 Bovines split between the Pen and Field (and maybe Pasture). I'm on a roll now!\n"
	.align 2
kibPh2Swap:
	.asciiz "ART: I'm swapping digits between the Pen and the Field. Will it be better... or worse?\n"
	.align 2
kibPh2Inc:
	.asciiz "ART: I got more Bovines by swapping digits! The old one was a Goat, the new one is a Bovine.\nI'm going to keep them where they are.\n"
	.align 2
kibPh2Pasture:
	.asciiz "ART: That used up the Bovine in the Field, so I'm going to look in the Pasture now.\n"
	.align 2
kibPh2Dec:
	.asciiz "ART: I lost a Bovine by swapping digits. The old one was a Bovine, the new one is a Goat.\nI'm going to swap them back.\n"
	.align 2
kibPh2Equ:
	.asciiz "ART: No change by swapping digits. They're both the same type, so I have to swap a different digit from the Field.\n"
	.align 2
kibPh2oops:
	.asciiz "ART: I ran out of digits to swap! (Probably because I didn't rotate pastures.)\n"
	.align 2

kibPh3Wow:
	.asciiz "ART: Hot dog, I've got four cows! Just going to swap them now.\n"
	.align 2
kibPh3Equ:
	.asciiz "ART: Neither of those is a Bull either way. Swapping with the other two.\nIt'll be a lot like starting over.\n"
	.align 2
kibPh3EquB:
	.asciiz "ART: Swapped two for two, but still the same result. Will flip one now, betcha that works!\n"
	.align 2
kibPh3Inc1:
	.asciiz "ART: One more Bull. Let's try an overlapping set.\n"
	.align 2
kibPh3Inc2:
	.asciiz "ART: Two known Bulls! When I flip the other two, I'll have four!\n"
	.align 2
kibPh3Dec1:
	.asciiz "ART: One less Bull. I'll swap back, then try an overlapping set.\n"
	.align 2
kibPh3Dec2:
	.asciiz "ART: Those two were already Bulls! When I flip the other two, I'll have four!\n"
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
	
	lw	$s3, curguess		# Last guess made
	andi	$t8, $a0, 0x00F0
	srl	$t8, $t8, 4		# bulls (in $t8 for use by Phase 4)
	andi	$t9, $a0, 0x000F	# cows (in $t9 for temp use below)
	add	$s4, $t9, $t8		# total cattle count in $s4
	
	la $a0, kibMyTurn
	jal printText

	# If we have 4 cows, we don't need to add to counters.
	beq	$s4, 4, phase3check	# Have 4 cows!
	
	# Add to digit counters
	# Add bovine count to all the digits in last guess ($s3)
	add	$t9, $zero, $zero	# counter
	add	$t7, $s3, $zero		# put guess in temp reg 
	beq	$s4, $zero, allgoats	# Unless it's zero - that means none are possible, all can be discarded

hasbovines:
	andi	$t3, $t7, 0x000F	# digit of last guess
	sll	$t3, $t3, 2		# get a word
	lw	$t4, ph1Poss($t3)	# current count for this char, init to 0
	add	$t4, $t4, $s4		# add to count
	sw	$t4, ph1Poss($t3)	# store result
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
	sw	$t4, ph1Poss($t3)	# store result
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

	# initialize
	sw	$zero, pen
	sw	$zero, field
	sw	$zero, pencount
	sw	$zero, fieldcount
	sw	$zero, pasture
	sw	$zero, pasturecount
	
	j	phase1play

phase1check:
	# Last guess has 0-3 bovines
	# If it has 0, no effect
	# If it has 1, save it in field or pasture and see if we have 4 total
	# If it has 2 or 3, save it in pen and see if we have 4 total
	beq	$s4, 3, ph1savepen
	beq	$s4, 2, ph1saveck # could be the Pen or the Field
	beq	$s4, 1, ph1savefield # could be the Field or the Pasture
	j	phase1play	# 0, no effect
ph1saveck:
	# If I have a Pen, this is the Field
	# If I have a Field, this is the Pen
	# If I have neither, this is the Pen
	lw	$t4, pen	# t4 = pen
	bne	$t4, $zero, ph1savefield
	# fall through to ph1savepen
	
ph1savepen:
	la $a0, kibPh1Pen
	jal printText

	sw	$s3, pen
	sw	$s4, pencount
	j	ph1chkpenfield
ph1savefield:
	# If I have a Field, this is the Pasture
	lw	$t4, field
	bne	$t4, $zero, ph1savepasture
	
	la $a0, kibPh1Fld
	jal printText

	sw	$s3, field
	sw	$s4, fieldcount
	j	ph1chkpenfield
ph1savepasture:
	la $a0, kibPh1Pas
	jal printText

	sw	$s3, pasture
	sw	$s4, pasturecount
	# fall through to ph1chkpenfield

ph1chkpenfield:
	# Do we have 4 total between Pen, Field, and Pasture?
	# (Won't happen for a 1/1/1/1 like 159D)
	# Remember, we can't always get 4 total in just Pen and Field (ex: A68E)
	lw	$t9, pencount
	lw	$t8, fieldcount
	lw	$t7, pasturecount
	add	$t9, $t9, $t8
	add	$t9, $t9, $t7
	blt	$t9, 4, phase1play

	# We have a pen and a field! Go to Phase 2!
	j	phase2setup
	
phase1play:
	# we want to end up with our next guess in $s0
	add	$s0, $zero, $zero	# init guess
	add	$t7, $zero, $zero	# init counter
	addi	$t8, $zero, -1	# catch out of bounds error

	# Get our next digit
	lw	$s2, digitoffset # get the next digit in the list
	# If the last digit of the offset is 0, we just started a new set
	andi	$t9, $s2, 0x000F
	bne	$t9, $zero, getchar # If we didn't just start a new set, continue

	# We didn't have 3+1 in the last set, so reset the pen and field
	la $a0, kibPh1Set
	jal printText
	sw	$zero, pen
	sw	$zero, field
	sw	$zero, pencount
	sw	$zero, fieldcount
	# fall through to getchar

getchar:
	# Get word pointed to by offset
	lb	$t1, set0($s2)	# Get digit at offset into $t1
	addi	$s2, $s2, 1	# bump pointer to next digit
	beq	$t1, $t8, error	# oops, we ran out of guesses!
	sll	$t5, $t1, 2		# turn the character into a word
	lw	$t4, ph1Poss($t5)	# current count for this char
	blt	$t4, $zero, getchar	# if this digit is a goat (poss=-1), get another one
	# if we're here, we have a good digit in $t1
	sll	$s0, $s0, 4	# make a spot
	or	$s0, $s0, $t1	# put digit in the spot
	beq	$t7, 3, phase1done
	addi	$t7, $t7, 1	# bump counter
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
	# $s4 has been set to bovine count of current guess
	
	# not used yet: $t2 = bovines known in pen, $t3 = in field

	# set $t4 = pen guess, $t5 = field guess
	lw	$t4, pen
	lw	$t5, field
	
	# Get count from the previous guess
	# set $t0 = (prev) pen count, $t1 = (prev) field count
	# We updated Pen/Field count if we swapped (Pen++, Field--)
	lw	$t0, pencount
	
	# Compare Pen count with the last guess
	# Did it go up or down, or stay the same?
	blt	$t0, $s4, ph2inc
	bgt	$t0, $s4, ph2dec

ph2equ:
	# No change: they're both the same.
	# Keep them where they are, and compare a different Goat
	la $a0, kibPh2Equ
	jal printText

	# Increase current Field Swap mode
	lw	$t9, mode
	addi	$t9, $t9, 1
	sw	$t9, mode
	j	ph2swap

ph2inc:
	# Increase: we swapped a Goat (penSwapOut) for a Bovine (fldSwapOut)
	# The Pen and the Field are just like we want them. Just mark digits as known.
	la $a0, kibPh2Inc
	jal printText
	
	# We will go back to looking at the first unknown Field digit
	sw	$zero, mode

	# Mark the Bovine that came from the field
	lw	$t2, fldSwapOut
	addi	$t3, $zero, 1
	sll	$t9, $t2, 2 # word
	sw	$t3, ph2Poss($t9)	# store result
	
	# The Pen went up and Field went down
	sw	$s4, pencount	# store back for next time

	# There's one less Bovine in the Field. If the Field is all Goats, rotate Pastures!
	lw	$t1, fieldcount
	addi	$t1, $t1, -1

	# If the Field has 0, it will be replaced with the Pasture, which has 1
	# So the Field is always going to be 1 now.
	addi	$t9, $zero, 1
	sw	$t9, fieldcount
	
	bne	$t1, $zero, ph2incgo # If we started with 2 in the Field, we still have 1 left

	# We've taken the only Bovine out of the Field. Rotate the Pasture into the Field!
	la $a0, kibPh2Pasture
	jal printText

	# Just move the Pasture guess to the Field
	lw	$t9, pasture
	sw	$t9, field
	addi	$t1, $zero, 1 # There will never be >1 Bovine in the Pasture
	# Have to reset the fldX (penX is just fine)
	j	ph2resetfield

ph2incgo:
	# Mark the Goat that went to the field
	lw	$t2, penSwapOut
	addi	$t3, $zero, -1
	sll	$t9, $t2, 2 # word
	sw	$t3, ph2Poss($t9)	# store result
	
	# Now the Pen and the Field have digits which are marked -1, 0, 1
	j	ph2swap

ph2dec:
	# Decrease: we swapped a Bovine (penSwapOut) for a Goat (fldSwapOut)
	# We messed up the Pen and the Field. Put them back like they were!
	la $a0, kibPh2Dec
	jal printText
	
	# We will go back to looking at the first unknown Field digit
	sw	$zero, mode

	# Move the Bovine back to the Pen
	lw	$t2, penSwapOut
	lw	$t9, penCurUnk
	sw	$t2, 0($t9)

	# Mark the Bovine
	addi	$t3, $zero, 1
	sll	$t9, $t2, 2 # word
	sw	$t3, ph2Poss($t9)	# store result

	# Move the Goat back to the Field
	lw	$t2, fldSwapOut
	lw	$t9, fldCurUnk
	sw	$t2, 0($t9)

	# Mark the Goat
	addi	$t3, $zero, -1
	sll	$t9, $t2, 2 # word
	sw	$t3, ph2Poss($t9)	# store result
	
	# Now the Pen and the Field have digits which are marked -1, 0, 1
	j	ph2swap

phase2setup:
	# initial pencount, fieldcount, pasturecount were set in Phase 1
	la $a0, kibPh2Start
	jal printText

	addi	$t9, $zero, 2
	sw	$t9, phase # phase 2
	sw	$zero, mode # Mode 0, look at first unknown Field digit

	# set $t4 = pen guess
	lw	$t4, pen

	# Need to remember the original Field count. Could be 1 or 2
	# When we have swapped that many out of the Field, we need to move to the Pasture
	
	# Pen digits: penA, penB, penC, penD
	# Each one is Bovine 1, Goat -1, or Unknown 0
	andi	$t8, $t4, 0x000F
	la	$t9, penD
	sw	$t8, 0($t9) # penA digit
	
	andi	$t8, $t4, 0x00F0
	srl	$t8, $t8, 4
	la	$t9, penC
	sw	$t8, 0($t9)
	
	andi	$t8, $t4, 0x0F00
	srl	$t8, $t8, 8
	la	$t9, penB
	sw	$t8, 0($t9)
	
	andi	$t8, $t4, 0xF000
	srl	$t8, $t8, 12
	la	$t9, penA
	sw	$t8, 0($t9)
	
ph2resetfield:
	# set $t5 = field guess
	lw	$t5, field

	# Field digits: fldA, fldB, fldC, fldD
	# Each one is also Bovine 1, Goat -1, or Unknown 0
	andi	$t8, $t5, 0x000F
	la	$t9, fldD
	sw	$t8, 0($t9) # fldA digit
	
	andi	$t8, $t5, 0x00F0
	srl	$t8, $t8, 4
	la	$t9, fldC
	sw	$t8, 0($t9)
	
	andi	$t8, $t5, 0x0F00
	srl	$t8, $t8, 8
	la	$t9, fldB
	sw	$t8, 0($t9)
	
	andi	$t8, $t5, 0xF000
	srl	$t8, $t8, 12
	la	$t9, fldA
	sw	$t8, 0($t9)

	# fall through to swap

ph2swap:
	la $a0, kibPh2Swap
	jal printText

	# Get current Field Swap mode (0-3)
	lw	$t4, mode
	bgt	$t4, 3, fldoops

	# $t7 = point to unknown in pen, $t8 = point to field
	# $t5 = pen digit, $t6 = field digit

	# Find the first unknown (always the first) in the Pen (t7 pointer, t5 digit)
penAck:
	la	$t7, penA
	lw	$t5, ($t7)
	sll	$t9, $t5, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	beq	$t9, $zero, gotPenUnk # 0 if unknown

penBck:
	la	$t7, penB
	lw	$t5, ($t7)
	sll	$t9, $t5, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	beq	$t9, $zero, gotPenUnk # 0 if unknown

penCck:
	la	$t7, penC
	lw	$t5, ($t7)
	sll	$t9, $t5, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	beq	$t9, $zero, gotPenUnk # 0 if unknown

penDck:
	la	$t7, penD
	lw	$t5, ($t7)
	sll	$t9, $t5, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	beq	$t9, $zero, gotPenUnk # 0 if unknown
	# all are known, what?
	j	error
	
gotPenUnk:
	# Find the desired unknown (0 to 3 in $t4) in the Field (t8 pointer, t6 digit)
fldAck:
	la	$t8, fldA
	lw	$t6, ($t8)
	sll	$t9, $t6, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	bne	$t9, $zero, fldBck # If known, check next
	beq	$t4, $zero, gotFldUnk # Is this the unknown we want?
	addi	$t4, $t4, -1	# no, try again

fldBck:
	la	$t8, fldB
	lw	$t6, ($t8)
	sll	$t9, $t6, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	bne	$t9, $zero, fldCck # If known, check next
	beq	$t4, $zero, gotFldUnk # Is this the unknown we want?
	addi	$t4, $t4, -1	# no, try again

fldCck:
	la	$t8, fldC
	lw	$t6, ($t8)
	sll	$t9, $t6, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	bne	$t9, $zero, fldDck # If known, check next
	beq	$t4, $zero, gotFldUnk # Is this the unknown we want?
	addi	$t4, $t4, -1	# no, try again

fldDck:
	la	$t8, fldD
	lw	$t6, ($t8)
	sll	$t9, $t6, 2		# get a word
	lw	$t9, ph2Poss($t9)	# current status for this char, init to 0
	bne	$t9, $zero, fldoops # If known, check next
	beq	$t4, $zero, gotFldUnk # Is this the unknown we want?
	addi	$t4, $t4, -1	# no, try again

fldoops:
	# all are known, what?
	la $a0, kibPh2oops
	jal printText

	j	error
	
gotFldUnk:
	# Swap an unknown digit from the Field into the Pen
	# $t7 = point to unknown in pen, $t8 = point to field
	# $t5 = pen digit, $t6 = field digit
	
	# Save what they used to be so we can swap them back
	sw	$t5, penSwapOut
	sw	$t6, fldSwapOut
	
	# Save where they were so we know where to swap them back to
	sw	$t7, penCurUnk
	sw	$t8, fldCurUnk
	
	# Swap the unknown digits
	sw	$t5, ($t8) # value from pen into field
	sw	$t6, ($t7) # value from field into pen
	
ph2guess:
	# Build the new guess from the digits in the pen
	lw	$t8, penA		# digit 1

	lw	$t9, penB
	sll	$t8, $t8, 4
	or	$t8, $t8, $t9

	lw	$t9, penC
	sll	$t8, $t8, 4
	or	$t8, $t8, $t9
	
	lw	$t9, penD
	sll	$t8, $t8, 4
	or	$t8, $t8, $t9

	add	$v0, $t8, $zero
	j guessmade


phase3check:
	# Endgame: we have four Bovines, now we just need to line them up!
	# Mode tells what was swapped last.
	# $s3 has guess, $t8 has bulls
	
	lw	$t0, lastbulls
	blt	$t0, $zero, ph3init # -1 = initialize
	sub	$t9, $t8, $t0	# get difference
	
	# Decrease?
	beq	$t9, -2, ph3dec2
	beq	$t9, -1, ph3dec1

	# The increase sets our new baseline
	sw	$t8, lastbulls
	
	beq	$t9, 1, ph3inc1
	beq	$t9, 2, ph3inc2
	# fall through to ph3equ

ph3equ:
	# Same bull as before
	la $a0, kibPh3Equ
	jal printText

	# If we swapped and there was no change, then neither of these is a bull in either position
	# We need to put both of these on the other side, and keep them there.
	# Swap the sets to the other side is actually easy!
	# ABCD becomes CDAB
	srl	$t8, $s3, 8 # push left digits of $s3 right
	sll	$t9, $s3, 8 # push right digits of $s3 left
	or	$a1, $t8, $t9 # put them back together in $a1!
	andi	$a1, $a1, 0xFFFF # mask out the extra bits

	# This is our guess, but when we come back from it, pretend we're starting over.
	# Then the first thing will be a simple flip (using the current mode)
	addi	$t9, $zero, -1
	sw	$t9, lastbulls
	j	ph3guess

ph3inc1:
	# More bull than before
	la $a0, kibPh3Inc1
	jal printText

	# Offset by one and swap again
	addi	$a0, $a0, 1 # next
	andi	$a0, $a0, 0x03 # 0-3 only
	add	$a1, $zero, $s3	# what to swap
	jal	swapBulls # sets $a1
	
	j	ph3guess	

ph3inc2:
	# Much more bull than before
	la $a0, kibPh3Inc2
	jal printText

	# The two we swapped are now bulls
	# Swap the other set, and we'll have 4
	addi	$a0, $a0, 2 # other
	andi	$a0, $a0, 0x03 # 0-3 only
	add	$a1, $zero, $s3	# what to swap
	jal	swapBulls # sets $a1

	j	ph3guess

ph3dec1:
	# Less bull than before
	la $a0, kibPh3Dec1
	jal printText

	# Swap back, offset by one, swap again
	lw	$a0, mode 		# which set to swap
	add	$a1, $zero, $s3	# what to swap
	jal	swapBulls		# sets $a1
	
	addi	$a0, $a0, 1 # next
	andi	$a0, $a0, 0x03 # 0-3 only
	#add	$a1, $zero, $s3	# what to swap
	jal	swapBulls # sets $a1
	
	j	ph3guess	

ph3dec2:
	# Much less bull than before
	la $a0, kibPh3Dec2
	jal printText

	# Swap back and swap other set. That will get us 4.
	lw	$a0, mode 		# which set to swap
	add	$a1, $zero, $s3	# what to swap
	jal	swapBulls		# sets $a1

	addi	$a0, $a0, 2 # other
	andi	$a0, $a0, 0x03 # 0-3 only
	#add	$a1, $zero, $s3	# what to swap
	jal	swapBulls # sets $a1
	
ph3init:
	# How much bull do we have? Will be 0, 1, or 2.
	la $a0, kibPh3Wow
	jal printText

	sw	$t8, lastbulls
	
	# Start with mode 0, left
	sw	$zero, mode
	
	lw	$a0, mode 		# which set to swap
	add	$a1, $zero, $s3	# what to swap
	jal	swapBulls		# sets $a1
	
	j	ph3guess

swapBulls:
	# Input:
	# $a0 = Which set we're going to swap
	#       0 = Left: A-B
	#       1 = Middle: B-C
	#       2 = Right: C-D
	#       3 = Outside: D-A (= A-D)
	# $a1 = The digits we're swapping (0xabcd)
	# Output:
	# $a1 = Set to reflect result

	# use standard macro to save registers
	push ($s0)
	push ($s1)
	push ($s5)
	push ($s6)
	push ($s7)

	# $s0 = Digit 1, $s1 = Digit 2
	# $s5 = unaffected digits
	# $s6 = Digit 1 mask, $s7 = Digit 2 mask (after move)
	
	# $s0 = Shift $a1 one digit right, circular
	srl	$s0, $a1, 4
	sll	$s7, $a1, 12
	or	$s0, $s0, $s7
	
	# $s1 = Shift $a1 one digit left, circular
	sll	$s1, $a1, 4
	srl	$s7, $a1, 12
	or	$s1, $s1, $s7

	# Mask out what we don't need
	beq	$a0, $zero, mask0
	beq	$a0, 1, mask1
	beq	$a0, 2, mask2
mask3:
	#       3 = Outside: D-A (= A-D)
	addi	$s5, $zero, 0x0FF0
	addi	$s6, $zero, 0x000F
	addi	$s7, $zero, 0xF000
	j	unmask
mask2:
	#       2 = Right: C-D
	addi	$s5, $zero, 0xFF00
	addi	$s6, $zero, 0x00F0
	addi	$s7, $zero, 0x000F
	j	unmask
mask1:
	#       1 = Middle: B-C
	addi	$s5, $zero, 0xF00F
	addi	$s6, $zero, 0x0F00
	addi	$s7, $zero, 0x00F0
	j	unmask
mask0:
	#       0 = Left: A-B
	addi	$s5, $zero, 0x00FF
	addi	$s6, $zero, 0xF000
	addi	$s7, $zero, 0x0F00
	j	unmask
unmask:
	# Mask out everything we don't want
	and	$a1, $a1, $s5 # unaffected digits
	and	$s1, $s1, $s6 # first swap digit
	and	$s0, $s0, $s7 # second swap digit
	# Put them back together!
	or	$a1, $a1, $s0
	or	$a1, $a1, $s1
	
	# use standard macro to restore registers
	pop ($s7)
	pop ($s6)
	pop ($s5)
	pop ($s1)
	pop ($s0)

	jr	$ra

ph3guess:
	# We always swapped something, so it's in $a1
	add	$v0, $a1, $zero
	j	guessmade
	

# returns

error:
	# Explicitly send an invalid value.
	la $a0, errortext
	jal printText

	addi	$v0, $zero, -1
	
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

