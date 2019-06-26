EXTERN __INICIO_NUCLEO_ROM
EXTERN __INICIO_NUCLEO_RAM
EXTERN __LONGITUD_NUCLEO

EXTERN __INICIO_TAREA_TECLADO_RAM

EXTERN __INICIO_TEXT_TAREA_1_RAM
EXTERN __INICIO_TEXT_TAREA_1_ROM
EXTERN __FIN_TEXT_TAREA_1_RAM
EXTERN __LONGITUD_TEXT_TAREA_1


EXTERN __INICIO_COPY_EN_NUCLEO_ROM
EXTERN __INICIO_COPY_EN_NUCLEO_RAM

EXTERN __INICIO_TAREAS_RAM
EXTERN __INICIO_TAREAS_ROM
EXTERN __LONGITUD_TAREAS

EXTERN __INICIO_DATA_TAREA_1_RAM
EXTERN __INICIO_DATA_TAREA_1_ROM
EXTERN __LONGITUD_DATA_TAREA_1

EXTERN __INICIO_HANDLER_DE_RAM
EXTERN __INICIO_HANDLER_UD_RAM
EXTERN __INICIO_HANDLER_PF_RAM
EXTERN __INICIO_HANDLER_GP_RAM
EXTERN __INICIO_HANDLER_DF_RAM

EXTERN __INICIO_ISR_TECLADO_RAM
EXTERN __INICIO_ISR_TIMER_RAM

EXTERN __INICIO_HANDLERS_RAM
EXTERN __INICIO_HANDLERS_ROM
EXTERN __LONGITUD_HANDLERS

EXTERN __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM

EXTERN __INICIO_PILA
EXTERN __FIN_PILA

EXTERN __SYSTEM_TABLES
EXTERN __SYSTEM_TABLES_ROM
EXTERN __SYSTEM_TABLES_LONG

EXTERN __CURRENT_TABLE_INDEX

EXTERN __PRINT_TEXT

EXTERN _pic_configure
EXTERN _pit_configure

TP_MESSAGE  DB "TP 10: Paginacion basica - Isaac Guillermo Gaete"
LONG_TP_MESSAGE EQU $-TP_MESSAGE

INICIO_PAGE_DIRECTORY EQU 0x1000 ;Las pongo en cualquier lugar
INICIO_PAGE_TABLE_RAM EQU 0x3000 ;Separado FFF
INICIO_PAGE_TABLE_ROM EQU 0x6000
INICIO_PAGE_TABLE_PILA EQU 0x9000

EXTERN __INICIO_PAGINATION_HELPERS_RAM

section .reset
arranque:
USE16
  mov ax,0
  jmp ax
  ;salto a inicio16
  times 16-($-arranque) db 0

section .init
  jmp inicio

inicio:
  %include "init_pci.inc"
  cli       ;Deshabilito interrupciones
  db 0x66            ;Requerido para direcciones mayores
  lgdt  [cs:img_gdtr] ;que 0x00FFFFFFF.
  mov eax,cr0        ;Habiltación bit de modo protegido.
  or eax,1
  mov cr0,eax
  jmp dword cs_sel:modo_proteg

USE32
modo_proteg:
  mov ax,ds_sel
  mov ds,ax
  mov ss,ax ;defino ss y esp dentro del segmento de datos
  mov esp,__FIN_PILA

  ;Copio todo lo que tengo que copiar de rom a RAM
  call _copy_from_rom_to_ram

  ;Borro la memoria, en donde voy a poner mis tablas
  mov edi,INICIO_PAGE_DIRECTORY
  mov ecx,INICIO_PAGE_TABLE_ROM/4
  xor eax,eax

