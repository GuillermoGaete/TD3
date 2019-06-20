section .copy
USE32
  ;mov eax,__INICIO_RUTINAS_ROM
  mov ecx, [esp+4]
  mov edi, [esp+8]
  mov esi, [esp+12]
  ;mov esi,__INICIO_RUTINAS_ROM ;Direccion desde donde voy a copiar en ROM
  ;mov edi,__INICIO_RUTINAS_RAM ;Direccion a donde voy a copiar en RAM
  ;mov ecx,__LONGITUD_RUTINAS ; Con linker script vamos a calcular la
                             ; cantidad de lineas a copiar
ciclo_copy:
  mov al,[esi] ;Vamos de byte en byte, copiamos de memoria a registro al ser el opreando de 8 bits esi toma solo el de 1 byte
  mov [edi],al ;Copiamos de registro a memoria
  inc esi ;al incrementar en 1 esi copiamos el siguiente byte
  inc edi
  dec ecx ;Al decrementar
  jne ciclo_copy ;Esto es para saltar cuando ecx es 0

  ret ;Para volver despues de copiar
