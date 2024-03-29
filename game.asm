;==========================
;	GAME LOGIC
;	 SECTOR 3
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code
[org 0x7e00]

%define BOOT_ADDR 0x07c0	; logical memory address of game sector
%define BOOT_SECTOR 1		; USB sector assigned to game

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
time_left: dw 60        ; timer starting value 
millis_count: dw 0      ; counter to track amount of 10ms (1cs)

; messages
timer_mssg: db 'Time left:', 0	        ; add termination char \0
mov_mssg: db 'Movement keys:', 0	    
keys_mssg: db 'ARROWS, Q, A, E, D', 0	
draw_mssg: db 'Draw mode (SPACE):', 0 
erase_mssg: db 'Erase mode (Z):', 0    
restart_mssg: db 'ESC to restart', 0    
error_mssg: db 'Failed to read sector from USB', 0
game_over_mssg: db `GAME OVER!`, 0 
victory_mssg: db `CONGRATS! YOU WIN!`, 0 

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
        call clear_screen
        
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
            
            .restart_command:
                mov si, restart_mssg    ; text to display
                mov di, 8               ; set row to display text
                call print_str

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
    

    jmp store_pos.store_pos_color

    move_up:
        dec word [playery] ;;mueve una linea arriba de la pantalla
        mov si, COLOR_BLUE
        jmp store_pos
    move_down:
        inc word [playery] ;;mueve una linea abajo de la pantalla
        mov si, COLOR_RED
        jmp store_pos
    move_right:
        inc word [playerx] ;;mueve una linea a la derecha de la pantalla
        mov si, COLOR_ORANGE
        jmp store_pos
    move_left:
        dec word [playerx] ;;mueve una linea a la izquierda de la pantalla
        mov si, COLOR_ORANGE
        jmp store_pos
    move_noe:
        dec word [playerx]
        dec word [playery]
        mov si, COLOR_LGRAY
        jmp store_pos
    move_ne:
        inc word [playerx]
        dec word [playery]
        mov si, COLOR_LBLUE
        jmp store_pos
    move_soe:
        dec word [playerx]
        inc word [playery]
        mov si, COLOR_CYAN
        jmp store_pos
    move_se:
        inc word [playerx]
        inc word [playery]
        mov si, COLOR_PURPLE
        jmp store_pos

    ; get position of the array based on x,y position
    store_pos:
        mov ax, [playerx]       ; get x position
        mov bx, [playery]       ; get y position
        call get_array_pos      ; mov array position in bx
        cmp byte [draw], 1
        je .store_pos_color
        cmp byte [erase], 1
        je .erase_color
        jmp comp_border

        .erase_color:
            mov si, BGCOLOR                  ; set position color to background
        .store_pos_color:
            inc word [path_length]
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

        ; cmp al, 'w'
        ; je victory

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
        no_key:
            mov bl, STAND
            jmp update_direction

    update_direction:
        mov byte [direction], bl ;;se actualiza la dirección 

    delay:              ; wait for 10 ms   
        mov dx, 10000   ; DX = 10000 for 10 milliseconds
        call waits
        inc word [millis_count]         ; increment 10ms counter
        cmp word [millis_count], 95     ; check if 1s passed (estimating that processing time takes 50ms)
        jne game_loop                   ; next iteration
        dec word [time_left]            ; decrement seconds timer
        mov word [millis_count], 0      ; reset 10ms counter

    check_win:
        cmp word [draw], 1
        jne check_game_over
        mov ax, [playerx]       ; get x position
        mov bx, [playery]       ; get y position

        dec bx
        mov cx, bx
        call .check_vertical_up
        jmp check_game_over

        .check_vertical_up:
            ; cmp byte [direction], 0
            ; je check_game_over
            mov bx, cx
            call check_win.matches_original_pos            
            call check_win.check_colored
            cmp bx, 0
            jne .move_right
            ret
            .move_right:
                mov bx, cx
                inc ax
                call check_win.check_colored
                cmp bx, 0
                jne .check_horizontal_right
                dec ax                              ; go back left
                mov bx, cx
                dec bx                              ; move up
                mov cx, bx
                jmp .check_vertical_up
        
        .check_horizontal_right:
            mov bx, cx
            call check_win.matches_original_pos            
            call check_win.check_colored
            cmp bx, 0
            jne .move_down
            ret
            .move_down:
                mov bx, cx
                inc bx
                mov cx, bx
                call check_win.check_colored
                cmp bx, 0
                jne .check_vertical_down
                mov bx, cx
                dec bx                                  ; go back up
                inc ax                                  ; move right
                mov cx, bx
                jmp .check_horizontal_right

        .check_vertical_down:
            mov bx, cx
            call check_win.matches_original_pos            
            call check_win.check_colored
            cmp bx, 0
            jne .move_left
            ret
            .move_left:
                mov bx, cx
                dec ax                                  ; move left
                call check_win.check_colored
                cmp bx, 0
                jne .check_horizontal_left
                inc ax                                  ; go back right
                mov bx, cx
                inc bx                                  ; move down
                mov cx, bx
                jmp .check_vertical_down

        .check_horizontal_left:
            mov bx, cx
            call check_win.matches_original_pos            
            call check_win.check_colored
            cmp bx, 0
            jne .move_up
            ret
            .move_up:
                mov bx, cx
                dec bx
                mov cx, bx                                  ; move up
                call check_win.check_colored
                cmp bx, 0
                jne .check_vertical_up
                mov bx, cx
                inc bx                                  ; move back down
                dec ax                                  ; move left
                mov cx, bx
                jmp .check_horizontal_left

        
        .matches_original_pos:
            cmp [playerx], ax
            jne .return
            cmp [playery], bx
            jne .return
            jmp victory
            .return:
                ret
        
        .check_colored:
            call get_array_pos
            mov bx, [NEW_ARRAY+bx]
            ret


    check_game_over:
        cmp word [time_left], 0 ; check if timer reached zero
        jne game_loop           ; jump to next game loop in case timer hasn't ended
        
        mov ax, 0
        .animation:
            cmp ax, 3               ; max 3 flickering iterations
            je .stop_animation       ; stop animation if reached 3 iterations
            push ax                 ; backup ax counter 
            call clear_screen       ; clear screen
            call wait_one_s         ; delay of 1 second
            mov si, game_over_mssg  ; message to print
            mov bh, COLOR_WHITE     ; color
            xor di, di              ; in line 0
            call print_str          ; print to screen
            call wait_one_s         ; delay of 1 second
            pop ax                  ; restore iterator value
            inc ax                  ; increment in 1
            jmp .animation          ; jump to new iteration
        
        .stop_animation:
            call reset


