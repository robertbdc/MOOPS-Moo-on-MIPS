	.data
errorCode: 
	.asciiz "ERR" #will be null terminated, so 4 chars total
	.align 2	
returnString:
	.space 4
		
	.text

.globl atoi
.globl itoa

#######################################################################
# atoi - conversion from hex number (in ASCII) to int
# Params:
#	$a0 - address of string to convert
# Returns:
#	$v0 - the integer (base 10) value of the hex number
#	     will be -1 if number is not valid	
# registers used:
#	$t0 - the current hex digit being proccessed
#	$t1 - the current index of the hex digit being processed
#	$t2 - temp for ANDed number
#	$t3 - the integer number (result of atoi)
#	$t4 - previous $ra
#	$t5 - copy of a0
atoi:
	move $t5, $a0  #save address of string in t5
	move $t4, $ra #save ra for later
	li $t1, 0
	li $t3, 0 #just in case
loop:	
	beq $t1, 4, success	
	sll $t3, $t3, 4 #shift the result 4 bits left
	lb $t6, ($t5)  
	jal validateDigit 
	or $t3, $t3, $t2 #combine the current digit and the result of ANDing
	
	#advance counters
	addi $t5, $t5, 1 
	addi $t1, $t1, 1 
	j loop
success:
	add $v0, $t3, $zero
	j exitLoop	
exitLoop:	
	move $ra, $t4 #restore ra before returning 
	j return
# Params:
#	$t6 - the ASCII character in need of validation
# exits loop returning -1 if invalid
validateDigit:
	blt $t6, 0x30, invalidNumber #0x30 = 0
	bgt $t6, 0x39, validateUppercase #0x39 = 9
	# goes to handleDigit if it is between ASCII 0 and 9
handleDigit:
	andi $t2, $t6, 0x0F #0x39 & 0x0F = 0x09 
	j return
validateUppercase:		
	blt $t6, 0x41, invalidNumber #0x41 = A
	bgt $t6, 0x70, validateLowercase #0x70 = F
handleUppercase:
	subi $t2, $t6, 7 #0x41 - 7 = 0x3A
	andi $t2, $t2, 0x0F #0x3A & 0x0F = 0x0A
	j return	
validateLowercase:
	blt $t6, 0x61, invalidNumber #0x61=a
	bgt $t6, 0x66, invalidNumber #0x66=f
handleLowercase:
	addi $t2, $t6, 9
	andi $t2, $t2, 0x0F
	j return
return:
	jr $ra

invalidNumber:
	li $v0, -1
	j exitLoop
	
#######################################################################
# itoa - conversion from integer to ASCII string
# Params:
#	$a0 - unsigned integer to convert (must be < 65535 (0xFFFF))
#
# Returns:
#	$v0 - a string representing the integer in hexadecimal 
#		or 'ERR\0' if the number is out of bounds  	
# Notes:
#	 returning the string in a register limits it to 4 bytes,
#        but thats all we'll need for this program, 
#	no null terminator is added to this string
# registers used:
#	$t0 - copy of a0 (integer, not address)
#	$t1 - temp for result
#	$t2 - temp for ORing result
#	$t3 - counter
#	$t4 - current byte of interest (result of ANDing)
#	$t9 - copy of original $ra

itoa:
	move $t0, $a0
	#move $t9, $ra
	#bounds checking
	bltu $t0, $zero, outOfBounds
	bgtu $t0, 65535, outOfBounds
	#zero out temps just in case there is something in there
	li $t1, 0
	li $t2, 0
	li $t3, 0
loop2:
	beq $t3, 4, finished
	sll $t1, $t1, 8
	addi $t3, $t3, 1
	
	#lb $t4, ($t0)
	andi $t4, $t0, 0x000F #$t4 now has last byte of t0
	bgtu $t4, 9, handleAtoF
handle0to9:
	or $t2, $t4, 0x30 #t2 now has ASCII code of digit
	j shiftOrig
handleAtoF:
	or $t2, $t4, 0x30 
	addi $t2, $t2, 7 #t2 now has ASCII code of letter (A-F)
	j shiftOrig
shiftOrig:	 
	srl $t0, $t0, 4 #shift original number 4bits right
orWithResult:
	or $t1, $t1, $t2	 
	j loop2
			
finished:
	#move $ra, $t9
	sw $t1, returnString
	la $v0, returnString
	j return	
outOfBounds:
	#move $ra, $t9		
	la $v0, errorCode
	j return

