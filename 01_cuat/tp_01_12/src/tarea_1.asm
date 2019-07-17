EXTERN __FLAG_TIMER_BASE

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __CURRENT_TABLE_INDEX

EXTERN __PRINT_NUMBER
EXTERN __PRINT_TEXT

EXTERN __CLEAR_VIDEO_BUFFER

USE32
section .data
max_address dd 0x02000000
;Messages
ACUM_MESSAGE  DB "El numero acumulado es:"
LONG_ACUM_MESSAGE EQU $-ACUM_MESSAGE

NOT_READ_MESSAGE  DB "Lectura no realizada."
LONG_NOT_READ_MESSAGE EQU $-NOT_READ_MESSAGE

READ_MESSAGE  DB "Lectura realizada, contenido:"
LONG_READ_MESSAGE EQU $-READ_MESSAGE

section .bss
low_part_acum resb 4
high_part_acum resb 4
readed_content resb 4

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

  ;Muestro en pantalla
  push dword ACUM_MESSAGE
  push dword LONG_ACUM_MESSAGE
  push dword 1 ;Fila
  push dword 0
  call __PRINT_TEXT
  times 4 pop eax

  push dword [low_part_acum]
  push dword [high_part_acum]
  push dword 2 ;Cantidad de words
  push dword 1 ;Fila donde muestro el numero
  push dword LONG_ACUM_MESSAGE  ;Columna donde muestro el numero
  call __PRINT_NUMBER
  times 5 pop ecx

  mov eax,0
  mov [__CURRENT_TABLE_INDEX],eax

  mov eax,[max_address]
  mov ebx,[low_part_acum]
  mov edx,[high_part_acum]

  cmp edx,0
  jne not_read_address

  cmp ebx,eax
  jl read_address

not_read_address:

  push dword 80
  push dword 4 ;Fila
  push dword 0
  call __CLEAR_VIDEO_BUFFER
  times 3 pop eax

  push dword NOT_READ_MESSAGE
  push dword LONG_NOT_READ_MESSAGE
  push dword 4 ;Fila
  push dword 0
  call __PRINT_TEXT
  times 4 pop eax
  jmp return

read_address:

  push dword 80
  push dword 4 ;Fila
  push dword 0
  call __CLEAR_VIDEO_BUFFER
  times 3 pop eax

  mov ebx,[low_part_acum]
  mov ebx,[ebx]
  mov [readed_content],ebx

  push dword READ_MESSAGE
  push dword LONG_READ_MESSAGE
  push dword 4  ;Fila
  push dword 0
  call __PRINT_TEXT
  times 4 pop eax

  mov ebx,[readed_content]

  push dword ebx
  push dword 1 ;Cantidad de words
  push dword 4 ;Fila donde muestro el numero
  push dword LONG_READ_MESSAGE  ;Columna donde muestro el numero
  call __PRINT_NUMBER
  times 4 pop ecx


return:
  hlt
  ret ;Para volver
