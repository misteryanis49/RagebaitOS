; RageBait OS - bootloader

; J'ai entierement réécrit le boot loader (j'ai fait de la merde mais maintenant c'est bien fait)
; action réaliser : passage en mode protégé écriture de la GDT, passage en  32 bits

[BITS 16]                   ; on encode en 16 Bits obligatoire pour débuter (on utilise le mode réel du Bios)
[ORG 0x7C00]                ; étiquette sorte de #include stud.io en C

KERNEL_OFFSET  equ 0x1000    ; adresse où on charge le kernel (le linker doit utiliser la même !)

%ifndef KERNEL_SECTORS
    KERNEL_SECTORS equ 1     
%endif

start:
    cli                     ; coupe les interruptions le temps d'initialiser la pile
    mov ax, 0               ; initie ax a 0
    mov ds, ax              ; DS = 0 : indispensable pour les messages
    mov es, ax              ; ES = 0 : segment de destination pour int 0x13
    mov ss, ax
    mov sp, 0x7C00          ; pile : grandit vers le bas, ne touche pas le code
    sti                     ; réactive (le BIOS en a besoin pour int 0x10 et 0x13) c'est le changement de mode (utile pour afficher les code de succès / erreur)
    cld                     ; DF = 0 : lodsb avancera dans le bon sens

    mov [boot_drive], dl    ; sauvegarde le disque de boot (donné par le BIOS)

    mov si, msg_boot
    call print_string       ; affiche "Bienvenue"

    call load_kernel        ; charge le kernel à 0x1000

    jmp switch_to_pm        ; passe en 32 bits si succès


; print_string : cette fonction sert a afficher tout simplement qu'elle que choise a l'écran (Attention le passage en mode réel est obligatoire)

print_string:
    lodsb                   ; AL = [SI], puis SI++
    cmp al, 0               ; Vérifie si on a finit d'afficher
    je .done                ; si c'est le cas alors on faire un return (le .done: ret est un return)
    mov ah, 0x0e            ; fonction "afficher un caractère"
    mov bh, 0               ; page 0
    int 0x10                ; applique l'affichage
    jmp print_string        ; retourne au début du print_string
.done:
    ret

; ------------------------------------------------------------
; load_kernel : lit KERNEL_SECTORS secteurs à partir du secteur 2,
;               et les copie à l'adresse physique KERNEL_OFFSET
; ------------------------------------------------------------

load_kernel:
    mov ax, 0
    mov es, ax              ; ES = 0 (segment de destination)
    mov bx, KERNEL_OFFSET   ; BX = 0x1000 (offset) → ES:BX = 0x0000:0x1000 = physique 0x1000
    mov ah, 0x02            ; fonction "lire des secteurs"
    mov al, KERNEL_SECTORS
    mov ch, 0               ; cylindre 0
    mov cl, 2               ; secteur 2 (juste après le boot sector)
    mov dh, 0               ; tête 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    cmp ah, 0
    jne disk_error
    ret

disk_error:
    mov si, msg_disk_error
    call print_string
hang16:
    jmp hang16              ; boucle infinie en cas d'erreur disque

; ------------------------------------------------------------
; switch_to_pm : active la GDT et passe en mode protégé 32 bits (rédiger par deepseek)
; ------------------------------------------------------------
switch_to_pm:
    cli                     ; plus d'interruptions : vue qu'on passe en 32 bit le Bios ne le supporte plus
    lgdt [gdt_descriptor]   ; donne la GDT au processeur
    mov eax, cr0
    or eax, 1               ; bit 0 de CR0 = PE (Protection Enable)
    mov cr0, eax
    jmp CODE_SEG:init_pm    ; far jump : recharge CS et vide le pipeline

; ------------------------------------------------------------
; init_pm : on est maintenant en 32 bits  (rédiger par deepseek)
; ------------------------------------------------------------
[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000        ; nouvelle pile en 32 bits, loin du kernel
    mov ebp, esp
    call KERNEL_OFFSET      ; saute dans le kernel (kernel_entry.asm -> kernel_main en C)
.halt:
    hlt                     ; si le kernel retourne, on stoppe
    jmp .halt

; ------------------------------------------------------------
; GDT : 3 entrées de 8 octets (nul, code, données)  (rédiger par deepseek)
; ------------------------------------------------------------
gdt_start:
    dq 0x0                  ; descripteur nul (obligatoire par la spec Intel)

gdt_code:                   ; code : base 0, limite 4 Go, ring 0, exécutable
    dw 0xFFFF               ; limite (bits 0-15)
    dw 0x0                  ; base (bits 0-15)
    db 0x0                  ; base (bits 16-23)
    db 10011010b            ; access : présent, ring 0, code, exécutable, lisible
    db 11001111b            ; flags : granularité 4 Ko, mode 32 bits, limite (16-19)
    db 0x0                  ; base (bits 24-31)

gdt_data:                   ; données : base 0, limite 4 Go, ring 0, lecture/écriture
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 10010010b            ; access : présent, ring 0, données, écriture
    db 11001111b
    db 0x0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; taille - 1 (lgdt attend "dernière adresse valide")
    dd gdt_start                ; adresse physique de la GDT

CODE_SEG equ gdt_code - gdt_start   ; = 0x08
DATA_SEG equ gdt_data - gdt_start   ; = 0x10

; Donné utile pour les message 

boot_drive:     db 0
msg_boot:       db 'Bienvenue', 13, 10, 0
msg_disk_error: db 'Erreur disque', 0

times 510 - ($ - $$) db 0
dw 0xAA55