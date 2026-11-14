# RagebaitOS
Un projet d'os crée a partir de 0 pour qui va faire rager n'importe qu'elle dev qui travail sur le projet 
Un petit système d'exploitation écrit from scratch

## État du projet

| Composant | Statut | Détails |
|---|---|---|
| Bootloader (16 bits) | OK | Chargé par le BIOS à `0x7C00` |
| Affichage BIOS (`int 0x10`) | OK | Affiche des messages en mode réel |
| Chargement du kernel (`int 0x13`) | OK | Lit le kernel depuis le disque (CHS) |
| Passage en mode protégé 32 bits | OK | GDT flat, activation du bit PE de `CR0` |
| Kernel en C | OK | `kernel_main()` exécuté à `0x1000` |
| Affichage VGA (`0xB8000`) | OK | Texte 80×25, couleurs |
| Pilote ATA PIO (lecture) | OK | `ata_read_sectors()` |
| Pilote ATA PIO (écriture) | OK | `ata_write_sectors()` + FLUSH CACHE |
| Système de fichiers FAT32 (lecture) | En cours | Parsing du BPB, lecture de la FAT |
| Système de fichiers FAT32 (écriture) |  Prévu | Allocation de clusters, entrées de répertoire |
| Clavier (PS/2) |  Prévu | Interruptions IRQ1 |
| Shell / commandes |  Prévu | Interpréteur basique |

##  Structure du projet

| Chemin | Rôle |
|---|---|
| `boot/boot.asm` | Bootloader : init, chargement du kernel, GDT, mode protégé |
| `kernel/kernel_entry.asm` | Point d'entrée 32 bits (`_start`), appelle `kernel_main` |
| `kernel/kernel.c` | Kernel principal : affichage VGA, logique de test |
| `kernel/ata.c` / `ata.h` | Pilote ATA PIO (lecture/écriture de secteurs) |
| `Makefile` | Compilation, link, création des images disque |
| `os.img` | Image bootable (boot sector + kernel) - générée |
| `disk.img` | Disque de données FAT32 (64 Mo) - généré |

##  Prérequis

| Outil | Version minimale | Rôle |
|---|---|---|
| `nasm` | 2.14 | Assembleur x86 |
| `gcc` | 8.0 (avec `-m32`) | Compilateur C |
| `gcc-multilib` | - | Bibliothèques 32 bits |
| `ld` (binutils) | 2.31 | Linker |
| `qemu-system-i386` | 4.0 | Émulateur |
| `dosfstools` | - | `mkfs.fat` pour créer `disk.img` |
| `mtools` | - | Inspection de `disk.img` (optionnel) |

Installation sur Debian/Ubuntu :

```bash
sudo apt install nasm gcc gcc-multilib binutils qemu-system-x86 dosfstools mtools
```
## remerciment
merci a :
* N3CR0-Ware
* moi même (misteryanis49)
* cfenollosa/os-tutorial - base du bootloader
* OSDev Wiki - référence technique
* Ralf Brown's Interrupt List - documentation BIOS
* deepseek - aide technique patch
