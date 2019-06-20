EXTERN __FLAG_TIMER
EXTERN __COUNT_TIMER

section .isr_timer
USE32
  pushad
  mov ebx,[__COUNT_TIMER]

  add ebx,1
  cmp ebx,100
  jl no_ticks
  je new_tick
  ;Sino es mayor
  xor eax,eax
  xor edx,edx

  mov eax,ebx
  mov ecx,100
  div ecx;Divido edx:eax en ebx

  cmp edx,0
  je new_tick
  jmp no_ticks

no_ticks:
  mov eax,0
  mov [__FLAG_TIMER],eax
  jmp finish_isr

new_tick:
  mov eax,1
  mov [__FLAG_TIMER],eax
  jmp finish_isr

finish_isr:
  mov [__COUNT_TIMER],ebx
  mov al,20h            ;Indicarle al PIC que finalizo la interrupcion.
  out 20h,al

  popad
  iret
