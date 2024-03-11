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
delete: dw 0 		    ; deleting flag
error_mssg: db 'Failed to read sector from USB', 10, 13, 0	; add \n (newline) before \0

setup_game:
    .set_video_mode:
        mov ax, 003h    ; code for text mode: 80x25. 16 colors. 8 pages. 
        int 10h         ; INTERRUPTION: set video mode

    .init_positions_array:
        mov cx, SCREENW*SCREENH ; 1919h (?)
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
            div cx			; (DX/AX) / CX; AX = quotient, DX = remainder (0-79) 
            mov word [playerx], dx

    .set_random_y:
        xor ah, ah
            int 1Ah			; Timer ticks since midnight in CX:DX
            mov ax, dx		; Lower half of timer ticks
            xor dx, dx		; Clear out upper half of dividend
            mov cx, SCREENH
            div cx			; (DX/AX) / CX; AX = quotient, DX = remainder (0-24) 
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
        cmp byte [delete], 1
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
        
        xor ah,ah
        int 16h ; INTERRUPTION: get keystroke from keyboard (no echo), AH = BIOS scan code and AL = ASCII char

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
        je delete_interface
        
        cmp al, ESC_KEY
        je execute_shell

        jmp no_key

        jmp update_direction

        delete_interface:
            cmp byte [delete],0
            je .is_deleting
            dec byte [delete]
            jmp no_key
            .is_deleting:
                inc byte [delete]
                mov byte [draw],0
                jmp no_key
        draw_interface:
            cmp byte [draw],0
            je .act_draw
            dec byte [draw]
            jmp no_key
            .act_draw:
                inc byte [draw]
                mov byte [delete],0
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


jmp game_loop



; procedure to read sector(s) from USB flash drive
; params:
;	al -> contains the number of sectors to read
read_sector:
        mov ah, 0x02            ; BIOS code to read from storage device
        mov ch, 0               ; specify cilinder
        mov dh, 0               ; specify head
        mov dl, 0x80            ; specify HDD code
        int 0x13                ; INTERRUPTION: read the sector from USB flash drive into memory
        jc .error               ; if failed to read sector, jump to error procedure
        ret                     ; return from procedure

        .error:
                mov si, error_mssg      ; point SOURCE INDEX register to error message string's address
                call print              ; print error message
                jmp $                   ; processor holt (infinite loop)

; procedure to execute boot sector that contains shell
execute_shell:
	mov ax, SHELL_ADDR	; logical address of new sector
	mov es, ax              ; point EXTRA SEGMENT register to logical address
	mov bx, 0               ; offset = 0
	mov cl, SHELL_SECTOR	; specify sector from USB flash
    mov al, 1               ; how many sectors to read
	call read_sector
	jmp SHELL_ADDR:0x0000

; procedure to print a string
print:                          
        cld                     ; clear DIRECTION FLAG
        mov ah, 0x0e            ; enable teletype output for INT 0X10 interruption

        .next_char:             ; print next char
                lodsb           ; read next byte from si(SOURCE INDEX) register
                cmp al, 0       ; checks if zero terminating char of the string is reached
                je .return      ; return if string doesn't contain any more characters
                int 0x10        ; INTERRUPTION: prints char in al register. ax register should be 0x0e
                jmp .next_char

        .return: ret            ; return from procedure


times 1024 - ($ - $$) db 0       ; fill trailing zeros to get exactly 1024 bytes long binary file (2 disk sectors)
