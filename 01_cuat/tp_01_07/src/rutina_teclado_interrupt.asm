EXTERN __BUFFER_TECLADO

EXTERN __UD_CHARACTER
EXTERN __DE_CHARACTER
EXTERN __GP_CHARACTER
EXTERN __DF_CHARACTER

EXTERN __INICIO_INVALIDATE_EN_NUCLEO_RAM

section .isr_teclado
USE32
  pushad
  xchg bx,bx

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

finish_isr:
  mov al,20h            ;Indicarle al PIC que finalizo la interrupcion.
  out 20h,al

  popad
  iret

process_key:
  xor eax,eax
  mov ax, [esp+4] ;en eax tengo el valor de la excepcion

  ;Enunciado: #DE=Y, #UD=U, #DF=I, #GP=O.

  ;Si la tecla presionada es "Y", entonces tengo que generar la excepcion
  cmp al,__UD_CHARACTER
  jz generate_ud

  ;Si la tecla presionada es "U", entonces tengo que generar la excepcion
  cmp al,__DE_CHARACTER
  jz generate_de

  ;Si la tecla presionada es "I", entonces tengo que generar la excepcion
  cmp al,__DF_CHARACTER
  jz generate_df

  ;Si la tecla presionada es "O", entonces tengo que generar la excepcion
  cmp al,__GP_CHARACTER
  jz generate_gp
  ret

generate_de:
  mov ebx,0
  div ebx
  ret

generate_ud:
  db 0xF0;Requerido para direcciones mayores
  ret

generate_df:
  ;Para generarla podemos invalidar la idt de la division por 0 y despues dividir por 0, eso va a producir una falla de segmentacion al vectorizar la
  ;division por 0
  push 0
  call __INICIO_INVALIDATE_EN_NUCLEO_RAM
  pop eax
  ;El descriptor ahora no es valido, al vectorizar la excepcion de div 0 salta df
  mov ebx,0
  div ebx
  ret

generate_gp:
  ;Loading the CR0 register with a set PG flag (paging enabled / bit 31)  and a clear PE flag (protection disabled / bit 0).
  mov eax,cr0
  and eax,0xFFFFFFFE
  or  eax,0x80000000
  mov cr0,eax
  ret
