# assemble bootloader
nasm -f bin bootloader.asm -o bootloader.bin

# assemble bootloader
nasm -f bin shell.asm -o shell.bin

# assemble game file
nasm -f bin game.asm -o game.bin 

# generate floppy image (2880 - 3 sectors for bootloader, shell and game = 2877)
dd if=/dev/zero of=floppy.bin count=2877 bs=512

# merge bootloader and game into floppy image
cat bootloader.bin shell.bin game.bin floppy.bin > micromundOS.img

# clean up files
rm -f bootloader.bin shell.bin game.bin floppy.bin

# run OS image in the QEMU emulator
qemu-system-i386 -hda micromundOS.img
