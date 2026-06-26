org 0x7c00
bits 16

%define ENDL 0x0d,0x0a

start:
    jmp main


;
; prints a string to the screen
;  ds:si points to the string 
;

puts:
    push si ;save the value before modifying to recover it later 
    push ax ;

.loop:
    lodsb  ;loads the value of ds:si into ax and increment si
    or al,al ; if both zero it will make zero flag = 1
    jz .done
    mov bh,0x0 ; set the page number to zero
    mov ah,0x0e
    int 0x10 
    jmp .loop


.done:
    pop ax
    pop si
    ret

main:
; setup segement registers 

;data segments
    mov ax,0
    mov ds,ax
    mov es,ax

;stack segement
    mov ss,ax
    mov sp,0x7c00 ; stack pointer poitns to the start of the program

    mov si,hello_world
    call puts

    hlt 

.halt:
    jmp .halt

hello_world:
    db 'hello world!',ENDL,0


times 510-($-$$) db 0

dw 0xaa55