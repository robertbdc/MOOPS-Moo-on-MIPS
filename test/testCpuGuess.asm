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
## Copied Stack functions from helper.asm
############################## stack ##################################	
#TODO: implement moving the frame pointer ($fp)

# Function which pushes address to stack.
# Params:
#	%a - address to be pushed to stack
		
.macro push(%a)
	addi $sp, $sp, -4
	sw %a, ($sp) #push onto the stack 
.end_macro

# Function which pops stack.
# Params:
#    %popped - the register which will hold the popped address
	
.macro pop(%popped)
	lw %popped, ($sp) #pop the stack
	addi $sp, $sp, 4
.end_macro


main:
	addi	$s1, $zero, 65	# count up from guess A

testloop:	
	sb	$s1, guessind
	addi $v0, $zero, 4	# print string
	la $a0, cur	# string to print
	syscall

	# $a0 = result fm prev
	# return $v0 = cur guess
	add	$a0, $zero, $zero
	jal	cpuguess	# here's the next guess
	
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

	addi	$s1, $s1, 1 # show next
	bgt	$s1, 'Z', done
	
	bne	$s0, -1, testloop # did it fail?

done:
	# done!
	add $v0, $zero, 10	# terminate program
	syscall

#.include "checkguess.asm"
.include "../cpuGuess.asm"
.include "../hexIntConversion.asm"
