;==========================
;	SHELL LOGIC
;	 SECTOR 2
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code
[org 0x7e00]			; set base address for sector 2

%define GAME_ADDR 0x0800        ; logical memory address of game boot sector
%define GAME_SECTOR 3           ; USB sector assigned to game

%define ENTER_KEY 0x1c		; ENTER ASCII code
%define BACKSPACE_KEY 0x0e	; BACKSPACE ASCII code

jmp short start

; text variables
intro_mssg: db 'Welcome to MicromundOS.', 10, 13,'Type "start" to play the game: ', 0	
error_mssg: db 'Failed to read sector from USB', 10, 13, 0	; add \n (newline) before \0

user_prompt: db 10, 13, ' > ', 0		; prefix for user input
user_input: times 20 db 0			; buffer to store user input

start_str: db 'start', 0		; input required to start game

start:
	mov ax, 0               ; init data registers, set ACCUMULATOR REGISTER to 0
	mov ds, ax              ; ds = DATA SEGMENT register
	mov es, ax              ; es = EXTRA SEGMENT register

	call clear_screen
	
	mov si, intro_mssg	; point SOURCE INDEX register to intro message string's address
	call print              ; print message to screen

shell_loop:
	mov si, user_prompt	; point SOURCE INDEX register to $ symbol string
	call print		; print to screen
	
	mov di, user_input	; point DESTINATION INDEX register to user_input variable address
	mov al, 0		; AL is used by stosb (store single byte ) instruction
	times 20 stosb		; store 20 zero bytes at DI and then increment DI
	mov di, user_input	; point DESTINATION INDEX register to user_input variable address

	.next_byte:
		mov ah, 0x00	; BIOS scan code
		int 0x16	; INTERRUPTION: get keystroke from keyboard (no echo)

		cmp ah, ENTER_KEY
		je .enter_char	; if ENTER key has been pressed, check if command matches with code
	
		cmp ah, BACKSPACE_KEY
		je .erase_char	

		stosb		; store key that has been pressed into user_input variable
		
		mov ah, 0x0e	; BIOS code for char outpout
		int 0x10	; INTERRUPTION: echo char that has been typed
		
		jmp .next_byte 

	.enter_char:
		call string_match	; compare user input with 'start' string
		cmp cl, 0		; if string does not match with 'start'
		je shell_loop 		; jump back to shell loop
		call execute_game	; start game

	.erase_char:
		mov ah, 0x03            ; BIOS code to get cursor position
		int 0x10                ; INTERRUPTION: get cursor position
		cmp dl, 3               ; cursor too far to the left?
		je .next_byte           ; if so process next byte

		mov ah, 0x0e            ; BIOS code for char output
		mov al, 8               ; ASCII code for '\b'
		int 0x10                ; INTERRUPTION: move cursor one step back
		mov ah, 0x0e            ; BIOS code for char output

		mov al, 0               ; ASCII code for empty char
		int 0x10                ; INTERRUPTION: echo empty char

		mov ah, 0x0e            ; BIOS code for char output
		mov al, 8               ; ASCII code for '\b'
		int 0x10                ; INTERRUPTION: move cursor one step back

		mov al, 0               ; AL is used by stosb instruction
		dec di,                 ; drop user input pointer one position back
		stosb                   ; replace whatever is there with 0
		dec di                  ; drop user input pointer one position back

		jmp .next_byte          ; process next byte		

	jmp shell_loop		; infinite loop

clear_screen:
	mov ah, 0x00  		; required to set video mode
	mov al, 0x03		; video mode as text type
	int 0x10		; INTERRUPTION: set video mode. Used to clear screen 
	ret

; procedure to compare user input with 'start' text
string_match:
	cld                             ; clear direction flag so that SI and DI gets incremented after SCASB/LODSB
	mov di, user_input              ; point DI to the target string
	mov si, start_str	        ; point SI to the source string

	.next_byte:
		lodsb                   ; init AX equals to the value of where SI is pointing at
		scasb                   ; compare the value of where DI is poining at with the value stored in AX
		jne .return_false       ; return false if chars do not match
		cmp al, 0               ; check if reached the zero terminating char
		je .return_true         ; string match each other
		jmp .next_byte          ; process next byte

	.return_true:
		mov cl, 1		; save true value in cl register
		ret

	.return_false:
	        mov cl, 0		; save false value in cl register
	        ret

; procedure to execute boot sector game
execute_game:
	mov ax, GAME_ADDR	; logical address of new sector
	mov es, ax              ; point EXTRA SEGMENT register to logical address
	mov bx, 0               ; offset = 0
	mov cl, GAME_SECTOR	; specify sector from USB flash
    mov al, 2               ; how many sectors to read
	call read_sector
	jmp GAME_ADDR:0x0000

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



times 512 - ($ - $$) db 0       ; fill trailing zeros to get exactly 512 bytes long binary file
