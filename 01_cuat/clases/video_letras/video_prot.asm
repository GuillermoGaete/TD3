; Mostrar en pantalla 25 lineas de caracteres. La linea superior
; debe contener letras 'A', la segunda linea letras 'B' y asi sucesivamente
; hasta la letra 'Y'.
; Registros usados:
;    CL = Fila, CH = Columna, SI = Puntero, BL = Letra a mostrar



      
BITS 16



inicio:
      xchg bx,bx
%include "init_pci.inc"

     jmp pasaje_aMP
   
   ALIGN 8
   
   GDT:
         dq 0 ;selector nulo
     
      CS_SEL equ $-GDT
      
         dw 0xffff   
         dw 0
         db 0xff
         db 0x9a
         db 0xcf
         db 0xff
         
      DS_SEL equ $-GDT
      
         dw 0xffff   
         dw 0
         db 0
         db 0x92
         db 0xcf
         db 0
      
      GDT_tam equ $-GDT 
      
 
 im_gdtr:
 
      dw  GDT_tam -1 
      dd  0xf0000 + GDT
     
     
     
     
pasaje_aMP:     
     
     cli
     lgdt[cs:im_gdtr]
     
     mov eax, cr0
     or  eax, 1
     mov cr0, eax
     
     jmp CS_SEL:inicio_32
     
  BITS 32   
  
  inicio_32:
  
 
      mov ax, DS_SEL
      mov ds, ax
      MOV BL, "A" ; Caracter
      MOV CL, 0   ; Fila
      MOV ESI, 0xb8000   ; Puntero
CICLO_EXTERNO:
      MOV CH, 0   ; Columna
CICLO_INTERNO:
      MOV [ESI], BL  ; Escribo en pantalla
      MOV BYTE [ESI+1], 0x07
      ADD ESI, 2  ; Incremento el puntero
      INC CH     ; Incremento columna
      CMP CH, 80 
      JNE CICLO_INTERNO
      INC CL    ; Incremento la fila
      INC BL    ; Incremento el caracter
      CMP CL, 25
      JNE CICLO_EXTERNO
      JMP $

      
     times 0xFFF0 -($ - inicio)  db 0

     
BITS 16     
reset:
      jmp inicio
     
     times 0x10 - ($ -reset) db 0
     

      
      
      
      