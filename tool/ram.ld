MEMORY
{
    ram : ORIGIN = 0x00000000, LENGTH = 0x00001000
}

SECTIONS
{
    .text :
    {
     *(.text)
     } > ram

    .data :
    {
    *(.data)
    } > ram

    .bss :
    {
    *(.data)
    } > ram
}
ENTRY (_start)
