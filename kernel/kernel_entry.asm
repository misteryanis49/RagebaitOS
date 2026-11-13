; Point d'entrée du kernel : c'est la toute première chose exécutée à l'adresse 0x1000.
; Il doit être le PREMIER fichier donné au linker (voir le Makefile).
; Son seul rôle : appeler kernel_main (écrit en C) puis stopper le processeur si jamais il retourne.

[BITS 32]
[EXTERN kernel_main]    ; kernel_main est défini dans kernel.c

global _start
_start:
    call kernel_main
    cli                 ; si on arrive ici, le kernel a fini : on coupe tout
.halt:
    hlt
    jmp .halt

section .note.GNU-stack noalloc noexec nowrite progbits   ; dit au linker que la pile n'a pas besoin d'être exécutable (supprime un warning)
