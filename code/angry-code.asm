# ==============================================================================
# JOGO ANGRY BIRDS: SISTEMA COMPLETO (DOIS CLIQUES, HITBOX, TELA DE VITÓRIA)
# Display: 512x256 | Unit: 4x4 | Base: 0x10010000 | (128x64 unidades)
# ==============================================================================

.text
main:
    li $16, 0               # Deslocamento X das nuvens
    li $17, 0               # Fase do Jogo (0 = Dia, 1 = Noite)

    # ==========================================================================
    # TELA INICIAL
    # ==========================================================================
tela_inicial:
    jal desenha_ceu
    jal desenha_astro      
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra
    jal desenha_passaro
    jal desenha_porco
    jal desenha_titulo      

aguarda_inicio:
    lui $8, 0xFFFF          
    lw $9, 0($8)            
    andi $9, $9, 1        
    beq $9, $0, aguarda_inicio
    lw $10, 4($8)          
    bne $10, 32, aguarda_inicio # Aguarda BARRA DE ESPAÇO para começar
   
    # Pausa (debounce)
    li $2, 32              
    li $4, 250              
    syscall

    # ==========================================================================
    # GAME LOOP PRINCIPAL
    # ==========================================================================
game_loop:
    # SE O ESTADO FOR 3 (VITÓRIA), DESVIA PARA A TELA DE VITÓRIA FIXA
    lw $11, passaro_st
    beq $11, 3, tela_vitoria

    # 1. VERIFICA ENTRADA DO TECLADO (DURANTE O JOGO)
    lui $8, 0xFFFF          
    lw $9, 0($8)            
    andi $9, $9, 1        
    beq $9, $0, render_frame
   
    lw $10, 4($8)          
    beq $10, 32, inverte_fase
    beq $10, 108, aperta_l
    j render_frame

inverte_fase:
    xori $17, $17, 1        
    j render_frame

aperta_l:
    lw $11, passaro_st
    beq $11, 0, inicia_carga      # Se está no estilingue, começa a carregar
    beq $11, 1, atira_passaro     # Se está carregando, atira!
    j render_frame

inicia_carga:
    li $11, 1
    sw $11, passaro_st
    sw $0, forca_atual
    li $11, 1
    sw $11, forca_dir
   
    # Debounce (200ms) para evitar cliques duplos acidentais
    li $2, 32
    li $4, 200
    syscall
    j render_frame

atira_passaro:
    li $11, 2
    sw $11, passaro_st
   
    # Calcula a velocidade com base na força escolhida pelo jogador
    lw $12, forca_atual
   
    # Vx = 2 + (força / 4)
    srl $13, $12, 2
    addi $13, $13, 2
    sw $13, passaro_vx
   
    # Vy = -3 - (força / 3) (Valores negativos sobem na tela)
    li $14, 3
    div $12, $14
    mflo $13
    li $14, -3
    sub $13, $14, $13
    sw $13, passaro_vy
    j render_frame

# ==========================================================================
# LÓGICA DA TELA DE VITÓRIA (ESTÁTICA)
# ==========================================================================
tela_vitoria:
    # 1. Desenha o cenário de fundo estático
    jal desenha_ceu
    jal desenha_estrelas    
    jal desenha_astro      
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra
    jal desenha_passaro       # Pássaro fica parado onde colidiu
    jal desenha_vitoria       # <--- Escreve "VOCE VENCEU" na tela!

aguarda_reinicios:
    # 2. Fica em loop aguardando a tecla 'l' para reiniciar
    lui $8, 0xFFFF          
    lw $9, 0($8)            
    andi $9, $9, 1        
    beq $9, $0, aguarda_reinicios
   
    lw $10, 4($8)          
    bne $10, 108, aguarda_reinicios # Só aceita 'l' (108) para resetar

reseta_jogo:
    # Reinicia posições e força para jogar de novo
    sw $0, passaro_st
    sw $0, forca_atual
    li $11, 12
    sw $11, passaro_x
    li $11, 42
    sw $11, passaro_y
   
    # Debounce para voltar ao jogo limpamente
    li $2, 32
    li $4, 250
    syscall
    j game_loop

