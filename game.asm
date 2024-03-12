;==========================
;	GAME LOGIC
;	 SECTOR 3
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code
[org 0x8000]

jmp setup_game

; CONSTANTS
VIDEO_MEM equ 0B800h
SCREENW equ 80
SCREENH equ 25
WINCOND equ 10
TIMER equ 046Ch

SHELL_ADDR equ 07e0h    ; logical memory address of shell boot sector
SHELL_SECTOR equ 2      ; USB sector assigned to shell

; colors
BGCOLOR equ 0h
COLOR_WHITE equ 0Fh
COLOR_BLUE equ 1020h
COLOR_GREEN equ 2020h
COLOR_CYAN equ 3020h
COLOR_RED  equ 4020h
COLOR_PURPLE equ 5020h
COLOR_ORANGE equ 6020h
COLOR_LGRAY equ 7020h
COLOR_GRAY equ 8020h
COLOR_LBLUE equ 9020h

; ASCII codes
ESC_KEY equ 1Bh
UP_ARROW equ 48h
DOWN_ARROW equ 50h
RIGHT_ARROW equ 4Dh
LEFT_ARROW equ 4Bh

; positions array address 
NEW_ARRAY equ 1000h

; directions map
UP equ 0
DOWN equ 1
LEFT equ 2
RIGHT equ 3
STAND equ 4
NOE equ 5
NE equ 6
SOE equ 7
SE equ 8

; VARIABLES
playerx: dw 40
playery: dw 12
direction: db 4 	    ; init movement direction to STAND 
path_length: dw 1
draw: dw 1 		        ; drawing flag
erase: dw 0 		    ; deleting flag
time_left: dw 60        ; timer 
millis_count: dw 0      ; counter to track amount of 10ms (1cs)

; messages
timer_mssg: db 'Time left:', 0	        ; add termination char \0
mov_mssg: db 'Movement keys:', 0	        ; add termination char \0
keys_mssg: db 'ARROWS, Q, A, E, D', 0	; add termination char \0
draw_mssg: db 'Draw mode (SPACE):', 0 ; add termination char \0
erase_mssg: db 'Erase mode (Z):', 0    ; add termination char \0

setup_game:
    .set_video_mode:
        mov ax, 003h    ; code for text mode: 80x25. 16 colors. 8 pages. 
        int 10h         ; INTERRUPTION: set video mode

    .init_positions_array:
        mov cx, SCREENW*SCREENH
        xor bx,bx
        fill_zeros:
            mov word [NEW_ARRAY+bx], 0h
            inc bx
            inc bx
            loop fill_zeros

    .set_random_x:
        xor ah, ah
            int 1Ah			; Timer ticks since midnight in CX:DX
            mov ax, dx		; Lower half of timer ticks
            xor dx, dx		; Clear out upper half of dividend
            mov cx, SCREENW
            div cx			; (DX:AX) / CX; AX = quotient, DX = remainder (0-79) 
            mov word [playerx], dx

    .set_random_y:
        xor ah, ah
            int 1Ah			; Timer ticks since midnight in CX:DX
            mov ax, dx		; Lower half of timer ticks
            xor dx, dx		; Clear out upper half of dividend
            mov cx, SCREENH
            div cx			; (DX:AX) / CX; AX = quotient, DX = remainder (0-24) 
            mov word [playery], dx

    .set_video_mem:
        mov ax, VIDEO_MEM
        mov es, ax ;;ES:DI <- b800:000 point to video memory address

