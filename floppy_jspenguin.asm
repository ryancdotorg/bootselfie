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
	mov sp,0xfff0
	sti
	push word KERNEL_SEGMENT
	pop es

	mov bx, KERNEL_OFFSET
	mov cx, KERNEL_SIZE
	mov ax, 1
	mov dl, 0

more:
	push ax
	push cx
	mov dx,0
	mov cx, 18
	div cx

	mov ch,al
	shr ch,1

	mov dh,al
	and dh,1

	mov cl,dl
	inc cl

	mov ax,2

	mov dl,0

again:
	mov ax,0x201
	int 13h
	jnc ok
	jmp again
ok:
	pop cx
	pop ax

	add bx,512
	inc ax
	loop more

clear:
	mov ax, 0x0700         ; clear screen
	mov bh, 0x07
	xor cx, cx
	mov dl, 0x4f
	mov dh, 0x18
	int 0x10


	mov bx, 0x0101         ; move cursor to 0, 0
	mov ax, 0x02
	int 0x10

	xor ax, ax             ; zero registers
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
KERNEL_SIZE equ ((IMAGE_SIZE/512))      ; Kernel size in disk blocks
times (2880*512 - ($ - $$)) db 0

; vim:ft=nasm
