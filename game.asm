;==========================
;	GAME LOGIC
;	 SECTOR 2
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code

; list of available games
db 'Hello from sector 2', 10, 13, 0

times 512 - ($ - $$) db 0       ; fill trailing zeros to get exactly 512 bytes long binary file
