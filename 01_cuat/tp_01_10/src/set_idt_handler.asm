EXTERN __SYSTEM_TABLES
section .set_idt_handler
USE32
  mov ecx, __SYSTEM_TABLES ;Direccion donde comienza la IDT
  mov edi, [esp+4] ;Numero de interrupcion/excepcion
  mov esi, [esp+8] ;Direccion del handler

  mov ebx,esi
  and ebx,0xFFFF0000 ;Parte alta
  rol ebx,16 ;Lo coloco en bx
  mov [ecx+edi*8+6],bx

  mov ebx,esi
  and ebx,0x0000FFFF ;Parte baja
  mov [ecx+edi*8],bx

  ret ;Para volver despues de copiar
