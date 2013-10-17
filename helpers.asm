	.data
	
newline:.asciiz "\n"
        .align 2

	.text

.globl printText
.globl printInteger
.globl killProcess
.globl printNewline
.globl pushStack
.globl popStack
.globl readInt
.globl readString

########################### output ################################
#put string to print in $a0
printText:
	li $v0, 4
	syscall
	jr $ra
#put integer to print in $a0
printInteger:
	li $v0, 1
	syscall
	jr $ra

printNewline:
    	la $a0, newline
    	li $v0, 4
    	syscall	
	jr $ra

########################### input ####################################
#no args; returns int read in v0
readInt:
	li $v0, 5
	syscall
	jr $ra

#Args: $a0 = address of input buffer
#            string is stored here
#      $a1 = max number of chars to read
#            will actually only read $a1-1 characters
#	     because it always adds null terminator at end	
readString:
	li $v0, 8
	syscall
	jr $ra

############################## stack ##################################	

########################################################################
# Function which pushes address to stack.
# NOTE: stack should only be used to push addresses, and 0 should never
#       be pushed to the stack (because of implementation of pop)
# Params:
#	$a0 - address to be pushed to stack
#######################################################################		
pushStack:
	addi $sp, $sp, -4
	sw $a0, ($sp)
	jr $ra
	#TODO: implement moving the frame pointer ($fp)

########################################################################
# Function which pops stack.
# Params:
#
# Returns:
#	$v0 - the element just popped off the stack (32 bit address)
#		returns -1 if stack is empty
########################################################################	
popStack:
	beqz $sp, emptyStack #sp will point to address full of zeros if it is empty
	lw $v0, ($sp)
	addi $sp, $sp, 4
	jr $ra
emptyStack:
	addi $v0, $zero, -1
	jr $ra	
		
############################# misc ######################################	
killProcess:
	li $v0, 10
	syscall
	jr $ra		
