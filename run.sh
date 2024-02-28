# assemble bootloader
nasm -f bin bootloader.asm -o bootloader.bin

# assemble game file
nasm -f bin game.asm -o game.bin 

# generate floppy image (2880 - 2 sectors for bootloader = 2878)
dd if=/dev/zero of=floppy.bin count=2878 bs=512

# merge bootloader and game into floppy image
cat bootloader.bin game.bin floppy.bin > micromundOS.img

# clean up files
rm -f bootloader.bin game.bin floppy.bin

# run OS image in the QEMU emulator
qemu-system-i386 -hda micromundOS.img
