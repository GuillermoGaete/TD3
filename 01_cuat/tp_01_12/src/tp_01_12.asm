EXTERN __INICIO_NUCLEO_ROM
EXTERN __INICIO_NUCLEO_RAM
EXTERN __LONGITUD_NUCLEO
EXTERN __FIN_NUCLEO_RAM

EXTERN INICIO_PAGE_DIRECTORY
EXTERN INICIO_PAGE_TABLE_RAM_000
EXTERN INICIO_PAGE_TABLE_RAM_001
EXTERN INICIO_PAGE_TABLE_PILA
EXTERN INICIO_PAGE_TABLE_ROM
EXTERN SIZE_PAGINATION_STRUCTURE

EXTERN __PAGE_TABLES_DATOS_ROM
EXTERN __PAGE_TABLES_DATOS
EXTERN __LONGITUD_DATA_PAGE_TABLES

EXTERN __INICIO_BSS_TAREA_1
EXTERN __FIN_BSS_TAREA_1

EXTERN __PAGE_TABLES
EXTERN __PAGE_TABLES_END

EXTERN __INICIO_DATOS_RAM
EXTERN __FIN_DATOS_RAM
EXTERN __INICIO_PILA_TAREA_1
EXTERN __FIN_PILA_TAREA_1

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS

EXTERN __INICIO_TEXT_TAREA_1_RAM
EXTERN __INICIO_TEXT_TAREA_1_ROM
EXTERN __FIN_TEXT_TAREA_1_RAM
EXTERN __LONGITUD_TEXT_TAREA_1

EXTERN __INICIO_COPY_EN_NUCLEO_ROM
EXTERN __INICIO_COPY_EN_NUCLEO_RAM

EXTERN __INICIO_BUFFER_TECLADO

EXTERN __INICIO_DATA_TAREA_1_RAM
EXTERN __FIN_DATA_TAREA_1_RAM
EXTERN __INICIO_DATA_TAREA_1_ROM
EXTERN __LONGITUD_DATA_TAREA_1

EXTERN __HANDLER_DE
EXTERN __HANDLER_GP
EXTERN __HANDLER_PF
EXTERN __HANDLER_UD
EXTERN __HANDLER_DF

EXTERN __INICIO_ISR_TECLADO_RAM
EXTERN __ISR_TIMER

EXTERN __INICIO_ISRS_RAM
EXTERN __INICIO_ISRS_ROM
EXTERN __LONGITUD_ISRS
EXTERN __FIN_ISRS_RAM

EXTERN __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM

EXTERN __INICIO_PILA
EXTERN __FIN_PILA

EXTERN __INICIO_TECLADO_

EXTERN __SYSTEM_TABLES
EXTERN __SYSTEM_TABLES_END
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

TP_MESSAGE  DB "TP 12: Paginacion real - Isaac Guillermo Gaete"
LONG_TP_MESSAGE EQU $-TP_MESSAGE

EXTERN __SET_PAGINATION_STRUCTURE
EXTERN INIT_TABLE_PAGES

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

  ;Copio todo lo que tengo que copiar de rom a RAM identity
  call _copy_from_rom_to_ram_identity

  ;Configuro el arbol de paginacion
  call _set_pagination

  mov eax,INICIO_PAGE_DIRECTORY
  mov cr3,eax

  ;Activo la paginacion con cr0
  mov eax,cr0
  or eax,0x80000000
  mov cr0,eax

  mov edx,__INICIO_TECLADO_
  mov esp,__FIN_PILA

  xor edx,edx
  mov [__CURRENT_TABLE_INDEX],edx

  ;Copio todo lo que tengo que copiar de rom a RAM not identity
  call _copy_from_rom_to_ram_not_identity

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

main:
  call TAREA_STATUS_BAR
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
_copy_from_rom_to_ram_not_identity:

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

_copy_from_rom_to_ram_identity:
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
push dword __INICIO_ISRS_ROM ;fuente
push dword __INICIO_ISRS_RAM ;destino
push dword __LONGITUD_ISRS ;longitud
;Copio los handlers a las posiciones que corresponden
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

_set_pagination:
mov edi,INICIO_PAGE_DIRECTORY
mov ecx,INICIO_PAGE_TABLE_ROM
add ecx,4096
sub ecx,edi

xor eax,eax
.ciclo_borrado_tablas_paginacion:
mov [edi],eax
add edi,4
dec ecx
jnz .ciclo_borrado_tablas_paginacion

push dword 0xFFFF0000 ;Direccion lineal inicial
push dword 0xFFFFFFFF ;Direccion lineal final
push dword 0xFFFF0000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_ROM
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;ISRS, inicio 0x00000000
xchg bx,bx
push dword __INICIO_ISRS_RAM ;Direccion lineal inicial
push dword __FIN_ISRS_RAM ;Direccion lineal final
push dword 0x00000000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_000
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;VIDEO inicio 0x00010000
mov eax,0x00010000
push eax ;Direccion lineal inicial
push dword 0x00010FFF ;Direccion lineal final
push dword 0x000B8000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_000
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Tablas de sistema, inicio 0x00100000
push dword __SYSTEM_TABLES ;Direccion lineal inicial
push dword __SYSTEM_TABLES_END ;Direccion lineal final
push dword 0x00100000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_000
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Tablas de paginación, inician 0x00110000
push dword __PAGE_TABLES;Direccion lineal inicial
push dword __PAGE_TABLES_END ;Direccion lineal final
push dword 0x00110000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_000
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Nucleo, inicio 0x00400000
push dword __INICIO_NUCLEO_RAM;Direccion lineal inicial
push dword __FIN_NUCLEO_RAM ;Direccion lineal final
push dword 0x00400000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Tabla de dígitos, inica en 0x00410000
push dword __INICIO_TABLA_DE_DIGITOS ;Direccion lineal inicial
push dword __FIN_TABLA_DE_DIGITOS ;Direccion lineal final
push dword 0x00410000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;TEXT Tarea 1, incia en 0x00510000
push dword __INICIO_TEXT_TAREA_1_RAM;Direccion lineal inicial
push dword __FIN_TEXT_TAREA_1_RAM ;Direccion lineal final
push dword 0x00421000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;BSS Tarea 1, inicia 0x00511000
push dword __INICIO_BSS_TAREA_1;Direccion lineal inicial
push dword __FIN_BSS_TAREA_1 ;Direccion lineal final
push dword 0x00422000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;DATA Tarea 1, inicia 0x00423000
push dword __INICIO_DATA_TAREA_1_RAM;Direccion lineal inicial
push dword __FIN_DATA_TAREA_1_RAM ;Direccion lineal final
push dword 0x00423000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Datos, inicia 0x004E0000
push dword __INICIO_DATOS_RAM;Direccion lineal inicial
push dword __FIN_DATOS_RAM ;Direccion lineal final
push dword 0x004E0000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Pila, inicia 0x1FFFB000
push dword __INICIO_PILA;Direccion lineal inicial
push dword __FIN_PILA ;Direccion lineal final
push dword 0x1FFFB000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_PILA
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax

;Pila, inicia 0x00413000
push dword __INICIO_PILA_TAREA_1;Direccion lineal inicial
push dword __FIN_PILA_TAREA_1 ;Direccion lineal final
push dword 0x1FFFE000 ;Direcccion fisica inicial
push dword INICIO_PAGE_TABLE_RAM_001
push dword INICIO_PAGE_DIRECTORY
call __SET_PAGINATION_STRUCTURE
times 5 pop eax


ret
