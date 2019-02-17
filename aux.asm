; -----------------------------------------------------------------
; Leer disco
; -----------------------------------------------------------------
leerDisco:
    push ax
    push bx
    push cx
    push dx

    mov ax, 0
    mov es, ax
    mov ah, 0x02    ;Leer sectores
    mov al, 1       ;Numero de sectores a leer
    mov ch, 0       ;Numero de cilindro
    mov cl, 1       ;Numero de sector
    mov dh, 0       ;Numero de cabeza
    mov dl, 0x80    ;Leer del disco
    mov bx, 0x6000  ;ES:BX - 0000h:6000h
    mov es, bx      
    xor bx, bx      ;ES:BX - 6000h:0000h
     
    int 0x13

    jc leerDiscoError
    mov si, discoLeido
    call imprimir
    call nuevaLinea

    mov bx, 0x1CA   ;Leer el tamaño de la partición

    ;jmp leerDiscoRet
analizarPB:

    xor ax, ax
    mov al, byte [pByte]
    cmp al, [es:bx]

    je pByteIgual
    jmp pByteNoIgual

pByteIgual:
    mov si, verdadero
    call imprimir
    call nuevaLinea
    jmp analizarSB

pByteNoIgual:
    mov si, falso
    call imprimir
    call nuevaLinea
    xor dx, dx
    mov dl, [es:bx]
    call numeroACadena

analizarSB:
    xor ax, ax
    add bx, 1
    mov al, byte [sByte]
    cmp al, [es:bx]
    je sByteIgual
    jmp sByteNoIgual

sByteIgual:
    mov si, verdadero
    call imprimir
    call nuevaLinea
    jmp analizarTB

sByteNoIgual:
    mov si, falso
    call imprimir
    call nuevaLinea
    xor dx, dx
    mov dl, [es:bx]
    call numeroACadena

analizarTB:
    xor ax, ax
    add bx, 1
    mov al, byte [tByte]
    cmp al, [es:bx]
    je tByteIgual
    jmp tByteNoIgual

tByteIgual:
    mov si, verdadero
    call imprimir
    jmp leerDiscoRet

tByteNoIgual:
    mov si, falso
    call imprimir
    call nuevaLinea
    xor dx, dx
    mov dl, [es:bx]
    call numeroACadena
    jmp leerDiscoRet

leerDiscoError:
    mov si, discoNoLeido
    call imprimir

leerDiscoRet:
    pop dx
    pop cx
    pop bx
    pop ax

    ret
; -----------------------------------------------------------------