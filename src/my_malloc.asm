%ifndef MACRO_
    %define MACRO_
    %macro ABS 1
        cmp %1, 0
        jge %%bye_ABS
        neg %1
        %%bye_ABS:
    %endmacro

    %macro CALL_ 1-7
        push rdi ; -prologue-
        push rsi ;
        push rdx ;
        push rcx ;
        push r8 ;
        push r9 ;
        push r10 ;
        push r11 ; ----------
        %if %0 >= 2 ; check if there is 1st param
            mov rdi, %2 ; set 1st param
            %if %0 >= 3 ; check if there is 2nd param
                %rotate 1 ; move to 2nd param
                mov rsi, %2 ; set 2nd param
                %if %0 >= 4 ; check if there is 3rd param
                    %rotate 1 ; move to 3rd param
                    mov rdx, %2 ; set 3rd param
                    %if %0 >= 5 ; check if there is 4th param
                        %rotate 1 ; move to 4th param
                        mov rcx, %2 ; set 4th param
                        %if %0 >= 6 ; check if there is 5th param
                            %rotate 1 ; move to 5th param
                            mov r8, %2 ; set 5th param
                            %if %0 == 7 ; check if there is 6th param
                                %rotate 1 ; move to 6th param
                                mov r9, %2 ; set 6th param
                            %endif
                        %endif
                    %endif
                %endif
            %endif
        %endif
        %rotate 2 ; move to function

        call %1 ; call function

        pop r11 ; -epilogue-
        pop r10 ;
        pop r9 ;
        pop r8 ;
        pop rcx ;
        pop rdx ;
        pop rsi ;
        pop rdi ; ----------
    %endmacro
%endif

section .data
    malloc_base dq -1
    malloc_bug db "malloc(): memory allocation failed", 10
    free_error db "free(): invalid pointer", 10
    free_bug db "free(): bug memory release", 10

section .text
    global mmalloc
    global mfree
    global mcalloc
    global mrealloc
    global show_malloc

