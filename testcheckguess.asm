# test routine
	.data 
quest1:	.asciiz "Enter guess (four characters, each 0-9 or A-F): "
quest2:	.asciiz "Enter the answer to compare to the guess: "
you:	.asciiz "You entered: "
ans:	.asciiz "The result is: "
endln:
	.asciiz "\n"

# scratch input buffer (make it big to prevent overflow)
inpbuffer:
	.byte 127

	.text 
prompt:
# Ask for the guess
	addi $v0, $zero, 4	# print string
	la $a0, quest1	# string to print
	syscall
	la $a0, inpbuffer	# buffer to load
	addi $a1, $zero, 10	# Only need 4 bytes, but want user to hit enter
	addi $v0, $zero, 8	# read string
	syscall

	# convert ascii to integer if valid
	# $a0 already set to string to convert
	# $v0 will contain result or -1
	jal atoi #atoi
	add $s0, $zero, $v0
	
	# convert integer in $a0 back to ascii for display
	# $v0 points to ascii buffer (not null terminated)
	add $a0, $zero, $s0
	jal itoa #itoa
	
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t0, 0($v0)
	sw $t0, inpbuffer
	sw $zero, inpbuffer + 4
	addi $v0, $zero, 4	# print string
	la $a0, you	# string to print
	syscall
	addi $v0, $zero, 4	# print string
	la $a0, inpbuffer	# string to print
	syscall
	addi $v0, $zero, 4	# print string
	la $a0, endln	# string to print
	syscall
	
# Ask for the correct answer
	add $v0, $zero, 4	# print string
	la $a0, quest2	# string to print
	syscall
	la $a0, inpbuffer	# buffer to load
	addi $a1, $zero, 10	# Only need 4 bytes, but want user to hit enter
	addi $v0, $zero, 8	# read string
	syscall
	
	# convert ascii to integer if valid
	# $a0 already set to string to convert
	# $v0 will contain result or -1
	jal atoi
	add $s1, $zero, $v0

	# convert integer in $a0 back to ascii for display
	# $v0 points to ascii buffer (not null terminated)
	add $a0, $zero, $s1
	jal itoa #itoa
	
	# move 4 bytes at 0($v0) to buffer and add a /0
	lw $t0, 0($v0)
	sw $t0, inpbuffer
	sw $zero, inpbuffer + 4
	addi $v0, $zero, 4	# print string
	la $a0, you	# string to print
	syscall
	addi $v0, $zero, 4	# print string
	la $a0, inpbuffer	# string to print
	syscall
	addi $v0, $zero, 4	# print string
	la $a0, endln	# string to print
	syscall

	# Call the routine
	add	$a0, $s0, $zero	# guess
	add	$a1, $s1, $zero	# answer
	jal	checkguess
	# result now in $v0
	add	$s3, $v0, $zero
		
done:	add $v0, $zero, 4	# print string
	la $a0, ans	# string to print
	syscall
	add $v0, $zero, 34	# print integer in hex
	add $a0, $zero, $s3	# int to print
	syscall
	# done!
	add $v0, $zero, 10	# terminate program
	syscall

.include "checkguess.asm"
.include "hexIntConversion.asm"
