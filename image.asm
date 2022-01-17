;
; image.asm - image.jpg on your MCGA 320x200x256 screen
;

bits 16
%ifndef _KERNEL_OFFSET
%define _KERNEL_OFFSET 0x0
%endif
org _KERNEL_OFFSET

%ifndef PWLEN
%define PWLEN 6
%endif

start:
	; copy code segment address to data segment and extra segment addresses
	push cs
	pop ds
	push cs
	pop es



askpass:
	mov si, key            ; message address
	mov di, si             ; it's also the key address, copy it now
	mov ah, 0eh            ; function teletype
print:
	lodsb                  ; load byte from si into al and increment si
	cmp al, 0              ; end of string?
	je xprint
	int 10h                ; call bios
	jmp print
xprint:

	;xor cx, cx            ; cx should be been cleared in boot sector
read:
	mov ah, 0x00           ; function (read key)
	int 0x16               ; call bios (write ah:scan code, al: ascii char)
	xchg al, ah            ; swap scan code and ascii character...
	stosb                  ; copy the character to the key array
	xchg al, ah            ; ...and back
	mov ah, 0x0e           ; function (teletype output)
	int 0x10               ; call bios
	inc cl
	cmp cl, PWLEN
	jb read



ksa0x:
	; cx is key length (that we set when reading the password) we
	; do a self-overlapping copy to go from e.g. {key_____________}
	; to {keykeykeykeykeyk} as this makes the KSA loop simpler
	mov bx, cx             ; i = len
	mov si, key            ; s = key
	mov di, si             ; d = key
	sub si, cx             ; s -= len
ksa0l:
	mov ch, [si+bx]        ; T = key[i]
	mov [di+bx], ch        ; key[i+len] = T
	inc bl                 ; i += 1
	jnz ksa0l              ; loop until i & 0xff == 0



ksa1x:
	; clear stuff
	xor cx, cx
	xor dx, dx

	; load addresses
	mov si, key
	mov di, S

ksa1l:
	mov bx, cx             ; cx :: i

	mov ah, [si+bx]        ; key[i%N]
	add dl, ah             ; j += key[i%N]

	mov ah, [di+bx]        ; T = S[i]
	add dl, ah             ; j += S[i]

	movzx bx, dl           ; dx :: j (mod 256)
	mov al, [di+bx]        ; U = S[j]
	mov [di+bx], ah        ; S[j] = T

	mov bx, cx             ; cx :: i
	mov [di+bx], al        ; S[i] = U

	inc cl
	jnz ksa1l              ; loop until i overflows to zero



prng:
	; cx will have been reset by now
	mov dx, cx             ; cx :: i, dx :: j still, key schedule still di
	mov si, cx             ; clear si
	mov ax, image          ; offset

prngl:
	inc cl                 ; i += 1

	movzx bx, cl
	mov ch, [di+bx]        ; T = S[i]
	add dl, ch             ; j += S[i]

	movzx bx, dl
	mov dh, [di+bx]        ; U = S[j]
	mov [di+bx], ch        ; S[j] = T (S[i])

	movzx bx, cl
	mov [di+bx], dh        ; S[i] = U (old S[j])

	add ch, dh             ; S[i] + S[j]
	movzx bx, ch
	mov dh, [di+bx]        ; S[(S[i] + S[j]) % 256] - keystream byte

	mov bx, ax
	xor [si+bx], dh        ; xor image data


	inc ax
	jnz prngl              ; loop until overflow to zero



wpal:
	; load start of video memory into es
	push 0a000h
	pop es

	; set video mode to 13h
	mov ax, 13h
	int 10h

	; tell video card we're going to write to the palette at color 0
	mov dx, 3c8h
	mov al, 0
	out dx, al

	; update port address to palette data
	inc dx

	; write pallet data to port
	mov cx, 256*3
	mov si, image
	rep outsb



wimg:
	; write image data to video memory
	xor di, di
	mov cx, (320*200)/2
	rep movsw

endprg:
	jmp short $



; pad out code so image ends at 0x10000 in memory
datapad equ ((256-(0+_KERNEL_OFFSET))-($-start))
	times (datapad) db 0
key:	incbin "prompt.txt",0,255
	times (256-($-key)) db 0
S:	; generate at compile time, lol
%assign i 0
%rep 256
	db i
%assign i i+1
%endrep

image:
	incbin "image.pal",0,256*3   ; 3*256 bytes palette (8 bits)
	incbin "image.raw",0,320*200 ; 320*200 bytes pixel data


;the_end equ ($-start)
;size_in_sectors equ ((the_end - the_end % 512)/512+1)
;times (size_in_sectors*512)-($-$$) db 255 ; pad the file so it fills the last sector

; vim:ft=nasm
