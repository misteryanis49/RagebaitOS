#include "terminal.h"
#include "keyboard.h"
#include "vga.h"

#define LINE_MAX 128
static char line[LINE_MAX];
static int  line_len = 0;

extern void shell_execute(const char* cmd);

static void print_prompt(void) { vga_putchar('>'); vga_putchar(' '); }

static void handle_key(char c) {
    if (c == KEY_ENTER) {
        line[line_len] = '\0';
        vga_putchar('\n');
        line_len = 0;              //  reset AVANT d'exécuter
        shell_execute(line);       // peut rebooter sans jamais revenir
        print_prompt();
    }
    else if (c == KEY_BACKSPACE) {
        if (line_len > 0) { line_len--; vga_backspace(); }
    }
    else if ((unsigned char)c >= ' ' && line_len < LINE_MAX - 1) {
        line[line_len++] = c;
        vga_putchar(c);
    }
}

void terminal_init(void) {
    for (int i = 0; i < LINE_MAX; i++) line[i] = 0;
    line_len = 0;

    vga_clear();
    vga_puts("RagebaitOS v0.1 - terminal\n");
    vga_puts("Tape 'help' pour la liste des commandes.\n\n");
    print_prompt();
}

void terminal_run(void) {
    for (;;) {
        if (keyboard_haschar()) {
            char c = keyboard_getchar();
            if (c) handle_key(c);
        }
    }
}