mmalloc:
    cmp rdi, 0
    jle .malloc_error
    push rdi
    mov r10, qword [rel malloc_base]
    cmp r10, -1
    je .init_malloc_page
    .unprotect:
        mov rax, 10
        mov rdi, r10
        mov rsi, 4096
        mov rdx, 3
        syscall
        cmp rax, 0
        jl .malloc_error2
        cmp qword [r10], 0
        je .alloc
        mov r10, qword [r10]
        jmp .unprotect
    .alloc:
    pop rdi
    mov r8, rdi

    mov r10, qword [rel malloc_base]
    mov r11, -1
    .find_space:
        add r11, 17
        cmp r11, 4096
        jge .go_next_malloc_page
        cmp qword [r10 + r11], 0
        je .continue_find_space
        cmp byte [r10 + r11 + 16], 1
        je .find_space
        cmp qword [r10 + r11], r8
        jl .find_space
    .continue_find_space:
    cmp qword [r10 + r11], 0
    jne .split_malloc
    jmp .new_malloc

    .protect:
        mov r10, qword [rel malloc_base]
        .loop_protect:
            cmp r10, 0
            je .bye
            mov r8, qword [r10]
            mov rax, 10
            mov rdi, r10
            mov rsi, 4096
            mov rdx, 1
            syscall
            cmp rax, 0
            jl .malloc_error2
            mov r10, r8
            jmp .loop_protect
    .bye:
    pop rax
    ret

    .init_malloc_page:
        mov rax, 9
        mov rdi, 0
        mov rsi, 4096
        mov rdx, 3
        mov r10, 34
        mov r8, -1
        mov r9, 0
        syscall
        cmp rax, 0
        jl .malloc_error2

        mov qword [rel malloc_base], rax
        mov qword [rax], 0
        mov qword [rax + 8], 13
        mov qword [rax + 16], 0
        mov qword [rax + 24], 0
        mov byte [rax + 32], 0

        jmp .alloc

    .create_malloc_page:
        push r8
        push r10
        mov rax, 9
        mov rdi, 0
        mov rsi, 4096
        mov rdx, 3
        mov r10, 34
        mov r8, -1
        mov r9, 0
        syscall
        pop r10
        pop r8
        cmp rax, 0
        jl .malloc_error

        mov qword [r10], rax
        mov r10, rax
        mov qword [r10], 0
        mov qword [r10 + 8], 13
        mov qword [r10 + 16], 0
        mov qword [r10 + 24], 0
        mov byte [r10 + 32], 0

        mov r11, 16
        jmp .new_malloc
    
    .go_next_malloc_page:
        cmp qword [r10], 0
        je .create_malloc_page
        mov r10, qword [r10]
        mov r11, -1
        jmp .find_space

    .split_malloc:
        mov byte [r10 + r11 + 16], 1
        mov rdi, qword [r10 + r11 + 8]
        push rdi
        cmp qword [r10 + r11], r8
        je .protect
        mov rsi, qword [r10 + r11]
        sub rsi, r8
        mov qword[r10 + r11], r8
        push rsi
        .find_last_space:
            add r11, 17
            cmp r11, 4096
            jge .go_next_malloc_page2
            cmp qword [r10 + r11], 0
            jne .find_last_space
        .continue_split_malloc:
        pop rsi
        pop rdi
        push rdi
        add rdi, r8
        mov qword [r10 + r11], rsi
        mov qword [r10 + r11 + 8], rdi
        mov byte [r10 + r11 + 16], 0
        jmp .protect

    .create_malloc_page2:
        push r8
        push r10
        mov rax, 9
        mov rdi, 0
        mov rsi, 4096
        mov rdx, 3
        mov r10, 34
        mov r8, -1
        mov r9, 0
        syscall
        pop r10
        pop r8

        cmp rax, 0
        jl .malloc_error3

        mov qword [r10], rax
        mov r10, rax
        mov qword [r10], 0
        mov qword [r10 + 8], 13
        mov qword [r10 + 16], 0
        mov qword [r10 + 24], 0
        mov byte [r10 + 32], 0

        mov r11, 16
        jmp .continue_split_malloc
    
    .go_next_malloc_page2:
        cmp qword [r10], 0
        je .create_malloc_page2
        mov r10, qword [r10]
        mov r11, -1
        jmp .continue_split_malloc

    .new_malloc:
        push r8
        push r10
        push r11

        mov rax, 9
        mov rdi, 0
        mov rsi, r8
        mov rdx, 3
        mov r10, 34
        mov r8, -1
        mov r9, 0
        syscall

        mov r9, rax
        pop r11
        pop r10
        pop r8

        cmp rax, 0
        jl .malloc_error

        mov rax, r8
        xor rdx, rdx
        mov rbx, 4096
        div rbx
        sub rbx, rdx
        add rbx, r8

        mov qword [r10 + r11], rbx
        mov qword [r10 + r11 + 8], r9
        mov byte [r10 + r11 + 16], 0

        jmp .split_malloc

    .malloc_error:
        mov rax, 1
        mov rdi, 2
        lea rsi, [rel free_bug]
        mov rdx, 26
        syscall
        mov rax, 0
        ret
    
    .malloc_error2:
        pop rax
        jmp .malloc_error
    
    .malloc_error3:
        pop rax
        jmp .malloc_error2

