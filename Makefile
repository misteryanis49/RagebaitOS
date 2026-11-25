# RageBait OS - Makefile
#   make       -> construit os.img (boot sector + kernel)
#   make run   -> lance os.img dans QEMU
#   make clean -> supprime tout ce qui est généré

AS = nasm
CC = gcc
LD = ld

KERNEL_ADDR = 0x1000
MAX_SECTORS = 54

CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -fcf-protection=none \
         -nostdlib -O0 -Wall -Wextra -std=gnu11

# Ordre critique : kernel_entry.o EN PREMIER
KERNEL_OBJS = kernel/kernel_entry.o \
              kernel/kernel.o \
              kernel/ata.o \
              kernel/vga.o \
              kernel/keyboard.o \
              kernel/terminal.o \
              kernel/shell.o

all: os.img disk.img

# --- Kernel -----------------------------------------------------------
kernel/kernel_entry.o: kernel/kernel_entry.asm
	$(AS) -f elf32 $< -o $@

kernel/ata.o: kernel/ata.c kernel/ata.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/kernel.o: kernel/kernel.c kernel/ata.h kernel/terminal.h kernel/vga.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/vga.o: kernel/vga.c kernel/vga.h kernel/io.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/keyboard.o: kernel/keyboard.c kernel/keyboard.h kernel/io.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/terminal.o: kernel/terminal.c kernel/terminal.h kernel/vga.h kernel/keyboard.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/shell.o: kernel/shell.c kernel/terminal.h kernel/vga.h kernel/keyboard.h kernel/io.h
	$(CC) $(CFLAGS) -c $< -o $@

kernel/kernel.bin: $(KERNEL_OBJS)
	$(LD) -m elf_i386 -z noseparate-code -Ttext $(KERNEL_ADDR) --oformat binary -o $@ $^
	truncate -s $$(( ($$(stat -c%s $@) + 511) / 512 * 512 )) $@

# --- Bootloader -------------------------------------------------------
boot/boot.bin: boot/boot.asm kernel/kernel.bin
	@sectors=$$(( $$(stat -c%s kernel/kernel.bin) / 512 )); \
	if [ $$sectors -gt $(MAX_SECTORS) ]; then \
		echo "Kernel trop gros : $$sectors secteurs (max $(MAX_SECTORS))"; exit 1; \
	fi; \
	echo "Kernel : $$sectors secteur(s) a charger"; \
	$(AS) -f bin -D KERNEL_SECTORS=$$sectors $< -o $@

# --- Image disque finale ----------------------------------------------
os.img: boot/boot.bin kernel/kernel.bin
	cat $^ > $@

# --- Disque de données FAT32 (64 Mo) ---------------------------------
disk.img:
	dd if=/dev/zero of=$@ bs=1M count=64
	mkfs.fat -F 32 $@

run: os.img disk.img
	qemu-system-i386 -drive format=raw,file=os.img -drive format=raw,file=disk.img

clean:
	rm -f boot/*.bin kernel/*.o kernel/*.bin os.img disk.img

.PHONY: all run clean