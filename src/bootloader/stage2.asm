org 0x8000
bits 16

%define ENDL 0x0d,0x0a

KERNEL_OFFSET equ 0x10000

stage2_start:
    mov [BOOT_DRIVE],dl

    xor ax,ax
    mov ds,ax
    mov es,ax

;load kernel from disk 
mov ax,0x1000
mov es,ax           ; ES = 0x1000  →  ES:BX = 0x10000 physical
xor bx,bx           ; BX = 0 (offset)
mov dh,5            ; number of kernel sectors
mov dl,[BOOT_DRIVE]
call disk_load_ext


call enable_a20 ; enable the a20 line 

cli ; disable interrupts before the switch 
lgdt [gdt_descriptor] 

mov eax,cr0
or eax,0x1 ; set PE(protection enable) bit
mov cr0,eax 

jmp CODE_SEG:init_pm ; far jump flushes the pipeline

disk_load_ext:
    mov [SECTORS], dh   ; save sector count in memory (BX is the ES:BX buffer offset)
    mov di, 3           ; retry count
    .retry:
        mov ah, 0x02        ; read sectors
        mov al, [SECTORS]   ; AL = count
        mov ch, 0x00        ; cylinder 0
        mov dh, 0x00        ; head 0
        mov cl, 0x06        ; kernel starts at sector 6
        int 0x13
        jnc .check
        xor ah, ah      ; reset disk
        int 0x13
        dec di
        jnz .retry
        jmp disk_error
    .check:
        cmp al, [SECTORS]   ; sectors read == requested?
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

;GDT
gdt_start:
    gdt_null:
        dd 0x0
        dd 0x0 ;first sd is NULL
    gdt_code: ;code segment : base=0, limit=0xFFFFF 
        dw 0xffff ; limit low 
        dw 0x0 ; base low 
        db 0x0 ; base middle 
        ; 1st flags : ( present )1 ( privilege )00 ( descriptor type )1 -> 1001 b
        ; type flags : ( code )1 ( conforming )0 ( readable )1 ( accessed )0 -> 1010 b
        ; 2nd flags : ( granularity )1 (32 - bit default )1 (64 - bit seg )0 ( AVL )0 -> 1100 b
        db 10011010b 
        db 11001111b
        db 0x0 ; base high
    gdt_data:
        dw 0xffff ; limit low 
        dw 0x0 ; base low 
        db 0x0 ; base middle 
        db 10010010b ; (code)0 = data segment
        db 11001111b
        db 0x0 ; base high
gdt_end:


gdt_descriptor:
    dw gdt_end-gdt_start-1
    dd gdt_start 


CODE_SEG equ gdt_code-gdt_start
DATA_SEG equ gdt_data-gdt_start

BOOT_DRIVE db 0
SECTORS db 0
msg_disk_err db "disk read error",ENDL,0



enable_a20: ;enabling a20 via fast gate port 0x92 (not supported by all the BIOS)
    in al,0x92 
    or al,0x2
    out 0x92,al 
    ret 


;32 bit mode started everything below will be interpreted as 32 bit instructions 
bits 32 

init_pm: ; point all seg registers to data segment 
    mov ax,DATA_SEG 
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    ;cs cant be set with mov instruction it gets automaticallys set to CODE_SEG

    mov ebp,0x90000 ; set up 32 bit stack 
    mov esp,ebp

    mov byte [0xB8000], 'P'
    mov byte [0xB8001], 0x0F
    
    call KERNEL_OFFSET ; jump into the C kernel at 0x10000


    
    jmp $ ; if kernel returns , hang(error)


    times 2048-($-$$) db 0    ; pad stage2 to exactly 4 sectors