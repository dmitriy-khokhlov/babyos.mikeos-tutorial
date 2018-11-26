AS = nasm
AS_FLAGS = -f bin

BOOTLOADER_BINARY = bootloader.bin
BINARIES = $(BOOTLOADER_BINARY)

DISK_IMAGE = babyos.flp

all : $(DISK_IMAGE)

$(DISK_IMAGE) : $(BINARIES)
	cp $(BOOTLOADER_BINARY) $(DISK_IMAGE)

%.bin : src/%.asm
	$(AS) $(AS_FLAGS) -o $@ $<

run : all
	qemu-system-i386 -fda $(DISK_IMAGE)

clean :
	rm -f $(BINARIES) $(DISK_IMAGE)
