section .copy
USE32
copy:
  ;mov eax,__INICIO_RUTINAS_ROM
  mov ecx, [esp+4];longitud
  mov edi, [esp+8];destino
  mov esi, [esp+12];fuente
  ;mov esi,__INICIO_RUTINAS_ROM ;Direccion desde donde voy a copiar en ROM
  ;mov edi,__INICIO_RUTINAS_RAM ;Direccion a donde voy a copiar en RAM
  ;mov ecx,__LONGITUD_RUTINAS ; Con linker script vamos a calcular la
                             ; cantidad de lineas a copiar
ciclo:
  mov al,[esi] ;Vamos de byte en byte, copiamos de memoria a registro al ser el opreando 1 byte
  mov [edi],al ;Copiamos de registro a memoria
  inc esi ;al incrementar en 1 esi copiamos el siguiente byte
  inc edi
  dec ecx ;Al decrementar
  jne ciclo ;Esto es para saltar cuando ecx es 0

  ret ;Para volver despues de copiar
