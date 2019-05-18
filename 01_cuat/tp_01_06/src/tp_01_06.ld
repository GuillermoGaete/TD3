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
		__INICIO_NUCLEO_ROM = LOADADDR(.nucleo); /*Guardamos en __INICIO_NUCLE_ROM la LMA desde donde se va a ejecutar la primer vez*/
		__INICIO_COPY_EN_NUCLEO_RAM = .;
		copy.elf(.copy); /*Solamente la que esta en copy.elf*/
		*(.rutinas);  /*Voy a colocar todo lo que encuentre en sections rutinas en los archivos de entrada*/
		__FIN_NUCLEO_RAM = .;
		/*Calculo el tamanio de mi seccion rutina como la direccion VMA final menos la inicial*/
		/*Para ser coherente con lo que sucede en nucleo
		__LONGITUD_NUCLEO = __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
		*/
		} AT >rom /*A que lugar de la rom envio esta seccion*/

		.rutina_teclado 0x00000000:
		{
			__INICIO_RUTINA_TECLADO_RAM = .;
			__INICIO_RUTINA_TECLADO_ROM = LOADADDR(.rutina_teclado);
			*(.rutina_teclado);
			__FIN_RUTINA_TECLADO_RAM = .;
		} AT >rom

		.reset 0xFFFFFFF0:
			{*(.reset)}AT >rom_reset
}
__INICIO_COPY_EN_NUCLEO_ROM = __INICIO_NUCLEO_ROM;
__LONGITUD_NUCLEO = __FIN_NUCLEO_RAM - __INICIO_NUCLEO_RAM;
__LONGITUD_RUTINA_TECLADO = __FIN_RUTINA_TECLADO_RAM - __INICIO_RUTINA_TECLADO_RAM;
