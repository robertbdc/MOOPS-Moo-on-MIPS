.text

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