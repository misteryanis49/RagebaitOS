# RageBait OS - Makefile
#   make       -> construit os.img (boot sector + kernel)
#   make run   -> lance os.img dans QEMU
#   make clean -> supprime tout ce qui est généré

AS = nasm
CC = gcc
LD = ld

# Doit être la même valeur que KERNEL_OFFSET dans boot/boot.asm
KERNEL_ADDR = 0x1000

# Place max pour le kernel : entre 0x1000 et 0x7C00 (là où commence le boot sector) = 54 secteurs
MAX_SECTORS = 54

CFLAGS = -m32 -ffreestanding -fno-pie -fno-stack-protector -fcf-protection=none \
         -nostdlib -O0 -Wall -Wextra

all: os.img

# --- Kernel -----------------------------------------------------------
kernel/kernel_entry.o: kernel/kernel_entry.asm
	$(AS) -f elf32 $< -o $@

kernel/kernel.o: kernel/kernel.c
	$(CC) $(CFLAGS) -c $< -o $@

# kernel_entry.o doit rester en premier : c'est lui qui se retrouve à 0x1000
kernel/kernel.bin: kernel/kernel_entry.o kernel/kernel.o
	$(LD) -m elf_i386 -z noseparate-code -Ttext $(KERNEL_ADDR) --oformat binary -o $@ $^
	@# on complète avec des zéros pour avoir un nombre entier de secteurs de 512 octets
	truncate -s $$(( ($$(stat -c%s $@) + 511) / 512 * 512 )) $@

# --- Bootloader (dépend du kernel : il a besoin de sa taille) ----------
boot/boot.bin: boot/boot.asm kernel/kernel.bin
	@sectors=$$(( $$(stat -c%s kernel/kernel.bin) / 512 )); \
	if [ $$sectors -gt $(MAX_SECTORS) ]; then \
		echo "Kernel trop gros : $$sectors secteurs (max $(MAX_SECTORS))"; exit 1; \
	fi; \
	echo "Kernel : $$sectors secteur(s) a charger"; \
	$(AS) -f bin -D KERNEL_SECTORS=$$sectors $< -o $@

# --- Image disque finale ------------------------------------------------
os.img: boot/boot.bin kernel/kernel.bin
	cat $^ > $@

run: os.img
	qemu-system-i386 -drive format=raw,file=os.img

clean:
	rm -f boot/*.bin kernel/*.o kernel/*.bin os.img

.PHONY: all run clean
