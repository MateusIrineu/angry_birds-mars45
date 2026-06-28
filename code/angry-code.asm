# ==============================================================================
# JOGO ANGRY BIRDS: SISTEMA DE DIA E NOITE + TELA INICIAL COM LOGO + NPCs
# Display: 512x256 | Unit: 4x4 | Base: 0x10010000 | (128x64 unidades)
# ==============================================================================

.text
main:
    li $16, 0               # $16 = Deslocamento X das nuvens (Carrossel)
    li $17, 0               # $17 = Fase do Jogo (0 = Dia, 1 = Noite)

    # ==========================================================================
    # TELA INICIAL (ESTÁTICA)
    # ==========================================================================
tela_inicial:
    # 1. Desenha o cenário inicial de DIA (estático)
    jal desenha_ceu
    jal desenha_astro       
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra
    
    # === NOVO: Desenha os NPCs na Tela Inicial ===
    jal desenha_passaro
    jal desenha_porco
    # ============================================
    
    jal desenha_titulo      # Desenha a Pixel Art do Logo

aguarda_inicio:
    # 2. Fica em loop infinito esperando a tecla Espaço ser pressionada
    lui $8, 0xFFFF          
    lw $9, 0($8)            
    andi $9, $9, 1        
    beq $9, $0, aguarda_inicio 
    
    lw $10, 4($8)           
    bne $10, 32, aguarda_inicio 
    
    # 3. Espaço pressionado! Pausa (debounce) para não trocar a fase na mesma hora
    li $2, 32               
    li $4, 250              
    syscall

    # ==========================================================================
    # GAME LOOP PRINCIPAL (ANIMAÇÕES)
    # ==========================================================================
game_loop:
    # 1. VERIFICA ENTRADA DO TECLADO
    lui $8, 0xFFFF          
    lw $9, 0($8)            
    andi $9, $9, 1        
    beq $9, $0, render_frame
    
    lw $10, 4($8)           
    bne $10, 32, render_frame
    
    xori $17, $17, 1        # Inverte a fase com a tecla Espaço

render_frame:
    # 2. ATUALIZA ANIMAÇÕES
    addi $16, $16, 1        
    andi $16, $16, 127      

    # 3. CHAMA AS ROTINAS DE DESENHO
    jal desenha_ceu
    jal desenha_estrelas    
    jal desenha_astro       
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra
    
    # === NOVO: Desenha os NPCs no Game Loop ===
    jal desenha_passaro
    jal desenha_porco
    # ==========================================

    # 4. CONTROLE DE VELOCIDADE (FPS)
    li $2, 32               
    li $4, 50               
    syscall

    j game_loop             

# ==============================================================================
# 1. CÉU
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

# ==============================================================================
# 2. ESTRELAS ESTÁTICAS
# ==============================================================================
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

# ==============================================================================
# 3. O ASTRO
# ==============================================================================
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

# ==============================================================================
# 4. MONTANHAS NO FUNDO
# ==============================================================================
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

# ==============================================================================
# 5. CHÃO BASE
# ==============================================================================
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

# ==============================================================================
# 6. TEXTURA DA GRAMA
# ==============================================================================
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

# ==============================================================================
# 7. TEXTURA DA TERRA 
# ==============================================================================
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

# ==============================================================================
# 8. NUVENS E CARROSSEL
# ==============================================================================
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

# ==============================================================================
# 9. TÍTULO NA TELA INICIAL
# ==============================================================================
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
# 10. DESENHO DOS NPCS (PÁSSARO E PORCO)
# ==============================================================================
desenha_passaro:
    addi $29, $29, -4
    sw $31, 0($29)
    
    li $4, 12           # X inicial
    li $5, 42           # Y inicial (encostado no chao, Y do chao = 48)
    li $6, 17           # X final (largura = 6 pixels)
    li $7, 47           # Y final (altura = 6 pixels)
    li $9, 0x00E32636   # Cor: Vermelho (Alizarin Crimson)
    jal desenha_npc_generico

    # Opcional: Desenha um pixel branco para o olho
    li $10, 44          # Y = 44
    li $11, 15          # X = 15
    li $9, 0x00FFFFFF   # Branco
    jal pinta_pixel_direto

    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

desenha_porco:
    addi $29, $29, -4
    sw $31, 0($29)
    
    li $4, 105          # X inicial (Canto direito)
    li $5, 42           # Y inicial
    li $6, 110          # X final
    li $7, 47           # Y final
    li $9, 0x0055A630   # Cor: Verde Porco
    jal desenha_npc_generico
    
    # Opcional: Desenha os olhos do porco
    li $10, 44
    li $11, 106
    li $9, 0x00000000   # Preto
    jal pinta_pixel_direto
    
    li $10, 44
    li $11, 109
    li $9, 0x00000000   # Preto
    jal pinta_pixel_direto

    lw $31, 0($29)
    addi $29, $29, 4
    jr $31

desenha_npc_generico:
    # Retângulo sólido simples preenchido
    # $4 = X init, $5 = Y init, $6 = X end, $7 = Y end, $9 = Cor
    move $10, $5              # $10 = Y atual
npc_laco_y:
    move $11, $4              # $11 = X atual
npc_laco_x:
    sll $12, $10, 7           # $12 = Y * 128
    add $12, $12, $11         # $12 = (Y * 128) + X
    sll $12, $12, 2           # Multiplica por 4 (tamanho da word)
    lui $13, 0x1001           # Base da memória de vídeo
    add $12, $12, $13         # Soma o endereço base
    sw $9, 0($12)             # Pinta o pixel
    
    addi $11, $11, 1          # Próximo X
    ble $11, $6, npc_laco_x
    
    addi $10, $10, 1          # Próximo Y
    ble $10, $7, npc_laco_y
    jr $31

# ==============================================================================
# SEÇÃO DE DADOS (COORDENADAS DO TEXTO)
# ==============================================================================
.data 0x10040000        
.align 2
dados_logo:
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
    # Condição de Parada
    .word -1, -1
