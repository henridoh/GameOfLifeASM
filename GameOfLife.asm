width    equ 50
height   equ 50

poll_len equ 3


section .rodata
  deadcell  db "  ", 0
  alivecell db " *", 0
  cursorcolor db 27, "[42m", 0
  resetcolor db 27, "[0m", 0

  newline db 10, 0

  clearscreen db 27, "[2J", 27, "[0;0H" , 0

  msg db "Hello World", 10, 0

  up		      db 27, '[A', 0
  down	      db 27, '[B', 0
  left	      db 27, '[C', 0
  right	      db 27, '[D', 0

  endofline   db 27, '[0m', '║', 10, 0
  startofline db '║', 0
  top				db '╔'
						times (width-5) db '═'
					  db 27, '[32m', 'GameOfLife', 27, '[0m'
						times (width-5) db '═'
    	      db '╗', 10, 0
  
  bottom    db '╚'
    	      times (width*2) db '═'
    	      db '╝', 0




section .data
  field1 times width*height db 0
  field2 times width*height db 0

  current dq field1
  next dq field2
  state db 0

  currentx dw 0
  currenty dw 0

  fd dd 0
  eve dw 1
  rev dw 0
  sym db 1

  running db 0

  cursorx dw 0
  cursory dw 0

  sleeptime:
    .s dq 0
    .ns dq 125000000

section .bss
  buffer    resb 128
  stty	  resb 12
  slflag  resb 4
  srest	  resb 44
  tty			resb 12
  lflag	  resb 4
  brest	  resb 44


section .text
  global _start


_start:
  call setnoncan

gameloop:
  call poll  ; get input

  cmp al, 'q'  ; if q is pressed exit
  je exit

  cmp al, ' '  ; if space is pressed change 
  jne .noinput ;state of cell on curren cursor pos

  xor rax, rax
  mov ax, word[cursory]
  mov bx, width
  mul bx
  add ax, word[cursorx]
  add rax, qword[current]
  xor byte[rax], 1

  .noinput:

  cmp al, 27   ; if ansi escape sequence is detected
  jne .nocursorevent
  mov rax, buffer	 ; switch through possible key presses

  mov rsi, up     ; move cursor
  call strcmp
  je .up
  mov rsi, down
  call strcmp
  je .down
  mov rsi, left
  call strcmp
  je .left
  mov rsi, right
  call strcmp
  je .right
  jmp .end
  .left:
    cmp word[cursorx], height - 1
    je .end
    add word[cursorx], 1
    jmp .end
  .right:
    cmp word[cursorx], 0
    je .end
    sub word[cursorx], 1
    jmp .end
  .up:
    cmp word[cursory], 0
    je .end
    sub word[cursory], 1
    jmp .end
  .down:
    cmp word[cursory], width - 1
    je .end
    add word[cursory], 1

  .end:
  .nocursorevent:
  cmp al, 's'   ; if s is pressed
  jne .nopause  ; pause/unpause generations
  xor byte[running], 1

  .nopause:
  call update_field
  call sleep
  mov rsi, clearscreen
  call print
  jmp gameloop

exit:  ; exit with code 0
  call setcan
  mov rax, 60
  mov rdi, 0
  syscall