render_frame:
    # 2. ATUALIZA FÍSICA E LÓGICAS (APENAS SE NÃO TIVER VENCIDO)
    jal atualiza_carga      # Faz a barra oscilar se estiver carregando
    jal atualiza_fisica     # Move o pássaro e checa a hitbox da colisão
   
    addi $16, $16, 1        
    andi $16, $16, 127      

    # 3. DESENHA O FRAME NORMAL DE JOGO
    jal desenha_ceu
    jal desenha_estrelas    
    jal desenha_astro      
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra
   
    jal desenha_barra       # Desenha a barra de força amarela
    jal desenha_passaro
    jal desenha_porco

    # 4. CONTROLE DE TEMPO (FPS)
    li $2, 32              
    li $4, 40              
    syscall

    j game_loop            

# ==============================================================================
# ATUALIZA CARGA (EFEITO VAI-E-VEM DA BARRA)
# ==============================================================================
atualiza_carga:
    lw $8, passaro_st
    bne $8, 1, fim_carga          # Só roda se estado == 1 (Carregando)
   
    lw $9, forca_atual
    lw $10, forca_dir
    add $9, $9, $10               # Força = Força + Direção
   
    bge $9, 20, inverte_desce     # Máximo de força alcançado = 20
    ble $9, 0, inverte_sobe       # Mínimo de força alcançado = 0
    j salva_carga
   
inverte_desce:
    li $10, -1
    j salva_carga
inverte_sobe:
    li $10, 1
salva_carga:
    sw $9, forca_atual
    sw $10, forca_dir
fim_carga:
    jr $31

# ==============================================================================
# ATUALIZA FÍSICA DO PÁSSARO & HITBOX DE COLISÃO
# ==============================================================================
atualiza_fisica:
    lw $8, passaro_st
    bne $8, 2, fim_fisica         # Só aplica se estado == 2 (Voando)

    lw $9, passaro_x
    lw $10, passaro_y
    lw $11, passaro_vx
    lw $12, passaro_vy

    add $9, $9, $11               # X = X + Vx
    add $10, $10, $12             # Y = Y + Vy
    addi $12, $12, 1              # Vy = Vy + Gravidade (1)

    sw $9, passaro_x
    sw $10, passaro_y
    sw $12, passaro_vy

    # --------------------------------------------------------
    # HITBOX GENEROSA (COLISÃO AABB) CONTRA O ALVO/PORCO
    # Aumentamos a área para aceitar acertos "de raspão"
    # --------------------------------------------------------
    bgt $9, 115, checa_chao       # Limite Direito (expandido para 115)
    addi $13, $9, 5
    blt $13, 98, checa_chao       # Limite Esquerdo (recuado para 98)
    bgt $10, 50, checa_chao       # Limite Inferior (expandido para 50)
    addi $13, $10, 5
    blt $13, 35, checa_chao       # Limite Superior (subido para 35)
   
    # SE PASSOU POR TODOS OS TESTES, TOCOU A HITBOX! VITÓRIA!
    li $13, 3
    sw $13, passaro_st            # Estado = 3 (Ativa a Tela de Vitória)
    j fim_fisica

checa_chao:
    bge $10, 44, falhou_chao      # Rebaixamos o chão para 44 (permite raspar na grama)
    bge $9, 120, falhou_chao      # Saiu da tela pela direita
    j fim_fisica

falhou_chao:
    # Se errou e bateu no chão, volta pro estilingue limpo
    sw $0, passaro_st
    sw $0, forca_atual
    li $13, 12
    sw $13, passaro_x
    li $13, 42
    sw $13, passaro_y
fim_fisica:
    jr $31

# ==============================================================================
# DESENHO DA BARRA DE FORÇA
# ==============================================================================
desenha_barra:
    addi $29, $29, -4
    sw $31, 0($29)
   
    lw $8, passaro_st
    bne $8, 1, fim_desenho_barra  # Só desenha se estiver carregando
   
    lw $9, forca_atual
    beq $9, $0, fim_desenho_barra # Se força for 0, não desenha nada
   
    lw $4, passaro_x
    lw $5, passaro_y
    addi $5, $5, -4               # Posiciona a barra 4 pixels acima do pássaro
    add $6, $4, $9                # Largura estende de acordo com a força
    move $7, $5                  
    li $9, 0x00FFD700             # Cor: Amarelo Ouro
    jal desenha_retangulo

