.data	
.text

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

# Some temps used here (for reference when debugging):
#		$t0 = current guess
#		$t1 = 
#		$t2 = current round (within phase)
#		$t3 = 
#		$t4 = 
#		$t5 = 
#		$t7 = 
#		$t8 = 
#		$t9 = scratch

.data

possibles:
	.word 0:20 # 20 words initialized to 0

.align 2

# 16 initial guesses (could fit in halfwords, but that makes picking it harder)
map:
	.word 0x0123
	.word 0x4567
	.word 0x89AB
	.word 0xCDEF

	.word 0x49E3
	.word 0x8D27
	.word 0xC16B
	.word 0x05AF

	.word 0x81A3
	.word 0xC5E7
	.word 0x092B
	.word 0x4D6F

	.word 0xC963
	.word 0x0DA7
	.word 0x41EB
	.word 0x852F

phase:
	.word 0 # Current phase
round:
	.word 0 # Current round within phase
curguess:
	.word 0 # Last submitted guess
result:
	.word 0 # Result of last submitted guess


.text

#.globl cpumakeguess
# Params:	$a0 = result from previous guess, format from checkguess (see below)
# Returns:	$v0 = current guess
cpumakeguess:
	lw	$t9, phase
	beq	$t9, $zero, firstguess # no previous guess
	
	# Store result of previous guess
	sw	$a0, result

	# go to current phase
	beq	$t9, 1, phase1check
	beq	$t9, 2, phase2check
	beq	$t9, 3, phase3check
	beq	$t9, 4, phase4check # 4a
	beq	$t9, 5, phase5check # 4b
	# If we fall through, there's an error.
	j error

firstguess:
	# initialize
	addi	$t9, $zero, 1
	sw	$t9, phase # phase 1
	j	phase1play

phase1check:
	# todo: Implement Phase 1 check
	# fall through to play

phase1play:
	# round # is pointer to current guess
	la	$t9, map
	lw	$t2, round
	sll	$t2, $t2, 2	# *4 for word
	add	$t9, $t9, $t2	# point to current guess
	lw	$t0, 0($t9)

	# todo: check whether this guess contains only goats
	# If so, advance round and j phase1play

	add	$v0, $zero, $t0	# load current guess into return value

	# advance round and possibly phase
	addi	$t2, $zero, 1
	beq	$t2, 16, phase1done # we've been through all 16 rounds (0-15)
	sw	$t2, round
	j	guessmade

phase1done:
	# next phase begin on next turn!
	addi	$t9, $zero, 2
	sw	$t9, phase # cur phase will be 2
	add	$t9, $zero, $zero
	sw	$t9, round # cur round will be 0
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
	jr	$ra

