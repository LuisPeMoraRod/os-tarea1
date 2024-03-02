# Variables
ASM = nasm
FORMAT = bin
ASMFLAGS = -f $(FORMAT)
QEMU = qemu-system-i386
IMG = micromundOS.img
BOOTLOADER_SRC = bootloader.asm
SHELL_SRC = shell.asm
GAME_SRC = game.asm
BOOTLOADER_BIN = bootloader.bin
SHELL_BIN = shell.bin
GAME_BIN = game.bin
FLOPPY_BIN = floppy.bin
BS = 512
COUNT = 2877

# Default target
all: $(IMG)

$(BOOTLOADER_BIN): $(BOOTLOADER_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(SHELL_BIN): $(SHELL_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(GAME_BIN): $(GAME_SRC)
	$(ASM) $(ASMFLAGS) $< -o $@

$(FLOPPY_BIN):
	dd if=/dev/zero of=$@ count=$(COUNT) bs=$(BS)

$(IMG): $(BOOTLOADER_BIN) $(SHELL_BIN) $(GAME_BIN) $(FLOPPY_BIN)
	cat $(BOOTLOADER_BIN) $(SHELL_BIN) $(GAME_BIN) $< > $@

# Phony targets for cleaning up and running
.PHONY: clean run

clean:
	rm -f $(BOOTLOADER_BIN) $(SHELL_BIN) $(GAME_BIN) $(FLOPPY_BIN) $(IMG)

run: all
	$(QEMU) -hda $(IMG)

