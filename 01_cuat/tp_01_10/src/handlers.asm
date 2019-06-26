EXTERN __FIN_PILA
EXTERN __PRINT_TEXT

FP_MESSAGE  DB "Ocurrio un fallo de pagina"
LONG_TP_MESSAGE EQU $-FP_MESSAGE

USE32
section .handler_main
_handler_main:
  xchg bx,bx
  xor edx,edx
  mov dx, [esp+4] ;En dx tengo el numero de excepcion
  cmp dx,14 ;Fallo de pagina
  je page_fault
  jmp return
page_fault:
  push  dword FP_MESSAGE
  push  dword LONG_TP_MESSAGE
  push 0x10  ;Fila
  call __PRINT_TEXT
  pop eax
  pop eax
  pop eax
  jmp return

return:
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
  xchg bx,bx
  pushad
  mov dx,8
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_gp
_handler_gp: ;General Protection
  xchg bx,bx
  pushad
  mov dx,13
  push dx
  call _handler_main
  pop dx
  popad
  iret

section .handler_pf
_handler_pf: ;Page Fault
  xchg bx,bx
  pushad
  mov dx,14
  push dx
  call _handler_main
  pop dx
  popad
  iret
