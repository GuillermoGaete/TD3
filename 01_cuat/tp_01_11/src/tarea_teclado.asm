EXTERN __FLAG_TECLADO_READY

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS

EXTERN __CURRENT_TABLE_INDEX

EXTERN __INICIO_BUFFER_TECLADO

GLOBAL TAREA_TECLADO
section .text
TAREA_TECLADO:
USE32
  cmp dword [__FLAG_TECLADO_READY],0x00000001
  jne return
  ;Se presiono enter, bajo el flag
  mov dword [__FLAG_TECLADO_READY],0x00000000
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
  mov [ebx+4],edx

  add dword [__CURRENT_TABLE_INDEX],1
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
