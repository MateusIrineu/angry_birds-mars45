# Display: 512x256 / Unit: 4x4 / Base: 0x10010000 / (128x64 unidades)

.text
main:
    li $16, 0               # $16 = Deslocamento nuwem
    li $17, 0               # $17 = tela do jogo
    jal render_completo


    # jogo
game_loop:
    lui $8, 0xFFFF          # $8 0xFFFF0000
    lw $9, 0($8)            # $9 verifica se tem tecla pressionada
    andi $9, $9, 1        
    beq $9, $0, aguarda_tecla 
    
    lw $10, 4($8)           #le tecla pressionada 
    bne $10, 32, aguarda_tecla # ignora se a tecla n for espaco
    
    xori $17, $17, 1        # torca a tela
    jal render_completo     # desenha tela nova

aguarda_tecla:
    li $2, 32               # syscall sleep
    li $4, 50               
    syscall

    j game_loop             

# RENDER

render_completo:
    addi $29, $29, -4       
    sw $31, 0($29)

    jal desenha_ceu
    jal desenha_estrelas    
    jal desenha_astro       
    jal desenha_cenario_fundo
    jal desenha_nuvens
    jal desenha_chao
    jal desenha_textura_grama
    jal desenha_textura_terra

    lw $31, 0($29)          
    addi $29, $29, 4
    jr $31


# C�U
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


# ESTRELAS 

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

# MODELOS SOL E LUA

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


# MONTANHA DOS FUNDO
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

# BASE SOLO
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

# TEXTURA GRAMA 
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

# TEXTURA TERRA 
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


# NUVENS
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
