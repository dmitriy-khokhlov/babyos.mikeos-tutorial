                BITS    16

start:
                mov     ax, CODE_SEGMENT + (SECTOR_SIZE >> 4) ; Set up stack right after code
                mov     ss, ax
                mov     sp, STACK_SIZE

                mov     ax, CODE_SEGMENT ; Set data segment to where we're loaded
                mov     ds, ax
                mov     es, ax

                mov     ah, 2           ; int 13h 'read sector, CHS mode' function
                mov     al, 1           ; sectors count
                mov     ch, 0           ; cylinder
                mov     dh, 0           ; head
                mov     cl, 2           ; sector
                mov     bx, SECTOR_SIZE ; es:bx - buffer address
                ; dl already contains correct drive number passed from BIOS
                int     13h             ; read the rest of bootloader

                mov     si, message
                call    print_string

                jmp     $               ; Infinite loop because nothing to do more



CODE_SEGMENT    equ     0x07C0          ; BIOS loads us to 0000:7C00 = 07C0:0000
SECTOR_SIZE     equ     512
STACK_SIZE      equ     4096            ; 4K stack "ought to be enough for anybody" (c)
SIGNATURE       equ     0xAA55          ; Standard PC signature at end of boot sector
SIGNATURE_SIZE  equ     2

message         db      `\n`, "BabyOS born of MikeOS's tutorial", 0
;message         db      'ok', 0         ; Can't fit both full message and debug stuff into sector size



                times   (SECTOR_SIZE - SIGNATURE_SIZE) - ($ - $$) \
                db      0               ; Pad remainder of boot sector with zeros

                dw      SIGNATURE



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



; =============== DEBUG STUFF ===============

_SCREEN_WIDTH \
                equ     80
_SCREEN_HEIGHT  equ     25
_TEXT_BUFFER_LINE_SIZE \
                equ     _SCREEN_WIDTH * 2
_TEXT_BUFFER_SIZE \
                equ     _TEXT_BUFFER_LINE_SIZE * _SCREEN_HEIGHT
_textBufferOffset \
                dw      0

_BULLET_COLOR \
                equ     0x0C
_REGISTERS_BACK_COLOR \
                equ     0x00
_FLAGS_BACK_COLOR \
                equ     0x10
_STACK_BACK_COLOR \
                equ     0x40
_LABEL_FORE_COLOR \
                equ     0x0A
_VALUE_FORE_COLOR_1 \
                equ     0x0F
_VALUE_FORE_COLOR_2 \
                equ     0x07
_SET_FLAG_FORE_COLOR \
                equ     0x0E
_CLEARED_FLAG_FORE_COLOR \
                equ     0x08
_valueForeColors \
                db      _VALUE_FORE_COLOR_1, _VALUE_FORE_COLOR_2
_flagForeColors db      _CLEARED_FLAG_FORE_COLOR, _SET_FLAG_FORE_COLOR
_bulletLabel    db      '>>', 0

_REGISTERS_COUNT \
                equ     13 ; не считаем регистр флагов
_PRINT_STACK_BYTES_COUNT \
                equ     2
; Таблица для хранения регистров. Начальные значения - смещения относительно
; вершины стека, по которым регистры попадут в стек
_registersTable dw      'ax', 22, 0, 'bx', 16, 0, 'cx', 20, 0, 'dx', 18, 0, \
                        'si', 10, 0, 'di',  8, 0, 'bp', 12, 0, \
                        'sp', 14
_registersTable_Sp \
                dw      0,
                dw      'ds',  6, 0, 'es',  4, 0, 'ss',  2, 0, 'cs',  0, 0, \
                        'ip', 26, 0
_flags          dw      'fl', 24, 0


; Нет ввода
; Нет вывода
DEBUG_PrintState:
                pushf
                pusha
                push    ds
                push    es
                push    ss ; для единообразия обработки
                push    cs ; для единообразия обработки

;                mov     ax, cs
;                mov     ds, ax

                mov     cx, _REGISTERS_COUNT + 1 ; флаги скопируем в общем цикле
                mov     si, _registersTable + 2
                mov     bp, sp
.saveRegister:
                mov     bx, [ si ]
                add     bx, bp
                mov     bx, [ ss:bx ]
                add     si, 2
                mov     [ si ], bx
                add     si, 4
                loop    .saveRegister
                add     word [ _registersTable_Sp ], 4 ; скорректировать sp

                mov     ax, 0xB800
                mov     es, ax
                mov     di, [ _textBufferOffset ]

                mov     bh, _BULLET_COLOR
                mov     si, _bulletLabel
                call    _PrintString
                call    _PrintRegisters
                call    _PrintFlags
                call    _PrintStack

                mov     ax, [ _textBufferOffset ]
.addLine:
                add     ax, _TEXT_BUFFER_LINE_SIZE
                cmp     ax, _TEXT_BUFFER_SIZE
                jae     .resetTextBufferOffset
                cmp     di, ax
                ja      .addLine

                mov     [ _textBufferOffset ], ax
                jmp     .restoreRegisters

.resetTextBufferOffset:
                mov     word [ _textBufferOffset ], 0

.restoreRegisters:
                add     sp, 4 ; ss и cs восстанавливать не нужно
                pop     es
                pop     ds
                popa
                popf
                ret
; конец DEBUG_PrintState

