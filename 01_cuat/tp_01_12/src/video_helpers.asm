GLOBAL __PRINT_NUMBER
GLOBAL __PRINT_TEXT
GLOBAL __CLEAR_VIDEO_BUFFER
USE32
section .data

BUFFER_VIDEO EQU 0x00010000

section .bss
fila resb 4
columna resb 4
cantidad_words resb 4

section .text
__PRINT_NUMBER:
call compute_initial_esi
mov eax,0
ciclo_mostrar_numero:
mov edx,[esp+4*eax+16]
mov ebx,0
ciclo_mostrar_dword:
rol edx,4
push edx
and edx,0x0000000F
call return_ascii
;Retorna en ecx el valor a mostar
;Tengo que enviar el numero y retornar de alguna forma el codigo return_ascii
MOV [ESI], dl  ; Escribo en el caracter
MOV BYTE [ESI+1], 0x07 ;Escribir el atributo
ADD ESI, 2  ; Incremento el puntero
pop edx
add ebx,1
cmp ebx,7
jle ciclo_mostrar_dword
add eax,1
mov ebx,[esp+12]
cmp eax,ebx
jl ciclo_mostrar_numero
ret

return_ascii:
  add edx,48
  cmp edx,58
  jl finish_return_ascii
  add edx,7
finish_return_ascii:
  ret



__PRINT_TEXT:
call compute_initial_esi

xor eax,eax
xor ecx,ecx
mov edx,[esp+12]
print_cicle:
  mov ebx,[esp+16]
  mov ebx,[ebx+eax];Puntero al mensaje
  mov cl,bl
  MOV [ESI], bl  ; Escribo en el caracter
  MOV BYTE [ESI+1], 0x07 ;Escribir el atributo
  ADD ESI, 2  ; Incremento el puntero
  add eax,1
  cmp eax,edx
  jl print_cicle
ret

__CLEAR_VIDEO_BUFFER:
call compute_initial_esi
xor eax,eax
xor ecx,ecx
mov edx,[esp+12]
clear_cicle:
  MOV BYTE [ESI], 0x00  ; Escribo en el caracter
  MOV BYTE [ESI+1], 0x00 ;Escribir el atributo
  ADD ESI, 2  ; Incremento el puntero
  add eax,1
  cmp eax,edx
  jl clear_cicle
ret

compute_initial_esi:
mov ebx,[esp+12]
mov eax,160
xor edx,edx
mul ebx

mov esi, BUFFER_VIDEO   ; Puntero a buffer de video, que tiene 80x25 caracteres
add esi,eax

mov ebx,[esp+8]
mov eax,2
xor edx,edx
mul ebx

add esi,eax
ret
