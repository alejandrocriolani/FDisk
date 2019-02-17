[BITS 16]
org 0x7C00

    ; -----------------------------------------------------------------
    ; Inicializar stack y segments registers
    ; -----------------------------------------------------------------
    xor ax, ax      ; 
    mov ds, ax      ; Set DS at 0
    mov es, ax      ; Set ES = DS
    mov bx, 0x8000  ; Stack segment located at 8000h (to any usable memory)

    cli             ; Disable interrupts
    mov ss, bx      ; This places it with the top of the stack 80000h
    mov sp, ax      ; Set SP = 0 so the bottom of the stack will be 8FFFFh
    sti             ; Re-enable interrupts

    cld             ; Set the direction flag to positive direction


    ; -----------------------------------------------------------------
    ; You should do further initializations here
    ; like setup the stack and segment registers.

    ; Load stage 2 to memory.
    mov ah, 0x02
    ; Number of sectors to read.
    mov al, 3
    ; This may not be necessary as many BIOS set it up as an initial state.
    mov dl, 0x0
    ; Cylinder number.
    mov ch, 0
    ; Head number.
    mov dh, 0
    ; Starting sector number. 2 because 1 was already loaded.
    mov cl, 2
    ; Where to load to.
    mov bx, stage2
    int 0x13

    jc leerFloppyError

    mov si, stageTwoOk
    call escribirCadena

    jmp stage2

leerFloppyError:
    mov si, stageTwoBad
    call escribirCadena

; -----------------------------------------------------------------
; Escribir un caracter por interrupciones de la BIOS
; -----------------------------------------------------------------
escribir:
    push ax
    push bx

    mov ah, 0x0E           ; Color 
    mov bh, 0x00           

    mov bl, 0x06           ; Color background
    mov al, dl

    int 0x10

    pop bx
    pop ax

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Escribir una cadena de caracter por interrupciones de BIOS
; -----------------------------------------------------------------
escribirCadena:
    push ax
    push bx

nextChar:
    mov dl, [si]
    inc si
    or dl, dl
    jz escribirCadenaRet
    call escribir
    jmp nextChar
escribirCadenaRet:
    pop bx
    pop ax
    ret
; -----------------------------------------------------------------

    stageTwoOk db 'Stage 2!', 0
    stageTwoBad db 'Error al pasar a Stage 2!', 0

    ; Magic bytes.    
    times ((0x200 - 2) - ($ - $$)) db 0x00
    dw 0xAA55
; -----------------------------------------------------------------

stage2:
    ;Imprimimos una linea de bienvenida
    call limpiarPantalla
    mov si, bienvenido
    mov byte [cursorX], 36 ;centramos el texto manualmente
    call imprimir
    call nuevaLinea
menuPrincipal:
    call nuevaLinea
    mov si, menu
    mov byte [cursorX], 38 ;centramos el texto manualmente
    call imprimir
    call nuevaLinea

    ;imprimimos las opciones del usuario
    mov si, opMenuP1
    call imprimir
    call nuevaLinea
    mov si, opMenuP2
    call imprimir
    call nuevaLinea
    mov si, elegirOpcion
    call imprimir

    ;Leemos del teclado
    xor ax, ax
    int 0x16

    cmp ah, 0x02
    je menuPrincipalOp1
    cmp ah, 0x0B
    je salir
    jmp menuPrincipalError

menuPrincipalOp1:
    mov byte [opCode], 0x30
    mov si, opCode
    call imprimir
    call nuevaLinea

    call leerDisco
    jmp salir

menuPrincipalError:
    mov dl, ah

    push dx

    call imprimir
    call dejarUnEspacio
    pop dx
    call numeroACadena
    call nuevaLinea


    jmp menuPrincipal

    ;call leerDisco
    ;call nuevaLinea

    ;call test1

    ;mov dl, 0x0
    ;call numeroACadena
    ;mov dl, 0x1F
    ;call numeroACadena

salir:
    call nuevaLinea
    mov si, opMenuP2
    call imprimir

    cli
    hlt

; -----------------------------------------------------------------
; Imprimir cadena de caracteres
; -----------------------------------------------------------------
imprimir:
    push ax
    push bx
    push cx

imprimirLoop:
    mov cl, [si]
    or cl, cl
    jz imprimirRet
    call imprimirCaracter
    inc byte [cursorX]
    inc si
    jmp imprimirLoop

