[BITS 16]
org 0x7C00

mov ax, 0xb800
;mov es, ax
;mov ax, 0x1f46
;mov cx, 1
;xor di, di
;rep stosw
mov fs, ax
xor di, di
mov ax, 0x1f46
mov byte [fs:di], al
inc di
mov byte [fs:di], ah

times ((0x200 - 2) - ($ - $$)) db 0x00 
dw 0xAA55