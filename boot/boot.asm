; RageBait OS - bootloader
; Base : https://github.com/cfenollosa/os-tutorial/tree/master/01-bootsector-barebones
;
; Ce que fait ce fichier, dans l'ordre :
;   1. initialise les registres (segments + pile)
;   2. charge le kernel depuis le disque en mémoire à l'adresse 0x1000
;   3. active la ligne A20 (pour pouvoir utiliser plus de 1 Mo de RAM)
;   4. passe en mode protégé 32 bits (GDT)
;   5. saute dans le kernel (écrit en C, voir kernel/)

[BITS 16]               ; au démarrage le processeur est en mode réel 16 bits
[ORG 0x7C00]            ; le BIOS charge toujours le boot sector à l'adresse 0x7C00 (ça permet de gérer la mémoire plus simplement)

KERNEL_OFFSET equ 0x1000    ; adresse mémoire où on charge le kernel (le Makefile doit linker le kernel à la même adresse !)

%ifndef KERNEL_SECTORS
    KERNEL_SECTORS equ 16   ; nombre de secteurs (512 octets) à lire, le Makefile le calcule tout seul
%endif

    jmp 0x0000:start    ; saut "far" pour être sûr que CS = 0 (certains BIOS démarrent en 07C0:0000)

start:
    cli                 ; on coupe les interruptions le temps de changer la pile
    xor ax, ax          ; ax = 0
    mov ds, ax          ; DS = 0 : indispensable pour lire les messages au bon endroit en mémoire
    mov es, ax          ; pareil pour ES, on remet tout à zéro
    mov ss, ax          ; on se fait une pile à nous
    mov sp, 0x7C00      ; la pile grandit vers le bas, donc elle ne touche pas notre code
    sti                 ; on remet les interruptions (le BIOS en a besoin pour int 0x10 et 0x13)
    cld                 ; lodsb avancera toujours dans le bon sens (si++)

    mov [boot_drive], dl    ; le BIOS met le numéro du disque de boot dans DL : on le garde, int 0x13 en a besoin

    mov si, msg_boot
    call print_string       ; affiche "Bienvenue"

    call load_kernel        ; lit le kernel sur le disque
    call enable_a20         ; active la ligne A20
    jmp switch_to_pm        ; passe en 32 bits (on ne revient jamais ici)

; ------------------------------------------------------------
; print_string : affiche la chaîne pointée par SI (finie par 0)
; ------------------------------------------------------------
print_string:
    lodsb               ; en gros : al = [si] puis si++
    cmp al, 0           ; sorte de if en ASM : on regarde si la chaîne de caractères vaut nul (donc qu'on a fini)
    je .done            ; si vrai alors on a fini
    mov ah, 0x0e        ; sert à activer le mode "afficher un caractère" du BIOS
    mov bh, 0           ; page vidéo 0
    int 0x10            ; affiche le caractère chargé dans le registre processeur
    jmp print_string    ; retourne au début pour finir d'afficher (jmp = l'équivalent du goto)
.done:
    ret

; ------------------------------------------------------------
; load_kernel : lit KERNEL_SECTORS secteurs du disque (à partir
; du secteur 1, juste après le boot sector) vers KERNEL_OFFSET
; On utilise int 0x13 / AH=0x42 (adressage LBA) : pas besoin de
; se prendre la tête avec cylindres / têtes / secteurs.
; ------------------------------------------------------------
load_kernel:
    mov ah, 0x41            ; on demande au BIOS s'il sait faire du LBA (extensions int 0x13)
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc disk_error           ; carry = 1 -> pas supporté

    mov si, dap             ; DS:SI pointe sur la structure "disk address packet" définie plus bas
    mov dl, [boot_drive]
    mov ah, 0x42            ; fonction "lecture étendue"
    int 0x13
    jc disk_error           ; carry = 1 -> la lecture a échoué
    ret

disk_error:
    mov si, msg_disk_error
    call print_string
hang:
    jmp hang                ; boucle infinie pour éviter le crash

; ------------------------------------------------------------
; enable_a20 : méthode "fast A20" via le port 0x92
; ------------------------------------------------------------
enable_a20:
    in al, 0x92
    or al, 2                ; bit 1 = A20
    and al, 0xFE            ; bit 0 = reset du PC, on s'assure qu'il est à 0 !
    out 0x92, al
    ret

; ------------------------------------------------------------
; switch_to_pm : passage en mode protégé 32 bits
; ------------------------------------------------------------
switch_to_pm:
    cli                     ; plus d'interruptions (le BIOS ne marche plus en 32 bits)
    lgdt [gdt_descriptor]   ; on donne la GDT au processeur
    mov eax, cr0
    or eax, 1               ; bit 0 de CR0 = mode protégé
    mov cr0, eax
    jmp CODE_SEG:init_pm    ; saut "far" : vide le pipeline et charge le segment de code 32 bits

[BITS 32]                   ; à partir d'ici on écrit du code 32 bits
init_pm:
    mov ax, DATA_SEG        ; tous les segments de données pointent sur le segment de données de la GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; nouvelle pile, loin du kernel et du boot sector
    mov ebp, esp

    call KERNEL_OFFSET      ; on saute dans le kernel (kernel_entry.asm -> kernel_main en C)

.halt:
    hlt                     ; si le kernel retourne, on stoppe le processeur
    jmp .halt

[BITS 16]                   ; retour au 16 bits pour les données (aucun effet sur les octets, juste pour NASM)

; ------------------------------------------------------------
; GDT : table qui décrit les segments mémoire (modèle "flat" : tout est à plat sur 4 Go)
; ------------------------------------------------------------
gdt_start:
    dq 0x0                  ; le premier descripteur doit être nul

gdt_code:                   ; segment de code : base 0, limite 4 Go, exécutable, lisible
    dw 0xFFFF               ; limite (bits 0-15)
    dw 0x0                  ; base (bits 0-15)
    db 0x0                  ; base (bits 16-23)
    db 10011010b            ; présent, ring 0, code, exécutable, lisible
    db 11001111b            ; granularité 4 Ko, mode 32 bits, limite (bits 16-19)
    db 0x0                  ; base (bits 24-31)

gdt_data:                   ; segment de données : base 0, limite 4 Go, lecture/écriture
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b            ; présent, ring 0, données, écriture autorisée
    db 11001111b
    db 0x0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; taille de la GDT - 1
    dd gdt_start                ; adresse de la GDT

CODE_SEG equ gdt_code - gdt_start   ; = 0x08
DATA_SEG equ gdt_data - gdt_start   ; = 0x10

; ------------------------------------------------------------
; Données
; ------------------------------------------------------------
boot_drive: db 0

dap:                            ; "disk address packet" pour int 0x13 / AH=0x42
    db 0x10                     ; taille de la structure (16 octets)
    db 0                        ; réservé
    dw KERNEL_SECTORS           ; nombre de secteurs à lire
    dw KERNEL_OFFSET            ; adresse de destination : offset
    dw 0x0000                   ; adresse de destination : segment
    dq 1                        ; premier secteur à lire (LBA 1 = juste après le boot sector)

msg_boot:       db 'Bienvenue', 13, 10, 0       ; 13, 10 = retour à la ligne (pas d'accents : la police du BIOS ne les gère pas)
msg_disk_error: db 'Erreur disque', 0

times 510-($-$$) db 0           ; cette ligne sert uniquement à NASM : il génère assez d'octets vides pour remplir le boot sector
                                ; (si tu dépasses 510 octets, NASM te met une erreur : il faut alléger le bootloader)
dw 0xAA55                       ; signature BIOS
