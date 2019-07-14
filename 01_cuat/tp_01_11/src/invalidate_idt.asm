EXTERN __INICIO_INVALIDATE_EN_NUCLEO_RAM
EXTERN __SYSTEM_TABLES

section .invalidate_idt
USE32
  mov edi, [esp+4] ;Numero de interrupcion
  mov ecx, __SYSTEM_TABLES
  mov ebx,[ecx+edi*8+4] ;Obtengo los segundos 32 bits
  and ebx,0xFFFF7FFF ;Bajo el Segment Present flag
  mov [ecx+edi*8+4],ebx
  ret ;Para volver despues de copiar
