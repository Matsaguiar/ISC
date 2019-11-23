# Jogo em si
.data
# Mapa de jogo
GAME_MAP_PATH_PTR:	.word 0x00
# Background
BLAYER_PATH_PTR:	.word 0x00
DLAYER_PATH_PTR: 	.word 0x00
HLAYER_PATH_PTR: 	.word 0x00
VLAYER_PATH_PTR: 	.word 0x00

# Fases
# Level 00
LEVEL_0_GMAP: 		.asciz "bin/level_0/00_gmap.bin"
LEVEL_0_BLAYER:		.asciz "bin/level_0/00_bg_blayer.bin"
LEVEL_0_DLAYER:		.asciz "bin/level_0/00_bg_dlayer.bin"
LEVEL_0_HLAYER:		.asciz "bin/level_0/00_bg_hlayer.bin"
LEVEL_0_VLAYER:		.asciz "bin/level_0/00_bg_vlayer.bin"
# Level 02
# Level 03
# Level 04
# Level 05

# Buffers de gráfico
BG_DLAYER_BUFFER:       .space 76800
BG_BLAYER_BUFFER:	.space 76800
BG_HLAYER_BUFFER:	.space 76800
BG_VLAYER_BUFFER:	.space 76800

TUNNEL_M_PATH:		.asciz "bin/tunnel_mask.bin"
TUNNEL_MASK:		.space 400

# Representação virtual dos túneis

GAME_MAP: 		.space 76800
GAP_DATA:		.space 324
GAP_DATA_PATH:		.asciz "bin/gap.bin"

# Levels
LEVEL_COUNTER:	 	.word 0

.text

.macro GAME ()

	# Primeiro setup
	
	la	t0, LEVEL_0_GMAP
	sw	t0, GAME_MAP_PATH_PTR, t1
	
	la	t0, LEVEL_0_DLAYER
	sw	t0, DLAYER_PATH_PTR, t1
	
	la	t0, LEVEL_0_HLAYER
	sw	t0, HLAYER_PATH_PTR, t1
	
	la	t0, LEVEL_0_VLAYER
	sw	t0, VLAYER_PATH_PTR, t1
	
	la	t0, LEVEL_0_BLAYER
	sw	t0, BLAYER_PATH_PTR, t1
	
	# Resetamos todos os valores
	
	# A seção a seguir executa quando há:
	# - Início de jogo
	# - Troca de fase
	# - Perda de vida
    SETUP:
	# Carrega os arquivos referentes à fase
	LOAD_FILE_PTR(DLAYER_PATH_PTR, BG_DLAYER_BUFFER, 76800)
	LOAD_FILE_PTR(HLAYER_PATH_PTR, BG_HLAYER_BUFFER, 76800)
	LOAD_FILE_PTR(VLAYER_PATH_PTR, BG_VLAYER_BUFFER, 76800)
	LOAD_FILE_PTR(BLAYER_PATH_PTR, BG_BLAYER_BUFFER, 76800)
	# Carrega mapa de jogo
	LOAD_FILE_PTR(GAME_MAP_PATH_PTR, GAME_MAP, 76800)
	
	# Carrega inimigos e desenha
	# Load file with enemy info
	
	li a0, 200
	li a1, 800
	LOAD_ENEMY(POOKA_IN, POOKA_SIZE, GAME_POOKA_BUFFER, ENEMY_POS_OFFSET, a0, a1)
	# Draw pooka
	
	# Carrega Dig Dug
	SET_VALUE_IMM(DIGDUG_TOP_X, 1400)
	SET_VALUE_IMM(DIGDUG_TOP_Y, 1200)
	SET_VALUE_IMM(DIGDUG_BOT_X, 1590)
	SET_VALUE_IMM(DIGDUG_BOT_Y, 1390)
	
	# Pinta a tela de preto para apagar menu
	li 	t1, 0xFF000000
	li 	t2, 0xFF012C00
	li 	t3, 0x00000000
    FILL_B: 
	beq 	t1, t2, END_FILL_B
	sw 	t3, 0(t1)
	addi 	t1, t1, 4
	j FILL_B
    END_FILL_B:
	
	
	# Set Dig Dug initial position, draw him
	
	li a0, 320
	li a1, 240
	DRAW_IMG(BG_DLAYER_BUFFER, 320, zero, a0, a1, zero, zero)
	
	# Draw flower function
	li a0, 320
	li a1, 240
	DRAW_IMG(BG_BLAYER_BUFFER, 320, zero, a0, a1, zero, zero)
	
	# Print start message and redraw
	
	