fim_desenho_barra:
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

# ==============================================================================
# DESENHO DOS PERSONAGENS
# ==============================================================================
desenha_passaro:
    addi $29, $29, -4
    sw $31, 0($29)
   
    lw $4, passaro_x
    lw $5, passaro_y
    addi $6, $4, 5          
    addi $7, $5, 5          
    li $9, 0x00E32636       # Vermelho
    jal desenha_retangulo

    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

desenha_porco:
    addi $29, $29, -4
    sw $31, 0($29)
   
    li $4, 105          
    li $5, 42          
    li $6, 110          
    li $7, 47          
    li $9, 0x0055A630   # Verde Porco
    jal desenha_retangulo
   
    # Olhos do porco
    li $10, 44
    li $11, 106
    li $9, 0x00000000  
    jal pinta_pixel_direto
   
    li $10, 44
    li $11, 109
    li $9, 0x00000000  
    jal pinta_pixel_direto

fim_desenha_porco:
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

# GERADOR DE RETÂNGULOS
desenha_retangulo:
    move $10, $5              
laco_ret_y:
    move $11, $4              
laco_ret_x:
    sll $12, $10, 7          
    add $12, $12, $11        
    sll $12, $12, 2          
    lui $13, 0x1001          
    add $12, $12, $13        
    sw $9, 0($12)            
   
    addi $11, $11, 1          
    ble $11, $6, laco_ret_x
   
    addi $10, $10, 1          
    ble $10, $7, laco_ret_y
    jr $31

# ==============================================================================
# FUNÇÃO: DESENHA TEXTO "VOCE VENCEU"
# ==============================================================================
desenha_vitoria:
    addi $29, $29, -4
    sw $31, 0($29)

    la $8, dados_vitoria      
    li $9, 0x00FFFFFF          # Cor: Branco para o texto

laco_vitoria_txt:
    lw $10, 0($8)              
    bltz $10, fim_vitoria_txt  
    lw $11, 4($8)              

    sll $12, $11, 7            
    add $12, $12, $10          
    sll $12, $12, 2            
    lui $13, 0x1001
    add $12, $12, $13          
    sw $9, 0($12)              
   
    addi $8, $8, 8            
    j laco_vitoria_txt

fim_vitoria_txt:
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

# ==============================================================================
# MOTOR GRÁFICO E AMBIENTAL (CÉU, CENÁRIO, TEXTURAS)
# ==============================================================================
desenha_ceu:
    beq $17, $0, paleta_ceu_dia
    li $9, 0x00061224      
    li $11, 0x000B2040      
    li $12, 0x0013325E      
    j aplica_ceu
paleta_ceu_dia:
    li $9, 0x005DADE2      
    li $11, 0x0085C1E9      
    li $12, 0x00AED6F1      
aplica_ceu:
    lui $8, 0x1001          
    li $10, 2048            
laco_ceu1: beq $10, $0, pre_ceu2
    sw $9, 0($8)
    addi $8, $8, 4
    addi $10, $10, -1
    j laco_ceu1
pre_ceu2:
    li $10, 2048            
laco_ceu2: beq $10, $0, pre_ceu3
    sw $11, 0($8)
    addi $8, $8, 4
    addi $10, $10, -1
    j laco_ceu2
pre_ceu3:
    li $10, 2048            
laco_ceu3: beq $10, $0, fim_ceu
    sw $12, 0($8)
    addi $8, $8, 4
    addi $10, $10, -1
    j laco_ceu3
fim_ceu:
    jr $31                  

desenha_estrelas:
    beq $17, $0, fim_estrelas
    li $2, 40              
    li $4, 1                
    li $5, 1998            
    syscall
    li $11, 40              
    li $15, 0x00FFFFFF      
laco_estrelas:
    beq $11, $0, fim_estrelas
    li $2, 42
    li $4, 1
    li $5, 128
    syscall
    move $12, $4            
    li $2, 42
    li $4, 1
    li $5, 32
    syscall
    move $13, $4            
    sll $14, $13, 7        
    add $14, $14, $12      
    sll $14, $14, 2        
    lui $8, 0x1001
    add $14, $14, $8        
    sw $15, 0($14)
    addi $11, $11, -1
    j laco_estrelas
