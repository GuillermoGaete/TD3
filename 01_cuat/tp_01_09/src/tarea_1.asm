EXTERN __FLAG_TIMER

EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __CURRENT_TABLE_INDEX
EXTERN __ACUM

section .tarea_1
USE32
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
  mov edx,[__ACUM]
  add edx,ecx
  mov [__ACUM],edx
  mov ecx,edx
  ;en ecx tengo el numero a mostrar
  MOV ESI, 0xb8000   ; Puntero

ciclo_mostrar:
  rol ecx,4
  push ecx
  and ecx,0x0000000F
  call return_ascii
  ;Retorna en ecx el valor a mostar
  ;Tengo que enviar el numero y retornar de alguna forma el codigo return_ascii
  MOV [ESI], cl  ; Escribo en pantalla
  MOV BYTE [ESI+1], 0x07
  ADD ESI, 2  ; Incremento el puntero
  pop ecx
  add eax,1
  cmp eax,7
  jle ciclo_mostrar

  mov eax,0
  mov [__CURRENT_TABLE_INDEX],eax

return:
  hlt
  ret ;Para volver

return_ascii:
  add ecx,48
  cmp ecx,58
  jl finish_return_ascii
  add ecx,7
finish_return_ascii:
  ret