MAIN: 
	lw t0, INPUT_RDY_ADDR		# Vemos se há caractere a ler
	beq t0, zero, GET_CURRENT_TIME  
	lw t0, INPUT_DATA_ADDR   	# Termina o loop se recebermos o caractere desejado
	li t1, INPUT_FINISH		# Caractere desejado
	beq t0, t1, END			# Teste
	mv s2, t0			# Colocamos o caractere em buffer para uso futuro
	
GET_CURRENT_TIME:
	GET_TIME(s0) 			# Pegamos o tempo no começo do loop



MOVEMENT_PHASE:


	DIGDUG_MOVE:
	# Pegamos o input recebido, que está armazenado em s2, testamos para ver se é uma direção válida
	
	mv t0, s2
	li t1, GAME_UP_KEY
	beq t0, t1, DIGDUG_MOVE_UP
	li t1, GAME_LF_KEY
	beq t0, t1, DIGDUG_MOVE_LEFT
	li t1, GAME_DW_KEY
	beq t0, t1, DIGDUG_MOVE_DOWN
	li t1, GAME_RT_KEY
	beq t0, t1, DIGDUG_MOVE_RIGHT
	li t1, GAME_ATK_KEY
	beq t0, t1, DIGDUG_ATTACK
	j DIGDUG_CALC_NEXT_POS
	
	DIGDUG_MOVE_UP:
		# Mudamos a velocidade de Dig Dug - magnitude, direção e sentido
		# Checamos se é uma posição válida para mudança de direção - X e Y precisam ser múltiplos de 20
		# A checagem só é feita se houver mudança de direção
		lw t0, DIGDUG_DIRECTION
		li t1, 1
		ble t0, t1, DIGDUG_MOVE_UP_OK		# Se Dig Dug não mudar de direção, ignoramos o próximo teste
		lw a0, DIGDUG_TOP_X
		lw a1, DIGDUG_TOP_Y
		IS_ALIGNED(a0, a1)
		beq a0, zero, DIGDUG_CALC_NEXT_POS
	DIGDUG_MOVE_UP_OK:
		li a0, 0xFFFFFFFF		# Move-se para cima. O componente Y da velocidade deve ser negativo, então convertemos
		li t0, DIGDUG_BS_SPEED
		sub a0, a0, t0
		addi a0, a0, 1
		SET_VALUE_REG(DIGDUG_SPEED_Y, a0)
		SET_VALUE_REG(DIGDUG_SPEED_X, zero)
		SET_VALUE_IMM(DIGDUG_DIRECTION, 0)
		j DIGDUG_CALC_NEXT_POS

	DIGDUG_MOVE_DOWN:
		lw t0, DIGDUG_DIRECTION
		li t1, 1
		ble t0, t1, DIGDUG_MOVE_DOWN_OK
		lw a0, DIGDUG_TOP_X
		lw a1, DIGDUG_TOP_Y
		IS_ALIGNED(a0, a1)
		beq a0, zero, DIGDUG_CALC_NEXT_POS
	DIGDUG_MOVE_DOWN_OK:
		li a0, DIGDUG_BS_SPEED
		SET_VALUE_REG(DIGDUG_SPEED_Y, a0)
		SET_VALUE_REG(DIGDUG_SPEED_X, zero)
		SET_VALUE_IMM(DIGDUG_DIRECTION, 1)
		j DIGDUG_CALC_NEXT_POS

	DIGDUG_MOVE_LEFT:
		lw t0, DIGDUG_DIRECTION
		li t1, 2
		bge t0, t1, DIGDUG_MOVE_LEFT_OK
		lw a0, DIGDUG_TOP_X
		lw a1, DIGDUG_TOP_Y
		IS_ALIGNED(a0, a1)
		beq a0, zero, DIGDUG_CALC_NEXT_POS
	DIGDUG_MOVE_LEFT_OK:
		li a0, DIGDUG_BS_SPEED		# Move-se para a esquerda. O componente X da velocidade deve ser negativo, então convertemos
		neg a0, a0
		SET_VALUE_REG(DIGDUG_SPEED_X, a0)
		SET_VALUE_REG(DIGDUG_SPEED_Y, zero)
		SET_VALUE_IMM(DIGDUG_DIRECTION, 2)
		j DIGDUG_CALC_NEXT_POS
	
	DIGDUG_MOVE_RIGHT:
		lw t0, DIGDUG_DIRECTION
		li t1, 2
		bge t0, t1, DIGDUG_MOVE_RIGHT_OK
		lw a0, DIGDUG_TOP_X
		lw a1, DIGDUG_TOP_Y
		IS_ALIGNED(a0, a1)
		beq a0, zero, DIGDUG_CALC_NEXT_POS
	DIGDUG_MOVE_RIGHT_OK:
		li a0, DIGDUG_BS_SPEED
		SET_VALUE_REG(DIGDUG_SPEED_X, a0)
		SET_VALUE_REG(DIGDUG_SPEED_Y, zero)
		SET_VALUE_IMM(DIGDUG_DIRECTION, 3)
		j DIGDUG_CALC_NEXT_POS

	DIGDUG_ATTACK: # Solta a mangueira, fica parado enquanto espera voltar

	DIGDUG_CALC_NEXT_POS:
	
		# Guardamos a posição atual
		loadw( 	a0, DIGDUG_TOP_X)
		SET_VALUE_REG(DIGDUG_TOP_X_P, a0)
		loadw(	a0, DIGDUG_TOP_Y)
		SET_VALUE_REG(DIGDUG_TOP_Y_P, a0)
		loadw( 	a0, DIGDUG_BOT_X)
		SET_VALUE_REG(DIGDUG_BOT_X_P, a0)
		loadw( 	a0, DIGDUG_BOT_Y)
		SET_VALUE_REG(DIGDUG_BOT_Y_P, a0)
	
		# Checa se Dig Dug não saiu da borda do jogo. Testamos X e Y.
		# Atualizamos X
		lw a0, DIGDUG_TOP_X
		lw t0, DIGDUG_SPEED_X
		add a0, a0, t0
		li t0, WORLD_UP_EDGE_X
		blt a0, t0, DIGDUG_TEST_LOWER_X
		mv a0, t0
		SET_VALUE_REG(DIGDUG_SPEED_X, zero)
		j DIGDUG_SET_NEW_X
	DIGDUG_TEST_LOWER_X:
		li t0, WORLD_LW_EDGE_X
		bge a0, t0, DIGDUG_SET_NEW_X
		mv a0, t0
		SET_VALUE_REG(DIGDUG_SPEED_X, zero)
	DIGDUG_SET_NEW_X:
		mv s11,	a0
		SET_VALUE_REG(DIGDUG_TOP_X, a0)
		addi s11, s11, 190
		SET_VALUE_REG(DIGDUG_BOT_X, s11)
		
		# Atualizamos Y
		lw a0, DIGDUG_TOP_Y
		lw t0, DIGDUG_SPEED_Y
		add a0, a0, t0

		li t0, WORLD_UP_EDGE_Y
		blt a0, t0, DIGDUG_TEST_LOWER_Y
		mv a0, t0
		SET_VALUE_REG(DIGDUG_SPEED_Y, zero)
		j DIGDUG_SET_NEW_Y
	DIGDUG_TEST_LOWER_Y:
		li t0, WORLD_LW_EDGE_Y
		bge a0, t0, DIGDUG_SET_NEW_Y
		mv a0, t0
		SET_VALUE_REG(DIGDUG_SPEED_Y, zero)
	DIGDUG_SET_NEW_Y:
		mv s11, a0
		SET_VALUE_REG(DIGDUG_TOP_Y, a0)
		addi s11, s11, 190
		SET_VALUE_REG(DIGDUG_BOT_Y, s11)
	
	DIGDUG_CALC_NEXT_POS_END:
	
		# Colocar checagem se está cavando ou não
		# Para isso, testar TOP e BOT
		
	# Pooka
	# Ao contrário de Dig Dug, Pooka colide com paredes
	# Tem a mesma restrição de movimento na grade
	
	
	
	
	
