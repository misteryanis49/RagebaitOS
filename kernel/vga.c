#include "vga.h"
#include "io.h"

#define VGA_MEM  ((volatile uint16_t*)0xB8000)
#define VGA_ATTR 0x07

static int cx = 0, cy = 0;

static void update_cursor(void) {
    uint16_t pos = cy * VGA_WIDTH + cx;
    outb(0x3D4, 0x0F); outb(0x3D5, (uint8_t)(pos & 0xFF));
    outb(0x3D4, 0x0E); outb(0x3D5, (uint8_t)((pos >> 8) & 0xFF));
}

static void scroll(void) {
    for (int i = 0; i < (VGA_HEIGHT - 1) * VGA_WIDTH; i++)
        VGA_MEM[i] = VGA_MEM[i + VGA_WIDTH];
    for (int i = (VGA_HEIGHT - 1) * VGA_WIDTH; i < VGA_HEIGHT * VGA_WIDTH; i++)
        VGA_MEM[i] = (VGA_ATTR << 8) | ' ';
    cy = VGA_HEIGHT - 1;
}

void vga_clear(void) {
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++)
        VGA_MEM[i] = (VGA_ATTR << 8) | ' ';
    cx = 0; cy = 0;
    update_cursor();
}

void vga_putchar(char c) {
    if (c == '\n') { cx = 0; cy++; }
    else if (c == '\r') { cx = 0; }
    else if (c == '\b') {
        if (cx > 0) cx--;
        else if (cy > 0) { cy--; cx = VGA_WIDTH - 1; }
        else return;
        VGA_MEM[cy * VGA_WIDTH + cx] = (VGA_ATTR << 8) | ' ';
    } else if (c == '\t') {
        int next = (cx + 4) & ~3;
        while (cx < next && cx < VGA_WIDTH) vga_putchar(' ');
    } else {
        VGA_MEM[cy * VGA_WIDTH + cx] = (VGA_ATTR << 8) | (uint8_t)c;
        cx++;
        if (cx >= VGA_WIDTH) { cx = 0; cy++; }
    }
    if (cy >= VGA_HEIGHT) scroll();
    update_cursor();
}

void vga_backspace(void) { vga_putchar('\b'); }
void vga_puts(const char* s) { while (*s) vga_putchar(*s++); }
