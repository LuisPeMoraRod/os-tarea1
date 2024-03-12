# MicromundOS

Bootloaded game built in x86 assembly that emulates the retro game: MicroMundos

## Prerequisites

You must have installed the following programs to run the game in QEMU:

1. `nasm`
2. `qemu`

## How to build image

Run the following command to build the image file named `micromundOS.img`:

```
make
```

## How to run in QEMU

Run the following command to build and run image in QEMU:

```
make run
```

## How to load image to USB

1. Connect the flash drive and locate the device name with:

```
sudo fdisk -l
```

For instance, the name of the USB used in this guide is: `/dev/sdc1`

2. Clear the sectors that will be overriden:

```
sudo dd if=/dev/zero of=/dev/sdc1 count=2876 bs=512
```

You can check that the first 4 sectors are written with zeros:

```
sudo xxd -l 2048 /dev/sdc1
```

3. Write image file to USB:

```
sudo dd if=micromundOS.img of=/dev/sdc1 count=2876 bs=512
```
