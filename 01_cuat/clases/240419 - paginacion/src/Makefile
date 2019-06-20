all:
	nasm -f elf32 -o tp_01_05.elf ejercicio.asm -l ejercicio.lst
	nasm -f elf32 -o copy.elf copy.asm
	nasm -f elf32 -o pic.elf pic.asm
	nasm -f elf32 -o pit.elf pit.asm
	ld -z max-page-size=0x1000 -Map tp_01_05.map -m elf_i386 -T ejercicio.ld tp_01_05.elf copy.elf pic.elf pit.elf -o tp_01_05_rom.elf
	ld -z max-page-size=0x1000 --oformat=binary -m elf_i386 -T ejercicio.ld tp_01_05.elf copy.elf pic.elf pit.elf -o ../bin/paginacion.bin
clean:
	rm *.elf *.map
	rm ../bin/tp_01_05_rom.bin