mfree:
    cmp rdi, 0
    je .bye
    mov r10, qword [rel malloc_base]
    cmp r10, -1
    je .error_free
    push rdi
    .unprotect:
        mov rax, 10
        mov rdi, r10
        mov rsi, 4096
        mov rdx, 3
        syscall
        cmp rax, 0
        jl .bug_free2
        cmp qword [r10], 0
        je .dalloc
        mov r10, qword [r10]
        jmp .unprotect
        
    .dalloc:
    pop rdi

    mov r10, qword [rel malloc_base]
    mov r11, -1
    .find_malloc:
        add r11, 17
        cmp r11, 4096
        jge .go_next_malloc_page
        cmp qword [r10 + r11], 0
        je .error_free
        cmp qword [r10 + r11 + 8], rdi
        jne .find_malloc
    
    cmp byte [r10 + r11 + 16], 0
    je .error_free
    mov byte [r10 + r11 + 16], 0

    mov r8, r10
    add r8, r11
    mov r10, qword [rel malloc_base]
    mov r11, -1
    .find_free_prev:
        add r11, 17
        cmp r11, 4096
        jge .go_next_malloc_page_prev
        cmp qword [r10 + r11], 0
        je .leave_find_free_prev
        cmp byte [r10 + r11 + 16], 1
        je .find_free_prev
        mov r9, qword [r10 + r11 + 8]
        add r9, qword [r10 + r11]
        cmp qword [r8 + 8], r9
        jne .find_free_prev
        mov r9, qword [r8]
        add qword [r10 + r11], r9
        jmp .swap_prev

         .go_next_malloc_page_prev:
            cmp qword [r10], 0
            je .leave_find_free_prev
            mov r10, qword [r10]
            mov r11, -1
            jmp .find_free_prev

    .leave_find_free_prev:

    mov r10, qword [rel malloc_base]
    mov r11, -1
    mov r9, qword [r8 + 8]
    add r9, qword [r8]
    .find_free_next:
        add r11, 17
        cmp r11, 4096
        jge .go_next_malloc_page_next
        cmp qword [r10 + r11], 0
        je .leave_find_free_next
        cmp byte [r10 + r11 + 16], 1
        je .find_free_next
        cmp qword [r10 + r11 + 8], r9
        jne .find_free_next
        mov r9, qword [r10 + r11]
        add qword [r8], r9
        jmp .swap_next

         .go_next_malloc_page_next:
            cmp qword [r10], 0
            je .leave_find_free_next
            mov r10, qword [r10]
            mov r11, -1
            jmp .find_free_next

    .leave_find_free_next:

    .protect:
        mov r10, qword [rel malloc_base]
        .loop_protect:
            cmp r10, 0
            je .bye
            mov r8, qword [r10]
            mov rax, 10
            mov rdi, r10
            mov rsi, 4096
            mov rdx, 1
            syscall
            cmp rax, 0
            jl .bug_free
            mov r10, r8
            jmp .loop_protect

    .bye:
    ret

    .go_next_malloc_page:
        cmp qword [r10], 0
        je .error_free
        mov r10, qword [r10]
        mov r11, -1
        jmp .find_malloc

    .swap_prev:
        mov r9, r10
        add r9, r11
        push r9
        mov r10, qword [rel malloc_base]
        mov r11, -1
        mov r9, 0
        .find_last_prev:
            add r11, 17
            cmp r11, 4096
            jge .go_next_malloc_page_last_prev
            cmp qword [r10 + r11], 0
            je .leave_find_last_prev
            mov r9, r10
            add r9, r11
            jmp .find_last_prev
        .leave_find_last_prev:
        mov r10, r9
        pop r9
        mov rdx, qword [r10 + 8]
        cmp qword [r9 + 8], rdx
        je .prev_is_last
        mov rdx, qword [r10]
        mov qword [r8], rdx
        mov rdx, qword [r10 + 8]
        mov qword [r8 + 8], rdx
        mov dl, byte [r10 + 16]
        mov byte [r8 + 16], dl
        mov qword [r10], 0
        mov qword [r10 + 8], 0
        mov byte [r10 + 16], 0
        mov r8, r9
        jmp .leave_find_free_prev

        .go_next_malloc_page_last_prev:
            cmp qword [r10], 0
            je .leave_find_last_prev
            mov r10, qword [r10]
            mov r11, -1
            jmp .find_last_prev

        .prev_is_last:
            mov rdx, qword [r10]
            mov qword [r8], rdx
            mov rdx, qword [r10 + 8]
            mov qword [r8 + 8], rdx
            mov dl, byte [r10 + 16]
            mov byte [r8 + 16], dl
            mov qword [r10], 0
            mov qword [r10 + 8], 0
            mov byte [r10 + 16], 0
            jmp .leave_find_free_prev
        
    .swap_next:
        mov r9, r10
        add r9, r11
        push r9
        mov r10, qword [rel malloc_base]
        mov r11, -1
        mov r9, 0
        .find_last_next:
            add r11, 17
            cmp r11, 4096
            jge .go_next_malloc_page_last_next
            cmp qword [r10 + r11], 0
            je .leave_find_last_next
            mov r9, r10
            add r9, r11
            jmp .find_last_next
        .leave_find_last_next:
        mov r10, r9
        pop r9
        mov rdx, qword [r10]
        mov qword [r9], rdx
        mov rdx, qword [r10 + 8]
        mov qword [r9 + 8], rdx
        mov dl, byte [r10 + 16]
        mov byte [r9 + 16], dl
        mov qword [r10], 0
        mov qword [r10 + 8], 0
        mov byte [r10 + 16], 0
        jmp .leave_find_free_next

        .go_next_malloc_page_last_next:
            cmp qword [r10], 0
            je .leave_find_last_next
            mov r10, qword [r10]
            mov r11, -1
            jmp .find_last_next

    .error_free:
        mov rax, 1
        mov rdi, 2
        lea rsi, [rel free_error]
        mov rdx, 24
        syscall
        mov rax, 39
        syscall
        mov rdi, rax
        mov rsi, 6
        mov rax, 62
        syscall
        ret
    
    .bug_free:
        mov rax, 1
        mov rdi, 2
        lea rsi, [rel free_bug]
        mov rdx, 26
        syscall
        mov rax, 39
        syscall
        mov rdi, rax
        mov rsi, 6
        mov rax, 62
        syscall
        ret

    .bug_free2:
        pop rax
        mov rax, 1
        mov rdi, 2
        lea rsi, [rel free_bug]
        mov rdx, 26
        syscall
        mov rax, 39
        syscall
        mov rdi, rax
        mov rsi, 6
        mov rax, 62
        syscall
        ret

