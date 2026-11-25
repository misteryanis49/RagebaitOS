#ifndef VGA_H
#define VGA_H
#define VGA_WIDTH  80
#define VGA_HEIGHT 25
void vga_clear(void);
void vga_putchar(char c);
void vga_backspace(void);
void vga_puts(const char* s);
#endif
