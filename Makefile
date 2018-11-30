AS = nasm
AS_FLAGS = -f bin

BOOTLOADER_BINARY = bootloader.bin
BINARIES = $(BOOTLOADER_BINARY)

BIN_LST_SUBSTITUTION = .bin=.lst
LISTINGS = $(BINARIES:$(BIN_LST_SUBSTITUTION))

DISK_IMAGE = babyos.flp

all : $(DISK_IMAGE)

$(DISK_IMAGE) : $(BINARIES)
	cp $(BOOTLOADER_BINARY) $(DISK_IMAGE)

%.bin : src/%.asm
	$(AS) $(AS_FLAGS) -o $@ -l $(@:$(BIN_LST_SUBSTITUTION)) $<

run : all
	qemu-system-i386 -drive if=floppy,index=0,file=$(DISK_IMAGE),format=raw

clean :
	rm -f $(BINARIES) $(LISTINGS) $(DISK_IMAGE)
