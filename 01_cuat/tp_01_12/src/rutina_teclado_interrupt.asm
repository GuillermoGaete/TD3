EXTERN __BUFFER_TECLADO

EXTERN __0_CHARACTER
EXTERN __1_CHARACTER

EXTERN __F_CHARACTER
EXTERN __E_CHARACTER
EXTERN __D_CHARACTER
EXTERN __C_CHARACTER
EXTERN __B_CHARACTER
EXTERN __A_CHARACTER

EXTERN LONG_TP_MESSAGE
EXTERN __PRINT_TEXT
EXTERN __PRINT_NUMBER

EXTERN __ENTER_CHARACTER

GLOBAL __INICIO_BUFFER_TECLADO
GLOBAL __FLAG_TECLADO_READY
GLOBAL __CURRENT_TABLE_INDEX

section .data
__SIZE_BUFFER_TECLADO_BYTES EQU 9
BUFFER_MESSAGE  DB "Buffer teclado:"
LONG_BUFFER_MESSAGE EQU $-BUFFER_MESSAGE
section .bss
__INICIO_BUFFER_TECLADO resb 9
__FLAG_TECLADO_READY resb 4
__CURRENT_TABLE_INDEX resb 4
EXTERN TAREA_TECLADO

section .isr_teclado
USE32
  pushad
  in al,__BUFFER_TECLADO               ;Obtener informacion del controlador de teclado
  mov bl,al ;Guardo el valor leido
  and bl,128 ;Hago un and con 10000000
  cmp bl,128 ;Comparo si ese bit vale 1(Si es asi estoy detectando cuando se solto)
  jz on_release ;Para evitar el doble lectura, ademas erronea porque el bit 7
                ;es indicador de si solte o presione
  jnz on_press

;si presionamos la tecla
on_press:
  push ax
  call process_key
  pop ax
  jmp finish_isr

;si soltamos la tecla
on_release:
  jmp finish_isr

process_key:
  xor eax,eax
  xor ebx,ebx
  mov ax, [esp+4]

  mov ebx,0xFF

  cmp eax,__1_CHARACTER
  JL finish_process_key

  cmp eax,__0_CHARACTER
  JG check_numbers
  JE set_zero

  sub eax,1
  mov ebx,eax
  jmp check_valid_key

set_zero:
  mov ebx,0x0
  jmp check_valid_key

check_numbers:
  cmp eax,__F_CHARACTER
  mov ecx,0x0F
  CMOVE ebx,ecx

  cmp eax,__E_CHARACTER
  mov ecx,0x0E
  CMOVE ebx,ecx

  cmp eax,__D_CHARACTER
  mov ecx,0x0D
  CMOVE ebx,ecx

  cmp eax,__C_CHARACTER
  mov ecx,0x0C
  CMOVE ebx,ecx

  cmp eax,__B_CHARACTER
  mov ecx,0x0B
  CMOVE ebx,ecx

  cmp eax,__A_CHARACTER
  mov ecx,0x0A
  CMOVE ebx,ecx

  cmp eax,__ENTER_CHARACTER
  mov ecx,0xEE
  CMOVE ebx,ecx

  jmp check_valid_key

check_valid_key:
  cmp ebx,0xFF
  ;Si ebx vale lo mismo que al principio significa que no es una tecla valida
  JE finish_process_key

  cmp ebx,0xEE
  ;Si presionamos la tecla enter
  JE finish_process_key_flag

  ;Cargo el tamaño del buffer
  xor eax,eax
  mov eax,__SIZE_BUFFER_TECLADO_BYTES

  ;Si es menor a 1 dword es un buffer pequeño
  ;lo considero asi por la funcion que hace la rotacion que utiliza
  ;los registros de 32 bits
  cmp eax,4
  jle is_short_buffer
  jmp rotate_larger_buffer

;Al ser un buffer menor a 4 bytes, simplemente hago una rotacion con la tecla
is_short_buffer:
  push dword __INICIO_BUFFER_TECLADO
  push dword __SIZE_BUFFER_TECLADO_BYTES
  rol ebx,28;Lo llevo al final
  push ebx
  call rotate_short_buffer
  pop eax
  pop eax
  pop eax
  jmp finish_process_key

