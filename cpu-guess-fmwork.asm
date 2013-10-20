.data

possibles:
.word 0:20 # 20 words initialized to 0

# 16 initial guesses, each in a half-word
map0:
.word 0x01234567
.word 0x89ABCDEF
map1:
.word 0x49E38D27
.word 0xC16B05AF
map2:
.word 0x81A3C5E7
.word 0x092B4D6F
map3:
.word 0xC9630DA7
.word 0x41EB852F

phase:
.word 0 # Current phase
round:
.word 0 # Current round within phase
curguess:
.word 0 # Last submitted guess
result:
.word 0 # Result of last submitted guess

.text

# get the code that starts it up

lw $t0, phase
beq $t0, $zero, firstguess # no previous guess
beq $t0, 1, phase1check
beq $t0, 2, phase2check
beq $t0, 3, phase3check
beq $t0, 4, phase4check # 4a
beq $t0, 5, phase5check # 4b

# If we fall through, there's an error.
j error

firstguess:
# initialize
addi $t7, $zero, 1
sw $t7, phase # phase 1
j phase1play

phase1check:
# Implement Phase 1 check
# fall through to play

phase1play:
# get pointer to current halfword
la $t1, map0 # first halfword
la $t7, round # $t7 = round no, indicates which halfword
lw $t2, (0)$t7
sll $t2, $t2, 1 # x2 = offset
add $t1, $t1, $t2 # first + offset
lhu $v0, (0)$t1 # load current guess (unsigned halfword) into return value

# advance round and possibly phase
addi $t7, $zero, 1
beq $t7, 16, phase1done # we've been through all 16 rounds (0-15)
sw $t7, round
j guessmade

phase1done:
# next phase begin on next turn!
addi $t7, $zero, 2
sw $t7, phase # cur phase will be 2
add $t7, $zero, $zero
sw $t7, round # cur round will be 0
j guessmade


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
addi $v0, $zero, 0xFFFFFFFF
# fall through to guessmade

guessmade:
# $v0 contains the current guess
# store for reference and return
sw $v0, curguess 
jr $ra

