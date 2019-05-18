EXTERN __INICIO_RUTINAS_ROM
EXTERN __INICIO_RUTINAS_RAM
EXTERN __LONGITUD_RUTINAS

EXTERN __INICIO_COPY_EN_RUTINAS_ROM
EXTERN __INICIO_COPY_EN_RUTINAS_RAM

EXTERN __INICIO_NUCLEO_RAM
EXTERN __INICIO_NUCLEO_ROM
EXTERN __LONGITUD_NUCLEO

EXTERN __FIN_PILA
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

  push dword __INICIO_RUTINAS_ROM ;fuente
  push dword __INICIO_RUTINAS_RAM ;destino
  push dword __LONGITUD_RUTINAS ;longitud

  ;Voy a autocopiar la seccion rutinas en RAM, al hacer eso tambien copio lo que esta en
  ;copy con lo que tengo el codigo que copia en RAM despues de esto.
  call __INICIO_COPY_EN_RUTINAS_ROM

  pop eax
  pop eax
  pop eax

  push dword __INICIO_NUCLEO_ROM ;fuente
  push dword __INICIO_NUCLEO_RAM ;destino
  push dword __LONGITUD_NUCLEO ;longitud

  call __INICIO_COPY_EN_RUTINAS_RAM ;Ya tengo el codigo de copy en RAM, lo ejecuto desde ahi

  pop eax
  pop eax
  pop eax

  call __INICIO_NUCLEO_RAM ;puedo ir a ejecutar lo que esta en nucleo en RAM
  jmp $

section .nucleo
  nop
  xchg bx,bx ;Para probar si funciona
  ret
