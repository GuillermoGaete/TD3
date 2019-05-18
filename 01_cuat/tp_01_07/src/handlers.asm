USE32
section .handler_main
_handler_main:
  xchg bx,bx ;Para ver la excepcion que se generó
  xor edx,edx
  mov dx, [esp+4] ;En dx tengo el numero de excepcion
  hlt ;No se si es la mejor forma de finalizar
  ret

section .handler_de
_handler_de: ;Divide Error
  pushad
  mov dx,0
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_ud
_handler_ud:;Invalid Opcode (Undefined Opcode)
  pushad
  mov dx,6
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_df
_handler_df:;Double Fault
  ;Para generarla podemos invalidar la idt de la division por 0 y despues dividir por 0, eso va a producir una falla de segmentacion al vectorizar la
  ;division por 0
  pushad
  mov dx,8
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_gp
_handler_gp: ;General Protection
  pushad
  mov dx,13
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_pf
_handler_pf: ;Page Fault
  pushad
  mov dx,14
  push dx
  call _handler_main
  pop dx
  popad
  iret