; updates to the next generation and prints the field
update_field:
  push r8
  push r10
  push r12

  mov rsi, top
  call print
  mov rsi, startofline
  call print

  mov word[currentx], 0
  mov word[currenty], 0

  mov r8, [current]   ; current field
  mov r10, [next]     ; field of next frame

  ; loop through each cell
  .l:
    mov r12w, word[cursorx]     ; print background color if cursor on current position
    cmp word[currentx], r12w
    jne .nocursor
    mov r12w, word[cursory]
    cmp word[currenty], r12w
    jne .nocursor
    mov r12b, 1
    mov rsi, cursorcolor
    call print

    .nocursor:
    cmp byte[r8], 1   ; check if cell is alive
    jne .dead
    ; and print the corresponding symbol
    mov rsi, alivecell
    jmp .out
    .dead:
    mov rsi, deadcell
    .out:
    call print

    cmp r12b, 1   ; reset background-color
    jne .nocursor2
    mov rsi, resetcolor
    call print

    .nocursor2:
    cmp byte[running], 0 ; if paused skip update
    je .e

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
    mov rsi, endofline    ; printnewline
    call print
    add word[currenty], 1

    cmp word[currenty], height
    je .nnl

    mov rsi, startofline
    call print

    .nnl:
    cmp word[currenty], height  ; check for end of field
    jne .l                      ; if end of field: goto .l

  ; else:
  cmp byte[running], 0  ; skip buffer swap if not running
  je .se

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
  mov rsi, bottom
  call print
  pop r12
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

  cmp word[currentx], 0
  je .noleft
  sub r8, 1
  cmp byte[r8], 0
  je .noleft
  inc rax
  .noleft:

  cmp word[currentx], width - 1
  je .noright
  mov r8, rbx
  add r8, 1
  cmp byte[r8], 0
  je .noright
  inc rax
  .noright:

  cmp word[currenty], 0
  je .notop
  mov r8, rbx
  sub r8, width
  cmp byte[r8], 0
  je .notop
  inc rax
  .notop:

  cmp word[currenty], height - 1
  je .nobottom
  mov r8, rbx
  add r8, width
  cmp byte[r8], 0
  je .nobottom
  inc rax
  .nobottom:

  cmp word[currentx], 0
  je .notopleft
  cmp word[currenty], 0
  je .notopleft
  mov r8, rbx
  sub r8, width + 1
  cmp byte[r8], 0
  je .notopleft
  inc rax
  .notopleft:

  cmp word[currentx], width - 1
  je .notopright
  cmp word[currenty], 0
  je .notopright
  mov r8, rbx
  sub r8, width - 1
  cmp byte[r8], 0
  je .notopright
  inc rax
  .notopright:

  cmp word[currentx], 0
  je .nobottomleft
  cmp word[currenty], height - 1
  je .nobottomleft
  mov r8, rbx
  add r8, width - 1
  cmp byte[r8], 0
  je .nobottomleft
  inc rax
  .nobottomleft:

  cmp word[currentx], width - 1
  je .nobottomright
  cmp word[currenty], height - 1
  je .nobottomright
  mov r8, rbx
  add r8, width + 1
  cmp byte[r8], 0
  je .nobottomright
  inc rax
  .nobottomright:

  mov r8, rbx
  pop rbx
  ret


poll:
  mov qword[buffer], 0
  push rbx
  push rcx
  push rdx
  push rdi
  push rsi
  mov rax, 7; the number of the poll system call
  mov rdi, fd; pointer to structure
  mov rsi, 1; monitor one thread
  mov rdx, 0; do not give time to wait
  syscall
  test rax, rax; check the returned value to 0
  jz .e
  mov rax, 0
  mov rdi, 0; if there is data
  mov rsi, buffer; then make the call read
  mov rdx, poll_len
  syscall
  xor rax, rax
  mov al, byte [buffer]; return the character code if it was read
  .e:
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret


setnoncan:
  push stty
  call tcgetattr
  push tty
  call tcgetattr
  and dword[lflag], (~ 2)
  and dword[lflag], (~ 8)
  call tcsetattr
  add rsp, 16
  ret

setcan:
        push stty
        call tcsetattr
        add rsp, 8
        ret

tcgetattr:
  mov rdx, qword [rsp+8]
  push rax
  push rbx
  push rcx
  push rdi
  push rsi
  mov rax, 16; ioctl system call
  mov rdi, 0
  mov rsi, 21505
  syscall
  pop rsi
  pop rdi
  pop rcx
  pop rbx
  pop rax
  ret

tcsetattr:
  mov rdx, qword [rsp+8]
  push rax
  push rbx
  push rcx
  push rdi
  push rsi
  mov rax, 16; ioctl system call
  mov rdi, 0
  mov rsi, 21506
  syscall
  pop rsi
  pop rdi
  pop rcx
  pop rbx
  pop rax
  ret


strcmp:
  push rax
  push rsi
  push r8
  xor r8, r8
  .loop:
    cmp byte[rax], 0
    je .e

    mov r8b, [rsi]
    cmp [rax], r8b
    jne .ne
    inc rax
    inc rsi
    jmp .loop

  .e:
    cmp byte[rsi], 0
    jne .ne
    pop r8
    pop rsi
    pop rax
    cmp rax, rax
    ret

  .ne:
    pop r8
    pop rsi
    pop rax
    cmp rax, 0
    ret

sleep:			  ; sleep $sleeptime
  mov rax, 35
  mov rdi, sleeptime
  mov rsi, 0
	mov rdx, 0
  syscall
  ret


