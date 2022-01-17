;
; floppy.asm - builds the floppy image, includes the required bootsector code
;

bits 16


org 0

%ifndef _KERNEL_OFFSET
%define _KERNEL_OFFSET 0x0
%endif

KERNEL_START equ 1

KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET equ _KERNEL_OFFSET

		cli
		mov ax,0x9000
		mov ss,ax
		mov sp,0xffff
		sti

		mov ax, 200h + KERNEL_SIZE
		push word KERNEL_SEGMENT
		pop es
		mov bx, KERNEL_OFFSET
		mov cx, KERNEL_START + 1

		int 13h
		jnc ok
		jmp $
ok:
		xor ax, ax
		mov bx, ax
		mov cx, ax
		mov dx, ax
		jmp KERNEL_SEGMENT:KERNEL_OFFSET

times 510 - ($ - $$) db 0
db 55h
db 0aah

IMAGE_START equ ($-$$)
incbin "image.com"
IMAGE_SIZE equ ($-$$)-IMAGE_START
KERNEL_SIZE equ ((IMAGE_SIZE/512)+1)    ; Kernel size in disk blocks
times (2880*512 - ($ - $$)) db 0

; vim:ft=nasm
