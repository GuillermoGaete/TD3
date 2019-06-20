/*VMA constants*/
__INICIO_PILA = 0x1FFFB000;
__SIZE_PILA = 16K;
__FIN_PILA = __INICIO_PILA + __SIZE_PILA; /*Tamanio de pila 16kb*/
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

	.rutinas 0x00000000:
		{
		__INICIO_RUTINAS_RAM = .; /*Guardamos en __INICIO_RUTINAS_RAM la primer direccion de esta seccion*/
		__INICIO_RUTINAS_ROM = LOADADDR(.rutinas); /*Guardamos en __INICIO_RUTINAS_ROM la LMA desde donde se va a ejecutar la primer vez*/
		__INICIO_COPY_EN_RUTINAS_ROM = __INICIO_RUTINAS_ROM;
		__INICIO_COPY_EN_RUTINAS_RAM = .;
		copy.elf(.copy); /*Solamente la que esta en copy.elf*/
		*(.rutinas);  /*Voy a colocar todo lo que encuentre en sections rutinas en los asm*/
		__LONGITUD_NUCLEO = . - __INICIO_RUTINAS_RAM;
		} AT >rom /**/

	.nucleo 0x00300000:
		{
			__INICIO_NUCLEO_RAM = .;
			__INICIO_NUCLEO_ROM = LOADADDR(.nucleo);
			*(.nucleo);
			__LONGITUD_RUTINAS = 0x00000005;
		} AT >rom

	.reset 0xFFFFFFF0:
		{*(.reset)}AT >rom_reset
}