.ciclo_borrado_tablas_paginacion:
  mov [edi],eax
  add edi,4
  dec ecx
  jnz .ciclo_borrado_tablas_paginacion

  ;Lleno las tablas desde a
  ;00000000h
  ;004E0000h

  ;La direccion minima es 0x00000000 = 0000 0000 00.00 0000 0000.0000 0000 0000 [10bits.10bits.12bits]
  ;La direccion maxima es 0x004E0000 = 0000 0000 01.00 1110 0000.0000 0000 0000 [10bits.10bits.12bits]

  ;Primeros 10 bits minimos = xx0000000000 = 000

    ;Para 0x000
    ;Segundos 10 bits minimos = xx00.0000.0000 = 000
    ;Segundos 10 bits maximos = xx11.1111.1111 = 3FF [En decimal son 3*16*16=768]

  ;Primeros 10 bits maximos = xx0000000001 = 001

    ;Para 0x001
    ;Segundos 10 bits minimos = xx00.0000.0000 = 000
    ;Segundos 10 bits maximos = xx00.1110.0000 = 0E0 [En decimal son 16*15=240]

  ;Ahora configuro la paginacion de la ROM
  push dword 0xFFFF0000 ;Direccion lineal inicial
  push dword 0xFFFFFFFF ;Direccion lineal final
  push dword 0xFFFF0000 ;Direcccion fisica inicial
  push dword INICIO_PAGE_TABLE_ROM
  push dword INICIO_PAGE_DIRECTORY
  call __INICIO_PAGINATION_HELPERS_RAM
  pop eax
  pop eax
  pop eax
  pop eax
  pop eax

  push dword 0x00000000 ;Direccion lineal inicial
  push dword 0x004E0000 ;Direccion lineal final
  push dword 0x00000000 ;Direcccion fisica inicial
  push dword INICIO_PAGE_TABLE_RAM ;En que lugar esta la tabla para esta region
  push dword INICIO_PAGE_DIRECTORY
  call __INICIO_PAGINATION_HELPERS_RAM
  pop eax
  pop eax
  pop eax
  pop eax
  pop eax

  push dword __INICIO_PILA ;Direccion lineal inicial
  push dword __FIN_PILA ;Direccion lineal inicial
  push dword __INICIO_PILA ;Direccion lineal inicial
  push dword INICIO_PAGE_TABLE_PILA ;En que lugar esta la tabla para esta region
  push dword INICIO_PAGE_DIRECTORY
  call __INICIO_PAGINATION_HELPERS_RAM
  pop eax
  pop eax
  pop eax
  pop eax
  pop eax

  mov eax,INICIO_PAGE_DIRECTORY
  mov cr3,eax

  ;Activo la paginacion con cr0
  mov eax,cr0
  or eax,0x80000000
  mov cr0,eax

  xchg bx,bx
  mov esp,__FIN_PILA

  xor edx,edx
  mov [__CURRENT_TABLE_INDEX],edx

  ;Antes de cargar la idt, lo que tengo que hacer es escribir en cada vector los
  ;handlers que corresponden, para esto hago
  call _set_idt_handlers
  ;Cargo idtr
  lidt  [img_idtr]

  ;Configuro los pics
  call _pic_configure
  ;Cofiguro el pit
  call _pit_configure
  ;Configuro las irq
  call config_irq
  ;A partir de este momento estan habilitadas las interrupciones
  sti

  push  dword TP_MESSAGE
  push  dword LONG_TP_MESSAGE
  push 0x0  ;Fila
  call __PRINT_TEXT
  pop eax
  pop eax
  pop eax

main:
  call __INICIO_TEXT_TAREA_1_RAM
  jmp main

config_irq:
  ;Le digo al pic que este habilitada la interrupcion del teclado
  mov al,0xFC;Habilito la irq 1 del teclado
  out 0x21,al
  ret

gdt:
  db 0,0,0,0,0,0,0,0  ;Descriptor nulo
ds_sel    equ $-gdt
  db 0xFF, 0xFF, 0, 0, 0, 0x92, 0xCF, 0
cs_sel    equ $-gdt
  db 0xFF, 0xFF, 0, 0, 0, 0x9A, 0xCF, 0

long_gdt equ $-gdt

img_gdtr:
  dw long_gdt-1
  dd gdt

img_idtr:
  dw long_idt-1
  dd idt

section .idt
idt:
  dw 0x00 ;Pisar
  dw cs_sel
  db 0x0
  db 0x8F
  dw 0x00 ;Pisar

  TIMES 0x05 dq 0;

  dw 0x00 ;Pisar
  dw cs_sel
  db 0x0
  db 0x8F
  dw 0x00 ;Pisar

  dq 0;

  dw 0x00 ;Pisar
  dw cs_sel
  db 0x0
  db 0x8F
  dw 0x00 ;Pisar

  TIMES 0x04 dq 0

  dw 0x00 ;Pisar
  dw cs_sel
  db 0x0
  db 0x8F
  dw 0x00 ;Pisar

  dw 0x00 ;Pisar con handler del Doble Fault
  dw cs_sel
  db 0x0
  db 0x8F
  dw 0x00 ;Pisar

  TIMES 0x11 dq 0

  dw 0x00 ;Pisar con handler teclado
  dw cs_sel
  db 0x0
  db 0x8E
  dw 0x00 ;Pisar

  dw 0x00 ;Pisar con handler teclado
  dw cs_sel
  db 0x0
  db 0x8E
  dw 0x00 ;Pisar

  long_idt equ $-idt


section .init
_copy_from_rom_to_ram:
push dword __INICIO_NUCLEO_ROM ;fuente
push dword __INICIO_NUCLEO_RAM ;destino
push dword __LONGITUD_NUCLEO ;longitud
;Voy a autocopiar la seccion nucleo en RAM, al hacer eso tambien copio lo que esta en
call __INICIO_COPY_EN_NUCLEO_ROM
pop eax
pop eax
pop eax

