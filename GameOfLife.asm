width    equ 20
height   equ 20


section .rodata
  deadcell  db "d ", 0
  alivecell db "a ", 0

  newline db 10, 0

  msg db "Hello World", 10, 0

section .data
  field times width*height db 0

section .text
  global _start


_start:
  call draw_field


exit:  ; exit with code 0
  mov rax, 60
  mov rdi, 0
  syscall


update_field:
  push rax
  push r8
  push r9
  mov r8, field
  mov r9, 0
  .l:
    cmp byte[r8], 1
    jne .dead
    mov rsi, alivecell
    jmp .out
    .dead:
    mov rsi, deadcell
    .out:
    call print

    call get_neighbors
    cmp rax, 2
    jl .die
    cmp rax, 3
    jg .die

    jmp .e
    .die:

    .e:

    inc r8
    inc r9
    cmp r9, width
    jne .nl

    mov r9, 0
    mov rsi, newline
    call print

    .nl:
    cmp r8, field + (width*height)
    jne .l

  pop r9
  pop r8
  pop rax
  ret

print:
  push rax
  push rdi
  push rdx
  push rsi
  xor rdx, rdx
  .l:
    lodsb
    cmp al, 0
    je .flush
    inc rdx
    jmp .l
  .flush:
    pop rsi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdx
    pop rdi
    pop rax
    ret


get_neighbors:
  nop
  ret
