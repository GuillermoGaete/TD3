	/*VMA constants*/
__INICIO_PILA = 0x1FFFE000;
__SIZE_PILA = 4K;
__FIN_PILA = __INICIO_PILA + __SIZE_PILA; /*Tamanio de pila 16kb*/

__INICIO_TABLA_DE_DIGITOS = 0x00310000;
__SIZE_TABLA_DE_DIGITOS = 64K;
__FIN_TABLA_DE_DIGITOS = __INICIO_TABLA_DE_DIGITOS + __SIZE_TABLA_DE_DIGITOS;

__BUFFER_TECLADO = 0x60;
__BUFFER_TECLADO_ESTADO = 0x64;

__EXIT_CHARACTER = 0x1F;

__UD_CHARACTER = 0x15;/*Y*/
__DE_CHARACTER = 0x16;/*U*/
__DF_CHARACTER = 0x17;/*I*/
__GP_CHARACTER = 0x18;/*O*/

__DATOS_PROGRAMA = 0x003E0000;

__INICIO_RESET = 0xFFFFFFF0;
__INICIO_ROM = 0xFFFF0000;
__INICIO_RAM = 0x00000000;

MEMORY
{
	ram(rwx) : ORIGIN = __INICIO_RAM, LENGTH = 0xFFFF0000
	rom(rx) : ORIGIN = __INICIO_ROM, LENGTH = 64K
	rom_reset(rx) : ORIGIN = __INICIO_RESET, LENGTH = 0x10
}

SECTIONS
{
	.init 0xFFFF0000:
		{*(.init)} AT >rom /*Todo lo que este en seccione init va a estar en rom*/

	.nucleo 0x00300000:
		{
		__INICIO_NUCLEO_RAM = .; /*Guardamos en __INICIO_NUCLEO_RAM la primer direccion de esta seccion*/
		__INICIO_NUCLEO_ROM = LOADADDR(.nucleo); /*Guardamos en __INICIO_NUCLEO_ROM la LMA desde donde se va a ejecutar la primer vez*/
		__INICIO_COPY_EN_NUCLEO_RAM = .;
		copy.elf(.copy); /*Solamente la que esta en copy.elf*/
		__INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM = .;
		set_idt_handler.elf(.set_idt_handler); /*Solamente la que esta en set_idt_handler.elf*/
		__INICIO_INVALIDATE_EN_NUCLEO_RAM = .;
		invalidate_idt.elf(.invalidate_idt); /*Solamente la que esta en invalidate_idt.elf*/
		*(.nucleo);  /*Voy a colocar todo lo que encuentre en sections nucleo en los archivos de entrada*/
		__FIN_NUCLEO_RAM = .;
		/*Calculo el tamanio de mi seccion rutina como la direccion VMA final menos la inicial*/
		/*Para ser coherente con lo que sucede en nucleo
		__LONGITUD_NUCLEO= __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
		*/
		} AT >rom /*A que lugar de la rom envio esta seccion*/

		.system_tables 0x00100000:
		{
			__SYSTEM_TABLES = .;
			__SYSTEM_TABLES_ROM = LOADADDR(.system_tables);
			*(.idt);
			__SYSTEM_TABLES_END = .;
		} AT>rom

		.teclado_isrs 0x00000000:
		{
			__INICIO_HANDLERS_RAM = .;
			__INICIO_HANDLERS_ROM = LOADADDR(.teclado_isrs);
			__INICIO_HANDLER_MAIN_RAM = .;
			handlers.elf(.handler_main);
			__INICIO_HANDLER_DE_RAM = .;
			handlers.elf(.handler_de);
			__INICIO_HANDLER_UD_RAM = .;
			handlers.elf(.handler_ud);
			__INICIO_HANDLER_DF_RAM = .;
			handlers.elf(.handler_df);
			__INICIO_HANDLER_GP_RAM = .;
			handlers.elf(.handler_gp);
			__INICIO_HANDLER_PF_RAM = .;
			handlers.elf(.handler_pf);
			__INICIO_ISR_TECLADO_RAM = .;
			rutina_teclado_interrupt.elf(.isr_teclado);
			__FIN_HANDLERS_RAM = .;
		} AT >rom

		.reset 0xFFFFFFF0:
			{*(.reset)}AT >rom_reset
}

__SYSTEM_TABLES_LONG = __SYSTEM_TABLES_END - __SYSTEM_TABLES;
__INICIO_COPY_EN_NUCLEO_ROM = __INICIO_NUCLEO_ROM;
__LONGITUD_NUCLEO = __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
__LONGITUD_HANDLERS = __FIN_HANDLERS_RAM - __INICIO_HANDLERS_RAM;
