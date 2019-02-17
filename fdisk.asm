[BITS 16]
org 0x7C00

; ----------------------------------------------------------------------------------------
; Inicializar stack y segments registers
; ----------------------------------------------------------------------------------------
    xor ax, ax      ; 
    mov ds, ax      ; Set DS at 0.
    mov es, ax      ; Set ES = DS.
    mov bx, 0x8000  ; Stack segment located at 8000h (to any usable memory).

    cli             ; Disable interrupts
    mov ss, bx      ; This places it with the top of the stack 80000h.
    mov sp, ax      ; Set SP = 0 so the bottom of the stack will be 8FFFFh.
    sti             ; Re-enable interrupts.

    cld             ; Set the direction flag to positive direction.

; ----------------------------------------------------------------------------------------
; Load stage 2 to memory.
; ----------------------------------------------------------------------------------------
    mov ah, 0x02    ; Leer sectores.
    mov al, 4       ; Número de sectores a leer.
    mov dl, 0       ; Leer el primer diskette.
    mov ch, 0       ; Número de cilindro.
    mov dh, 0       ; Número de cabeza.
    mov cl, 2       ; Número de sector desde donde empieza a leer. El primero ya está cargado.
    mov bx, stage2  ; Donde cargarlo.
    int 0x13

    jc leerFloppyError
    jmp stage2

leerFloppyError:
    mov si, stageTwoBad
    call escribirCadena

; ----------------------------------------------------------------------------------------
; Escribir un caracter por interrupciones de la BIOS
; ----------------------------------------------------------------------------------------
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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Escribir una cadena de caracter por interrupciones de BIOS
; ----------------------------------------------------------------------------------------
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
; ----------------------------------------------------------------------------------------

    stageTwoBad db 'Error al pasar a Stage 2!', 0

    ; Magic bytes.    
    times ((0x200 - 2) - ($ - $$)) db 0x00
    dw 0xAA55
; ----------------------------------------------------------------------------------------

stage2:
    ;Imprimimos una linea de bienvenida
    call limpiarPantalla
    mov si, bienvenido
    mov byte [cursorX], 36 ;centramos el texto manualmente
    call imprimir
    call nuevaLinea

; ----------------------------------------------------------------------------------------
; Menu principal
; ----------------------------------------------------------------------------------------
menuPrincipal:
    mov si, menu
    mov byte [cursorX], 33 ;centramos el texto manualmente
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

menuPrincipalLeerOpc:
    ;Leemos el teclado
    xor ax, ax
    int 0x16                    ;Interrupción para lectura del teclado

    cmp ah, 0x02                ;Tecla '1'
    je menuPrincipalOp1
    cmp ah, 0x0B                ;Tecla '0'
    je salir
    jmp menuPrincipalLeerOpc    ;Otra tecla

menuPrincipalOp1:
    mov byte [opCode], 0x30
    mov si, opCode
    call imprimir
    call nuevaLinea

    call leerDisco
    jmp menuPrincipal

salir:
    mov ax, 0x5307
    mov bx, 1
    mov cx, 3
    int 0x15
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Imprimir cadena de caracteres
; ----------------------------------------------------------------------------------------
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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Imprimir caracter
; ----------------------------------------------------------------------------------------
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
    mov ah, 0x1f ; Color de fondo y del caracter
    mov byte [fs:di], cl ;Ponemos en la memoria de video el caracter
    dec di
    mov byte [fs:di], ah ;Ponemos en la memoria de video el color de fondo y caracter
    ret
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Nueva Linea
; ----------------------------------------------------------------------------------------
nuevaLinea:
    push bx

    mov byte [cursorX], 0
    inc byte [cursorY]

    cmp byte [cursorY], 25
    jne nuevaLineaRet
    call limpiarPantallaSinElTitulo

nuevaLineaRet:
    call actualizarCursorPos
    pop bx

    ret
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Limpiar pantalla
; ----------------------------------------------------------------------------------------
limpiarPantalla:
    push ax
    push cx

    mov ax, 0xb800
    mov cx, 2000
    mov fs, ax
    mov ax, 0x1f20
    xor di, di

limpiarPantallaLoop:
    mov byte [fs:di], al        ;Caracter ' '
    mov byte [fs:di + 1], ah    ;Fondo azul, letra blanca
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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Limpiar pantalla dejando la primer linea
; ----------------------------------------------------------------------------------------
limpiarPantallaSinElTitulo:
    push ax
    push cx

    mov ax, 0xb800
    mov cx, 1920
    mov fs, ax
    mov ax, 0x1f20
    mov di, 160

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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Dejar un espacio
; ----------------------------------------------------------------------------------------
dejarUnEspacio:
    inc byte [cursorX]
    call chequearNuevaLinea
    call actualizarCursorPos
    ret

; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Chequear nueva linea
; ----------------------------------------------------------------------------------------
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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Actualizar posición del cursor
; ----------------------------------------------------------------------------------------
actualizarCursorPos:
    push ax
    push bx
    push dx

    mov ah, 0x02 ; decimos que cambiamos la posición del cursor
    mov bh, 0x00 ; número de página
    mov dh, byte [cursorY]
    mov dl, byte [cursorX]
    int 0x10

    pop dx
    pop bx
    pop ax

    ret

; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Leer disco
; ----------------------------------------------------------------------------------------
leerDisco:
    push ax
    push bx
    push cx
    push dx

    mov ah, 0x02    ;Leer sectores
    mov al, 1       ;Numero de sectores a leer
    mov ch, 0       ;Numero de cilindro
    mov cl, 1       ;Numero de sector
    mov dh, 0       ;Numero de cabeza
    mov dl, 0x80    ;Leer del disco
    mov bx, 0x5000  ;ES:BX - 0000h:5000h
    mov es, bx      
    xor bx, bx      ;ES:BX - 5000h:0000h
     
    int 0x13

menuTablaParticiones:
    call limpiarPantallaSinElTitulo
    mov si, ptMenu
    mov byte [cursorX], 30
    call imprimir
    call nuevaLinea

; ----------------------------------------------------------------------------------------
; Primera fila de la tabla
; ----------------------------------------------------------------------------------------
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

    mov byte [cursorX], 26
    mov si, head
    call imprimir

    mov byte [cursorX], 29
    mov si, sector
    call imprimir

    mov byte [cursorX], 32
    mov si, separador
    call imprimir

    mov byte [cursorX], 34
    mov si, final
    call imprimir

    mov byte [cursorX], 38
    mov si, cylinder
    call imprimir

    mov byte [cursorX], 43
    mov si, head
    call imprimir

    mov byte [cursorX], 46
    mov si, sector
    call imprimir

    mov byte [cursorX], 49
    mov si, separador
    call imprimir

    mov byte [cursorX], 51
    mov si, tamanio
    call imprimir

    mov byte [cursorX], 60
    mov si, separador
    call imprimir

    mov byte [cursorX], 62
    mov si, tipoDeParticion
    call imprimir

; ----------------------------------------------------------------------------------------
; Filas de la tabla de particiones
; ----------------------------------------------------------------------------------------
    call nuevaLinea
    xor cx, cx
    xor ax, ax

    push ax
    
analizarTablaLoop:
; ----------------------------------------------------------------------------------------
; Imprimir numero de particion
; ----------------------------------------------------------------------------------------

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
    
; ----------------------------------------------------------------------------------------
; Leer el formato de una partición
; ----------------------------------------------------------------------------------------

    mov byte [cursorX], 60
    mov si, separador
    call imprimir

    mov byte [cursorX], 62
    pop ax
    mov bx, 0x1C2
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]

    cmp dl, 0x07        ;NTFS
    je particionNTFS
    cmp dl, 0x0B        ;FAT 32
    je particionFAT32
    cmp dl, 0x83        ;Linux
    je particionEXT4
particionSinFormato:
    mov si, sinFormato  ;Sin Formato
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

particionEXT4:
    mov si, fEXT4
    call imprimir

; ----------------------------------------------------------------------------------------
; Inicio de los valores CSH
; ----------------------------------------------------------------------------------------

inicioDeDisco:
; ----------------------------------------------------------------------------------------
; Leer inicio del cilindro
; ----------------------------------------------------------------------------------------
    mov byte [cursorX], 21
    pop ax
    mov bx, 0x01C0      ;Accedemos al byte del cilindro + sector
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    shr dl, 6           ;Nos quedamos con los 6 bits menos significativos
    call numeroACadena  ;Imprimimos
    pop ax
    mov bx, 0x01C1      ;Accedemos al byte del cilindro
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    call numeroACadena  ;Imprimimos

; ----------------------------------------------------------------------------------------
; Leer inicio del sector
; ----------------------------------------------------------------------------------------
    pop ax
    mov bx, 0x01C0      ;Accedemos al byte del cilindro + sector
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov byte [cursorX], 29
    mov dl, [es:bx]
    and dl, 0x3F        ;Nos quedamos con los 6 bits menos significativos. 0x3F = 00111111
    call numeroACadena  ;Imprimimos

