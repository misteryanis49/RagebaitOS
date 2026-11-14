/* RageBait OS - kernel de test
 * Pas de libc, pas d'OS en dessous : on écrit directement dans la mémoire vidéo.
 * En mode texte VGA, l'écran fait 80 colonnes x 25 lignes et commence à 0xB8000.
 * Chaque case = 2 octets : le caractère (octet bas) + sa couleur (octet haut).
 */

#include "ata.h"

#define VGA_MEMORY ((volatile unsigned short *)0xB8000)
#define VGA_COLS   80
#define VGA_ROWS   25

#define COLOR_WHITE_ON_RED  0x4F
#define COLOR_GREY_ON_BLACK 0x07

static void clear_screen(void) {
    for (int i = 0; i < VGA_COLS * VGA_ROWS; i++) {
        VGA_MEMORY[i] = (COLOR_GREY_ON_BLACK << 8) | ' ';
    }
}

static void print_at(const char *text, int row, int col, unsigned char color) {
    for (int i = 0; text[i] != '\0'; i++) {
        VGA_MEMORY[row * VGA_COLS + col + i] = (color << 8) | (unsigned char)text[i];
    }
}

void kernel_main(void) {
    clear_screen();
    print_at("RageBait OS", 0, 0, COLOR_WHITE_ON_RED);
    print_at("Chargement du kernel en 32 bit: Succes", 2, 0, COLOR_GREY_ON_BLACK);

    print_at("Test ecriture", 4, 0, COLOR_GREY_ON_BLACK);
    // --- Test du pilote ATA ---
    static uint8_t write_buf[512];
    static uint8_t read_buf[512];

    for (int i = 0; i < 512; i++) write_buf[i] = 0;
    write_buf[0] = 'T';
    write_buf[1] = 'E';
    write_buf[2] = 'S';
    write_buf[3] = 'T';

    // Écrit au secteur 1000 de disk.img
    if (ata_write_sectors(1000, 1, write_buf) != 0) {
        print_at("ATA: erreur ecriture", 6, 0, 0x0C);
        return;
    }
    print_at("ATA: ecriture OK", 6, 0, 0x0A);

    // Relit le même secteur
    if (ata_read_sectors(1000, 1, read_buf) != 0) {
        print_at("ATA: erreur lecture", 7, 0, 0x0C);
        return;
    }

    // Compare
    int ok = 1;
    for (int i = 0; i < 512; i++) {
        if (write_buf[i] != read_buf[i]) { ok = 0; break; }
    }
    if (ok) {
        print_at("ATA: lecture OK, donnees identiques", 7, 0, 0x0A);
    } else {
        print_at("ATA: donnees differentes !", 7, 0, 0x0C);
    }

    
}
