section .pagination_helpers
USE32
;[esp] ;Direccion de retorno

;[esp+4] ;INICIO_PAGE_DIRECTORY
;[esp+8] ;INICIO_PAGE_TABLE_ROM

;[esp+12] ;Direccion fisica inicial
;[esp+16] ;Direccion lineal final
;[esp+20] ;Direccion lineal inicial

compute_directions_amount:
mov eax,[esp+16] ;Direccion lineal final
mov ebx,[esp+20] ;Direccion lineal inicial
sub eax,ebx ;Cantidad de direcciones a paginar eax=eax-ebx
add eax,1 ;Agrego 1 que es la direccion inicial

;En eax tengo la cantidad de direcciones que tengo que paginar
compute_pages_number:
is_less_than_one_page:
mov ebx,eax
mov eax,1;Si la comparacion es valida, tengo 1 sola pagina
cmp ebx,4096
jl compute_directory_entries_number

is_more_than_one_page:
;Si no es menor que 4096 vuelvo a poner en eax la cantidad de direcciones
mov eax,ebx

xor edx,edx
mov ecx,4096
div ecx ;divido EDX:EAX en ECX y tengo resultado en EAX y resto en EDX

cmp edx,0;Si no me sobra nada, paso a calcular la cantidad de entradas del directorio
je compute_directory_entries_number
add eax,1 ;Si tengo resto agrego 1 pagina para poder paginar correctamente

compute_directory_entries_number:
;Llego con eax la cantidad de paginas (es lo unico que me importa)
mov ebx,eax
mov eax,1
cmp ebx,1024
jl complete_pagination_tree
;Si no es menor que 4096 vuelvo a poner en eax la cantidad de paginas
mov eax,ebx

xor edx,edx
mov ecx,1024
div ecx

cmp edx,0
je complete_pagination_tree
add eax,1


complete_pagination_tree:
;LLego con la cantidad de entradas del directorio de paginas en eax
;Cantida de paginas en ebx

push eax
push ebx

;[esp] ; Cantidad de paginas
;[esp+4] ; Cantidad de entradas del directorio

;[esp+8] ;Direccion de retorno

;[esp+12] ;INICIO_PAGE_DIRECTORY
;[esp+16] ;INICIO_PAGE_TABLE

;[esp+20] ;Direccion fisica inicial
;[esp+24] ;Direccion lineal final
;[esp+28] ;Direccion lineal inicial

mov ecx,[esp+28]
ror ecx,22
and ecx,0x3FF

;Para multiplicar salvo eax
push eax
mov eax,4
mul ecx
mov ecx,eax
pop eax

;Tengo en ecx la primer entrada del arbol de paginacion
mov edx,[esp+12];INICIO_PAGE_DIRECTORY
add ecx,edx

mov edi,[esp+28]
ror edi,12
and edi,0x3FF

;Para multiplicar salvo eax
push eax
mov eax,4
mul edi
mov edi,eax
pop eax

mov edx,[esp+16] ;INICIO_PAGE_TABLE
add edi,edx

push ecx
push edi

;[esp] ; Primer entrada tabla de paginas
;[esp+4] ; Primer entrada del directorio

;[esp+8] ; Cantidad de paginas
;[esp+12] ; Cantidad de entradas del directorio

;[esp+16] ;Direccion de retorno

;[esp+20] ;INICIO_PAGE_DIRECTORY
;[esp+24] ;INICIO_PAGE_TABLE

;[esp+28] ;Direccion fisica inicial
;[esp+32] ;Direccion lineal final
;[esp+36] ;Direccion lineal inicial

mov eax,[esp+12] ;Cantidad de entradas directorio
mov edi,[esp+4] ;Primer entrada del directorio
mov ecx,[esp] ;Primer entrada tabla de paginas
add ecx,0x3

ciclo_llenado_directorio:
  mov [edi],ecx
  add edi,4
  add ecx,0x1000 ;La proxima tabla esta en 0x400*4
  dec eax
  jnz ciclo_llenado_directorio

  ;[esp] ; Primer entrada tabla de paginas
  ;[esp+4] ; Primer entrada del directorio

  ;[esp+8] ; Cantidad de paginas
  ;[esp+12] ; Cantidad de entradas del directorio

  ;[esp+16] ;Direccion de retorno

  ;[esp+20] ;INICIO_PAGE_DIRECTORY
  ;[esp+24] ;INICIO_PAGE_TABLE

  ;[esp+28] ;Direccion fisica inicial
  ;[esp+32] ;Direccion lineal final
  ;[esp+36] ;Direccion lineal inicial
mov ecx,[esp+8] ;Cantidad de paginas
mov edi,[esp] ;Primer entrada de tabla de paginas
mov eax,[esp+28]
add eax,0x3 ;Primer direccion fisica + atributos

ciclo_llenado_paginas:
  mov [edi],eax
  add edi,4
  add eax,0x1000
  dec ecx
  jnz ciclo_llenado_paginas

;   ;Completo la primeras paginas de RAM y las segundas
;   mov edi,INICIO_PAGE_TABLE_RAM
;   mov eax,0x00000000+0x3
;
; ciclo_llenado_tablas_ram:
;   mov [edi],eax
;   add edi,4 ;Me muevo al proximo offset que es 4 bytes
;   add eax,0x1000 ;la siguiente pagina esta 4kb adelante
;   dec ecx
;   jnz ciclo_llenado_tablas_ram




pop eax
pop eax
pop eax
pop eax

ret
