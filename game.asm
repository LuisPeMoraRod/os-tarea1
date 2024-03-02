;==========================
;	GAME LOGIC
;	 SECTOR 3
;==========================

[bits 16]                       ; tell NASM to assemble 16-bit code

game_loop:
	
times 512 - ($ - $$) db 0       ; fill trailing zeros to get exactly 512 bytes long binary file
