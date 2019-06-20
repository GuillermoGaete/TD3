; Hacer un programa que muestre la cantidad de decimas de segundo que estuvo
; corriendo en modo largo (64 bits) y la cantidad de teclas presionadas.
; Utilizar para ello las interrupciones en modo protegido 8 (reloj) y 9 (teclado).
;
; Hecho por Dario Alejandro Alpern el 11 de marzo de 2008.
;
BUF_VIDEO                EQU 0xB8000
INICIO_TABLAS_PAGINACION EQU 0x90000      ; Debe ser multiplo de 0x1000
DIR_FISICA_PML4          EQU INICIO_TABLAS_PAGINACION
DIR_FISICA_PDP           EQU DIR_FISICA_PML4 + 0x1000
DIR_FISICA_DP            EQU DIR_FISICA_PDP + 0x1000

[bits 16]
org 8000h       ;Direccion donde carga el bootloader este programa.

comienzo:jmp inicio
gdt     db 0,0,0,0,0,0,0,0  ;Descriptor nulo
; Valores que van en la tabla de descriptores globales (dos descriptores)
; Primer descriptor: Segmento de codigo de 64 bits.
cs_sel_64  equ $-gdt
        db 0FFh         ;Bits 7-0 del limite (no usado en 64 bits).
        db 0FFh         ;Bits 15-8 del limite (no usado en 64 bits).
        db 0            ;Bits 7-0 de la base (no usado en 64 bits).
        db 0            ;Bits 15-8 de la base (no usado en 64 bits).
        db 0            ;Bits 23-16 de la base (no usado en 64 bits).
	db 9Ah		;Byte de derechos de acceso:
			;Bit 7=1: Segmento Presente.
			;Bits 6,5=00: Nivel de Privilegio cero.
                        ;Bit 4=1: Segmento de codigo o datos.
                        ;Bit 3=1: Descriptor correspondiente a codigo.
			;Bit 2=0: Segmento no conforme.
                        ;Bit 1=1: El segmento de codigo se puede leer.
			;Bit 0=0: El segmento no fue accedido.
        db 0AFh         ;Bit 7=1: Granularidad (no usado en 64 bits).
                        ;Bit 6,5=01: Segmento de 64 bits (en modo largo).
                        ;Bit 4=0: No usado.
                        ;Bits 3-0=1111: Bits 19-16 del limite (no usados
                        ;en modo largo).
        db 0            ;Bits 31-24 de la base (no usado en 64 bits).
; Segundo descriptor: Segmento de codigo de 32 bits.
cs_sel_32  equ $-gdt
        db 0FFh         ;Bits 7-0 del limite.
        db 0FFh         ;Bits 15-8 del limite.
        db 0            ;Bits 7-0 de la base.
        db 0            ;Bits 15-8 de la base.
        db 0            ;Bits 23-16 de la base.
	db 9Ah		;Byte de derechos de acceso:
			;Bit 7=1: Segmento Presente.
			;Bits 6,5=00: Nivel de Privilegio cero.
                        ;Bit 4=1: Segmento de codigo o datos.
                        ;Bit 3=1: Descriptor correspondiente a codigo.
			;Bit 2=0: Segmento no conforme.
                        ;Bit 1=1: El segmento de codigo se puede leer.
			;Bit 0=0: El segmento no fue accedido.
        db 0CFh         ;Bit 7=1: Granularidad.
                        ;Bit 6,5=10: Segmento de 32 bits (en modo largo).
                        ;Bit 4=0: No usado.
                        ;Bits 3-0=1111: Bits 19-16 del limite.
        db 0            ;Bits 31-24 de la base.
