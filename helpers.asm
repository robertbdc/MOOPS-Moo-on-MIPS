	.data
	
newline:.asciiz "\n"
        .align 2

	.text

.globl printText
.globl printInteger
.globl killProcess
.globl printNewline
#.globl pushStack
#.globl popStack
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
		
############################# misc ######################################	

# Function which returns a random integer
# Params:
#	$a1 - upper bound of range of returned integer values
#
# Returns:
#	$a0 - The integer chosen

randomInteger:
	li $v0, 42
	syscall
	jr $ra

killProcess:
	li $v0, 10
	syscall
	jr $ra
######################### array stuff #############################################
	
# Function which loads a word into the specified register from a word aligned array
#note: this will use t9	
.macro loadArrayWord(%arrayLabel, %index, %resultRegister)
	lw $t9, %index
	sll $t9, $t9, 2
	lw %resultRegister, %arrayLabel($t9)
.end_macro
#function which stores a word from register %storedRegister to the word alligned array %arrayLabel at index %index
.macro storeArrayWord(%arrayLabel, %index, %storedRegister)
	lw $t9, %index
	sll $t9, $t9, 2
	sw %storedRegister, %arrayLabel($t9)
.end_macro  	

# Function which loads a halfword into the specified register from a half word aligned array
#note: this will use t9	
.macro loadArrayHalfWord(%arrayLabel, %index, %resultRegister)
	lw $t9, %index
	sll $t9, $t9, 1
	lh %resultRegister, %arrayLabel($t9)
.end_macro 

#Function which stores a halfword in a halfword alligned array
#storedRegister must be a register, whose contents will be stored in the array
.macro storeArrayHalfWord(%arrayLabel, %index, %storedRegister)
	lw $t9, %index
	sll $t9, $t9, 1
	sh %storedRegister, %arrayLabel($t9)
.end_macro 					
