;=======================
;     Bootloader
;=======================

[bits 16]	; tell NASM to assemble 16-bit code to save space
[org 0x7c00]	; tell NASM the code is running at boot sector
jmp short start

start:
	mov ax, 0		; init data registers, set ACCUMULATOR REGISTER to 0
	mov ds, ax		; ds = DATA SEGMENT register
	mov es, ax		; es = EXTRE SEGMENT register

	mov si, success_mssg	; point SOURCE INDEX register to success message string's address
	call print		; print message to screen

	mov bx, 0x7e00		; init address of second sector
	mov cl, 2		; specify which sector to read from USB flash
	call read_sector	; read sector 2 of USB

	mov si, 0x7e00		
	call print
	jmp $  


print:				; procedure to print a string
	cld			; clear DIRECTION FLAG
	mov ah, 0x0e		; enable teletype output for INT 0X10 interruption
	
	.next_char:		; print next char
		lodsb		; read next byte from si(SOURCE INDEX) register
		cmp al, 0	; checks if zero terminating char of the string is reached
		je .return	; return if string doesn't contain any more characters
		int 0x10	; INTERRUPTION: prints char in al register. ax register should be 0x0e
		jmp .next_char		

	.return: ret		; return from procedure
		

; procedure to read a single sector from USB flash drive
read_sector:
	mov ah, 0x02		; BIOS code to read from storage device
	mov al, 1		; how many sector to read
	mov ch, 0		; specify cilinder
	mov dh, 0		; specify head
	int 0x13		; INTERRUPTION: read the sector from USB flash drive into memory
	jc .error		; if failed to read sector, jump to error procedure
	ret			; return from procedure

	.error
		mov si, error_mssg	; point SOURCE INDEX register to error message string's address
		call print		; print error message
		jmp $			; processor holt (infinite loop)  


; messages
success_mssg db 'Game loaded successfully', 10, 13, 0 		; add \n (newline) before \0
error_mssg db 'Failed to read sector from USB', 10, 13, 0 	; add \n (newline) before \0

signature:
	times 510 - ($ - $$) db 0	; fill trailing zeros to get exactly 512 bytes long binary file
	dw 0xaa55			; set boot signature
