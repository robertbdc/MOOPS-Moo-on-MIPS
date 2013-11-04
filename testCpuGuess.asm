# test routine
	.data 
# Not null terminated yet!
cur:
		.ascii "Guess: "
guessind:
		.asciiz "A\n"
endln:
		.asciiz "\n"

# scratch input buffer (make it big to prevent overflow)
inpbuffer:
	.byte 127

	.text 
testprogram:
	addi	$t7, $zero, 65	# count up from guess A

testloop:	
	sb	$t7, guessind
	addi $v0, $zero, 4	# print string
	la $a0, cur	# string to print
	syscall

	# $a0 = result fm prev
	# return $v0 = cur guess
	add	$a0, $zero, $zero
	jal	cpuguess	# BREAK: here's the next guess
	
	add	$s0, $zero, $v0	# save guess
	
	# convert integer in $a0 back to ascii for display
	# $v0 points to ascii buffer (not null terminated)
	add $a0, $zero, $s0
	jal itoa #itoa
	
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t0, 0($v0)
	sw $t0, inpbuffer
	sw $zero, inpbuffer + 4

	addi $v0, $zero, 4	# print string
	la $a0, inpbuffer	# string to print
	syscall
	addi $v0, $zero, 4	# print string
	la $a0, endln	# string to print
	syscall

	addi	$t7, $t7, 1 # show next
	bgt	$t7, 'Z', done
	
	bne	$s0, -1, testloop # did it fail?

done:
	# done!
	add $v0, $zero, 10	# terminate program
	syscall

#.include "checkguess.asm"
.include "CpuGuess.asm"
.include "hexIntConversion.asm"
