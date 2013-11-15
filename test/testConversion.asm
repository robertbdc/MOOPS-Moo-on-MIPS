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
num5:	.asciiz "AzCP"
	.align 2	
num6:	.asciiz "abcd"
	.align 2	
num7:	.asciiz "0a4c"
	.align 2	
	
	.text	
	
main:	
	################### test atoi ##########################
	la $a0, num7         #change this to test other strings
	jal atoi
	beq $v0, -1, handleInvalid
	add $t0, $v0, $zero #store number in t0
	
	la $a0, num7 	     #change this to test other strings
	jal printText
	
	la $a0, equals
	jal printText
	
	add $a0, $t0, $zero
	jal printInteger
	
	jal printNewline
	############# test itoa #################
	addiu $a0, $zero, 1   #change this number to test others
	jal printInteger
	
	la $a0, equals
	jal printText
	
	li $a0, 0
	addiu $a0, $a0, 1		#change this num to test others
	jal itoa
	
	move $a0, $v0
	jal printText
	 	  	   	  	  
	
	j exit
	
handleInvalid:
	la $a0, invalid
	jal printText
	j exit
exit:	
	li $v0, 10
	syscall
	
	.include "hexIntConversion.asm"
	.include "helpers.asm"	
	
