EXTERN __INICIO_TABLA_DE_DIGITOS
EXTERN __FIN_TABLA_DE_DIGITOS

EXTERN __BUFFER_TECLADO
EXTERN __BUFFER_TECLADO_ESTADO
EXTERN __EXIT_CHARACTER

section .rutina_teclado
USE32
  mov ecx,__INICIO_TABLA_DE_DIGITOS ;El lugar donde vamos a copiar las teclas
  mov edx,__FIN_TABLA_DE_DIGITOS ;La ultima direccion en la que tengo que copiar teclas
ciclo_llenado:
ciclo_polling:
  ;leyendo el puerto 0x64 (IN AL,0x64) y esperar que el bit cero pase a uno.
  in al,__BUFFER_TECLADO_ESTADO
  mov bl,al ;Guardo el valor de al
  and al,1  ;Hago un and con 00000001
  cmp al,1  ;Comparo con 00000001, con esto se si el bit 1 vale 1
  jnz ciclo_polling  ;Si no vale 1 vuelvo al inico
  in al,__BUFFER_TECLADO  ;Leo el puerto de datos
  mov bl,al ;Guardo el valor leido
  and bl,128 ;Hago un and con 10000000
  cmp bl,128 ;Comparo si ese bit vale 1(Si es asi estoy detectando cuando se solto)
  jz ciclo_polling ;Para evitar el doble lectura, ademas erronea porque el bit 7
                    ;es indicador de si solte o presione

  ;Muevo el valor a la tabla
  mov [ecx],al

  ;Si la tecla presionada es "S", entonces tengo que salir
  cmp al,__EXIT_CHARACTER
  jz fin_lectura

  ;Voy incremntando ecx de a 1 byte(tamanio de al)
  add ecx,1
  ;Esto es para saltar cuando ecx es distinto de edx
  cmp edx,ecx
  jnz ciclo_llenado

  ;Para sobreescribir lo que hago es resetaer ecx
  mov ecx,__INICIO_TABLA_DE_DIGITOS
  jmp ciclo_llenado ;Salto incondicional

fin_lectura:
  xchg bx,bx ;Para ver si salio
  ret ;Para volver despues de copiar
