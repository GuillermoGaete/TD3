GLOBAL __FLAG_TIMER_BASE
GLOBAL __FLAG_TIMER_SCREEN
GLOBAL __COUNT_TIMER
GLOBAL __ISR_TIMER

EXTERN __PRINT_TEXT

section .data

__FLAG_TIMER_SCREEN dd 0x00000000
__FLAG_TIMER_BASE dd 0x00000000
__COUNT_TIMER dd 0x00000000

TIMER_BASE_COUNT EQU 100
SCREEN_UPDATE_TICK_COUNT EQU 5

section .text
USE32
__ISR_TIMER:
  pushad

  add dword [__COUNT_TIMER],1

  push dword __FLAG_TIMER_SCREEN
  push dword SCREEN_UPDATE_TICK_COUNT
  call set_timer_flag
  times 2 pop eax

  push dword __FLAG_TIMER_BASE
  push dword TIMER_BASE_COUNT
  call set_timer_flag
  times 2 pop eax

finish_isr:
  ;Indicarle al PIC que finalizo la interrupcion.
  mov al,20h
  out 20h,al
  ;Popeo los registros de uso general
  popad
  iret ;Retorno de interrupcion


set_timer_flag:
  ;[esp+4] --> COUNTER_TIME
  ;[esp+8] --> *FLAG
  mov ebx,[esp+4]
  cmp [__COUNT_TIMER],ebx
  je set_flag
  jg compute_flag
  ret ;If less ret

compute_flag:
  ;Si estoy aca es porque es mayor
  xor eax,eax
  xor edx,edx

  div ebx
  ;En eax tengo __COUNT_TIMER/TIMER_BASE_MS, si edx es 0 entonces estoy en una cuenta
  cmp edx,0
  je set_flag
  ret

set_flag:
  mov eax,[esp+8]
  mov dword [eax],0x00000001
  ret
