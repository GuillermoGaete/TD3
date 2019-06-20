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
EXTERN __INICIO_ISR_TIMER_RAM

EXTERN __INICIO_HANDLERS_RAM
EXTERN __INICIO_HANDLERS_ROM
EXTERN __LONGITUD_HANDLERS

EXTERN __INICIO_SET_IDT_HANDLER_EN_NUCLEO_RAM

EXTERN __FIN_PILA

EXTERN __SYSTEM_TABLES
EXTERN __SYSTEM_TABLES_ROM
EXTERN __SYSTEM_TABLES_LONG

EXTERN __SIZE_BUFFER_TECLADO_BYTES
EXTERN __FLAG_TECLADO_READY

EXTERN __INICIO_BUFFER_TECLADO
EXTERN __FIN_BUFFER_TECLADO

EXTERN __CURRENT_TABLE_INDEX
EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS

EXTERN _pic_configure
EXTERN _pit_configure

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

  xor edx,edx
  mov [__CURRENT_TABLE_INDEX],edx

  ;Copio todo lo que tengo que copiar de rom a RAM
  call _copy_from_rom_to_ram

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

main:
  mov eax,[__FLAG_TECLADO_READY]
  and eax,0x00000001
  cmp eax,1
  jne main
  ;Se presiono enter, bajo el flag
  mov eax,[__FLAG_TECLADO_READY]
  and eax,0xFFFFFFFE
  mov [__FLAG_TECLADO_READY],eax
  ;Hago lo que tengo que hacer
  mov ebx,__INICIO_TABLA_DE_DIGITOS

  xor eax,eax
  mov eax,8
  mov edx,[__CURRENT_TABLE_INDEX]
  mul edx

  add ebx,eax

  cmp ebx,__FIN_TABLA_DE_DIGITOS
  jl insert_number
  ;Reseteo el buffer de teclado
  xor edx,edx
  mov [__CURRENT_TABLE_INDEX],edx
  jmp main

insert_number:
  ;En ebx tengo la direccion a escribir
  mov eax,[__INICIO_BUFFER_TECLADO]
  mov edx,[__INICIO_BUFFER_TECLADO+4]

  mov [ebx],eax
  add ebx,4
  mov [ebx],edx
  add ebx,4

  mov edx,[__CURRENT_TABLE_INDEX]
  add edx,1
  mov [__CURRENT_TABLE_INDEX],edx

  ;Limpio el buffer circular
  mov eax,__INICIO_BUFFER_TECLADO
  mov ebx,0x00000000
  mov [eax],ebx
  mov [eax+4],ebx
  mov ebx,[__INICIO_BUFFER_TECLADO+8]
  mov edx,0xFFFFFF00
  and ebx,edx
  mov [eax+8],ebx
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