imprimirRet:
    call actualizarCursorPos
    pop cx
    pop bx
    pop ax

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Imprimir caracter
; -----------------------------------------------------------------
imprimirCaracter:
    ; Calcular valor de DI
    call chequearNuevaLinea
    xor ax, ax
    mov al, byte [cursorY] ; cursorY va desde 0 a 24, entra en un byte
    mov dl, byte [anchoP] ; 80
    mul dl
    xor dx, dx
    mov dl, byte [cursorX] ; 
    add ax, dx
    shl ax, 1 ; ax = ax * 2
    mov di, ax

    ; Imprimir caracter
    mov ax, 0xb800
    mov fs, ax
    mov ah, 0x1f
    mov al, cl
    mov byte [fs:di], al
    dec di
    mov byte [fs:di], ah
    ;mov di, 0
    ;rep stosw
    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Nueva Linea
; -----------------------------------------------------------------
nuevaLinea:
    push bx

    mov byte [cursorX], 0
    inc byte [cursorY]

    cmp byte [cursorY], 25
    jne nuevaLineaRet
    mov byte [cursorY], 0

nuevaLineaRet:
    call actualizarCursorPos
    pop bx

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Limpiar pantalla
; -----------------------------------------------------------------
limpiarPantalla:
    push ax
    push cx

    mov ax, 0xb800
    mov cx, 2000
    mov fs, ax
    mov ax, 0x1f20
    ;mov es, ax
    xor di, di
    ;rep stosw

limpiarPantallaLoop:
    mov byte [fs:di], al
    mov byte [fs:di + 1], ah
    add di, 2
    dec cx
    cmp cx, 0
    jne limpiarPantallaLoop

    xor di, di
    mov byte [cursorX], 0
    mov byte [cursorY], 0
    call actualizarCursorPos

    pop cx
    pop ax

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Limpiar pantalla dejando la primer linea
; -----------------------------------------------------------------
limpiarPantallaSinElTitulo:
    push ax
    push cx

    mov ax, 0xb800
    mov cx, 1840
    mov fs, ax
    mov ax, 0x1f20
    ;mov es, ax
    mov di, 160
    ;rep stosw

limpiarPantallaSETLoop:
    mov byte [fs:di], al
    mov byte [fs:di + 1], ah
    add di, 2
    dec cx
    cmp cx, 0
    jne limpiarPantallaSETLoop

    xor di, di
    mov byte [cursorX], 0
    mov byte [cursorY], 1
    call actualizarCursorPos

    pop cx
    pop ax

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Dejar un espacio
; -----------------------------------------------------------------
dejarUnEspacio:
    inc byte [cursorX]
    call chequearNuevaLinea
    call actualizarCursorPos
    ret

; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Chequear nueva linea
; -----------------------------------------------------------------
chequearNuevaLinea:
    push ax

    mov al, byte [cursorX]
    cmp al, 80
    jne retChequearNuevaLinea
    mov byte [cursorX], 0
    inc byte [cursorY]
retChequearNuevaLinea:
    pop ax

    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Scroll Up (No usar)
; -----------------------------------------------------------------
scrollUp:
    push ax
    push bx
    push cx
    push dx

    mov ax, 0x0601
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184f
    int 0x10

    mov ax, 0xb800
    mov es, ax
    mov ax, 0x1f20
    mov cx, 80
    mov di, 1920
    rep stosw

    pop dx
    pop cx
    pop bx
    pop ax
    
    ret
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Actualizar posición del cursor
; -----------------------------------------------------------------
actualizarCursorPos:
    push ax
    push bx
    push dx

    mov ah, 0x02 ; decimos que cambiamos la posición del cursor
    mov bh, 0x00 ; número de página
    ;mov dh, 0x01 ; número de fila
    ;mov dl, 0x0C ; número de columna
    mov dh, byte [cursorY]
    mov dl, byte [cursorX]
    int 0x10

    pop dx
    pop bx
    pop ax

    ret

; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Leer disco
; -----------------------------------------------------------------
leerDisco:
    push ax
    push bx
    push cx
    push dx

    ;mov ax, 0
    ;mov es, ax
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
    ;mov si, discoLeido
    ;call imprimir
    ;call nuevaLinea

