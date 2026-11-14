/* RageBait OS - kernel de test
 * Pas de libc, pas d'OS en dessous : on écrit directement dans la mémoire vidéo.
 * En mode texte VGA, l'écran fait 80 colonnes x 25 lignes et commence à 0xB8000.
 * Chaque case = 2 octets : le caractère (octet bas) + sa couleur (octet haut).
 */

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
}
