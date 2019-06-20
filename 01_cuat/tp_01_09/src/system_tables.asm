
section .system_tables
USE16
gdt:
  db 0,0,0,0,0,0,0,0  ;Descriptor nulo
ds_sel    equ $-gdt
  db 0xFF, 0xFF, 0, 0, 0, 0x92, 0xCF, 0
cs_sel    equ $-gdt
  db 0xFF, 0xFF, 0, 0, 0, 0x9A, 0xCF, 0

long_gdt equ $-gdt

idt:
  ;Division por 0
  dw _handler_main ;Offset de mi manejador
  dw cs_sel ;Selector de codigo
  db 0x0
  db 0x8F ;Indico que es de excepcion
  dw 0xFFFF

  TIMES 0x19 dq 0;todo a 0 qd(quad words-8 bytes a 0)

  ;Interrupcion del teclado
  dw _handler_divz ;Offset de mi manejador
  dw cs_sel ;Selector de codigo
  db 0x0
  db 0x8E ;Indico que es de interrupcion
  dw 0xFFFF
  ;Interrupcion del
  dw _handler_divz ;Offset de mi manejador
  dw cs_sel ;Selector de codigo
  db 0x0
  db 0x8E ;Indico que es de interrupcion
  dw 0xFFFF

long_idt equ $-idt

img_idtr:
  dw long_idt-1
  dd __SYSTEM_TABLES_RAM
