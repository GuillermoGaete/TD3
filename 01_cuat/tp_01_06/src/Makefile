tp_name = tp_01_06
objects = $(tp_name) copy rutina_teclado
elfs = $(tp_name).elf copy.elf rutina_teclado.elf

all:
	for object in $(objects) ; do \
    nasm -f elf32 -o $$object.elf $$object.asm ; \
	done
	ld -z max-page-size=0x1000 -Map $(tp_name).map -m elf_i386 -T $(tp_name).ld $(elfs) -o $(tp_name)_rom.elf
	ld -z max-page-size=0x1000 --oformat=binary -m elf_i386 -T $(tp_name).ld $(elfs) -o ../bin/$(tp_name)_rom.bin
clean:
	rm *.elf *.map *.lst
	rm ../bin/$(tp_name)_rom.bin
