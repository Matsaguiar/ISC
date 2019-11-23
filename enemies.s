.include "common.s"

############
# Inimigos #
############
.eqv ENEMY_BS_SPEED     0x0A
.eqv ENEMY_UP	        1
.eqv ENEMY_DOWN	        -1
.eqv ENEMY_LEFT         2
.eqv ENEMY_RIGHT        -2

.eqv EXIT_X	     	0
.eqv EXIT_Y		200

.eqv POOKA_SIZE         68		# Espaço em bytes ocupado por um Pooka - Sempre lembrar de atualizar após alterações
.eqv FYGAR_SIZE         0

.eqv ENEMY_DIR_OFFSET   4
.eqv ENEMY_POS_OFFSET   24

.data
# Variáveis de controle
ENEMY_DD_COLLIDED:	.word 0

#########
# Pooka #
#########
POOKA_IN: 		.word 1

POOKA_DIRECTION: 	.word ENEMY_DOWN
POOKA_CYCLE: 		.word 0x00

# Estados possíveis:
# 0: normal; 1: fantasma; 2: inflado; 3: jogando fogo; 4: sendo esmagado; 5: explodindo
POOKA_STATE: 		.word 0x00

POOKA_SPEED_X: 		.word 0
POOKA_SPEED_Y: 		.word 0

POOKA_TOP_X: 		.word 255
POOKA_TOP_Y: 		.word 255
POOKA_BOT_X: 		.word 255
POOKA_BOT_Y: 		.word 255

POOKA_TOP_X_P: 		.word 255
POOKA_TOP_Y_P: 		.word 255
POOKA_BOT_X_P: 		.word 255
POOKA_BOT_Y_P: 		.word 255

POOKA_ROCK_ADDR:	.word 0x00

POOKA_INIT_X:		.word 0x00
POOKA_INTI_Y:		.word 0x00

# Fygar

FYGAR_IN: 		.word 1

FYGAR_SPEED_X: 		.word 2
FYGAR_SPEED_Y: 		.word 2

FYGAR_TOP_X: 		.word 255
FYGAR_TOP_Y: 		.word 255
FYGAR_BOT_X: 		.word 255
FYGAR_BOT_Y: 		.word 255

FYGAR_ROCK_ADDR:	.word 0x00

# Inimigos carregados em memória
CURRENT_ENEMY_ADDR:	.word 0x00
ENEMY_AVAIL_DIR:	.space 16

#ALIGNMENT_BUFFER_00:	.space 2
# Pooka(s) - Espaço para só um, por enquanto
.align 2
GAME_ENEMY_COUNT:	.word 0
GAME_POOKA_COUNT:	.word 0 		# Quantidade de pookas remanescentes
GAME_POOKA_BUFFER: 	.space 272		# Deverá ser 4 vezes o tamanho de um Pooka


.text

# Carrega um inimigo na memória
# %template: label; %size: eqv; %enemy_buffer: label; %posoffset: eqv; %posx e %posy: registradores
.macro LOAD_ENEMY (%template, %size, %enemy_buffer, %posoffset, %posx, %posy)
	# Adicionamos 1 para o contador de inimigos e 1 para o contador daquele tipo de monstro
	la t0, GAME_ENEMY_COUNT
	lw t1, (t0)
	addi t1, t1, 1
	sw t1, (t0)
	
	la t0, %enemy_buffer
	lw t1, -4(t0)
	addi t1, t1, 1
	sw t1, -4(t0)
	
	# O teste presume que sempre haverá um espaço vazio, só precisa encontrá-lo
	TEST_AVAILABILITY:
		lw t1, (t0)
		beq t1, zero, TEST_AVAILABILITY_END
		addi t0, t0, %size
		j TEST_AVAILABILITY
	TEST_AVAILABILITY_END:
	
	# Copia o template para o espaço
	
	la t1, %template
	li t2, %size
	mv t4, t0					# Armazena o endereço do começo do espaço para depois
	
	LOAD:
		beq t2, zero, LOAD_END
		lb t3, (t1)
		sb t3, (t0)
		addi t0, t0, 1
		addi t1, t1, 1
		addi t2, t2, -1
		j LOAD
	LOAD_END:
	
	# Definir posição inicial
	
	li t3, %posoffset
	add t0, t4, t3
	mv t1, %posx
	mv t2, %posy
	
	sw t1, (t0)
	sw t2, 4(t0)
	# Bottom coords
	addi t1, t1, 200
	addi t2, t2, 200
	addi t0, t0, 8
	
	sw t1, (t0)
	sw t2, 4(t0)
