	/*VMA constants*/
__INICIO_PILA = 0x1FFFB000;
__SIZE_PILA = 4K;
__FIN_PILA = __INICIO_PILA + __SIZE_PILA; /*Tamanio de pila 16kb*/

__INICIO_PILA_TAREA_1 = 0x00413000;/*1FFFB000*/
__SIZE_PILA_TAREA_1 = 4K;
__FIN_PILA_TAREA_1 = __INICIO_PILA_TAREA_1 + __SIZE_PILA_TAREA_1; /*Tamanio de pila 16kb*/

__INICIO_TABLA_DE_DIGITOS = 0x00410000;
__SIZE_TABLA_DE_DIGITOS = 4K;
__FIN_TABLA_DE_DIGITOS = __INICIO_TABLA_DE_DIGITOS + __SIZE_TABLA_DE_DIGITOS;

__BUFFER_TECLADO = 0x60;
__BUFFER_TECLADO_ESTADO = 0x64;

__EXIT_CHARACTER = 0x1F;

__UD_CHARACTER = 0x15;/*Y*/
__DE_CHARACTER = 0x16;/*U*/
__DF_CHARACTER = 0x17;/*I*/
__GP_CHARACTER = 0x18;/*O*/
__ENTER_CHARACTER = 0x1C;/*ENTER*/

__1_CHARACTER = 0x02;/*1*/
__0_CHARACTER = 0x0B;/*0*/

__F_CHARACTER = 0x21;/*F*/
__E_CHARACTER = 0x12;/*E*/
__D_CHARACTER = 0x20;/*D*/
__C_CHARACTER = 0x2E;/*C*/
__B_CHARACTER = 0x30;/*B*/
__A_CHARACTER = 0x1E;/*A*/

__ENTER_CHARACTER = 0x1C;/*ENTER*/

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

	.nucleo 0x00400000:
		{
		__INICIO_NUCLEO_RAM = .; /*Guardamos en __INICIO_NUCLEO_RAM la primer direccion de esta seccion*/
		__INICIO_NUCLEO_ROM = LOADADDR(.nucleo); /*Guardamos en __INICIO_NUCLEO_ROM la LMA desde donde se va a ejecutar la primer vez*/
		__INICIO_COPY_EN_NUCLEO_RAM = .;
		copy.elf(.copy); /*Solamente la que esta en copy.elf*/
		__INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM = .;
		set_idt_handler.elf(.set_idt_handler); /*Solamente la que esta en set_idt_handler.elf*/
		__INICIO_INVALIDATE_EN_NUCLEO_RAM = .;
		invalidate_idt.elf(.invalidate_idt); /*Solamente la que esta en invalidate_idt.elf*/
		pagination_helpers.elf(.text);
		video_helpers.elf(.text);
		tarea_status_bar.elf(.text);
		tarea_teclado.elf(.text);
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

		.pages_tables 0x00110000:
		{
			__PAGE_TABLES = .;
			__PAGE_TABLES_DATOS = .;
			__PAGE_TABLES_DATOS_ROM = LOADADDR(.pages_tables);
			pages_tables.elf(.datos);
			__PAGE_TABLES_DATOS_END = .;
			pages_tables.elf(.bss);
			__PAGE_TABLES_END = .;
		} AT>rom

		.text_tarea_1 0x00510000:
		{
			__INICIO_TEXT_TAREA_1_RAM = .;
			__INICIO_TEXT_TAREA_1_ROM = LOADADDR(.text_tarea_1);
			tarea_1.elf(.text);
			__FIN_TEXT_TAREA_1_RAM = .;
		} AT>rom

		.datos 0x004E0000:
		{
			__INICIO_DATA_RAM = .;
			__INICIO_DATOS_RAM = .;
			__INICIO_DATA_ROM = LOADADDR(.datos);
			rutina_timer.elf(.data);
			tarea_status_bar.elf(.data);
			handlers.elf(.data);
			rutina_teclado_interrupt.elf(.data);
			__FIN_DATA_RAM = .;
			rutina_timer.elf(.bss);
			pagination_helpers.elf(.bss);
			tarea_status_bar.elf(.bss);
			handlers.elf(.bss);
			__INICIO_TECLADO_ = . ;
			rutina_teclado_interrupt.elf(.bss);
			__FIN_DATOS_RAM = .;
		} AT>rom

		.bss_tarea_1 0x00511000:
		{
			__INICIO_BSS_TAREA_1 = . ;
			tarea_1.elf(.bss);
			__FIN_BSS_TAREA_1 = . ;
		} AT>rom

		.data_tarea_1 0x00512000:
		{
			__INICIO_DATA_TAREA_1_RAM = .;
			__INICIO_DATA_TAREA_1_ROM = LOADADDR(.data_tarea_1);
			tarea_1.elf(.data);
			__FIN_DATA_TAREA_1_RAM = .;
		} AT>rom

		.isrs 0x00000000:
		{
			__INICIO_ISRS_RAM = .;
			__INICIO_ISRS_ROM = LOADADDR(.isrs);
			handlers.elf(.text);
			__INICIO_ISR_TECLADO_RAM = .;
			rutina_teclado_interrupt.elf(.isr_teclado);
			rutina_timer.elf(.text);
			__FIN_ISRS_RAM = .;
		} AT >rom

		.reset 0xFFFFFFF0:
			{*(.reset)}AT >rom_reset
}
__SYSTEM_TABLES_LONG = __SYSTEM_TABLES_END - __SYSTEM_TABLES;
__INICIO_COPY_EN_NUCLEO_ROM = __INICIO_NUCLEO_ROM;
__LONGITUD_NUCLEO = __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
__LONGITUD_ISRS = __FIN_ISRS_RAM - __INICIO_ISRS_RAM;
__LONGITUD_TEXT_TAREA_1 = __FIN_TEXT_TAREA_1_RAM - __INICIO_TEXT_TAREA_1_RAM;
__LONGITUD_DATA_TAREA_1 = __FIN_DATA_TAREA_1_RAM - __INICIO_DATA_TAREA_1_RAM;
__LONGITUD_DATA = __FIN_DATA_RAM - __INICIO_DATA_RAM;
__LONGITUD_DATA_PAGE_TABLES =  __PAGE_TABLES_DATOS_END - __PAGE_TABLES_DATOS;