fim_estrelas:
    jr $31

desenha_astro:
    beq $17, $0, paleta_sol
    li $9, 0x00F0F4F8      
    li $10, 4              
    li $15, 100            
    li $24, 109            
    li $25, 13              
    j aplica_astro
paleta_sol:
    li $9, 0x00FFD700      
    li $10, 3              
    li $15, 5              
    li $24, 14              
    li $25, 11              
aplica_astro:
laco_ast_y:
    move $11, $15          
laco_ast_x:
    sll $12, $10, 7        
    add $12, $12, $11      
    sll $12, $12, 2        
    lui $13, 0x1001        
    add $12, $12, $13      
    sw $9, 0($12)          
    addi $11, $11, 1        
    ble $11, $24, laco_ast_x
    addi $10, $10, 1        
    ble $10, $25, laco_ast_y
    jr $31

desenha_cenario_fundo:
    addi $29, $29, -4      
    sw $31, 0($29)
    li $4, 32              
    li $5, 18              
    jal motor_montanha
    li $4, 95              
    li $5, 24              
    jal motor_montanha
    li $4, 64              
    li $5, 12              
    beq $17, $0, cor_mont_dia
    li $25, 0x00101C1C      
    j pula_cor_mont
cor_mont_dia:
    li $25, 0x00244747      
pula_cor_mont:
    jal motor_montanha_cor
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

motor_montanha:
    beq $17, $0, padrao_mont_dia
    li $25, 0x001A2B2B      
    j motor_montanha_cor
padrao_mont_dia:
    li $25, 0x002F4F4F      
motor_montanha_cor:
    li $8, 47              
    sub $9, $8, $5      
    li $10, 0              
m_laco_y:
    bgt $9, $8, fim_montanha
    sub $11, $4, $10      
    add $12, $4, $10      
m_laco_x:
    bgt $11, $12, m_prox_y
    sll $13, $9, 7        
    add $13, $13, $11      
    sll $13, $13, 2        
    lui $14, 0x1001        
    add $13, $13, $14      
    sw $25, 0($13)          
    addi $11, $11, 1
    j m_laco_x
m_prox_y:
    addi $9, $9, 1        
    addi $10, $10, 1        
    j m_laco_y
fim_montanha:
    jr $31

desenha_chao:
    beq $17, $0, cor_chao_dia
    li $9, 0x002B5E28      
    li $11, 0x004A1D07      
    j aplica_chao
cor_chao_dia:
    li $9, 0x004CAF50      
    li $11, 0x008B4513      
aplica_chao:
    lui $8, 0x1001
    addi $8, $8, 24576    
    li $10, 512            
laco_grama: beq $10, $0, pre_terra
    sw $9, 0($8)
    addi $8, $8, 4
    addi $10, $10, -1
    j laco_grama
pre_terra:
    li $10, 1536            
laco_terra: beq $10, $0, fim_chao
    sw $11, 0($8)
    addi $8, $8, 4
    addi $10, $10, -1
    j laco_terra
fim_chao:
    jr $31

desenha_textura_grama:
    addi $29, $29, -4      
    sw $31, 0($29)          
    beq $17, $0, tex_gr_dia
    li $9, 0x00122B10      
    j aplica_tex_gr
tex_gr_dia:
    li $9, 0x002E7D32      
aplica_tex_gr:
    li $11, 0              
laco_grama_topo:
    rem $15, $11, 4        
    bne $15, $0, grama_topo_pula1
    li $10, 46
    jal pinta_pixel_direto
    li $10, 47
    jal pinta_pixel_direto
grama_topo_pula1:
    bne $15, 2, grama_topo_pula2
    li $10, 47
    jal pinta_pixel_direto
grama_topo_pula2:
    addi $11, $11, 1
    blt $11, 128, laco_grama_topo

    li $10, 49
    li $11, 0
laco_grama_miolo:
    rem $15, $11, 5        
    bne $15, $0, grama_miolo_pula
    jal pinta_pixel_direto
    addi $10, $10, 1        
    jal pinta_pixel_direto
    addi $10, $10, -1      
