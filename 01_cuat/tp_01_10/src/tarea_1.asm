EXTERN __FLAG_TIMER

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __CURRENT_TABLE_INDEX

EXTERN __PRINT_NUMBER

USE32
section .data
_acum dd 0x00000001
section .bss

section .text
  mov eax,[__FLAG_TIMER]
  and eax,0x00000001
  cmp eax,1
  jne return
  ;Si estoy aca es porque el flag del timer se levanto, lo bajo
  mov eax,[__FLAG_TIMER]
  and eax,0xFFFFFFFE
  mov [__FLAG_TIMER],eax

  mov eax,__INICIO_TABLA_DE_DIGITOS
  mov ebx,[__CURRENT_TABLE_INDEX]

  cmp ebx, 0
  je return

  mov ecx,0
  mov edx, 0

ciclo_suma:
  push edx
  mov edx,[eax]
  push ebx
  mov ebx,0
  mov [eax],ebx
  pop ebx
  add ecx,edx
  pop edx
  add edx,1
  add eax,8
  cmp edx,ebx
  jl ciclo_suma
  ;Muestro en pantalla
  mov eax,0
  ;Acumulo en __ACUM
  mov edx,[_acum]
  add edx,ecx
  mov [_acum],edx

  mov ecx,edx

  push ecx ;En ecx tengo el numero a mostrar
  push 0x2 ;Fila donde muestro el numero
  call __PRINT_NUMBER
  pop ecx
  pop ecx

  mov eax,0
  mov [__CURRENT_TABLE_INDEX],eax

return:
  xchg bx,bx
  hlt
  ret ;Para volver