; Tercer descriptor: Segmento de datos.
ds_sel  equ $-gdt
        db 0FFh         ;Bits 7-0 del limite (no usado en 64 bits).
        db 0FFh         ;Bits 15-8 del limite (no usado en 64 bits).
        db 0            ;Bits 7-0 de la base (no usado en 64 bits).
        db 0            ;Bits 15-8 de la base (no usado en 64 bits).
        db 0            ;Bits 23-16 de la base (no usado en 64 bits).
	db 92h		;Byte de derechos de acceso:
			;Bit 7=1: Segmento Presente.
			;Bits 6,5=00: Nivel de Privilegio cero.
                        ;Bit 4=1: Segmento de codigo o datos.
			;Bit 3=0: Descriptor correspondiente a datos.
                        ;Bit 2=0: Offset <= Limite.
			;Bit 1=1: El segmento de datos se puede escribir.
			;Bit 0=0: El segmento no fue accedido.
        db 0CFh         ;Bit 7=0: Granularidad (no usado en 64 bits).
                        ;Bit 6,5=10: Segmento de 32 bits.
			;Bit 4=0: No usado.
                        ;Bits 3-0=1111: Bits 19-16 del limite (no usados
                        ;en modo largo).
        db 0            ;Bits 31-24 de la base (no usado en 64 bits).
long_gdt equ $-gdt
; La BIOS que corria antes de este programa modificaba las IRQs, las mapeaba distinto
; Las compuertas de interrupcion en modo largo tienen 16 bytes cada una.
; Si el programa ocupa mas de 32 KB y hay que inicializar la parte alta del
; offset (bits 31-16), habra que hacerlo en tiempo de ejecucion.
; Compuertas de interrupcion correspondientes a INT 0 a INT 7 (no usados).
idt     times 8 dq 0,0  ;16 bytes por compuerta.
; Compuerta de interrupcion de 16 bytes correspondiente a INT 8.
        dw int8han      ;Bits 15-0 del offset.
        dw cs_sel_64    ;Selector del segmento de codigo.
        db 0            ;Cantidad de palabras que ocupan los parametros.
        db 8Eh          ;Compuerta de interrupcion de 64 bits.
	dw 0            ;Bits 31-16 del offset.
        dd 0            ;Bits 63-32 del offset.
        dd 0            ;Reservado.
; Compuerta de interrupcion de 16 bytes correspondiente a INT 9.
	dw int9han	;Bits 15-0 del offset.
        dw cs_sel_64    ;Selector del segmento de codigo.
        db 0            ;Cantidad de palabras que ocupan los parametros.
        db 8Eh          ;Compuerta de interrupcion de 64 bits.
	dw 0            ;Bits 31-16 del offset.
        dd 0            ;Bits 63-32 del offset.
        dd 0            ;Reservado.

long_idt equ $-idt
texto1  dw 12*160+15*2
        db "Modo de 64 bits no soportado: CPUID no funciona",0
texto2  dw 12*160+15*2
        db "Modo de 64 bits no soportado: sin CPUID extendido",0
texto3  dw 12*160+15*2
        db "Modo de 64 bits no soportado: EM64T no funciona",0
texto4  dw 24*160+25*2
        db "Hecho por Dario Alpern el 4/5/2011.",0
texto5  dw 11*160+25*2
        db "Segundos en modo largo:",0
texto6  dw 12*160+25*2
        db "Teclas presionadas:",0
fin_texto6:

gdtr:                   ;Informacion a almacenar en el registro GDTR.
        dw long_gdt-1   ;Limite de la tabla de descriptores globales.
	dd gdt		            ;Base de la tabla de descriptores globales.
                        ;Se llena durante la ejecucion del programa.
idtr:                   ;Informacion a almacenar en el registro IDTR.
        dw long_idt-1   ;Limite de la tabla de descriptores de interrupcion.
        dd idt          ;Base de la tabla de descriptores de interrupcion.
