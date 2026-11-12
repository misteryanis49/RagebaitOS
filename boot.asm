; Pour ce qu'il lise c'est ligne et je pense a mes pote du lycée ne vous inquiété pas j'ai écrit c'est ligne et donc vous n'aurrez pas a plonger dans l'ASM
; Ce bout de code sert uniquement a boot et provient de ce github https://github.com/cfenollosa/os-tutorial/tree/master/01-bootsector-barebones


[BITS] ; code temporaire le temps de métriser / réaprendre l'ASM



mov ah, 0x0e    ; sert activer le module vidéo du Bios
mov al, 'B'     ; charge b dans le registre du processeur
int 0x10        ; écrit la lettre dans la lettre du registre al

mov al, 'i'
int 0x10
mov al, 'e'
int 0x10
mov al, 'n'
int 0x10
mov al, 'v'
int 0x10
mov al, 'e'
int 0x10
mov al, 'n'
int 0x10
mov al, 'u'
int 0x10
mov al, 'e'
int 0x10


; boucle infinie pour éviter le crash

loop:
    jmp loop 

times 510-($-$$) db 0; cettte ligne cert uniquement a nasm pour qu'il génère suffisament d'octet vide pour respecter le bootsector


dw 0xaa55 
; signature Bios