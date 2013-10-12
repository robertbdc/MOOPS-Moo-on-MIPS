# test routine
	.data 
quest1:	.asciiz "Enter a guess less than 65536: "
quest2:	.asciiz "Enter an answer less than 65536: "
ans:	.asciiz "The result is: "
endln:
	.asciiz "\n"

	.text 
prompt:	add $v0, $zero, 4	# print string
	la $a0, quest1	# string to print
	syscall
	add $v0, $zero, 5	# get integer (in $v0)
	syscall
	add $s0, $v0, $zero	# put integer in $s0

	add $v0, $zero, 34	# print integer in hex
	add $a0, $zero, $s0	# int to print
	syscall
	add $v0, $zero, 4
	la $a0, endln
	syscall

	add $v0, $zero, 4	# print string
	la $a0, quest2	# string to print
	syscall
	add $v0, $zero, 5	# get integer (in $v0)
	syscall
	add $s1, $v0, $zero	# put integer in $s1

	add $v0, $zero, 34	# print integer in hex
	add $a0, $zero, $s1	# int to print
	syscall
	add $v0, $zero, 4
	la $a0, endln
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