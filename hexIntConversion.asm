	.data
	.text

.globl atoi
.globl itoa

#######################################################################
#atoi - conversion from hex number (in ASCII) to int
#Params:
#	a0 - address of first four bytes containing ascii to convert
#Return:
#	v0 - the integer (base 10) value of the hex number
#	     will be -1 if number is not valid	
#registers used:
#	$s0 - the address given by a0
#	$s1 - the integer number (result of atoi)
#	$s7 - previous $ra
#	$t0 - the current hex digit being proccessed
#	$t1 - the current index of the hex digit being processed
#	$t2 - temp for ANDed number
atoi:
	move $s0, $a0  #save address of string in s0
	move $s7, $ra #save ra for later
	li $t1, 0
loop:	
	beq $t1, 4, success
	sll $s1, $s1, 4
	lb $a1, ($a0)
	jal validateDigit #exits loop returning -1 if invalid
	or $s1, $s1, $t2
	
	addi $s0, $s0, 4
	addi $t1, $t1, 1
	j loop
success:
	add $v0, $s1, $zero
	j exitLoop	
exitLoop:	
	move $ra, $s7 #restore ra before returning 
	j return
#Params:
#	a1 - the ASCII character in need of validation
validateDigit:
	blt $a1, 48, invalidNumber
	bgt $a1, 57, validateUppercase
	# goes to handleDigit if it is between ASCII 0 and 9
handleDigit:
	andi $t2, $a1, 0x0F
	j return
validateUppercase:		
	blt $a1, 65, invalidNumber
	bgt $a1, 70, validateLowercase
handleUppercase:
	subi $t2, $a1, 7
	andi $t2, $t2, 0x0F
	j return	
validateLowercase:
	blt $a1, 97, invalidNumber
	bgt $a1, 102, invalidNumber
handleLowercase:
	addi $t2, $a1, 9
	andi $t2, $t2, 0x0F
	j return
return:
	jr $ra

invalidNumber:
	li $v0, -1
	j exitLoop
#######################################################################

itoa:

#######################################################################