tics    dd 0            ;Tiempo (en tics de reloj) desde que comenzo el prog.
teclas  dd 0            ;Cantidad de teclas presionadas desde el inicio.
inicio:                 ;Verificar que se pueda utilizar el modo largo.
        cli             ;Deshabilitar interrupciones.
        pushfd          ;Si se puede cambiar el bit 21 de EFLAGS, se soporta CPUID.
        pop eax         ;Obtener en EAX los 32 bits del registro EFLAGS.
        mov ecx,eax     ;Salvar viejo valor de los flags.
        xor eax,1 << 21 ;Cambiar el bit 21.
        push eax
        popfd           ;Salvar nuevo valor de flags con bit 21 cambiado.
        pushfd
        pop eax         ;Leer nuevamente los flags para ver si el bit 21 cambio.
        push ecx
        popfd             ;Volver los flags a su valor inicial.
        mov si,texto1+2   ;Apuntar al primer caracter del texto a mostrar.
        xor eax,ecx       ;Si el bit 21 no cambio no hay CPUID, asi que no hay
        jz sin_modo_largo ;modo largo.
        mov eax,80000000h ;Verificar si se encuentran los CPUID extendidos
        cpuid             ;con bit 31 a uno.
        mov si,texto2+2   ;Apuntar al primer caracter del texto a mostrar.
        cmp eax,80000001h
        jb sin_modo_largo ;No hay modo largo si no se encuentran.
        mov eax,80000001h ;Selector de CPUID.
        cpuid
        test edx, 1 << 29  ;Si bit 29 vale 1 hay modo largo.
        jnz hay_modo_largo ;Saltar si el procesador lo soporta.
        mov si,texto3+2   ;Apuntar al primer caracter del texto a mostrar.
sin_modo_largo:
        cld
        mov ax,0B800h     ;Apuntar al buffer de video.
        mov es,ax
        mov ax,0720h      ;Borrar la pantalla.
        mov cx,25*80
        mov di,0
        rep stosw         ;Instruccion de cadena, lo que hace es
;mov[es:edi]
;edi +- 2
;ecx--
;si ecx no es cero, repetir
;
;
;
;
        mov di,[si-2]     ;Obtener el offset en el buffer de video.
ciclo_mostrar_texto:
        lodsb             ;Obtener el caracter del texto AL <- [SI] e
                          ;incrementar el puntero.
        stosw             ;Salvar el caracter respetando el atributo.
        cmp byte [si],0
        jnz ciclo_mostrar_texto
ciclo_espera_reset:
        hlt               ;Ahorrar energia
        jmp ciclo_espera_reset;Saltar si vino una interrupcion no enmascarable.