victory:
    mov ax, 0
    .animation:
        cmp ax, 3               ; max 3 flickering iterations
        je .stop_animation       ; stop animation if reached 3 iterations
        push ax                 ; backup ax counter 
        call clear_screen       ; clear screen
        call wait_one_s         ; delay of 1 second
        mov si, victory_mssg    ; message to print
        mov bh, COLOR_WHITE     ; color
        xor di, di              ; in line 0
        call print_str          ; print to screen
        call wait_one_s         ; delay of 1 second
        pop ax                  ; restore iterator value
        inc ax                  ; increment in 1
        jmp .animation          ; jump to new iteration
    
    .stop_animation:
        call reset


; procedure to get index of positions array
; params:
;   ax -> x
;   bx -> y
; returns: bx -> index
get_array_pos:
    imul bx, bx, SCREENW    
    add bx, ax              
    imul bx,2               ; get linear position. store in bx
    ret

clear_screen:          ; sets background color to every position
    xor ax,ax           ; reset ax register
    mov ax, BGCOLOR
    xor di, di
    mov cx, SCREENW*SCREENH ; sets window dimensions    
    rep stosw ; writes AX register color at DI register direction. Repeats this instruction the times defined by CX
    ret

; procedure to wait
; params:
;   dx -> microseconds
waits:
    mov ah, 0x86    ; AH = 0x86 for the BIOS wait
    mov cx, 0       ; CX is the high word of the delay time in microseconds
    int 0x15        ; INTERRUPTION: BIOS wait function
    ret

wait_one_s:
    mov ah, 0x86    ; AH = 0x86 for the BIOS wait
    mov cx, 0x000F  ; CX is the high word of the delay time in microseconds
    mov dx, 0x4240  ; DX is the lower word of the delay time in microseconds
    int 0x15        ; INTERRUPTION: BIOS wait function
    ret


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

; procedure to jump back to bootloader sector
reset:
	mov ax, BOOT_ADDR	; logical address of new sector
	mov es, ax              ; point EXTRA SEGMENT register to logical address
	mov bx, 0               ; offset = 0
	mov cl, BOOT_SECTOR		; specify sector from USB flash
    mov al, 1               ; how many sectors to read
	call read_sector
	jmp BOOT_ADDR:0x0000

; procedure to read sector(s) from USB flash drive
; params:
;	al -> contains the number of sectors to read
;	cl -> contains sector to read (1...18)
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
        mov bh, COLOR_WHITE ; set color
        mov di, 0
        call print_str              ; print error message
        jmp $                   ; processor holt (infinite loop)

times 1536 - ($ - $$) db 0       ; fill trailing zeros to get exactly 1536 bytes long binary file (3 disk sectors)