UPDATE_GAME_MAP:


		# Checamos se Dig Dug cavou algo e atualizamos o mapa
		# Como a rocha caindo também pode alterar a configuração do mapa, ela também aparece aqui
	
		# Dig Dug
		DIGDUG_DIGS()
		


	# Um loop que é aplicado a cada inimigo carregado em memória
    ENEMY_PHASE:
    	# WIP
    	la	t0, CURRENT_ENEMY_ADDR
    	la	t1, GAME_POOKA_BUFFER
    	sw	t1, (t0)
    	ENEMY_ACTION(CURRENT_ENEMY_ADDR)


COLLISION_TEST: # Passar teste de colisão para depois da renderização


RENDER_OBJECTS:

		# Usamos a booleana DIGDUG_DIGGING para determinar se irá cavar (substituir o background) ou não.
		# Usa-se 2 camadas para representar as divisórias horizontais e verticais
		# Se Dig Dug se mover horizontalmente, apaga as divisórias verticais, e vice-versa
		
		loadw(	a0, DIGDUG_TOP_X_P)
		loadw(	a1, DIGDUG_TOP_Y_P)
		li	a2, 20
		li	a3, 20
		
		REDRAW_BG(a0, a1, a2, a3)
	
	
	DRAW_DIGDUG:
		# Desenhando Dig Dug
		# Se não estiver cavando, usar transparência
	
		loadw(	a3, DIGDUG_TOP_X)
		loadw(	a4, DIGDUG_TOP_Y)
		li 	t0, 10
		div 	a3, a3, t0
		div 	a4, a4, t0
		addi 	a3, a3, 1
		addi 	a4, a4, 1
		
		# Retorna a0, a1, a2
		DIGDUG_SPRITE_PICK()
		DRAW_IMG(DIGDUG_SPRT_SHEET, 36, a0, a1, a2, a3, a4)
		
	# Pookas(s)
	
	# Checa se há Pookas para desenhar
	DRAW_POOKA:
		loadw(t0, GAME_POOKA_COUNT)
		beq t0, zero, DRAW_POOKA_END
		
		
		
	# TO-DO - Fazer quatro checks em vez de um só com um loop
	
		loadw( 	t0, CURRENT_ENEMY_ADDR)
		addi 	t0, t0, ENEMY_POS_OFFSET
		
		# Redesenhamos o BG primeiro
		lw	a0, 16(t0)
		lw	a1, 20(t0)
		li	a2, 20
		li	a3, 20
		REDRAW_BG(a0, a1, a2, a3)
		
		loadw( 	t0, CURRENT_ENEMY_ADDR)
		addi 	t0, t0, ENEMY_POS_OFFSET
		
		lw 	a3,  (t0)
		lw 	a4, 4(t0)
		
		li 	t1, 10
		div 	a3, a3, t1
		div 	a4, a4, t1
		addi 	a3, a3, 1
		addi 	a4, a4, 1
		
		ENEMY_SPRITE_PICK(CURRENT_ENEMY_ADDR)
		DRAW_IMG(POOKA_SPRITE_BUFFER, 36, a0, a1, a2, a3, a4)
		
		
	DRAW_POOKA_END:
	