menuTablaParticiones:
    call limpiarPantallaSinElTitulo
    mov si, ptMenu
    mov byte [cursorX], 30
    call imprimir
    call nuevaLinea

    ; ----------------------------------------------------------------------------------
    ; Primera fila de la tabla
    ; ----------------------------------------------------------------------------------
    mov si, part
    call imprimir
    
    mov byte [cursorX], 12
    mov si, separador
    call imprimir

    mov byte [cursorX], 14
    mov si, inicio
    call imprimir
    mov byte [cursorX], 21
    mov si, cylinder
    call imprimir

    mov byte [cursorX], 27
    mov si, head
    call imprimir

    mov byte [cursorX], 30
    mov si, sector
    call imprimir

    mov byte [cursorX], 33
    mov si, separador
    call imprimir

    mov byte [cursorX], 35
    mov si, final
    call imprimir

    mov byte [cursorX], 39
    mov si, cylinder
    call imprimir

    mov byte [cursorX], 44
    mov si, head
    call imprimir

    mov byte [cursorX], 47
    mov si, sector
    call imprimir

    mov byte [cursorX], 50
    mov si, separador
    call imprimir

    mov byte [cursorX], 52
    mov si, tamanio
    call imprimir

    mov byte [cursorX], 60
    mov si, separador
    call imprimir

    mov byte [cursorX], 62
    mov si, tipoDeParticion
    call imprimir

    ; ----------------------------------------------------------------------------------
    ; Filas de la tabla de particiones
    ; ----------------------------------------------------------------------------------
    call nuevaLinea
    xor cx, cx
    xor ax, ax

    push ax
    
analizarTablaLoop:
    mov byte [cursorX], 9

    mov dl, cl
    inc dl
    call numeroACadena

    mov byte [cursorX], 0

    mov si, part
    call imprimir
 
    mov byte [cursorX], 12
    mov si, separador
    call imprimir
    
    ;Leer el formato

    mov byte [cursorX], 60
    mov si, separador
    call imprimir

    mov byte [cursorX], 62
    pop ax
    mov bx, 0x1C2
    add bx, ax
    push ax
    mov dl, [es:bx]

    cmp dl, 0x87 ;NTFS
    je particionNTFS
    cmp dl, 0x0b
    je particionFAT32
    cmp dl, 0x83
    je particionEXT3
particionSinFormato:
    mov si, sinFormato
    call imprimir
    jmp inicioDeDisco

particionNTFS:
    mov si, fNTFS
    call imprimir
    jmp inicioDeDisco

particionFAT32:
    mov si, fFAT32
    call imprimir
    jmp inicioDeDisco

particionEXT3:
    mov si, fEXT3
    call imprimir

inicioDeDisco:
    ;Leer inicio del cilindro
    mov byte [cursorX], 21
    pop ax
    mov bx, 0x01C0
    add bx, ax
    push ax
    mov dl, [es:bx]
    shr dl, 6
    call numeroACadena
    pop ax
    mov bx, 0x01C1
    add bx, ax
    push ax
    mov dl, [es:bx]
    call numeroACadena

    ;Leer incio del sector
    pop ax
    mov bx, 0x01C0
    add bx, ax
    push ax
    mov byte [cursorX], 30
    mov dl, [es:bx]
    and dl, 0x3F ; = 00111111
    call numeroACadena

    ;Leer inicio cabeza
    mov byte [cursorX], 27 
    pop ax
    mov bx, 0x01BF
    add bx, ax
    push ax
    mov dl, [es:bx]
    call numeroACadena

    mov byte [cursorX], 33
    mov si, separador
    call imprimir

finalDeDisco:
    ;Leer final del cilindro
    mov byte [cursorX], 39
    pop ax
    mov bx, 0x01C4
    add bx, ax
    push ax
    mov dl, [es:bx]
    shr dl, 6
    call numeroACadena
    pop ax
    mov bx, 0x01C5
    add bx, ax
    push ax
    mov dl, [es:bx]
    call numeroACadena

    ;Leer final del sector
    pop ax
    mov bx, 0x01C4
    add bx, ax
    push ax
    mov byte [cursorX], 47
    mov dl, [es:bx]
    and dl, 0x3F ; = 00111111
    call numeroACadena

    ;Leer final cabeza
    mov byte [cursorX], 44
    pop ax 
    mov bx, 0x01C3
    add bx, ax
    push ax
    mov dl, [es:bx]
    call numeroACadena

    mov byte [cursorX], 50
    mov si, separador
    call imprimir
    
    ;Leer el tamaño de la partición
    pop ax
    mov bx, 0x1CC
    add bx, ax
    push ax   
    mov byte [cursorX], 52
    xor ax, ax

    push cx

    mov cx, 3 ;Contador del tamaño de la particion
    

