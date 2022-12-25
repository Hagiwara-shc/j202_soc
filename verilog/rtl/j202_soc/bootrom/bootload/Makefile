ARCH    = sh-elf
ADDNAME = $(ARCH)-

AR      = $(ADDNAME)ar
AS      = $(ADDNAME)as
CC      = $(ADDNAME)gcc
LD      = $(ADDNAME)ld
NM      = $(ADDNAME)nm
OBJCOPY = $(ADDNAME)objcopy
OBJDUMP = $(ADDNAME)objdump
RANLIB  = $(ADDNAME)ranlib
STRIP   = $(ADDNAME)strip

BuCVA9_DIR = ../../J22/BuCVA9

OBJS  = vector.o startup.o main.o
OBJS += lib.o serial.o xmodem.o elf.o

TARGET = kzload

CFLAGS = -Wall -m2 -nostdinc -nostdlib -fno-builtin
CFLAGS += -I.
CFLAGS += -g
CFLAGS += -O
CFLAGS += -DKZLOAD

LFLAGS = -static -T ld.scr -L.

.SUFFIXES: .c .o
.SUFFIXES: .s .o

all :		$(BuCVA9_DIR)/test.hex

$(BuCVA9_DIR)/test.hex : $(TARGET)
	$(OBJCOPY) -O ihex $(TARGET).elf $(TARGET).hex
	$(OBJCOPY) -O srec --srec-forceS3 $(TARGET).elf $(TARGET).srec
	./srec2mem.py $(TARGET).srec > $(TARGET).mem
	./srec2case.py $(TARGET).srec > $(TARGET).v
	$(OBJDUMP) -d $(TARGET).elf > $(TARGET).lis
	#$(BuCVA9_DIR)/cnvihex.pl $(TARGET).hex > $@

$(TARGET) :	$(OBJS)
		$(CC) $(OBJS) -o $(TARGET) $(CFLAGS) $(LFLAGS)
		cp $(TARGET) $(TARGET).elf
		$(STRIP) $(TARGET)

.c.o :		$<
		$(CC) -c $(CFLAGS) $<

.s.o :		$<
		$(CC) -c $(CFLAGS) $<

$(TARGET).mot :	$(TARGET)
		$(OBJCOPY) -O srec $(TARGET) $(TARGET).mot

image :		$(TARGET).mot

clean :
		rm -f $(OBJS) $(TARGET) $(TARGET).*