; Ввод:
;     es:di - см. _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     ax, bx, cx, si
_PrintRegisters:
                mov     si, _registersTable
                mov     cx, _REGISTERS_COUNT

.printRegister:
                mov     bh, _REGISTERS_BACK_COLOR | _LABEL_FORE_COLOR
                lodsw
                xchg    ah, al
                call    _PrintWordChar

                mov     bh, _REGISTERS_BACK_COLOR | _VALUE_FORE_COLOR_1
                add     si, 2
                lodsw
                call    _PrintWordHex

                loop    .printRegister

                ret
; конец _PrintRegister

; Ввод:
;     es:di - см. _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     ax, bx, cx
_PrintFlags:
                mov     cx, _flags + 4

                mov     al, 'n'
                rol     cx, 2
                call    _PrintSingleBitFlag

                rol     cx, 2
                mov     ax, cx
                and     ax, 0x0003
                shl     ax, 7
                shr     al, 7
                add     ax, '00'
                mov     bh, _FLAGS_BACK_COLOR | _SET_FLAG_FORE_COLOR
                call    _PrintWordChar

                mov     al, 'o'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 'd'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 'i'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 't'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 's'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 'z'
                rol     cx, 1
                call    _PrintSingleBitFlag

                mov     al, 'a'
                rol     cx, 2
                call    _PrintSingleBitFlag

                mov     al, 'p'
                rol     cx, 2
                call    _PrintSingleBitFlag

                mov     al, 'c'
                rol     cx, 2
                call    _PrintSingleBitFlag

                ret
; конец _PrintFlags

; Ввод:
;     al - код символа, обозначающего данный флаг
;     cx - содержимое флага в младшем бите
;     es:di - см. _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     al, bx
_PrintSingleBitFlag:
                mov     bx, cx
                and     bx, 0x0001
                mov     bh, [ _flagForeColors + bx ]
                add     bh, _FLAGS_BACK_COLOR
                call    _PrintByteChar
                ret
; конец _PrintSingleBitFlag

; Ввод:
;     es:di - см. _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     ax, bx, cx, bp
_PrintStack:
                mov     bp, [ _registersTable_Sp ]
                mov     cx, _PRINT_STACK_BYTES_COUNT

.printStackWord:
                mov     bx, _PRINT_STACK_BYTES_COUNT
                sub     bx, cx
                and     bx, 0x0007
                jnz     .doNotPrintSeparator

                mov     al, ' '
                mov     bh, _STACK_BACK_COLOR
                call    _PrintByteChar

.doNotPrintSeparator:
                mov     bx, _PRINT_STACK_BYTES_COUNT
                sub     bx, cx
                shr     bx, 1
                and     bx, 0x0001
                mov     bh, [ _valueForeColors + bx ]
                or      bh, _STACK_BACK_COLOR
                mov     ax, [ bp ]
                call    _PrintByteHex
                inc     bp
                loop    .printStackWord

                ret
; конец _PrintStack

; Ввод:
;     al - байт, который нужно вывести
;     bh - цвета фона и текста
;     es - сегментный адрес текстового буфера видеокарты (обычно 0xB800)
;     di - позиция в текстовом буфере, в которую нужно произвести вывод
; Вывод:
;     di - позиция в текстовом буфере, следующая за выведенными данными
; Изменяет:
;     al
_PrintByteChar:
                stosb
                mov     al, bh
                stosb
                ret
; конец _PrintByteChar

; Ввод:
;     ax - слово, которое нужно вывести
;     остальное аналогично _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     ax
_PrintWordChar:
                xchg    ah, al
                call    _PrintByteChar
                mov     al, ah
                call    _PrintByteChar
                ret
; конец _PrintWordChar

; Ввод:
;     см. _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     ax
_PrintByteHex:
                call    _ByteToHex
                call    _PrintWordChar
                ret
; конец _PrintByteHex

; Ввод:
;     см. _PrintWordChar
; Вывод:
;     см. _PrintWordChar
; Изменяет:
;     ax
_PrintWordHex:
                push    ax
                mov     al, ah
                call    _PrintByteHex
                pop     ax
                call    _PrintByteHex
                ret
; конец _PrintWordHex

; Ввод:
;     ds:si - адрес выводимой строки, заканчивающейся нулевым символом
;     остальное аналогично _PrintByteChar
; Вывод:
;     см. _PrintByteChar
; Изменяет:
;     al, si
_PrintString:
                lodsb
                test    al, al
                jz      .exitPrintString
                call    _PrintByteChar
                jmp     _PrintString
.exitPrintString:
                ret
; конец _PrintString

; Ввод:
;     al - байт, который нужно сконвертировать в шестнадцатиричное представление
; Вывод:
;     ah - код символа для старшей шестнадцатиричной цифры байта
;     al - код символа для младшей шестнадцатиричной цифры байта
_ByteToHex:
                mov     ah, al

                shr     al, 4
                cmp     al, 0x0A
                sbb     al, 0x69
                das

                xchg    al, ah

                and     al, 0x0F
                cmp     al, 0x0A
                sbb     al, 0x69
                das

                ret
; конец _ByteToHex

; =============== END OF DEBUG STUFF ===============



                times   SECTOR_SIZE - ($ - $$) % SECTOR_SIZE \
                db      0               ; Pad remainder of last sector with zeros
