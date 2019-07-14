global __SET_PAGINATION_STRUCTURE
section .bss

lineal_address_initial: resb 4
lineal_address_final: resb 4
phisical_address_initial: resb 4

pagination_directory: resb 4
tables_page: resb 4

pages_number: resb 32
directorie_entries_number: resb 4

firts_table_entry: resb 4
firts_directory_entry: resb 4

lineal_address: resb 4


section .set_page_structure
__SET_PAGINATION_STRUCTURE:
USE32
;MUEVO LOS PARAMETROS A LAS VARIABLES LOCALES

mov eax,[esp+4]
mov [pagination_directory],eax

mov eax,[esp+8]
mov [tables_page],eax

mov eax,[esp+20]
mov [lineal_address_initial],eax

mov eax,[esp+16]
mov [lineal_address_final],eax

mov eax,[esp+12]
mov [phisical_address_initial],eax

compute_directions_amount:
mov eax,[lineal_address_final] ;Direccion lineal final
mov ebx,[lineal_address_initial] ;Direccion lineal inicial
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

mov [pages_number],ebx
mov [directorie_entries_number],eax

mov ecx,[lineal_address_initial]
ror ecx,22
and ecx,0x3FF

;Para multiplicar salvo eax
push eax
mov eax,4
mul ecx
mov ecx,eax
pop eax

;Tengo en ecx la primer entrada del arbol de paginacion
mov edx,[pagination_directory];INICIO_PAGE_DIRECTORY
add ecx,edx

mov edi,[lineal_address_initial]
ror edi,12
and edi,0x3FF

;Para multiplicar salvo eax
push eax
mov eax,4
mul edi
mov edi,eax
pop eax

mov edx,[tables_page] ;INICIO_PAGE_TABLE
add edi,edx

mov [firts_table_entry],edi
mov [firts_directory_entry],ecx


mov eax,[directorie_entries_number] ;Cantidad de entradas directorio
mov edi,[firts_directory_entry] ;Primer entrada del directorio
mov ecx,[firts_table_entry] ;Primer entrada tabla de paginas
add ecx,0x3

ciclo_llenado_directorio:
  mov [edi],ecx
  add edi,4
  add ecx,0x1000 ;La proxima tabla esta en 0x400*4
  dec eax
  jnz ciclo_llenado_directorio


mov ecx,[pages_number] ;Cantidad de paginas
mov edi,[firts_table_entry] ;Primer entrada de tabla de paginas
mov eax,[phisical_address_initial]
add eax,0x3 ;Primer direccion fisica + atributos

ciclo_llenado_paginas:
  mov [edi],eax
  add edi,4
  add eax,0x1000 ;Paso a la siguiente pagina
  dec ecx
  jnz ciclo_llenado_paginas

ret

section .get_page_from_linear_address
;MUEVO LOS PARAMETROS A LAS VARIABLES LOCALES