;Lectura del tamaño de la particion
leerTP1L:             
    mov dl, byte [es:bx]

    push cx
    push bx
    call numeroACadena
    pop bx
    pop cx

    dec bx
    dec cx
    cmp cx, 0x0
    je finalDeLecturaDeParticion
    jmp leerTP1L

finalDeLecturaDeParticion:
    pop cx
    pop ax
    add ax, 16
    push ax
    call nuevaLinea
    inc cx
    cmp cx, 4
    je leerDiscoRet
    jmp analizarTablaLoop

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

; -----------------------------------------------------------------
; Numeros a Cadena de caracteres y mostrar por pantalla
; -----------------------------------------------------------------

numeroACadena:
    push bx
    xor ax, ax
primerDigito:                   ;Dígito de la izquierda
    mov al, dl
    shr al, 4
    cmp al, 10
    jge mayorA10PD
    add al, '0'
    mov byte [hexToAscii], al
    jmp segundoDigito

mayorA10PD:
    add al, 55                  ;'A' - 10
    mov byte [hexToAscii], al

segundoDigito:                  ;Dígito de la derecha
    xor ax, ax
    mov al, dl
    and al, 0x0F
    cmp al, 10
    jge mayorA10SD
    add al, '0'
    mov byte [hexToAscii + 1], al
    jmp retNumeroACadena

mayorA10SD:
    add al, 55                  ;'A' - 10
    mov byte [hexToAscii + 1], al

retNumeroACadena:
    xor ax, ax
    mov si, hexToAscii
    call imprimir

    pop bx
    ret

; -----------------------------------------------------------------

; -----------------------------------------------------------------
; Imprimir A Varias veces
; -----------------------------------------------------------------
test1:
    push cx
    mov cx, 600

test1loop:
    cmp cx, 0
    je testret
    mov si, aaaa
    call imprimir
    call dejarUnEspacio
    dec cx
    jmp test1loop

testret:
    pop cx
    ret

; -----------------------------------------------------------------

; -----------------------------------------------------------------

    cursorX db 0 ; Posicion horizontal del cursor
    cursorY db 0 ; Posicion vertical del cursor
    anchoP db 80 ; Ancho de la pantalla
    altoP db 25 ; Alto de la pantalla

    hexToAscii db '00',0 ; lugar donde guardamos el byte para imprimirlo por pantalla
    opCode db '0',0 ; lugar donde guardamos la opcion elegida por el usuario

    verdadero db 'True',0
    falso db 'False',0
    aaaa db 'A', 0 ;Para testear la impresion por pantalla

    discoLeido db 'Disco leido!',0
    discoNoLeido db 'Disco no leido!', 0

    ;Menu principal
    bienvenido db 'TP FDisk',0
    menu db 'Menu!', 0
    opMenuP1 db '1. Leer tabla de particiones', 0
    opMenuP2 db '0. Salir de FDisk',0
    opError db 'Opcion incorrecta',0
    elegirOpcion db 'Elija su opcion: ', 0

    ;Menu de tabla de particiones
    ptMenu db 'Tabla de particiones',0
    part db 'Particion ', 0
    inicio db 'Inicio', 0
    final db 'Fin',0
    tamanio db 'Espacio', 0
    cylinder db 'C', 0
    head db 'H',0
    sector db 'S', 0
    separador db '|', 0
    tipoDeParticion db 'Formato ', 0

    sinFormato db 'Sin formato', 0 ; 00h Empty partition table
    fNTFS db 'NTFS', 0 ; 87h
    fFAT32 db 'FAT 32', 0 ; 0bh FAT 32 with CHS addressing, 0ch FAT 32 with LBA
    fEXT3 db 'Linux File System', 0 ;83h

    ;Menu de formateo
    formatMenu db 'Formatear disco ', 0

    
    fMSalir db '0. Volver al menu principal',0


    ; Pad image to multiple of 512 bytes.
    times ((0x800) - ($ - $$)) db 0x00