game_loop:

    paint_screen:               ; paint screen paths and turtle every iteration
        .clear_screen:          ; sets background color to every position
            xor ax,ax           ; reset ax register
            mov ax, BGCOLOR
            xor di, di
            mov cx, SCREENW*SCREENH ; sets window dimensions    
            rep stosw ; writes AX register color at DI register direction. Repeats this instruction the times defined by CX
        
        .paint_dashboard:
            .modes:
                mov bh, COLOR_WHITE ; set color
                mov si, draw_mssg   ; text to display
                mov di, 0           ; set row to display text
                call print_str
                mov bl, [draw]
                call print_int      ; print current draw status

                mov si, erase_mssg  ; text to display
                mov di, 1           ; set row to display text
                call print_str
                mov bl, [erase]
                call print_int      ; print current erase status

            .movement_keys:
                mov si, mov_mssg    ; text to display
                mov di, 3           ; set row to display text
                call print_str

                mov si, keys_mssg   ; text to display
                mov di, 4           ; set row to display text
                call print_str

            .timer:
                mov si, timer_mssg  ; text to display
                mov di, 6           ; set row to display text
                call print_str

                xor dx, dx                      ; reset upper part of dividend
                mov ax, [time_left]             ; set lower part of dividen
                mov bx, 10                      ; set divisor
                div bx                          ; (DX:AX) / CX; AX = quotient, DX = remainder 

                mov bh, COLOR_WHITE ; set color
                mov bl, al          ; move quotinet to BL
                call print_int      ; print tens of time left
                mov bl, dl          ; move remainder to BL
                call print_int      ; print units of time left

        .paint_paths:
            xor bx,bx
            xor bl,bl
            mov cx, SCREENH ;Repite el bucle con el alto de la pantalla 
            mov di, 0h
            .turtle_loop_y:
                mov dx, 0h
                .turtle_loop_x:
                    mov bp, dx ;almaceno el valor del x para no perderlo 
                    imul dx, 2 ; esto es necesario para poder pintar en la posicion en x correcta
                    mov ax,[NEW_ARRAY+bx] ;;Toma el color de la posicion
                    mov si, di ; guarda el valor del di en si para no perderlo 
                    imul di, SCREENW*2 ; esto es necesario para pintar en la posición en y correcta
                    cmp ax, 0h ; si encuentra un 0 en el array no dibuja nada 
                    je .salto
                    add di, dx
                    stosw 
                    .salto:
                    mov dx, bp
                    add bx,2 ; incrementa el indice
                    inc dx ; incrementa en x
                    mov di, si ; regresa el valor del di
                    cmp dx, SCREENW ; compara si ya llegó al final de la fila
                    jne .turtle_loop_x ; sino repite el loop
                inc di
            loop .turtle_loop_y
        
        .draw_turtle:
            ;;Dibuja la cabeza de la tortuga siempre
            imul di, [playery], SCREENW*2
            imul dx, [playerx], 2
            add di, dx
            mov ax, COLOR_GREEN
            stosw


    ;;Mover
    mov al, [direction] ;; aqui se guarda la direccion del input 
    cmp al, UP
    je move_up
    cmp al, DOWN
    je move_down
    cmp al, RIGHT
    je move_right
    cmp al, LEFT
    je move_left
    cmp al, NOE
    je move_noe
    cmp al, NE
    je move_ne
    cmp al, SOE
    je move_soe
    cmp al, SE
    je move_se
    cmp al, STAND
    je get_player_input
    

    jmp calc_pos.store_pos_color

    move_up:
        dec word [playery] ;;mueve una linea arriba de la pantalla
        mov si, COLOR_BLUE
        jmp calc_pos
    move_down:
        inc word [playery] ;;mueve una linea abajo de la pantalla
        mov si, COLOR_RED
        jmp calc_pos
    move_right:
        inc word [playerx] ;;mueve una linea a la derecha de la pantalla
        mov si, COLOR_CYAN
        jmp calc_pos
    move_left:
        dec word [playerx] ;;mueve una linea a la izquierda de la pantalla
        mov si, COLOR_GRAY
        jmp calc_pos
    move_noe:
        dec word [playerx]
        dec word [playery]
        mov si, COLOR_LGRAY
        jmp calc_pos
    move_ne:
        inc word [playerx]
        dec word [playery]
        mov si, COLOR_LBLUE
        jmp calc_pos
    move_soe:
        dec word [playerx]
        inc word [playery]
        mov si, COLOR_ORANGE
        jmp calc_pos
    move_se:
        inc word [playerx]
        inc word [playery]
        mov si, COLOR_PURPLE
        jmp calc_pos
    ;;Actualiza la posicion de la tortuga

