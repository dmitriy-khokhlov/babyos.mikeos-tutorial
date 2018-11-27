                BITS    16

start:
                mov     ax, CODE_SEGMENT + (SECTOR_SIZE >> 4) ; Set up stack right after code
                mov     ss, ax
                mov     sp, STACK_SIZE

                mov     ax, CODE_SEGMENT ; Set data segment to where we're loaded
                mov     ds, ax

                mov     si, message
                call    print_string

                jmp     $               ; Infinite loop because nothing to do more



CODE_SEGMENT    equ     0x07C0          ; BIOS loads us to 0000:7C00 = 07C0:0000
SECTOR_SIZE     equ     512
STACK_SIZE      equ     4096            ; 4K stack "ought to be enough for anybody" (c)
SIGNATURE       equ     0xAA55          ; Standard PC signature at end of boot sector
SIGNATURE_SIZE  equ     2

message         db      `\n`, "BabyOS born of MikeOS's tutorial", 0



; Prints string to screen at current cursor position
; Takes:
;     ds:si - address of string
; Returns:
;     nothing
; Changes:
;     al, ah, bh, si
print_string:
                mov     ah, 0Eh         ; int 10h 'print char' function
                mov     bh, 0           ; int 10h page number = 0
.print_char:
                lodsb                   ; Get character from string to AL
                cmp     al, 0
                je      .done           ; If character is zero, end of string
                int     10h             ; Otherwise, print it
                jmp     .print_char
.done:
                ret
; End of print_string



                times   (SECTOR_SIZE - SIGNATURE_SIZE) - ($ - $$) \
                db      0               ; Pad remainder of boot sector with zeros

                dw      SIGNATURE
