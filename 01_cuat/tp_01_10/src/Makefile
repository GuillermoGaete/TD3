tp_name = tp_01_10
objects = $(tp_name) tarea_status_bar video_helpers pagination_helpers tarea_teclado tarea_1 copy rutina_timer rutina_teclado_interrupt set_idt_handler invalidate_idt handlers pic pit
elfs = $(tp_name).elf tarea_status_bar.elf video_helpers.elf pagination_helpers.elf tarea_teclado.elf tarea_1.elf copy.elf rutina_timer.elf rutina_teclado_interrupt.elf set_idt_handler.elf invalidate_idt.elf handlers.elf pic.elf pit.elf

all:
	for object in $(objects) ; do \
		nasm -f elf32 -o $$object.elf $$object.asm ; \
	done
	ld -z max-page-size=0x1000 -Map $(tp_name).map -m elf_i386 -T $(tp_name).ld $(elfs) -o $(tp_name)_rom.elf
	ld -z max-page-size=0x1000 --oformat=binary -m elf_i386 -T $(tp_name).ld $(elfs) -o ../bin/$(tp_name)_rom.bin
clean:
	rm *.elf *.map *.log
	rm ../bin/$(tp_name)_rom.bin
