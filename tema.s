###############################################
#  Programa de exemplo para Syscall MIDI      #
#  ISC Abr 2018				      #
#  Marcus Vinicius Lamar		      #
###############################################

.data
# Numero de Notas a tocar
NUM: .word 43
# lista de nota,dura��o,nota,dura��o,nota,dura��o,...
NOTAS: 78,192,79,192,79,192,79,384,79,192,79,192,79,192,79,192,79,192,79,192,79,384,79,192,79,192,79,192,76,384,74,192,76,384,74,192,76,192,74,192,76,768,74,900,75,192,76,192,76,192,76,384,76,192,76,192,76,192,76,192,76,192,76,192,76,384,76,192,76,192,76,192,76,384,74,192,76,384,74,192,76,192,74,192,79,1536

.text
	la s0,NUM		# define o endere�o do n�mero de notas
	lw s1,0(s0)		# le o numero de notas
	la s0,NOTAS		# define o endere�o das notas
	li t0,0			# zera o contador de notas
	li a2,11		# define o instrumento
	li a3,40		# define o volume

LOOP:	beq t0,s1, FIM	# contador chegou no final? ent�o  v� para FIM
	lw a0,0(s0)		# le o valor da nota
	lw a1,4(s0)		# le a duracao da nota
	li a7,31		# define a chamada de syscall
	ecall			# toca a nota
	mv a0,a1		# passa a dura��o da nota para a pausa
	#addi a1,a1,75
	#li a7,32		# define a chamada de syscal 
	#ecall			# realiza uma pausa de $a0 ms
	addi s0,s0,8		# incrementa para o endere�o da pr�xima nota
	addi t0,t0,1		# incrementa o contador de notas
	j LOOP			# volta ao loop
	
FIM:	li a7,10		# define o syscall Exit
	ecall			# exit