hay_modo_largo:
  ;Puedo hacerlo con cli
	mov al,0FFh	;Deshabilitar todas las IRQ del PIC.
	out 21h,al
        lgdt [gdtr]     ;Cargar el GDTR.
        lidt [idtr]     ;Cargar el IDTR.

        ;Hay cuatro niveles de tablas de paginas en procesadores de 64 bits:
        ;- PML4 -> maneja los bits 47-39 de las direcciones lineales.
        ;- PDP (Tabla de Punteros a Directorios de Paginas) -> bits 38-30
        ;- PD (Directorios de Paginas) -> bits 29-21
        ;- Tablas de Paginas -> bits 20-12 (no se usa si el bit 7, Page Size,
        ;  de la entrada correspondiente de la PD vale 1)
        ;Cada elemento de las tablas de paginacion ocupa 64 bits = 8 bytes.
        ;Pondremos las tablas a partir de la direccion lineal 0x90000 ya
        ;que el programa arranca en la direccion 0x8000 asi que no hay
        ;solapamiento.
        ;Las tablas, que ocupan 4 KB, deben estar ubicadas en direcciones
        ;multiplo de 4 KB.
        ;El formato debe ser el siguiente:
        ;
        ;PML4 (Tabla de nivel 4):
        ;dq 0x0000000000xxx00f
        ;4096-8 bytes no usados
        ;
        ;PDP (Punteros a directorios de paginas):
        ;dq 0x0000000000yyy00f
        ;4096-8 bytes no usados
        ;
        ;DP (Directorio de paginas):
        ;dq 0x000000000000018f   ;Bit 7 (Page Size) a "1" -> pagina de 2 MB
        ;4096-8 bytes no usados
        ;
        ;Donde xxx e yyy indican las direcciones fisicas donde estan ubicadas
        ;la PDP y la PD respectivamente. zzz indica la direccion fisica del
        ;segmento de codigo. De esta manera se define una pagina de 2 MB a
        ;partir de la direccion fisica donde arranca el segmento COM para
        ;codigo y variables. Tambien definimos una pagina de 2 MB a partir
        ;de la direccion cero para acceder a la pantalla.
        ;
        mov ax,DIR_FISICA_PML4 >> 4 
        mov es,ax         ;ES apunta a las tablas de paginacion a inicializar.
        mov di,0          ;ES:DI apunta a la tabla PML4.
        mov dword [es:di],DIR_FISICA_PDP+0x0F       ;Inicializar PML4.
        mov dword [es:di+4],0
        mov dword [es:di+0x1000],DIR_FISICA_DP+0x0F ;Inicializar PDP.
        mov dword [es:di+0x1004],0
        mov dword [es:di+0x2000],0x18F              ;Inicializar DP.
        mov dword [es:di+0x2004],0
        ;
        ; Entrar al modo largo.
        ;
        mov eax,00100000b       ;Poner a "1" el bit PAE (CR4.5) requerido
        mov cr4,eax             ;para 64 bits. Tambien habilita pag de 2 MB.
        mov eax,DIR_FISICA_PML4
        mov cr3,eax             ;Apuntar CR3 al inicio de la tabla PML4.

        mov ecx,0xC0000080      ;Especificar el indice de EFER.
        rdmsr                   ;Leer el Model Specific Register indicado
                                ;copiando su contenido en EDX:EAX.
        or eax,0x00000100       ;Habilitar el modo largo (bit 2 de EFER).
        wrmsr                   ;Escribir el Model Specific Register indicado.

        mov eax,cr0             ;Activar el modo largo poniendo a "1" el
        or eax,0x80000001       ;bit 31 (paginacion) y el bit 0 (modo
        mov cr0,eax             ;protegido) simultaneamente.
                                ;En este momento el procesador esta en el
                                ;modo de compatibilidad de 16 bits dentro del
                                ;modo largo.
        push word cs_sel_64     ;Poner en la pila el selector de 64 bits.
        mov eax,modo_largo      ;Poner en la pila el offset para el salto.
        push eax
        db 66h                  ;Prefijo de tamano para forzar la instruccion
                                ;a 32 bits (no funciona RETFD en NASM).
        retf                    ;Saltar a codigo de 64 bits.

        [bits 64]

modo_largo:
        mov rsp,0x8000          ;Inicializar la pila antes de este programa.
	mov ax,ds_sel
        mov ds,ax       ;Poner en reg. DS el selector del segmento de datos.
        mov es,ax       ;Poner en reg. ES el selector del segmento de datos.
        mov ss,ax       ;No se puede dejar el SS de modo real ya que la
                        ;instruccion IRETQ en 64 bits necesita que el SS
                        ;apunte a la GDT.
        mov ebx,BUF_VIDEO ;Limpiar la pantalla.
        mov ecx,2000
        mov ax,0720h
bucle_cls:mov [ebx],ax
	add ebx,2
	loop bucle_cls
        lea r8,[texto4]   ;Mostrar las tres leyendas en pantalla.
	call mostrar_texto
        lea r8,[texto5]
	call mostrar_texto
        lea r8,[texto6]
	call mostrar_texto
        mov al,0FCh     ;Habilitar unicamente la INT 8 (reloj) e INT 9
	out 21h,al	;(teclado).
        sti             ;Volver a habilitar interrupciones.
espera: hlt             ;Ahorrar energia.
        jmp espera

;La siguiente subrutina muestra un texto ASCIIZ apuntado por el registro R8.
mostrar_texto:
        movzx ebx,word [r8] ;Obtener offset dentro del buffer de video.
        add ebx,BUF_VIDEO ;EBX = Direccion donde debe ir el texto en pantalla.
        inc r8