.end_macro


# Enemy AI

# Testa colisão com paredes
# Retorna, em a0, 1: colisão, 0: sem colisão
# %game_map: Label
# Usa t0, t1, t5, t6, a0
.macro ENEMY_WALL_COLL (%topx, %topy, %direction)

	mv 	t0, %direction
	
	li	t1, ENEMY_UP
	beq 	t0, t1, DIR_UP
	li	t1, ENEMY_DOWN
	beq	t0, t1, DIR_DOWN
	li	t1, ENEMY_LEFT
	beq	t0, t1, DIR_LEFT
	li	t1, ENEMY_RIGHT
	beq	t0, t1, DIR_RIGHT
	j COLL_DETECT
	
	# Procuramos o pixel a testar no mapa do jogo
	DIR_UP: 	li 	t6, 10
		
			mv 	t0, %topx
			div 	t0, t0, t6
			addi	t0, t0, 1
		
			mv 	t1, %topy
			div	t1, t1, t6
			
			li 	t5, 1
			j FIND_OFFSET
			
	DIR_DOWN:	li 	t6, 10
	
			mv 	t0, %topx
			div	t0, t0, t6
			addi	t0, t0, 1
			
			mv	t1, %topy
			addi	t1, t1, 190			# Possível problema aqui
			div	t1, t1, t6
			
			li	t5, 1
			j FIND_OFFSET
	
	DIR_LEFT:	li	t6, 10
	
			mv 	t0, %topx
			div	t0, t0, t6
		
			mv	t1, %topy
			div	t1, t1, t6
			addi	t1, t1, 1
			
			li	t5, 320
			j FIND_OFFSET
			
	DIR_RIGHT:	li	t6, 10
	
			mv	t0, %topx
			addi	t0, t0, 190
			div	t0, t0, t6
			
			mv	t1, %topy
			div	t1, t1, t6
			addi	t1, t1, 1
			
			li	t5, 320
			
	
	FIND_OFFSET:	li	t6, 320
			mul 	t1, t1, t6
			add	t0, t0, t1
			la 	t6, GAME_MAP
			add	t6, t0, t6
	
			li	t0, 18				# Se encontrar problemas de desempenho, tentar mudar teste de byte para word
	TEST:  		beq 	t0, zero, NO_COLL
			lb	t1, (t6)
			bne 	t1, zero, COLL_DETECT
			add	t6, t6, t5
			addi	t0, t0, -1
			j TEST
			
	NO_COLL:	li 	a0, 0
			j END
	COLL_DETECT:	li	a0, 1
	END:
.end_macro

