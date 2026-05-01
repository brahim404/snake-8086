org 100h
jmp start

; --- DONNÉES ---
snake_x db 40, 39, 38, 37
times 100 db 0

snake_y db 12, 12, 12, 12
times 100 db 0

food_x db 0
food_y db 0
length db 4
dir db 1
score db 0
game_over_msg db 'GAME OVER!', 13, 10, '$'
start:
    mov ax, 0013h
    int 10h
    call spawn_food
main_loop:
    call input
    call update
    call draw
    call delay
    call draw_score
    jmp main_loop

; --- SAISIE CLAVIER ---
input:
    mov ah, 01h
    int 16h
    jz no_key

    mov ah, 00h
    int 16h

    cmp al, 1Bh
    je exit_game

    cmp ah, 4Dh
    je set_right

    cmp ah, 4Bh
    je set_left
    cmp ah, 48h
    je set_up
    cmp ah, 50h
    je set_down
    ret

exit_game:
    MOV AX, 0003H
    INT 10H
    
    XOR AX, AX
    XOR DX, DX
    MOV DX, game_over_msg
    MOV AH, 09H
    int 21H
    mov ax, 4C00h
    int 21h
    set_right:
    cmp byte [dir], 2
    je no_key
    mov byte [dir], 1
    ret

set_left:
    cmp byte [dir], 1
    je no_key
    mov byte [dir], 2
    ret

set_up:
    cmp byte [dir], 4
    je no_key
    mov byte [dir], 3
    ret

set_down:
    cmp byte [dir], 3
    je no_key
    mov byte [dir], 4
    ret

no_key:
ret

; --- MISE À JOUR POSITION ---
update:

    mov cl, byte [length]
    xor ch, ch
    dec cx
    jz update_head
    mov si, cx

shift_loop:
    mov di, si
    dec di
    mov al, [snake_x + di]
    mov [snake_x + si], al
    mov al, [snake_y + di]
    mov [snake_y + si], al
    dec si
    jnz shift_loop

update_head:
    mov al, [dir]
    cmp al, 1
    je move_r
    cmp al, 2
    je move_l
    cmp al, 3
    je move_u
    cmp al, 4
    je move_d
    ret

move_r:
    inc byte [snake_x]
    jmp check_boundaries

move_l:
    dec byte [snake_x]
    jmp check_boundaries

move_u:
    dec byte [snake_y]
    jmp check_boundaries

move_d:
    inc byte [snake_y]
    jmp check_boundaries
    
check_boundaries:
    ; top
    CMP byte [snake_y], 8
    JB exit_game
    
    ;bottom
    CMP byte [snake_y], 200
    JAE exit_game
    
    ;droite
    CMP byte [snake_x], 250
    JAE exit_game
    
    ;gauche
    ; check droite suffit (255 > 250)

self_collision:
    MOV SI, 1
    XOR CX, CX
    MOV CL, [length]
    DEC CX
    JZ skip_self
    
    MOV BL, [snake_x]
    MOV BH, [snake_y]
    l1:
    CMP BL, [snake_x+SI]
    JNE not_equal
    CMP BH, [snake_y+SI]
    JNE not_equal
    JMP exit_game
    not_equal:
    INC SI
    LOOP l1
skip_self:
    
    
check_food:               ; verif si snake rencontre une pomme
    MOV AL, [food_x]
    CMP AL, [snake_x]
    JNE no_eat
    MOV AL, [food_y]
    CMP AL, [snake_y]
    JNE no_eat
    
eat:
    INC byte [length]
    INC byte [score]
    CALL spawn_food
    
no_eat:    
    ret

; --- AFFICHAGE ---
draw:
    mov ax, 0A000h             ; 320 * 8 = 2560
    mov es, ax
    MOV DI, 2560  ; skip les 8 premieres lignes
    mov cx, 61440 ; 64000 total - 2560 = 61440
    xor al, al
    rep stosb
    
    draw_walls:
    MOV DI, 2560
    MOV CX, 250
    draw_top:
    MOV byte [ES:DI], 7
    INC DI
    LOOP draw_top
    
    MOV DI, 63680
    MOV CX, 251
    draw_bottom:
    MOV byte [ES:DI], 7
    INC DI
    LOOP draw_bottom
    
    MOV DI, 2560
    MOV CX, 191
    draw_left:
    MOV byte [ES:DI], 7
    ADD DI, 320
    LOOP draw_left
    
    MOV DI, 2810
    MOV CX, 191
    draw_right:
    MOV byte [ES:DI], 7
    ADD DI, 320
    LOOP draw_right
    
    mov cl, byte [length]
    xor ch, ch
    xor si, si

draw_loop:
    ; Calcul offset = y * 320 + x
    mov al, [snake_y + si]
    xor ah, ah
    mov bx, 320
    mul bx
    mov bx, ax
    mov al, [snake_x + si]
    xor ah, ah
    add bx, ax
    mov di, bx
    mov byte [es:di], 10 ; Couleur verte
    inc si
    dec cx
    jnz draw_loop
    
    MOV AL, [food_y]
    XOR AH, AH
    MOV BX, 320
    MUL BX
    MOV BX, AX
    MOV AL, [food_x]
    XOR AH, AH
    ADD BX, AX
    MOV DI, BX
    MOV byte [ES:DI], 5
    MOV byte [ES:DI+1], 4
    MOV byte [ES:DI-1], 4         ; 3x3 pomme
    MOV byte [ES:DI+320], 4
    MOV byte [ES:DI+321], 4
    MOV byte [ES:DI+319], 4
    
    MOV byte [ES:DI-320], 4
    MOV byte [ES:DI-321], 4
    MOV byte [ES:DI-319], 4
    
    
    
    ret

; --- TEMPORISATION ---
delay:
    push cx
    mov cx, 0FFFFh
    d1:
    loop d1
    pop cx
    ret
      
; --- SYSTEME DE NOURRITURE ---
spawn_food:
    MOV AH, 00H     ; coordonnes x random
    INT 1AH         ; timer -> DX
    MOV AX, DX
    XOR DX, DX
    MOV BX, 250
    DIV BX
    MOV [food_x], DL
    
    IN AL, 40H      ; coordonnees y random
    MOV AH, 0       ; on utilise PIT pour le generer
    XOR DX, DX
    MOV BX, 182
    DIV BX
    ADD DL, 8    ; shift de 8 pixels
    MOV [food_y], DL
    
    ret 
    
; --- AFFICHAGE SCORE ---

draw_score:
    MOV AH, 02H
    MOV BH, 0
    MOV DH, 0    ;ligne 0
    MOV DL, 0    ;col   0
    INT 10H
    
    MOV AL, [score]
    MOV BL, 10
    XOR CX, CX
    
extract_loop:
    XOR AH, AH
    DIV BL
    
    MOV DL, AH
    PUSH DX     ; stack pour inverser l'ordre d'affichage
    INC CX      ; compteur pour print_loop
    
    CMP AL, 0
    JNE extract_loop

print_loop:
    POP DX
    MOV AL, DL
    ADD AL, 30H   ; conversion ASCII
    MOV AH, 0EH    
    INT 10H       ; print charactere    
    LOOP print_loop
    
    ret