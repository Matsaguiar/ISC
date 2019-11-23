# Lembretes
# - 
# TO-DO List
# - Muita coisa

##############################################################
#        Universidade de Bras�lia
#        Instituto de Ci�ncias Exatas
#        Departamento de Ci�ncia da Computa��o
#        Introdu��o aos Sistemas Computacionais � 2/2018
#        Grupo:    Marco Ant�nio Souza de Athayde
#	  	   Matheus Aguiar
#	    	   Murilo Ferreira
#	           Rafael dos Santos
#        Turma: A
#        Descri��o: Dig Dug para RISC-V, DIY
##############################################################

#.include "common.s"
.include "data.s"
.include "dig_dug.s"
.include "enemies.s"
.include "game.s"


.eqv INPUT_PLAY		0x031
.eqv INPUT_INSTRUCT	0x032
.eqv INPUT_RANKING 	0x033
.eqv INPUT_FINISH      	0x030		# Caractere de finaliza��o

.eqv INPUT_BACK_TITLE	0x031


.data
# Imagens de menu
	TITLE_SCREEN_PATH: 	.asciz "bin/menu/title_screen.bin"
	INSTRUCTIONS_PATH:	.asciz "bin/menu/instructions_wip.bin"
	
# V�riaveis de navega��o do menu
	MENU_IMG_BUFFER: 	.space 76800
	MENU_CURRENT_SECTION:   .word 0x00


.text

	######################################
	######################################
	#	 Come�o do programa	     #
	######################################
	######################################

	# Carrega todos os arquivos que devem ser carregados s� uma vez
	
	LOAD_FILE(SPRITE_SHEET_PATH, SPRITE_SHEET_BUFFER, 42504)
	LOAD_FILE(DIGDUG_SPRT_SHEET_PATH, DIGDUG_SPRT_SHEET, 18000)
	LOAD_FILE(POOKA_SPRITE_PATH, POOKA_SPRITE_BUFFER, 9000)
	
	# Imagem de lacuna na representa��o invis�vel
	LOAD_FILE(GAP_DATA_PATH, GAP_DATA, 324)
	# Imagem de lacuna na representa��o gr�fica
	LOAD_FILE(TUNNEL_M_PATH, TUNNEL_MASK, 400)
	
	# Tela inicial
	LOAD_FILE(TITLE_SCREEN_PATH, MENU_IMG_BUFFER, 76800)
	# Reservamos s3 para guardar endere�o da se��o atual no menu
	la	s3, TITLE_SCREEN_INPUT
MAIN:	# Desenha imagem atual do menu na tela, s� uma vez
	li	a0, 320
	li	a1, 240
	DRAW_IMG(MENU_IMG_BUFFER, 320, zero, a0, a1, zero, zero)
	
	# Processa input
	MENU_INPUT: GET_TIME(s0)
	
		lw 	t0, INPUT_RDY_ADDR			# Vemos se h� caractere a ler
		beq 	t0, zero, WAIT  
		lw 	t0, INPUT_DATA_ADDR   			# Termina o loop se recebermos o caractere desejado
		li 	t1, INPUT_FINISH			# Caractere desejado
		beq 	t0, t1, END				# Teste
		mv 	s1, t0					# Colocamos o car�ter em um registrador para uso futuro
		
		jalr	zero, s3, 0
	
	TITLE_SCREEN_INPUT:
		li	t0, INPUT_PLAY
		beq	s1, t0, PLAY_GAME
		li	t0, INPUT_INSTRUCT
		beq	s1, t0, INSTRUCTIONS
		
		jump (t1, WAIT)	
	
	
	
	PLAY_GAME: 	mv s1, zero					# Resetamos o registrador com o input
	
		GAME()
		jump (t0, MAIN)
		
	INSTRUCTIONS: 	mv s1, zero
	
		LOAD_FILE(INSTRUCTIONS_PATH, MENU_IMG_BUFFER, 76800)
		la 	s3, INSTRUCTIONS_SCREEN_INPUT
		jump (t0, MAIN)
		
		INSTRUCTIONS_SCREEN_INPUT:
			li	t0, INPUT_BACK_TITLE
			beq	s1, t0, BACK_TO_TITLE
			
			jump (t1, WAIT)
	
	
	BACK_TO_TITLE:	la s3, TITLE_SCREEN_INPUT
		LOAD_FILE(TITLE_SCREEN_PATH, MENU_IMG_BUFFER, 76800)
		jump (t0, MAIN)
	
	
	# Calcula quanto tempo esperar at� a pr�xima atualiza��o, printa esse tempo
	WAIT:	GET_TIME(t0)			# Pegamos o tempo no final do loop, ap�s todas as computa��es
		addi s0, s0, TIME_STEP  	# Adicionamos o intervalo que queremos, para decidir o momento da pr�xima atualiza��o
		sub s0, s0, t0			# Subtra�mos o tempo no final do loop do valor anterior para sabermos quanto tempo esperar

		mv a0, s0			# Printamos esse valor
		li a7, 1
		ecall
	
		#mv a0, s5
		#li a7, 1
		#ecall
	
		#li a0, 0x020
		#li a7, 11
		#ecall
	
		#mv a0, s6
		#li a7, 1
		#ecall
	
	
		li a0, 10			# Printamos 'new line', para pular para a pr�xima linha no I/O
		li a7, 11
		ecall
	
		WAIT(s0)
		jump(t0, MENU_INPUT)


END:	li 	a7, 10
		ecall