grama_miolo_pula:
    addi $11, $11, 1
    blt $11, 128, laco_grama_miolo
   
    lw $31, 0($29)          
    addi $29, $29, 4        
    jr $31

pinta_pixel_direto:
    sll $12, $10, 7        
    add $12, $12, $11      
    sll $12, $12, 2        
    lui $13, 0x1001
    add $12, $12, $13      
    sw $9, 0($12)
    jr $31

desenha_textura_terra:
    beq $17, $0, tex_te_dia
    li $9, 0x00241003      
    j aplica_tex_te
tex_te_dia:
    li $9, 0x005C2E0B      
aplica_tex_te:
    li $10, 54              
laco_tex_y:
    li $11, 2              
laco_tex_x:
    sll $12, $10, 7        
    add $12, $12, $11      
    sll $12, $12, 2        
    lui $13, 0x1001
    add $12, $12, $13      
    sw $9, 0($12)          
    addi $11, $11, 13      
    ble $11, 127, laco_tex_x
    addi $10, $10, 2        
    ble $10, 62, laco_tex_y
    jr $31

desenha_nuvens:
    addi $29, $29, -4
    sw $31, 0($29)
    li $4, 10              
    li $5, 5              
    jal nuvem_m
    li $4, 50              
    li $5, 12              
    jal nuvem_p
    li $4, 90              
    li $5, 8              
    jal nuvem_g
    li $4, 115            
    li $5, 18              
    jal nuvem_m
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

nuvem_p:
    addi $29, $29, -4
    sw $31, 0($29)
    move $24, $4            
    move $10, $5          
    li $25, 6              
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -2      
    addi $10, $5, 1        
    li $25, 10
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -2      
    addi $10, $5, 2        
    li $25, 10
    jal aplica_cor_nuvem_escura
    jal draw_hline_wrap
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

nuvem_m:
    addi $29, $29, -4
    sw $31, 0($29)
    move $24, $4
    move $10, $5
    li $25, 8
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -3
    addi $10, $5, 1
    li $25, 14
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -5
    addi $10, $5, 2
    li $25, 18
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -5
    addi $10, $5, 3
    li $25, 18
    jal aplica_cor_nuvem_escura
    jal draw_hline_wrap
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

nuvem_g:
    addi $29, $29, -4
    sw $31, 0($29)
    move $24, $4
    move $10, $5
    li $25, 10
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -4
    addi $10, $5, 1
    li $25, 18
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -8
    addi $10, $5, 2
    li $25, 26
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -8
    addi $10, $5, 3
    li $25, 26
    jal aplica_cor_nuvem_clara
    jal draw_hline_wrap
    addi $24, $4, -8
    addi $10, $5, 4
    li $25, 26
    jal aplica_cor_nuvem_escura
    jal draw_hline_wrap
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

aplica_cor_nuvem_clara:
    beq $17, $0, nuv_cla_dia
    li $15, 0x00A0B0C0      
    jr $31
nuv_cla_dia:
    li $15, 0x00FFFFFF      
    jr $31

aplica_cor_nuvem_escura:
    beq $17, $0, nuv_esc_dia
    li $15, 0x00405060      
    jr $31
nuv_esc_dia:
    li $15, 0x00D0E0E8      
    jr $31

draw_hline_wrap:
laco_hline_w:
    beq $25, $0, fim_hline_w
    add $12, $24, $16      
    andi $12, $12, 127      
    sll $13, $10, 7        
    add $13, $13, $12      
    sll $13, $13, 2        
    lui $14, 0x1001
    add $13, $13, $14      
    sw $15, 0($13)          
    addi $24, $24, 1        
    addi $25, $25, -1      
    j laco_hline_w
fim_hline_w:
    jr $31

desenha_titulo:
    addi $29, $29, -4
    sw $31, 0($29)

    la $8, dados_logo          
    li $9, 0x00FFFFFF          

laco_titulo:
    lw $10, 0($8)              
    bltz $10, fim_titulo      
    bgt $10, 127, fim_titulo  
    lw $11, 4($8)              

    sll $12, $11, 7            
    add $12, $12, $10          
    sll $12, $12, 2            
    lui $13, 0x1001
    add $12, $12, $13          
    sw $9, 0($12)              
   
    addi $8, $8, 8            
    j laco_titulo

