EXTERN __FLAG_TECLADO_READY

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS
EXTERN __PRINT_TEXT
EXTERN __PRINT_NUMBER

EXTERN __CURRENT_TABLE_INDEX
EXTERN LONG_TP_MESSAGE

EXTERN __INICIO_BUFFER_TECLADO

GLOBAL TAREA_TECLADO
GLOBAL DIGITOS_MESSAGE
GLOBAL LONG_DIGITOS_MESSAGE

section .data
DIGITOS_MESSAGE  DB "# Digitos en tabla:"
LONG_DIGITOS_MESSAGE EQU $-DIGITOS_MESSAGE
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
  call show_current_index

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
  call show_current_index
  jmp return

show_current_index:

;Muestro en pantalla
push dword DIGITOS_MESSAGE
push dword LONG_DIGITOS_MESSAGE
push dword 23 ;Fila
push dword LONG_TP_MESSAGE
call __PRINT_TEXT
times 4 pop eax

push dword [__CURRENT_TABLE_INDEX]
push dword 1 ;Cantidad de words
push dword 23 ;Fila donde muestro el numero
push dword LONG_TP_MESSAGE+LONG_DIGITOS_MESSAGE   ;Columna donde muestro el numero
call __PRINT_NUMBER
times 4 pop ecx

ret

return:
  ret ;Para volver
