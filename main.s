# Lembretes
# - 
# TO-DO List
# - Muita coisa

##############################################################
#        Universidade de Brasília
#        Instituto de Ciências Exatas
#        Departamento de Ciência da Computação
#        Introdução aos Sistemas Computacionais – 2/2018
#        Grupo:    Marco Antônio Souza de Athayde
#	  	   Matheus Aguiar
#	    	   Murilo Ferreira
#	           Rafael dos Santos
#        Turma: A
#        Descrição: Dig Dug para RISC-V, DIY
##############################################################

#.include "common.s"
.include "data.s"
.include "dig_dug.s"
.include "enemies.s"
.include "game.s"


.eqv INPUT_PLAY		0x031
.eqv INPUT_INSTRUCT	0x032
.eqv INPUT_RANKING 	0x033
.eqv INPUT_FINISH      	0x030		# Caractere de finalização

.eqv INPUT_BACK_TITLE	0x031


.data
# Imagens de menu
	TITLE_SCREEN_PATH: 	.asciz "bin/menu/title_screen.bin"
	INSTRUCTIONS_PATH:	.asciz "bin/menu/instructions_wip.bin"
	
# Váriaveis de navegação do menu
	MENU_IMG_BUFFER: 	.space 76800
	MENU_CURRENT_SECTION:   .word 0x00


.text

	######################################
	######################################
	#	 Começo do programa	     #
	######################################
	######################################

	# Carrega todos os arquivos que devem ser carregados só uma vez
	
	LOAD_FILE(SPRITE_SHEET_PATH, SPRITE_SHEET_BUFFER, 42504)
	LOAD_FILE(DIGDUG_SPRT_SHEET_PATH, DIGDUG_SPRT_SHEET, 18000)
	LOAD_FILE(POOKA_SPRITE_PATH, POOKA_SPRITE_BUFFER, 9000)
	
	# Imagem de lacuna na representação invisível
	LOAD_FILE(GAP_DATA_PATH, GAP_DATA, 324)
	# Imagem de lacuna na representação gráfica
	LOAD_FILE(TUNNEL_M_PATH, TUNNEL_MASK, 400)
	
	# Tela inicial
	LOAD_FILE(TITLE_SCREEN_PATH, MENU_IMG_BUFFER, 76800)
	# Reservamos s3 para guardar endereço da seção atual no menu
	la	s3, TITLE_SCREEN_INPUT
MAIN:	# Desenha imagem atual do menu na tela, só uma vez
	li	a0, 320
	li	a1, 240
	DRAW_IMG(MENU_IMG_BUFFER, 320, zero, a0, a1, zero, zero)
	
	# Processa input
	MENU_INPUT: GET_TIME(s0)
	
		lw 	t0, INPUT_RDY_ADDR			# Vemos se há caractere a ler
		beq 	t0, zero, WAIT  
		lw 	t0, INPUT_DATA_ADDR   			# Termina o loop se recebermos o caractere desejado
		li 	t1, INPUT_FINISH			# Caractere desejado
		beq 	t0, t1, END				# Teste
		mv 	s1, t0					# Colocamos o caráter em um registrador para uso futuro
		
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
	
	
	# Calcula quanto tempo esperar até a próxima atualização, printa esse tempo
	WAIT:	GET_TIME(t0)			# Pegamos o tempo no final do loop, após todas as computações
		addi s0, s0, TIME_STEP  	# Adicionamos o intervalo que queremos, para decidir o momento da próxima atualização
		sub s0, s0, t0			# Subtraímos o tempo no final do loop do valor anterior para sabermos quanto tempo esperar

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
	
	
		li a0, 10			# Printamos 'new line', para pular para a próxima linha no I/O
		li a7, 11
		ecall
	
		WAIT(s0)
		jump(t0, MENU_INPUT)


END:	li 	a7, 10
		ecall