; ----------------------------------------------------------------------------------------
; Leer inicio del head
; ----------------------------------------------------------------------------------------
    mov byte [cursorX], 26 
    pop ax
    mov bx, 0x01BF      ;Accedemos al byte del head
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    call numeroACadena  ;Imprimimos

    mov byte [cursorX], 32
    mov si, separador
    call imprimir

; ----------------------------------------------------------------------------------------
; Final de los valores del CHS
; ----------------------------------------------------------------------------------------
finalDeDisco:
; ----------------------------------------------------------------------------------------
; Leer final de la cilindro
; ----------------------------------------------------------------------------------------
    mov byte [cursorX], 38
    pop ax
    mov bx, 0x01C4      ;Accedemos al byte del cilindro + sector
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    shr dl, 6           ;Nos quedamos con los bits mas significativos
    call numeroACadena  ;Imprimimos
    pop ax
    mov bx, 0x01C5      ;Acedemos al byte del cilindro
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    call numeroACadena  ;Imprimimos

; ----------------------------------------------------------------------------------------
; Leer final del sector
; ----------------------------------------------------------------------------------------
    pop ax
    mov bx, 0x01C4      ;Accedemos al byte del cilindro + sector
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov byte [cursorX], 46
    mov dl, [es:bx]
    and dl, 0x3F ;      ;Nos quedamos con los 6 bits menos significativos. 0x3F = 00111111
    call numeroACadena  ;Imprimimos

; ----------------------------------------------------------------------------------------
; Leer final del head
; ----------------------------------------------------------------------------------------
    mov byte [cursorX], 43
    pop ax 
    mov bx, 0x01C3      ;Accedemos al byte del head
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax
    mov dl, [es:bx]
    call numeroACadena  ;Imprimimos

    mov byte [cursorX], 49
    mov si, separador
    call imprimir
    
; ----------------------------------------------------------------------------------------
; Leer el tamaño de una particion (Está en little-endian)
; ----------------------------------------------------------------------------------------
    pop ax
    mov bx, 0x1CD       ;Accedemos al último byte del tamaño de una partición
    add bx, ax          ;Le sumamos un offset de 0, 16, 32 o 48 para leer cada partición
    push ax   
    mov byte [cursorX], 51
    xor ax, ax

    push cx             ;Contador del numero de particiones

    mov cx, 4           ;Contador del tamaño de la partición
    
; ----------------------------------------------------------------------------------------
; Ciclo de lectura para los cuatro bytes del tamaño de una partición
; ----------------------------------------------------------------------------------------
leerTPL:             
    mov dl, byte [es:bx]

    push cx
    push bx
    call numeroACadena  ;Imprimimos
    pop bx
    pop cx

    dec bx              ;Nos movemos al byte anterior por estar en little-endiand
    dec cx              ;Decrementamos el contador
    cmp cx, 0x0
    je finalDeLecturaDeParticion
    jmp leerTPL

finalDeLecturaDeParticion:
    pop cx
    pop ax
    add ax, 16          ;Le sumamos un offset (tamaño de una entrada de una tabla de part)
    push ax
    call nuevaLinea
    inc cx
    cmp cx, 4           ;Terminamos de leer todas las entradas de una partición?
    je finAnalizarTablaParticion
    jmp analizarTablaLoop

finAnalizarTablaParticion:
    pop ax
    call menuDeFormateo
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
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Formatear particiones (selección de partición)
; ----------------------------------------------------------------------------------------

menuDeFormateo:
    call nuevaLinea
    mov byte [cursorX], 33
    mov si, formatMenu
    call imprimir
    call nuevaLinea
    mov si, selPart
    call imprimir
    xor ax, ax
    int 0x16
    cmp ah, 0x0B
    je retMenuDeFormateo
    cmp ah, 0x02
    je seleccionDeFormato
    cmp ah, 0x03
    je seleccionDeFormato
    cmp ah, 0x04
    je seleccionDeFormato
    cmp ah, 0x05
    je seleccionDeFormato
    jmp menuDeFormateo

seleccionDeFormato:
; ----------------------------------------------------------------------------------------
; Indicar que partición vamos a modificar
; ----------------------------------------------------------------------------------------
    call nuevaLinea
    mov cx, 1
    mov si, formatMenu
    call imprimir
    mov si, part
    mov byte [cursorX], 10
    call imprimir
    dec ah
    mov dl, ah
    push dx
    add ah, '0'
    mov [opCode], ah
    mov si, opCode
    call imprimir
    call nuevaLinea

; ----------------------------------------------------------------------------------------
; Imprimir opiones para el formateo
; ----------------------------------------------------------------------------------------

seleccionDeFormatoLoop:
    mov dl, cl
    add dl, '0'
    mov byte [opFormatMenu], dl
    mov si, opFormatMenu
    call imprimir
    call dejarUnEspacio
