        BITS 16

STACK_SIZE \
        equ 4096

start:
        mov ax, 07C0h           ; Set up 4K stack space after this bootloader
        add ax, 288             ; (4096 + 512) / 16 bytes per paragraph
        mov ss, ax
        mov sp, STACK_SIZE

        mov ax, 07C0h           ; Set data segment to where we're loaded
        mov ds, ax

        mov si, message
        call print_string

        jmp $                   ; Infinite loop because nothing to do more



message db "BabyOS born of MikeOS's tutorial", 0



; Routine: output string pointed by SI to screen
print_string:
        mov ah, 0Eh             ; int 10h 'print char' function

.print_char:
        lodsb                   ; Get character from string
        cmp al, 0
        je .done                ; If character is zero, end of string
        int 10h                 ; Otherwise, print it
        jmp .print_char

.done:
        ret



        times 510 - ($ - $$) db 0       ; Pad remainder of boot sector with zeros
        dw 0xAA55                       ; Standard PC signature at end of boot sector
