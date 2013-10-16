	.data
	
equals: .asciiz  " = "
	.align 2
invalid:.asciiz "Number was invalid"
	.align 2	
num1:	.asciiz "ABCD"
	.align 2
num2:	.asciiz "A0B1"
	.align 2
num3:	.asciiz "0000"
	.align 2
num4:	.asciiz "FFFF"
	.align 2
num5:	.asciiz "ABCP"
	.align 2	
	
	.text	
	
main:	li $t9, -1
	la $a0, num4         #change this to test other strings
	jal atoi
	beq $v0, $t9, handleInvalid
	add $s0, $v0, $zero #store number in s0
	
	la $a0, num4 	     #change this to test other strings
	jal printText
	
	la $a0, equals
	jal printText
	
	add $a0, $s0, $zero
	jal printInteger
	
	jal printNewline
	
	li $v0, 10
	syscall
	
handleInvalid:
	la $a0, invalid
	jal printText
	
	.include "hexIntConversion.asm"
	.include "helpers.asm"	
	