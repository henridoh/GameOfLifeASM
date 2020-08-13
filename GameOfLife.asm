width    equ 20
height   equ 20


section .rodata
  deadcell  db "d ", 0
  alivecell db "a ", 0

  newline db 10, 0

  msg db "Hello World", 10, 0

section .data
  field1 times width*height db 0
  field2 times width*height db 0

  current dq field1
  next dq field2
  state db 0

  currentx dw 0
  currenty dw 0

section .text
  global _start


_start:
  call update_field
  mov rsi, msg
  call print
  call update_field

exit:  ; exit with code 0
  mov rax, 60
  mov rdi, 0
  syscall


update_field:
  push r8
  push r10

  mov word[currentx], 0
  mov word[currenty], 0

  mov r8, [current]   ; current field
  mov r10, [next]     ; field of next frame
  .l:
    cmp byte[r8], 1   ; print symbol
    jne .dead
  
    mov rsi, alivecell
    jmp .out
    .dead:
    mov rsi, deadcell
    .out:
    call print

    call get_neighbors; get num of neighbors (not implemented yet)
    cmp rax, 2
    jl .die
    cmp rax, 3
    jg .die

    mov byte[r10], 1

    jmp .e
    .die:
    mov byte[r10], 0

    .e:

    inc r8
    inc word[currentx]

    cmp word[currentx], width
    jne .nnl

    mov word[currentx], 0
    mov rsi, newline
    call print
    add word[currenty], 1

    .nnl:
    cmp word[currenty], height
    jne .l

  cmp byte[state], 0
  je .s0

  .s1:        ; switch current and next field
    mov qword[next], field2
    mov qword[current], field1
    mov byte[state], 0
    jmp .se

  .s0:
    mov qword[next], field1
    mov qword[current], field2
    mov byte[state], 1

  .se:

  pop r10
  pop r8
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
  xor rax, rax
  push rbx
  mov rbx, r8

  cmp word[currentx], 0
  je .noleftneighbor
  sub r8, 1
  cmp byte[r8], 0
  je .noleftneighbor
  inc rax
  .noleftneighbor:

  cmp word[currentx], width - 1
  je .norightneighbor
  mov r8, rbx
  add r8, 1
  cmp byte[r8], 0
  je .norightneighbor
  inc rax
  .norightneighbor:

  cmp word[currenty], 0
  je .notopneighbor
  mov r8, rbx
  sub r8, width
  cmp byte[r8], 0
  je .notopneighbor
  inc rax
  .notopneighbor:

  cmp word[currenty], height - 1
  je .nobottomneighbor
  mov r8, rbx
  add r8, width
  cmp byte[r8], 0
  je .nobottomneighbor
  .nobottomneighbor:

  pop rbx
  ret