fim_titulo:
    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

# ==============================================================================
# VARIÁVEIS DO SISTEMA E MAPA DE SPRITES (LOGO E VITÓRIA)
# ==============================================================================
.data 0x10040000        
.align 2

passaro_x:   .word 12    
passaro_y:   .word 42    
passaro_vx:  .word 0      
passaro_vy:  .word 0      
passaro_st:  .word 0      # 0=Estilingue, 1=Carga, 2=Voo, 3=Vitória
forca_atual: .word 0      # Carga atual (0 a 20)
forca_dir:   .word 1      # Direção da barra de força (1 sobe, -1 desce)

dados_logo:
    # Letras do Título "ANGRY BIRDS" mapeadas em pixel coordenados
    # A
    .word 45,20, 46,20, 44,21, 47,21, 44,22, 45,22, 46,22, 47,22, 44,23, 47,23, 44,24, 47,24
    # N
    .word 49,20, 52,20, 49,21, 50,21, 52,21, 49,22, 51,22, 52,22, 49,23, 52,23, 49,24, 52,24
    # G
    .word 55,20, 56,20, 57,20, 54,21, 54,22, 56,22, 57,22, 54,23, 57,23, 55,24, 56,24, 57,24
    # R
    .word 59,20, 60,20, 61,20, 59,21, 62,21, 59,22, 60,22, 61,22, 59,23, 61,23, 59,24, 62,24
    # Y
    .word 64,20, 67,20, 64,21, 67,21, 65,22, 66,22, 65,23, 65,24
    # B
    .word 46,27, 47,27, 48,27, 46,28, 49,28, 46,29, 47,29, 48,29, 46,30, 49,30, 46,31, 47,31, 48,31
    # I
    .word 51,27, 52,27, 53,27, 52,28, 52,29, 52,30, 51,31, 52,31, 53,31
    # R
    .word 55,27, 56,27, 57,27, 55,28, 58,28, 55,29, 56,29, 57,29, 55,30, 57,30, 55,31, 58,31
    # D
    .word 60,27, 61,27, 62,27, 60,28, 63,28, 60,29, 63,29, 60,30, 63,30, 60,31, 61,31, 62,31
    # S
    .word 66,27, 67,27, 68,27, 65,28, 66,29, 67,29, 68,30, 65,31, 66,31, 67,31
    # Sinalizador de fim do array do logo
    .word -1, -1

dados_vitoria:
    # Letras mapeadas para escrever "VOCE VENCEU!" de forma centralizada
    # V
    .word 30,22, 34,22, 30,23, 34,23, 31,24, 33,24, 31,25, 33,25, 32,26
    # O
    .word 37,22, 38,22, 39,22, 36,23, 40,23, 36,24, 40,24, 36,25, 40,25, 37,26, 38,26, 39,26
    # C
    .word 43,22, 44,22, 45,22, 42,23, 42,24, 42,25, 43,26, 44,26, 45,26
    # E
    .word 47,22, 48,22, 49,22, 47,23, 47,24, 48,24, 47,25, 47,26, 48,26, 49,26
    # Espaço
    # V
    .word 54,22, 58,22, 54,23, 58,23, 55,24, 57,24, 55,25, 57,25, 56,26
    # E
    .word 60,22, 61,22, 62,22, 60,23, 60,24, 61,24, 60,25, 60,26, 61,26, 62,26
    # N
    .word 64,22, 67,22, 64,23, 65,23, 67,23, 64,24, 66,24, 67,24, 64,25, 67,25, 64,26, 67,26
    # C
    .word 70,22, 71,22, 72,22, 69,23, 69,24, 69,25, 70,26, 71,26, 72,26
    # E
    .word 74,22, 75,22, 76,22, 74,23, 74,24, 75,24, 74,25, 74,26, 75,26, 76,26
    # U
    .word 78,22, 81,22, 78,23, 81,23, 78,24, 81,24, 78,25, 81,25, 79,26, 80,26, 81,26
    # !
    .word 83,22, 83,23, 83,24, 83,26
    # Sinalizador de fim do array da vitória
    .word -1, -1
