; Mostrar en pantalla seis letras de 'A' a 'F' que se muevan por la pantalla.
; Tanto la posición inicial como la velocidad (fija) debe ser aleatoria.
; Al llegar al extremo de la pantalla, la letra debe rebotar.
; El código debe estar en modo protegido con segmentos de 32 bits.

; Hecho por Dario Alpern el 13/04/2018

CANT_LETRAS   equ 6
CANT_FILAS    equ 25
COLS_POR_FILA equ 80
MAX_VELOCIDAD equ 64 ;Un cuarto de fila o columna por tick de reloj.      
BITS 16

inicio:

%include "init_pci.inc"

     jmp pasaje_aMP
   
   ALIGN 8
   
GDT:
     dq 0        ;Selector nulo. No se puede usar.
     
CS_SEL equ $-GDT
      
     dw 0xffff   ;Limite bits 15 a 0
     dw 0        ;Base bits 15 a 0
     db 0xff     ;Base bits 23 a 16
     db 0x9a     ;Byte de derechos de acceso. Segmento de código DPL = 0
     db 0xcf     ;Granularidad y Default = 1, Límite bits 19 a 16.
     db 0xff     ;Base bits 31 a 24
         
DS_SEL equ $-GDT
      
     dw 0xffff   ;Limite bits 15 a 0
     dw 0        ;Base bits 15 a 0
     db 0        ;Base bits 23 a 16
     db 0x92     ;Byte de derechos de acceso. Segmento de datos DPL = 0
     db 0xcf     ;Granularidad y Default = 1, Límite bits 19 a 16.
     db 0x0      ;Base bits 31 a 24
      
GDT_tam equ $-GDT 
      
imagen_gdtr:
 
     dw  GDT_tam -1     ;Límite GDT (16 bits)
     dd  0xf0000 + GDT  ;Base GDT (32 bits)
     
     ALIGN 8

IDT:
     times 32*8 db 0  
   
     dw  handler_timer  ;PARTE BAJA del offset del handler
     dw  CS_SEL
     db  0
     db  0x8e
     dw  0x0            ;PARTE ALTA del offset del handler (ojo que base de CS apunta a ROM).
   
IDT_LEN equ $ - IDT  
   
imagen_idtr:
 
     dw  IDT_LEN -1     ;Límite IDT (16 bits)
     dd  0xf0000 + IDT  ;Base IDT (32 bits)
   
BUFFER_DOBLE_OFFS EQU 0x20000

; El orden queda little-endian para usar menos instrucciones, ya que 
; los procesadores Intel usan little-endian.
OFFS_FILA       EQU 0               ;Fila (fracción, luego entero)
OFFS_COLUMNA    EQU OFFS_FILA+2     ;Columna (fracción, luego entero)
OFFS_DELTAX     EQU OFFS_COLUMNA+2  ;Delta X (fracción, luego entero)
OFFS_DELTAY     EQU OFFS_DELTAX+2   ;Delta Y (fracción, luego entero)
LONG_ESTRUCTURA_POR_LETRA EQU OFFS_DELTAY+2

VARS_LETRAS equ BUFFER_DOBLE_OFFS+2*CANT_FILAS*COLS_POR_FILA
semilla equ VARS_LETRAS+CANT_LETRAS*LONG_ESTRUCTURA_POR_LETRA
FLAG_INT equ semilla + 4
BUFFER_VIDEO equ 0xb8000

pasaje_aMP:     
     
     cli         ;El pasaje a modo protegido debe hacerse sin interrupciones.
     lgdt [cs:imagen_gdtr]  ;Cargar registro GDTR.
     
     mov eax, cr0           ;Pasar a modo protegido encendiendo bit cero
     or  eax, 1             ;de CR0.
     mov cr0, eax
     
     jmp CS_SEL:inicio_32   ;Saltar al segmento de 32 bits.
     
  BITS 32   

;Subrutina para calcular número aleatorio actualizando la semilla.
;Entrada: Registro ESI: Rango del número aleatorio: de 0 a ESI-1.
;Salida: Registro EDX: Número aleatorio.
nro_aleatorio: 
     mov eax, 314159265
     mul dword [semilla]    ;Producto en EDX:EAX
     add eax, 0x1234567
     mov [semilla], eax
     mul esi                ;Producto en EDX:EAX
     ret                    ;0 <= EDX < ESI como se pide.

