#############################
#
# Description: Plays sounds based on how many bulls and cows were submitted
#
# Arguments:
#	$a0: Number of bulls
#	$a1: Number of cows
#

.globl playCowsAndBulls
.globl playBulls
.globl playCows

playCowsAndBulls:
	push($ra)
	push($a1)
	jal playBulls
	pop($a1)
	jal playCows
	pop($ra)
	jr $ra
	
playBulls:
	move $t0, $a0 #bulls
	li $t9, 0 #index
	#play bulls
loopBulls:
	beq $t9, $t0, bullsDone
	li $v0, 33
	li $a0, 37 #pitch
	li $a1, -1  #duration
	li $a2, 59 #instrument
	li $a3, 62 #volume
	syscall
	addi $t9, $t9, 1
	j loopBulls
bullsDone: 
	jr $ra
	
playCows:
	move $t1, $a1 #cows	
	li $t9, 0 #index
loopCows:
	beq $t9, $t1, cowsDone
	li $v0, 33
	li $a0, 53 #pitch
	li $a1, -1  #duration
	li $a2, 58 #instrument
	li $a3, 62 #volume
	syscall
	addi $t9, $t9, 1
	j loopCows
cowsDone:
	jr $ra
	