push dword __SYSTEM_TABLES_ROM ;fuente
push dword __SYSTEM_TABLES ;destino
push dword __SYSTEM_TABLES_LONG ;longitud
;Copio la idt que esta en rom, para poder cargarle los handlers
call __INICIO_COPY_EN_NUCLEO_RAM
pop eax
pop eax
pop eax

;Copio los handlers a las posiciones que corresponden
push dword __INICIO_HANDLERS_ROM ;fuente
push dword __INICIO_HANDLERS_RAM ;destino
push dword __LONGITUD_HANDLERS ;longitud
;Copio los handlers a las posiciones que corresponden
call __INICIO_COPY_EN_NUCLEO_RAM
pop eax
pop eax
pop eax

push dword __INICIO_TAREAS_ROM ;fuente
push dword __INICIO_TAREAS_RAM ;destino
push dword __LONGITUD_TAREAS ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
pop eax
pop eax
pop eax

push dword __INICIO_TEXT_TAREA_1_ROM ;fuente
push dword __INICIO_TEXT_TAREA_1_RAM ;destino
push dword __LONGITUD_TEXT_TAREA_1 ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
pop eax
pop eax
pop eax

push dword __INICIO_DATA_TAREA_1_ROM ;fuente
push dword __INICIO_DATA_TAREA_1_RAM ;destino
push dword __LONGITUD_DATA_TAREA_1 ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
pop eax
pop eax
pop eax

ret

_set_idt_handlers:
push dword __INICIO_HANDLER_DE_RAM
push dword 0
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_HANDLER_UD_RAM
push dword 6
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_HANDLER_DF_RAM
push dword 8
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_HANDLER_GP_RAM
push dword 13
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_HANDLER_PF_RAM
push dword 14
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_ISR_TIMER_RAM ;Por ahora el timer lo mando a la isr del teclado
push dword 32
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

push dword __INICIO_ISR_TECLADO_RAM ;Por ahora el timer lo mando a la isr del teclado
push dword 33
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax

ret

set_rom_pagination:

pushad
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx

is_identity_map:;init eax, finish ebx

mov eax,0xFFFF0000
mov ebx,0xFFFFFFFF
mov ecx,ebx
sub ecx,eax
add ecx,1

mov eax,1 ;Si tengo menos de 4096 direcciones entonces tengo una sola pagina
cmp ecx,4096
jle finished_number_page_compute

xor eax,eax
xor edx,edx
mov eax,ecx
mov ecx,4096

div ecx
cmp edx,0
je finished_number_page_compute
add eax,1

finished_number_page_compute:
mov edx,eax ;En edx tengo la cantidad de paginas
push edx ;Lo pusheo ya que lo voy a usar mas adelante
;Voy a computar la cantidad de directorios
;El maximo valor es 1024 porque son 10 bits
mov ecx,edx ;Lo muevo a ecx porque edx se usa en la division
mov eax,1 ;Si tengo menos de 1024 direcciones entonces tengo una entrada en el directorio
cmp ecx,1024
jle finished_number_directory_compute

xor eax,eax
xor edx,edx
mov eax,ecx
mov ecx,1024

div ecx
cmp edx,0
je finished_number_directory_compute
add eax,1

finished_number_directory_compute:
mov edx,eax ;En edx tengo la cantidad de paginas

mov eax,0xFFFF0000
mov ebx,0
ciclo_directorio:
  push eax ;Guardo la direccion
  push ebx  ;Guardo el indice actual

  ror eax,22;Dejo los 10msb en la parte baja
  and eax,0x3FF;And con 0x1111111111

  mov ecx,INICIO_PAGE_DIRECTORY
  rol eax,2;Multiplico por 4

  add ecx,eax ;Tengo a direccion a donde quiero escribir
  mov eax,0x400
  mul ebx

  mov ebx,INICIO_PAGE_TABLE_ROM
  add ebx,eax
  add ebx,0x3

  mov [ecx],ebx

  pop ebx ;Saco el indice actual
  pop eax ;Saco la direccion despues de operar con ella
  add eax,0x1000000 ;La aumento la direccion 0x1000000 que es el maximo de un directorio
  add ebx,1;La aumento en el indice 1

  cmp ebx,edx
  jl ciclo_directorio


pop edx ;Cantidad de paginas

mov eax,0xFFFF0000
ror eax,12;Dejo los 10msb en la parte baja
and eax,0x3FF;And con 0x1111111111

rol eax,2;Lo multiplico por 4

add eax,INICIO_PAGE_TABLE_ROM
mov ebx,0

mov ecx,0xFFFF0000+0x3
ciclo_llenado_page_table:
  mov [eax],ecx
  add eax,4 ;Me muevo al proximo offset que es 4 bytes(Es un offset en la tabla de paginas)
  add ecx,0x1000;la siguiente pagina esta 4kb adelante en direcciones fisicas
  add ebx,1

  cmp ebx,edx
  jl ciclo_llenado_page_table

is_not_identity_map:
popad
ret

ecx_plus:
  add ecx,1
  ret
