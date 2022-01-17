FLOPPYNAME=floppy.img
CDNAME=floppy.iso
NETBOOTNAME=floppy.nb

VOLUMENAME=BOOTSELFIE
KERNEL_OFFSET:=0x0
PWLEN:=$(shell stat -L -c %s password.raw)

NASM=nasm -f bin -DPWLEN=$(PWLEN) -D_KERNEL_OFFSET=$(KERNEL_OFFSET)

.PHONY: cdrom floppy netboot

all: floppy cdrom

cdrom: $(CDNAME)
floppy: $(FLOPPYNAME)
netboot: $(NETBOOTNAME)
clean:
	-rm image.com
	-rm image.raw image.pal
	-rm $(FLOPPYNAME)
	-rm $(CDNAME)
	-rm $(NETBOOTNAME)
	-rm -rf garbage/


$(NETBOOTNAME): $(FLOPPYNAME)
	-mknbi-dos --output=$(NETBOOTNAME) $(FLOPPYNAME)

$(CDNAME): $(FLOPPYNAME)
	-mkdir garbage garbage/boot && cp $(FLOPPYNAME) garbage/boot/image.img \
	&& cd garbage && mkisofs -r -V $(VOLUMENAME) -b boot/image.img -c \
	boot/image.cat -o ../$(CDNAME) . && cd .. && rm -rf garbage/

$(FLOPPYNAME): image.com
	$(NASM) floppy_jspenguin.asm -o $(FLOPPYNAME)

image.com: image.asm image.raw image.pal prompt.txt
	$(NASM) image.asm -o image.com

image.raw image.pal &: tools/convert.py image.jpg password.raw
	tools/convert.py image.jpg password.raw
