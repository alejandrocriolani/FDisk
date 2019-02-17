clear
nasm -f bin fdisk.asm -o fdisk.bin
qemu-system-i386 -fda fdisk.bin -hda disk.img -boot order=a