;Este manejador se ejecuta cada vez que el timer llega a cero.
;Esto ocurre 18.2 veces por segundo (es decir, cada 55 milisegundos).
handler_timer:
     push ds                ;Preservar registros de segmentación.
     push es
     pushad                 ;Preservar registros de uso general.
      
     mov ax, DS_SEL         ;Cargar registro de segmento de datos
     mov ds, ax             ;ya que no se sabe cuál es valor fuera del
                            ;manejador.      
     mov byte [FLAG_INT],1  ;Setear flag para indicar que pasó el tiempo.
     mov al, 0x20           ;Enviar End Of Interrupt (EOI) al PIC.
     out 0x20, al
      
     popad                  ;Restaurar registros de uso general.
     pop es                 ;Restaurar registros de segmentación.
     pop ds
     iretd                  ;Fin de manejador de interrupción (d = 32 bits).
      
inicio_32:
  
 xchg bx,bx
     mov ax, DS_SEL         ;Cargar registros de segmentos de datos y pila.
     mov ds, ax
     mov es, ax      
     mov ss, ax
     mov esp, 0x5000
     
;Inicializo el PIC
;Escribo en bx = 0x2028 para que me me interrumpan ahi
     mov bx, 0x2028
     mov al, 11h            ;IRQs activas x flanco, 
     out 20h, al
     mov al, bh             ;El PIC Nº1 arranca en INT tipo indicado por BH.
     out 21h, al
     mov al, 04h            ;PIC 1 Master, Slave ingresa 
     out 21h, al
     mov al, 01h            ;Modo 8086
     out 21h, al
     mov al, 0FEh           ;Máscara de interrupciones del primer PIC:
     out 21h, al            ;11111110 -> IRQ0 habilitado, el resto deshabilitado.
; Ahora inicializamos el PIC Nº2
; ICW1
     mov al, 11h            ;IRQs activas x flanco,cascada, 
     out 0A0h, al
; ICW2
     mov al, bl             ;El PIC Nº2 arranca en INT tipo indicado por BL.
     out 0A1h, al
; ICW3
     mov al, 02h            ;PIC2 Slave, ingresa Int x IRQ2
     out 0A1h, al
; ICW4
     mov al, 01h            ;Modo 8086
     out 0A1h, al
; Enmascaramos el resto de las Interrupciones
; (las del PIC Nº2)
     mov al, 0FFh           ;Máscara de interrupciones del primer PIC:
     out 0A1h, al           ;11111111 -> Todas las interrupciones deshabilitadas.
     
     lidt [cs:imagen_idtr]  ;Cargar el registro IDTR.
      
     rdtsc; EDX:EAX 
     mov [semilla], eax
;Inicializar el array de estructuras correspondiente a cada letra.
     mov ebx, VARS_LETRAS   ;Offset (dirección efectiva) del array.
     mov ecx, CANT_LETRAS   ;Cantidad de elementos del array.
ciclo_init:
     mov esi,CANT_FILAS*256
     call nro_aleatorio
     mov [ebx+OFFS_FILA],dx    ;Fracción y entero del número de fila.
     mov esi,COLS_POR_FILA*256
     call nro_aleatorio
     mov [ebx+OFFS_COLUMNA],dx ;Fracción y entero del número de columna.
     mov esi,MAX_VELOCIDAD*2
     call nro_aleatorio     
     sub edx,MAX_VELOCIDAD     ;Convertir a rango -MAX_VELOCIDAD a MAX_VELOCIDAD
     mov [ebx+OFFS_DELTAX],dx  ;Fracción y entero de la velocidad horizontal.
     mov esi,MAX_VELOCIDAD*2
     call nro_aleatorio     
     sub edx,MAX_VELOCIDAD     ;Convertir a rango -MAX_VELOCIDAD a MAX_VELOCIDAD
     mov [ebx+OFFS_DELTAY],dx  ;Fracción y entero de la velocidad vertical.
     
     add ebx,LONG_ESTRUCTURA_POR_LETRA ;Apuntar al siguiente elemento del array.
     loop ciclo_init ;decrementa ecx y salta si no es 0
    ;En instrcucciones de cadena:
    ;Instruccion std -> decrementa puntero (flag dirección <- 1).
    ;Instruccion cld -> incrementa puntero (flag dirección <- 0).
;Programar el timer cero para que interrumpa 18,2 veces por segundo.
     mov al, 0x36              ;Timer counter cero (bits 7-6).
     out 0x43, al
     mov al,0
     out 0x40, al              ;Escribir el byte menos significativo de la cuenta.
     out 0x40, al              ;Escribir el byte más significativo de la cuenta.
     sti                       ;Habilitar interrupciones.