# Decide a próxima direção
# Todos os argumentos são labels, exceto o último
# Usa t0, t1, t2, t3, t4, a0, a1, a2, s9, s10, s11
.macro ENEMY_NORMAL_DIR (%enemy_addr)

	# Clear buffer with available directions first
	la	t0, ENEMY_AVAIL_DIR
	sw	x0, (t0)
	sw	x0, 4(t0)
	sw	x0, 8(t0)
	sw	x0, 12(t0)
	mv	s11, zero
	
	# Testamos se o inimigo está alinhado com a grade
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_POS_OFFSET
	lw	a0, (t0)
	lw	a1, 4(t0)
	IS_ALIGNED(a0, a1)
	beq	a0, zero, TEST_CUR_DIR		# Se não estiver alinhado, só pode voltar para trás
	
	# Testamos se há possíveis caminhos alternativos
	
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_DIR_OFFSET
	lw	t1, (t0)
	li	t2, 2
	rem	t1, t1, t2
	# Considerando as direções horizontais como 2 e -2, e as verticais como 1 e -1, podemos saber o sentido
	# por meio do resto da divisão por 2 
	beq	t1, zero, TEST_VERTICAL

	TEST_HORIZONTAL:
		# Test left
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_POS_OFFSET
		lw	t3, (t0)
		lw	t4, 4(t0)
		li	a0, ENEMY_LEFT
		ENEMY_WALL_COLL (t3, t4, a0)
		bne	a0, zero, TEST_RIGHT
		# Adiciona direção à lista de direções válidas
		
		la	t0, ENEMY_AVAIL_DIR
		li	t1, 4
		mul	t1, s11, t1
		add	t0, t0, t1
		li	t1, ENEMY_LEFT
		sw	t1, (t0)
		addi	s11, s11, 1
		
		TEST_RIGHT:
			li 	a0, ENEMY_RIGHT
			ENEMY_WALL_COLL(t3, t4, a0)
			bne	a0, zero, CHOOSE_DIR
			
			la	t0, ENEMY_AVAIL_DIR
			li	t1, 4
			mul	t1, s11, t1
			add	t0, t0, t1
			li	t1, ENEMY_RIGHT
			sw	t1, (t0)
			addi	s11, s11, 1
			j CHOOSE_DIR
	
	TEST_VERTICAL:
		# Test up
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_POS_OFFSET
		lw	t3, (t0)
		lw	t4, 4(t0)
		li	a0, 1
		ENEMY_WALL_COLL (t3, t4, a0)
		bne	a0, zero, TEST_DOWN
		
		la 	t0, ENEMY_AVAIL_DIR
		li	t1, 4
		mul	t1, s11, t1
		add	t0, t0, t1
		li	t1, ENEMY_UP
		sw	t1, (t0)
		addi	s11, s11, 1
		
		TEST_DOWN:
			li 	a0, ENEMY_DOWN
			ENEMY_WALL_COLL(t3, t4, a0)
			bne	a0, zero, CHOOSE_DIR
			
			la	t0, ENEMY_AVAIL_DIR
			li	t1, 4
			mul	t1, s11, t1
			add	t0, t0, t1
			li	t1, ENEMY_DOWN
			sw	t1, (t0)
			addi	s11, s11, 1
		 
		 
    CHOOSE_DIR:
		# Se não houver caminhos disponíveis, testamos a direção atual somente
	beq	s11, zero, TEST_CUR_DIR
	
	# Descomentar as próximas três linhas faz com que o inimigo fuja se for o último	
	#loadw(	t0, GAME_ENEMY_COUNT)
	#li	t1, 1
	#beq	t0, t1, LAST_ENEMY
	# Não é o último inimigo, então checamos se está alinhado com Dig Dug
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_POS_OFFSET
	lw	t1, (t0)
	lw	t2, 4(t0)
	
	loadw(	t3, DIGDUG_TOP_X)
	beq	t1, t3, CHASE_DIGDUG_SAME_X
	loadw(	t3, DIGDUG_TOP_Y)
	beq	t2, t3, CHASE_DIGDUG_SAME_Y
	j RANDOM_DIRECTION
	
    CHASE_DIGDUG_SAME_X:
    	loadw(	t3, DIGDUG_TOP_Y)
    	sub	t4, t2, t3
    	bge	t4, zero, CHASE_UP
    	# Chase down
    	li	s10, ENEMY_DOWN
    	j DIR_TEST_IF_VALID
    	CHASE_UP:
    		li	s10, ENEMY_UP
		j DIR_TEST_IF_VALID

    CHASE_DIGDUG_SAME_Y:
    	loadw(	t3, DIGDUG_TOP_X)
    	sub	t4, t1, t3
    	bge	t4, zero, CHASE_LEFT
    	# Chase right
    	li	s10, ENEMY_RIGHT
    	j DIR_TEST_IF_VALID
	CHASE_LEFT:
		li	s10, ENEMY_LEFT
		j DIR_TEST_IF_VALID


    LAST_ENEMY:
    	loadw(	t0, %enemy_addr)
    	addi	t0, t0, ENEMY_POS_OFFSET
    	lw	t1, 4(t0)
    
	li	t2, EXIT_Y
	sub	t3, t1, t2
	bgt	t3, zero, ESCAPE_UP
	# Estamos na altura da saída, então o inimigo se move horizontalmente
	# Essa seção só funciona se a saída for em X: 0, Y: 200, e não houver obstáculos
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_DIR_OFFSET
	li	t1, ENEMY_LEFT
	sw	t1, (t0)
	j END
	
	ESCAPE_UP:
		li	s10, ENEMY_UP
		j DIR_TEST_IF_VALID


    DIR_TEST_IF_VALID: # Temos s10 = direção
		mv	a2,	s10
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_POS_OFFSET
		lw	a0, (t0)
		lw	a1, 4(t0)
		ENEMY_WALL_COLL(a0, a1, a2)
		bne	a0, zero, RANDOM_DIRECTION
		# Se não houver colisão, perseguimos
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_DIR_OFFSET
		sw	s10, (t0)
		j END
		
		
    RANDOM_DIRECTION: # Escolhemos uma direção entre as disponíveis. Testamos se a direção atual e a inversa dela são válidas.
    	loadw(	t0, %enemy_addr)
    	addi	t0, t0, ENEMY_DIR_OFFSET
    	lw	s10, (t0)
	
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_POS_OFFSET
	lw	a0, (t0)
	lw	a1, 4(t0)
	ENEMY_WALL_COLL(a0, a1, s10)
	bne	a0, zero, TEST_OPP_DIR
	
	la	t2, ENEMY_AVAIL_DIR
	li	t1, 4
	mul	t1, s11, t1
	add	t2, t2, t1
	sw	s10, (t2)
	addi	s11, s11, 1
	TEST_OPP_DIR:
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_POS_OFFSET
		lw	a0, (t0)
		lw	a1, 4(t0)
		neg 	s10, s10
		ENEMY_WALL_COLL(a0, a1, s10)
		bne 	a0, zero, PICK_RNDM_DIR
		
		la	t2, ENEMY_AVAIL_DIR
		li	t1, 4
		mul	t1, s11, t1
		add	t2, t2, t1
		sw	s10, (t2)
		addi	s11, s11, 1
		
	PICK_RNDM_DIR: 			# Geramos um número aleatório usando o syscall de tempo
		li	a7, 30
		ecall
		mv	a1, a0
		li	a0, 0
		li	a7, 40
		ecall
		
		addi	s11, s11, -1
		mv	a1, s11
		li	a7, 42
		ecall
		
		la	t0, ENEMY_AVAIL_DIR
		li	t1, 4
		mul	t1, t1, a0
		add	t0, t0, t1
		lw	t3, (t0)
		
		loadw(	t0, %enemy_addr)
		addi	t0, t0, ENEMY_DIR_OFFSET
		sw	t3, (t0)
		j END
	
	# Testa se há colisão no caminho atual, se houver, troca para o sentido oposto
    TEST_CUR_DIR:
    	loadw(	t0, %enemy_addr)
    	addi	t0, t0, ENEMY_POS_OFFSET
    	lw	a0, (t0)
    	lw	a1, 4(t0)
    	
    	loadw(	t0, %enemy_addr)
    	addi	t0, t0, ENEMY_DIR_OFFSET
    	lw	a2, (t0)
    	
    	ENEMY_WALL_COLL (a0, a1, a2)
    	beq	a0, zero, END
    	# Não funcionará se o sentido oposto não for o sentido atual negativado
    	loadw(	t0, %enemy_addr)
    	addi	t0, t0, ENEMY_DIR_OFFSET
    	lw	t1, (t0)
    	neg	t1, t1
    	sw	t1, (t0)
    
    END:
.end_macro

# Atualiza posição do inimigo, caso esteja em estado normal
# Usa t0, t1, t2, t3, a0, a1, a2, a3
.macro ENEMY_UPDATE_POSITION (%enemy_addr)
	# Testar se está normal ou fantasma, talvez?
	
	# Guardamos a posição anterior primeiro
	loadw(	t0, %enemy_addr)
	addi	t0, t0, ENEMY_POS_OFFSET		# Não alterar t0 a partir de agora
	lw	a0, (t0)
	lw	a1, 4(t0)
	sw	a0, 16(t0)				# Não alterar a0 e a1
	sw	a1, 20(t0)
	addi	a2, a0, 200
	addi	a3, a1, 200
	sw	a2, 24(t0)
	sw	a3, 28(t0)
	
	# Escolhemos a direção
	
	loadw(	t1, %enemy_addr)
	addi	t1, t1, ENEMY_DIR_OFFSET
	lw	t2, (t1)
	
	li	t3, ENEMY_UP
	beq	t2, t3, ENEMY_MOVE_UP
	li	t3, ENEMY_DOWN
	beq	t2, t3, ENEMY_MOVE_DOWN
	li	t3, ENEMY_LEFT
	beq	t2, t3, ENEMY_MOVE_LEFT
	
	# a0: POS_X, a1: POS_Y
    	# ENEMY_MOVE_RIGHT
		addi	a2, a0, ENEMY_BS_SPEED
		sw	a2, (t0)
		addi	a2, a2, 200
		sw	a2, 8(t0)
		j END
   	 ENEMY_MOVE_UP:
		li	a2, ENEMY_BS_SPEED
		neg	a2, a2
		add	a2, a1, a2
		sw	a2, 4(t0)
		addi	a2, a2, 200
		sw	a2, 12(t0)
		j END
	ENEMY_MOVE_DOWN:
		addi	a2, a1, ENEMY_BS_SPEED
		sw	a2, 4(t0)
		addi	a2, a2, 200
		sw	a2, 12(t0)
		j END
	ENEMY_MOVE_LEFT:
		li	a2, ENEMY_BS_SPEED
		neg	a2, a2
		add	a2, a0, a2
		sw	a2, (t0)
		addi	a2, a2, 200
		sw	a2, 8(t0)
		j END
	
    END:
.end_macro

# Só para Pooka, no momento
# Usa t0, s9, s10, s11
.macro ENEMY_SPRITE_PICK (%enemy_addr_ptr)

	# Armazena endereço do inimigo em s9 para o resto da sub-rotina
	loadw(	s9, %enemy_addr_ptr)
	
	# ALERTA; CONSTANTE MÁGICA TROCAR DEPOIS
	# Representa offset de State
	lw		t0, 12(s9)
	# Representa offset de ciclo de animação
	lw		s10, 8(s9)
	
	beq		t0, zero, NORMAL
	j END
	
	NORMAL:
	
	

    	
    # WALK_RIGHT:
    	li	t0, 3240
    	add	a0, zero, t0
    	j CYCLE
    	
    	  	
    	
    	# Como Dig Dug só tem dois sprites por animação, só tem 2 ciclos
    	# Achamos o offset X multiplicando o ciclo pelo tamanho do sprite
    	CYCLE: 
    		# Testamos primeiro se Dig Dug está se movimentando. Se não estiver, não fazemos nada
    		loadw(	t0, DIGDUG_SPEED_X)
    		loadw(	t1, DIGDUG_SPEED_Y)
    	
    		add	t0, t0, t1
    		beq	t0, zero, END
    	
    		# Para que a animação só seja atualizada a cada 2 frames
    		mv	t1, s11
    		li	t2, 2
    		#div	t1, t1, t2
    		
    		li	t0, 18
    		mul	t0, t0, t1
    		add	a0, a0, t0
    		
    		# Usamos função modulo para retornar o contador de ciclos para 0, se alcançar 4
    		li	t0, 2
    		addi	s11, s11, 1
    		rem	s11, s11, t0
    		
    		sw	s11, DIGDUG_CYCLE, t0
    		
    		
    		j END
    
    END:
    	li	a1, 18
    	li	a2, 18
 
