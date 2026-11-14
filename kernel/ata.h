#ifndef ATA_H
#define ATA_H

#include <stdint.h>

// Choisis le disque : 0 = master (os.img), 1 = slave (disk.img)
#define ATA_DRIVE_SLAVE 1

// Lit "count" secteurs à partir de "lba" dans "buffer"
// Retourne 0 si succès, -1 si erreur
int ata_read_sectors(uint32_t lba, uint8_t count, void *buffer);

// Écrit "count" secteurs depuis "buffer" à partir de "lba"
// Retourne 0 si succès, -1 si erreur.
int ata_write_sectors(uint32_t lba, uint8_t count, const void *buffer);

#endif