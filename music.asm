#############################
#
# Description: Plays sounds based on how many bulls and cows were submitted
#
# Arguments:
#	$a0: Number of bulls
#	$a1: Number of cows
#

.globl playCowsAndBulls

playCowsAndBulls:
	move $t0, $a0 #bulls
	move $t1, $a1 #cows
	add $t2, $t0, $t1
	li $t3, 4
	sub $t2, $t3, $t2 #number of misses
	
	li $t9, 0 #index
	#play bulls
loopBulls:
	beq $t9, $t0, bullsDone
	li $v0, 33
	li $a0, 62 #pitch
	li $a1, -1  #duration
	li $a2, 24 #instrument
	li $a3, 62 #volume
	syscall
	addi $t9, $t9, 1
	j loopBulls
bullsDone: 
	li $t9, 0 #index
playCows:
	beq $t9, $t1, cowsDone
	li $v0, 33
	li $a0, 62 #pitch
	li $a1, -1  #duration
	li $a2, 72 #instrument
	li $a3, 62 #volume
	syscall
	addi $t9, $t9, 1
	j playCows
cowsDone:
	li $t9, 0 #index
playMisses:
	beq $t9, $t2, missesDone
	li $v0, 33
	li $a0, 62 #pitch
	li $a1, -1  #duration
	li $a2, 8 #instrument
	li $a3, 62 #volume
	syscall
	addi $t9, $t9, 1
	j playMisses
missesDone:
	jr $ra
	