;;calcular la posicion del array
    calc_pos:
        mov ax, [playerx]
        mov bx, [playery]
        imul bx, bx, SCREENW
        add bx, ax 
        cmp byte [draw], 1
        je .store_pos_color
        cmp byte [erase], 1
        je .erase_color
        jmp comp_border

        .erase_color:
            mov si, BGCOLOR                  ; set position color to background
        .store_pos_color:
            inc word [path_length]
            imul bx,2
            mov word [NEW_ARRAY+bx], si
            jmp comp_border


    ;; Cmpara si toca los bordes de la pantalla
    comp_border:
        cmp word [playery], -1
        je stop_up
        cmp word [playery], SCREENH
        je stop_down
        cmp word [playerx], -1
        je stop_left
        cmp word [playerx], SCREENW
        je stop_right
        jmp get_player_input
        ;; Condicion de ganar 
        stop_up:
            inc word [playery]
            jmp get_player_input
        stop_down:
            dec word [playery]
            jmp get_player_input
        stop_left:
            inc word [playerx]
            jmp get_player_input
        stop_right:
            dec word [playerx]
            jmp get_player_input


    get_player_input:
        mov bl, [direction] ;; guarda la dirección actual

        mov ah, 1
        int 16h     ; INTERRUPTION: check if keystroke is present in buffer. ZF = 1 if keystroke is not available. ZF = 0 if keystroke available.         

        jz no_key   ; no_key procedure if no keystroke

        xor ah, ah
        int 16h     ; INTERRUPTION: get keystroke from keyboard (no echo), AH = BIOS scan code and AL = ASCII char

        cmp ah, UP_ARROW
        je up_pressed
        
        cmp ah, DOWN_ARROW
        je down_pressed
        
        cmp ah, RIGHT_ARROW
        je right_pressed
        
        cmp ah, LEFT_ARROW
        je left_pressed
        
        cmp al, 'q'
        je q_pressed
        
        cmp al, 'e'
        je e_pressed
        
        cmp al, 'd'
        je d_pressed
        
        cmp al, 'a'
        je a_pressed
        
        cmp al, ' '
        je draw_interface
        
        cmp al, 'z'
        je erase_interface
        
        cmp al, ESC_KEY
        je reset

        jmp update_direction

        erase_interface:
            cmp byte [erase],0
            je .is_deleting
            dec byte [erase]
            jmp no_key
            .is_deleting:
                inc byte [erase]
                mov byte [draw],0
                jmp no_key
        draw_interface:
            cmp byte [draw],0
            je .act_draw
            dec byte [draw]
            jmp no_key
            .act_draw:
                inc byte [draw]
                mov byte [erase],0
                jmp no_key
        up_pressed:
            mov bl, UP
            jmp update_direction
        down_pressed:
            mov bl, DOWN
            jmp update_direction
        right_pressed:
            mov bl, RIGHT
            jmp update_direction
        left_pressed:
            mov bl, LEFT
            jmp update_direction
        q_pressed:
            mov bl, NOE
            jmp update_direction
        e_pressed:
            mov bl, NE
            jmp update_direction
        a_pressed:
            mov bl, SOE
            jmp update_direction
        d_pressed:
            mov bl, SE
            jmp update_direction
        reset:
            int 19h     ; INTERRUPTION: system reboot
        no_key:
            mov bl, STAND
            jmp update_direction

    update_direction:
        mov byte [direction], bl ;;se actualiza la dirección 

    .wait:              ; wait for 10 ms   
        mov ah, 0x86    ; AH = 0x86 for the BIOS wait function
        mov cx, 0       ; CX is the high word of the delay time in microseconds
        mov dx, 10000   ; DX = 10000 for 10 milliseconds
        int 0x15        ; INTERRUPTION: BIOS wait function
        inc word [millis_count]         ; increment 10ms counter
        cmp word [millis_count], 95     ; check if 1s passed (estimating that processing time takes 50ms)
        jne game_loop                   ; next iteration
        dec word [time_left]            ; decrement seconds timer
        mov word [millis_count], 0      ; reset 10ms counter

    check_win:

    check_game_over:
        cmp word [time_left], 0 ; check if timer reached zero
        jne game_loop           ; jump to next game loop in case timer hasn't ended
        .game_over_animation:
            int 19h             ; INTERRUPTION: system reboot


; procedure to print a string
; params:
;   si -> pointer to string array
;   bh -> color
;   di -> row number to print string
print_str:
        imul di, di, SCREENW*2    ; set row where string will be printed
        .next_char:             ; print next char
                lodsb           ; read next byte from si(SOURCE INDEX) register
                cmp al, 0       ; checks if zero terminating char of the string is reached
                je .return      ; return if string doesn't contain any more characters
                mov bl, al      ; set char to be printed
                mov [es:di], bx ; print char in given color
                add di, 2   ; move pointer to next position on screen
                jmp .next_char

        .return: ret            ; return from procedure

; procedure to print a single number
; params:
;   bh -> color
;   bl -> number
print_int:
        add di, 2       ; move to next position in screen
        add bl, 30h     ; ASCII code of number
        mov [es:di], bx ; print char in given color
        ret             ; return from procedure

times 1024 - ($ - $$) db 0       ; fill trailing zeros to get exactly 1024 bytes long binary file (2 disk sectors)
