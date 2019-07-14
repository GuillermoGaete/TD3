EXTERN __PRINT_TEXT
EXTERN __FLAG_TIMER_SCREEN

GLOBAL TAREA_STATUS_BAR

USE32
section .data

INDICATOR_FLAG dd 0x00000000

POSITIVE_INDICATOR  DB "/"
LONG_POSITIVE_INDICATOR EQU $-POSITIVE_INDICATOR

NEGATIVE_INDICATOR  DB "\"
LONG_NEGATIVE_INDICATOR EQU $-POSITIVE_INDICATOR

section .bss

section .text
TAREA_STATUS_BAR:
  mov eax,[__FLAG_TIMER_SCREEN]
  and eax,0x00000001
  cmp eax,1
  jne return
  ;Si estoy aca es porque el flag del timer se levanto, lo bajo
  mov dword [__FLAG_TIMER_SCREEN],0x00000000

  cmp dword [INDICATOR_FLAG],0x00000001
  je set_positive_indicator
  jne set_negative_indicator

set_positive_indicator:
  mov dword [INDICATOR_FLAG],0x00000000
  push  dword POSITIVE_INDICATOR
  push  dword LONG_POSITIVE_INDICATOR
  push 24  ;Fila
  push 79 ;Columna
  call __PRINT_TEXT
  times 4 pop eax
  jmp return

set_negative_indicator:
  mov dword [INDICATOR_FLAG],0x00000001
  push  dword NEGATIVE_INDICATOR
  push  dword LONG_NEGATIVE_INDICATOR
  push 24  ;Fila
  push 79 ;Columna
  call __PRINT_TEXT
  times 4 pop eax
  jmp return

return:
  ret ;Para volver
