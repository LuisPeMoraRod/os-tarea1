;==========================
;	SHELL LOGIC
;	 SECTOR 2
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code
[org 0x7e00]			; set base address for sector 2

start:
	mov ax, 0               ; init data registers, set ACCUMULATOR REGISTER to 0
        mov ds, ax              ; ds = DATA SEGMENT register
        mov es, ax              ; es = EXTRA SEGMENT register
	
	mov si, hello_mssg	; point SOURCE INDEX register to success message string's address
        call print              ; print message to screen
	jmp $

print:                          ; procedure to print a string
        cld                     ; clear DIRECTION FLAG
        mov ah, 0x0e            ; enable teletype output for INT 0X10 interruption

        .next_char:             ; print next char
                lodsb           ; read next byte from si(SOURCE INDEX) register
                cmp al, 0       ; checks if zero terminating char of the string is reached
                je .return      ; return if string doesn't contain any more characters
                int 0x10        ; INTERRUPTION: prints char in al register. ax register should be 0x0e
                jmp .next_char

        .return: ret            ; return from procedure

hello_mssg db 'Hello from SHELL', 10, 13, 0

times 512 - ($ - $$) db 0       ; fill trailing zeros to get exactly 512 bytes long binary file
