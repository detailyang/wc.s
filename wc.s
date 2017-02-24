.global _start

.set SYSCALL_EXIT, 60
.set SYSCALL_OPEN, 2
.set O_RDONLY, 0
.set SYSCALL_READ, 0
.set SYSCALL_WRITE, 1
.set MAX_BUF_SIZE, 1024
.set STDOUT, 1
.set ASCII_0, 48
.set ASCII_hyphen, 45

.data
newline:
	.asciz "\n"

newline_end:

debug_msg:
    .asciz "debug\n"

debug_msg_end:

msg:
    .asciz "ready to count the bytes in the file\n"

msg_end:

msg_err:
    .asciz "must provide the filename\n"

msg_err_end:

buf:
    .space MAX_BUF_SIZE + 1, 0

itoa_buf:
    .space 22, 0

.text

/*
    Initial Process Stack
    0   : 8+8*argc+%rsp
    argv: 8+%rsp
    argc: %rsp
*/

_start:
    cmp $2, (%rsp)
    je run

    mov $msg_err_end, %rax
    sub $msg_err, %rax
    mov %rax, %rsi
    mov $msg_err, %rdi
    call print
    jmp exit

run:
    mov $msg_end, %rax
    sub $msg, %rax
    mov %rax, %rsi
    mov $msg, %rdi
    call print

/*
* we only take one argument
* ./wc xx
*/
/* call syscall_open argv[n], O_RDONLY */
    mov 16(%rsp), %rdi
    mov $O_RDONLY, %rsi
    mov $SYSCALL_OPEN, %rax
    syscall

/* check return value */
    cmp $1, %rax
    je exit

    mov %rax, %rdi
    call count_in_file

    mov %rax, %rdi
    lea itoa_buf, %rsi
    call itoa

    mov %rax, %rdi
    mov $22, %rsi
    call print
    call print_newline

exit:
/* call syscall_exit */
	mov $0, %rdi
	mov $SYSCALL_EXIT, %rax
    syscall
	ret

print_newline:
    mov $newline_end, %rax
    sub $newline, %rax
    mov %rax, %rsi
    mov $newline, %rdi
    call print
    ret
/*
    write(fd, buf, count)
*/

debug:
    mov $debug_msg_end, %rax
    sub $debug_msg, %rax
    mov %rax, %rsi
    mov $debug_msg, %rdi
    call print
    ret

print:
   mov $SYSCALL_WRITE, %rax
   mov %rsi, %rdx
   mov %rdi, %rsi
   mov $STDOUT, %rdi
   syscall
   ret
/*
    int count_in_file(int fd)
*/
count_in_file:
/*
    callee-saved registers
*/
    xor %r9, %r9

.reread:
/*
    call syscall_read
*/
    mov $SYSCALL_READ, %rax
    lea buf, %rsi
    mov $MAX_BUF_SIZE, %rdx
    syscall

    cmp $0, %rax
    je .end

    cmp $-1, %rax
    je .end

    add %rax, %r9
    jmp .reread

.end:
    mov %r9, %rax

    ret

/*
* char * itoa(int, char *)
*/
itoa:
    xor %r9, %r9
    movb $0, (%rsi)

    cmp $0, %rdi
    jge .itoa_input_positive
    mov $1, %r9
    neg %rdi

.itoa_input_positive:
    /*
        %rax / 10 = %rax mod %rdx
     */
    mov %rdi, %rax
    mov $10, %r8

.itoa_next_digit:
    xor %rdx, %rdx
    div %r8

    dec %rsi
    /* ascii is 8 bit */
    add $ASCII_0, %dl
    movb %dl, (%rsi)

    cmp $0, %rax
    jne .itoa_next_digit


    cmp $0, %r9
    je .itoa_done
    dec %rsi
    movb $ASCII_hyphen, (%rsi)

.itoa_done:
    mov %rsi, %rax
    ret
