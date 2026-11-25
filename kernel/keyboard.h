#ifndef KEYBOARD_H
#define KEYBOARD_H
#define KEY_BACKSPACE '\b'
#define KEY_ENTER     '\n'
#define KEY_ESC       0x1B
#define KEY_UP        0x80
#define KEY_DOWN      0x81
#define KEY_LEFT      0x82
#define KEY_RIGHT     0x83
int  keyboard_haschar(void);
char keyboard_getchar(void);
#endif