opcNTFS:
    cmp cx, 1
    jne opcFat
    mov si, fNTFS
    jmp finOpc
opcFat:
    cmp cx, 2
    jne opcExt
    mov si, fFAT32
    jmp finOpc
opcExt:
    cmp cx, 3
    jne opcSinFormato
    mov si, fEXT4
    jmp finOpc
opcSinFormato:
    cmp cx, 4
    mov si, sinFormato

finOpc:
    call imprimir
    call nuevaLinea
    inc cx
    cmp cx, 5
    jne seleccionDeFormatoLoop
opcSalir:
    mov si, fMSalir
    call imprimir
    call nuevaLinea

elegirOpcF:
    xor ax, ax
    int 0x16

    mov cl, ah
    pop dx
    dec dl
    mov al, dl
    mov ah, 16
    mul ah

    mov bx, 0x01C2
    add bx, ax

    cmp cl, 0x0B             ;Tecla '0'
    je retMenuDeFormateo
    cmp cl, 0x02             ;Tecla '1'
    je formatNTFS
    cmp cl, 0x03             ;Tecla '2'
    je formatFAT32
    cmp cl, 0x04             ;Tecla '3'
    je formatEXT4
    cmp cl, 0x05             ;Tecla '4'
    je formatSinFormato
    jmp elegirOpcF
    

formatNTFS:
    mov byte [es:bx], 0x07 ;NTFS
    jmp formatear

formatFAT32:
    mov byte [es:bx], 0x0B ;FAT32
    jmp formatear

formatEXT4:
    mov byte [es:bx], 0x83 ;EXT4
    jmp formatear

formatSinFormato:
    mov byte [es:bx], 0    ;Sin Formato

formatear:
    mov ah, 0x03    ;Escribir sector
    mov al, 0x01    ;Escribir un sector
    mov ch, 0       ;Cuantos tracks
    mov cl, 1       ;Que sector
    mov dh, 0       ;Que head
    mov dl, 0x80    ;Primer disco rígido
    xor bx, bx
    int 0x13

    jnc retMenuDeFormateo

fomarteoError:
    call nuevaLinea
    mov si, errorAlFormatear
    call imprimir

retMenuDeFormateo:
    call limpiarPantallaSinElTitulo
    ret
; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------
; Numeros a cadena de caracteres y mostrar por pantalla
; ----------------------------------------------------------------------------------------

numeroACadena:
    push bx
    xor ax, ax
primerDigito:                   ;Dígito de la izquierda
    mov al, dl
    shr al, 4                   ;Tomamos los 4 bits mas alto
    cmp al, 10
    jge mayorA10PD
    add al, '0'                 ;Menor que 10, sumamos con el valor ascii de '0'
    mov byte [hexToAscii], al   ;Lo guardamos para imprimir
    jmp segundoDigito

mayorA10PD:
    add al, 55                  ;Mayor a 10, sumamos con el valor ascii 'A'-10
    mov byte [hexToAscii], al

segundoDigito:                  ;Dígito de la derecha
    xor ax, ax
    mov al, dl  
    and al, 0x0F                ;Nos quedamos ocn los
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

; ----------------------------------------------------------------------------------------

; ----------------------------------------------------------------------------------------

    cursorX db 0 ; Posicion horizontal del cursor
    cursorY db 0 ; Posicion vertical del cursor
    anchoP db 80 ; Ancho de la pantalla
    altoP db 25 ; Alto de la pantalla

    hexToAscii db '00',0 ; lugar donde guardamos el byte para imprimirlo por pantalla
    opCode db '0',0 ; lugar donde guardamos la opcion elegida por el usuario

    discoNoLeido db 'Disco no leido!', 0

    ;Menu principal
    bienvenido db 'TP FDisk',0
    menu db 'Menu principal', 0
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

    sinFormato db 'Vacio', 0 ; 00h Empty partition table
    fNTFS db 'NTFS', 0 ; 07h
    fFAT32 db 'FAT 32', 0 ; 0bh FAT 32 with CHS addressing, 0ch FAT 32 with LBA
    fEXT4 db 'EXT4', 0 ;83h

    ;Menu de formateo
    formatMenu db 'Formatear disco', 0
    selPart db 'Ingrese el numero de una particion o 0 para salir: ', 0
    opFormatMenu db '0.', 0
    errorAlFormatear db 'Error al formatear!',0

    fMSalir db '0. Volver al menu principal',0

    ; Pad image to multiple of 512 bytes.
    times ((0xA00) - ($ - $$)) db 0x00
