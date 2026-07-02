void kmain(void){
    volatile char *vga = (volatile char*)0xb8000;
    const char *msg = "Hello c kernel";
    for(int i=0;msg[i];i++){
        vga[i*2] = msg[i];
        vga[i*2+1]=0x0f; // white on black
    }
    for(;;); // halt 
}