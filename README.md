# OmegaOS Bootloader

A 16-bit Real Mode Stage 1 bootloader written in x86 Assembly (`nasm`). It initializes the system stack, reads subsequent sectors from disk to memory, and transfers control to a Stage 2 bootloader / kernel.

## Overview of Operation

When the computer boots, the BIOS performs POST (Power-On Self-Test) and loads the first sector (LBA 0, 512 bytes) of the bootable media into memory at address `0x7C00`. The CPU then begins execution there.

Here is a step-by-step breakdown of what `src/bootloader/boot.asm` does:

1. **Sets Origin**: Sets origin to `0x7C00` (`org 0x7c00`) so all memory references are offset correctly.
2. **Saves Boot Drive**: The BIOS passes the boot drive number in the `DL` register. The bootloader immediately saves it into memory (`[BOOT_DRIVE]`).
3. **Initializes the Stack**: Sets up a 16-bit stack starting at `0x7C00` (growing downwards):
   - `bp` (Base Pointer) = `0x7C00`
   - `sp` (Stack Pointer) = `0x7C00`
4. **Loads Stage 2 from Disk**:
   - Calls the `disk_load` routine to read **4 sectors** starting from **Sector 2** (LBA 1) of the boot drive.
   - The destination address is defined as `STAGE2_OFFSET` (`0x8000`).
   - Uses BIOS Interrupt `0x13`, Service `0x02` (Read Sectors).
   - If an error occurs, it resets the disk controller (Service `0x00`) and retries up to **3 times**.
   - If all retries fail, it prints "Disk error!" and halts execution (`jmp $`).
5. **Prints Success Message**: Prints `"Stage1 OK\r\n"` to the screen using BIOS Interrupt `0x10`, Service `0x0E` (Teletype Output).
6. **Jumps to Stage 2**: Performs a jump (`jmp STAGE2_OFFSET`) to hand execution off to the newly loaded Stage 2 code at `0x8000`.
7. **Boot Signature**: Pads the remaining bytes of the sector with `0` up to 510 bytes, followed by the magic boot signature `0xAA55` at bytes 511-512 to mark the sector as bootable.

---

## File Structure

- `src/bootloader/boot.asm` - The Stage 1 assembly source code.
- `Makefile` - Configuration to assemble the code and package it as a floppy image.
- `.gitignore` - Ignores generated build artifacts (`*.bin`, `*.img`).

---

## Building and Running

### Prerequisites
- [NASM](https://www.nasm.us/) (Netwide Assembler)
- GNU Make

### Build Steps

To compile the bootloader and create a bootable floppy disk image:

```bash
make
```

This will run the following build steps:
1. Compile the assembly file into a flat binary file:
   ```bash
   nasm src/bootloader/boot.asm -f bin -o build/boot.bin
   ```
2. Copy the binary to a floppy disk image file and size it to a standard 1.44 MB floppy:
   ```bash
   cp build/boot.bin build/main_floppy.img
   truncate -s 1440k build/main_floppy.img
   ```

The output image `build/main_floppy.img` can be run using an emulator like QEMU:
```bash
qemu-system-x86_64 -fda build/main_floppy.img
```
