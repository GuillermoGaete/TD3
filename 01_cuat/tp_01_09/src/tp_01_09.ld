	/*VMA constants*/
__INICIO_PILA = 0x1FFFB000;
__SIZE_PILA = 16K;
__FIN_PILA = __INICIO_PILA + __SIZE_PILA; /*Tamanio de pila 16kb*/

__INICIO_TABLA_DE_DIGITOS = 0x00310000;
__SIZE_TABLA_DE_DIGITOS = 64K;
__FIN_TABLA_DE_DIGITOS = __INICIO_TABLA_DE_DIGITOS + __SIZE_TABLA_DE_DIGITOS;

__INICIO_BUFFER_TECLADO = 0x00410000;
__SIZE_BUFFER_TECLADO_BYTES = 9;
__FIN_BUFFER_TECLADO = __INICIO_BUFFER_TECLADO + __SIZE_BUFFER_TECLADO_BYTES;

__FLAG_TECLADO_READY = __FIN_BUFFER_TECLADO + 1;
__CURRENT_TABLE_INDEX = __FLAG_TECLADO_READY + 64;

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

__DATOS_PROGRAMA = 0x003E0000;
__FLAG_TIMER = __DATOS_PROGRAMA;
__COUNT_TIMER = __FLAG_TIMER + 8;
__ACUM = __COUNT_TIMER + 8;

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

		.tareas 0x00320000:
		{
			__INICIO_TAREAS_RAM = .;
			__INICIO_TAREAS_ROM = LOADADDR(.tareas);
			__INICIO_TAREA_1_RAM = .;
			tarea_1.elf(.tarea_1);
			__INICIO_TAREA_TECLADO_RAM = .;
			tarea_teclado.elf(.tarea_teclado);
			__FIN_TAREAS_RAM = .;
		} AT>rom

		.isrs 0x00000000:
		{
			__INICIO_HANDLERS_RAM = .;
			__INICIO_HANDLERS_ROM = LOADADDR(.isrs);
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
			__INICIO_ISR_TIMER_RAM = .;
			rutina_timer.elf(.isr_timer);
			__FIN_HANDLERS_RAM = .;
		} AT >rom

		.reset 0xFFFFFFF0:
			{*(.reset)}AT >rom_reset
}
__SYSTEM_TABLES_LONG = __SYSTEM_TABLES_END - __SYSTEM_TABLES;
__INICIO_COPY_EN_NUCLEO_ROM = __INICIO_NUCLEO_ROM;
__LONGITUD_NUCLEO = __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
__LONGITUD_TAREAS = __FIN_TAREAS_RAM - __INICIO_TAREAS_RAM;
__LONGITUD_HANDLERS = __FIN_HANDLERS_RAM - __INICIO_HANDLERS_RAM;
