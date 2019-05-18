tp_name = tp_01_05
all:
	nasm -f elf32 -o $(tp_name).elf $(tp_name).asm
	nasm -f elf32 -o copy.elf copy.asm
	ld -z max-page-size=0x1000 -Map $(tp_name).map -m elf_i386 -T $(tp_name).ld $(tp_name).elf copy.elf -o $(tp_name)_rom.elf
	ld -z max-page-size=0x1000 --oformat=binary -m elf_i386 -T $(tp_name).ld $(tp_name).elf copy.elf -o ../bin/$(tp_name)_rom.bin
clean:
	rm *.elf *.map *.lst
	rm ../bin/$(tp_name)_rom.bin
