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
  mov rsi, msg
  call print
  call update_field

exit:  ; exit with code 0
  mov rax, 60
  mov rdi, 0
  syscall


; updates to the next generation and prints the field
update_field:
  push r8
  push r10

  mov word[currentx], 0
  mov word[currenty], 0

  mov r8, [current]   ; current field
  mov r10, [next]     ; field of next frame

  ; loop through each cell
  .l:
    cmp byte[r8], 1   ; check if cell is alive
    jne .dead
    ; and print the corresponding symbol
    mov rsi, alivecell
    jmp .out
    .dead:
    mov rsi, deadcell
    .out:
    call print

    call get_neighbors; get num of neighbors (not implemented yet)
    ; update to the next generation, write to [[next]]
    cmp rax, 2
    jl .die
    cmp rax, 3
    je .born
    jg .die

    .live:
    push rax
    mov al, byte[r8]
    mov byte[r10], al
    pop rax
    jmp .e

    .born:
    mov byte[r10], 1
    jmp .e

    .die:
    mov byte[r10], 0

    .e:

    ; increace cell counter for current and next generation
    inc r8
    inc r10
    inc word[currentx]

    ; check for end of line
    cmp word[currentx], width
    jne .nnl

    mov word[currentx], 0 ; reset x-pos
    mov rsi, newline      ; print newline
    call print
    add word[currenty], 1

    .nnl:
    cmp word[currenty], height  ; check for end of field
    jne .l                      ; if end of field: goto .l

  ; else:

  cmp byte[state], 0
  je .s0

  .s1:        ; switch current and next field depending on current state
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


; get number of neighbors for current cell. n -> rax
get_neighbors:
  xor rax, rax
  push rbx
  mov rbx, r8




  pop rbx
  ret
