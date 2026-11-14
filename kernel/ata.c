#include "ata.h"

// Ports du canal primaire ATA


// définir Type         divers   description   
#define ATA_DATA        0x1F0   // données (16 bits)
#define ATA_ERROR       0x1F1   // code d'erreur (lecture)
#define ATA_SECCOUNT    0x1F2   // nombre de secteurs
#define ATA_LBA_LOW     0x1F3   // LBA bits 0-7
#define ATA_LBA_MID     0x1F4   // LBA bits 8-15
#define ATA_LBA_HIGH    0x1F5   // LBA bits 16-23
#define ATA_DRIVE_HEAD  0x1F6   // sélection disque + LBA bits 24-27
#define ATA_STATUS      0x1F7   // statut (lecture) / commande (écriture)
#define ATA_COMMAND     0x1F7

// Bits du registre de statut
#define ATA_SR_BSY  0x80        // Busy
#define ATA_SR_RDY  0x40        // Ready
#define ATA_SR_DF   0x20        // Device Fault
#define ATA_SR_DRQ  0x08        // Data Request
#define ATA_SR_ERR  0x01        // Error

// Commandes
#define ATA_CMD_READ    0x20
#define ATA_CMD_WRITE   0x30
#define ATA_CMD_FLUSH   0xE7

// Timeout pour le polling (évite de bloquer indéfiniment)
#define ATA_TIMEOUT 1000000


// commande ASM intégrès au code pour la lecture / écriture

static inline uint8_t inb(uint16_t port) {
    uint8_t ret;
    __asm__ volatile ("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outb(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

static inline uint16_t inw(uint16_t port) {
    uint16_t ret;
    __asm__ volatile ("inw %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline void outw(uint16_t port, uint16_t val) {
    __asm__ volatile ("outw %0, %1" : : "a"(val), "Nd"(port));
}


// Attente : le disque doit être prêt (BSY = 0)

static int ata_wait_bsy(void) {
    for (int i = 0; i < ATA_TIMEOUT; i++) {
        if ((inb(ATA_STATUS) & ATA_SR_BSY) == 0) return 0;
    }
    return -1;  // timeout
}


// Attente : le disque doit avoir des données prêtes (DRQ = 1)

static int ata_wait_drq(void) {
    for (int i = 0; i < ATA_TIMEOUT; i++) {
        uint8_t status = inb(ATA_STATUS);
        if (status & ATA_SR_ERR) return -1;
        if (status & ATA_SR_DF)  return -1;
        if ((status & ATA_SR_BSY) == 0 && (status & ATA_SR_DRQ)) return 0;
    }
    return -1;  // timeout
}

// ------------------------------------------------------------
// Petit délai (400 ns) : nécessaire après la sélection du disque
// pour laisser le temps au contrôleur de se stabiliser.
// On lit le port de statut 4 fois, ce qui prend environs 400 ns. sellons le github
// ------------------------------------------------------------
static void ata_io_wait(void) {
    for (int i = 0; i < 4; i++) {
        inb(ATA_STATUS);
    }
}


// Sélectionne le disque et envoie l'adresse LBA + le nombre de secteurs


static void ata_select(uint32_t lba, uint8_t count) {
    // 0xE0 = bits 7-5 à 111 (LBA mode), bit 4 = 0 (master) ou 1 (slave)
    uint8_t drive = 0xE0 | ((ATA_DRIVE_SLAVE ? 1 : 0) << 4)
                         | ((lba >> 24) & 0x0F);
    outb(ATA_DRIVE_HEAD, drive);
    ata_io_wait();  // laisse le temps au disque de se sélectionner

    outb(ATA_SECCOUNT, count);
    outb(ATA_LBA_LOW,  (uint8_t)(lba & 0xFF));
    outb(ATA_LBA_MID,  (uint8_t)((lba >> 8) & 0xFF));
    outb(ATA_LBA_HIGH, (uint8_t)((lba >> 16) & 0xFF));
}


// Lecture de secteurs

int ata_read_sectors(uint32_t lba, uint8_t count, void *buffer) {
    if (count == 0) return -1;

    if (ata_wait_bsy() != 0) return -1;
    ata_select(lba, count);

    // Envoie la commande de lecture
    outb(ATA_COMMAND, ATA_CMD_READ);

    uint16_t *buf = (uint16_t *)buffer;

    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() != 0) return -1;

        // Lit 256 mots (512 octets) depuis le port de données
        for (int i = 0; i < 256; i++) {
            buf[s * 256 + i] = inw(ATA_DATA);
        }
    }

    // Attend la fin de l'opération
    if (ata_wait_bsy() != 0) return -1;
    return 0;
}


// Écriture de secteurs

int ata_write_sectors(uint32_t lba, uint8_t count, const void *buffer) {
    if (count == 0) return -1;

    if (ata_wait_bsy() != 0) return -1;
    ata_select(lba, count);

    // Envoie la commande d'écriture
    outb(ATA_COMMAND, ATA_CMD_WRITE);

    const uint16_t *buf = (const uint16_t *)buffer;

    for (int s = 0; s < count; s++) {
        if (ata_wait_drq() != 0) return -1;

        // Écrit 256 mots (512 octets) vers le port de données
        for (int i = 0; i < 256; i++) {
            outw(ATA_DATA, buf[s * 256 + i]);
        }
    }

    // FLUSH CACHE : force l'écriture physique sur le disque.
    // Sans ça, les données peuvent rester dans le cache du contrôleur.
    
    outb(ATA_COMMAND, ATA_CMD_FLUSH);
    if (ata_wait_bsy() != 0) return -1;

    return 0;
}