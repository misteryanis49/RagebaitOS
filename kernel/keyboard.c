// keyboard.c — AZERTY français
// aide de deepseek
#include "keyboard.h"
#include "io.h"

// Table AZERTY set 1 — accents en CP437 (page de code VGA) merci deepseek pour l'aide
static const char sc_azerty[128] = {
    0,    0,   '&',  0x82, '"',  '\'', '(',  '-',
    0x8A, '_', 0x87, 0x85, ')',  '=',  '\b', '\t',
    'a',  'z', 'e',  'r',  't',  'y',  'u',  'i',
    'o',  'p', '^',  '$',  '\n', 0,    'q',  's',
    'd',  'f', 'g',  'h',  'j',  'k',  'l',  'm',
    0x97, '*', 0,    '\\', 'w',  'x',  'c',  'v',
    'b',  'n', ',',  ';',  ':',  '!',  0,    '*',
    0,    ' ', 0,    0,    0,    0,    0,    0,
};

static const char sc_azerty_shift[128] = {
    0,    0,   '1',  '2',  '3',  '4',  '5',  '6',
    '7',  '8', '9',  '0',  0xF8, '+',  '\b', '\t',
    'A',  'Z', 'E',  'R',  'T',  'Y',  'U',  'I',
    'O',  'P', 0,    0x9C, '\n', 0,    'Q',  'S',
    'D',  'F', 'G',  'H',  'J',  'K',  'L',  'M',
    '%',  0xE6, 0,   '|',  'W',  'X',  'C',  'V',
    'B',  'N', '?',  '.',  '/',  0xA7, 0,    '*',
    0,    ' ', 0,    0,    0,    0,    0,    0,
};

static const char sc_azerty_altgr[128] = {
    0,    0,   0,   '~', '#', '{', '[',  '|',
    '`',  '\\','^', '@', ']', '}', 0,    0,
};

static int shift_down = 0;
static int caps_lock  = 0;
static int altgr_down = 0;
static int extended   = 0;

int keyboard_haschar(void) {
    return (inb(0x64) & 0x01) != 0;
}

void keyboard_reset_state(void) {
    shift_down = 0;
    caps_lock  = 0;
    altgr_down = 0;
    extended   = 0;
}

char keyboard_getchar(void) {
    if (!keyboard_haschar()) return 0;

    uint8_t sc = inb(0x60);

    // Touche relâchée
    if (sc & 0x80) {
        uint8_t code = sc & 0x7F;
        if (code == 0x2A || code == 0x36) shift_down = 0;
        if (code == 0x38) altgr_down = 0;
        extended = 0;
        return 0;
    }

    // Préfixe touches étendues
    if (sc == 0xE0) { extended = 1; return 0; }

    if (extended) {
        extended = 0;
        switch (sc) {
            case 0x48: return KEY_UP;
            case 0x50: return KEY_DOWN;
            case 0x4B: return KEY_LEFT;
            case 0x4D: return KEY_RIGHT;
            case 0x38: altgr_down = 1; return 0;   // Right Alt = AltGr
        }
        return 0;
    }

    // Modificateurs
    if (sc == 0x2A || sc == 0x36) { shift_down = 1; return 0; }
    if (sc == 0x3A) { caps_lock = !caps_lock; return 0; }

    // Sélection de table
    char c;
    if (altgr_down)         c = sc_azerty_altgr[sc];
    else if (shift_down)    c = sc_azerty_shift[sc];
    else                    c = sc_azerty[sc];

    if (!c) return 0;

    // CapsLock : inverse uniquement les lettres ASCII A-Z/a-z
    if (caps_lock && !altgr_down) {
        if (c >= 'a' && c <= 'z') c -= 32;
        else if (c >= 'A' && c <= 'Z') c += 32;
    }

    return c;
}