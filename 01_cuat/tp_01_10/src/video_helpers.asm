USE32
BUFFER_VIDEO EQU 0xb8000
DEFAULT_MESSAGE  DB "El numero acumulado es:"
LONG_DEFAULT_MESSAGE EQU $-DEFAULT_MESSAGE

section .print_number
;[esp] ;Direccion de retorno

;[esp+4] ;Fila en donde mostar el numero
;[esp+8] ;Fila en donde mostar el numero

;en ecx tengo el numero a mostrar
mov ecx,[esp+8]
mov ebx,[esp+4];Fila
mov eax,80
xor edx,edx
mul ebx

mov esi, BUFFER_VIDEO   ; Puntero a buffer de video, que tiene 80x25 caracteres
add esi,eax

push ecx

xor eax,eax
xor ecx,ecx
mov edx,LONG_DEFAULT_MESSAGE

ciclo_mostrar_texto:
  mov ebx,[DEFAULT_MESSAGE+eax];Puntero al mensaje
  mov cl,bl
  MOV [ESI], bl  ; Escribo en el caracter
  MOV BYTE [ESI+1], 0x07 ;Escribir el atributo
  ADD ESI, 2  ; Incremento el puntero
  add eax,1
  cmp eax,edx
  jl ciclo_mostrar_texto

pop ecx
mov eax,0
ciclo_mostrar_numero:
rol ecx,4
push ecx
and ecx,0x0000000F
call return_ascii
;Retorna en ecx el valor a mostar
;Tengo que enviar el numero y retornar de alguna forma el codigo return_ascii
MOV [ESI], cl  ; Escribo en el caracter
MOV BYTE [ESI+1], 0x07 ;Escribir el atributo
ADD ESI, 2  ; Incremento el puntero
pop ecx
add eax,1
cmp eax,7
jle ciclo_mostrar_numero

ret

return_ascii:
  add ecx,48
  cmp ecx,58
  jl finish_return_ascii
  add ecx,7
finish_return_ascii:
  ret


section .print_text
;[esp] ;Direccion de retorno

;[esp+4] ;Fila en donde mostar el texto
;[esp+8] ;Longitud del texto
;[esp+12] ;Direccion de inicio del texto
print_text:
mov ebx,[esp+4];Fila
mov eax,80
xor edx,edx
mul ebx

mov esi, BUFFER_VIDEO   ; Puntero a buffer de video, que tiene 80x25 caracteres
add esi,eax

xor eax,eax
xor ecx,ecx
mov edx,[esp+8]

print_cicle:
  mov ebx,[esp+12]
  mov ebx,[ebx+eax];Puntero al mensaje
  mov cl,bl
  MOV [ESI], bl  ; Escribo en el caracter
  MOV BYTE [ESI+1], 0x07 ;Escribir el atributo
  ADD ESI, 2  ; Incremento el puntero
  add eax,1
  cmp eax,edx
  jl print_cicle
ret