.end_macro

# Testa colisão entre um inimigo e Dig Dug
# Retorna, em a0, se houve colisão ou não
# Usa t0, t1, t2, t3, t4, s7, s8, s9, s10, s11, a0, a1
.macro ENEMY_DD_COLL (%enemy_addr_ptr)
	
	loadw(	s11, %enemy_addr_ptr)
	addi	t0, s11, ENEMY_POS_OFFSET
	
	# Enemy top X
	lw	t1, (t0)
	# Enemy top Y
	lw	t2, 4(t0)
	# Enemy bottom X
	lw	t3, 8(t0)
	# Enemy bottom Y
	lw	t4, 12(t0)
	
	# Ajuste de caixa de colisão
	# Top
	addi	t1, t1, 50
	addi	t2, t2, 50
	# Bottom
	addi	t3, t3, -50
	addi	t3, t3, -50
	
	loadw(	s7, DIGDUG_TOP_X)
	loadw(	s8, DIGDUG_TOP_Y)
	loadw(	s9, DIGDUG_BOT_X)
	loadw( s10, DIGDUG_BOT_Y)
	
	# Série de comparações para detectar colisão
	
	# if ( D_top_x - En_bot_x > 0) No Col
	sub	a0, s7, t3
	bge	a0, zero, NO_COL
	
	sub	a0, t1, s9
	bge	a0, zero, NO_COL
	
	# Teste de coordenadas Y
	sub	a0, t2, s10
	bge	a0, zero, NO_COL
	
	sub	a0, s8, t4
	bge	a0, zero, NO_COL
	
	# Collision TRUE
	li	a0, 1
	j END
	
    NO_COL:
    	li	a0, 0
    END:
    	sw	a0, ENEMY_DD_COLLIDED, t0
.end_macro

.macro ENEMY_ACTION (%enemy_addr_ptr)
	# Julgar o que fazer baseado no estado do inimgo.
	
	
	# Estado normal
	# To-do:
	# - Testar se transforma em fantasma
	#
	ENEMY_NORMAL_DIR(%enemy_addr_ptr)
	ENEMY_UPDATE_POSITION(%enemy_addr_ptr)
	ENEMY_DD_COLL(%enemy_addr_ptr)
.end_macro

# Usa s11
.macro ENEMY_SPRITE_PICK (%enemy_addr_ptr)

	loadw(	s11, %enemy_addr_ptr)
	lw	s10, 4(s11)					# Direção
	lw	 s9, 8(s11)					# Ciclo 
	
	mv	a0, zero
	
	beq	s11, zero, WALKING

    # Alerta: muitas magic constants
    # Necessário olhar o arquivo de sprite para tirar os valores
    
    WALKING:
    	
    	# Pegamos a direção e testamos
    	li	t0, ENEMY_LEFT
    	beq	s10, t0, WALK_LEFT
    	li	t0, ENEMY_RIGHT
    	beq	s10, t0, WALK_RIGHT
    	
    WALK_LEFT:
    	li	t0, 0
    	add	a0, zero, t0
    	j CYCLE	
    
    WALK_RIGHT:
    	li	t0, 648
    	add	a0, zero, t0
    	j CYCLE  	
    	

    	CYCLE: 
    	
    		# Pooka only
    		mv	t0, s9
    		li	t1, 2
    		bge	t0, t1, CYCLE_2
    		
    		# CYCLE_1
    			li	t0, 0
    			add	a0, a0, t0
    			j CYCLE_INCREASE
    			
    		CYCLE_2:
    			li	t0, 18
    			add	a0, a0, t0
 
    		CYCLE_INCREASE:
    		# Usamos função modulo para retornar o contador de ciclos para 0, se alcançar 4
    		li	t0, 16
    		addi	s9, s9, 1
    		rem	s9, s9, t0
    		
    		sw	s9, 8(s11)
    		
    		j END
    
    END:
    	# Largura e altura do sprite
    	li	a1, 18
    	li	a2, 18
.end_macro
