EXTERN __FIN_PILA

INICIO_DIR_PAG EQU 0x1000 ;Las pongo en cualquier lugar
INICIO_TAB_PAG_RAM EQU 0x2000
INICIO_TAB_PAG_ROM EQU 0x3000

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

idt:
  TIMES 0x20 dq 0;todo a 0 qd(quad words-8 bytes a 0)
  ;Compuerta de interrupcion
  dw _handler_timer ;Offset de mi manejador
  dw cs_sel ;Selector de codigo
  db 0x0
  db 0x8E ;Indico que es de interrupcion
  dw 0xFFFF
long_idt equ $-idt

img_idtr:
      dw long_idt-1
      dd idt

inicio:
  mov eax,0xFFFFFFF0
  mov [0],eax
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

  ;Borro la memoria, en donde voy a poner mis tablas
  mov edi,0x1000
  mov ecx,0x3000/4
  xor eax,eax
.ciclo_borrado_tablas_paginacion:
  mov [edi],eax
  add edi,4
  dec ecx
  jnz .ciclo_borrado_tablas_paginacion
  ;Lleno las tablas
  mov dword[INICIO_DIR_PAG+0x100*4],INICIO_TAB_PAG_RAM+0x3
  mov dword[INICIO_DIR_PAG+0x3FF*4],INICIO_TAB_PAG_ROM+0x3
  mov dword[INICIO_TAB_PAG_RAM+0x000*4],0x00000000+0x3

  ;Tengo que llenar las tablas de rom, que son 16, 16x4kb=64kb
  mov edi,INICIO_TAB_PAG_ROM+0x3F0*4 ;algo + indice * 4
  mov eax,0xFFFF0000+0x3
  mov ecx, 16
.ciclo_set_tab_pag_rom:
  mov [edi],eax
  add edi,4
  add eax,0x1000 ;la siguiente pagina esta 4kb adelante
  dec ecx
  jnz .ciclo_set_tab_pag_rom
  ;cargo idt
  lidt  [img_idtr]
  ;Configuro los pics
  call _pic_configure
  call _pit_configure
  ;aca tengo que activar la paginacion
  ;Cargo cr3 en el inicio del directorio de paginas
  mov eax,INICIO_DIR_PAG
  mov cr3,eax
  ;activo la paginacion con cr0
  xchg bx,bx
  mov eax,cr0
  or eax,0x80000000
  mov cr0,eax
  ;Tengo que cambiar la pila que no esta paginada
  mov esp,0x40001000

  ;Le digo al pic que este habilitada la interrupcion del timer irq0
  mov al,0xFE;Habilito irq 0
  out 0x21,al

  sti ;A partir de este momento estan habilitadas las interrupciones
  jmp $


section .nucleo
  nop
  xchg bx,bx
  ret
