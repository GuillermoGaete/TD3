EXTERN __FLAG_TECLADO_READY

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS

EXTERN __CURRENT_TABLE_INDEX

EXTERN __INICIO_BUFFER_TECLADO

section .tarea_teclado
USE32
  mov eax,[__FLAG_TECLADO_READY]
  and eax,0x00000001
  cmp eax,1
  jne return
  ;Se presiono enter, bajo el flag
  mov eax,[__FLAG_TECLADO_READY]
  and eax,0xFFFFFFFE
  mov [__FLAG_TECLADO_READY],eax
  ;Hago lo que tengo que hacer
  mov ebx,__INICIO_TABLA_DE_DIGITOS

  xor eax,eax
  mov eax,8
  mov edx,[__CURRENT_TABLE_INDEX]
  mul edx

  add ebx,eax

  cmp ebx,__FIN_TABLA_DE_DIGITOS
  jl insert_number

  ;Reseteo el buffer de teclado
  xor edx,edx
  mov [__CURRENT_TABLE_INDEX],edx

  jmp return

insert_number:
  ;En ebx tengo la direccion a escribir
  mov eax,[__INICIO_BUFFER_TECLADO]
  mov edx,[__INICIO_BUFFER_TECLADO+4]

  mov [ebx],eax
  add ebx,4
  mov [ebx],edx
  add ebx,4

  mov edx,[__CURRENT_TABLE_INDEX]
  add edx,1
  mov [__CURRENT_TABLE_INDEX],edx

  ;Limpio el buffer circular
  mov eax,__INICIO_BUFFER_TECLADO
  mov ebx,0x00000000
  mov [eax],ebx
  mov [eax+4],ebx
  mov ebx,[__INICIO_BUFFER_TECLADO+8]
  mov edx,0xFFFFFF00
  and ebx,edx
  mov [eax+8],ebx
  jmp return

return:
  ret ;Para volver
