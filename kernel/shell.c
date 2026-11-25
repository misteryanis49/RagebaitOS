#include "terminal.h"
#include "keyboard.h"
#include "io.h"
#include "vga.h"

static int str_eq(const char* a, const char* b) {
    while (*a && *a == *b) { a++; b++; }
    return *a == *b;
}
static int str_prefix(const char* s, const char* prefix) {
    while (*prefix) if (*s++ != *prefix++) return 0;
    return 1;
}

static void cmd_help(void) {
    vga_putchar('\n');
    vga_puts("Commandes disponibles :\n");
    vga_puts("  help         - Affiche l'aide\n");
    vga_puts("  clear        - efface l'ecran\n");
    vga_puts("  echo <texte> - affiche le texte\n");
    vga_puts("  reboot       - redemarre\n");
    vga_puts("  shutdown     - Eteint le PCU\n");
}
static void cmd_echo(const char* args) { vga_puts(args); vga_putchar('\n'); }
static void cmd_reboot(void) {
    vga_puts("Redemarrage...\n");
    while (inb(0x64) & 0x02);
    outb(0x64, 0xFE);
    for (;;) __asm__ volatile ("hlt");
}
static void cmd_halt(void) {
    vga_puts("CPU halted. Machine arreter avec succes.\n");
    __asm__ volatile ("cli");
    for (;;) __asm__ volatile ("hlt");
}

void shell_execute(const char* cmd) {
    while (*cmd == ' ') cmd++;
    if (*cmd == '\0') return;
    if      (str_eq(cmd, "help"))      cmd_help();
    else if (str_eq(cmd, "clear"))     vga_clear();
    else if (str_eq(cmd, "reboot"))    cmd_reboot();
    else if (str_eq(cmd, "shutdown"))      cmd_halt();
    else if (str_eq(cmd, "echo"))      vga_putchar('\n');
    else if (str_prefix(cmd, "echo ")) cmd_echo(cmd + 5);
    else {
        vga_puts("Commande inconnue : ");
        vga_puts(cmd);
        vga_putchar('\n');
    }
}