;Si es un buffer mayor a 4 bytes
rotate_larger_buffer:
  push ebx ;En ebx tengo la tecla presionada, en el nibble menos significativo

  ;De la linea 98 eax tiene la cantidad de bytes en __SIZE_BUFFER_TECLADO_BYTES
  xor ecx,ecx
  xor edx,edx
  mov cx,4
  div ecx ;Divido eax en ecx, que vale 4 = 1dword

  ;En eax tengo la cantidad de dwords(4 bytes) enteros que tengo
  ;Ej: 6 bytes es el tamanio del buffer entonces => eax=1
  ;En edx tengo la cantidad de bytes restantes edx=2

  ;Salvo los valores
  push eax
  push edx

  ;Calculo la posicion en memoria del ultimo dword entero del buffer
  ;la guardo en eax
  mov edx,4
  mul edx

  pop edx;edx la cantidad de bytes restantes
  pop ecx;ecx la cantidad de dwords enteros

  ;Coloco en ebx la posicion en la que tengo que insertar el caracter
  mov ebx,__INICIO_BUFFER_TECLADO
  add ebx,eax

  ;Mueve el primer byte
  push ebx
  push edx
  sub ebx,1;En una posicion anterior tengo el valor a ingresar
  mov ebx,[ebx]
  ror ebx,4
  rol ebx,28
  push ebx
  call rotate_short_buffer
  pop eax
  pop eax
  pop ebx ;En ebx tengo la direccion

  ;ebx la cantidad a contar y comprar con __INICIO_BUFFER_TECLADO
  sub ebx,4

ciclo_rotacion:
  push ebx
  push 4
  sub ebx,1
  mov ebx,[ebx]
  ror ebx,4
  rol ebx,28
  push ebx ;Coloco el ultimo caracter en el nibble(4 bits) mas significativo de ebx
  call rotate_short_buffer
  pop eax
  pop eax
  pop ebx ;En ebx tengo la direccion
  sub ebx,4
  cmp ebx,__INICIO_BUFFER_TECLADO
  jne ciclo_rotacion

  ;Estoy en el primer dword en el que tengo que meter la tecla
  pop eax;Saco la letra
  rol eax,28 ;La roto

  push ebx
  push 4
  push eax
  call rotate_short_buffer
  pop eax
  pop eax
  pop eax

  jmp finish_process_key

rotate_short_buffer:
  mov eax,[esp+12];Primero saco el inicio de la direccion a rotar
  mov edx,[eax] ;Traigo el valor actual en esa direccion
  mov eax,[eax] ;Traigo el valor actual en esa direccion

  mov ebx,[esp+4];Saco el valor que contiene la letra

  ;Ingreso la letra en el buffer local nuevo
  SHLD eax, ebx, 4

  ;Preparo las mascaras
  mov ecx,0xFFFFFFFF

  mov ebx,[esp+8] ;Tamanio maximo permitido

  push eax
  xor eax,eax

ciclo_desplazar:
  SHLD ecx,eax,8
  dec ebx
  cmp ebx,0
  jne ciclo_desplazar

  pop eax

  mov ebx,ecx
  not ecx

  ;Aplico las mascaras
  and eax,ecx
  and edx,ebx
  or eax,edx

  mov ecx,[esp+12]
  mov [ecx],eax
  ret

finish_process_key:
  ret

finish_process_key_flag:
  mov dword [__FLAG_TECLADO_READY],0x00000001
  ret

finish_isr:
  mov al,20h            ;Indicarle al PIC que finalizo la interrupcion.
  out 20h,al

  ;Muestro en pantalla
  push dword BUFFER_MESSAGE
  push dword LONG_BUFFER_MESSAGE
  push dword 24 ;Fila
  push dword LONG_TP_MESSAGE
  call __PRINT_TEXT
  times 4 pop eax

  mov eax,[__INICIO_BUFFER_TECLADO]
  push eax
  mov eax,[__INICIO_BUFFER_TECLADO+4]
  push eax
  push dword 2 ;Cantidad de words
  push dword 24 ;Fila donde muestro el numero
  push dword LONG_TP_MESSAGE+LONG_BUFFER_MESSAGE   ;Columna donde muestro el numero
  call __PRINT_NUMBER
  times 5 pop ecx
  ;Como el timer me controla el halt tengo que ver si la tecla enter se presiono
  ;desde aca
  call TAREA_TECLADO

  popad
  iret