SOUND_PHASE:
	SOUND_FUNCT()


# Mudar para uma macro WIP
GAME_OVER_TEST:
	loadw(	t0, ENEMY_DD_COLLIDED)
	beq	t0, zero, WAIT
	
	li	a0, 8888
	li	a7, 1
	ecall
	
WAIT:
	# Calcula quanto tempo esperar até a próxima atualização, printa esse tempo
	GET_TIME(t1)			# Pegamos o tempo no final do loop, após todas as computações
	addi s0, s0, TIME_STEP  	# Adicionamos o intervalo que queremos, para decidir o momento da próxima atualização
	sub s0, s0, t1			# Subtraímos o tempo no final do loop do valor anterior para sabermos quanto tempo esperar

	
	mv a0, s0			# Printamos esse valor
	li a7, 1
	ecall
	
	li a0, 10			# Printamos 'new line', para pular para a próxima linha no I/O
	li a7, 11
	ecall
	
	# Função Wait nua
	mv a0, s0
	bgez a0, NORMAL_TIME_STEP	# Caso o loop demore demais, não esperamos nada
	li a0, 0		
	NORMAL_TIME_STEP:
	li a7, 32
	ecall

	jump (t0, MAIN)
	
	
LEVEL_SELECT: 
	
END:	
	# DEBUG, remover depois
	li a0, 320
	li a1, 240
	DRAW_IMG(GAME_MAP, 320, zero, a0, a1, zero, zero)
	

.end_macro
