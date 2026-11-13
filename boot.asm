; Pour ce qu'il lise c'est ligne et je pense a mes pote du lycée ne vous inquiété pas j'ai écrit c'est ligne et donc vous n'aurrez pas a plonger dans l'ASM
; Ce bout de code sert uniquement a boot et provient de ce github https://github.com/cfenollosa/os-tutorial/tree/master/01-bootsector-barebones


[BITS 16]           ; mode réel de base du processeur/Bios
[ORG 0x7C00]        ; étiquette de résolution (pour faire simple sa permet de gérez la mémoire plus simplement)

mov ax, 0               ; Ax est une addresse qui est utiliser a chaque message et doit être init a 0
mov ds, ax              ; Chiant a expliquer

mov [boot_drive], dl    ; sa sert a écrire dans le registre mémoire dl et de savoir depuis ou on boot
mov bx, 0               ; défini l'addresse BX (qui n'est pas utiliser mais ici serviras d'index a 0)
jmp Afficher_bienvenue  ; jmp sert a sauter de fonction en fonction ce qui est pratique l'équivalent du goto en bash


boot_drive: db 0        ; définie 1 octet dans le fichier binnaire avec l'étiquette/fonction boot_drive qui pointe ici

message:
    db 'Bienvenue', 0   ; défini les octet avec les chaine ascii
msg_ok:
    db ' OK', 0          ; message OK utiliser pour le test secteur
msg_err:
    db ' E', 0           ; si la lettre E apparait cela signifie que le test secteur a échouer


Afficher_bienvenue:
    mov al, [message + bx] ; engros cette ligne permet de regarger dans la chaine de character message défini plutot et va a l'index bx
    cmp al, 0              ; cette ligne est une sorte de if en ASM elle sert a comparer si il a finit d'afficher (engros on regarde si la chaine de charactère vaut nulle)
    je load_kernel         ; Si vrai alors on load le kernel, le message bienvenue est afficher
    mov ah, 0x0e           ; sert activer le module vidéo du Bios
    int 0x10               ; affiche le character charger dans le registre processeur
    inc bx                 ; c'est le i++; du sa sert a ajouter 1 a l'index bx
    jmp Afficher_bienvenue ; retourne a mess_pass pour finir d'afficher
    

load_kernel:                ; cette partie est assez complexe a comprendre, pour être honette j'ai du faire du copier coller (trop compliquer pour moi mais je vais quand même détailler)
    mov ah, 0x02            ; AH sert a dire qu'on selectionne le secteur 0x02 qui ici est le kernel
    mov al, 1               ; ici sa sert a dire combien de secteur on souhaite lire, ici 1 = 512 octet
    mov ch, 0               ; Sa sert a définir ou la tête de lecture doit lire physiquement sur le disque 
    mov cl, 2               ; on définit le secteur souhaiter c'est le 2 c'est a dire le kernel
    mov dh, 0               ; Après bonne chance je pige plus rien mais si tu comprend je suis preneur 
    mov dl, [boot_drive]
    mov bx, 0x8000
    mov es, bx
    mov bx, 0

    int 0x13
    jc disk_error
    cmp ah, 0
    jne disk_error          ; si Error on va aller sur disk_error qui affiche E
    mov bx, 0

; Si aucune erreur le code continue ici
affiche_ok:
    mov al, [msg_ok + bx]
    cmp al, 0
    je loop                ; ok afficher on va a loop
    mov ah, 0x0e
    int 0x10
    inc bx
    jmp affiche_ok

disk_error:
    mov bx, 0
    
affiche_err:
    mov al, [msg_err + bx]
    cmp al, 0
    je loop
    mov ah, 0x0e
    int 0x10
    inc bx
    jmp affiche_err

loop:
    jmp loop

times 510-($-$$) db 0; cettte ligne cert uniquement a nasm pour qu'il génère suffisament d'octet vide pour respecter le bootsector


dw 0xaa55 ; signature Bios