bucle_disp:inc r8       ;Apuntar al siguiente caracter.
        mov al,[r8]     ;Obtener el proximo caracter a mostrar.
        and al,al       ;Ver si se termino.
        jz short fin_disp ;Saltar si es asi.
        mov [ebx],al    ;Mandarlo a pantalla.
        add ebx,2       ;Apuntar a la siguiente posicion en pantalla.
	jmp bucle_disp
fin_disp:ret		;Terminar la subrutina.
;Manejador de la interrupcion de reloj.
int8han:push rax        ;Preservar todos los registros de uso general.
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push rbp
        push r8
        push r9
        push r10
        inc dword [tics]        ;Incrementar tics desde inicio del programa.
        mov eax,35997*65536     ;Convertir a decimos de segundo.
        mul dword [tics]
        mov r10d,edx            ;R10D = Numero a mostrar (cantidad de segundos).
        mov ebx,BUF_VIDEO       ;Obtener posicion a mostrar en pantalla.
        add bx,[texto5]
        add bx,(texto6 - texto5) * 2 ;EBX = Posicion en pantalla.
        call mostrar_numero     ;Mostrar hasta decenas de segundos.
	mov cl,1                ;Para las unidades el cero es significativo.
	mov r9b,10
	call digito
	mov al,"."              ;Mostrar el punto decimal.
	call mostr_dig
	mov r9b,1               ;Mostrar decimas de segundo.
	call digito
fin_inter:mov al,20h            ;Indicarle al PIC que finalizo la interrupcion.
	out 20h,al
        pop r10                 ;Restaurar los registros.
        pop r9
        pop r8
        pop rbp
        pop rdi
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        iretq                   ;Fin de la interrupcion.
mostrar_numero:
	mov cl,0                ;No mostrar cero no significativo
	mov r9d,1000000000      ;En R9D se almacena el divisor.
	call digito
	mov r9d,100000000
	call digito
	mov r9d,10000000
	call digito
	mov r9d,1000000
	call digito
	mov r9d,100000
	call digito
	mov r9d,10000
	call digito
	mov r9w,1000
	call digito
	mov r9w,100
	call digito
        ret
digito: xor edx,edx
        mov eax,r10d            ;EDX:EAX = Dividendo, R9D = Divisor.
        div r9d                 ;EAX = Cociente, EDX = Resto.
        mov r10d,edx            ;Guardar el resto para la proxima division.
        add al,"0"              ;Convertir el cociente a ASCII.
        test cl,cl              ;Los ceros son significativos (se deben mostrar)?
	jnz short mostr_dig     ;Saltar si se debe mostrar cualquier digito.
	cmp al,"0"              ;El digito es cero?
	jz short fin_digito     ;No mostrarlo si lo es.
	mov cl,1                ;Como se muestra un digito los ceros a la
                                ;derecha deben mostrarse.
mostr_dig:mov [ebx],al
	add ebx,2
fin_digito:ret
int9han:push rax                ;Preservar todos los registros de uso general.
        push rbx
        push rcx
        push rdx
        push rsi
        push rdi
        push rbp
        push r8
        push r9
        push r10
        in al,60h               ;Obtener informacion del controlador de teclado
        and al,al               ;La tecla se acaba de apretar o de soltar?
	js fin_inter		;Saltar si se acaba de soltar.
        inc dword [teclas]      ;Indicar que se apreto una tecla.
        mov r10d,[teclas]       ;R10D = Numero a mostrar (cantidad de teclas).
        mov ebx,BUF_VIDEO       ;Obtener posicion a mostrar en pantalla.
        add bx,[texto6]
        add bx,(fin_texto6 - texto6) * 2 ;EBX = Posicion en pantalla.
        call mostrar_numero
	mov r9b,10              ;Divisor para decenas.
	call digito
	mov cl,1                ;Para las unidades el cero es significativo.
	mov r9b,1               ;Divisor para unidades.
	call digito
	jmp fin_inter		;Ir a restaurar los registros.
