GLOBAL __HANDLER_DE
GLOBAL __HANDLER_GP
GLOBAL __HANDLER_PF
GLOBAL __HANDLER_UD
GLOBAL __HANDLER_DF

EXTERN __FIN_PILA
EXTERN __PRINT_TEXT

section .data

FP_MESSAGE  DB "EXCEPCION: Ocurrio un fallo de pagina."
LONG_FP_MESSAGE EQU $-FP_MESSAGE

FP_SGX_NOT DB "- Related to SGX: Not"
FP_SGX_YES DB "- Related to SGX: Yes"
LONG_FP_SGX EQU $-FP_SGX_YES

FP_PK_NOT DB "- Caused by protection keys: Not"
FP_PK_YES DB "- Caused by protection keys: Yes"
LONG_FP_PK EQU $-FP_PK_YES

FP_IF_NOT DB "- Instruction fetch: Not"
FP_IF_YES DB "- Instruction fetch: Yes"
LONG_FP_IF EQU $-FP_IF_YES

FP_RB_VIOLATION_NOT DB "- Reserved bit violation: Not"
FP_RB_VIOLATION_YES DB "- Reserved bit violation: Yes"
LONG_FP_RB_VIOLATION EQU $-FP_RB_VIOLATION_YES

FP_PAGE_PRESENT_NOT DB "- Page present: Not"
FP_PAGE_PRESENT_YES DB "- Page present: Yes"
LONG_FP_PAGE_PRESENT EQU $-FP_PAGE_PRESENT_YES

FP_W_OPERATION DB "- R/W operation type: W"
FP_R_OPERATION DB "- R/W operation type: R"
LONG_FP_WR EQU $-FP_R_OPERATION

FP_S_OPERATION DB "- S/U operation type: S"
FP_U_OPERATION DB "- S/U operation type: U"
LONG_FP_SU EQU $-FP_U_OPERATION


DE_MESSAGE  DB "EXCEPCION: Division por cero."
LONG_DE_MESSAGE EQU $-DE_MESSAGE

USE32
section .text
__HANDLER_MAIN:

  ;[esp] Retorno
  ;[esp+4] Dx
  ;[esp + 8-36] Retorno

  ;[esp+40] Error code
  ;[esp+12] EIP
  ;[esp+16] CS
  ;[esp+20] EFLAGS
  xor edx,edx
  mov edx, [esp+4] ;En dx tengo el numero de excepcion
  cmp edx,14 ;Fallo de pagina
  je page_fault
  cmp edx,0 ;Division por cero
  je divide_error
  jmp return
return:
  ret

__HANDLER_DE: ;Divide Error
  pushad
  mov edx,0
  push edx
  call __HANDLER_MAIN
  pop edx
  popad
  iret

__HANDLER_UD:;Invalid Opcode (Undefined Opcode)
  pushad
  mov edx,6
  push edx
  call __HANDLER_MAIN
  pop edx
  popad
  iret

__HANDLER_DF:;Double Fault
  ;Para generarla podemos invalidar la idt de la division por 0 y despues dividir por 0, eso va a producir una falla de segmentacion al vectorizar la
  ;division por 0
  pushad
  xchg edx,edx
  mov edx,8
  push edx
  call __HANDLER_MAIN
  pop edx
  popad
  iret

__HANDLER_GP: ;General Protection
  pushad
  mov edx,13
  push edx
  call __HANDLER_MAIN
  pop edx
  popad
  iret

__HANDLER_PF: ;Page Fault
  pushad
  mov edx,14
  push edx
  call __HANDLER_MAIN
  pop edx
  popad
  iret

  page_fault:
    ;[esp] Retorno
    ;[esp+4] Dx
    ;[esp + 8-36] Retorno

    ;[esp+40] Error code
    ;[esp+12] EIP
    ;[esp+16] CS
    ;[esp+20] EFLAGS

    ;Print message
    xchg bx,bx

    push  dword FP_MESSAGE
    push  dword LONG_FP_MESSAGE
    push 15  ;Fila
    push 0
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de no haber error
    mov edx,FP_PAGE_PRESENT_NOT
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000001
    cmp eax,0x00000001
    mov esi,FP_PAGE_PRESENT_YES
    CMOVE edx,esi
    mov ecx,LONG_FP_PAGE_PRESENT

    push edx
    push ecx
    push 16  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 2
    mov edx,FP_R_OPERATION
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000002
    cmp eax,0x00000002
    mov esi,FP_W_OPERATION
    CMOVE edx,esi
    mov ecx,LONG_FP_WR

    push edx
    push ecx
    push 17  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 3
    mov edx,FP_S_OPERATION
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000004
    cmp eax,0x00000004
    mov esi,FP_U_OPERATION
    CMOVE edx,esi
    mov ecx,LONG_FP_SU

    push edx
    push ecx
    push 18  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 4
    mov edx,FP_RB_VIOLATION_NOT
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000008
    cmp eax,0x00000008
    mov esi,FP_RB_VIOLATION_YES
    CMOVE edx,esi
    mov ecx,LONG_FP_RB_VIOLATION

    push edx
    push ecx
    push 19  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 5
    mov edx,FP_IF_NOT
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000010
    cmp eax,0x00000010
    mov esi,FP_IF_YES
    CMOVE edx,esi
    mov ecx,LONG_FP_IF

    push edx
    push ecx
    push 20  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 6
    mov edx,FP_PK_NOT
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00000020
    cmp eax,0x00000020
    mov esi,FP_PK_YES
    CMOVE edx,esi
    mov ecx,LONG_FP_PK

    push edx
    push ecx
    push 21  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    ;Cargo el mensaje en caso de ser 0 el bit 6
    mov edx,FP_SGX_NOT
    ;Me fijo el bit correspondiente
    mov eax,[esp+40]
    and eax,0x00008000
    cmp eax,0x00008000
    mov esi,FP_SGX_YES
    CMOVE edx,esi
    mov ecx,LONG_FP_SGX

    push edx
    push ecx
    push 22  ;Fila
    push 5
    call __PRINT_TEXT
    times 4 pop eax

    jmp return

    divide_error:
      push  dword DE_MESSAGE
      push  dword LONG_DE_MESSAGE
      push 23  ;Fila
      push 0
      call __PRINT_TEXT
      times 4 pop eax
      jmp return
