org 0x7c00
bits 16

%define ENDL 0x0d,0x0a

STAGE2_OFFSET equ 0x8000 ; where we load stage2 in the memory
; stage2 is the bridge between read mode and the kernel 
; it makes the switch to protected mode and loads the kernel


start:
    mov [BOOT_DRIVE],dl ; BIOS loads the boot drive number in dl


    mov bp,0x7c00
    mov sp,bp 

    ;load stage2 from the memory
    mov bx,STAGE2_OFFSET ; ES:BX=destination 
    mov dh,4 ; how many sectors to read, of the stage2
    mov dl,[BOOT_DRIVE] ; drive to read form 
    call disk_load 
    
    mov si,msg_stage1
    call print_string



jmp STAGE2_OFFSET ; jump to stage2 

;BIOS disk read using int 0x13
disk_load:
    push dx
    mov di,3 ;retry count 
    .retry:
        mov ah,0x02 ;BIOS read sectors function 
        mov al,dh ; number of sectors 
        mov ch,0x00 ; cylinder 0
        mov dh,0x00 ; head 0
        mov cl,0x02 ;start at sector 2(sector 1= boot sector)
        int 0x13 
        jnc .check ; no carry means so check sector count
        ; error = reset disk and retry
        xor ah,ah
        int 0x13 ;function 0 = reset disk 
        dec di
        jnz .retry
        jmp disk_error
    .check:
        pop dx
        cmp al,dh ; al=sectors actually read 
        jne disk_error
        ret 

disk_error:
    mov si, msg_disk_err
    call print_string
    jmp $

;print null-terminated string in si
print_string:
    mov ah, 0x0E
    .loop:
        lodsb
        or al, al
        jz .done
        int 0x10
        jmp .loop
    .done:
        ret


BOOT_DRIVE db 0
msg_stage1 db 'Stage1 OK',ENDL, 0
msg_disk_err db 'Disk error!', ENDL,0

times 510-($-$$) db 0

dw 0xaa55
