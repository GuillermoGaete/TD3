EXTERN __INICIO_NUCLEO_ROM
EXTERN __INICIO_NUCLEO_RAM
EXTERN __LONGITUD_NUCLEO

EXTERN __INICIO_COPY_EN_NUCLEO_ROM
EXTERN __INICIO_COPY_EN_NUCLEO_RAM

EXTERN __INICIO_HANDLER_DE_RAM
EXTERN __INICIO_HANDLER_UD_RAM
EXTERN __INICIO_HANDLER_PF_RAM
EXTERN __INICIO_HANDLER_GP_RAM
EXTERN __INICIO_HANDLER_DF_RAM

EXTERN __INICIO_ISR_TECLADO_RAM

EXTERN __INICIO_HANDLERS_RAM
EXTERN __INICIO_HANDLERS_ROM
EXTERN __LONGITUD_HANDLERS

EXTERN __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM

EXTERN __FIN_PILA

EXTERN __SYSTEM_TABLES
EXTERN __SYSTEM_TABLES_ROM
EXTERN __SYSTEM_TABLES_LONG

EXTERN _pic_configure

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

  ;Antes de cargar la idt, lo que tengo que hacer es escribir en cada vector los
  ;handlers que corresponden, para esto hago
  call _set_idt_handlers

  ;Cargo idtr
  lidt  [img_idtr]
  ;Configuro los pics
  call _pic_configure
  ;Configuro las irq
  call config_irq

  ;A partir de este momento estan habilitadas las interrupciones
  sti
  jmp $

config_irq:
  ;Le digo al pic que este habilitada la interrupcion del teclado
  mov al,0xFD;Habilito la irq 1 del teclado
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

  TIMES 0x12 dq 0

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

push dword __INICIO_ISR_TECLADO_RAM ;Por ahora el timer lo mando a la isr del teclado
push dword 33
call __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM
pop eax
pop eax
ret