mcalloc:
    mov rax, rdi
    mul rsi
    mov rdi, rax
    push rdi
    call mmalloc
    pop rdi
    mov rcx, 0
    .loop_calloc:
        mov byte [rax + rcx], 0
        inc rcx
        cmp rcx, rdi
        jne .loop_calloc
    ret

mrealloc:
    push rsi
    cmp rdi, 0
    jne .free
    .back_free:
    pop rdi
    cmp rdi, 0
    jne .malloc
    .back_malloc:
    ret

    .free:
        call mfree
        jmp .back_free

    .malloc:
        call mmalloc
        jmp .back_malloc

show_malloc:
    CALL_ putchar, 'g'
    CALL_ putchar, 'o'
    CALL_ putchar, 10
    mov r10, qword [rel malloc_base]
    cmp r10, -1
    je .bye
    .unprotect:
        mov rax, 10
        mov rdi, r10
        mov rsi, 4096
        mov rdx, 3
        syscall
        cmp rax, 0
        jl .bye
        cmp qword [r10], 0
        je .alloc
        mov r10, qword [r10]
        jmp .unprotect
    .alloc:

    mov r10, qword [rel malloc_base]
    mov r11, -1
    .find_space:
        add r11, 17
        cmp r11, 4096
        jge .go_next_malloc_page
        xor rdi, rdi
        mov rdi, qword[r10 + r11]
        CALL_ putchar, 's'
        CALL_ putchar, ':'
        CALL_ putnbr, rdi
        CALL_ putchar, 32
        xor rdi, rdi
        mov rdi, qword[r10 + r11 + 8]
        CALL_ putchar, 'a'
        CALL_ putchar, ':'
        CALL_ putnbr, rdi
        CALL_ putchar, 32
        xor rdi, rdi
        movzx rdi, byte[r10 + r11 + 16]
        CALL_ putchar, 'e'
        CALL_ putchar, ':'
        CALL_ putnbr, rdi
        CALL_ putchar, 10
        jmp .find_space
    .continue_find_space:

    .protect:
        mov r10, qword [rel malloc_base]
        .loop_protect:
            cmp r10, 0
            je .bye
            mov r8, qword [r10]
            mov rax, 10
            mov rdi, r10
            mov rsi, 4096
            mov rdx, 1
            syscall
            cmp rax, 0
            jl .bye
            mov r10, r8
            jmp .loop_protect
    .bye:
    ret

    .go_next_malloc_page:
        cmp qword [r10], 0
        je .bye
        CALL_ putchar, 'n'
        CALL_ putchar, 'p'
        CALL_ putchar, 10
        mov r10, qword [r10]
        mov r11, -1
        jmp .find_space

putchar:
    mov dl, dil
    mov rax, 12
    mov rdi, 0
    syscall
    mov rsi, rax
    mov rax, 12
    lea rdi, [rsi + 1]
    syscall
    
    mov byte [rsi], dl
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    mov rax, 12
    lea rdi, [rsi]
    syscall
    ret

putnbr:
    cmp rdi, 0
    jl .putnbr_neg
    call .putnbr_pos
    ret

    .putnbr_neg:
        CALL_ putchar, '-'

        neg rdi
        call .putnbr_pos
        ret

    .putnbr_pos:
        mov r8, rdi

        mov r11, 0
        .loop_putnbr_len:
            inc r11

            mov rdi, 10
            mov rsi, r11
            call power

            mov rbx, rax
            mov rax, r8
            xor rdx, rdx
            div rbx

            cmp rax, 1
            jge .loop_putnbr_len
        
        .loop_putnbr:
            dec r11

            mov rdi, 10
            mov rsi, r11
            call power
            mov rbx, rax
            mov rax, r8
            xor rdx, rdx
            div rbx

            mov r8, rdx
            add rax, '0'
            CALL_ putchar, rax

            cmp r11, 0
            jne .loop_putnbr
        xor rax, rax
        ret

power:
    cmp rsi, 0
    jl .neg_power_it
    cmp rsi, 0
    je .zero_power_it

    mov rax, 1
    .loop_power_it:
        dec rsi

        mul rdi

        cmp rsi, 0
        jne .loop_power_it
    ret

    .zero_power_it:
        mov rax, 1
        ret
    
    .neg_power_it:
        mov rax, 0
        ret