;Arranca ciclo principal de animación.    
ciclo_anim:
;Borrar buffer doble.
     cld                ;La instrucción de cadena incrementa puntero.
     mov edi, BUFFER_DOBLE_OFFS
     mov ecx, CANT_FILAS * COLS_POR_FILA
     mov ax, 0x0720     ;Espacio con atributo blanco sobre negro
     rep stosw          ;Operatoria de esta instrcción de cadena:
                        ;[ES:EDI] <- AX
                        ;EDI <- EDI +/- 2 (signo según flag de dirección)
                        ;ECX <- ECX - 1
                        ;Repite instrucción si ECX es distinto de cero.
;Poner las letras en el buffer doble.
     mov ebx, VARS_LETRAS
     mov ecx, CANT_LETRAS
     mov dl,'A'
ciclo_mostrar_letras:
;Hallar ubicación de la letra en el buffer doble: 2*(fila*COLS_POR_FILA+columna).
     mov al,COLS_POR_FILA
     mul byte [ebx+OFFS_FILA+1]     ;Producto en AX.
     add al, [ebx+OFFS_COLUMNA+1]   ;Otra posibilidad (movzx dx, byte[ebx+2])
     adc ah, 0                      ;add ax,dx (mov con zero extend)
     movzx eax, ax                  ;Completar producto a 32 bits.
     mov [BUFFER_DOBLE_OFFS+eax*2],dl ;Poner la letra en el buffer doble.
     add ebx,LONG_ESTRUCTURA_POR_LETRA ;Apuntar al siguiente elemento del array.
     inc dl                         ;Indicar siguiente letra (en ASCII).
     loop ciclo_mostrar_letras      ;Cerrar ciclo (decrementar ECX y saltar si no es cero).
;Copiar buffer doble a buffer de video.
     mov esi, BUFFER_DOBLE_OFFS     ;Puntero origen de datos.
     mov edi, BUFFER_VIDEO          ;Puntero destino de datos.
     mov ecx, COLS_POR_FILA*CANT_FILAS 
     rep movsw          ;Operatoria de esta instrcción de cadena:
                        ;WORD [ES:EDI] <- WORD [DS:ESI]
                        ;ESI <- ESI +/- 2 (signo según flag de dirección)
                        ;EDI <- EDI +/- 2 (signo según flag de dirección)
                        ;ECX <- ECX - 1
                        ;Repite instrucción si ECX es distinto de cero.
;Actualizar posición de las letras.
     mov ebx, VARS_LETRAS
     mov ecx, CANT_LETRAS
actualizar_posic_letras:
;Actualizar columna.
     mov ax,[EBX+OFFS_COLUMNA]   ;Obtener columna.
     add ax,[EBX+OFFS_DELTAX]    ;Sumar velocidad horizontal.
     cmp ax,COLS_POR_FILA * 256  ;Verificar si la letra llegó al tope.
     jb guardar_columna          ;Saltar si no es así.
     neg word [EBX+OFFS_DELTAX]  ;Cambiar signo de la velocidad horizontal.
     mov ax,[EBX+OFFS_COLUMNA]   ;Obtener colummna.
     add ax,[EBX+OFFS_DELTAX]    ;Sumar velocidad horizontal.
guardar_columna:
     mov [EBX+OFFS_COLUMNA],ax   ;Guardar columna
;Actualizar fila.
     mov ax,[EBX+OFFS_FILA]      ;Obtener fila.
     add ax,[EBX+OFFS_DELTAY]    ;Sumar velocidad vertical.
     cmp ax,CANT_FILAS * 256     ;Verificar si la letra llegó al tope.
     jb guardar_fila             ;Saltar si no es así.
     neg word [EBX+OFFS_DELTAY]  ;Cambiar signo de la velocidad vertical.
     mov ax,[EBX+OFFS_FILA]      ;Obtener fila.
     add ax,[EBX+OFFS_DELTAY]    ;Sumar velocidad vertical.
guardar_fila:
     mov [EBX+OFFS_FILA],ax      ;Guardar fila.

     add ebx,LONG_ESTRUCTURA_POR_LETRA ;Apuntar al siguiente elemento del array.
     loop actualizar_posic_letras  ;Cerrar ciclo (decrementar ECX y saltar si no es cero).
     
FIN_LOOP:
     cmp byte [FLAG_INT], 1        ;Esperar a que llegue el tick de reloj.
     jne FIN_LOOP
     mov byte [FLAG_INT], 0        ;Apagar el flag para usarlo en la sig. iteración.
     jmp ciclo_anim                ;Continuar animación.
     
     
     times 0xFFF0 - ($ - inicio) db 0  ;Completar hasta 64 KB - 16 bytes.

     
BITS 16     
reset:
     jmp inicio
     
     times 0x10 - ($ -reset) db 0      ;Completar hasta 64 KB.
