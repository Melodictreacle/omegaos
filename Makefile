# ── Toolchain ───────────────────────────────────────────────
ASM     := nasm
CC      := gcc
LD      := ld
QEMU    := qemu-system-i386

# ── Directories ─────────────────────────────────────────────
SRC     := src
BOOT    := $(SRC)/bootloader
KERNEL  := $(SRC)/kernel
BUILD   := build

# ── Flags ───────────────────────────────────────────────────
CFLAGS  := -m32 -ffreestanding -fno-pie -fno-stack-protector -nostdlib -Wall -Wextra
LDFLAGS := -m elf_i386 -T linker.ld

# ── Outputs ─────────────────────────────────────────────────
BOOT_BIN   := $(BUILD)/boot.bin
STAGE2_BIN := $(BUILD)/stage2.bin
KERNEL_BIN := $(BUILD)/kernel.bin
IMG        := $(BUILD)/main_floppy.img

# C sources in the kernel dir → object files in build/
C_SOURCES := $(wildcard $(KERNEL)/*.c)
C_OBJECTS := $(patsubst $(KERNEL)/%.c,$(BUILD)/%.o,$(C_SOURCES))

# ── Default target ──────────────────────────────────────────
all: $(IMG)

# ── Bootloader (stage 1): raw 512-byte boot sector ──────────
$(BOOT_BIN): $(BOOT)/boot.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

# ── Bootloader (stage 2): raw binary ────────────────────────
$(STAGE2_BIN): $(BOOT)/stage2.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

# ── Kernel entry stub: ELF object, linked with C ────────────
$(BUILD)/kernel_entry.o: $(KERNEL)/kernel_entry.asm | $(BUILD)
	$(ASM) -f elf32 $< -o $@

# ── C source → ELF object ───────────────────────────────────
$(BUILD)/%.o: $(KERNEL)/%.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

# ── Link kernel: entry stub MUST come first ─────────────────
$(KERNEL_BIN): $(BUILD)/kernel_entry.o $(C_OBJECTS)
	$(LD) $(LDFLAGS) -o $@ $^ --oformat binary

# ── Assemble final floppy image ─────────────────────────────
# boot sector first, then stage2, then kernel, laid end to end
$(IMG): $(BOOT_BIN) $(STAGE2_BIN) $(KERNEL_BIN)
	cat $(BOOT_BIN) $(STAGE2_BIN) $(KERNEL_BIN) > $@

# ── Build dir ───────────────────────────────────────────────
$(BUILD):
	mkdir -p $(BUILD)

# ── Run in QEMU ─────────────────────────────────────────────
run: $(IMG)
	$(QEMU) -drive format=raw,file=$(IMG),if=floppy

# ── Debug: wait for GDB on :1234, freeze CPU at reset ───────
debug: $(IMG)
	$(QEMU) -drive format=raw,file=$(IMG),if=floppy -s -S

# ── Clean ───────────────────────────────────────────────────
clean:
	rm -rf $(BUILD)

.PHONY: all run debug clean