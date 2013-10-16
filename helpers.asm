.data
    newline:.asciiz "\n"
            .align 2

.text

.globl printText
.globl printInteger
.globl killProcess
.globl printNewline

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
	
killProcess:
	li $v0, 10
	syscall
	jr $ra
