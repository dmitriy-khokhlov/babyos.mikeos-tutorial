ASM = nasm
ASM_FLAGS = -f bin

BOOTLOADER_BINARY = bootloader.bin
BINARIES = $(BOOTLOADER_BINARY)

DISK_IMAGES_DIR = disk_images
DISK_IMAGE = $(DISK_IMAGES_DIR)/babyos.flp

all : $(DISK_IMAGE)

$(DISK_IMAGE) : $(BINARIES)
	dd status=noxfer conv=notrunc if=$(BOOTLOADER_BINARY) of=$@

%.bin : src/%.asm
	$(ASM) $(ASM_FLAGS) -o $@ $<

run : all
	qemu-system-i386 -fda $(DISK_IMAGE)

clean :
	rm -f $(BINARIES)
