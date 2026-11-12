; Pour ce qu'il lise c'est ligne et je pense a mes pote du lycée ne vous inquiété pas j'ai écrit c'est ligne et donc vous n'aurrez pas a plonger dans l'ASM
; Ce bout de code sert uniquement a boot et provient de ce github https://github.com/cfenollosa/os-tutorial/tree/master/01-bootsector-barebones


[BITS 16]           ; code temporaire le temps de métriser / réaprendre l'ASM
[ORG 0x7C00]        ; étiquette de résolution (pour faire simple sa permet de gérez la mémoire plus simplement)

mov bx, 0           ; défini l'addresse BX (qui n'est pas utiliser mais ici serviras d'index a 0)
jmp start           ; jmp sert a sauter de fonction en fonction ce qui est pratique l'équivalent du goto en bash


message:
    db 'Bienvenue', 0   ; défini les octet avec les chaine ascii


start:
    mov ah, 0x0e    ; sert activer le module vidéo du Bios


mess_pass:
    mov al, [message + bx] ; engros cette ligne permet de regarger dans la chaine de character message défini plutot et va a l'index bx
    cmp al, 0              ; cette ligne est une sorte de if en ASM elle sert a comparer si il a finit d'afficher (engros on regarde si la chaine de charactère vaut nulle)
    je loop                ; Si vrai alors on va a loop (engros on a fini)

    int 0x10               ; affiche le character charger dans le registre processeur
    inc bx                 ; c'est le i++; du sa sert a ajouter 1 a l'index bx
    jmp mess_pass          ; retourne a mess_pass pour finir d'afficher



; boucle infinie pour éviter le crash

loop:
    jmp loop 

times 510-($-$$) db 0; cettte ligne cert uniquement a nasm pour qu'il génère suffisament d'octet vide pour respecter le bootsector


dw 0xaa55 ; signature Bios