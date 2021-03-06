;==========================================================================================
;
; File Name: io16.asm
;
;
; BSD 3-Clause License
; 
; Copyright (c) 2019, nelsoncole
; All rights reserved.
; 
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
; 
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
; 
; 3. Neither the name of the copyright holder nor the names of its
;    contributors may be used to endorse or promote products derived from
;   this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
; CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;
;========================================================================================

LDSBASE equ 0x600
LDSPARAMETERSBASE equ 0x4000
bits 16
global bootdevice_num,puts16,gatea20,GetDeviceParameters

bootdevice_num db 0

; Display
puts16:
	pusha	
.next:
	cld 		
	lodsb		
	cmp al,0	
	je  .end	
	mov ah,0x0e
	int 0x10
	jmp .next
.end:
	popa
	ret

; Gate A20
gatea20:
	pusha
	cli
; Desabilita teclado
	call a20_wait1
	mov al,0xAD
	out dx,al

;Ler o status gate a20
	call a20_wait1
	mov al,0xD0	
	out 0x64,al

	call a20_wait0
	in al,0x60	;ler o status lido
	mov cl,al

;Escreve status gate a20
	call a20_wait1
	mov al,0xD1	
	out 0x64,al

; Hablita a gate a20
	call a20_wait1
	mov al,cl
	or al,2		;liga o bit 2
	out 0x60,al	

; Habilita o teclado
	call a20_wait1
	mov al,0xAE
	out 0x64,al

	call a20_wait1	;Espera
	sti		;Habilita interrupcoes
	popa
	ret

a20_wait0:
	in al,0x64
	test al,1
	jz a20_wait0  
	ret

a20_wait1:
	in al,0x64
	test al,2
	jnz a20_wait1
	ret
msg0:
	db "BIOSes Extensions Parameters not present",10,13,0
msg1:
	db "BIOSes Get Device Parameters Error",10,13,0
msg2:
	db "BIOSes Enhanced disk device not suport (EDD)",10,13,0

GetDeviceParameters:
;checkExtensionsParameters
	mov ah, 0x41
	mov dl, byte[bootdevice_num]
	mov bx, 0x55aa
	int 0x13
	jnc .present
	cmp bx,0xaa55
	je .present

	mov si,msg0
	jmp error

.present:
	test cx,4
	jnz .suport
	mov si,msg2
	jmp error
	
.suport:	

	push ds
	mov si, LDSBASE
	mov word[si],0x4A ; Length 74 Bytes
	mov ah, 0x48
	mov dl, byte[bootdevice_num]
	int 0x13
	cmp ah,0
    	je .ok  

.error:
	pop ds
	mov si,msg1
	jmp error
	
.ok:
	push es
	push ds
	push si
	push di

	mov di,LDSPARAMETERSBASE
	mov es,di
	xor di,di
	mov cx,0x4A
	cld
	rep movsb	

	pop di
	pop si
	pop ds
	pop es
	
	pop ds
	ret

error:
	call puts16
	ret

section .data

