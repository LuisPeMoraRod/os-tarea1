;==========================
;       BOOTLOADER
;        SECTOR 1
;==========================

[bits 16]	; tell NASM to assemble 16-bit code to save space
[org 0x7c00]	; tell NASM the code is running at boot sector

%define SHELL_ADDR 0x07e0	; logical memory address of shell boot sector
%define SHELL_SECTOR 2		; USB sector assigned to shell
jmp short start


start:
	mov ax, 0		; init data registers, set ACCUMULATOR REGISTER to 0
	mov ds, ax		; ds = DATA SEGMENT register
	mov es, ax		; es = EXTRA SEGMENT register

	mov si, success_mssg	; point SOURCE INDEX register to success message string's address
	call print		; print message to screen

	; JUMP TO SECTOR 2: SHELL

	; 0x0000_7e00 is the memory address where the shell is loaded
	; To get the physical address = (A * 0x10) + B
	; 	where A = logical address
	;	      B = offset
	; 0x0000_7e00 = (0x7e0 * 0x10) + 0

	mov ax, SHELL_ADDR	; logical address of new sector
	mov es, ax		; point EXTRA SEGMENT register to logical address
	mov bx, 0		; offset = 0
	mov cl, SHELL_SECTOR	; specify sector 2 from USB flash
	call read_sector
	jmp SHELL_ADDR:0x0000


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
	mov dl, 0x80		; specify HDD code
	int 0x13		; INTERRUPTION: read the sector from USB flash drive into memory
	jc .error		; if failed to read sector, jump to error procedure
	ret			; return from procedure

	.error:
		mov si, error_mssg	; point SOURCE INDEX register to error message string's address
		call print		; print error message
		jmp $			; processor holt (infinite loop)  


; messages
success_mssg db 'Game loaded successfully', 10, 13, 0 		; add \n (newline) before \0
error_mssg db 'Failed to read sector from USB', 10, 13, 0 	; add \n (newline) before \0

signature:
	times 510 - ($ - $$) db 0	; fill trailing zeros to get exactly 512 bytes long binary file
	dw 0xaa55			; set boot signature
