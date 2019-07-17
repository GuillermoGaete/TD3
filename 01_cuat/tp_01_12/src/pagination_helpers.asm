EXTERN INICIO_PAGE_DIRECTORY
GLOBAL __SET_PAGINATION_STRUCTURE
GLOBAL FIX_PAGE_ERROR
section .bss

lineal_address_initial: resb 4
lineal_address_final: resb 4
phisical_address_initial: resb 4

pagination_directory_base: resb 4
table_page_base: resb 4

current_table_page_entry: resb 4
current_directory_entry: resb 4
current_phisical_address: resb 4
current_linear_address: resb 4

lineal_address: resb 4
lineal_address_to_paginate resb 4

section .text
__SET_PAGINATION_STRUCTURE:
USE32
;MUEVO LOS PARAMETROS A LAS VARIABLES LOCALES

mov eax,[esp+4]
mov [pagination_directory_base],eax

mov eax,[esp+8]
mov [table_page_base],eax

mov eax,[esp+20]
mov [lineal_address_initial],eax
mov [current_linear_address],eax

mov eax,[esp+16]
mov [lineal_address_final],eax

mov eax,[esp+12]
mov [phisical_address_initial],eax
mov [current_phisical_address],eax

compute_first_page_entry:
  mov ecx,[lineal_address_initial]
  ror ecx,12
  and ecx,0x3FF
  rol ecx,2

  mov eax,[table_page_base]
  add eax,ecx
  mov [current_table_page_entry],eax

compute_first_directory_entry:
  mov ecx,[lineal_address_initial]
  ror ecx,22
  and ecx,0x3FF
  rol ecx,2

  mov eax,[pagination_directory_base]
  add eax,ecx
  mov [current_directory_entry],eax

  mov edx,1023
ciclo_llenado_paginas:
  mov eax,[current_table_page_entry]
  mov ebx,[current_directory_entry]
  cmp edx,1023
  je llenado_entrada_directorio
  jmp post_llenado_entrada_directorio
llenado_entrada_directorio:
  add eax,0x3
  mov [ebx],eax
  sub eax,0x3
  add dword [current_directory_entry],4
  mov edx,0
post_llenado_entrada_directorio:
  mov eax,[current_phisical_address]
  mov ebx,[current_table_page_entry]

  add eax,0x3
  mov [ebx],eax

  add dword [current_table_page_entry],4
  add dword [current_phisical_address],0x1000
  add dword [current_linear_address],0x1000
  add edx,1

  mov eax,[lineal_address_final]
  cmp [current_linear_address],eax
  jl ciclo_llenado_paginas

ret

FIX_PAGE_ERROR:
  mov eax,[esp+4]
  mov [lineal_address_to_paginate],eax

  ;Page table offset
  mov ecx,[lineal_address_to_paginate]
  ror ecx,12
  and ecx,0x3FF
  rol ecx,2
  push ecx

  ;Directory page offset
  mov ecx,[lineal_address_to_paginate]
  ror ecx,22
  and ecx,0x3FF
  rol ecx,2

  xchg bx,bx
  mov eax,INICIO_PAGE_DIRECTORY
  add eax,ecx
  mov ecx,[eax]
  and ecx,0x00000001

  cmp ecx,0x00000000
  je no_present_directory
  ;Ya esta presente
  xor edx,edx
  mov ecx,[eax]
  and ecx,0xFFFFF000
  mov eax,ecx
  ;En ecx tengo la base
  pop ecx
  mov edx,0x80000000
  add edx,0x3
  mov [eax+ecx],edx
  ret
no_present_directory:

return:
ret
