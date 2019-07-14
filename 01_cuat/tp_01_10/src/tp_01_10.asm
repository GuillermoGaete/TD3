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

EXTERN __HANDLER_DE
EXTERN __HANDLER_GP
EXTERN __HANDLER_PF
EXTERN __HANDLER_UD
EXTERN __HANDLER_DF

EXTERN __INICIO_ISR_TECLADO_RAM
EXTERN __ISR_TIMER

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

EXTERN __INICIO_DATA_ROM
EXTERN __INICIO_DATA_RAM
EXTERN __LONGITUD_DATA

EXTERN TAREA_STATUS_BAR

EXTERN _pic_configure
EXTERN _pit_configure

TP_ERROR  DB "Generando error de paginacion en archivo: tp_01_10.asm:203"
LONG_TP_ERROR EQU $-TP_ERROR

TP_MESSAGE  DB "TP 10: Paginacion basica - Isaac Guillermo Gaete"
LONG_TP_MESSAGE EQU $-TP_MESSAGE

INICIO_PAGE_DIRECTORY EQU 0x1000 ;Las pongo en cualquier lugar
INICIO_PAGE_TABLE_RAM EQU 0x3000 ;Separado FFF
INICIO_PAGE_TABLE_ROM EQU 0x6000
INICIO_PAGE_TABLE_PILA EQU 0x9000

EXTERN __SET_PAGINATION_STRUCTURE

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
  call __SET_PAGINATION_STRUCTURE
  times 5 pop eax

  push dword 0x00000000 ;Direccion lineal inicial
  push dword 0x004E0000 ;Direccion lineal final
  push dword 0x00000000 ;Direcccion fisica inicial
  push dword INICIO_PAGE_TABLE_RAM ;En que lugar esta la tabla para esta region
  push dword INICIO_PAGE_DIRECTORY
  call __SET_PAGINATION_STRUCTURE
  times 5 pop eax

  push dword __INICIO_PILA ;Direccion lineal inicial
  push dword __FIN_PILA ;Direccion lineal inicial
  push dword __INICIO_PILA ;Direccion lineal inicial
  push dword INICIO_PAGE_TABLE_PILA ;En que lugar esta la tabla para esta region
  push dword INICIO_PAGE_DIRECTORY
  call __SET_PAGINATION_STRUCTURE
  times 5 pop eax

  mov eax,INICIO_PAGE_DIRECTORY
  mov cr3,eax

  ;Activo la paginacion con cr0
  mov eax,cr0
  or eax,0x80000000
  mov cr0,eax

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
  push 0  ;Fila
  push 0
  call __PRINT_TEXT
  times 4 pop eax

  push  dword TP_ERROR
  push  dword LONG_TP_ERROR
  push 1  ;Fila
  push 0
  call __PRINT_TEXT
  times 4 pop eax

main:
  call TAREA_STATUS_BAR

  ;La direccion no esta paginada.
  mov [0x00800000],EAX

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
times 3 pop eax

push dword __INICIO_DATA_ROM ;fuente
push dword __INICIO_DATA_RAM ;destino
push dword __LONGITUD_DATA ;longitud
;Copio todos los datos inicializados a sus VMAs en ram
call __INICIO_COPY_EN_NUCLEO_ROM
times 3 pop eax

push dword __SYSTEM_TABLES_ROM ;fuente
push dword __SYSTEM_TABLES ;destino
push dword __SYSTEM_TABLES_LONG ;longitud
;Copio la idt que esta en rom, para poder cargarle los handlers
call __INICIO_COPY_EN_NUCLEO_RAM
times 3 pop eax

;Copio los handlers a las posiciones que corresponden
push dword __INICIO_HANDLERS_ROM ;fuente
push dword __INICIO_HANDLERS_RAM ;destino
push dword __LONGITUD_HANDLERS ;longitud
;Copio los handlers a las posiciones que corresponden
call __INICIO_COPY_EN_NUCLEO_RAM
times 3 pop eax

push dword __INICIO_TAREAS_ROM ;fuente
push dword __INICIO_TAREAS_RAM ;destino
push dword __LONGITUD_TAREAS ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
times 3 pop eax

push dword __INICIO_TEXT_TAREA_1_ROM ;fuente
push dword __INICIO_TEXT_TAREA_1_RAM ;destino
push dword __LONGITUD_TEXT_TAREA_1 ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
times 3 pop eax

push dword __INICIO_DATA_TAREA_1_ROM ;fuente
push dword __INICIO_DATA_TAREA_1_RAM ;destino
push dword __LONGITUD_DATA_TAREA_1 ;longitud
call __INICIO_COPY_EN_NUCLEO_RAM
times 3 pop eax

ret

_set_idt_handlers:
push dword __HANDLER_DE
push dword 0
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __HANDLER_UD
push dword 6
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __HANDLER_DF
push dword 8
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __HANDLER_GP
push dword 13
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __HANDLER_PF
push dword 14
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __ISR_TIMER ;Por ahora el timer lo mando a la isr del teclado
push dword 32
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

push dword __INICIO_ISR_TECLADO_RAM ;Por ahora el timer lo mando a la isr del teclado
push dword 33
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
times 2 pop eax

ret
