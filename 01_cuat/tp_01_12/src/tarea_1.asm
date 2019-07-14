EXTERN __FLAG_TIMER_BASE

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __CURRENT_TABLE_INDEX

EXTERN __PRINT_NUMBER

USE32
section .data
_acum dd 0x00000000
section .bss
low_part_acum resb 4
high_part_acum resb 4

section .text
  cmp dword [__FLAG_TIMER_BASE],0x00000001
  jne return
  ;Si estoy aca es porque el flag del timer se levanto, lo bajo
  mov eax,[__FLAG_TIMER_BASE]
  and eax,0xFFFFFFFE
  mov [__FLAG_TIMER_BASE],eax

  mov eax,__INICIO_TABLA_DE_DIGITOS

  cmp dword [__CURRENT_TABLE_INDEX], 0
  je return

  mov ebx,0
ciclo_suma:
  mov ecx,[eax]
  mov edx,[eax+4]

  add [low_part_acum],ecx
  adc [high_part_acum],edx

  add ebx,1
  add eax,8
  cmp ebx,[__CURRENT_TABLE_INDEX]
  jl ciclo_suma

  mov ecx,[low_part_acum]
  mov edx,[high_part_acum]

  xchg bx,bx
  ;Muestro en pantalla
  push dword [low_part_acum]
  push dword [high_part_acum]
  push dword 2 ;Cantidad de words
  push dword 0x1 ;Fila donde muestro el numero
  call __PRINT_NUMBER
  times 4 pop ecx

  mov eax,0
  mov [__CURRENT_TABLE_INDEX],eax

return:
  hlt
  ret ;Para volver
